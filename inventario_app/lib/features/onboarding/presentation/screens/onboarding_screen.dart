import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:inventario_app/core/design_system/design_system.dart';
import 'package:inventario_app/shared/providers/business_type_provider.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  void _selectType(BuildContext context, WidgetRef ref, String type) {
    ref.read(businessTypeProvider.notifier).save(type);
    context.go('/dashboard?type=$type');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: OmniColors.bg,
      body: SafeArea(
        child: OmniResponsiveCenter(
        child: Padding(
          padding: const EdgeInsets.all(OmniSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: OmniSpacing.xxxl),
              Text('Bienvenido a', style: OmniTypography.bodyLg.copyWith(color: OmniColors.textSecondary)),
              const SizedBox(height: OmniSpacing.xs),
              Text('OmniBiz', style: OmniTypography.displayLg),
              const SizedBox(height: OmniSpacing.sm),
              Text(
                'La solución inteligente para gestionar\ntu negocio de forma profesional.',
                style: OmniTypography.bodySm,
              ),
              const SizedBox(height: OmniSpacing.xxxl),
              Text('Selecciona tu tipo de negocio', style: OmniTypography.headingMd),
              const SizedBox(height: OmniSpacing.xl),
              Expanded(
                child: ListView(
                  children: [
                    _BusinessCard(
                      title: 'Tienda de Ropa / Retail',
                      subtitle: 'Gestión de tallas, colores y variantes de stock.',
                      icon: LucideIcons.shirt,
                      color: OmniColors.purple,
                      onTap: () => _selectType(context, ref, 'retail'),
                    ),
                    const SizedBox(height: OmniSpacing.base),
                    _BusinessCard(
                      title: 'Restaurante / Bar',
                      subtitle: 'Control de mesas, barra e ingredientes.',
                      icon: LucideIcons.utensils,
                      color: OmniColors.orange,
                      onTap: () => _selectType(context, ref, 'fnb'),
                    ),
                    const SizedBox(height: OmniSpacing.base),
                    _BusinessCard(
                      title: 'Otro Local Comercial',
                      subtitle: 'Puntos de venta rápidos y servicios.',
                      icon: LucideIcons.store,
                      color: OmniColors.blue,
                      onTap: () => _selectType(context, ref, 'generic'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

class _BusinessCard extends StatelessWidget {
  const _BusinessCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: OmniRadius.lgAll,
      child: Container(
        padding: const EdgeInsets.all(OmniSpacing.lg),
        decoration: BoxDecoration(
          color: OmniColors.bgSurface,
          borderRadius: OmniRadius.lgAll,
          border: Border.all(color: OmniColors.borderSubtle),
        ),
        child: Row(
          children: [
            OmniIconAvatar(icon: icon, color: color, size: 52),
            const SizedBox(width: OmniSpacing.base),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: OmniTypography.headingSm),
                  const SizedBox(height: OmniSpacing.xs),
                  Text(subtitle, style: OmniTypography.bodySm),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: OmniColors.textDisabled),
          ],
        ),
      ),
    );
  }
}
