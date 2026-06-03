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
  final bool isProcessingMove;

  // Dynamic board layout configurations
  final Map<int, int> windTiles;
  final Map<int, int> fogTiles;
  final Set<int> napTiles;
  final Set<int> cloverTiles;
  final Set<int> startTiles; // Contains the return to start tile

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
    this.isProcessingMove = false,
    this.windTiles = const {},
    this.fogTiles = const {},
    this.napTiles = const {},
    this.cloverTiles = const {},
    this.startTiles = const {},
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
    bool? isProcessingMove,
    Map<int, int>? windTiles,
    Map<int, int>? fogTiles,
    Set<int>? napTiles,
    Set<int>? cloverTiles,
    Set<int>? startTiles,
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
      isProcessingMove: isProcessingMove ?? this.isProcessingMove,
      windTiles: windTiles ?? this.windTiles,
      fogTiles: fogTiles ?? this.fogTiles,
      napTiles: napTiles ?? this.napTiles,
      cloverTiles: cloverTiles ?? this.cloverTiles,
      startTiles: startTiles ?? this.startTiles,
    );
  }
}

/// Managing board game rules, dynamic setups, and state transitions.
class GameNotifier extends StateNotifier<GameState> {
  GameNotifier() : super(const GameState()) {
    resetGame();
  }

  final math.Random _random = math.Random();

  // Internal flags to track turn-skips
  bool _playerSkipsNextTurn = false;
  bool _rivalSkipsNextTurn = false;

  /// Resets the game and generates a fresh dynamic board layout
  void resetGame() {
    state = const GameState();
    _playerSkipsNextTurn = false;
    _rivalSkipsNextTurn = false;
    _generateRandomBoard();
  }

  /// Generates non-adjacent, randomized special tiles for the current match
  void _generateRandomBoard() {
    final Map<int, int> wind = {};
    final Map<int, int> fog = {};
    final Set<int> nap = {};
    final Set<int> clover = {};
    final Set<int> start = {};

    final Set<int> taken = {};

    // 1. Place exactly 1 "Return-To-Start" hazard tile in the late-game range (70 to 90)
    final startTilePos = 70 + _random.nextInt(18); // 70 to 87
    start.add(startTilePos);
    taken.add(startTilePos);
    taken.add(startTilePos - 1);
    taken.add(startTilePos + 1);

    // Helper to find a free tile that is not adjacent to any taken tile
    int getFreeTile() {
      int attempts = 0;
      while (attempts < 500) {
        // Safe play range: tiles 8 to 95
        final tile = 8 + _random.nextInt(87);
        if (!taken.contains(tile) && !taken.contains(tile - 1) && !taken.contains(tile + 1)) {
          return tile;
        }
        attempts++;
      }
      // Fallback: any untaken tile
      for (int tile = 8; tile <= 95; tile++) {
        if (!taken.contains(tile)) return tile;
      }
      return 8;
    }

    // 2. Place 5 Wind tiles (advance 3 to 6 spaces)
    for (int i = 0; i < 5; i++) {
      final tile = getFreeTile();
      wind[tile] = 3 + _random.nextInt(4); // advance 3..6
      taken.add(tile);
      taken.add(tile - 1);
      taken.add(tile + 1);
    }

    // 3. Place 5 Fog tiles (back 3 to 6 spaces)
    for (int i = 0; i < 5; i++) {
      final tile = getFreeTile();
      fog[tile] = 3 + _random.nextInt(4); // back 3..6
      taken.add(tile);
      taken.add(tile - 1);
      taken.add(tile + 1);
    }

    // 4. Place 5 Nap tiles (skip turn)
    for (int i = 0; i < 5; i++) {
      final tile = getFreeTile();
      nap.add(tile);
      taken.add(tile);
      taken.add(tile - 1);
      taken.add(tile + 1);
    }

    // 5. Place 4 Clover tiles (extra turn)
    for (int i = 0; i < 4; i++) {
      final tile = getFreeTile();
      clover.add(tile);
      taken.add(tile);
      taken.add(tile - 1);
      taken.add(tile + 1);
    }

    state = state.copyWith(
      windTiles: wind,
      fogTiles: fog,
      napTiles: nap,
      cloverTiles: clover,
      startTiles: start,
    );
  }

  /// Triggers the player's turn to roll the dice (guarded against spam and race conditions)
  Future<void> rollPlayerDice() async {
    if (state.isProcessingMove || state.isRolling || !state.isPlayerTurn || state.isGameOver) return;

    // Lock interaction immediately to prevent double-tap race conditions
    state = state.copyWith(isProcessingMove: true, isRolling: true, clearEvent: true);
    
    // Simulate dice rolling delay (1.5 seconds)
    await Future.delayed(const Duration(milliseconds: 1500));
    
    final roll = _random.nextInt(6) + 1;
    
    // Set dice value and end rolling status
    state = state.copyWith(isRolling: false, diceValue: roll);

    // Calculate next tile
    int newTile = state.playerTile + roll;
    if (newTile >= 100) {
      newTile = 100;
      state = state.copyWith(
        playerTile: newTile,
        isGameOver: true,
        isVictory: true,
        isProcessingMove: false,
      );
      return;
    }

    // Update player position
    state = state.copyWith(playerTile: newTile);

    // Wait for the token jumping animation to complete in the UI (approx 220ms per tile + settle)
    await Future.delayed(Duration(milliseconds: roll * 220 + 200));

    // Process special tile event at landing position
    await _handleSpecialTile(newTile, isPlayer: true);

    if (state.isGameOver) {
      state = state.copyWith(isProcessingMove: false);
      return;
    }

    // Switch turns
    if (state.eventType == 'clover') {
      // Clover gives extra turn, keep turn and clear event banner after 2 seconds
      await Future.delayed(const Duration(milliseconds: 2000));
      state = state.copyWith(clearEvent: true, isProcessingMove: false);
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
      state = state.copyWith(clearEvent: true, isProcessingMove: false);
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
        isProcessingMove: false,
      );
      return;
    }

    state = state.copyWith(rivalTile: newTile);

    // Wait for jumping animation
    await Future.delayed(Duration(milliseconds: roll * 220 + 200));

    // Handle special tiles for rival
    await _handleSpecialTile(newTile, isPlayer: false);

    if (state.isGameOver) {
      state = state.copyWith(isProcessingMove: false);
      return;
    }

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
        state = state.copyWith(isPlayerTurn: true, clearEvent: true, isProcessingMove: false);
      }
    }
  }

  /// Checks and applies tile actions
  Future<void> _handleSpecialTile(int tile, {required bool isPlayer}) async {
    if (state.windTiles.containsKey(tile)) {
      // Wind: Advance X spaces
      final spaces = state.windTiles[tile]!;
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
    } else if (state.fogTiles.containsKey(tile)) {
      // Fog: Move backward X spaces
      final spaces = state.fogTiles[tile]!;
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
    } else if (state.napTiles.contains(tile)) {
      // Nap: Lose next turn
      state = state.copyWith(eventType: 'nap');
      if (isPlayer) {
        _playerSkipsNextTurn = true;
      } else {
        _rivalSkipsNextTurn = true;
      }
      await Future.delayed(const Duration(milliseconds: 1500));
    } else if (state.cloverTiles.contains(tile)) {
      // Clover: Extra turn
      state = state.copyWith(eventType: 'clover');
      await Future.delayed(const Duration(milliseconds: 1500));
    } else if (state.startTiles.contains(tile)) {
      // Start: Lost in woods, return completely to tile 1
      state = state.copyWith(eventType: 'start');
      await Future.delayed(const Duration(milliseconds: 1500));

      if (isPlayer) {
        state = state.copyWith(playerTile: 1);
      } else {
        state = state.copyWith(rivalTile: 1);
      }

      // Wait for the slide back jump animation to finish in UI
      await Future.delayed(const Duration(milliseconds: 1200));
    }
  }
}

/// Provider to access game state and trigger moves
final gameStateProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  return GameNotifier();
});
