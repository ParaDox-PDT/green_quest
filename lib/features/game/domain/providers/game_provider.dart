import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Represents the active state of the Green Quest game.
class GameState {
  final int playerTile;
  final int rivalTile;
  final int diceValue;
  final bool isRolling;
  final bool isPlayerTurn;
  final String? eventType; // 'nap', 'wind', 'clover', 'fog', 'start', or null
  final int? eventSpaces;   // number of spaces affected
  final bool isGameOver;
  final bool isVictory;

  const GameState({
    this.playerTile = 1,
    this.rivalTile = 1,
    this.diceValue = 1,
    this.isRolling = false,
    this.isPlayerTurn = true,
    this.eventType,
    this.eventSpaces,
    this.isGameOver = false,
    this.isVictory = false,
  });

  GameState copyWith({
    int? playerTile,
    int? rivalTile,
    int? diceValue,
    bool? isRolling,
    bool? isPlayerTurn,
    String? eventType,
    int? eventSpaces,
    bool? isGameOver,
    bool? isVictory,
    bool clearEvent = false,
  }) {
    return GameState(
      playerTile: playerTile ?? this.playerTile,
      rivalTile: rivalTile ?? this.rivalTile,
      diceValue: diceValue ?? this.diceValue,
      isRolling: isRolling ?? this.isRolling,
      isPlayerTurn: isPlayerTurn ?? this.isPlayerTurn,
      eventType: clearEvent ? null : (eventType ?? this.eventType),
      eventSpaces: clearEvent ? null : (eventSpaces ?? this.eventSpaces),
      isGameOver: isGameOver ?? this.isGameOver,
      isVictory: isVictory ?? this.isVictory,
    );
  }
}

/// Managing board game rules and state transitions.
class GameNotifier extends StateNotifier<GameState> {
  GameNotifier() : super(const GameState());

  // Define Special Action Tiles
  // Tile index corresponds to 1-based board positions
  static const Map<int, int> windTiles = {
    8: 5,   // advance 5
    22: 4,  // advance 4
    45: 6,  // advance 6
    72: 5,  // advance 5
    88: 4,  // advance 4
  };

  static const Map<int, int> fogTiles = {
    18: 4,  // back 4
    38: 6,  // back 6
    60: 5,  // back 5
    85: 6,  // back 6
    94: 8,  // back 8
  };

  static const Set<int> napTiles = {15, 30, 48, 65, 82};
  static const Set<int> cloverTiles = {12, 35, 55, 78};

  final math.Random _random = math.Random();

  // Internal flags to track status
  bool _playerSkipsNextTurn = false;
  bool _rivalSkipsNextTurn = false;

  /// Resets the game to start conditions
  void resetGame() {
    state = const GameState();
    _playerSkipsNextTurn = false;
    _rivalSkipsNextTurn = false;
  }

  /// Triggers the player's turn to roll the dice
  Future<void> rollPlayerDice() async {
    if (state.isRolling || !state.isPlayerTurn || state.isGameOver) return;

    // 1. Start dice rolling animation
    state = state.copyWith(isRolling: true, clearEvent: true);
    
    // Simulate dice rolling delay (1.5 seconds)
    await Future.delayed(const Duration(milliseconds: 1500));
    
    final roll = _random.nextInt(6) + 1;
    
    // 2. Set dice value and end rolling status
    state = state.copyWith(isRolling: false, diceValue: roll);

    // Calculate next tile
    int newTile = state.playerTile + roll;
    if (newTile >= 100) {
      newTile = 100;
      state = state.copyWith(
        playerTile: newTile,
        isGameOver: true,
        isVictory: true,
      );
      return;
    }

    // Update player position
    state = state.copyWith(playerTile: newTile);

    // Wait for the token jumping animation to complete in the UI (approx 200ms per tile = roll * 200 + settle)
    await Future.delayed(Duration(milliseconds: roll * 220 + 200));

    // 3. Process special tile event at landing position
    await _handleSpecialTile(newTile, isPlayer: true);

    if (state.isGameOver) return;

    // 4. Switch turns
    if (state.eventType == 'clover') {
      // Clover gives extra turn, don't switch turns!
      // Clear event banner after 2 seconds
      await Future.delayed(const Duration(milliseconds: 2000));
      state = state.copyWith(clearEvent: true);
    } else {
      // Normal switch to rival
      await Future.delayed(const Duration(milliseconds: 1500));
      state = state.copyWith(isPlayerTurn: false, clearEvent: true);
      
      // Execute computer rival's turn
      await _executeRivalTurn();
    }
  }

  /// Executes the computer logic for the rival
  Future<void> _executeRivalTurn() async {
    if (state.isGameOver || state.isPlayerTurn) return;

    // Check if rival skips turn
    if (_rivalSkipsNextTurn) {
      _rivalSkipsNextTurn = false;
      state = state.copyWith(
        eventType: 'nap',
        isPlayerTurn: true,
      );
      await Future.delayed(const Duration(milliseconds: 2500));
      state = state.copyWith(clearEvent: true);
      return;
    }

    // Wait slightly before rival rolls to look natural (e.g. 1 sec)
    await Future.delayed(const Duration(milliseconds: 1000));

    state = state.copyWith(isRolling: true);
    await Future.delayed(const Duration(milliseconds: 1500));

    final roll = _random.nextInt(6) + 1;
    state = state.copyWith(isRolling: false, diceValue: roll);

    int newTile = state.rivalTile + roll;
    if (newTile >= 100) {
      newTile = 100;
      state = state.copyWith(
        rivalTile: newTile,
        isGameOver: true,
        isVictory: false,
      );
      return;
    }

    state = state.copyWith(rivalTile: newTile);

    // Wait for jumping animation
    await Future.delayed(Duration(milliseconds: roll * 220 + 200));

    // Handle special tiles for rival
    await _handleSpecialTile(newTile, isPlayer: false);

    if (state.isGameOver) return;

    // Switch back to player (unless rival got clover extra turn)
    if (state.eventType == 'clover') {
      await Future.delayed(const Duration(milliseconds: 2000));
      state = state.copyWith(clearEvent: true);
      await _executeRivalTurn(); // rival plays again!
    } else {
      await Future.delayed(const Duration(milliseconds: 1500));
      
      // Check if player has to skip this upcoming turn
      if (_playerSkipsNextTurn) {
        _playerSkipsNextTurn = false;
        state = state.copyWith(eventType: 'nap', isPlayerTurn: false);
        await Future.delayed(const Duration(milliseconds: 2500));
        state = state.copyWith(clearEvent: true);
        
        // Let rival roll again immediately since player was skipped!
        await _executeRivalTurn();
      } else {
        state = state.copyWith(isPlayerTurn: true, clearEvent: true);
      }
    }
  }

  /// Checks and applies tile actions
  Future<void> _handleSpecialTile(int tile, {required bool isPlayer}) async {
    if (windTiles.containsKey(tile)) {
      // Wind: Advance X spaces
      final spaces = windTiles[tile]!;
      int target = tile + spaces;
      if (target >= 100) target = 100;

      state = state.copyWith(eventType: 'wind', eventSpaces: spaces);
      await Future.delayed(const Duration(milliseconds: 1500));

      if (isPlayer) {
        state = state.copyWith(playerTile: target);
      } else {
        state = state.copyWith(rivalTile: target);
      }
      
      // Wait for second jump animation
      await Future.delayed(Duration(milliseconds: spaces * 220 + 200));

      if (target == 100) {
        state = state.copyWith(isGameOver: true, isVictory: isPlayer);
      }
    } else if (fogTiles.containsKey(tile)) {
      // Fog: Move backward X spaces
      final spaces = fogTiles[tile]!;
      int target = tile - spaces;
      if (target < 1) target = 1;

      state = state.copyWith(eventType: 'fog', eventSpaces: spaces);
      await Future.delayed(const Duration(milliseconds: 1500));

      if (isPlayer) {
        state = state.copyWith(playerTile: target);
      } else {
        state = state.copyWith(rivalTile: target);
      }

      // Wait for slide back animation
      await Future.delayed(Duration(milliseconds: spaces * 220 + 200));
    } else if (napTiles.contains(tile)) {
      // Nap: Lose next turn
      state = state.copyWith(eventType: 'nap');
      if (isPlayer) {
        _playerSkipsNextTurn = true;
      } else {
        _rivalSkipsNextTurn = true;
      }
      await Future.delayed(const Duration(milliseconds: 1500));
    } else if (cloverTiles.contains(tile)) {
      // Clover: Extra turn
      state = state.copyWith(eventType: 'clover');
      await Future.delayed(const Duration(milliseconds: 1500));
    }
  }
}

/// Provider to access game state and trigger moves
final gameStateProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  return GameNotifier();
});
