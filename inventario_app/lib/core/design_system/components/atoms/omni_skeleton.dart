import 'package:flutter/material.dart';
import '../../tokens/omni_colors.dart';
import '../../tokens/omni_radius.dart';
import '../../tokens/omni_spacing.dart';

class OmniSkeleton extends StatefulWidget {
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
  State<OmniSkeleton> createState() => _OmniSkeletonState();
}

class _OmniSkeletonState extends State<OmniSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _anim = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = widget.circle
        ? BorderRadius.circular(OmniRadius.full)
        : BorderRadius.circular(widget.radius ?? OmniRadius.md);

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          gradient: LinearGradient(
            begin: Alignment(_anim.value - 1, 0),
            end: Alignment(_anim.value + 1, 0),
            colors: const [
              OmniColors.bgSurface,
              OmniColors.borderMuted,
              OmniColors.bgSurface,
            ],
          ),
        ),
      ),
    );
  }
}

// ── Composites ────────────────────────────────────────────────────────────────

class OmniSkeletonTile extends StatelessWidget {
  const OmniSkeletonTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(OmniSpacing.base),
      decoration: BoxDecoration(
        color: OmniColors.bgSurface,
        borderRadius: OmniRadius.lgAll,
        border: Border.all(color: OmniColors.borderSubtle),
      ),
      child: const Row(
        children: [
          OmniSkeleton(width: 40, height: 40, circle: true),
          SizedBox(width: OmniSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OmniSkeleton(width: 140, height: 13),
                SizedBox(height: OmniSpacing.xs),
                OmniSkeleton(width: 90, height: 11),
              ],
            ),
          ),
          OmniSkeleton(width: 60, height: 13),
        ],
      ),
    );
  }
}

class OmniSkeletonList extends StatelessWidget {
  const OmniSkeletonList({super.key, this.count = 6});
  final int count;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(OmniSpacing.base),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: OmniSpacing.sm),
      itemBuilder: (_, __) => const OmniSkeletonTile(),
    );
  }
}
