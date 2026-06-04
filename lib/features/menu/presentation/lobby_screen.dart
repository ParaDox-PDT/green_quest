import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:green_quest/app/theme/theme.dart';
import 'package:green_quest/core/providers/locale_provider.dart';
import 'package:green_quest/features/game/domain/models/game_map.dart';
import 'package:green_quest/features/game/domain/providers/multiplayer_provider.dart';
import 'package:green_quest/features/menu/domain/providers/character_provider.dart';
import 'package:green_quest/features/menu/presentation/widgets/character_painters.dart';
import 'package:green_quest/features/game/presentation/game_screen.dart';
import 'package:green_quest/core/services/firebase_service.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  // Simple translations helper
  String _getText(String key, String lang) {
    final Map<String, Map<String, String>> localized = {
      'room_code': {
        'en': 'ROOM CODE',
        'ru': 'КОД КОМНАТЫ',
        'uz': 'XONA KODI',
      },
      'lobby_title': {
        'en': 'GAME LOBBY',
        'ru': 'ИГРОВОЙ ЛОББИ',
        'uz': 'KUTISH ZALI',
      },
      'players': {
        'en': 'Players',
        'ru': 'Игроки',
        'uz': 'Oʻyinchilar',
      },
      'ready': {
        'en': 'Ready',
        'ru': 'Готов',
        'uz': 'Tayyor',
      },
      'not_ready': {
        'en': 'Not Ready',
        'ru': 'Не готов',
        'uz': 'Tayyor emas',
      },
      'host': {
        'en': 'Host',
        'ru': 'Хозяин',
        'uz': 'Host',
      },
      'select_character': {
        'en': 'Choose Character',
        'ru': 'Выберите персонажа',
        'uz': 'Qahramonni tanlang',
      },
      'select_map': {
        'en': 'Select Map (Host Only)',
        'ru': 'Выбор карты (Только хост)',
        'uz': 'Xaritani tanlash (Faqat Host)',
      },
      'current_map': {
        'en': 'Selected Map',
        'ru': 'Выбранная карта',
        'uz': 'Tanlangan xarita',
      },
      'start_btn': {
        'en': 'Start Match',
        'ru': 'Начать матч',
        'uz': 'Oʻyinni boshlash',
      },
      'leave_btn': {
        'en': 'Leave Room',
        'ru': 'Выйти из комнаты',
        'uz': 'Xonani tark etish',
      },
      'waiting_host': {
        'en': 'Waiting for host to start...',
        'ru': 'Ожидание начала от хоста...',
        'uz': 'Host boshlashini kutilmoqda...',
      }
    };
    return localized[key]?[lang] ?? localized[key]?['en'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider).languageCode;
    final mpState = ref.watch(multiplayerProvider);
    final myUid = ref.watch(firebaseServiceProvider).currentUser?.uid;

    final isHost = mpState.hostId == myUid;
    final myPlayer = mpState.players[myUid];

    // Trigger navigation when status is 'playing'
    ref.listen<MultiplayerRoomState>(multiplayerProvider, (previous, next) {
      if (next.status == 'playing' && previous?.status != 'playing') {
        // Also update local selected character provider to avoid issues
        final localFigure = next.players[myUid]?.figure;
        if (localFigure != null) {
          ref.read(selectedCharacterProvider.notifier).state = localFigure;
        }

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const GameScreen(isMultiplayer: true)),
        );
      } else if (next.status == 'finished' && previous?.status != 'finished') {
        // Host dissolved lobby
        if (next.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.error!)),
          );
        }
        Navigator.of(context).pop();
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE8F5E9),
              Color(0xFFC8E6C9),
              Color(0xFFA5D6A7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // LEFT PANEL: Room Code, Players, Map Selection
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Room Code Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getText('room_code', lang),
                                style: GoogleFonts.fredoka(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: GameTheme.darkWood.withValues(alpha: 0.6),
                                ),
                              ),
                              Text(
                                mpState.roomCode ?? '------',
                                style: GoogleFonts.fredoka(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: GameTheme.darkWood,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                          // Leave Room Button
                          ElevatedButton(
                            onPressed: () {
                              ref.read(multiplayerProvider.notifier).leaveRoom();
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent.shade200,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.exit_to_app_rounded, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  _getText('leave_btn', lang),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24, thickness: 1.5),

                      // Players list
                      Text(
                        _getText('players', lang),
                        style: GoogleFonts.fredoka(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: GameTheme.darkWood,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Expanded(
                        child: ListView(
                          children: mpState.players.values.map((player) {
                            final isPlayerHost = player.id == mpState.hostId;
                            final isMe = player.id == myUid;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8.0),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isMe ? Colors.white : Colors.white.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isMe ? GameTheme.primaryGreen : Colors.black12,
                                  width: isMe ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Player character avatar icon if selected
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: player.figure != null
                                          ? Color(player.figure!.colorHex).withValues(alpha: 0.2)
                                          : Colors.grey.shade200,
                                      shape: BoxShape.circle,
                                    ),
                                    child: player.figure != null
                                        ? CharacterVectorWidget(character: player.figure!, size: 20)
                                        : const Icon(Icons.person_rounded, size: 18, color: Colors.grey),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          player.name + (isMe ? ' (You)' : ''),
                                          style: GoogleFonts.fredoka(
                                            fontWeight: FontWeight.bold,
                                            color: GameTheme.darkWood,
                                            fontSize: 14,
                                          ),
                                        ),
                                        if (player.figure != null)
                                          Text(
                                            player.figure!.name.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Color(player.figure!.colorHex),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  // Ready Tag
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isPlayerHost
                                          ? GameTheme.primaryAmber.withValues(alpha: 0.15)
                                          : (player.isReady
                                              ? Colors.green.shade100
                                              : Colors.red.shade100),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isPlayerHost
                                          ? _getText('host', lang)
                                          : (player.isReady ? _getText('ready', lang) : _getText('not_ready', lang)),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isPlayerHost
                                            ? GameTheme.primaryAmber
                                            : (player.isReady ? Colors.green.shade800 : Colors.red.shade800),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Map selection List
                      Text(
                        isHost ? _getText('select_map', lang) : _getText('current_map', lang),
                        style: GoogleFonts.fredoka(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: GameTheme.darkWood,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildMapSelectionList(ref, lang, isHost, mpState.activeMap),
                    ],
                  ),
                ),

                const VerticalDivider(width: 32, thickness: 1.5),

                // RIGHT PANEL: Choose Characters & Ready Button
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getText('select_character', lang),
                        style: GoogleFonts.fredoka(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: GameTheme.darkGreen,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Characters grid / row
                      Expanded(
                        child: GridView.count(
                          crossAxisCount: 2,
                          childAspectRatio: 1.3,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          children: GameCharacter.values.map((char) {
                            final chosenByUid = mpState.selectedFigures[char.name];
                            final isTaken = chosenByUid != null;
                            final isTakenByMe = chosenByUid == myUid;
                            final ownerName = isTaken ? mpState.players[chosenByUid]?.name ?? 'Player' : '';

                            return GestureDetector(
                              onTap: isTaken && !isTakenByMe
                                  ? null
                                  : () => ref.read(multiplayerProvider.notifier).selectCharacter(char),
                              child: Opacity(
                                opacity: isTaken && !isTakenByMe ? 0.4 : 1.0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isTakenByMe
                                          ? Color(char.colorHex)
                                          : (isTaken ? Colors.black12 : Colors.grey.shade300),
                                      width: isTakenByMe ? 3 : 1.5,
                                    ),
                                    boxShadow: isTakenByMe
                                        ? [
                                            BoxShadow(
                                              color: Color(char.colorHex).withValues(alpha: 0.2),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            )
                                          ]
                                        : null,
                                  ),
                                  padding: const EdgeInsets.all(8.0),
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: CharacterVectorWidget(character: char, size: 45),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              char.name.toUpperCase(),
                                              style: GoogleFonts.fredoka(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: GameTheme.darkWood,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Taken badge
                                      if (isTaken)
                                        Positioned(
                                          top: 0,
                                          right: 0,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isTakenByMe ? GameTheme.primaryGreen : Colors.blueGrey,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              isTakenByMe ? 'YOU' : ownerName,
                                              style: const TextStyle(
                                                fontSize: 8,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Action Buttons
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: isHost
                            ? ElevatedButton(
                                onPressed: _isStartGameEnabled(mpState)
                                    ? () => ref.read(multiplayerProvider.notifier).startGame()
                                    : null,
                                child: Text(_getText('start_btn', lang)),
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: myPlayer?.figure == null
                                            ? null
                                            : () => ref.read(multiplayerProvider.notifier).toggleReady(!(myPlayer?.isReady ?? false)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: (myPlayer?.isReady ?? false)
                                              ? Colors.grey.shade500
                                              : GameTheme.primaryAmber,
                                        ),
                                        child: Text(
                                          (myPlayer?.isReady ?? false)
                                              ? _getText('not_ready', lang)
                                              : _getText('ready', lang),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getText('waiting_host', lang),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: GameTheme.darkWood.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isStartGameEnabled(MultiplayerRoomState mpState) {
    final players = mpState.players.values.toList();
    if (players.length < 2 || players.length > 4) return false;
    for (var p in players) {
      if (p.id != mpState.hostId && !p.isReady) return false;
      if (p.figure == null) return false;
    }
    return true;
  }

  Widget _buildMapSelectionList(WidgetRef ref, String langCode, bool isHost, GameMap selectedMap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: GameMap.availableMaps.map((map) {
        final isSelected = selectedMap.type == map.type;
        return GestureDetector(
          onTap: isHost
              ? () => ref.read(multiplayerProvider.notifier).updateMap(map)
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 6.0),
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
            width: double.infinity,
            decoration: BoxDecoration(
              color: isSelected ? GameTheme.primaryGreen : Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? GameTheme.primaryGreen : Colors.black12,
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                  color: isSelected ? Colors.white : GameTheme.darkWood.withValues(alpha: 0.5),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    map.getName(langCode),
                    style: GoogleFonts.fredoka(
                      fontSize: 12,
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
}
