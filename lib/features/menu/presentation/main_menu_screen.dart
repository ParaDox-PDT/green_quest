import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:green_quest/app/theme/theme.dart';
import 'package:green_quest/core/providers/locale_provider.dart';
import 'package:green_quest/features/game/domain/models/game_map.dart';
import 'package:green_quest/features/game/domain/providers/game_provider.dart';
import 'package:green_quest/features/menu/domain/providers/character_provider.dart';
import 'package:green_quest/features/menu/presentation/widgets/character_painters.dart';
import 'package:green_quest/features/game/presentation/game_screen.dart';
import 'package:green_quest/core/l10n/app_localizations.dart';
import 'package:green_quest/features/menu/presentation/multiplayer_setup_screen.dart';

class MainMenuScreen extends ConsumerWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeLocale = ref.watch(localeProvider);
    final selectedChar = ref.watch(selectedCharacterProvider);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE8F5E9), // Light mint green
              Color(0xFFC8E6C9), // Soft green
              Color(0xFFA5D6A7), // Forest green bottom accent
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Ambient leaf silhouettes in the background
            Positioned(
              left: -40,
              top: -40,
              child: Opacity(
                opacity: 0.15,
                child: CustomPaint(
                  size: const Size(180, 180),
                  painter: DecorativeLeafPainter(),
                ),
              ),
            ),
            Positioned(
              right: -30,
              bottom: -40,
              child: Opacity(
                opacity: 0.15,
                child: CustomPaint(
                  size: const Size(200, 200),
                  painter: DecorativeLeafPainter(rotateAngle: 1.8),
                ),
              ),
            ),

            Positioned.fill(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Row(
                    children: [
                      // LEFT COLUMN: Title Banner & Language Selection
                      Expanded(
                        flex: 4,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final double titleSubtitleSpacer = constraints.maxHeight > 500 ? 8.0 : 4.0;
                            final double midSpacer = constraints.maxHeight > 500 ? 28.0 : 12.0;
                            final double sectionSpacer = constraints.maxHeight > 500 ? 20.0 : 10.0;

                            return SingleChildScrollView(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight,
                                ),
                                child: IntrinsicHeight(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // App Title with playful dropshadow
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          localizations.appTitle,
                                          maxLines: 1,
                                          style: GoogleFonts.fredoka(
                                            fontSize: 38,
                                            fontWeight: FontWeight.bold,
                                            color: GameTheme.darkGreen,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black.withValues(alpha: 0.12),
                                                offset: const Offset(0, 4),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: titleSubtitleSpacer),
                                      // Subtitle or description
                                      Text(
                                        'Forest Roll-and-Move Game',
                                        style: GoogleFonts.fredoka(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: GameTheme.darkWood.withValues(alpha: 0.7),
                                        ),
                                      ),
                                      SizedBox(height: midSpacer),
                                      // Custom Language Switcher Label
                                      Text(
                                        localizations.selectLanguage,
                                        style: GoogleFonts.fredoka(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: GameTheme.darkWood,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      // Language Switcher Custom Capsule Row
                                      _buildLanguageSwitcher(ref, activeLocale.languageCode),
                                      SizedBox(height: sectionSpacer),
                                      Text(
                                        activeLocale.languageCode == 'uz'
                                            ? 'Xaritani Tanlash'
                                            : (activeLocale.languageCode == 'ru'
                                                ? 'Выбор Карты'
                                                : 'Select Map'),
                                        style: GoogleFonts.fredoka(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: GameTheme.darkWood,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildMapSelectionList(ref, activeLocale.languageCode),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // VERTICAL SEPARATOR LINE
                      Container(
                        width: 2,
                        height: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 16.0),
                        color: Colors.black12,
                      ),

                      // RIGHT COLUMN: Character Selection & Play Button
                      Expanded(
                        flex: 6,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              localizations.selectCharacter,
                              style: GoogleFonts.fredoka(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: GameTheme.darkGreen,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Characters row (1x4)
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: GameCharacter.values.map((char) {
                                  final isSelected = selectedChar == char;
                                  return Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                      child: _buildCharacterCard(ref, char, isSelected, localizations),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Action Buttons Wrap (Single Player & Multiplayer)
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 16,
                              runSpacing: 12,
                              children: [
                                // Start Game Button (Single Player)
                                AnimatedScale(
                                  scale: selectedChar != null ? 1.0 : 0.85,
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOutBack,
                                  child: AnimatedOpacity(
                                    opacity: selectedChar != null ? 1.0 : 0.4,
                                    duration: const Duration(milliseconds: 200),
                                    child: _buildPlayButton(context, ref, selectedChar, localizations),
                                  ),
                                ),
                                // Multiplayer Button
                                _buildMultiplayerButton(context, ref, activeLocale.languageCode),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the custom capsule language buttons
  Widget _buildLanguageSwitcher(WidgetRef ref, String activeLangCode) {
    const langs = [
      {'code': 'en', 'label': 'EN'},
      {'code': 'ru', 'label': 'RU'},
      {'code': 'uz', 'label': 'UZ'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12, width: 1.5),
      ),
      padding: const EdgeInsets.all(4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: langs.map((lang) {
          final isSelected = lang['code'] == activeLangCode;
          return GestureDetector(
            onTap: () {
              ref.read(localeProvider.notifier).setLanguageCode(lang['code']!);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? GameTheme.primaryGreen : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                lang['label']!,
                style: GoogleFonts.fredoka(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : GameTheme.darkWood,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Builds a card selector for each character with implicit animations
  Widget _buildCharacterCard(
    WidgetRef ref,
    GameCharacter char,
    bool isSelected,
    AppLocalizations localizations,
  ) {
    final name = _getCharacterName(char, localizations);
    final cardColor = Color(char.colorHex);

    return GestureDetector(
      onTap: () {
        ref.read(selectedCharacterProvider.notifier).state = char;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        transform: Matrix4.diagonal3Values(isSelected ? 1.0 : 0.93, isSelected ? 1.0 : 0.93, 1.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? cardColor : Colors.black12,
            width: isSelected ? 4 : 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: cardColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : GameTheme.softShadows,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Character drawing
            Expanded(
              child: CharacterVectorWidget(character: char, size: 65),
            ),
            const SizedBox(height: 4),
            // Character name
            Text(
              name,
              style: GoogleFonts.fredoka(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? cardColor : GameTheme.darkWood,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Play Button Builder
  Widget _buildPlayButton(
    BuildContext context,
    WidgetRef ref,
    GameCharacter? selectedChar,
    AppLocalizations localizations,
  ) {
    final active = selectedChar != null;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: active
            ? [
                BoxShadow(
                  color: GameTheme.primaryAmber.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                )
              ]
            : null,
      ),
      child: ElevatedButton(
        key: const Key('start_game_button'),
        onPressed: active
            ? () {
                // Initialize the game with the selected map before entering the screen
                final selectedMap = ref.read(selectedMapProvider);
                ref.read(gameStateProvider.notifier).resetGame(map: selectedMap);

                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => const GameScreen(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                            CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
                          ),
                          child: child,
                        ),
                      );
                    },
                    transitionDuration: const Duration(milliseconds: 600),
                  ),
                );
              }
            : null, // Disabled when no character is selected
        style: ElevatedButton.styleFrom(
          backgroundColor: GameTheme.primaryAmber,
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
          disabledBackgroundColor: Colors.grey.shade400,
          disabledForegroundColor: Colors.white,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(localizations.startGame),
            const SizedBox(width: 8),
            const Icon(Icons.play_arrow_rounded, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiplayerButton(BuildContext context, WidgetRef ref, String langCode) {
    String label = 'Multiplayer';
    if (langCode == 'uz') {
      label = 'Koʻp oʻyinchi';
    } else if (langCode == 'ru') {
      label = 'Мультиплеер';
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: GameTheme.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: ElevatedButton(
        key: const Key('multiplayer_button'),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const MultiplayerSetupScreen(),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: GameTheme.primaryGreen,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            const SizedBox(width: 8),
            const Icon(Icons.people_alt_rounded, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMapSelectionList(WidgetRef ref, String langCode) {
    final selectedMap = ref.watch(selectedMapProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: GameMap.availableMaps.map((map) {
        final isSelected = selectedMap.type == map.type;
        return GestureDetector(
          onTap: () {
            ref.read(selectedMapProvider.notifier).state = map;
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 8.0),
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            width: double.infinity,
            decoration: BoxDecoration(
              color: isSelected ? GameTheme.primaryGreen : Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? GameTheme.primaryGreen : Colors.black12,
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: GameTheme.primaryGreen.withValues(alpha: 0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                  color: isSelected ? Colors.white : GameTheme.darkWood.withValues(alpha: 0.5),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    map.getName(langCode),
                    style: GoogleFonts.fredoka(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : GameTheme.darkWood,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getCharacterName(GameCharacter character, AppLocalizations localizations) {
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

/// Simple painter to draw ambient leaf shapes in background corner
class DecorativeLeafPainter extends CustomPainter {
  final double rotateAngle;
  DecorativeLeafPainter({this.rotateAngle = 0});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(rotateAngle);
    canvas.translate(-size.width / 2, -size.height / 2);

    final paint = Paint()
      ..color = Colors.green.shade700.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width * 0.1, size.height * 0.9)
      ..cubicTo(
        size.width * 0.1, size.height * 0.2,
        size.width * 0.8, size.height * 0.1,
        size.width * 0.9, size.height * 0.1,
      )
      ..cubicTo(
        size.width * 0.9, size.height * 0.8,
        size.width * 0.2, size.height * 0.9,
        size.width * 0.1, size.height * 0.9,
      )
      ..close();

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
