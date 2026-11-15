import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:inventario_app/core/design_system/design_system.dart';

/// App mínima que se muestra cuando la BD cifrada no se puede abrir (clave
/// perdida o incorrecta). No toca los datos salvo que el usuario confirme
/// "Empezar de cero", que aparta el archivo ilegible (no lo borra).
class DatabaseErrorApp extends StatelessWidget {
  const DatabaseErrorApp({
    super.key,
    required this.reason,
    required this.onRetry,
    required this.onReset,
    this.themeMode = ThemeMode.system,
  });

  final ThemeMode themeMode;
  final String reason;
  final Future<void> Function() onRetry;
  final Future<void> Function() onReset;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OmniBiz',
      debugShowCheckedModeBanner: false,
      theme: OmniTheme.light(),
      darkTheme: OmniTheme.dark(),
      themeMode: themeMode,
      home: _DatabaseErrorScreen(
        reason: reason,
        onRetry: onRetry,
        onReset: onReset,
      ),
    );
  }
}

class _DatabaseErrorScreen extends StatefulWidget {
  const _DatabaseErrorScreen({
    required this.reason,
    required this.onRetry,
    required this.onReset,
  });

  final String reason;
  final Future<void> Function() onRetry;
  final Future<void> Function() onReset;

  @override
  State<_DatabaseErrorScreen> createState() => _DatabaseErrorScreenState();
}

class _DatabaseErrorScreenState extends State<_DatabaseErrorScreen> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    await action();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _confirmReset() async {
    final ok = await OmniConfirmDialog.show(
      context,
      title: 'Empezar de cero',
      body:
          'Se creará una base de datos vacía. Los datos actuales no se '
          'pueden leer sin su clave; el archivo se conserva aparte en el '
          'dispositivo pero la app no lo usará.',
      confirmLabel: 'Empezar de cero',
      destructive: true,
    );
    if (ok) await _run(widget.onReset);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: OmniResponsiveCenter(
          maxWidth: OmniBreakpoints.tablet,
          child: Padding(
            padding: const EdgeInsets.all(OmniSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: OmniStateIllustration(
                    icon: LucideIcons.shieldAlert,
                    tone: OmniTone.danger,
                  ),
                ),
                const SizedBox(height: OmniSpacing.xl),
                Text(
                  'No se pueden abrir los datos',
                  style: context.text.headingLg,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: OmniSpacing.md),
                Text(
                  widget.reason,
                  style: context.text.bodyMd.copyWith(
                    color: context.colors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: OmniSpacing.xxl),
                OmniButton(
                  label: 'Reintentar',
                  icon: LucideIcons.refreshCw,
                  fullWidth: true,
                  loading: _busy,
                  onPressed: _busy ? null : () => _run(widget.onRetry),
                ),
                const SizedBox(height: OmniSpacing.md),
                OmniButton(
                  label: 'Empezar de cero',
                  variant: OmniButtonVariant.danger,
                  fullWidth: true,
                  onPressed: _busy ? null : _confirmReset,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
