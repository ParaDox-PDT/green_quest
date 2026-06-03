import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:green_quest/app/theme/theme.dart';
import 'package:green_quest/features/menu/domain/providers/character_provider.dart';
import 'package:green_quest/features/menu/presentation/widgets/character_painters.dart';
import 'package:green_quest/core/l10n/app_localizations.dart';

class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedChar = ref.watch(selectedCharacterProvider);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE8F5E9), // Light mint
              Color(0xFFC8E6C9), // Soft green
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                localizations.appTitle,
                style: GoogleFonts.fredoka(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: GameTheme.darkGreen,
                ),
              ),
              const SizedBox(height: 24),
              if (selectedChar != null) ...[
                Text(
                  'Selected Character:',
                  style: GoogleFonts.fredoka(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: GameTheme.darkWood,
                  ),
                ),
                const SizedBox(height: 16),
                CharacterVectorWidget(
                  character: selectedChar,
                  size: 150,
                ),
                const SizedBox(height: 8),
                Text(
                  _getLocalizedCharacterName(context, selectedChar),
                  style: GoogleFonts.fredoka(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(selectedChar.colorHex),
                  ),
                ),
              ],
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () {
                  // Reset character and return
                  ref.read(selectedCharacterProvider.notifier).state = null;
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.arrow_back),
                label: Text(localizations.mainMenu),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GameTheme.woodBrown,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getLocalizedCharacterName(BuildContext context, GameCharacter character) {
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
