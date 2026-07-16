import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../tokens/omni_colors.dart';
import '../../tokens/omni_radius.dart';
import '../../tokens/omni_spacing.dart';
import '../../tokens/omni_typography.dart';

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

  @override
  Widget build(BuildContext context) {
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
      style: OmniTypography.bodyMd.copyWith(color: OmniColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: OmniTypography.caption.copyWith(color: OmniColors.textMuted),
        hintStyle: OmniTypography.bodyMd.copyWith(color: OmniColors.textDisabled),
        filled: true,
        fillColor: OmniColors.borderSubtle,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: OmniColors.textMuted, size: 18)
            : null,
        suffix: suffixWidget,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: OmniSpacing.base,
          vertical: OmniSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: OmniRadius.mdAll,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: OmniRadius.mdAll,
          borderSide: const BorderSide(color: OmniColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: OmniRadius.mdAll,
          borderSide: const BorderSide(color: OmniColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: OmniRadius.mdAll,
          borderSide: const BorderSide(color: OmniColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: OmniRadius.mdAll,
          borderSide: const BorderSide(color: OmniColors.danger, width: 1.5),
        ),
      ),
    );
  }
}
