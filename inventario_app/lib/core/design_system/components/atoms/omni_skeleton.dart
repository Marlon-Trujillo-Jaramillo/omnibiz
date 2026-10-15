import 'package:flutter/material.dart';
import '../../theme/omni_theme_extensions.dart';
import '../../tokens/omni_radius.dart';
import '../../tokens/omni_sizes.dart';
import '../../tokens/omni_spacing.dart';

/// Bloque de carga con brillo animado. Un solo controlador por [OmniShimmer]
/// sincroniza todos los bloques de debajo.
class OmniSkeleton extends StatelessWidget {
  const OmniSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.radius,
    this.circle = false,
  });

  final double? width;
  final double height;
  final double? radius;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = _ShimmerScope.maybeOf(context);
    final borderRadius = circle
        ? OmniRadius.fullAll
        : BorderRadius.circular(radius ?? OmniRadius.sm);

    Widget block(double v) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: LinearGradient(
              begin: Alignment(v - 1, 0),
              end: Alignment(v + 1, 0),
              colors: [c.bgRaised, c.borderMuted, c.bgRaised],
            ),
          ),
        );

    if (t == null) return _StandaloneShimmer(builder: block);
    return AnimatedBuilder(animation: t, builder: (_, __) => block(t.value));
  }
}

/// Comparte una animación de brillo entre los [OmniSkeleton] descendientes.
class OmniShimmer extends StatefulWidget {
  const OmniShimmer({super.key, required this.child});
  final Widget child;

  @override
  State<OmniShimmer> createState() => _OmniShimmerState();
}

class _OmniShimmerState extends State<OmniShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: OmniMotion.shimmer)..repeat();
  late final Animation<double> _anim = Tween<double>(begin: -2, end: 2)
      .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _ShimmerScope(animation: _anim, child: widget.child);
}

class _ShimmerScope extends InheritedWidget {
  const _ShimmerScope({required this.animation, required super.child});
  final Animation<double> animation;

  static Animation<double>? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_ShimmerScope>()
      ?.animation;

  @override
  bool updateShouldNotify(_ShimmerScope old) => old.animation != animation;
}

class _StandaloneShimmer extends StatelessWidget {
  const _StandaloneShimmer({required this.builder});
  final Widget Function(double) builder;

  @override
  Widget build(BuildContext context) => OmniShimmer(
        child: Builder(
          builder: (ctx) {
            final t = _ShimmerScope.maybeOf(ctx)!;
            return AnimatedBuilder(
                animation: t, builder: (_, __) => builder(t.value));
          },
        ),
      );
}

// ── Composites ────────────────────────────────────────────────────────────────

BoxDecoration _cardDecoration(BuildContext context) {
  final c = context.colors;
  return BoxDecoration(
    color: c.bgSurface,
    borderRadius: OmniRadius.lgAll,
    border: Border.all(color: c.borderSubtle),
  );
}

/// Fila de lista en carga (avatar + dos líneas + monto).
class OmniSkeletonTile extends StatelessWidget {
  const OmniSkeletonTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(OmniSpacing.base),
      decoration: _cardDecoration(context),
      child: const Row(
        children: [
          OmniSkeleton(
              width: OmniSizes.avatarSm + 4,
              height: OmniSizes.avatarSm + 4,
              radius: OmniRadius.md),
          SizedBox(width: OmniSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FractionallySizedBox(
                    widthFactor: 0.6, child: OmniSkeleton(height: 13)),
                SizedBox(height: OmniSpacing.sm),
                FractionallySizedBox(
                    widthFactor: 0.35, child: OmniSkeleton(height: 10)),
              ],
            ),
          ),
          SizedBox(width: OmniSpacing.md),
          OmniSkeleton(width: 64, height: 14),
        ],
      ),
    );
  }
}

class OmniSkeletonList extends StatelessWidget {
  const OmniSkeletonList({super.key, this.count = 6, this.padding});
  final int count;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return OmniShimmer(
      child: ListView.separated(
        padding: padding ?? const EdgeInsets.all(OmniSpacing.base),
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(height: OmniSpacing.sm),
        itemBuilder: (_, __) => const OmniSkeletonTile(),
      ),
    );
  }
}

/// Tarjeta de producto en carga (grilla del POS).
class OmniSkeletonCard extends StatelessWidget {
  const OmniSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(OmniSpacing.md),
      decoration: _cardDecoration(context),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OmniSkeleton(
              width: OmniSizes.avatarSm,
              height: OmniSizes.avatarSm,
              radius: OmniRadius.md),
          Spacer(),
          FractionallySizedBox(
              widthFactor: 0.8, child: OmniSkeleton(height: 13)),
          SizedBox(height: OmniSpacing.sm),
          FractionallySizedBox(
              widthFactor: 0.45, child: OmniSkeleton(height: 18)),
        ],
      ),
    );
  }
}

/// Grilla de tarjetas en carga.
class OmniSkeletonGrid extends StatelessWidget {
  const OmniSkeletonGrid({
    super.key,
    this.count = 8,
    required this.crossAxisCount,
    this.childAspectRatio = 1,
    this.padding = const EdgeInsets.all(OmniSpacing.base),
  });

  final int count;
  final int crossAxisCount;
  final double childAspectRatio;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return OmniShimmer(
      child: GridView.builder(
        padding: padding,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: OmniSpacing.md,
          mainAxisSpacing: OmniSpacing.md,
          childAspectRatio: childAspectRatio,
        ),
        itemCount: count,
        itemBuilder: (_, __) => const OmniSkeletonCard(),
      ),
    );
  }
}
