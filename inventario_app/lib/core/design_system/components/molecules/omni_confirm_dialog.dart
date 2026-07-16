import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../tokens/omni_colors.dart';
import '../../tokens/omni_radius.dart';
import '../../tokens/omni_spacing.dart';
import '../../tokens/omni_typography.dart';
import '../atoms/omni_button.dart';

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
    return Dialog(
      backgroundColor: OmniColors.bgModal,
      shape: RoundedRectangleBorder(borderRadius: OmniRadius.xlAll),
      child: Padding(
        padding: const EdgeInsets.all(OmniSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(OmniSpacing.md),
                decoration: BoxDecoration(
                  color: destructive ? OmniColors.dangerBg : OmniColors.primaryBg,
                  borderRadius: OmniRadius.mdAll,
                ),
                child: Icon(
                  icon,
                  color: destructive ? OmniColors.danger : OmniColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(height: OmniSpacing.base),
            ],
            Text(title, style: OmniTypography.headingMd),
            const SizedBox(height: OmniSpacing.sm),
            Text(body, style: OmniTypography.bodySm),
            const SizedBox(height: OmniSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: OmniButton(
                    label: cancelLabel,
                    onPressed: () => Navigator.pop(context, false),
                    variant: OmniButtonVariant.ghost,
                  ),
                ),
                const SizedBox(width: OmniSpacing.md),
                Expanded(
                  child: OmniButton(
                    label: confirmLabel,
                    onPressed: () {
                      if (destructive) {
                        HapticFeedback.heavyImpact();
                      }
                      Navigator.pop(context, true);
                    },
                    variant: destructive
                        ? OmniButtonVariant.danger
                        : OmniButtonVariant.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
