import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:green_quest/app/theme/theme.dart';
import 'package:green_quest/core/l10n/app_localizations.dart';
import 'package:green_quest/core/providers/locale_provider.dart';
import 'package:green_quest/features/game/domain/models/game_map.dart';
import 'package:green_quest/features/menu/domain/providers/character_provider.dart';
import 'package:green_quest/features/menu/presentation/widgets/character_painters.dart';
import 'package:green_quest/features/game/domain/providers/game_provider.dart';
import 'package:green_quest/features/game/presentation/widgets/board_path.dart';
import 'package:green_quest/features/game/presentation/widgets/animated_dice.dart';
import 'package:green_quest/features/game/presentation/widgets/player_token.dart';
import 'package:green_quest/features/game/presentation/game_over_screen.dart';
import 'package:green_quest/core/services/firebase_service.dart';
import 'package:green_quest/features/game/domain/providers/multiplayer_provider.dart';

class GameScreen extends ConsumerStatefulWidget {
  final bool isMultiplayer;
  const GameScreen({super.key, this.isMultiplayer = false});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  final TransformationController _transformController = TransformationController();
  late AnimationController _cameraAnimController;
  Animation<Matrix4>? _cameraAnimation;
  bool _initializedScroll = false;

  // Local state for multiplayer rolling & event displays
  bool _isLocalRolling = false;
  int _localDiceValue = 1;
  String? _localEventType;
  int? _localEventSpaces;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _cameraAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _cameraAnimController.addListener(() {
      if (_cameraAnimation != null) {
        _transformController.value = _cameraAnimation!.value;
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _cameraAnimController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  /// Smoothly animate the InteractiveViewer camera to a target translation
  void _animateCameraTo(double targetX, double targetY) {
    final Matrix4 currentMatrix = _transformController.value.clone();
    final Matrix4 targetMatrix = Matrix4.translationValues(-targetX, -targetY, 0.0);

    _cameraAnimation = Matrix4Tween(
      begin: currentMatrix,
      end: targetMatrix,
    ).animate(CurvedAnimation(
      parent: _cameraAnimController,
      curve: Curves.easeInOutCubic,
    ));

    _cameraAnimController.forward(from: 0.0);
  }

  void _scrollToTile(GameMap activeMap, int tile, {bool animate = true}) {
    final screenSize = MediaQuery.of(context).size;
    final tileOffset = activeMap.getTileOffset(tile - 1);

    // For maps that fit in screen width, use the vertical-only scroll controller
    if (activeMap.boardWidth <= screenSize.width) {
      if (!_scrollController.hasClients) return;
      final double targetY = tileOffset.dy - (screenSize.height / 2);
      final double maxScroll = _scrollController.position.maxScrollExtent;
      final double clampedY = targetY.clamp(0.0, maxScroll);

      if (animate) {
        _scrollController.animateTo(
          clampedY,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOutCubic,
        );
      } else {
        _scrollController.jumpTo(clampedY);
      }
    } else {
      // For wide maps, use the TransformationController to pan
      final double targetX = (tileOffset.dx - screenSize.width / 2).clamp(
        0.0,
        (activeMap.boardWidth - screenSize.width).clamp(0.0, double.infinity),
      );
      final double targetY = (tileOffset.dy - screenSize.height / 2).clamp(
        0.0,
        (activeMap.boardHeight + 40 - screenSize.height).clamp(0.0, double.infinity),
      );

      if (animate) {
        _animateCameraTo(targetX, targetY);
      } else {
        _transformController.value = Matrix4.translationValues(-targetX, -targetY, 0.0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    final selectedChar = ref.watch(selectedCharacterProvider);
    final localizations = AppLocalizations.of(context)!;
    final mpState = ref.watch(multiplayerProvider);
    final myUid = ref.watch(firebaseServiceProvider).currentUser?.uid;

    final activeMap = widget.isMultiplayer ? mpState.activeMap : gameState.activeMap;

    // Single Player state listener
    if (!widget.isMultiplayer) {
      ref.listen<GameState>(gameStateProvider, (previous, next) {
        if (next.isGameOver && !(previous?.isGameOver ?? false)) {
          Future.delayed(const Duration(milliseconds: 1400), () {
            if (!context.mounted) return;
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const GameOverScreen(isMultiplayer: false),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
                transitionDuration: const Duration(milliseconds: 600),
              ),
            );
          });
          return;
        }

        if (previous == null) return;
        if (next.isPlayerTurn && next.playerTile != previous.playerTile) {
          Future.delayed(const Duration(milliseconds: 250), () {
            if (mounted) _scrollToTile(next.activeMap, next.playerTile);
          });
        } else if (!next.isPlayerTurn && next.rivalTile != previous.rivalTile) {
          Future.delayed(const Duration(milliseconds: 250), () {
            if (mounted) _scrollToTile(next.activeMap, next.rivalTile);
          });
        } else if (next.isPlayerTurn != previous.isPlayerTurn) {
          if (mounted) {
            _scrollToTile(next.activeMap, next.isPlayerTurn ? next.playerTile : next.rivalTile);
          }
        }
      });
    }

    // Multiplayer state listener
    if (widget.isMultiplayer) {
      ref.listen<MultiplayerRoomState>(multiplayerProvider, (previous, next) {
        if (next.status == 'finished' && previous?.status != 'finished') {
          Future.delayed(const Duration(milliseconds: 1400), () {
            if (!context.mounted) return;
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const GameOverScreen(isMultiplayer: true),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
                transitionDuration: const Duration(milliseconds: 600),
              ),
            );
          });
          return;
        }

        if (previous == null) return;

        // Cleanup disconnected players (host only)
        if (next.hostId == myUid) {
          for (var playerId in next.playerOrder) {
            if (!next.players.containsKey(playerId)) {
              ref.read(multiplayerProvider.notifier).removeDisconnectedPlayer(playerId);
            }
          }
        }

        // Camera follow & Event banners for other players
        for (var playerId in next.playerOrder) {
          if (playerId == myUid) continue;
          final oldPos = previous.positions[playerId] ?? 1;
          final newPos = next.positions[playerId] ?? 1;

          if (oldPos != newPos) {
            Future.delayed(const Duration(milliseconds: 250), () {
              if (mounted) _scrollToTile(next.activeMap, newPos);
            });

            // Local banner for other player triggers
            String? event;
            if (next.windTiles.containsKey(newPos)) {
              event = 'wind';
            } else if (next.fogTiles.containsKey(newPos)) {
              event = 'fog';
            } else if (next.napTiles.contains(newPos)) {
              event = 'nap';
            } else if (next.cloverTiles.contains(newPos)) {
              event = 'clover';
            } else if (next.startTiles.contains(newPos)) {
              event = 'start';
            }

            if (event != null) {
              setState(() {
                _localEventType = event;
                _localEventSpaces = event == 'wind' ? next.windTiles[newPos] : (event == 'fog' ? next.fogTiles[newPos] : null);
              });
              Future.delayed(const Duration(milliseconds: 2500), () {
                if (mounted) {
                  setState(() {
                    _localEventType = null;
                    _localEventSpaces = null;
                  });
                }
              });
            }
          }
        }

        // Focus on active player when turn changes
        if (next.currentTurn != previous.currentTurn && next.currentTurn != null) {
          final activePos = next.positions[next.currentTurn!] ?? 1;
          _scrollToTile(next.activeMap, activePos);
        }
      });
    }

    // Schedule initial scroll to tile 1 (start position) - instant, no animation
    if (!_initializedScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToTile(activeMap, 1, animate: false);
        setState(() {
          _initializedScroll = true;
        });
      });
    }

    // Determine overlay offsets if characters land on the same tile
    final bool sameTile = gameState.playerTile == gameState.rivalTile;
    final double playerOffset = sameTile ? -14.0 : 0.0;
    final double rivalOffset = sameTile ? 14.0 : 0.0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE8F5E9), // Light mint
              Color(0xFFC8E6C9), // Soft green
              Color(0xFFA5D6A7), // Rich forest green
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // Left/Right Forest silhouette details in empty space
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.07,
                  child: CustomPaint(
                    painter: ForestSideDecorationPainter(),
                  ),
                ),
              ),
            ),

            // Scrollable Game Board
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Group player tokens in multiplayer to avoid overlap
                  final List<Widget> tokensList = [];
                  if (widget.isMultiplayer) {
                    final Map<int, List<String>> tileGroups = {};
                    for (var playerId in mpState.playerOrder) {
                      final tile = mpState.positions[playerId] ?? 1;
                      tileGroups.putIfAbsent(tile, () => []).add(playerId);
                    }

                    for (var playerId in mpState.playerOrder) {
                      final player = mpState.players[playerId];
                      if (player == null) continue;

                      final tile = mpState.positions[playerId] ?? 1;
                      final group = tileGroups[tile] ?? [];
                      final int idx = group.indexOf(playerId);
                      final int count = group.length;
                      final double offset = count > 1 ? (idx - (count - 1) / 2) * 16.0 : 0.0;

                      tokensList.add(
                        PlayerToken(
                          character: player.figure,
                          tile: tile,
                          activeMap: mpState.activeMap,
                          offsetX: offset,
                        ),
                      );
                    }
                  } else {
                    final bool sameTile = gameState.playerTile == gameState.rivalTile;
                    final double playerOffset = sameTile ? -14.0 : 0.0;
                    final double rivalOffset = sameTile ? 14.0 : 0.0;

                    tokensList.add(
                      PlayerToken(
                        character: selectedChar,
                        tile: gameState.playerTile,
                        activeMap: gameState.activeMap,
                        offsetX: playerOffset,
                      ),
                    );
                    tokensList.add(
                      PlayerToken(
                        character: null,
                        tile: gameState.rivalTile,
                        activeMap: gameState.activeMap,
                        offsetX: rivalOffset,
                      ),
                    );
                  }

                  final boardContent = Container(
                    width: activeMap.boardWidth,
                    height: activeMap.boardHeight,
                    margin: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Winding Path & Tile Points
                        Positioned.fill(
                          child: CustomPaint(
                            painter: BoardPathPainter(
                              activeMap: activeMap,
                              playerTile: widget.isMultiplayer ? 1 : gameState.playerTile,
                              rivalTile: widget.isMultiplayer ? 1 : gameState.rivalTile,
                              windTiles: widget.isMultiplayer ? mpState.windTiles : gameState.windTiles,
                              fogTiles: widget.isMultiplayer ? mpState.fogTiles : gameState.fogTiles,
                              napTiles: widget.isMultiplayer ? mpState.napTiles : gameState.napTiles,
                              cloverTiles: widget.isMultiplayer ? mpState.cloverTiles : gameState.cloverTiles,
                              startTiles: widget.isMultiplayer ? mpState.startTiles : gameState.startTiles,
                            ),
                          ),
                        ),
                        ...tokensList,
                      ],
                    ),
                  );

                  // If the board fits horizontally, use simple vertical scroll
                  if (activeMap.boardWidth <= constraints.maxWidth) {
                    return SingleChildScrollView(
                      controller: _scrollController,
                      child: Center(child: boardContent),
                    );
                  }

                  // For wide maps, use InteractiveViewer for both axes
                  return InteractiveViewer(
                    transformationController: _transformController,
                    constrained: false,
                    boundaryMargin: const EdgeInsets.all(20.0),
                    minScale: 0.4,
                    maxScale: 1.5,
                    child: boardContent,
                  );
                },
              ),
            ),

            // HUD Layer (Top overlay cards)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withValues(alpha: 0.15), Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      // Back & Help Info Buttons Row
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildBackButton(context),
                          const SizedBox(width: 12),
                          _buildInfoButton(context),
                        ],
                      ),
                      const Spacer(),

                      // Players HUD Cards
                      if (widget.isMultiplayer)
                        ...mpState.playerOrder.map((playerId) {
                          final player = mpState.players[playerId];
                          if (player == null) return const SizedBox.shrink();
                          final isCurrentTurn = mpState.currentTurn == playerId;
                          final tile = mpState.positions[playerId] ?? 1;

                          return Padding(
                            padding: const EdgeInsets.only(left: 10.0),
                            child: _buildHudCard(
                              name: player.name + (playerId == myUid ? ' (You)' : ''),
                              tile: tile,
                              isActive: isCurrentTurn,
                              avatar: player.figure != null
                                  ? CharacterVectorWidget(character: player.figure!, size: 36)
                                  : const SizedBox.shrink(),
                              isPlayer: playerId == myUid,
                            ),
                          );
                        })
                      else ...[
                        // Player HUD
                        _buildHudCard(
                          name: _getLocalizedCharacterName(context, selectedChar),
                          tile: gameState.playerTile,
                          isActive: gameState.isPlayerTurn,
                          avatar: selectedChar != null
                              ? CharacterVectorWidget(character: selectedChar, size: 36)
                              : const SizedBox.shrink(),
                          isPlayer: true,
                        ),
                        const SizedBox(width: 16),
                        // Rival HUD
                        _buildHudCard(
                          name: 'Rival Crow',
                          tile: gameState.rivalTile,
                          isActive: !gameState.isPlayerTurn,
                          avatar: CustomPaint(
                            size: const Size(36, 36),
                            painter: RivalCrowPainter(),
                          ),
                          isPlayer: false,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Floating Event Alert Banner
            if (widget.isMultiplayer ? _localEventType != null : gameState.eventType != null)
              Positioned(
                top: 90,
                left: 0,
                right: 0,
                child: Center(
                  child: _buildEventBanner(
                    widget.isMultiplayer ? _localEventType! : gameState.eventType!,
                    widget.isMultiplayer ? _localEventSpaces : gameState.eventSpaces,
                    localizations,
                  ),
                ),
              ),

            // Bottom controls (Dice button)
            Positioned(
              bottom: 24,
              right: 24,
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Turn Indicator Label above Dice
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: widget.isMultiplayer
                            ? (mpState.currentTurn == myUid ? GameTheme.primaryGreen : Colors.blueGrey)
                            : (gameState.isPlayerTurn ? GameTheme.primaryGreen : Colors.blueGrey),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: GameTheme.softShadows,
                      ),
                      child: Text(
                        widget.isMultiplayer
                            ? (mpState.currentTurn == myUid
                                ? (ref.watch(localeProvider).languageCode == 'uz' ? "Sizning navbatingiz" : (ref.watch(localeProvider).languageCode == 'ru' ? "Ваш ход" : "Your Turn"))
                                : (ref.watch(localeProvider).languageCode == 'uz'
                                    ? "${mpState.players[mpState.currentTurn]?.name ?? 'Raqib'} navbati"
                                    : (ref.watch(localeProvider).languageCode == 'ru'
                                        ? "Ход ${mpState.players[mpState.currentTurn]?.name ?? 'соперника'}"
                                        : "Turn: ${mpState.players[mpState.currentTurn]?.name ?? 'Player'}")))
                            : _getTurnLabel(context, gameState),
                        style: GoogleFonts.fredoka(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Dice Button (guarded against spam taps)
                    AnimatedDice(
                      value: widget.isMultiplayer ? _localDiceValue : gameState.diceValue,
                      isRolling: widget.isMultiplayer ? _isLocalRolling : gameState.isRolling,
                      onTap: widget.isMultiplayer
                          ? ((mpState.currentTurn == myUid && !_isLocalRolling && mpState.status == 'playing')
                              ? () => _rollMultiplayerDice()
                              : null)
                          : ((gameState.isPlayerTurn && !gameState.isRolling && !gameState.isGameOver && !gameState.isProcessingMove)
                              ? () => ref.read(gameStateProvider.notifier).rollPlayerDice()
                              : null),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _rollMultiplayerDice() async {
    final mpState = ref.read(multiplayerProvider);
    final myUid = ref.read(firebaseServiceProvider).currentUser?.uid;
    if (mpState.currentTurn != myUid || _isLocalRolling) return;

    setState(() {
      _isLocalRolling = true;
      _localEventType = null;
      _localEventSpaces = null;
    });

    // 1. Roll animation (1.5s)
    await Future.delayed(const Duration(milliseconds: 1500));

    final roll = math.Random().nextInt(6) + 1;
    setState(() {
      _isLocalRolling = false;
      _localDiceValue = roll;
    });

    // 2. Get current position
    final int currentPos = mpState.positions[myUid] ?? 1;
    int newTile = currentPos + roll;
    final totalTiles = mpState.activeMap.totalTiles;

    if (newTile >= totalTiles) {
      newTile = totalTiles;
      // Winning move
      await ref.read(multiplayerProvider.notifier).submitMove(
        newPosition: newTile,
        getsExtraTurn: false,
        skipsNextTurn: false,
      );
      return;
    }

    // Wait for the token jumping animation (approx 220ms per tile + settle)
    await Future.delayed(Duration(milliseconds: roll * 220 + 200));

    // 3. Handle special tiles
    bool getsExtraTurn = false;
    bool skipsNextTurn = false;

    if (mpState.windTiles.containsKey(newTile)) {
      final spaces = mpState.windTiles[newTile]!;
      setState(() {
        _localEventType = 'wind';
        _localEventSpaces = spaces;
      });
      await Future.delayed(const Duration(milliseconds: 1500));
      newTile = (newTile + spaces).clamp(1, totalTiles);
      await Future.delayed(Duration(milliseconds: spaces * 220 + 200));
    } else if (mpState.fogTiles.containsKey(newTile)) {
      final spaces = mpState.fogTiles[newTile]!;
      setState(() {
        _localEventType = 'fog';
        _localEventSpaces = spaces;
      });
      await Future.delayed(const Duration(milliseconds: 1500));
      newTile = (newTile - spaces).clamp(1, totalTiles);
      await Future.delayed(Duration(milliseconds: spaces * 220 + 200));
    } else if (mpState.napTiles.contains(newTile)) {
      setState(() {
        _localEventType = 'nap';
      });
      skipsNextTurn = true;
      await Future.delayed(const Duration(milliseconds: 1500));
    } else if (mpState.cloverTiles.contains(newTile)) {
      setState(() {
        _localEventType = 'clover';
      });
      getsExtraTurn = true;
      await Future.delayed(const Duration(milliseconds: 1500));
    } else if (mpState.startTiles.contains(newTile)) {
      setState(() {
        _localEventType = 'start';
      });
      newTile = 1;
      await Future.delayed(const Duration(milliseconds: 1500));
    }

    // 4. Submit move to Firebase
    await ref.read(multiplayerProvider.notifier).submitMove(
      newPosition: newTile,
      getsExtraTurn: getsExtraTurn,
      skipsNextTurn: skipsNextTurn,
    );

    // Clear event banner
    setState(() {
      _localEventType = null;
      _localEventSpaces = null;
    });
  }

  Widget _buildHudCard({
    required String name,
    required int tile,
    required bool isActive,
    required Widget avatar,
    required bool isPlayer,
  }) {
    final localizations = AppLocalizations.of(context)!;
    final accentColor = isPlayer ? GameTheme.primaryGreen : const Color(0xFF37474F);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isActive ? 0.95 : 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? accentColor : Colors.black12,
          width: isActive ? 3.0 : 1.5,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.35),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                )
              ]
            : GameTheme.softShadows,
      ),
      padding: const EdgeInsets.all(10.0),
      width: 170,
      child: Row(
        children: [
          // Token avatar
          SizedBox(
            width: 36,
            height: 36,
            child: avatar,
          ),
          const SizedBox(width: 8),
          
          // Stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: GoogleFonts.fredoka(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: GameTheme.darkWood,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  localizations.tileStatus(tile),
                  style: GoogleFonts.fredoka(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    final lang = ref.watch(localeProvider).languageCode;
    
    // Custom dialog translations
    String dialogTitle = 'Exit Game?';
    String dialogContent = 'Are you sure you want to end this quest and return to the main menu?';
    String cancelLabel = 'Cancel';
    String exitLabel = 'Exit';

    if (lang == 'uz') {
      dialogTitle = 'Oʻyindan chiqish?';
      dialogContent = 'Sarguzashtni tugatib, asosiy menyuga qaytishni xohlaysizmi?';
      cancelLabel = 'Bekor qilish';
      exitLabel = 'Chiqish';
    } else if (lang == 'ru') {
      dialogTitle = 'Выйти из игры?';
      dialogContent = 'Вы уверены, что хотите завершить квест и вернуться в главное меню?';
      cancelLabel = 'Отмена';
      exitLabel = 'Выйти';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        shape: BoxShape.circle,
        boxShadow: GameTheme.softShadows,
      ),
      child: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF8D6E63), size: 24),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Text(
                  dialogTitle,
                  style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, color: GameTheme.darkWood),
                ),
                content: Text(
                  dialogContent,
                  style: GoogleFonts.fredoka(),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(cancelLabel, style: GoogleFonts.fredoka(color: Colors.grey)),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // pop dialog
                      if (widget.isMultiplayer) {
                        ref.read(multiplayerProvider.notifier).leaveRoom();
                      } else {
                        ref.read(selectedCharacterProvider.notifier).state = null;
                        ref.read(gameStateProvider.notifier).resetGame();
                      }
                      Navigator.of(context).pop(); // pop game screen
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: GameTheme.woodBrown),
                    child: Text(exitLabel, style: GoogleFonts.fredoka(color: Colors.white)),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        shape: BoxShape.circle,
        boxShadow: GameTheme.softShadows,
      ),
      child: IconButton(
        icon: const Icon(Icons.help_outline_rounded, color: Color(0xFF8D6E63), size: 24),
        onPressed: () => _showTilesInfoDialog(context),
      ),
    );
  }

  void _showTilesInfoDialog(BuildContext context) {
    final lang = ref.read(localeProvider).languageCode;
    
    String title = 'Game Rules & Special Tiles';
    if (lang == 'uz') {
      title = 'Oʻyin qoidalari va Maxsus kataklar';
    } else if (lang == 'ru') {
      title = 'Правила игры и Особые клетки';
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          titlePadding: const EdgeInsets.fromLTRB(24, 16, 8, 8),
          title: Row(
            children: [
              const SizedBox(width: 32),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.fredoka(
                    fontWeight: FontWeight.bold,
                    color: GameTheme.darkWood,
                    fontSize: 22,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: Color(0xFF8D6E63),
                  size: 28,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildInfoTileItem(
                    label: lang == 'uz' ? 'Mavjli Shamol' : (lang == 'ru' ? 'Ветер' : 'Friendly Wind'),
                    desc: lang == 'uz' ? 'Qahramonni bir necha katak oldinga uchirib yuboradi.' : (lang == 'ru' ? 'Переносит героя на несколько клеток вперед.' : 'Blows the hero forward by several spaces.'),
                    color: const Color(0xFFE0F7FA),
                    borderColor: const Color(0xFF00ACC1),
                    icon: Icons.air_rounded,
                  ),
                  const SizedBox(height: 10),
                  _buildInfoTileItem(
                    label: lang == 'uz' ? 'Qalin Tuman' : (lang == 'ru' ? 'Туман' : 'Thick Fog'),
                    desc: lang == 'uz' ? 'Adashib qolib, bir necha katak orqaga qaytasiz.' : (lang == 'ru' ? 'Герой сбивается с пути и отступает назад.' : 'Hero gets lost and retreats backward.'),
                    color: const Color(0xFFECEFF1),
                    borderColor: const Color(0xFF78909C),
                    icon: Icons.cloud_rounded,
                  ),
                  const SizedBox(height: 10),
                  _buildInfoTileItem(
                    label: lang == 'uz' ? 'Daraxt Soyasi' : (lang == 'ru' ? 'Сон под деревом' : 'Tree Nap'),
                    desc: lang == 'uz' ? 'Qahramon dam oladi va keyingi navbatni oʻtkazib yuboradi.' : (lang == 'ru' ? 'Герой засыпает и пропускает следующий ход.' : 'Hero falls asleep and skips the next turn.'),
                    color: const Color(0xFFF3E5F5),
                    borderColor: const Color(0xFFAB47BC),
                    icon: Icons.hotel_rounded,
                  ),
                  const SizedBox(height: 10),
                  _buildInfoTileItem(
                    label: lang == 'uz' ? 'Omadli Beda' : (lang == 'ru' ? 'Клевер удачи' : 'Lucky Clover'),
                    desc: lang == 'uz' ? 'Toʻrt bargli beda yana bir marta tosh otish imkonini beradi.' : (lang == 'ru' ? 'Четырехлистный клевер дает дополнительный ход.' : 'Four-leaf clover grants an extra dice roll.'),
                    color: const Color(0xFFE8F5E9),
                    borderColor: GameTheme.primaryGreen,
                    icon: Icons.stars_rounded,
                  ),
                  const SizedBox(height: 10),
                  _buildInfoTileItem(
                    label: lang == 'uz' ? 'Adashib Qolish' : (lang == 'ru' ? 'Портал на старт' : 'Lost Hazard'),
                    desc: lang == 'uz' ? 'Eng katta xavfli katak! Qahramonni butunlay 1-katakchaga qaytaradi.' : (lang == 'ru' ? 'Самая опасная клетка! Возвращает героя на 1-ю стартовую клетку.' : 'The ultimate hazard! Returns the hero completely to start Tile 1.'),
                    color: const Color(0xFFFFEBEE),
                    borderColor: const Color(0xFFE57373),
                    icon: Icons.replay_rounded,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoTileItem({
    required String label,
    required String desc,
    required Color color,
    required Color borderColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Row(
        children: [
          Icon(icon, color: borderColor, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 15, color: GameTheme.darkWood),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: GoogleFonts.fredoka(fontSize: 13, color: GameTheme.darkWood.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTurnLabel(BuildContext context, GameState gameState) {
    final localizations = AppLocalizations.of(context)!;
    final lang = ref.watch(localeProvider).languageCode;
    
    if (gameState.isPlayerTurn) {
      return localizations.turnStatus;
    } else {
      if (lang == 'uz') {
        return "Raqib navbati";
      } else if (lang == 'ru') {
        return "Ход соперника";
      } else {
        return "Rival's Turn";
      }
    }
  }

  Widget _buildEventBanner(String type, int? spaces, AppLocalizations localizations) {
    String message = '';
    Color color = Colors.white;
    IconData icon = Icons.info;

    switch (type) {
      case 'nap':
        message = localizations.eventNap;
        color = const Color(0xFFAB47BC); // Purple
        icon = Icons.hotel_rounded;
        break;
      case 'wind':
        message = localizations.eventWind(spaces ?? 0);
        color = const Color(0xFF00ACC1); // Cyan
        icon = Icons.air_rounded;
        break;
      case 'clover':
        message = localizations.eventClover;
        color = GameTheme.primaryGreen; // Green
        icon = Icons.stars_rounded;
        break;
      case 'fog':
        message = localizations.eventFog(spaces ?? 0);
        color = const Color(0xFF78909C); // Slate grey
        icon = Icons.cloud_rounded;
        break;
      case 'start':
        message = localizations.eventStart;
        color = const Color(0xFFE57373); // Red/pink hazard
        icon = Icons.replay_rounded;
        break;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              margin: const EdgeInsets.symmetric(horizontal: 32.0),
              constraints: const BoxConstraints(maxWidth: 480),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: GoogleFonts.fredoka(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getLocalizedCharacterName(BuildContext context, GameCharacter? character) {
    if (character == null) return 'Hero';
    final localizations = AppLocalizations.of(context)!;
    switch (character) {
      case GameCharacter.fox:
        return localizations.characterFox;
      case GameCharacter.rabbit:
        return localizations.characterRabbit;
      case GameCharacter.bear:
        return localizations.characterBear;
      case GameCharacter.squirrel:
        return localizations.characterSquirrel;
    }
  }
}

/// Helper Custom Painter to draw forest side elements in wide aspect ratios
class ForestSideDecorationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.shade900.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    // Draw some simple vector tree blobs on the left and right edges
    final leftTree = Path()
      ..moveTo(0, size.height * 0.2)
      ..quadraticBezierTo(size.width * 0.1, size.height * 0.25, size.width * 0.05, size.height * 0.35)
      ..quadraticBezierTo(size.width * 0.12, size.height * 0.45, 0, size.height * 0.5)
      ..close();
    canvas.drawPath(leftTree, paint);

    final rightTree = Path()
      ..moveTo(size.width, size.height * 0.5)
      ..quadraticBezierTo(size.width * 0.9, size.height * 0.6, size.width * 0.95, size.height * 0.7)
      ..quadraticBezierTo(size.width * 0.88, size.height * 0.8, size.width, size.height * 0.85)
      ..close();
    canvas.drawPath(rightTree, paint);
  }

  @override
  bool shouldRepaint(covariant ForestSideDecorationPainter oldDelegate) => false;
}
