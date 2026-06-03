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

    test('Initial game state is correct and has dynamic board', () {
      final state = container.read(gameStateProvider);
      
      expect(state.playerTile, equals(1));
      expect(state.rivalTile, equals(1));
      expect(state.diceValue, equals(1));
      expect(state.isRolling, isFalse);
      expect(state.isPlayerTurn, isTrue);
      expect(state.eventType, isNull);
      expect(state.isGameOver, isFalse);
      expect(state.isVictory, isFalse);

      // Verify dynamic board lists are initialized on startup
      expect(state.windTiles.length, equals(5));
      expect(state.fogTiles.length, equals(5));
      expect(state.napTiles.length, equals(5));
      expect(state.cloverTiles.length, equals(4));
      expect(state.startTiles.length, equals(1));
    });

    test('Resetting the game restores starting conditions and randomizes board', () {
      final notifier = container.read(gameStateProvider.notifier);
      final initialStartTile = container.read(gameStateProvider).startTiles.first;
      expect(initialStartTile >= 70 && initialStartTile <= 90, isTrue);
      
      notifier.resetGame();
      
      final state = container.read(gameStateProvider);
      expect(state.playerTile, equals(1));
      expect(state.rivalTile, equals(1));
      expect(state.isPlayerTurn, isTrue);
      expect(state.isGameOver, isFalse);
      
      // Sometime random shuffles might produce the same start tile, but generally it changes
      // This test ensures board is at least generated correctly
      expect(state.startTiles.length, equals(1));
    });

    test('Special Wind tile advance ranges are correct', () async {
      final state = container.read(gameStateProvider);
      
      state.windTiles.forEach((tile, advance) {
        expect(advance >= 3 && advance <= 6, isTrue);
      });
    });

    test('Special Fog tile retreat ranges are correct', () async {
      final state = container.read(gameStateProvider);
      
      state.fogTiles.forEach((tile, retreat) {
        expect(retreat >= 3 && retreat <= 6, isTrue);
      });
    });

    test('Start hazard tile position is in the late-game range', () {
      final state = container.read(gameStateProvider);
      final startTile = state.startTiles.first;
      expect(startTile >= 70 && startTile <= 90, isTrue);
    });
  });
}
