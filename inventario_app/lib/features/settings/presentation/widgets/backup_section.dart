import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:inventario_app/core/backup/backup_codec.dart';
import 'package:inventario_app/core/backup/backup_service.dart';
import 'package:inventario_app/core/design_system/design_system.dart';
import 'package:inventario_app/core/utils/app_logger.dart';
import 'package:inventario_app/core/utils/app_currency.dart';
import 'package:inventario_app/features/customers/presentation/providers/customers_notifier.dart';
import 'package:inventario_app/features/inventory/presentation/providers/products_notifier.dart';
import 'package:inventario_app/features/sales/presentation/providers/cart_notifier.dart';
import 'package:inventario_app/features/sales/presentation/providers/sales_notifier.dart';
import 'package:inventario_app/features/stores/presentation/providers/stores_notifier.dart';
import 'package:inventario_app/shared/providers/currency_provider.dart';
import 'package:inventario_app/shared/providers/current_store_provider.dart';
import 'package:inventario_app/shared/providers/database_provider.dart';

const _tag = 'BackupSection';

final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(ref.watch(databaseProvider)),
);

/// Respaldo cifrado de todos los datos: crear (y compartir) y restaurar.
class BackupSection extends ConsumerWidget {
  const BackupSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ActionTile(
          icon: LucideIcons.shieldCheck,
          title: 'Crear respaldo',
          subtitle: 'Guarda todo en un archivo cifrado con tu contraseña',
          onTap: () => _createBackup(context, ref),
        ),
        const SizedBox(height: OmniSpacing.sm),
        _ActionTile(
          icon: LucideIcons.archiveRestore,
          title: 'Restaurar respaldo',
          subtitle: 'Reemplaza los datos de este teléfono por los del archivo',
          onTap: () => _restoreBackup(context, ref),
        ),
        const SizedBox(height: OmniSpacing.md),
        const OmniBanner(
          tone: OmniTone.info,
          message:
              'Todo vive solo en este teléfono. Crea un respaldo seguido y '
              'guárdalo fuera de él (Drive, correo, WhatsApp). Sin la '
              'contraseña del respaldo nadie puede leerlo, ni siquiera tú.',
        ),
      ],
    );
  }
}

Future<void> _createBackup(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  final file = await showDialog<File>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _PasswordDialog(
      mode: _PasswordMode.create,
      run: (password) async {
        final bytes = await ref.read(backupServiceProvider).create(password);
        final dir = await getTemporaryDirectory();
        final stamp = DateFormat('yyyy-MM-dd-HHmm').format(DateTime.now());
        final file = File(p.join(dir.path, 'omnibiz-respaldo-$stamp.omnibak'));
        await file.writeAsBytes(bytes, flush: true);
        return file;
      },
    ),
  );
  if (file == null) return;
  final result = await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: 'application/octet-stream')],
      subject: 'Respaldo de OmniBiz',
      text: 'Respaldo cifrado de OmniBiz. Guárdalo en un lugar seguro.',
    ),
  );
  if (result.status != ShareResultStatus.dismissed) {
    messenger.showOmni('Respaldo creado', tone: OmniTone.success);
  }
}

Future<void> _restoreBackup(BuildContext context, WidgetRef ref) async {
  final picked = await FilePicker.pickFiles(withData: true);
  final bytes = picked?.files.single.bytes;
  if (bytes == null || !context.mounted) return;

  final ok = await OmniConfirmDialog.show(
    context,
    icon: LucideIcons.archiveRestore,
    title: 'Restaurar respaldo',
    body:
        'Se reemplazarán TODOS los datos de este teléfono (productos, ventas, '
        'clientes y sucursales) por los del respaldo. No se puede deshacer.',
    confirmLabel: 'Continuar',
    destructive: true,
  );
  if (!ok || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  final summary = await showDialog<RestoreSummary>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _PasswordDialog(
      mode: _PasswordMode.restore,
      run: (password) => ref
          .read(backupServiceProvider)
          .restore(
            bytes,
            password,
            legacyCurrencyCode: ref.read(currencyProvider).code,
          ),
    ),
  );
  if (summary == null) return;

  // Todo lo que se leyó de la BD anterior queda obsoleto.
  await ref.read(currentStoreProvider.notifier).set(summary.defaultStoreId);
  ref
    ..invalidate(storesProvider)
    ..invalidate(productsProvider)
    ..invalidate(categoriesProvider)
    ..invalidate(customersProvider)
    ..invalidate(salesInRangeProvider)
    ..invalidate(salesHistoryProvider)
    ..invalidate(cartProvider);
  messenger.showOmni(
    'Respaldo restaurado: ${summary.count('products')} productos, '
    '${summary.count('customers')} clientes y ${summary.count('sales')} ventas',
    tone: OmniTone.success,
  );
}

enum _PasswordMode { create, restore }

/// Pide la contraseña y ejecuta [run] mostrando el progreso (el KDF tarda un
/// par de segundos a propósito). Devuelve el resultado de [run] al cerrar.
class _PasswordDialog<T> extends StatefulWidget {
  const _PasswordDialog({required this.mode, required this.run});

  final _PasswordMode mode;
  final Future<T> Function(String password) run;

  @override
  State<_PasswordDialog<T>> createState() => _PasswordDialogState<T>();
}

class _PasswordDialogState<T> extends State<_PasswordDialog<T>> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _working = false;
  String? _error;

  bool get _creating => widget.mode == _PasswordMode.create;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_working || !_formKey.currentState!.validate()) return;
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      final result = await widget.run(_password.text);
      if (mounted) Navigator.pop(context, result);
    } on BackupException catch (e) {
      if (mounted) {
        setState(() {
          _working = false;
          _error = e.message;
        });
      }
    } catch (e, st) {
      AppLogger.e(_tag, 'respaldo falló', e, st);
      if (mounted) {
        setState(() {
          _working = false;
          _error = _creating
              ? 'No se pudo crear el respaldo.'
              : 'No se pudo restaurar el respaldo.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mientras corre el KDF/restauración no se puede cerrar (ni con "atrás").
    return PopScope(
      canPop: !_working,
      child: Form(
        key: _formKey,
        child: OmniDialog(
          title: _creating ? 'Crear respaldo' : 'Contraseña del respaldo',
          subtitle: _creating
              ? 'Elige una contraseña para proteger el archivo'
              : 'La que usaste al crear el respaldo',
          icon: _creating ? LucideIcons.shieldCheck : LucideIcons.keyRound,
          actions: OmniDialogActions(
            onCancel: () {
              if (!_working) Navigator.pop(context);
            },
            onConfirm: _submit,
            confirmLabel: _creating ? 'Crear' : 'Restaurar',
            loading: _working,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OmniTextField(
                controller: _password,
                label: 'Contraseña',
                prefixIcon: LucideIcons.lock,
                obscureText: true,
                autofocus: true,
                validator: (v) =>
                    (v ?? '').length < BackupCodec.minPasswordLength
                    ? 'Mínimo ${BackupCodec.minPasswordLength} caracteres'
                    : null,
              ),
              if (_creating) ...[
                const SizedBox(height: OmniSpacing.md),
                OmniTextField(
                  controller: _confirm,
                  label: 'Repite la contraseña',
                  prefixIcon: LucideIcons.lock,
                  obscureText: true,
                  validator: (v) => v != _password.text
                      ? 'Las contraseñas no coinciden'
                      : null,
                ),
                const SizedBox(height: OmniSpacing.md),
                Text(
                  'Anótala en un lugar seguro: sin ella el respaldo no se '
                  'puede abrir.',
                  style: context.text.caption,
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: OmniSpacing.md),
                OmniBanner(tone: OmniTone.danger, message: _error!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OmniCard(
      onTap: onTap,
      child: Row(
        children: [
          OmniIconAvatar(icon: icon),
          const SizedBox(width: OmniSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.text.bodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: OmniSpacing.xxs),
                Text(subtitle, style: context.text.caption),
              ],
            ),
          ),
          Icon(
            LucideIcons.chevronRight,
            size: OmniSizes.iconSm,
            color: context.colors.textMuted,
          ),
        ],
      ),
    );
  }
}
