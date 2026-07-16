import 'package:flutter/material.dart';

abstract final class OmniBreakpoints {
  static const double tablet  = 600;
  static const double desktop = 900;
}

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  bool get isTablet  => screenWidth >= OmniBreakpoints.tablet;
  bool get isDesktop => screenWidth >= OmniBreakpoints.desktop;
}

/// Centers content on tablet/desktop with an optional max width.
class OmniResponsiveCenter extends StatelessWidget {
  const OmniResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = OmniBreakpoints.desktop,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
