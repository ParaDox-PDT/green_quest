import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:green_quest/app/theme/theme.dart';
import 'package:green_quest/features/game/domain/providers/game_provider.dart';

class BoardPath {
  static const double boardWidth = 500.0;
  static const double boardHeight = 2300.0;
  static const double tileRadius = 22.0;

  static const double bottomSpacing = 100.0;
  static const double stepY = 16.0; // vertical climb per tile within a row
  static const double rowExtraStep = 32.0; // extra vertical step at row turns

  /// Computes the exact center offset of a tile index (0 to 99) on the board
  static Offset getTileOffset(int index) {
    if (index < 0) index = 0;
    if (index > 99) index = 99;

    final int r = index ~/ 6; // row index (0 is bottom)
    final int col = index % 6; // column index inside the row

    final bool isEvenRow = (r % 2 == 0);
    final int c = isEvenRow ? col : (5 - col); // flip column direction on odd rows

    const double colWidth = boardWidth / 6;
    
    // Calculate X center with a natural sine wave wobble
    final double wobble = 14 * math.sin(r * 1.5);
    final double x = (c + 0.5) * colWidth + wobble;

    // Calculate Y center (climbing up from bottom with extra vertical spacing at row transitions)
    final double y = boardHeight - bottomSpacing - (index * stepY) - (r * rowExtraStep);

    return Offset(x, y);
  }
}

/// Custom painter to draw the continuous sandy trail and nature elements
class BoardPathPainter extends CustomPainter {
  final int playerTile;
  final int rivalTile;

  BoardPathPainter({required this.playerTile, required this.rivalTile});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw continuous winding Sandy Path
    final pathPaint = Paint()
      ..color = const Color(0xFFF1E4C3) // Soft sand/soil color
      ..strokeWidth = 46.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final firstOffset = BoardPath.getTileOffset(0);
    path.moveTo(firstOffset.dx, firstOffset.dy);

    for (int i = 1; i < 100; i++) {
      final offset = BoardPath.getTileOffset(i);
      path.lineTo(offset.dx, offset.dy);
    }

    // Draw shadow under the sandy path
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.05)
        ..strokeWidth = 52.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Draw sandy path
    canvas.drawPath(path, pathPaint);

    // Draw lighter soil highlight line down the middle of the trail
    final pathCenterLinePaint = Paint()
      ..color = const Color(0xFFE5D5B3)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, pathCenterLinePaint);

    // 2. Draw surrounding grass tufts/flowers at random nodes to populate the forest
    final grassPaint = Paint()
      ..color = Colors.green.shade800.withValues(alpha: 0.25)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 100; i += 4) {
      final offset = BoardPath.getTileOffset(i);
      final dx = offset.dx + (i % 3 == 0 ? 32 : -32);
      final dy = offset.dy + (i % 2 == 0 ? 8 : -8);

      // Draw 3 blades of grass
      canvas.drawLine(Offset(dx, dy), Offset(dx - 4, dy - 12), grassPaint);
      canvas.drawLine(Offset(dx, dy), Offset(dx, dy - 15), grassPaint);
      canvas.drawLine(Offset(dx, dy), Offset(dx + 4, dy - 10), grassPaint);

      // Add a tiny red flower dot occasionally
      if (i % 12 == 0) {
        canvas.drawCircle(Offset(dx, dy - 16), 3, Paint()..color = const Color(0xFFE57373));
      }
    }

    // 3. Draw each tile point
    for (int i = 0; i < 100; i++) {
      _drawTile(canvas, i);
    }
  }

  /// Helper to draw individual tile visuals depending on its action type
  void _drawTile(Canvas canvas, int index) {
    final offset = BoardPath.getTileOffset(index);
    final tileNumber = index + 1;

    // Categorize tiles (1-based positions)
    final bool isStart = (tileNumber == 1);
    final bool isFinish = (tileNumber == 100);
    final bool isWind = GameNotifier.windTiles.containsKey(tileNumber);
    final bool isFog = GameNotifier.fogTiles.containsKey(tileNumber);
    final bool isNap = GameNotifier.napTiles.contains(tileNumber);
    final bool isClover = GameNotifier.cloverTiles.contains(tileNumber);

    // Default tile colors
    Color fill = Colors.white;
    Color border = const Color(0xFFC8E6C9); // Light green border
    double borderSize = 3.0;

    if (isStart) {
      fill = const Color(0xFFFFF9C4); // Sunny Start Yellow
      border = GameTheme.primaryAmber;
      borderSize = 4.0;
    } else if (isFinish) {
      fill = const Color(0xFFFFECB3); // Golden Finish
      border = const Color(0xFFFFB300);
      borderSize = 5.0;
    } else if (isWind) {
      fill = const Color(0xFFE0F7FA); // Wind blue
      border = const Color(0xFF00ACC1);
    } else if (isFog) {
      fill = const Color(0xFFECEFF1); // Fog grey
      border = const Color(0xFF78909C);
    } else if (isNap) {
      fill = const Color(0xFFF3E5F5); // Sleep purple
      border = const Color(0xFFAB47BC);
    } else if (isClover) {
      fill = const Color(0xFFE8F5E9); // Lucky clover green
      border = GameTheme.primaryGreen;
    }

    // Draw tile shadow
    canvas.drawCircle(
      Offset(offset.dx, offset.dy + 3),
      BoardPath.tileRadius,
      Paint()..color = Colors.black.withValues(alpha: 0.1),
    );

    // Draw tile body
    canvas.drawCircle(
      offset,
      BoardPath.tileRadius,
      Paint()..color = fill,
    );

    // Draw tile border
    canvas.drawCircle(
      offset,
      BoardPath.tileRadius,
      Paint()
        ..color = border
        ..strokeWidth = borderSize
        ..style = PaintingStyle.stroke,
    );

    // 4. Draw Vector Action Icons inside the Tile
    if (isStart) {
      _drawText(canvas, offset, 'S', Colors.red.shade700, 16);
    } else if (isFinish) {
      _drawStar(canvas, offset, const Color(0xFFFFB300));
    } else if (isWind) {
      _drawWindIcon(canvas, offset, const Color(0xFF00ACC1));
    } else if (isFog) {
      _drawFogIcon(canvas, offset, const Color(0xFF78909C));
    } else if (isNap) {
      _drawNapIcon(canvas, offset, const Color(0xFFAB47BC));
    } else if (isClover) {
      _drawCloverIcon(canvas, offset, GameTheme.primaryGreen);
    } else {
      // Normal tile: draw tile number
      _drawText(canvas, offset, '$tileNumber', GameTheme.darkWood.withValues(alpha: 0.7), 13);
    }
  }

  void _drawText(Canvas canvas, Offset offset, String text, Color color, double size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: GoogleFonts.fredoka(
          fontSize: size,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(offset.dx - textPainter.width / 2, offset.dy - textPainter.height / 2),
    );
  }

  void _drawStar(Canvas canvas, Offset offset, Color color) {
    final path = Path();
    final double cx = offset.dx;
    final double cy = offset.dy;
    const double r = BoardPath.tileRadius * 0.7;

    path.moveTo(cx, cy - r);
    for (int i = 1; i < 5; i++) {
      final double angle = (i * 4 * math.pi) / 5 - (math.pi / 2);
      path.lineTo(cx + r * math.cos(angle), cy + r * math.sin(angle));
    }
    path.close();

    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawWindIcon(Canvas canvas, Offset offset, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final cx = offset.dx;
    final cy = offset.dy;

    // Draw small wind swirl path
    final path = Path()
      ..moveTo(cx - 10, cy - 3)
      ..quadraticBezierTo(cx - 3, cy - 6, cx + 5, cy - 3)
      ..quadraticBezierTo(cx + 10, cy, cx + 7, cy + 4)
      ..quadraticBezierTo(cx + 4, cy + 3, cx + 5, cy - 1);
    canvas.drawPath(path, paint);

    canvas.drawCircle(Offset(cx - 5, cy + 5), 1, Paint()..color = color);
  }

  void _drawFogIcon(Canvas canvas, Offset offset, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final cx = offset.dx;
    final cy = offset.dy;

    // Draw little cloud/fog shape
    canvas.drawCircle(Offset(cx - 6, cy + 2), 5, paint);
    canvas.drawCircle(Offset(cx, cy - 2), 6, paint);
    canvas.drawCircle(Offset(cx + 6, cy + 2), 5, paint);
    canvas.drawRect(Rect.fromLTRB(cx - 6, cy + 2, cx + 6, cy + 7), paint);
  }

  void _drawNapIcon(Canvas canvas, Offset offset, Color color) {
    // Draw "Zzz" Sleep letters
    _drawText(canvas, Offset(offset.dx - 4, offset.dy + 3), 'z', color, 12);
    _drawText(canvas, Offset(offset.dx + 4, offset.dy - 3), 'Z', color, 15);
  }

  void _drawCloverIcon(Canvas canvas, Offset offset, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final cx = offset.dx;
    final cy = offset.dy;
    const double r = 4.5;

    // Draw 4 leaves of clover
    canvas.drawCircle(Offset(cx - r, cy - r), r, paint);
    canvas.drawCircle(Offset(cx + r, cy - r), r, paint);
    canvas.drawCircle(Offset(cx - r, cy + r), r, paint);
    canvas.drawCircle(Offset(cx + r, cy + r), r, paint);

    // Stem
    final stemPaint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx, cy), Offset(cx, cy + 12), stemPaint);
  }

  @override
  bool shouldRepaint(covariant BoardPathPainter oldDelegate) {
    return oldDelegate.playerTile != playerTile || oldDelegate.rivalTile != rivalTile;
  }
}
