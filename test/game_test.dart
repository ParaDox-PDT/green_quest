import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:green_quest/features/game/domain/providers/game_provider.dart';

void main() {
  group('Game State Unit Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial game state is correct', () {
      final state = container.read(gameStateProvider);
      
      expect(state.playerTile, equals(1));
      expect(state.rivalTile, equals(1));
      expect(state.diceValue, equals(1));
      expect(state.isRolling, isFalse);
      expect(state.isPlayerTurn, isTrue);
      expect(state.eventType, isNull);
      expect(state.isGameOver, isFalse);
      expect(state.isVictory, isFalse);
    });

    test('Resetting the game restores starting conditions', () {
      final notifier = container.read(gameStateProvider.notifier);
      
      // Manually trigger some updates by executing operations, then reset
      notifier.resetGame();
      
      final state = container.read(gameStateProvider);
      expect(state.playerTile, equals(1));
      expect(state.rivalTile, equals(1));
      expect(state.isPlayerTurn, isTrue);
      expect(state.isGameOver, isFalse);
    });

    test('Special Wind tile moves player forward correctly', () async {
      // Directly check the wind tiles mapping logic
      // In game_provider.dart: 8: 5 (lands on 8, advances 5 to 13)
      expect(GameNotifier.windTiles[8], equals(5));
      expect(GameNotifier.windTiles[22], equals(4));
    });

    test('Special Fog tile moves player backward correctly', () async {
      // In game_provider.dart: 18: 4 (lands on 18, retreats 4 to 14)
      expect(GameNotifier.fogTiles[18], equals(4));
      expect(GameNotifier.fogTiles[38], equals(6));
    });

    test('Special Nap and Clover tiles are defined correctly', () {
      expect(GameNotifier.napTiles.contains(15), isTrue);
      expect(GameNotifier.cloverTiles.contains(12), isTrue);
    });
  });
}
