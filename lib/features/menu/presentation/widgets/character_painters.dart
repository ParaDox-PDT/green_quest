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

/// Reusable helper to draw a 3D board game pawn/token base and columns
void drawTokenBaseAndColumn(Canvas canvas, Size size, Color baseColor) {
  final w = size.width;
  final h = size.height;

  // Calculate shading values (darker shade for rim, lighter shade for highlight)
  final hsv = HSVColor.fromColor(baseColor);
  final darkColor = hsv.withValue(hsv.value * 0.65).toColor();
  final lightColor = hsv.withValue(hsv.value * 1.15 > 1.0 ? 1.0 : hsv.value * 1.15).toColor();

  // 1. Pawn Shadow
  canvas.drawOval(
    Rect.fromLTRB(w * 0.15, h * 0.82, w * 0.85, h * 0.96),
    Paint()..color = Colors.black.withValues(alpha: 0.12),
  );

  // 2. Lower Base Rim (creates thickness)
  final baseRimPaint = Paint()
    ..shader = LinearGradient(
      colors: [darkColor, baseColor],
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    ).createShader(Rect.fromLTRB(w * 0.18, h * 0.76, w * 0.82, h * 0.90))
    ..style = PaintingStyle.fill;
  canvas.drawOval(
    Rect.fromLTRB(w * 0.18, h * 0.76, w * 0.82, h * 0.90),
    baseRimPaint,
  );

  // 3. Upper Base Ring (slanted inset)
  final baseTopPaint = Paint()
    ..shader = LinearGradient(
      colors: [baseColor, lightColor],
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    ).createShader(Rect.fromLTRB(w * 0.22, h * 0.72, w * 0.78, h * 0.82))
    ..style = PaintingStyle.fill;
  canvas.drawOval(
    Rect.fromLTRB(w * 0.22, h * 0.72, w * 0.78, h * 0.82),
    baseTopPaint,
  );

  // 4. Figurine Pillar/Column
  final bodyPaint = Paint()
    ..shader = LinearGradient(
      colors: [darkColor, baseColor, lightColor],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ).createShader(Rect.fromLTRB(w * 0.3, h * 0.44, w * 0.7, h * 0.75))
    ..style = PaintingStyle.fill;

  final bodyPath = Path()
    ..moveTo(w * 0.32, h * 0.75)
    ..quadraticBezierTo(w * 0.43, h * 0.58, w * 0.38, h * 0.45)
    ..lineTo(w * 0.62, h * 0.45)
    ..quadraticBezierTo(w * 0.57, h * 0.58, w * 0.68, h * 0.75)
    ..close();
  canvas.drawPath(bodyPath, bodyPaint);

  // 5. Neck Ring (Figurine Collar)
  final collarPaint = Paint()
    ..shader = LinearGradient(
      colors: [darkColor, lightColor],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromLTRB(w * 0.34, h * 0.41, w * 0.66, h * 0.46))
    ..style = PaintingStyle.fill;
  canvas.drawOval(
    Rect.fromLTRB(w * 0.34, h * 0.41, w * 0.66, h * 0.46),
    collarPaint,
  );
}

/// 1. FOX FIGURINE PAINTER
class FoxPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    const baseColor = Color(0xFFFF7043); // Orange
    final orangePaint = Paint()..color = baseColor;
    final whitePaint = Paint()..color = Colors.white;
    final blackPaint = Paint()..color = const Color(0xFF212121);

    // 1. Draw Pawn Base & Column
    drawTokenBaseAndColumn(canvas, size, baseColor);

    // 2. Fox Head sits on top of column (center at h * 0.35)
    final double hx = w * 0.5;
    final double hy = h * 0.35;
    final double hr = w * 0.23; // Head radius

    // Fox Ears
    final leftEar = Path()
      ..moveTo(hx - hr * 0.8, hy - hr * 0.3)
      ..lineTo(hx - hr * 1.1, hy - hr * 1.2)
      ..lineTo(hx - hr * 0.1, hy - hr * 0.8)
      ..close();
    canvas.drawPath(leftEar, orangePaint);
    
    final leftInnerEar = Path()
      ..moveTo(hx - hr * 0.7, hy - hr * 0.4)
      ..lineTo(hx - hr * 0.95, hy - hr * 1.0)
      ..lineTo(hx - hr * 0.25, hy - hr * 0.7)
      ..close();
    canvas.drawPath(leftInnerEar, whitePaint);

    final rightEar = Path()
      ..moveTo(hx + hr * 0.8, hy - hr * 0.3)
      ..lineTo(hx + hr * 1.1, hy - hr * 1.2)
      ..lineTo(hx + hr * 0.1, hy - hr * 0.8)
      ..close();
    canvas.drawPath(rightEar, orangePaint);

    final rightInnerEar = Path()
      ..moveTo(hx + hr * 0.7, hy - hr * 0.4)
      ..lineTo(hx + hr * 0.95, hy - hr * 1.0)
      ..lineTo(hx + hr * 0.25, hy - hr * 0.7)
      ..close();
    canvas.drawPath(rightInnerEar, whitePaint);

    // Ear Tips (Black)
    final leftTip = Path()
      ..moveTo(hx - hr * 1.1, hy - hr * 1.2)
      ..lineTo(hx - hr * 1.0, hy - hr * 0.9)
      ..lineTo(hx - hr * 0.8, hy - hr * 1.0)
      ..close();
    canvas.drawPath(leftTip, blackPaint);

    final rightTip = Path()
      ..moveTo(hx + hr * 1.1, hy - hr * 1.2)
      ..lineTo(hx + hr * 1.0, hy - hr * 0.9)
      ..lineTo(hx + hr * 0.8, hy - hr * 1.0)
      ..close();
    canvas.drawPath(rightTip, blackPaint);

    // Head circle
    canvas.drawCircle(Offset(hx, hy), hr, orangePaint);

    // White Cheeks/Muzzle inside head
    final leftMuzzle = Path()
      ..moveTo(hx - hr, hy)
      ..quadraticBezierTo(hx - hr * 0.8, hy + hr * 0.8, hx, hy + hr * 0.9)
      ..quadraticBezierTo(hx - hr * 0.4, hy + hr * 0.1, hx, hy)
      ..close();
    canvas.drawPath(leftMuzzle, whitePaint);

    final rightMuzzle = Path()
      ..moveTo(hx + hr, hy)
      ..quadraticBezierTo(hx + hr * 0.8, hy + hr * 0.8, hx, hy + hr * 0.9)
      ..quadraticBezierTo(hx + hr * 0.4, hy + hr * 0.1, hx, hy)
      ..close();
    canvas.drawPath(rightMuzzle, whitePaint);

    // Eyes
    drawCartoonEyes(canvas, hx, hy - hr * 0.1, hr * 0.45, hr * 0.16);

    // Blush
    drawBlush(canvas, hx, hy + hr * 0.2, hr * 0.6, hr * 0.11);

    // Nose
    canvas.drawOval(
      Rect.fromCenter(center: Offset(hx, hy + hr * 0.6), width: hr * 0.35, height: hr * 0.22),
      blackPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 2. RABBIT FIGURINE PAINTER
class RabbitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    const baseColor = Color(0xFFB39DDB); // Soft lavender/purple
    const innerEarColor = Color(0xFFFF8A80); // Coral pink
    const white = Colors.white;
    const dark = Color(0xFF212121);

    final earPaint = Paint()..color = baseColor;
    final innerEarPaint = Paint()..color = innerEarColor;

    // 1. Draw Pawn Base & Column
    drawTokenBaseAndColumn(canvas, size, baseColor);

    // 2. Rabbit Head (center at h * 0.4)
    final double hx = w * 0.5;
    final double hy = h * 0.42;
    final double hr = w * 0.21;

    // Tall Ears (must go higher)
    canvas.drawOval(
      Rect.fromCenter(center: Offset(hx - hr * 0.5, hy - hr * 0.9), width: hr * 0.42, height: hr * 1.3),
      earPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(hx - hr * 0.5, hy - hr * 0.95), width: hr * 0.22, height: hr * 1.0),
      innerEarPaint,
    );

    canvas.drawOval(
      Rect.fromCenter(center: Offset(hx + hr * 0.5, hy - hr * 0.9), width: hr * 0.42, height: hr * 1.3),
      earPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(hx + hr * 0.5, hy - hr * 0.95), width: hr * 0.22, height: hr * 1.0),
      innerEarPaint,
    );

    // Head
    canvas.drawCircle(Offset(hx, hy), hr, earPaint);

    // White Muzzle
    final muzzlePaint = Paint()..color = white;
    canvas.drawCircle(Offset(hx - hr * 0.2, hy + hr * 0.3), hr * 0.3, muzzlePaint);
    canvas.drawCircle(Offset(hx + hr * 0.2, hy + hr * 0.3), hr * 0.3, muzzlePaint);

    // Buckteeth
    final teethPaint = Paint()..color = white;
    final teethBorder = Paint()
      ..color = dark
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final teethRect = Rect.fromLTWH(hx - hr * 0.12, hy + hr * 0.5, hr * 0.24, hr * 0.2);
    canvas.drawRRect(RRect.fromRectAndRadius(teethRect, const Radius.circular(2)), teethPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(teethRect, const Radius.circular(2)), teethBorder);
    canvas.drawLine(Offset(hx, hy + hr * 0.5), Offset(hx, hy + hr * 0.7), teethBorder);

    // Eyes
    drawCartoonEyes(canvas, hx, hy - hr * 0.1, hr * 0.45, hr * 0.18);

    // Blush
    drawBlush(canvas, hx, hy + hr * 0.25, hr * 0.6, hr * 0.12);

    // Nose
    final Path nosePath = Path()
      ..moveTo(hx - hr * 0.12, hy + hr * 0.15)
      ..lineTo(hx + hr * 0.12, hy + hr * 0.15)
      ..lineTo(hx, hy + hr * 0.3)
      ..close();
    canvas.drawPath(nosePath, innerEarPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3. BEAR FIGURINE PAINTER
class BearPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    const baseColor = Color(0xFF8D6E63); // Warm brown
    const cream = Color(0xFFFFECB3);
    const black = Color(0xFF212121);

    final earPaint = Paint()..color = baseColor;
    final innerEarPaint = Paint()..color = cream;

    // 1. Draw Pawn Base & Column
    drawTokenBaseAndColumn(canvas, size, baseColor);

    // 2. Bear Head (center at h * 0.37)
    final double hx = w * 0.5;
    final double hy = h * 0.38;
    final double hr = w * 0.24;

    // Circular ears
    canvas.drawCircle(Offset(hx - hr * 0.8, hy - hr * 0.6), hr * 0.36, earPaint);
    canvas.drawCircle(Offset(hx - hr * 0.8, hy - hr * 0.6), hr * 0.20, innerEarPaint);

    canvas.drawCircle(Offset(hx + hr * 0.8, hy - hr * 0.6), hr * 0.36, earPaint);
    canvas.drawCircle(Offset(hx + hr * 0.8, hy - hr * 0.6), hr * 0.20, innerEarPaint);

    // Head
    canvas.drawCircle(Offset(hx, hy), hr, earPaint);

    // Cream Muzzle
    canvas.drawOval(
      Rect.fromCenter(center: Offset(hx, hy + hr * 0.3), width: hr * 0.72, height: hr * 0.54),
      innerEarPaint,
    );

    // Nose
    canvas.drawCircle(Offset(hx, hy + hr * 0.18), hr * 0.15, Paint()..color = black);

    // Smile
    final mouthPaint = Paint()
      ..color = black
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(hx, hy + hr * 0.32), width: hr * 0.24, height: hr * 0.18),
      0,
      3.1415,
      false,
      mouthPaint,
    );

    // Eyes
    drawCartoonEyes(canvas, hx, hy - hr * 0.15, hr * 0.45, hr * 0.14);

    // Blush
    drawBlush(canvas, hx, hy + hr * 0.12, hr * 0.65, hr * 0.11);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 4. SQUIRREL FIGURINE PAINTER
class SquirrelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    const baseColor = Color(0xFFFFB74D); // Golden orange
    const white = Colors.white;
    const dark = Color(0xFF4E342E); // Dark brown

    final earPaint = Paint()..color = baseColor;
    final tuftPaint = Paint()
      ..color = dark
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 1. Draw Pawn Base & Column
    drawTokenBaseAndColumn(canvas, size, baseColor);

    // 2. Squirrel Head (center at h * 0.38)
    final double hx = w * 0.5;
    final double hy = h * 0.38;
    final double hr = w * 0.22;

    // Pointy Ears
    final leftEar = Path()
      ..moveTo(hx - hr * 0.8, hy - hr * 0.3)
      ..lineTo(hx - hr * 1.0, hy - hr * 1.2)
      ..lineTo(hx - hr * 0.1, hy - hr * 0.7)
      ..close();
    canvas.drawPath(leftEar, earPaint);

    canvas.drawLine(Offset(hx - hr * 1.0, hy - hr * 1.2), Offset(hx - hr * 1.15, hy - hr * 1.4), tuftPaint);
    canvas.drawLine(Offset(hx - hr * 1.0, hy - hr * 1.2), Offset(hx - hr * 0.95, hy - hr * 1.4), tuftPaint);

    final rightEar = Path()
      ..moveTo(hx + hr * 0.8, hy - hr * 0.3)
      ..lineTo(hx + hr * 1.0, hy - hr * 1.2)
      ..lineTo(hx + hr * 0.1, hy - hr * 0.7)
      ..close();
    canvas.drawPath(rightEar, earPaint);

    canvas.drawLine(Offset(hx + hr * 1.0, hy - hr * 1.2), Offset(hx + hr * 1.15, hy - hr * 1.4), tuftPaint);
    canvas.drawLine(Offset(hx + hr * 1.0, hy - hr * 1.2), Offset(hx + hr * 0.95, hy - hr * 1.4), tuftPaint);

    // Head
    canvas.drawCircle(Offset(hx, hy), hr, earPaint);

    // Cheek fluff
    final cheekPaint = Paint()..color = white;
    canvas.drawCircle(Offset(hx - hr * 0.3, hy + hr * 0.32), hr * 0.32, cheekPaint);
    canvas.drawCircle(Offset(hx + hr * 0.3, hy + hr * 0.32), hr * 0.32, cheekPaint);

    // Bucktooth
    canvas.drawRect(
      Rect.fromLTWH(hx - hr * 0.05, hy + hr * 0.48, hr * 0.1, hr * 0.14),
      Paint()..color = white,
    );
    canvas.drawRect(
      Rect.fromLTWH(hx - hr * 0.05, hy + hr * 0.48, hr * 0.1, hr * 0.14),
      Paint()
        ..color = dark
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke,
    );

    // Eyes
    drawCartoonEyes(canvas, hx, hy - hr * 0.15, hr * 0.45, hr * 0.17);

    // Blush
    drawBlush(canvas, hx, hy + hr * 0.16, hr * 0.65, hr * 0.12);

    // Nose
    canvas.drawOval(
      Rect.fromCenter(center: Offset(hx, hy + hr * 0.22), width: hr * 0.22, height: hr * 0.14),
      Paint()..color = dark,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
