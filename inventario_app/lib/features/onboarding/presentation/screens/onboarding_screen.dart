import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
    final c = context.colors;
    return Scaffold(
      body: SafeArea(
        child: OmniResponsiveCenter(
          maxWidth: OmniBreakpoints.tablet,
          child: ListView(
            padding: const EdgeInsets.all(OmniSpacing.xl),
            children: [
              const SizedBox(height: OmniSpacing.xxl),
              Container(
                width: OmniSizes.avatarLg,
                height: OmniSizes.avatarLg,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: c.brandGradient,
                  borderRadius: OmniRadius.lgAll,
                  boxShadow: c.glow(c.primary),
                ),
                child: Icon(LucideIcons.zap,
                    color: c.onPrimary, size: OmniSizes.iconLg + 4),
              ),
              const SizedBox(height: OmniSpacing.xl),
              Text('Bienvenido a', style: context.text.bodyLg
                  .copyWith(color: c.textSecondary)),
              Text('OmniBiz', style: context.text.displayLg),
              const SizedBox(height: OmniSpacing.sm),
              Text(
                'Vende, controla tu inventario y lleva el fiado de tus clientes, todo en un solo lugar.',
                style: context.text.bodyMd.copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: OmniSpacing.xxl),
              Text('¿QUÉ TIPO DE NEGOCIO TIENES?', style: context.text.overline),
              const SizedBox(height: OmniSpacing.md),
              _BusinessCard(
                title: 'Tienda de ropa / Retail',
                subtitle: 'Gestión de tallas, colores y variantes de stock.',
                icon: LucideIcons.shirt,
                color: c.purple,
                onTap: () => _selectType(context, ref, 'retail'),
              ),
              const SizedBox(height: OmniSpacing.md),
              _BusinessCard(
                title: 'Restaurante / Bar',
                subtitle: 'Control de mesas, barra e ingredientes.',
                icon: LucideIcons.utensils,
                color: c.orange,
                onTap: () => _selectType(context, ref, 'fnb'),
              ),
              const SizedBox(height: OmniSpacing.md),
              _BusinessCard(
                title: 'Otro local comercial',
                subtitle: 'Puntos de venta rápidos y servicios.',
                icon: LucideIcons.store,
                color: c.info,
                onTap: () => _selectType(context, ref, 'generic'),
              ),
            ],
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
    return OmniCard(
      onTap: onTap,
      padding: const EdgeInsets.all(OmniSpacing.lg),
      child: Row(
        children: [
          OmniIconAvatar(icon: icon, color: color, size: OmniSizes.avatarLg),
          const SizedBox(width: OmniSpacing.base),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.headingSm),
                const SizedBox(height: OmniSpacing.xs),
                Text(subtitle, style: context.text.bodySm),
              ],
            ),
          ),
          Icon(LucideIcons.chevronRight,
              size: OmniSizes.iconMd, color: context.colors.textMuted),
        ],
      ),
    );
  }
}
