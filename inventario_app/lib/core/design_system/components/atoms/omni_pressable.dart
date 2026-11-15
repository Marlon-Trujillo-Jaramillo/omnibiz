import 'package:flutter/widgets.dart';
import '../../tokens/omni_sizes.dart';

/// Hunde levemente a [child] mientras se presiona (feedback táctil visual).
/// Usa un [Listener], así no compite con los gestos del hijo.
class OmniPressable extends StatefulWidget {
  const OmniPressable({
    super.key,
    required this.child,
    this.enabled = true,
    this.scale = 0.97,
  });

  final Widget child;
  final bool enabled;

  /// Escala mientras está presionado.
  final double scale;

  @override
  State<OmniPressable> createState() => _OmniPressableState();
}

class _OmniPressableState extends State<OmniPressable> {
  bool _down = false;

  void _set(bool down) {
    if (!widget.enabled && down) return;
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: OmniMotion.fast,
        curve: OmniMotion.standard,
        child: widget.child,
      ),
    );
  }
}
