import 'package:flutter/material.dart';

class BalatroButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color color;
  final double width;
  final double height;

  const BalatroButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.color = const Color(0xFFE53935),
    this.width = double.infinity,
    this.height = 60,
  });

  @override
  State<BalatroButton> createState() => _BalatroButtonState();
}

class _BalatroButtonState extends State<BalatroButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null;
    final baseColor = isDisabled ? Colors.grey[800]! : widget.color;
    final darkerColor = HSLColor.fromColor(baseColor).withLightness((HSLColor.fromColor(baseColor).lightness - 0.2).clamp(0.0, 1.0)).toColor();

    return GestureDetector(
      onTapDown: isDisabled ? null : (_) => setState(() => _isPressed = true),
      onTapUp: isDisabled ? null : (_) {
        setState(() => _isPressed = false);
        widget.onPressed!();
      },
      onTapCancel: isDisabled ? null : () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 50),
        width: widget.width,
        height: widget.height,
        margin: EdgeInsets.only(top: _isPressed ? 6 : 0, bottom: _isPressed ? 0 : 6),
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: _isPressed
              ? []
              : [
                  BoxShadow(
                    color: darkerColor,
                    offset: const Offset(0, 6),
                  ),
                  const BoxShadow(
                    color: Colors.black54,
                    offset: Offset(0, 8),
                    blurRadius: 4,
                  )
                ],
        ),
        child: Center(
          child: DefaultTextStyle(
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              shadows: [
                Shadow(color: Colors.black87, offset: Offset(2, 2)),
              ]
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
