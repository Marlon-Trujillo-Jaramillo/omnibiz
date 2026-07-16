import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventario_app/core/design_system/design_system.dart';

/// Shows a dialog to type an exact quantity instead of tapping +/- repeatedly.
/// Returns the entered quantity, or null if cancelled.
Future<int?> showQuantityDialog(
  BuildContext context, {
  required String productName,
  int initialValue = 1,
  String confirmLabel = 'Aceptar',
}) {
  return showDialog<int>(
    context: context,
    builder: (_) => _QuantityDialog(
      productName: productName,
      initialValue: initialValue,
      confirmLabel: confirmLabel,
    ),
  );
}

class _QuantityDialog extends StatefulWidget {
  const _QuantityDialog({
    required this.productName,
    required this.initialValue,
    required this.confirmLabel,
  });

  final String productName;
  final int initialValue;
  final String confirmLabel;

  @override
  State<_QuantityDialog> createState() => _QuantityDialogState();
}

class _QuantityDialogState extends State<_QuantityDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: '${widget.initialValue}');

  void _submit() {
    final value = int.tryParse(_controller.text.trim());
    Navigator.pop(context, value != null && value > 0 ? value : null);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
            Text('Cantidad', style: OmniTypography.headingMd),
            const SizedBox(height: OmniSpacing.xs),
            Text(
              widget.productName,
              style: OmniTypography.bodySm.copyWith(color: OmniColors.textMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: OmniSpacing.base),
            OmniTextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: OmniSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: OmniButton(
                    label: 'Cancelar',
                    onPressed: () => Navigator.pop(context),
                    variant: OmniButtonVariant.ghost,
                  ),
                ),
                const SizedBox(width: OmniSpacing.md),
                Expanded(
                  child: OmniButton(
                    label: widget.confirmLabel,
                    onPressed: _submit,
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
