import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/omni_theme_extensions.dart';
import '../../tokens/omni_colors.dart';
import '../../tokens/omni_radius.dart';
import '../../tokens/omni_sizes.dart';
import '../../tokens/omni_spacing.dart';
import '../atoms/omni_drag_handle.dart';

IconData _toneIcon(OmniTone tone) => switch (tone) {
      OmniTone.success => LucideIcons.checkCircle2,
      OmniTone.warning => LucideIcons.alertTriangle,
      OmniTone.danger  => LucideIcons.alertCircle,
      OmniTone.info || OmniTone.brand || OmniTone.neutral => LucideIcons.info,
    };

// ── Snackbar ───────────────────────────────────────────────────────────────────

extension OmniSnackBar on ScaffoldMessengerState {
  /// Muestra un snackbar del sistema de diseño (reemplaza al actual).
  /// El fondo es siempre oscuro, así que el ícono usa los tonos de
  /// [OmniPalette.dark] en ambos temas.
  void showOmni(
    String message, {
    OmniTone tone = OmniTone.neutral,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    this
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        duration: duration,
        content: _SnackContent(message: message, tone: tone, icon: icon),
      ));
  }
}

class _SnackContent extends StatelessWidget {
  const _SnackContent({required this.message, required this.tone, this.icon});

  final String message;
  final OmniTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    const onDark = OmniPalette.dark;
    final fg = tone == OmniTone.neutral ? onDark.textSecondary : onDark.toneFg(tone);
    return Row(
      children: [
        Container(
          width: OmniSizes.iconXl - OmniSpacing.xs,
          height: OmniSizes.iconXl - OmniSpacing.xs,
          decoration: BoxDecoration(
            color: onDark.toneBg(tone),
            shape: BoxShape.circle,
          ),
          child: Icon(icon ?? _toneIcon(tone), color: fg, size: OmniSizes.iconSm),
        ),
        const SizedBox(width: OmniSpacing.md),
        Expanded(
          child: Text(message,
              style: context.text.bodyMd.copyWith(color: context.colors.onSnack)),
        ),
      ],
    );
  }
}

// ── Banner ─────────────────────────────────────────────────────────────────────

/// Aviso en línea tintado (advertencias, errores recuperables, info).
class OmniBanner extends StatelessWidget {
  const OmniBanner({
    super.key,
    required this.message,
    this.title,
    this.tone = OmniTone.info,
    this.icon,
    this.trailing,
  });

  final String message;
  final String? title;
  final OmniTone tone;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = c.toneFg(tone);
    return Container(
      padding: const EdgeInsets.all(OmniSpacing.md),
      decoration: BoxDecoration(
        color: c.toneBg(tone),
        borderRadius: OmniRadius.mdAll,
        border: Border.all(color: fg.withAlpha(c.isDark ? 50 : 40)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: OmniSpacing.xxs),
            child: Icon(icon ?? _toneIcon(tone), color: fg, size: OmniSizes.iconSm),
          ),
          const SizedBox(width: OmniSpacing.sm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(title!,
                      style: context.text.bodyMd
                          .copyWith(color: fg, fontWeight: FontWeight.w600)),
                  const SizedBox(height: OmniSpacing.xxs),
                ],
                Text(message, style: context.text.bodySm.copyWith(color: fg)),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: OmniSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}

// ── Bottom sheet ───────────────────────────────────────────────────────────────

/// Abre un bottom sheet con el estilo del sistema (asa, esquinas, ancho
/// máximo en tablet, respeta el teclado).
Future<T?> showOmniSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool scrollable = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: scrollable,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: builder,
  );
}

/// Cuerpo estándar de un sheet: asa, título y contenido con padding.
class OmniSheetBody extends StatelessWidget {
  const OmniSheetBody({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.trailing,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: OmniSpacing.xl,
        right: OmniSpacing.xl,
        top: OmniSpacing.md,
        bottom: OmniSpacing.xl + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const OmniDragHandle(),
            if (title != null) ...[
              const SizedBox(height: OmniSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title!, style: context.text.headingLg),
                        if (subtitle != null) ...[
                          const SizedBox(height: OmniSpacing.xxs),
                          Text(subtitle!, style: context.text.bodySm),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
              const SizedBox(height: OmniSpacing.xl),
            ] else
              const SizedBox(height: OmniSpacing.base),
            child,
          ],
        ),
      ),
    );
  }
}
