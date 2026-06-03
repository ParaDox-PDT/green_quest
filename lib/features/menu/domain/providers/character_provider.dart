import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Supported game characters
enum GameCharacter {
  fox,
  rabbit,
  bear,
  squirrel;

  /// Returns translation key for character name
  String get nameKey {
    switch (this) {
      case GameCharacter.fox:
        return 'characterFox';
      case GameCharacter.rabbit:
        return 'characterRabbit';
      case GameCharacter.bear:
        return 'characterBear';
      case GameCharacter.squirrel:
        return 'characterSquirrel';
    }
  }

  /// Returns visual base color associated with each animal
  int get colorHex {
    switch (this) {
      case GameCharacter.fox:
        return 0xFFFF7043; // Cute orange
      case GameCharacter.rabbit:
        return 0xFF9575CD; // Cute purple
      case GameCharacter.bear:
        return 0xFF8D6E63; // Warm brown
      case GameCharacter.squirrel:
        return 0xFFFFB74D; // Light golden squirrel orange
    }
  }
}

/// Provider managing the selected game character.
/// Initially null, requiring selection before starting the game.
final selectedCharacterProvider = StateProvider<GameCharacter?>((ref) => null);
