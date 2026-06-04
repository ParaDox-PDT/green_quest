import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:green_quest/app/theme/theme.dart';
import 'package:green_quest/core/l10n/app_localizations.dart';
import 'package:green_quest/features/menu/domain/providers/character_provider.dart';
import 'package:green_quest/features/menu/presentation/widgets/character_painters.dart';
import 'package:green_quest/features/game/domain/providers/game_provider.dart';
import 'package:green_quest/features/game/presentation/game_screen.dart';
import 'package:green_quest/features/game/domain/providers/multiplayer_provider.dart';
import 'package:green_quest/core/services/firebase_service.dart';
import 'package:green_quest/core/providers/locale_provider.dart';

class GameOverScreen extends ConsumerStatefulWidget {
  final bool isMultiplayer;
  const GameOverScreen({super.key, this.isMultiplayer = false});

  @override
  ConsumerState<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends ConsumerState<GameOverScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _sparkleController;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.elasticOut,
      ),
    );
    
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedChar = ref.watch(selectedCharacterProvider);
    final gameState = ref.read(gameStateProvider);
    final mpState = ref.watch(multiplayerProvider);
    final myUid = ref.watch(firebaseServiceProvider).currentUser?.uid;
    final localizations = AppLocalizations.of(context)!;

    final String? winnerId = widget.isMultiplayer && mpState.playerOrder.isNotEmpty
        ? mpState.playerOrder.reduce((curr, next) => (mpState.positions[curr] ?? 1) > (mpState.positions[next] ?? 1) ? curr : next)
        : null;
    final winnerPlayer = winnerId != null ? mpState.players[winnerId] : null;

    final bool isVictory = widget.isMultiplayer
        ? (winnerId == myUid)
        : gameState.isVictory;

    final themeColor = isVictory ? GameTheme.primaryGreen : Colors.blueGrey;
    final cardBgColor = Colors.white.withValues(alpha: 0.9);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isVictory
                ? [
                    const Color(0xFFE8F5E9), // Soft green
                    const Color(0xFFA5D6A7), // Forest green accent
                  ]
                : [
                    const Color(0xFFECEFF1), // Cold grey
                    const Color(0xFFCFD8DC), // Heavy grey accent
                  ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // Ambient particle/rays overlay
            if (isVictory)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _sparkleController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: VictorySparksPainter(progress: _sparkleController.value),
                    );
                  },
                ),
              ),

            Center(
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _fadeController,
                  child: Container(
                    width: 520,
                    padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: themeColor.withValues(alpha: 0.4),
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: themeColor.withValues(alpha: 0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Victory/Defeat Header Text
                        Text(
                          isVictory ? 'VICTORY!' : 'GAME OVER',
                          style: GoogleFonts.fredoka(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: themeColor,
                            letterSpacing: 2,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                offset: const Offset(0, 2),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Message
                        Text(
                          widget.isMultiplayer
                              ? (isVictory
                                  ? (ref.watch(localeProvider).languageCode == 'uz'
                                      ? "Siz oʻrmon chempioni boʻldingiz! Sarguzasht muvaffaqiyatli yakunlandi."
                                      : (ref.watch(localeProvider).languageCode == 'ru'
                                          ? "Вы чемпион леса! Квест успешно пройден."
                                          : "You are the Forest Champion! Quest completed successfully."))
                                  : (ref.watch(localeProvider).languageCode == 'uz'
                                      ? "Gʻolib: ${winnerPlayer?.name ?? 'Raqib'}"
                                      : (ref.watch(localeProvider).languageCode == 'ru'
                                          ? "Победитель: ${winnerPlayer?.name ?? 'Соперник'}"
                                          : "Winner: ${winnerPlayer?.name ?? 'Rival'}")))
                              : (isVictory ? localizations.victoryMessage : localizations.defeatMessage),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.fredoka(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: GameTheme.darkWood.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Placements/Leaderboard
                        if (widget.isMultiplayer)
                          Container(
                            height: 120,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: () {
                                final sortedPlayers = List<String>.from(mpState.playerOrder)
                                  ..sort((a, b) => (mpState.positions[b] ?? 1).compareTo(mpState.positions[a] ?? 1));

                                return sortedPlayers.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final playerId = entry.value;
                                  final player = mpState.players[playerId];
                                  final pos = mpState.positions[playerId] ?? 1;

                                  if (player == null) return const SizedBox.shrink();

                                  final medalColor = index == 0
                                      ? const Color(0xFFFFD700)
                                      : (index == 1
                                          ? const Color(0xFFC0C0C0)
                                          : (index == 2
                                              ? const Color(0xFFCD7F32)
                                              : Colors.grey.shade400));

                                  return Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: medalColor, width: 2),
                                      boxShadow: GameTheme.softShadows,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          "${index + 1}-oʻrin",
                                          style: GoogleFonts.fredoka(
                                            fontWeight: FontWeight.bold,
                                            color: medalColor,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        if (player.figure != null)
                                          CharacterVectorWidget(character: player.figure!, size: 30)
                                        else
                                          const Icon(Icons.person, size: 30),
                                        const SizedBox(height: 4),
                                        Text(
                                          player.name,
                                          style: GoogleFonts.fredoka(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: GameTheme.darkWood,
                                          ),
                                        ),
                                        Text(
                                          "Katak: $pos",
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: Colors.grey.shade600,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList();
                              }(),
                            ),
                          )
                        else
                          // Large character graphics (Single Player)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (selectedChar != null) ...[
                                Column(
                                  children: [
                                    Text(
                                      isVictory ? 'Hero' : 'Oops!',
                                      style: GoogleFonts.fredoka(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: GameTheme.darkWood,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Transform.scale(
                                      scale: isVictory ? 1.1 : 0.9,
                                      child: Opacity(
                                        opacity: isVictory ? 1.0 : 0.6,
                                        child: CharacterVectorWidget(
                                          character: selectedChar,
                                          size: 90,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 48),
                              ],
                              Column(
                                children: [
                                  Text(
                                    isVictory ? 'Rival' : 'Winner!',
                                    style: GoogleFonts.fredoka(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: GameTheme.darkWood,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Transform.scale(
                                    scale: isVictory ? 0.8 : 1.15,
                                    child: Opacity(
                                      opacity: isVictory ? 0.5 : 1.0,
                                      child: CustomPaint(
                                        size: const Size(90, 90),
                                        painter: RivalCrowPainter(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        const SizedBox(height: 28),

                        // Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (!widget.isMultiplayer)
                              // Play Again (Single Player Only)
                              _buildActionButton(
                                context: context,
                                label: localizations.playAgain,
                                icon: Icons.replay_rounded,
                                color: GameTheme.primaryGreen,
                                onPressed: () {
                                  ref.read(gameStateProvider.notifier).resetGame();
                                  Navigator.of(context).pushReplacement(
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation, secondaryAnimation) => const GameScreen(),
                                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                        return FadeTransition(opacity: animation, child: child);
                                      },
                                      transitionDuration: const Duration(milliseconds: 500),
                                    ),
                                  );
                                },
                              ),

                            // Main Menu (Both modes)
                            _buildActionButton(
                              context: context,
                              label: localizations.mainMenu,
                              icon: Icons.home_rounded,
                              color: GameTheme.woodBrown,
                              onPressed: () {
                                if (widget.isMultiplayer) {
                                  ref.read(multiplayerProvider.notifier).leaveRoom();
                                } else {
                                  ref.read(gameStateProvider.notifier).resetGame();
                                  ref.read(selectedCharacterProvider.notifier).state = null;
                                }
                                Navigator.of(context).pop(); // pop GameOverScreen
                              },
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: GoogleFonts.fredoka(
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

/// Painter to draw magical sunburst sparks for victory
class VictorySparksPainter extends CustomPainter {
  final double progress;

  VictorySparksPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final double maxRadius = size.longestSide / 2;
    final random = math.Random(42);

    final sparklePaint = Paint()
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 40; i++) {
      final double angle = random.nextDouble() * 2 * math.pi;
      final double baseRadius = random.nextDouble() * maxRadius;
      final double currentRadius = (baseRadius + progress * maxRadius) % maxRadius;
      
      final double sx = cx + currentRadius * math.cos(angle);
      final double sy = cy + currentRadius * math.sin(angle);
      
      final double opacity = (1.0 - (currentRadius / maxRadius)).clamp(0.0, 1.0);
      final double sizeVal = (3.0 + random.nextDouble() * 5.0) * opacity;
      
      sparklePaint.color = Color.lerp(
        Colors.amber,
        Colors.lightGreenAccent,
        random.nextDouble(),
      )!.withValues(alpha: opacity * 0.8);
      
      canvas.drawCircle(Offset(sx, sy), sizeVal, sparklePaint);
    }
  }

  @override
  bool shouldRepaint(covariant VictorySparksPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
