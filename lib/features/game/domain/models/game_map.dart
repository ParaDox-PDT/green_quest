import 'dart:math' as math;
import 'package:flutter/material.dart';

enum MapType {
  standard, // 100 tiles zig-zag
  spiral,   // 125 tiles spiral
  vortex,   // 150 tiles rectangular spiral
}

class GameMap {
  final MapType type;
  final String nameUz;
  final String nameEn;
  final String nameRu;
  final int totalTiles;
  final double boardWidth;
  final double boardHeight;

  const GameMap({
    required this.type,
    required this.nameUz,
    required this.nameEn,
    required this.nameRu,
    required this.totalTiles,
    required this.boardWidth,
    required this.boardHeight,
  });

  String getName(String lang) {
    if (lang == 'uz') return nameUz;
    if (lang == 'ru') return nameRu;
    return nameEn;
  }

  /// Computes the exact center offset of a tile index (0 to totalTiles-1) on the board
  Offset getTileOffset(int index) {
    switch (type) {
      case MapType.standard:
        return _getStandardOffset(index);
      case MapType.spiral:
        return _getSpiralOffset(index);
      case MapType.vortex:
        return _getVortexOffset(index);
    }
  }

  Offset _getStandardOffset(int index) {
    if (index < 0) index = 0;
    if (index >= 100) index = 99;

    final int r = index ~/ 6;
    final int col = index % 6;
    final bool isEvenRow = (r % 2 == 0);
    final int c = isEvenRow ? col : (5 - col);
    const double colWidth = 500.0 / 6;
    final double wobble = 14 * math.sin(r * 1.5);
    final double x = (c + 0.5) * colWidth + wobble;
    final double y = boardHeight - 100.0 - (index * 16.0) - (r * 32.0);
    return Offset(x, y);
  }

  // Static cache for arc-length parameterized spiral positions
  static List<Offset>? _spiralCache;
  static double _spiralCacheW = 0;
  static double _spiralCacheH = 0;

  Offset _getSpiralOffset(int index) {
    if (index < 0) index = 0;
    if (index >= totalTiles) index = totalTiles - 1;

    // Rebuild cache if board dimensions changed
    if (_spiralCache == null ||
        _spiralCacheW != boardWidth ||
        _spiralCacheH != boardHeight) {
      _spiralCache = _computeSpiralPositions();
      _spiralCacheW = boardWidth;
      _spiralCacheH = boardHeight;
    }
    return _spiralCache![index];
  }

  List<Offset> _computeSpiralPositions() {
    final double cx = boardWidth / 2;
    final double cy = boardHeight / 2;

    // Circular spiral: use the smaller dimension for radius
    final double maxR = math.min(boardWidth, boardHeight) / 2 - 60;
    const double minR = 30.0;
    const double numRotations = 4.0;
    const double maxTheta = numRotations * 2.0 * math.pi;

    // Finely sample the spiral to compute cumulative arc length
    const int samples = 1000;
    final arcLengths = List<double>.filled(samples + 1, 0.0);
    const double dTheta = maxTheta / samples;

    for (int i = 1; i <= samples; i++) {
      final double prevTheta = dTheta * (i - 1);
      final double r = maxR - (maxR - minR) * prevTheta / maxTheta;
      final double dr = -(maxR - minR) * dTheta / maxTheta;
      final double ds = math.sqrt(dr * dr + r * r * dTheta * dTheta);
      arcLengths[i] = arcLengths[i - 1] + ds;
    }

    final double totalArc = arcLengths[samples];
    final positions = <Offset>[];

    for (int tileIdx = 0; tileIdx < totalTiles; tileIdx++) {
      final double targetArc = totalArc * tileIdx / (totalTiles - 1);

      // Binary search for the sample index containing targetArc
      int lo = 0;
      int hi = samples;
      while (lo < hi) {
        final int mid = (lo + hi) ~/ 2;
        if (arcLengths[mid] < targetArc) {
          lo = mid + 1;
        } else {
          hi = mid;
        }
      }

      // Interpolate to find exact theta
      double theta;
      if (lo == 0) {
        theta = 0;
      } else {
        final double frac = (targetArc - arcLengths[lo - 1]) /
            (arcLengths[lo] - arcLengths[lo - 1]);
        theta = dTheta * ((lo - 1) + frac);
      }

      final double r = maxR - (maxR - minR) * theta / maxTheta;
      positions.add(Offset(cx + r * math.cos(theta), cy + r * math.sin(theta)));
    }

    return positions;
  }

  // Static cache for arc-length parameterized rectangular spiral positions (previously vortex)
  static List<Offset>? _vortexCache;
  static double _vortexCacheW = 0;
  static double _vortexCacheH = 0;

  Offset _getVortexOffset(int index) {
    if (index < 0) index = 0;
    if (index >= totalTiles) index = totalTiles - 1;

    // Rebuild cache if board dimensions changed
    if (_vortexCache == null ||
        _vortexCacheW != boardWidth ||
        _vortexCacheH != boardHeight) {
      _vortexCache = _computeVortexPositions();
      _vortexCacheW = boardWidth;
      _vortexCacheH = boardHeight;
    }
    return _vortexCache![index];
  }

  List<Offset> _computeVortexPositions() {
    final double cx = boardWidth / 2;
    final double cy = boardHeight / 2;

    // Rectangular/square spiral: starts at bottom-left corner and winds inward.
    const double margin = 60.0;
    double xMin = margin;
    double xMax = boardWidth - margin;
    double yMin = margin;
    double yMax = boardHeight - margin;

    final pathPoints = <Offset>[];
    // Start at bottom-left corner
    pathPoints.add(Offset(xMin, yMax));

    // Distance between concentric lines in the spiral
    const double pitch = 85.0;

    while (xMin < xMax && yMin < yMax) {
      // 1. East along bottom
      pathPoints.add(Offset(xMax, yMax));
      yMax -= pitch;
      if (yMin >= yMax) break;

      // 2. North along right wall
      pathPoints.add(Offset(xMax, yMin));
      xMax -= pitch;
      if (xMin >= xMax) break;

      // 3. West along top
      pathPoints.add(Offset(xMin, yMin));
      yMin += pitch;
      if (yMin >= yMax) break;

      // 4. South along left wall
      pathPoints.add(Offset(xMin, yMax));
      xMin += pitch;
      if (xMin >= xMax) break;
    }

    // Add the center point to finish the spiral at the exact center
    pathPoints.add(Offset(cx, cy));

    // Calculate arc lengths for fine-grained equal spacing of tiles
    final arcLengths = <double>[0.0];
    for (int i = 1; i < pathPoints.length; i++) {
      final double dx = pathPoints[i].dx - pathPoints[i - 1].dx;
      final double dy = pathPoints[i].dy - pathPoints[i - 1].dy;
      arcLengths.add(arcLengths.last + math.sqrt(dx * dx + dy * dy));
    }

    final double totalArc = arcLengths.last;
    final positions = <Offset>[];

    for (int tileIdx = 0; tileIdx < totalTiles; tileIdx++) {
      final double targetArc = totalArc * tileIdx / (totalTiles - 1);

      // Binary search for the segment
      int lo = 0;
      int hi = pathPoints.length - 1;
      while (lo < hi) {
        final int mid = (lo + hi) ~/ 2;
        if (arcLengths[mid] < targetArc) {
          lo = mid + 1;
        } else {
          hi = mid;
        }
      }

      if (lo == 0) {
        positions.add(pathPoints[0]);
      } else {
        final double prevArc = arcLengths[lo - 1];
        final double currArc = arcLengths[lo];
        final double frac = (targetArc - prevArc) / (currArc - prevArc);

        final Offset prevPt = pathPoints[lo - 1];
        final Offset currPt = pathPoints[lo];

        final double px = prevPt.dx + frac * (currPt.dx - prevPt.dx);
        final double py = prevPt.dy + frac * (currPt.dy - prevPt.dy);
        positions.add(Offset(px, py));
      }
    }

    return positions;
  }

  static const GameMap defaultMap = GameMap(
    type: MapType.standard,
    nameUz: 'Qalin Oʻrmon (100 katak)',
    nameEn: 'Standard Forest (100 tiles)',
    nameRu: 'Густой лес (100 клеток)',
    totalTiles: 100,
    boardWidth: 500.0,
    boardHeight: 2300.0,
  );

  static const List<GameMap> availableMaps = [
    GameMap(
      type: MapType.standard,
      nameUz: 'Qalin Oʻrmon (100 katak)',
      nameEn: 'Standard Forest (100 tiles)',
      nameRu: 'Густой лес (100 клеток)',
      totalTiles: 100,
      boardWidth: 500.0,
      boardHeight: 2300.0,
    ),
    GameMap(
      type: MapType.spiral,
      nameUz: 'Sehrli Spiral (125 katak)',
      nameEn: 'Magic Spiral (125 tiles)',
      nameRu: 'Волшебная спираль (125 клеток)',
      totalTiles: 125,
      boardWidth: 1100.0,
      boardHeight: 1100.0,
    ),
    GameMap(
      type: MapType.vortex,
      nameUz: 'Toʻrtburchak Spiral (150 katak)',
      nameEn: 'Rectangular Spiral (150 tiles)',
      nameRu: 'Прямоугольная спираль (150 клеток)',
      totalTiles: 150,
      boardWidth: 1100.0,
      boardHeight: 1100.0,
    ),
  ];
}
