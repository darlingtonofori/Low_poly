import 'package:flutter/material.dart';
import '../models/game.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/pressable_slab.dart';
import '../main.dart';
import 'games/tic_tac_toe_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _query = '';
  String? _username;

  @override
  void initState() {
    super.initState();
    AuthService.instance.currentUsername().then((u) => setState(() => _username = u));
  }

  IconData _iconFor(String key) {
    switch (key) {
      case 'grid_3x3':
        return Icons.grid_3x3_rounded;
      case 'castle':
        return Icons.castle_rounded;
      case 'casino':
        return Icons.casino_rounded;
      default:
        return Icons.videogame_asset_rounded;
    }
  }

  // Each game gets its own accent so the grid doesn't read as one repeated tile.
  (Color, Color) _colorsFor(String gameId) {
    switch (gameId) {
      case 'tictactoe':
        return (LowpolyColors.primary, LowpolyColors.primaryShadow);
      case 'chess':
        return (LowpolyColors.secondary, LowpolyColors.secondaryShadow);
      case 'ludo':
        return (LowpolyColors.win, const Color(0xFF7FA83A));
      default:
        return (LowpolyColors.primary, LowpolyColors.primaryShadow);
    }
  }

  void _openGame(LowpolyGame game) {
    if (!game.implemented) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: LowpolyColors.surface,
          content: Text(
            '${game.name} is coming soon',
            style: LowpolyTextStyles.body(size: 14),
          ),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TicTacToeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = allGames.where((g) => g.name.toLowerCase().contains(_query.toLowerCase())).toList();

    return Scaffold(
      body: LowpolyBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _username != null ? 'Hey, $_username 👋' : 'Lowpoly',
                        style: LowpolyTextStyles.display(size: 26),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout_rounded, color: LowpolyColors.textMuted),
                      onPressed: () async {
                        await AuthService.instance.signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const AuthGate()),
                          );
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Pick a game, get matched, play live.', style: LowpolyTextStyles.body(size: 14, color: LowpolyColors.textMuted)),
                const SizedBox(height: 20),
                TextField(
                  style: LowpolyTextStyles.body(size: 15),
                  decoration: const InputDecoration(
                    hintText: 'Search games...',
                    prefixIcon: Icon(Icons.search_rounded, color: LowpolyColors.textMuted),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: GridView.builder(
                    itemCount: filtered.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.95,
                    ),
                    itemBuilder: (context, i) {
                      final game = filtered[i];
                      final (face, shadow) = _colorsFor(game.id);
                      return PressableSlab(
                        faceColor: game.implemented ? face : LowpolyColors.surface,
                        shadowColor: game.implemented ? shadow : LowpolyColors.surfaceShadow,
                        onTap: () => _openGame(game),
                        child: SizedBox.expand(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _iconFor(game.icon),
                                size: 52,
                                color: game.implemented ? Colors.white : LowpolyColors.textMuted,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                game.name,
                                style: LowpolyTextStyles.display(
                                  size: 18,
                                  color: game.implemented ? Colors.white : LowpolyColors.textMuted,
                                ),
                              ),
                              if (!game.implemented)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white10,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text('soon', style: LowpolyTextStyles.body(size: 11, color: LowpolyColors.textMuted, weight: FontWeight.w700)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
