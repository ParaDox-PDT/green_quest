import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:green_quest/app/theme/theme.dart';
import 'package:green_quest/features/menu/presentation/main_menu_screen.dart';
import 'package:green_quest/core/l10n/app_localizations.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _titleOpacity;
  late Animation<double> _ladybugPosition;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.9, curve: Curves.easeIn),
      ),
    );

    // Ladybug crawls slightly into view after the leaf pops in
    _ladybugPosition = Tween<double>(begin: -10.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.elasticOut),
      ),
    );

    _controller.forward().then((_) {
      _navigateToMenu();
    });
  }

  void _navigateToMenu() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const MainMenuScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final title = localizations?.appTitle ?? 'Green Quest';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE8F5E9), // Light mint
              Color(0xFFC8E6C9), // Soft green
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // Decorative background patterns (sunlight beams)
            Positioned.fill(
              child: Opacity(
                opacity: 0.1,
                child: CustomPaint(
                  painter: SunbeamPainter(),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Leaf Logo
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _logoScale.value,
                        child: Opacity(
                          opacity: _logoOpacity.value,
                          child: CustomPaint(
                            size: const Size(160, 160),
                            painter: LeafLogoPainter(
                              ladybugOffset: _ladybugPosition.value,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  // Animated Title
                  AnimatedBuilder(
                    animation: _titleOpacity,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _titleOpacity.value,
                        child: child,
                      );
                    },
                    child: Column(
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.fredoka(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: GameTheme.darkGreen,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                offset: const Offset(0, 4),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 80,
                          height: 4,
                          decoration: BoxDecoration(
                            color: GameTheme.primaryAmber,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Footer text / Version
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Center(
                child: Opacity(
                  opacity: 0.5,
                  child: Text(
                    'v1.0.0',
                    style: GoogleFonts.fredoka(
                      fontSize: 14,
                      color: GameTheme.darkGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom Painter to draw a modern, cute vector leaf and a tiny ladybug
class LeafLogoPainter extends CustomPainter {
  final double ladybugOffset;

  LeafLogoPainter({required this.ladybugOffset});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Leaf main body paint (vibrant green gradient)
    final leafPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF81C784), Color(0xFF2E7D32)],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ).createShader(Rect.fromLTWH(0, 0, width, height))
      ..style = PaintingStyle.fill;

    // Outer thick playful border (to give cartoon/game aesthetic)
    final borderPaint = Paint()
      ..color = const Color(0xFF1B5E20)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final leafPath = Path();
    // Starting at leaf stem tip (bottom-middle)
    leafPath.moveTo(width * 0.5, height * 0.9);

    // Left curve of the leaf
    leafPath.cubicTo(
      width * 0.1, height * 0.7,
      width * 0.1, height * 0.25,
      width * 0.5, height * 0.1,
    );

    // Right curve of the leaf
    leafPath.cubicTo(
      width * 0.9, height * 0.25,
      width * 0.9, height * 0.7,
      width * 0.5, height * 0.9,
    );

    // Draw leaf shadow
    final shadowPath = Path.from(leafPath);
    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Fill leaf body
    canvas.drawPath(leafPath, leafPaint);

    // Draw leaf border
    canvas.drawPath(leafPath, borderPaint);

    // Main Leaf Vein (center line)
    final veinPaint = Paint()
      ..color = const Color(0xFFC8E6C9).withValues(alpha: 0.5)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(width * 0.5, height * 0.9),
      Offset(width * 0.5, height * 0.15),
      veinPaint,
    );

    // Side veins
    canvas.drawLine(
      Offset(width * 0.5, height * 0.7),
      Offset(width * 0.3, height * 0.55),
      veinPaint,
    );
    canvas.drawLine(
      Offset(width * 0.5, height * 0.55),
      Offset(width * 0.7, height * 0.4),
      veinPaint,
    );
    canvas.drawLine(
      Offset(width * 0.5, height * 0.4),
      Offset(width * 0.28, height * 0.3),
      veinPaint,
    );

    // Draw leaf stem at the bottom
    final stemPaint = Paint()
      ..color = const Color(0xFF1B5E20)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(width * 0.5, height * 0.88),
      Offset(width * 0.5, height * 0.98),
      stemPaint,
    );

    // Tiny cute Ladybug crawling on the leaf
    final double lbX = width * 0.65 + (ladybugOffset * 0.5);
    final double lbY = height * 0.45 + (ladybugOffset * 0.8);
    final double lbSize = width * 0.08; // small ladybug

    // Ladybug Shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(lbX + 1, lbY + 2), width: lbSize * 1.1, height: lbSize * 1.1),
      Paint()..color = Colors.black.withValues(alpha: 0.15),
    );

    // Ladybug Body (Red)
    canvas.drawOval(
      Rect.fromCenter(center: Offset(lbX, lbY), width: lbSize, height: lbSize),
      Paint()..color = const Color(0xFFD32F2F),
    );

    // Ladybug Head (Black)
    canvas.drawOval(
      Rect.fromCenter(center: Offset(lbX - lbSize * 0.4, lbY - lbSize * 0.2), width: lbSize * 0.5, height: lbSize * 0.5),
      Paint()..color = const Color(0xFF1A1A1A),
    );

    // Ladybug Line down middle of back
    canvas.drawLine(
      Offset(lbX - lbSize * 0.1, lbY - lbSize * 0.48),
      Offset(lbX + lbSize * 0.4, lbY + lbSize * 0.35),
      Paint()
        ..color = const Color(0xFF1A1A1A)
        ..strokeWidth = 1.5,
    );

    // Ladybug spots (black circles)
    final spotPaint = Paint()..color = const Color(0xFF1A1A1A);
    canvas.drawCircle(Offset(lbX, lbY - lbSize * 0.2), 1.5, spotPaint);
    canvas.drawCircle(Offset(lbX + lbSize * 0.2, lbY - lbSize * 0.1), 1.5, spotPaint);
    canvas.drawCircle(Offset(lbX + lbSize * 0.1, lbY + lbSize * 0.2), 1.5, spotPaint);
  }

  @override
  bool shouldRepaint(covariant LeafLogoPainter oldDelegate) {
    return oldDelegate.ladybugOffset != ladybugOffset;
  }
}

/// Painter to draw subtle sunlight rays in the background
class SunbeamPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.4);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06) // Adjusted opacity for subtle shine
      ..style = PaintingStyle.fill;

    const rayCount = 12;
    final maxRadius = size.longestSide;

    for (int i = 0; i < rayCount; i++) {
      final angle = (i * 2 * math.pi) / rayCount;
      final path = Path();
      path.moveTo(center.dx, center.dy);
      
      // Calculate ray boundaries
      final angle1 = angle - 0.12;
      final angle2 = angle + 0.12;

      path.lineTo(
        center.dx + maxRadius * math.cos(angle1),
        center.dy + maxRadius * math.sin(angle1),
      );
      path.lineTo(
        center.dx + maxRadius * math.cos(angle2),
        center.dy + maxRadius * math.sin(angle2),
      );
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant SunbeamPainter oldDelegate) => false;
}

