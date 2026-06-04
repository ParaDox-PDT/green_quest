import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:green_quest/app/theme/theme.dart';
import 'package:green_quest/core/providers/locale_provider.dart';
import 'package:green_quest/features/game/domain/providers/multiplayer_provider.dart';
import 'package:green_quest/features/game/domain/models/game_map.dart';
import 'package:green_quest/features/menu/presentation/lobby_screen.dart';

class MultiplayerSetupScreen extends ConsumerStatefulWidget {
  const MultiplayerSetupScreen({super.key});

  @override
  ConsumerState<MultiplayerSetupScreen> createState() => _MultiplayerSetupScreenState();
}

class _MultiplayerSetupScreenState extends ConsumerState<MultiplayerSetupScreen> {
  // Simple translation helper
  String _getText(String key, String lang) {
    final Map<String, Map<String, String>> localized = {
      'title': {
        'en': 'MULTIPLAYER QUEST',
        'ru': 'МУЛЬТИПЛЕЕРНЫЙ КВЕСТ',
        'uz': 'KOʻP OʻYINCHILI SARG UZASHT',
      },
      'create_title': {
        'en': 'Create a Room',
        'ru': 'Создать комнату',
        'uz': 'Xona yaratish',
      },
      'create_desc': {
        'en': 'Host a new session and invite your friends with a 6-digit code.',
        'ru': 'Создайте новую сессию и пригласите друзей по 6-значному коду.',
        'uz': 'Yangi oʻyin seansini yarating va doʻstlaringizni 6 xonali kod orqali taklif qiling.',
      },
      'create_btn': {
        'en': 'Create Room',
        'ru': 'Создать',
        'uz': 'Xona Yaratish',
      },
      'join_title': {
        'en': 'Join a Room',
        'ru': 'Войти в комнату',
        'uz': 'Xonaga qoʻshilish',
      },
      'join_desc': {
        'en': 'Enter a 6-digit room code to join an existing session.',
        'ru': 'Введите 6-значный код комнаты, чтобы присоединиться к игре.',
        'uz': 'Mavjud oʻyinga qoʻshilish uchun 6 xonali kodni kiriting.',
      },
      'join_placeholder': {
        'en': 'Enter 6-digit code',
        'ru': 'Введите 6 знаков',
        'uz': 'Kodni kiriting',
      },
      'join_btn': {
        'en': 'Join Room',
        'ru': 'Войти',
        'uz': 'Qoʻshilish',
      },
      'back': {
        'en': 'Back',
        'ru': 'Назад',
        'uz': 'Orqaga',
      },
      'loading': {
        'en': 'Connecting...',
        'ru': 'Подключение...',
        'uz': 'Ulanmoqda...',
      }
    };
    return localized[key]?[lang] ?? localized[key]?['en'] ?? '';
  }

  Future<void> _handleCreateRoom() async {
    // By default, create room with Standard map
    final success = await ref.read(multiplayerProvider.notifier).createRoom(GameMap.defaultMap);
    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LobbyScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider).languageCode;
    final mpState = ref.watch(mpStateProvider(ref));

    // Listen for error messages
    ref.listen<MultiplayerRoomState>(multiplayerProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.redAccent,
          ),
        );
        ref.read(multiplayerProvider.notifier).clearError();
      }
    });

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
            // Left back button
            Positioned(
              top: 20,
              left: 20,
              child: SafeArea(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: GameTheme.softShadows,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: GameTheme.darkWood),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ),

            Positioned.fill(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 16),
                  child: Column(
                    children: [
                      // Screen Title
                      Text(
                        _getText('title', lang),
                        style: GoogleFonts.fredoka(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: GameTheme.darkGreen,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              offset: const Offset(0, 2),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Two main action cards
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // LEFT CARD: Create Room
                            Expanded(
                              child: Card(
                                elevation: 4,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE8F5E9),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: GameTheme.primaryGreen, width: 2),
                                        ),
                                        child: const Icon(
                                          Icons.add_home_work_rounded,
                                          size: 40,
                                          color: GameTheme.primaryGreen,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        _getText('create_title', lang),
                                        style: GoogleFonts.fredoka(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: GameTheme.darkGreen,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _getText('create_desc', lang),
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.fredoka(
                                          fontSize: 12,
                                          color: GameTheme.darkWood.withValues(alpha: 0.7),
                                        ),
                                      ),
                                      const Spacer(),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: mpState.isLoading
                                              ? null
                                              : _handleCreateRoom,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: GameTheme.primaryGreen,
                                          ),
                                          child: mpState.isLoading
                                              ? Text(_getText('loading', lang))
                                              : Text(_getText('create_btn', lang)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 24),

                            // RIGHT CARD: Join Room
                            Expanded(
                              child: Card(
                                elevation: 4,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFF8E1),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: GameTheme.primaryAmber, width: 2),
                                        ),
                                        child: const Icon(
                                          Icons.group_add_rounded,
                                          size: 40,
                                          color: GameTheme.primaryAmber,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        _getText('join_title', lang),
                                        style: GoogleFonts.fredoka(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: GameTheme.darkWood,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _getText('join_desc', lang),
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.fredoka(
                                          fontSize: 12,
                                          color: GameTheme.darkWood.withValues(alpha: 0.7),
                                        ),
                                      ),
                                      const Spacer(),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              barrierDismissible: false,
                                              builder: (context) => const JoinRoomDialog(),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: GameTheme.primaryAmber,
                                          ),
                                          child: Text(_getText('join_btn', lang)),
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
}

class JoinRoomDialog extends ConsumerStatefulWidget {
  const JoinRoomDialog({super.key});

  @override
  ConsumerState<JoinRoomDialog> createState() => _JoinRoomDialogState();
}

class _JoinRoomDialogState extends ConsumerState<JoinRoomDialog> {
  String _code = "";

  void _onKeyPress(String val) {
    if (_code.length < 6) {
      setState(() {
        _code += val;
      });
    }
  }

  void _onBackspace() {
    if (_code.isNotEmpty) {
      setState(() {
        _code = _code.substring(0, _code.length - 1);
      });
    }
  }

  void _onClear() {
    setState(() {
      _code = "";
    });
  }

  String _getDlgText(String key, String lang) {
    final Map<String, Map<String, String>> localized = {
      'title': {
        'en': 'Enter Room Code',
        'ru': 'Введите код',
        'uz': 'Xona kodini kiriting',
      },
      'cancel': {
        'en': 'Cancel',
        'ru': 'Отмена',
        'uz': 'Bekor qilish',
      },
      'join': {
        'en': 'Join',
        'ru': 'Войти',
        'uz': 'Kirish',
      },
      'loading': {
        'en': 'Connecting...',
        'ru': 'Вход...',
        'uz': 'Kirilmoqda...',
      }
    };
    return localized[key]?[lang] ?? localized[key]?['en'] ?? '';
  }

  Future<void> _handleJoin() async {
    if (_code.length != 6) return;
    final success = await ref.read(multiplayerProvider.notifier).joinRoom(_code);
    if (success && mounted) {
      Navigator.of(context).pop(); // Close dialog
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LobbyScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider).languageCode;
    final mpState = ref.watch(multiplayerProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 8,
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Container(
        width: 640,
        height: 280,
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // LEFT SIDE: Code display & buttons
            Expanded(
              flex: 6,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _getDlgText('title', lang),
                    style: GoogleFonts.fredoka(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: GameTheme.darkGreen,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 6 Digit boxes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (index) {
                      final char = _code.length > index ? _code[index] : "";
                      return Container(
                        width: 32,
                        height: 44,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: char.isNotEmpty ? GameTheme.primaryAmber : Colors.black12,
                            width: 2,
                          ),
                          boxShadow: char.isNotEmpty ? [
                            BoxShadow(
                              color: GameTheme.primaryAmber.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ] : null,
                        ),
                        child: Center(
                          child: Text(
                            char,
                            style: GoogleFonts.fredoka(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: GameTheme.darkWood,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const Spacer(),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: mpState.isLoading ? null : () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey.shade600,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            _getDlgText('cancel', lang),
                            style: GoogleFonts.fredoka(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: (_code.length == 6 && !mpState.isLoading) ? _handleJoin : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GameTheme.primaryAmber,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: mpState.isLoading
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _getDlgText('join', lang),
                                  style: GoogleFonts.fredoka(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // SEPARATOR
            Container(
              width: 1.5,
              height: double.infinity,
              color: Colors.black12,
              margin: const EdgeInsets.symmetric(horizontal: 12),
            ),

            // RIGHT SIDE: Custom Keypad
            Expanded(
              flex: 5,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildNumpadRow(['1', '2', '3']),
                  const SizedBox(height: 8),
                  _buildNumpadRow(['4', '5', '6']),
                  const SizedBox(height: 8),
                  _buildNumpadRow(['7', '8', '9']),
                  const SizedBox(height: 8),
                  _buildNumpadRow(['C', '0', '⌫']),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumpadRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) {
        final isAction = key == 'C' || key == '⌫';
        return SizedBox(
          width: 50,
          height: 42,
          child: ElevatedButton(
            onPressed: () {
              if (key == 'C') {
                _onClear();
              } else if (key == '⌫') {
                _onBackspace();
              } else {
                _onKeyPress(key);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isAction ? Colors.grey.shade200 : Colors.white,
              foregroundColor: isAction ? GameTheme.darkWood : GameTheme.primaryGreen,
              elevation: 1,
              shadowColor: Colors.black12,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: Colors.black12, width: 1),
              ),
            ),
            child: Text(
              key,
              style: GoogleFonts.fredoka(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// Simple provider helper
final mpStateProvider = Provider.family<MultiplayerRoomState, WidgetRef>((ref, widgetRef) {
  return ref.watch(multiplayerProvider);
});
