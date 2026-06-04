import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:green_quest/features/game/domain/models/game_map.dart';
import 'package:green_quest/features/menu/domain/providers/character_provider.dart';
import 'package:green_quest/features/menu/presentation/widgets/character_painters.dart';

class PlayerToken extends StatefulWidget {
  final GameCharacter? character; // null means Rival Crow
  final int tile; // 1 to totalTiles
  final GameMap activeMap;
  final double size;
  final double offsetX; // shift when on same tile

  const PlayerToken({
    super.key,
    required this.character,
    required this.tile,
    required this.activeMap,
    this.size = 42.0,
    this.offsetX = 0.0,
  });

  @override
  State<PlayerToken> createState() => _PlayerTokenState();
}

class _PlayerTokenState extends State<PlayerToken> with SingleTickerProviderStateMixin {
  late int _animatedTile;
  late AnimationController _controller;
  late Animation<double> _animation;
  
  // To queue steps if multiple tiles are traversed
  final List<int> _stepQueue = [];
  bool _isAnimatingStep = false;
  int _currentVisualTile = 1;

  @override
  void initState() {
    super.initState();
    _animatedTile = widget.tile;
    _currentVisualTile = widget.tile;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _currentVisualTile = _animatedTile;
          _isAnimatingStep = false;
        });
        _processNextStep();
      }
    });

    // Directly set to starting tile
    _animatedTile = widget.tile;
    _currentVisualTile = widget.tile;
  }

  @override
  void didUpdateWidget(covariant PlayerToken oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tile != widget.tile) {
      final start = _currentVisualTile;
      final end = widget.tile;
      
      if (start != end) {
        _stepQueue.clear();
        if (start < end) {
          for (int i = start + 1; i <= end; i++) {
            _stepQueue.add(i);
          }
        } else {
          for (int i = start - 1; i >= end; i--) {
            _stepQueue.add(i);
          }
        }
        _processNextStep();
      }
    }
  }

  void _processNextStep() {
    if (_isAnimatingStep || _stepQueue.isEmpty) return;
    
    setState(() {
      _isAnimatingStep = true;
      _animatedTile = _stepQueue.removeAt(0);
    });
    
    _controller.forward(from: 0.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final currentOffset = widget.activeMap.getTileOffset(_currentVisualTile - 1);
        final targetOffset = widget.activeMap.getTileOffset(_animatedTile - 1);
        
        // Lerp position
        final double t = _animation.value;
        final Offset basePos = Offset.lerp(currentOffset, targetOffset, t)!;
        
        // Hopping effect (Y offset and scale)
        final double hopY = math.sin(t * math.pi) * -20.0;
        final double scale = 1.0 + math.sin(t * math.pi) * 0.25;
        
        return Positioned(
          left: basePos.dx + widget.offsetX - (widget.size * scale) / 2,
          top: basePos.dy + hopY - (widget.size * scale) / 2,
          width: widget.size * scale,
          height: widget.size * scale,
          child: widget.character != null
              ? CharacterVectorWidget(character: widget.character!, size: widget.size * scale)
              : CustomPaint(
                  size: Size(widget.size * scale, widget.size * scale),
                  painter: RivalCrowPainter(),
                ),
        );
      },
    );
  }
}
