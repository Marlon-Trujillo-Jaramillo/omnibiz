import 'package:flutter/material.dart';
import '../../theme/omni_theme_extensions.dart';
import '../../tokens/omni_colors.dart';
import '../../tokens/omni_radius.dart';
import '../../tokens/omni_sizes.dart';
import '../../tokens/omni_typography.dart';

/// Iniciales de una persona. El tono se deriva del nombre (estable) salvo
/// que se indique [tone].
class OmniAvatar extends StatelessWidget {
  const OmniAvatar({
    super.key,
    required this.name,
    this.radius = OmniSizes.avatarMd / 2,
    this.tone,
  });

  final String name;
  final double radius;
  final OmniTone? tone;

  static const _tones = [
    OmniTone.brand,
    OmniTone.info,
    OmniTone.success,
    OmniTone.warning,
  ];

  String get _initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = tone ?? _tones[name.hashCode.abs() % _tones.length];
    return Container(
      width: radius * 2,
      height: radius * 2,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: c.toneBg(t), shape: BoxShape.circle),
      child: Text(
        _initials,
        style: OmniTypography.headingSm.copyWith(
          color: c.toneFg(t),
          fontSize: radius * 0.72,
          height: 1,
        ),
      ),
    );
  }
}

/// Ícono dentro de un cuadrado redondeado tintado.
class OmniIconAvatar extends StatelessWidget {
  const OmniIconAvatar({
    super.key,
    required this.icon,
    this.size = OmniSizes.avatarMd,
    this.color,
    this.background,
  });

  final IconData icon;
  final double size;

  /// Color del ícono; por defecto, marca. El fondo es un tinte del mismo
  /// color salvo que se indique [background].
  final Color? color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = color ?? c.primaryText;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? fg.withAlpha(c.isDark ? 36 : 24),
        borderRadius: size >= OmniSizes.avatarLg
            ? OmniRadius.lgAll
            : OmniRadius.mdAll,
      ),
      child: Icon(icon, color: fg, size: size * 0.46),
    );
  }
}
