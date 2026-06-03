import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:green_quest/app/theme/theme.dart';
import 'package:green_quest/core/l10n/app_localizations.dart';
import 'package:green_quest/core/providers/locale_provider.dart';
import 'package:green_quest/features/menu/domain/providers/character_provider.dart';
import 'package:green_quest/features/menu/presentation/widgets/character_painters.dart';
import 'package:green_quest/features/game/domain/providers/game_provider.dart';
import 'package:green_quest/features/game/presentation/widgets/board_path.dart';
import 'package:green_quest/features/game/presentation/widgets/animated_dice.dart';
import 'package:green_quest/features/game/presentation/widgets/player_token.dart';
import 'package:green_quest/features/game/presentation/game_over_screen.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late ScrollController _scrollController;
  bool _initializedScroll = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTile(int tile) {
    if (!_scrollController.hasClients) return;
    final screenHeight = MediaQuery.of(context).size.height;
    final tileOffset = BoardPath.getTileOffset(tile - 1);
    
    // Centering the tile in the vertical viewport
    final double targetY = tileOffset.dy - (screenHeight / 2);
    final double maxScroll = _scrollController.position.maxScrollExtent;
    final double clampedY = targetY.clamp(0.0, maxScroll);

    _scrollController.animateTo(
      clampedY,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    final selectedChar = ref.watch(selectedCharacterProvider);
    final localizations = AppLocalizations.of(context)!;

    // Listen to changes in game state for navigation and camera follow
    ref.listen<GameState>(gameStateProvider, (previous, next) {
      // 1. Navigation to Game Over Screen
      if (next.isGameOver && !(previous?.isGameOver ?? false)) {
        Future.delayed(const Duration(milliseconds: 1400), () {
          if (!context.mounted) return;
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const GameOverScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 600),
            ),
          );
        });
        return;
      }

      // 2. Camera Auto-Follow
      if (previous == null) return;
      
      if (next.isPlayerTurn && next.playerTile != previous.playerTile) {
        Future.delayed(const Duration(milliseconds: 250), () {
          if (mounted) _scrollToTile(next.playerTile);
        });
      } else if (!next.isPlayerTurn && next.rivalTile != previous.rivalTile) {
        Future.delayed(const Duration(milliseconds: 250), () {
          if (mounted) _scrollToTile(next.rivalTile);
        });
      } else if (next.isPlayerTurn != previous.isPlayerTurn) {
        if (mounted) {
          _scrollToTile(next.isPlayerTurn ? next.playerTile : next.rivalTile);
        }
      }
    });

    // Schedule initial scroll to the bottom of the board
    if (!_initializedScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          setState(() {
            _initializedScroll = true;
          });
        }
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
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Center(
                  child: Container(
                    width: BoardPath.boardWidth,
                    height: BoardPath.boardHeight,
                    margin: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Winding Path & Tile Points
                        Positioned.fill(
                          child: CustomPaint(
                            painter: BoardPathPainter(
                              playerTile: gameState.playerTile,
                              rivalTile: gameState.rivalTile,
                            ),
                          ),
                        ),

                        // Animated Player Token
                        PlayerToken(
                          character: selectedChar,
                          tile: gameState.playerTile,
                          offsetX: playerOffset,
                        ),

                        // Animated Rival Token (Rival Crow)
                        PlayerToken(
                          character: null, // Draws Rival Crow
                          tile: gameState.rivalTile,
                          offsetX: rivalOffset,
                        ),
                      ],
                    ),
                  ),
                ),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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

                      // Back to Menu Button
                      _buildBackButton(context),

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
                  ),
                ),
              ),
            ),

            // Floating Event Alert Banner
            if (gameState.eventType != null)
              Positioned(
                top: 90,
                left: 0,
                right: 0,
                child: Center(
                  child: _buildEventBanner(gameState.eventType!, gameState.eventSpaces, localizations),
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
                        color: gameState.isPlayerTurn ? GameTheme.primaryGreen : Colors.blueGrey,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: GameTheme.softShadows,
                      ),
                      child: Text(
                        gameState.isPlayerTurn ? localizations.turnStatus : 'Rival Thinking...',
                        style: GoogleFonts.fredoka(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Dice Button
                    AnimatedDice(
                      value: gameState.diceValue,
                      isRolling: gameState.isRolling,
                      onTap: (gameState.isPlayerTurn && !gameState.isRolling && !gameState.isGameOver)
                          ? () => ref.read(gameStateProvider.notifier).rollPlayerDice()
                          : null,
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
                      ref.read(selectedCharacterProvider.notifier).state = null;
                      ref.read(gameStateProvider.notifier).resetGame();
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
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
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
