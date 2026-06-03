import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:green_quest/app/theme/theme.dart';

class AnimatedDice extends StatefulWidget {
  final int value;
  final bool isRolling;
  final VoidCallback? onTap;

  const AnimatedDice({
    super.key,
    required this.value,
    required this.isRolling,
    this.onTap,
  });

  @override
  State<AnimatedDice> createState() => _AnimatedDiceState();
}

class _AnimatedDiceState extends State<AnimatedDice> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotation;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // Roll rotation: multiple full spins
    _rotation = Tween<double>(begin: 0, end: 6 * math.pi).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutBack,
      ),
    );

    // Bouncing scale effect (shrinks slightly, pops up, settles)
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.85), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 0.85, end: 1.25), weight: 40),
      TweenSequenceItem(tween: Tween<double>(begin: 1.25, end: 0.95), weight: 25),
      TweenSequenceItem(tween: Tween<double>(begin: 0.95, end: 1.0), weight: 15),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant AnimatedDice oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRolling && !oldWidget.isRolling) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.onTap != null && !widget.isRolling;

    return GestureDetector(
      onTap: active ? widget.onTap : null,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // Rapidly cycle/flicker faces while rolling to create a spin effect
          int displayValue = widget.value;
          if (widget.isRolling) {
            final cycle = (_controller.value * 24).toInt() % 6 + 1;
            displayValue = cycle;
          }

          return Transform.translate(
            // Bounce jump height (up to 20 pixels)
            offset: Offset(0, widget.isRolling ? -25 * math.sin(_controller.value * math.pi) : 0),
            child: Transform.rotate(
              angle: _rotation.value,
              child: Transform.scale(
                scale: _scale.value,
                child: MouseRegion(
                  cursor: active ? SystemMouseCursors.click : SystemMouseCursors.basic,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: active ? GameTheme.primaryAmber : const Color(0xFF8D6E63),
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                        if (active)
                          BoxShadow(
                            color: GameTheme.primaryAmber.withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 0),
                            spreadRadius: 2,
                          )
                      ],
                    ),
                    padding: const EdgeInsets.all(8.0),
                    child: CustomPaint(
                      painter: DiceFacePainter(value: displayValue),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Custom Painter to draw standard 6-sided dice dots
class DiceFacePainter extends CustomPainter {
  final int value;

  DiceFacePainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Dot paint colors: Red for 1 (Japanese custom, cute), Black for others
    final Color dotColor = (value == 1) ? const Color(0xFFD32F2F) : const Color(0xFF212121);
    final dotPaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    // Define dot coordinates
    final double left = w * 0.22;
    final double center = w * 0.5;
    final double right = w * 0.78;

    final double top = h * 0.22;
    final double middle = h * 0.5;
    final double bottom = h * 0.78;

    final double dotRadius = (value == 1) ? w * 0.16 : w * 0.08;

    switch (value) {
      case 1:
        canvas.drawCircle(Offset(center, middle), dotRadius, dotPaint);
        break;
      case 2:
        canvas.drawCircle(Offset(left, top), dotRadius, dotPaint);
        canvas.drawCircle(Offset(right, bottom), dotRadius, dotPaint);
        break;
      case 3:
        canvas.drawCircle(Offset(left, top), dotRadius, dotPaint);
        canvas.drawCircle(Offset(center, middle), dotRadius, dotPaint);
        canvas.drawCircle(Offset(right, bottom), dotRadius, dotPaint);
        break;
      case 4:
        canvas.drawCircle(Offset(left, top), dotRadius, dotPaint);
        canvas.drawCircle(Offset(right, top), dotRadius, dotPaint);
        canvas.drawCircle(Offset(left, bottom), dotRadius, dotPaint);
        canvas.drawCircle(Offset(right, bottom), dotRadius, dotPaint);
        break;
      case 5:
        canvas.drawCircle(Offset(left, top), dotRadius, dotPaint);
        canvas.drawCircle(Offset(right, top), dotRadius, dotPaint);
        canvas.drawCircle(Offset(center, middle), dotRadius, dotPaint);
        canvas.drawCircle(Offset(left, bottom), dotRadius, dotPaint);
        canvas.drawCircle(Offset(right, bottom), dotRadius, dotPaint);
        break;
      case 6:
        canvas.drawCircle(Offset(left, top), dotRadius, dotPaint);
        canvas.drawCircle(Offset(right, top), dotRadius, dotPaint);
        canvas.drawCircle(Offset(left, middle), dotRadius, dotPaint);
        canvas.drawCircle(Offset(right, middle), dotRadius, dotPaint);
        canvas.drawCircle(Offset(left, bottom), dotRadius, dotPaint);
        canvas.drawCircle(Offset(right, bottom), dotRadius, dotPaint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant DiceFacePainter oldDelegate) {
    return oldDelegate.value != value;
  }
}
