import 'package:flutter/material.dart';

/// Smooth spring cursor hover & press pop micro-interaction wrapper.
/// Uses MouseRegion (desktop/web pointer hover) and Listener (tactile tap press
/// without competing in the gesture arena with child InkWells or Buttons).
class HoverPop extends StatefulWidget {
  final Widget child;
  final double hoverScale;
  final double pressScale;
  final double slideX;
  final Duration duration;
  final BorderRadius? borderRadius;

  const HoverPop({
    super.key,
    required this.child,
    this.hoverScale = 1.03,
    this.pressScale = 0.97,
    this.slideX = 0.0,
    this.duration = const Duration(milliseconds: 200),
    this.borderRadius,
  });

  @override
  State<HoverPop> createState() => _HoverPopState();
}

class _HoverPopState extends State<HoverPop> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final targetScale = _pressed
        ? widget.pressScale
        : (_hovered ? widget.hoverScale : 1.0);

    Widget content = AnimatedScale(
      scale: targetScale,
      duration: widget.duration,
      curve: _pressed ? Curves.easeOut : Curves.easeOutBack,
      child: widget.child,
    );

    if (widget.slideX != 0.0) {
      content = AnimatedSlide(
        offset: Offset(_hovered && !_pressed ? widget.slideX : 0.0, 0.0),
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        child: content,
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => setState(() => _pressed = true),
        onPointerUp: (_) => setState(() => _pressed = false),
        onPointerCancel: (_) => setState(() => _pressed = false),
        child: content,
      ),
    );
  }
}
