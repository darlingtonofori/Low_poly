import 'package:flutter/material.dart';
import '../../services/socket_service.dart';
import '../../services/auth_service.dart';

enum _Stage { menu, searching, playing, gameOver }

class TicTacToeScreen extends StatefulWidget {
  const TicTacToeScreen({super.key});

  @override
  State<TicTacToeScreen> createState() => _TicTacToeScreenState();
}

class _TicTacToeScreenState extends State<TicTacToeScreen> {
  _Stage _stage = _Stage.menu;
  List<String> _board = List.filled(9, '');
  String _mySymbol = 'X';
  String _turn = 'X';
  String? _matchId;
  String? _resultText;
  bool _online = false;

  @override
  void initState() {
    super.initState();
    _wireSocketListeners();
  }

  void _wireSocketListeners() {
    final socket = SocketService.instance.socket;

    socket.on('match:found', (data) {
      setState(() {
        _matchId = data['matchId'];
        _mySymbol = data['symbol'];
        _board = List<String>.from(data['board'] ?? List.filled(9, ''));
        _turn = data['turn'] ?? 'X';
        _stage = _Stage.playing;
      });
    });

    socket.on('match:update', (data) {
      setState(() {
        _board = List<String>.from(data['board']);
        _turn = data['turn'];
      });
    });

    socket.on('match:over', (data) {
      setState(() {
        _resultText = data['result']; // 'win' | 'lose' | 'draw'
        _stage = _Stage.gameOver;
      });
    });
  }

  Future<void> _findOnlineMatch() async {
    final username = await AuthService.instance.currentUsername() ?? 'Player';
    setState(() {
      _stage = _Stage.searching;
      _online = true;
    });
    SocketService.instance.connect(username);
    SocketService.instance.joinQueue('tictactoe');
  }

  void _playOffline() {
    setState(() {
      _online = false;
      _board = List.filled(9, '');
      _turn = 'X';
      _mySymbol = 'X';
      _stage = _Stage.playing;
      _resultText = null;
    });
  }

  void _tap(int index) {
    if (_board[index].isNotEmpty || _stage != _Stage.playing) return;

    if (_online) {
      if (_turn != _mySymbol) return; // not your turn — server is authoritative
      SocketService.instance.sendMove(_matchId!, index);
      return;
    }

    // Offline local 2-player practice mode.
    setState(() {
      _board[index] = _turn;
      final winner = _checkWinnerLocal(_board);
      if (winner != null) {
        _resultText = winner == 'draw' ? 'draw' : '$winner wins';
        _stage = _Stage.gameOver;
      } else {
        _turn = _turn == 'X' ? 'O' : 'X';
      }
    });
  }

  String? _checkWinnerLocal(List<String> b) {
    const lines = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8],
      [0, 3, 6], [1, 4, 7], [2, 5, 8],
      [0, 4, 8], [2, 4, 6],
    ];
    for (final l in lines) {
      if (b[l[0]].isNotEmpty && b[l[0]] == b[l[1]] && b[l[1]] == b[l[2]]) {
        return b[l[0]];
      }
    }
    if (!b.contains('')) return 'draw';
    return null;
  }

  @override
  void dispose() {
    if (_online) SocketService.instance.leaveQueue('tictactoe');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tic-Tac-Toe')),
      body: Center(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    switch (_stage) {
      case _Stage.menu:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton.icon(
              onPressed: _findOnlineMatch,
              icon: const Icon(Icons.public),
              label: const Text('Find Live Match'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _playOffline,
              icon: const Icon(Icons.wifi_off),
              label: const Text('Practice Offline (2 players, same device)'),
            ),
          ],
        );

      case _Stage.searching:
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Searching for an opponent...'),
          ],
        );

      case _Stage.playing:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_online)
              Text('You are: $_mySymbol', style: const TextStyle(color: Colors.white60)),
            Text(_online ? "${_turn == _mySymbol ? 'Your' : "Opponent's"} turn" : "$_turn's turn"),
            const SizedBox(height: 16),
            _buildBoard(),
          ],
        );

      case _Stage.gameOver:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _resultText == 'draw' ? "It's a draw!" : (_online ? '${_resultText == 'win' ? 'You won!' : 'You lost.'}' : '$_resultText!'),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildBoard(),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => setState(() => _stage = _Stage.menu),
              child: const Text('Back to menu'),
            ),
          ],
        );
    }
  }

  Widget _buildBoard() {
    return SizedBox(
      width: 300,
      height: 300,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 9,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 6, crossAxisSpacing: 6),
        itemBuilder: (context, i) {
          final v = _board[i];
          return GestureDetector(
            onTap: () => _tap(i),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  v,
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: v == 'X' ? const Color(0xFF6C63FF) : Colors.orangeAccent,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
