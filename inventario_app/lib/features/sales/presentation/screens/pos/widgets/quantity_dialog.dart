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
  late final TextEditingController _controller = TextEditingController(
    text: '${widget.initialValue}',
  );

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
    return OmniDialog(
      title: 'Cantidad',
      subtitle: widget.productName,
      actions: OmniDialogActions(
        onCancel: () => Navigator.pop(context),
        onConfirm: _submit,
        confirmLabel: widget.confirmLabel,
      ),
      child: OmniTextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        autofocus: true,
        tabularDigits: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
      ),
    );
  }
}
