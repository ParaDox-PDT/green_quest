import 'package:flutter/material.dart';
import 'package:green_quest/features/menu/domain/providers/character_provider.dart';

class CharacterVectorWidget extends StatelessWidget {
  final GameCharacter character;
  final double size;

  const CharacterVectorWidget({
    super.key,
    required this.character,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _getPainter(character),
    );
  }

  CustomPainter _getPainter(GameCharacter character) {
    switch (character) {
      case GameCharacter.fox:
        return FoxPainter();
      case GameCharacter.rabbit:
        return RabbitPainter();
      case GameCharacter.bear:
        return BearPainter();
      case GameCharacter.squirrel:
        return SquirrelPainter();
    }
  }
}

/// Helper method to draw cartoonish eyes with highlight reflections
void drawCartoonEyes(Canvas canvas, double cx, double cy, double eyeSpacing, double eyeRadius) {
  final eyePaint = Paint()..color = const Color(0xFF212121);
  final shinePaint = Paint()..color = Colors.white;

  // Left Eye
  canvas.drawCircle(Offset(cx - eyeSpacing, cy), eyeRadius, eyePaint);
  canvas.drawCircle(Offset(cx - eyeSpacing - eyeRadius * 0.3, cy - eyeRadius * 0.3), eyeRadius * 0.3, shinePaint);
  canvas.drawCircle(Offset(cx - eyeSpacing + eyeRadius * 0.2, cy + eyeRadius * 0.2), eyeRadius * 0.15, shinePaint);

  // Right Eye
  canvas.drawCircle(Offset(cx + eyeSpacing, cy), eyeRadius, eyePaint);
  canvas.drawCircle(Offset(cx + eyeSpacing - eyeRadius * 0.3, cy - eyeRadius * 0.3), eyeRadius * 0.3, shinePaint);
  canvas.drawCircle(Offset(cx + eyeSpacing + eyeRadius * 0.2, cy + eyeRadius * 0.2), eyeRadius * 0.15, shinePaint);
}

/// Helper to draw a cute pink blush on cheeks
void drawBlush(Canvas canvas, double cx, double cy, double spacing, double radius) {
  final blushPaint = Paint()
    ..color = const Color(0xFFFF8A80).withValues(alpha: 0.4)
    ..style = PaintingStyle.fill;
  canvas.drawCircle(Offset(cx - spacing, cy), radius, blushPaint);
  canvas.drawCircle(Offset(cx + spacing, cy), radius, blushPaint);
}

/// 1. FOX PAINTER
class FoxPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Shadow
    canvas.drawOval(
      Rect.fromLTRB(w * 0.1, h * 0.8, w * 0.9, h * 0.95),
      Paint()..color = Colors.black.withValues(alpha: 0.1),
    );

    // 2. Ears
    final orangePaint = Paint()..color = const Color(0xFFFF7043);
    final whitePaint = Paint()..color = Colors.white;
    final blackPaint = Paint()..color = const Color(0xFF212121);

    // Left Ear
    final leftEar = Path()
      ..moveTo(w * 0.15, h * 0.45)
      ..lineTo(w * 0.1, h * 0.1)
      ..lineTo(w * 0.45, h * 0.35)
      ..close();
    canvas.drawPath(leftEar, orangePaint);
    
    // Left Inner Ear
    final leftInnerEar = Path()
      ..moveTo(w * 0.2, h * 0.4)
      ..lineTo(w * 0.15, h * 0.18)
      ..lineTo(w * 0.38, h * 0.33)
      ..close();
    canvas.drawPath(leftInnerEar, whitePaint);

    // Right Ear
    final rightEar = Path()
      ..moveTo(w * 0.85, h * 0.45)
      ..lineTo(w * 0.9, h * 0.1)
      ..lineTo(w * 0.55, h * 0.35)
      ..close();
    canvas.drawPath(rightEar, orangePaint);

    // Right Inner Ear
    final rightInnerEar = Path()
      ..moveTo(w * 0.8, h * 0.4)
      ..lineTo(w * 0.85, h * 0.18)
      ..lineTo(w * 0.62, h * 0.33)
      ..close();
    canvas.drawPath(rightInnerEar, whitePaint);

    // Ear Tips (Black)
    final leftTip = Path()
      ..moveTo(w * 0.1, h * 0.1)
      ..lineTo(w * 0.12, h * 0.22)
      ..lineTo(w * 0.2, h * 0.18)
      ..close();
    canvas.drawPath(leftTip, blackPaint);

    final rightTip = Path()
      ..moveTo(w * 0.9, h * 0.1)
      ..lineTo(w * 0.88, h * 0.22)
      ..lineTo(w * 0.8, h * 0.18)
      ..close();
    canvas.drawPath(rightTip, blackPaint);

    // 3. Face Body (Orange)
    canvas.drawCircle(Offset(w * 0.5, h * 0.55), w * 0.35, orangePaint);

    // 4. White Muzzle/Cheeks (Triangle/Heart shape path)
    final leftMuzzle = Path()
      ..moveTo(w * 0.15, h * 0.55)
      ..quadraticBezierTo(w * 0.2, h * 0.8, w * 0.5, h * 0.85)
      ..quadraticBezierTo(w * 0.35, h * 0.55, w * 0.5, h * 0.55)
      ..close();
    canvas.drawPath(leftMuzzle, whitePaint);

    final rightMuzzle = Path()
      ..moveTo(w * 0.85, h * 0.55)
      ..quadraticBezierTo(w * 0.8, h * 0.8, w * 0.5, h * 0.85)
      ..quadraticBezierTo(w * 0.65, h * 0.55, w * 0.5, h * 0.55)
      ..close();
    canvas.drawPath(rightMuzzle, whitePaint);

    // 5. Draw Eyes
    drawCartoonEyes(canvas, w * 0.5, h * 0.48, w * 0.15, w * 0.05);

    // 6. Blush
    drawBlush(canvas, w * 0.5, h * 0.58, w * 0.22, w * 0.04);

    // 7. Nose (Black oval at the bottom center of the face)
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.76), width: w * 0.12, height: h * 0.08),
      blackPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 2. RABBIT PAINTER
class RabbitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Shadow
    canvas.drawOval(
      Rect.fromLTRB(w * 0.1, h * 0.85, w * 0.9, h * 0.98),
      Paint()..color = Colors.black.withValues(alpha: 0.1),
    );

    const baseColor = Color(0xFFB39DDB); // Soft lavender/purple
    const innerEarColor = Color(0xFFFF8A80); // Coral pink
    const white = Colors.white;
    const dark = Color(0xFF212121);

    // 2. Ears
    final earPaint = Paint()..color = baseColor;
    final innerEarPaint = Paint()..color = innerEarColor;

    // Left Ear
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.35, h * 0.25), width: w * 0.14, height: h * 0.45),
      earPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.35, h * 0.27), width: w * 0.08, height: h * 0.35),
      innerEarPaint,
    );

    // Right Ear
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.65, h * 0.25), width: w * 0.14, height: h * 0.45),
      earPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.65, h * 0.27), width: w * 0.08, height: h * 0.35),
      innerEarPaint,
    );

    // 3. Head (Lavender)
    canvas.drawCircle(Offset(w * 0.5, h * 0.63), w * 0.32, earPaint);

    // 4. White Muzzle (Under nose)
    final muzzlePaint = Paint()..color = white;
    canvas.drawCircle(Offset(w * 0.44, h * 0.7), w * 0.09, muzzlePaint);
    canvas.drawCircle(Offset(w * 0.56, h * 0.7), w * 0.09, muzzlePaint);

    // 5. Buckteeth
    final teethPaint = Paint()
      ..color = white
      ..style = PaintingStyle.fill;
    final teethBorder = Paint()
      ..color = dark
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final teethRect = Rect.fromLTWH(w * 0.46, h * 0.75, w * 0.08, h * 0.07);
    canvas.drawRRect(RRect.fromRectAndRadius(teethRect, const Radius.circular(3)), teethPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(teethRect, const Radius.circular(3)), teethBorder);
    
    // Line splitting the two teeth
    canvas.drawLine(Offset(w * 0.5, h * 0.75), Offset(w * 0.5, h * 0.82), teethBorder);

    // 6. Eyes
    drawCartoonEyes(canvas, w * 0.5, h * 0.56, w * 0.14, w * 0.065);

    // 7. Blush
    drawBlush(canvas, w * 0.5, h * 0.67, w * 0.20, w * 0.045);

    // 8. Nose (Pink Triangle)
    final Path nosePath = Path()
      ..moveTo(w * 0.46, h * 0.66)
      ..lineTo(w * 0.54, h * 0.66)
      ..lineTo(w * 0.5, h * 0.71)
      ..close();
    canvas.drawPath(nosePath, innerEarPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3. BEAR PAINTER
class BearPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Shadow
    canvas.drawOval(
      Rect.fromLTRB(w * 0.1, h * 0.82, w * 0.9, h * 0.95),
      Paint()..color = Colors.black.withValues(alpha: 0.1),
    );

    const brown = Color(0xFF8D6E63);
    const cream = Color(0xFFFFECB3);
    const black = Color(0xFF212121);

    // 2. Ears
    final earPaint = Paint()..color = brown;
    final innerEarPaint = Paint()..color = cream;

    // Left Ear
    canvas.drawCircle(Offset(w * 0.24, h * 0.35), w * 0.12, earPaint);
    canvas.drawCircle(Offset(w * 0.24, h * 0.35), w * 0.07, innerEarPaint);

    // Right Ear
    canvas.drawCircle(Offset(w * 0.76, h * 0.35), w * 0.12, earPaint);
    canvas.drawCircle(Offset(w * 0.76, h * 0.35), w * 0.07, innerEarPaint);

    // 3. Head (Brown)
    canvas.drawCircle(Offset(w * 0.5, h * 0.6), w * 0.34, earPaint);

    // 4. Cream Muzzle
    final muzzlePaint = Paint()..color = cream;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.7), width: w * 0.24, height: h * 0.18),
      muzzlePaint,
    );

    // 5. Nose & Smile
    canvas.drawCircle(Offset(w * 0.5, h * 0.66), w * 0.05, Paint()..color = black);
    
    // Draw small curved smile
    final mouthPaint = Paint()
      ..color = black
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.71), width: w * 0.08, height: h * 0.06),
      0,
      3.1415,
      false,
      mouthPaint,
    );

    // 6. Eyes
    drawCartoonEyes(canvas, w * 0.5, h * 0.52, w * 0.15, w * 0.045);

    // 7. Blush
    drawBlush(canvas, w * 0.5, h * 0.62, w * 0.22, w * 0.04);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 4. SQUIRREL PAINTER
class SquirrelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Shadow
    canvas.drawOval(
      Rect.fromLTRB(w * 0.1, h * 0.85, w * 0.9, h * 0.98),
      Paint()..color = Colors.black.withValues(alpha: 0.1),
    );

    const golden = Color(0xFFFFB74D); // Golden orange
    const white = Colors.white;
    const dark = Color(0xFF4E342E); // Dark wood brown nose/details

    // 2. Pointy Ears with Fluffy Tuft/Stroke
    final earPaint = Paint()..color = golden;
    final tuftPaint = Paint()
      ..color = dark
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Left Ear
    final leftEar = Path()
      ..moveTo(w * 0.22, h * 0.45)
      ..lineTo(w * 0.2, h * 0.15)
      ..lineTo(w * 0.42, h * 0.38)
      ..close();
    canvas.drawPath(leftEar, earPaint);
    
    // Ear tuft hairs
    canvas.drawLine(Offset(w * 0.2, h * 0.15), Offset(w * 0.16, h * 0.10), tuftPaint);
    canvas.drawLine(Offset(w * 0.2, h * 0.15), Offset(w * 0.22, h * 0.09), tuftPaint);

    // Right Ear
    final rightEar = Path()
      ..moveTo(w * 0.78, h * 0.45)
      ..lineTo(w * 0.8, h * 0.15)
      ..lineTo(w * 0.58, h * 0.38)
      ..close();
    canvas.drawPath(rightEar, earPaint);

    // Ear tuft hairs
    canvas.drawLine(Offset(w * 0.8, h * 0.15), Offset(w * 0.84, h * 0.10), tuftPaint);
    canvas.drawLine(Offset(w * 0.8, h * 0.15), Offset(w * 0.78, h * 0.09), tuftPaint);

    // 3. Head Body (Golden Orange)
    canvas.drawCircle(Offset(w * 0.5, h * 0.62), w * 0.31, earPaint);

    // 4. Cheek Fluff (Cream)
    final cheekPaint = Paint()..color = white;
    canvas.drawCircle(Offset(w * 0.42, h * 0.70), w * 0.09, cheekPaint);
    canvas.drawCircle(Offset(w * 0.58, h * 0.70), w * 0.09, cheekPaint);

    // 5. Squirrel Tooth (single bucktooth)
    canvas.drawRect(
      Rect.fromLTWH(w * 0.485, h * 0.74, w * 0.03, h * 0.05),
      Paint()..color = white,
    );
    canvas.drawRect(
      Rect.fromLTWH(w * 0.485, h * 0.74, w * 0.03, h * 0.05),
      Paint()
        ..color = dark
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );

    // 6. Eyes (Large and cute brown/black)
    drawCartoonEyes(canvas, w * 0.5, h * 0.55, w * 0.13, w * 0.055);

    // 7. Blush
    drawBlush(canvas, w * 0.5, h * 0.65, w * 0.20, w * 0.04);

    // 8. Nose (Tiny dark oval)
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.67), width: w * 0.06, height: h * 0.04),
      Paint()..color = dark,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
