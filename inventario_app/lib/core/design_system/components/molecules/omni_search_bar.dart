import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/omni_theme_extensions.dart';
import '../../tokens/omni_radius.dart';
import '../../tokens/omni_sizes.dart';
import '../../tokens/omni_spacing.dart';

/// Buscador con ícono, botón de limpiar y acción opcional a la derecha.
class OmniSearchBar extends StatefulWidget {
  const OmniSearchBar({
    super.key,
    required this.controller,
    this.hint = 'Buscar...',
    this.onChanged,
    this.trailing,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final Widget? trailing;
  final bool autofocus;

  @override
  State<OmniSearchBar> createState() => _OmniSearchBarState();
}

class _OmniSearchBarState extends State<OmniSearchBar> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_rebuild);
    widget.controller.addListener(_rebuild);
  }

  @override
  void didUpdateWidget(OmniSearchBar old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_rebuild);
      widget.controller.addListener(_rebuild);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    _focus.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _clear() {
    widget.controller.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final focused = _focus.hasFocus;
    return AnimatedContainer(
      duration: OmniMotion.base,
      height: OmniSizes.controlMd,
      decoration: BoxDecoration(
        color: c.bgSurface,
        borderRadius: OmniRadius.lgAll,
        border: Border.all(
          color: focused ? c.primary : c.borderSubtle,
          width: focused ? OmniSizes.focusRing : OmniSizes.hairline,
        ),
        boxShadow: c.cardShadow,
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: OmniSpacing.md),
            child: Icon(LucideIcons.search,
                color: focused ? c.primaryText : c.textMuted,
                size: OmniSizes.iconSm + 2),
          ),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              onChanged: widget.onChanged,
              autofocus: widget.autofocus,
              textInputAction: TextInputAction.search,
              style: context.text.bodyMd,
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: context.text.bodyMd.copyWith(color: c.textMuted),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
                filled: false,
              ),
            ),
          ),
          if (widget.controller.text.isNotEmpty)
            IconButton(
              tooltip: 'Limpiar búsqueda',
              visualDensity: VisualDensity.compact,
              icon: Icon(LucideIcons.x,
                  size: OmniSizes.iconSm, color: c.textMuted),
              onPressed: _clear,
            ),
          if (widget.trailing != null) ...[
            Container(
              width: OmniSizes.hairline,
              height: OmniSizes.iconLg,
              color: c.borderSubtle,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: OmniSpacing.xs),
              child: widget.trailing!,
            ),
          ] else
            const SizedBox(width: OmniSpacing.xs),
        ],
      ),
    );
  }
}
