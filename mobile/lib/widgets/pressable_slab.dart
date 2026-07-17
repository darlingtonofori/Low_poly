import 'package:flutter/material.dart';

/// A button that looks like a physical arcade button: a solid color slab
/// sits behind the face, and the face slides down onto it on tap, like it's
/// actually being pressed. Used for game cards and primary CTAs.
class PressableSlab extends StatefulWidget {
  final Widget child;
  final Color faceColor;
  final Color shadowColor;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;
  final double pressDepth;

  const PressableSlab({
    super.key,
    required this.child,
    required this.faceColor,
    required this.shadowColor,
    this.onTap,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.pressDepth = 6,
  });

  @override
  State<PressableSlab> createState() => _PressableSlabState();
}

class _PressableSlabState extends State<PressableSlab> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: _pressed ? 1 : widget.pressDepth),
        decoration: BoxDecoration(
          color: widget.shadowColor,
          borderRadius: widget.borderRadius,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          margin: EdgeInsets.only(bottom: _pressed ? widget.pressDepth - 1 : 0),
          decoration: BoxDecoration(
            color: widget.faceColor,
            borderRadius: widget.borderRadius,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
