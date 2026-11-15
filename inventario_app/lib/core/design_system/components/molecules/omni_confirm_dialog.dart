import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/omni_theme_extensions.dart';
import '../../tokens/omni_colors.dart';
import '../../tokens/omni_radius.dart';
import '../../tokens/omni_sizes.dart';
import '../../tokens/omni_spacing.dart';
import '../atoms/omni_button.dart';

/// Contenedor estándar de diálogo: ancho acotado, padding y título.
class OmniDialog extends StatelessWidget {
  const OmniDialog({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.icon,
    this.tone = OmniTone.brand,
    this.actions,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final OmniTone tone;
  final Widget child;

  /// Fila de acciones al pie (ver [OmniDialogActions]).
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(OmniSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Container(
                  width: OmniSizes.avatarMd,
                  height: OmniSizes.avatarMd,
                  decoration: BoxDecoration(
                    color: c.toneBg(tone),
                    borderRadius: OmniRadius.mdAll,
                  ),
                  child: Icon(
                    icon,
                    color: c.toneFg(tone),
                    size: OmniSizes.iconMd + 2,
                  ),
                ),
                const SizedBox(height: OmniSpacing.base),
              ],
              Text(title, style: context.text.headingLg),
              if (subtitle != null) ...[
                const SizedBox(height: OmniSpacing.xs + 2),
                Text(
                  subtitle!,
                  style: context.text.bodyMd.copyWith(color: c.textSecondary),
                ),
              ],
              const SizedBox(height: OmniSpacing.xl),
              child,
              if (actions != null) ...[
                const SizedBox(height: OmniSpacing.xl),
                actions!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Cancelar + confirmar, a lo ancho.
class OmniDialogActions extends StatelessWidget {
  const OmniDialogActions({
    super.key,
    required this.onCancel,
    required this.onConfirm,
    required this.confirmLabel,
    this.cancelLabel = 'Cancelar',
    this.loading = false,
    this.destructive = false,
  });

  final VoidCallback onCancel;

  /// null → botón deshabilitado.
  final VoidCallback? onConfirm;
  final String confirmLabel;
  final String cancelLabel;

  /// Deshabilita ambos botones mientras se guarda (evita doble envío).
  final bool loading;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OmniButton(
            label: cancelLabel,
            onPressed: loading ? null : onCancel,
            variant: OmniButtonVariant.secondary,
          ),
        ),
        const SizedBox(width: OmniSpacing.md),
        Expanded(
          child: OmniButton(
            label: confirmLabel,
            onPressed: loading ? null : onConfirm,
            loading: loading,
            variant: destructive
                ? OmniButtonVariant.danger
                : OmniButtonVariant.primary,
          ),
        ),
      ],
    );
  }
}

class OmniConfirmDialog extends StatelessWidget {
  const OmniConfirmDialog({
    super.key,
    required this.title,
    required this.body,
    this.confirmLabel = 'Confirmar',
    this.cancelLabel = 'Cancelar',
    this.destructive = false,
    this.icon,
  });

  final String title;
  final String body;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;
  final IconData? icon;

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String body,
    String confirmLabel = 'Confirmar',
    String cancelLabel = 'Cancelar',
    bool destructive = false,
    IconData? icon,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => OmniConfirmDialog(
        title: title,
        body: body,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        destructive: destructive,
        icon: icon,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return OmniDialog(
      title: title,
      icon: icon,
      tone: destructive ? OmniTone.danger : OmniTone.brand,
      actions: OmniDialogActions(
        onCancel: () => Navigator.pop(context, false),
        onConfirm: () {
          if (destructive) HapticFeedback.heavyImpact();
          Navigator.pop(context, true);
        },
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        destructive: destructive,
      ),
      child: Text(
        body,
        style: context.text.bodyMd.copyWith(
          color: context.colors.textSecondary,
        ),
      ),
    );
  }
}
