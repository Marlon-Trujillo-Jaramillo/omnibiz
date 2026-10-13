import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:inventario_app/core/design_system/design_system.dart';

/// Pantalla mínima mientras [AuthNotifier] lee el almacenamiento seguro.
/// El router no deja pasar a ninguna otra ruta hasta que termine.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: OmniSizes.avatarXl,
              height: OmniSizes.avatarXl,
              decoration: BoxDecoration(
                gradient: c.brandGradient,
                borderRadius: OmniRadius.xxlAll,
                boxShadow: c.glow(c.primary),
              ),
              child: Icon(LucideIcons.lock,
                  color: c.onPrimary, size: OmniSizes.iconXl),
            ),
            const SizedBox(height: OmniSpacing.xl),
            Text('OmniBiz', style: context.text.headingLg),
            const SizedBox(height: OmniSpacing.xl),
            const SizedBox(
              width: OmniSizes.iconLg,
              height: OmniSizes.iconLg,
              child: CircularProgressIndicator(strokeWidth: OmniSizes.stroke),
            ),
          ],
        ),
      ),
    );
  }
}
