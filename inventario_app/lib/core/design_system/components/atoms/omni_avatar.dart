import 'package:flutter/material.dart';
import '../../tokens/omni_colors.dart';
import '../../tokens/omni_radius.dart';

class OmniAvatar extends StatelessWidget {
  const OmniAvatar({
    super.key,
    required this.name,
    this.radius = 22,
    this.color = OmniColors.primary,
  });

  final String name;
  final double radius;
  final Color color;

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withAlpha(30),
      child: Text(
        _initials,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.65,
        ),
      ),
    );
  }
}

class OmniIconAvatar extends StatelessWidget {
  const OmniIconAvatar({
    super.key,
    required this.icon,
    this.size = 44,
    this.color = OmniColors.primary,
  });

  final IconData icon;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: OmniRadius.mdAll,
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}
