import 'dart:math' as math;
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
    ..color = const Color(0xFFFF8A80).withValues(alpha: 0.45)
    ..style = PaintingStyle.fill;
  canvas.drawCircle(Offset(cx - spacing, cy), radius, blushPaint);
  canvas.drawCircle(Offset(cx + spacing, cy), radius, blushPaint);
}

/// Reusable helper to draw a 3D board game pawn/token base and columns
void drawTokenBaseAndColumn(Canvas canvas, double cx, double cy, double d, Color baseColor) {
  // Calculate shading values (darker shade for rim, lighter shade for highlight)
  final hsv = HSVColor.fromColor(baseColor);
  final darkColor = hsv.withValue(hsv.value * 0.65).toColor();
  final lightColor = hsv.withValue(hsv.value * 1.15 > 1.0 ? 1.0 : hsv.value * 1.15).toColor();

  // 1. Pawn Shadow (bottom oval)
  canvas.drawOval(
    Rect.fromLTRB(cx - d * 0.35, cy + d * 0.32, cx + d * 0.35, cy + d * 0.45),
    Paint()..color = Colors.black.withValues(alpha: 0.12),
  );

  // 2. Lower Base Rim (creates thickness)
  final baseRimPaint = Paint()
    ..shader = LinearGradient(
      colors: [darkColor, baseColor],
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    ).createShader(Rect.fromLTRB(cx - d * 0.32, cy + d * 0.26, cx + d * 0.32, cy + d * 0.40))
    ..style = PaintingStyle.fill;
  canvas.drawOval(
    Rect.fromLTRB(cx - d * 0.32, cy + d * 0.26, cx + d * 0.32, cy + d * 0.40),
    baseRimPaint,
  );

  // 3. Upper Base Ring (slanted inset)
  final baseTopPaint = Paint()
    ..shader = LinearGradient(
      colors: [baseColor, lightColor],
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    ).createShader(Rect.fromLTRB(cx - d * 0.28, cy + d * 0.22, cx + d * 0.28, cy + d * 0.32))
    ..style = PaintingStyle.fill;
  canvas.drawOval(
    Rect.fromLTRB(cx - d * 0.28, cy + d * 0.22, cx + d * 0.28, cy + d * 0.32),
    baseTopPaint,
  );

  // 4. Figurine Pillar/Column
  final bodyPaint = Paint()
    ..shader = LinearGradient(
      colors: [darkColor, baseColor, lightColor],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ).createShader(Rect.fromLTRB(cx - d * 0.2, cy - d * 0.05, cx + d * 0.2, cy + d * 0.25))
    ..style = PaintingStyle.fill;

  final bodyPath = Path()
    ..moveTo(cx - d * 0.18, cy + d * 0.25)
    ..quadraticBezierTo(cx - d * 0.07, cy + d * 0.08, cx - d * 0.12, cy - d * 0.05)
    ..lineTo(cx + d * 0.12, cy - d * 0.05)
    ..quadraticBezierTo(cx + d * 0.07, cy + d * 0.08, cx + d * 0.18, cy + d * 0.25)
    ..close();
  canvas.drawPath(bodyPath, bodyPaint);

  // 5. Neck Ring (Figurine Collar)
  final collarPaint = Paint()
    ..shader = LinearGradient(
      colors: [darkColor, lightColor],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromLTRB(cx - d * 0.15, cy - d * 0.09, cx + d * 0.15, cy - d * 0.04))
    ..style = PaintingStyle.fill;
  canvas.drawOval(
    Rect.fromLTRB(cx - d * 0.15, cy - d * 0.09, cx + d * 0.15, cy - d * 0.04),
    collarPaint,
  );
}

/// 1. FOX FIGURINE PAINTER
class FoxPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final d = math.min(w, h);
    final cx = w / 2;
    final cy = h / 2;

    const baseColor = Color(0xFFFF7043); // Orange
    final orangePaint = Paint()..color = baseColor;
    final whitePaint = Paint()..color = Colors.white;
    final blackPaint = Paint()..color = const Color(0xFF212121);
    final darkOrangePaint = Paint()
      ..color = const Color(0xFFE64A19) // Deep rust orange for outlines
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 1. Draw Pawn Base & Column
    drawTokenBaseAndColumn(canvas, cx, cy, d, baseColor);

    // 2. Fox Head sits on top of column (center at cy - d * 0.15)
    final double hx = cx;
    final double hy = cy - d * 0.15;
    final double hr = d * 0.22; // Head radius

    // Fox Ears
    final leftEar = Path()
      ..moveTo(hx - hr * 0.8, hy - hr * 0.3)
      ..lineTo(hx - hr * 1.1, hy - hr * 1.1)
      ..lineTo(hx - hr * 0.1, hy - hr * 0.8)
      ..close();
    canvas.drawPath(leftEar, orangePaint);
    canvas.drawPath(leftEar, darkOrangePaint);
    
    final leftInnerEar = Path()
      ..moveTo(hx - hr * 0.7, hy - hr * 0.4)
      ..lineTo(hx - hr * 0.95, hy - hr * 0.95)
      ..lineTo(hx - hr * 0.25, hy - hr * 0.7)
      ..close();
    canvas.drawPath(leftInnerEar, whitePaint);

    final rightEar = Path()
      ..moveTo(hx + hr * 0.8, hy - hr * 0.3)
      ..lineTo(hx + hr * 1.1, hy - hr * 1.1)
      ..lineTo(hx + hr * 0.1, hy - hr * 0.8)
      ..close();
    canvas.drawPath(rightEar, orangePaint);
    canvas.drawPath(rightEar, darkOrangePaint);

    final rightInnerEar = Path()
      ..moveTo(hx + hr * 0.7, hy - hr * 0.4)
      ..lineTo(hx + hr * 0.95, hy - hr * 0.95)
      ..lineTo(hx + hr * 0.25, hy - hr * 0.7)
      ..close();
    canvas.drawPath(rightInnerEar, whitePaint);

    // Ear Tips (Black)
    final leftTip = Path()
      ..moveTo(hx - hr * 1.1, hy - hr * 1.1)
      ..lineTo(hx - hr * 1.0, hy - hr * 0.85)
      ..lineTo(hx - hr * 0.8, hy - hr * 0.95)
      ..close();
    canvas.drawPath(leftTip, blackPaint);

    final rightTip = Path()
      ..moveTo(hx + hr * 1.1, hy - hr * 1.1)
      ..lineTo(hx + hr * 1.0, hy - hr * 0.85)
      ..lineTo(hx + hr * 0.8, hy - hr * 0.95)
      ..close();
    canvas.drawPath(rightTip, blackPaint);

    // Head circle
    canvas.drawCircle(Offset(hx, hy), hr, orangePaint);

    // White Cheeks/Muzzle inside head (raised up to hy + hr * 0.55 to keep chin orange)
    final leftMuzzle = Path()
      ..moveTo(hx - hr, hy)
      ..quadraticBezierTo(hx - hr * 0.8, hy + hr * 0.5, hx, hy + hr * 0.55)
      ..quadraticBezierTo(hx - hr * 0.4, hy + hr * 0.1, hx, hy)
      ..close();
    canvas.drawPath(leftMuzzle, whitePaint);

    final rightMuzzle = Path()
      ..moveTo(hx + hr, hy)
      ..quadraticBezierTo(hx + hr * 0.8, hy + hr * 0.5, hx, hy + hr * 0.55)
      ..quadraticBezierTo(hx + hr * 0.4, hy + hr * 0.1, hx, hy)
      ..close();
    canvas.drawPath(rightMuzzle, whitePaint);

    // Outline head circle (creates contrast against white card background and defines chin)
    canvas.drawCircle(Offset(hx, hy), hr, darkOrangePaint);

    // Eyes
    drawCartoonEyes(canvas, hx, hy - hr * 0.1, hr * 0.45, hr * 0.16);

    // Blush
    drawBlush(canvas, hx, hy + hr * 0.15, hr * 0.6, hr * 0.11);

    // Nose
    canvas.drawOval(
      Rect.fromCenter(center: Offset(hx, hy + hr * 0.35), width: hr * 0.32, height: hr * 0.2),
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
    final d = math.min(w, h);
    final cx = w / 2;
    final cy = h / 2;

    const baseColor = Color(0xFFB39DDB); // Soft lavender/purple
    const innerEarColor = Color(0xFFFF8A80); // Coral pink
    const white = Colors.white;
    const dark = Color(0xFF212121);
    final darkPurplePaint = Paint()
      ..color = const Color(0xFF7E57C2) // Deep purple border
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final earPaint = Paint()..color = baseColor;
    final innerEarPaint = Paint()..color = innerEarColor;

    // 1. Draw Pawn Base & Column
    drawTokenBaseAndColumn(canvas, cx, cy, d, baseColor);

    // 2. Rabbit Head (center at cy - d * 0.1)
    final double hx = cx;
    final double hy = cy - d * 0.1;
    final double hr = d * 0.20;

    // Tall Ears
    canvas.drawOval(
      Rect.fromCenter(center: Offset(hx - hr * 0.5, hy - hr * 0.9), width: hr * 0.42, height: hr * 1.3),
      earPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(hx - hr * 0.5, hy - hr * 0.95), width: hr * 0.22, height: hr * 1.0),
      innerEarPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(hx - hr * 0.5, hy - hr * 0.9), width: hr * 0.42, height: hr * 1.3),
      darkPurplePaint,
    );

    canvas.drawOval(
      Rect.fromCenter(center: Offset(hx + hr * 0.5, hy - hr * 0.9), width: hr * 0.42, height: hr * 1.3),
      earPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(hx + hr * 0.5, hy - hr * 0.95), width: hr * 0.22, height: hr * 1.0),
      innerEarPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(hx + hr * 0.5, hy - hr * 0.9), width: hr * 0.42, height: hr * 1.3),
      darkPurplePaint,
    );

    // Head
    canvas.drawCircle(Offset(hx, hy), hr, earPaint);

    // White Muzzle
    final muzzlePaint = Paint()..color = white;
    canvas.drawCircle(Offset(hx - hr * 0.2, hy + hr * 0.3), hr * 0.3, muzzlePaint);
    canvas.drawCircle(Offset(hx + hr * 0.2, hy + hr * 0.3), hr * 0.3, muzzlePaint);

    // Head Border
    canvas.drawCircle(Offset(hx, hy), hr, darkPurplePaint);

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
    final d = math.min(w, h);
    final cx = w / 2;
    final cy = h / 2;

    const baseColor = Color(0xFF8D6E63); // Warm brown
    const cream = Color(0xFFFFECB3);
    const black = Color(0xFF212121);
    final darkBrownPaint = Paint()
      ..color = const Color(0xFF4E342E) // Dark brown outline
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final earPaint = Paint()..color = baseColor;
    final innerEarPaint = Paint()..color = cream;

    // 1. Draw Pawn Base & Column
    drawTokenBaseAndColumn(canvas, cx, cy, d, baseColor);

    // 2. Bear Head (center at cy - d * 0.12)
    final double hx = cx;
    final double hy = cy - d * 0.12;
    final double hr = d * 0.22;

    // Circular ears
    canvas.drawCircle(Offset(hx - hr * 0.8, hy - hr * 0.6), hr * 0.36, earPaint);
    canvas.drawCircle(Offset(hx - hr * 0.8, hy - hr * 0.6), hr * 0.20, innerEarPaint);
    canvas.drawCircle(Offset(hx - hr * 0.8, hy - hr * 0.6), hr * 0.36, darkBrownPaint);

    canvas.drawCircle(Offset(hx + hr * 0.8, hy - hr * 0.6), hr * 0.36, earPaint);
    canvas.drawCircle(Offset(hx + hr * 0.8, hy - hr * 0.6), hr * 0.20, innerEarPaint);
    canvas.drawCircle(Offset(hx + hr * 0.8, hy - hr * 0.6), hr * 0.36, darkBrownPaint);

    // Head
    canvas.drawCircle(Offset(hx, hy), hr, earPaint);

    // Cream Muzzle
    canvas.drawOval(
      Rect.fromCenter(center: Offset(hx, hy + hr * 0.3), width: hr * 0.72, height: hr * 0.54),
      innerEarPaint,
    );

    // Head Border
    canvas.drawCircle(Offset(hx, hy), hr, darkBrownPaint);

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
    final d = math.min(w, h);
    final cx = w / 2;
    final cy = h / 2;

    const baseColor = Color(0xFFFFB74D); // Golden orange
    const white = Colors.white;
    const dark = Color(0xFF4E342E); // Dark brown
    final darkOrangePaint = Paint()
      ..color = const Color(0xFFE65100) // Deep dark orange outline
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final earPaint = Paint()..color = baseColor;
    final tuftPaint = Paint()
      ..color = dark
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 1. Draw Pawn Base & Column
    drawTokenBaseAndColumn(canvas, cx, cy, d, baseColor);

    // 2. Squirrel Head (center at cy - d * 0.12)
    final double hx = cx;
    final double hy = cy - d * 0.12;
    final double hr = d * 0.20;

    // Pointy Ears
    final leftEar = Path()
      ..moveTo(hx - hr * 0.8, hy - hr * 0.3)
      ..lineTo(hx - hr * 1.0, hy - hr * 1.2)
      ..lineTo(hx - hr * 0.1, hy - hr * 0.7)
      ..close();
    canvas.drawPath(leftEar, earPaint);
    canvas.drawPath(leftEar, darkOrangePaint);

    canvas.drawLine(Offset(hx - hr * 1.0, hy - hr * 1.2), Offset(hx - hr * 1.15, hy - hr * 1.4), tuftPaint);
    canvas.drawLine(Offset(hx - hr * 1.0, hy - hr * 1.2), Offset(hx - hr * 0.95, hy - hr * 1.4), tuftPaint);

    final rightEar = Path()
      ..moveTo(hx + hr * 0.8, hy - hr * 0.3)
      ..lineTo(hx + hr * 1.0, hy - hr * 1.2)
      ..lineTo(hx + hr * 0.1, hy - hr * 0.7)
      ..close();
    canvas.drawPath(rightEar, earPaint);
    canvas.drawPath(rightEar, darkOrangePaint);

    canvas.drawLine(Offset(hx + hr * 1.0, hy - hr * 1.2), Offset(hx + hr * 1.15, hy - hr * 1.4), tuftPaint);
    canvas.drawLine(Offset(hx + hr * 1.0, hy - hr * 1.2), Offset(hx + hr * 0.95, hy - hr * 1.4), tuftPaint);

    // Head
    canvas.drawCircle(Offset(hx, hy), hr, earPaint);

    // Cheek fluff
    final cheekPaint = Paint()..color = white;
    canvas.drawCircle(Offset(hx - hr * 0.3, hy + hr * 0.32), hr * 0.32, cheekPaint);
    canvas.drawCircle(Offset(hx + hr * 0.3, hy + hr * 0.32), hr * 0.32, cheekPaint);

    // Head Border
    canvas.drawCircle(Offset(hx, hy), hr, darkOrangePaint);

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
