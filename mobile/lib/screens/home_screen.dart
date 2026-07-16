import 'package:flutter/material.dart';
import '../models/game.dart';
import '../services/auth_service.dart';
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
        return Icons.grid_3x3;
      case 'castle':
        return Icons.castle;
      case 'casino':
        return Icons.casino;
      default:
        return Icons.videogame_asset;
    }
  }

  void _openGame(LowpolyGame game) {
    if (!game.implemented) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${game.name} is coming soon — plug it in using tic_tac_toe_screen.dart as the template.')),
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
      appBar: AppBar(
        title: Text(_username != null ? 'Hey, $_username' : 'Lowpoly'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.instance.signOut();
              if (context.mounted) Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const AuthGate()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search games...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                itemCount: filtered.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                itemBuilder: (context, i) {
                  final game = filtered[i];
                  return Card(
                    color: const Color(0xFF1E1E1E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _openGame(game),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_iconFor(game.icon), size: 48, color: const Color(0xFF6C63FF)),
                          const SizedBox(height: 12),
                          Text(game.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          if (!game.implemented)
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text('coming soon', style: TextStyle(fontSize: 11, color: Colors.white38)),
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
    );
  }
}
