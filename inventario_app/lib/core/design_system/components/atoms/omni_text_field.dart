import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/omni_theme_extensions.dart';
import '../../tokens/omni_typography.dart';
import '../../tokens/omni_sizes.dart';

/// Campo de texto del sistema de diseño. Bordes, relleno y estados vienen del
/// `inputDecorationTheme` de [OmniTheme] (claro/oscuro).
class OmniTextField extends StatelessWidget {
  const OmniTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixWidget,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
    this.obscureText = false,
    this.autofocus = false,
    this.readOnly = false,
    this.maxLines = 1,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.focusNode,
    this.textInputAction,
    this.initialValue,
    this.tabularDigits = false,
    this.helperText,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixWidget;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final bool autofocus;
  final bool readOnly;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final String? initialValue;
  /// Cifras tabulares (montos, cantidades, códigos).
  final bool tabularDigits;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    final style = context.text.bodyLg;
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      obscureText: obscureText,
      autofocus: autofocus,
      readOnly: readOnly,
      maxLines: maxLines,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      onTap: onTap,
      focusNode: focusNode,
      textInputAction: textInputAction,
      style: tabularDigits ? style.tabular : style,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: OmniSizes.iconSm + 2)
            : null,
        suffixIcon: suffixWidget,
      ),
    );
  }
}
