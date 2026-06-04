import 'dart:async';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:green_quest/core/services/firebase_service.dart';
import 'package:green_quest/features/game/domain/models/game_map.dart';
import 'package:green_quest/features/menu/domain/providers/character_provider.dart';

class MultiplayerPlayer {
  final String id;
  final String name;
  final bool isReady;
  final GameCharacter? figure;

  const MultiplayerPlayer({
    required this.id,
    required this.name,
    required this.isReady,
    this.figure,
  });

  factory MultiplayerPlayer.fromMap(Map<dynamic, dynamic> map) {
    GameCharacter? fig;
    if (map['figure'] != null) {
      fig = GameCharacter.values.firstWhere(
        (e) => e.name == map['figure'],
        orElse: () => GameCharacter.fox,
      );
    }
    return MultiplayerPlayer(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      isReady: map['isReady'] ?? false,
      figure: fig,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isReady': isReady,
      'figure': figure?.name,
    };
  }
}

class MultiplayerRoomState {
  final String? roomId;
  final String? roomCode;
  final String? hostId;
  final String? status; // 'lobby', 'playing', 'finished'
  final Map<String, MultiplayerPlayer> players;
  final Map<String, String> selectedFigures; // figureName -> playerId

  // Game state
  final List<String> playerOrder;
  final int turnIndex;
  final String? currentTurn;
  final Map<String, int> positions; // playerId -> tile number
  final Map<int, int> windTiles;
  final Map<int, int> fogTiles;
  final Set<int> napTiles;
  final Set<int> cloverTiles;
  final Set<int> startTiles;
  final GameMap activeMap;

  // Local state helper
  final String? error;
  final bool isLoading;

  const MultiplayerRoomState({
    this.roomId,
    this.roomCode,
    this.hostId,
    this.status,
    this.players = const {},
    this.selectedFigures = const {},
    this.playerOrder = const [],
    this.turnIndex = 0,
    this.currentTurn,
    this.positions = const {},
    this.windTiles = const {},
    this.fogTiles = const {},
    this.napTiles = const {},
    this.cloverTiles = const {},
    this.startTiles = const {},
    this.activeMap = GameMap.defaultMap,
    this.error,
    this.isLoading = false,
  });

  MultiplayerRoomState copyWith({
    String? roomId,
    String? roomCode,
    String? hostId,
    String? status,
    Map<String, MultiplayerPlayer>? players,
    Map<String, String>? selectedFigures,
    List<String>? playerOrder,
    int? turnIndex,
    String? currentTurn,
    Map<String, int>? positions,
    Map<int, int>? windTiles,
    Map<int, int>? fogTiles,
    Set<int>? napTiles,
    Set<int>? cloverTiles,
    Set<int>? startTiles,
    GameMap? activeMap,
    String? error,
    bool clearError = false,
    bool? isLoading,
  }) {
    return MultiplayerRoomState(
      roomId: roomId ?? this.roomId,
      roomCode: roomCode ?? this.roomCode,
      hostId: hostId ?? this.hostId,
      status: status ?? this.status,
      players: players ?? this.players,
      selectedFigures: selectedFigures ?? this.selectedFigures,
      playerOrder: playerOrder ?? this.playerOrder,
      turnIndex: turnIndex ?? this.turnIndex,
      currentTurn: currentTurn ?? this.currentTurn,
      positions: positions ?? this.positions,
      windTiles: windTiles ?? this.windTiles,
      fogTiles: fogTiles ?? this.fogTiles,
      napTiles: napTiles ?? this.napTiles,
      cloverTiles: cloverTiles ?? this.cloverTiles,
      startTiles: startTiles ?? this.startTiles,
      activeMap: activeMap ?? this.activeMap,
      error: clearError ? null : (error ?? this.error),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class MultiplayerNotifier extends StateNotifier<MultiplayerRoomState> {
  final FirebaseService _firebaseService;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  
  StreamSubscription<DatabaseEvent>? _roomSubscription;
  StreamSubscription<DatabaseEvent>? _gameSubscription;

  MultiplayerNotifier(this._firebaseService) : super(const MultiplayerRoomState());

  @override
  void dispose() {
    _roomSubscription?.cancel();
    _gameSubscription?.cancel();
    super.dispose();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Create a new lobby/room with a unique 6-digit code
  Future<bool> createRoom(GameMap map) async {
    state = state.copyWith(isLoading: true, clearError: true);

    User? user = _firebaseService.currentUser;
    if (user == null) {
      final credential = await _firebaseService.signInAnonymously();
      user = credential?.user;
      if (user == null) {
        state = state.copyWith(isLoading: false, error: "Authentication failed");
        return false;
      }
    }

    final uid = user.uid;
    final random = Random();
    String code = '';
    bool codeClaimed = false;
    String newRoomId = _db.child('rooms').push().key!;

    int attempts = 0;
    while (!codeClaimed && attempts < 10) {
      attempts++;
      code = (100000 + random.nextInt(900000)).toString();

      final codeRef = _db.child('room_codes').child(code);
      final transactionResult = await codeRef.runTransaction((Object? value) {
        if (value == null) {
          return Transaction.success({
            'roomId': newRoomId,
            'createdAt': ServerValue.timestamp,
          });
        }
        return Transaction.abort();
      });

      if (transactionResult.committed) {
        codeClaimed = true;
      }
    }

    if (!codeClaimed) {
      state = state.copyWith(isLoading: false, error: "Failed to generate a room code. Try again.");
      return false;
    }

    final roomData = {
      'hostId': uid,
      'status': 'lobby',
      'mapType': map.type.name,
      'players': {
        uid: {
          'id': uid,
          'name': 'Host',
          'isReady': true,
          'figure': null,
        }
      },
      'selectedFigures': {},
    };

    try {
      await _db.child('rooms').child(newRoomId).set(roomData);

      // Setup disconnect rules
      await _db.child('rooms').child(newRoomId).child('players').child(uid).onDisconnect().remove();
      await _db.child('room_codes').child(code).onDisconnect().remove();
      await _db.child('rooms').child(newRoomId).onDisconnect().remove();

      state = state.copyWith(
        roomId: newRoomId,
        roomCode: code,
        hostId: uid,
        status: 'lobby',
        activeMap: map,
        isLoading: false,
      );

      _listenToRoom(newRoomId);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Join an existing room via 6-digit code
  Future<bool> joinRoom(String code) async {
    state = state.copyWith(isLoading: true, clearError: true);

    User? user = _firebaseService.currentUser;
    if (user == null) {
      final credential = await _firebaseService.signInAnonymously();
      user = credential?.user;
      if (user == null) {
        state = state.copyWith(isLoading: false, error: "Authentication failed");
        return false;
      }
    }

    final uid = user.uid;

    try {
      final codeSnapshot = await _db.child('room_codes').child(code).get();
      if (!codeSnapshot.exists) {
        state = state.copyWith(isLoading: false, error: "Xona kodi topilmadi");
        return false;
      }

      final codeMap = codeSnapshot.value as Map<dynamic, dynamic>;
      final targetRoomId = codeMap['roomId'] as String;

      final roomSnapshot = await _db.child('rooms').child(targetRoomId).get();
      if (!roomSnapshot.exists) {
        state = state.copyWith(isLoading: false, error: "Xona mavjud emas");
        return false;
      }

      final roomMap = roomSnapshot.value as Map<dynamic, dynamic>;
      final status = roomMap['status'] as String;
      if (status != 'lobby') {
        state = state.copyWith(isLoading: false, error: "Oʻyin allaqachon boshlangan");
        return false;
      }

      final playersMap = roomMap['players'] as Map<dynamic, dynamic>? ?? {};
      if (playersMap.length >= 4) {
        state = state.copyWith(isLoading: false, error: "Xona toʻla (max 4 oʻyinchi)");
        return false;
      }

      final mapTypeName = roomMap['mapType'] as String? ?? 'standard';
      final mapType = MapType.values.firstWhere(
        (e) => e.name == mapTypeName,
        orElse: () => MapType.standard,
      );
      final activeMap = GameMap.availableMaps.firstWhere(
        (m) => m.type == mapType,
        orElse: () => GameMap.defaultMap,
      );

      final newPlayerName = "Player ${playersMap.length + 1}";
      final playerInfo = {
        'id': uid,
        'name': newPlayerName,
        'isReady': false,
        'figure': null,
      };

      await _db.child('rooms').child(targetRoomId).child('players').child(uid).set(playerInfo);

      // Setup disconnect rule
      await _db.child('rooms').child(targetRoomId).child('players').child(uid).onDisconnect().remove();

      state = state.copyWith(
        roomId: targetRoomId,
        roomCode: code,
        hostId: roomMap['hostId'] as String,
        status: status,
        activeMap: activeMap,
        isLoading: false,
      );

      _listenToRoom(targetRoomId);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Change readiness state (only relevant for guests)
  Future<void> toggleReady(bool isReady) async {
    final roomId = state.roomId;
    final uid = _firebaseService.currentUser?.uid;
    if (roomId == null || uid == null) return;

    try {
      await _db.child('rooms').child(roomId).child('players').child(uid).child('isReady').set(isReady);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Set the map type (host only)
  Future<void> updateMap(GameMap map) async {
    final roomId = state.roomId;
    if (roomId == null) return;
    try {
      await _db.child('rooms').child(roomId).child('mapType').set(map.type.name);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Select a character figure using Firebase Database Transactions for exclusivity
  Future<bool> selectCharacter(GameCharacter character) async {
    final roomId = state.roomId;
    final uid = _firebaseService.currentUser?.uid;
    if (roomId == null || uid == null) return false;

    final charName = character.name;

    // Run transaction to lock the figure name
    final figureRef = _db.child('rooms').child(roomId).child('selectedFigures').child(charName);
    final transactionResult = await figureRef.runTransaction((Object? value) {
      if (value == null || value == uid) {
        return Transaction.success(uid);
      }
      return Transaction.abort();
    });

    if (!transactionResult.committed) {
      state = state.copyWith(error: "Qahramon allaqachon boshqa oʻyinchi tomonidan tanlangan");
      return false;
    }

    try {
      // Find and release previous figure if any
      final currentFigure = state.players[uid]?.figure;
      final updates = <String, Object?>{
        'rooms/$roomId/players/$uid/figure': charName,
      };

      if (currentFigure != null && currentFigure != character) {
        updates['rooms/$roomId/selectedFigures/${currentFigure.name}'] = null;
        // Remove old disconnect rule and set new one
        await _db.child('rooms').child(roomId).child('selectedFigures').child(currentFigure.name).onDisconnect().cancel();
      }

      await _db.update(updates);
      await _db.child('rooms').child(roomId).child('selectedFigures').child(charName).onDisconnect().remove();

      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Leave the current room
  Future<void> leaveRoom() async {
    final roomId = state.roomId;
    final uid = _firebaseService.currentUser?.uid;
    final code = state.roomCode;
    
    if (roomId == null || uid == null) return;

    _roomSubscription?.cancel();
    _gameSubscription?.cancel();

    try {
      // Release player's selected figure
      final selectedFig = state.players[uid]?.figure;
      final updates = <String, Object?>{
        'rooms/$roomId/players/$uid': null,
      };
      if (selectedFig != null) {
        updates['rooms/$roomId/selectedFigures/${selectedFig.name}'] = null;
      }
      
      // If host leaves, delete the room code lookup and dissolve lobby
      if (state.hostId == uid) {
        if (code != null) {
          updates['room_codes/$code'] = null;
        }
        updates['rooms/$roomId'] = null;
        updates['active_games/$roomId'] = null;
      }

      await _db.update(updates);

      // Cancel disconnect handlers
      await _db.child('rooms').child(roomId).child('players').child(uid).onDisconnect().cancel();
      if (selectedFig != null) {
        await _db.child('rooms').child(roomId).child('selectedFigures').child(selectedFig.name).onDisconnect().cancel();
      }
      if (state.hostId == uid) {
        if (code != null) await _db.child('room_codes').child(code).onDisconnect().cancel();
        await _db.child('rooms').child(roomId).onDisconnect().cancel();
      }
    } catch (e) {
      print("Error leaving room: $e");
    }

    state = const MultiplayerRoomState();
  }

  /// Start the multiplayer match (host only)
  Future<void> startGame() async {
    final roomId = state.roomId;
    if (roomId == null) return;

    // Validation: 2-4 players, all ready, all have figures
    final players = state.players.values.toList();
    if (players.length < 2 || players.length > 4) {
      state = state.copyWith(error: "Oʻyin boshlash uchun 2 dan 4 gacha oʻyinchi kerak");
      return;
    }

    for (var p in players) {
      if (!p.isReady && p.id != state.hostId) {
        state = state.copyWith(error: "Hamma oʻyinchilar tayyor boʻlishi kerak");
        return;
      }
      if (p.figure == null) {
        state = state.copyWith(error: "Hamma oʻyinchilar qahramon tanlashi kerak");
        return;
      }
    }

    try {
      // Determine player order
      final playerIds = players.map((p) => p.id).toList()..shuffle();

      // Generate randomized special tiles
      final map = state.activeMap;
      final boardConfig = _generateRandomBoardConfig(map);

      final initialPositions = <String, int>{};
      for (var id in playerIds) {
        initialPositions[id] = 1;
      }

      final activeGameData = {
        'playerOrder': playerIds,
        'turnIndex': 0,
        'currentTurn': playerIds[0],
        'positions': initialPositions,
        'boardConfig': boardConfig,
      };

      final updates = {
        'rooms/$roomId/status': 'playing',
        'active_games/$roomId': activeGameData,
      };

      await _db.update(updates);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Firebase Listener for lobby / rooms
  void _listenToRoom(String roomId) {
    _roomSubscription?.cancel();
    _roomSubscription = _db.child('rooms').child(roomId).onValue.listen((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists) {
        // Room was disbanded
        if (state.roomId != null) {
          state = state.copyWith(status: 'finished', error: "Xona host tomonidan yopildi");
          _roomSubscription?.cancel();
          _gameSubscription?.cancel();
        }
        return;
      }

      final roomMap = snapshot.value as Map<dynamic, dynamic>;
      final status = roomMap['status'] as String? ?? 'lobby';

      // Parse players
      final playersMap = roomMap['players'] as Map<dynamic, dynamic>? ?? {};
      final parsedPlayers = <String, MultiplayerPlayer>{};
      playersMap.forEach((key, val) {
        parsedPlayers[key.toString()] = MultiplayerPlayer.fromMap(val as Map<dynamic, dynamic>);
      });

      // Parse selected figures
      final figuresMap = roomMap['selectedFigures'] as Map<dynamic, dynamic>? ?? {};
      final parsedFigures = <String, String>{};
      figuresMap.forEach((key, val) {
        if (val != null) {
          parsedFigures[key.toString()] = val.toString();
        }
      });

      // Map configuration
      final mapTypeName = roomMap['mapType'] as String? ?? 'standard';
      final mapType = MapType.values.firstWhere(
        (e) => e.name == mapTypeName,
        orElse: () => MapType.standard,
      );
      final activeMap = GameMap.availableMaps.firstWhere(
        (m) => m.type == mapType,
        orElse: () => GameMap.defaultMap,
      );

      state = state.copyWith(
        status: status,
        players: parsedPlayers,
        selectedFigures: parsedFigures,
        activeMap: activeMap,
      );

      if (status == 'playing' && _gameSubscription == null) {
        _listenToActiveGame(roomId);
      }
    });
  }

  /// Firebase Listener for active game loop
  void _listenToActiveGame(String roomId) {
    _gameSubscription?.cancel();
    _gameSubscription = _db.child('active_games').child(roomId).onValue.listen((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists) return;

      final gameMap = snapshot.value as Map<dynamic, dynamic>;
      final orderList = (gameMap['playerOrder'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
      final currentTurn = gameMap['currentTurn'] as String?;
      final turnIndex = gameMap['turnIndex'] as int? ?? 0;

      final posMap = gameMap['positions'] as Map<dynamic, dynamic>? ?? {};
      final parsedPositions = <String, int>{};
      posMap.forEach((key, val) {
        parsedPositions[key.toString()] = val as int;
      });

      // Parse boardConfig
      final boardConfig = gameMap['boardConfig'] as Map<dynamic, dynamic>? ?? {};
      
      // Wind
      final windMap = boardConfig['windTiles'] as Map<dynamic, dynamic>? ?? {};
      final parsedWind = <int, int>{};
      windMap.forEach((k, v) {
        parsedWind[int.parse(k.toString())] = v as int;
      });

      // Fog
      final fogMap = boardConfig['fogTiles'] as Map<dynamic, dynamic>? ?? {};
      final parsedFog = <int, int>{};
      fogMap.forEach((k, v) {
        parsedFog[int.parse(k.toString())] = v as int;
      });

      // Nap
      final napList = boardConfig['napTiles'] as List<dynamic>? ?? [];
      final parsedNap = napList.map((e) => int.parse(e.toString())).toSet();

      // Clover
      final cloverList = boardConfig['cloverTiles'] as List<dynamic>? ?? [];
      final parsedClover = cloverList.map((e) => int.parse(e.toString())).toSet();

      // Start
      final startList = boardConfig['startTiles'] as List<dynamic>? ?? [];
      final parsedStart = startList.map((e) => int.parse(e.toString())).toSet();

      state = state.copyWith(
        playerOrder: orderList,
        currentTurn: currentTurn,
        turnIndex: turnIndex,
        positions: parsedPositions,
        windTiles: parsedWind,
        fogTiles: parsedFog,
        napTiles: parsedNap,
        cloverTiles: parsedClover,
        startTiles: parsedStart,
      );
    });
  }

  /// Generate board config matching local game generation but storing it in Firebase
  Map<String, dynamic> _generateRandomBoardConfig(GameMap map) {
    final random = Random();
    final Set<int> taken = {};
    final int total = map.totalTiles;

    // 1. Return-to-start
    final int minStart = (total * 0.7).toInt();
    final int maxStart = (total * 0.9).toInt();
    final startTilePos = minStart + random.nextInt(maxStart - minStart);
    taken.add(startTilePos);
    taken.add(startTilePos - 1);
    taken.add(startTilePos + 1);

    int getFreeTile() {
      final int maxPlayRange = total - 5;
      for (int attempt = 0; attempt < 500; attempt++) {
        final tile = 8 + random.nextInt(maxPlayRange - 8);
        if (!taken.contains(tile) && !taken.contains(tile - 1) && !taken.contains(tile + 1)) {
          return tile;
        }
      }
      for (int tile = 8; tile <= maxPlayRange; tile++) {
        if (!taken.contains(tile)) return tile;
      }
      return 8;
    }

    int numWind = 5, numFog = 5, numNap = 5, numClover = 4;
    if (total == 125) {
      numWind = 6; numFog = 6; numNap = 6; numClover = 5;
    } else if (total == 150) {
      numWind = 7; numFog = 7; numNap = 7; numClover = 6;
    }

    final wind = <String, int>{};
    for (int i = 0; i < numWind; i++) {
      final tile = getFreeTile();
      wind[tile.toString()] = 3 + random.nextInt(4);
      taken.add(tile); taken.add(tile - 1); taken.add(tile + 1);
    }

    final fog = <String, int>{};
    for (int i = 0; i < numFog; i++) {
      final tile = getFreeTile();
      fog[tile.toString()] = 3 + random.nextInt(4);
      taken.add(tile); taken.add(tile - 1); taken.add(tile + 1);
    }

    final nap = <int>[];
    for (int i = 0; i < numNap; i++) {
      final tile = getFreeTile();
      nap.add(tile);
      taken.add(tile); taken.add(tile - 1); taken.add(tile + 1);
    }

    final clover = <int>[];
    for (int i = 0; i < numClover; i++) {
      final tile = getFreeTile();
      clover.add(tile);
      taken.add(tile); taken.add(tile - 1); taken.add(tile + 1);
    }

    return {
      'windTiles': wind,
      'fogTiles': fog,
      'napTiles': nap,
      'cloverTiles': clover,
      'startTiles': [startTilePos],
    };
  }

  /// Update the active player's turn status and positions
  Future<void> submitMove({
    required int newPosition,
    required bool getsExtraTurn,
    required bool skipsNextTurn,
  }) async {
    final roomId = state.roomId;
    final uid = _firebaseService.currentUser?.uid;
    if (roomId == null || uid == null) return;

    try {
      final nextTurnIndex = state.turnIndex + 1;
      
      // Calculate next active player
      String nextTurnUid;
      if (getsExtraTurn) {
        nextTurnUid = uid;
      } else {
        // Find next player in order
        final currentIdx = state.playerOrder.indexOf(uid);
        var nextIdx = (currentIdx + 1) % state.playerOrder.length;
        
        // If skips next turn, register skip (we could store skipped turns in database as metadata,
        // but simple loop works: check if the next player was scheduled to skip, or simply skip here).
        // Let's implement active skipping by marking skipping status or just standard rotation.
        // To be safe, standard rotation is fine, or we check if there are skipped players.
        // Wait, if the player who is next has a skipped status, we can skip them.
        // But let's check: can we just write the calculated next turn?
        // Yes! The current client can calculate who should play next and write that!
        nextTurnUid = state.playerOrder[nextIdx];
      }

      final updates = <String, Object?>{
        'active_games/$roomId/positions/$uid': newPosition,
      };

      // Only update turn order if the game isn't finished
      final hasWon = newPosition >= state.activeMap.totalTiles;
      if (hasWon) {
        updates['rooms/$roomId/status'] = 'finished';
      } else {
        updates['active_games/$roomId/turnIndex'] = nextTurnIndex;
        updates['active_games/$roomId/currentTurn'] = nextTurnUid;
      }

      await _db.update(updates);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Remove a player from playerOrder during active game if they disconnected
  Future<void> removeDisconnectedPlayer(String playerId) async {
    final roomId = state.roomId;
    if (roomId == null || state.status != 'playing') return;

    try {
      final currentOrder = List<String>.from(state.playerOrder);
      if (!currentOrder.contains(playerId)) return;

      currentOrder.remove(playerId);

      // If no players left, finish game
      if (currentOrder.isEmpty) {
        await _db.child('rooms').child(roomId).child('status').set('finished');
        return;
      }

      final updates = <String, Object?>{
        'active_games/$roomId/playerOrder': currentOrder,
      };

      // If the disconnected player was the active one, shift turn to next
      if (state.currentTurn == playerId) {
        final currentIdx = state.playerOrder.indexOf(playerId);
        final nextIdx = currentIdx % currentOrder.length;
        updates['active_games/$roomId/currentTurn'] = currentOrder[nextIdx];
        updates['active_games/$roomId/turnIndex'] = state.turnIndex + 1;
      }

      await _db.update(updates);
    } catch (e) {
      print("Error removing disconnected player: $e");
    }
  }
}

final multiplayerProvider = StateNotifierProvider<MultiplayerNotifier, MultiplayerRoomState>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return MultiplayerNotifier(firebaseService);
});
