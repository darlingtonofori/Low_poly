import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import '../../services/socket_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/pressable_slab.dart';

enum _Stage { menu, searching, playing, gameOver }

const List<List<int>> _kLines = [
  [0, 1, 2], [3, 4, 5], [6, 7, 8],
  [0, 3, 6], [1, 4, 7], [2, 5, 8],
  [0, 4, 8], [2, 4, 6],
];

const _kOnlineScoreKey = 'ttt_online_score_v1';

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
  String? _resultText; // 'win' | 'lose' | 'draw' (online) or 'X'/'O'/'draw' (offline)
  bool _online = false;
  List<int> _winningLine = [];

  // Online score persists across sessions. Offline is a live session tally.
  Map<String, int> _onlineScore = {'win': 0, 'lose': 0, 'draw': 0};
  Map<String, int> _offlineScore = {'X': 0, 'O': 0, 'draw': 0};

  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(milliseconds: 900));
    _wireSocketListeners();
    _loadOnlineScore();
  }

  Future<void> _loadOnlineScore() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kOnlineScoreKey);
    if (raw != null) {
      final decoded = Map<String, dynamic>.from(jsonDecode(raw));
      setState(() => _onlineScore = decoded.map((k, v) => MapEntry(k, v as int)));
    }
  }

  Future<void> _saveOnlineScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kOnlineScoreKey, jsonEncode(_onlineScore));
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
        _winningLine = [];
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
        _resultText = data['result'];
        _winningLine = _findWinningLine(_board);
        _stage = _Stage.gameOver;
        _onlineScore[_resultText!] = (_onlineScore[_resultText!] ?? 0) + 1;
      });
      _saveOnlineScore();
      if (_resultText == 'win') _confetti.play();
    });
  }

  List<int> _findWinningLine(List<String> b) {
    for (final line in _kLines) {
      if (b[line[0]].isNotEmpty && b[line[0]] == b[line[1]] && b[line[1]] == b[line[2]]) {
        return line;
      }
    }
    return [];
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
      _winningLine = [];
    });
  }

  void _tap(int index) {
    if (_board[index].isNotEmpty || _stage != _Stage.playing) return;

    if (_online) {
      if (_turn != _mySymbol) return;
      SocketService.instance.sendMove(_matchId!, index);
      return;
    }

    setState(() {
      _board[index] = _turn;
      final line = _findWinningLine(_board);
      if (line.isNotEmpty) {
        _winningLine = line;
        _resultText = _board[line[0]];
        _stage = _Stage.gameOver;
        _offlineScore[_resultText!] = (_offlineScore[_resultText!] ?? 0) + 1;
        _confetti.play();
      } else if (!_board.contains('')) {
        _resultText = 'draw';
        _stage = _Stage.gameOver;
        _offlineScore['draw'] = (_offlineScore['draw'] ?? 0) + 1;
      } else {
        _turn = _turn == 'X' ? 'O' : 'X';
      }
    });
  }

  Color _symbolColor(String symbol) =>
      symbol == 'X' ? LowpolyColors.primary : LowpolyColors.secondary;

  @override
  void dispose() {
    if (_online) SocketService.instance.leaveQueue('tictactoe');
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tic-Tac-Toe')),
      body: LowpolyBackground(
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Center(child: _buildBody()),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirection: 1.57,
                numberOfParticles: 24,
                maxBlastForce: 18,
                minBlastForce: 8,
                emissionFrequency: 0.08,
                gravity: 0.4,
                colors: const [
                  LowpolyColors.primary,
                  LowpolyColors.secondary,
                  LowpolyColors.win,
                  LowpolyColors.draw,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_stage) {
      case _Stage.menu:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildScoreboard(online: true),
              const SizedBox(height: 28),
              PressableSlab(
                faceColor: LowpolyColors.primary,
                shadowColor: LowpolyColors.primaryShadow,
                onTap: _findOnlineMatch,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.public_rounded, color: Colors.white),
                      const SizedBox(width: 10),
                      Text('Find Live Match', style: LowpolyTextStyles.body(size: 16, weight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _playOffline,
                icon: const Icon(Icons.wifi_off_rounded),
                label: const Text('Practice Offline (2 players)'),
              ),
            ],
          ),
        );

      case _Stage.searching:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: LowpolyColors.primary),
            const SizedBox(height: 16),
            Text('Searching for an opponent...', style: LowpolyTextStyles.body(size: 15, color: LowpolyColors.textMuted)),
            const SizedBox(height: 4),
            Text('(a bot joins in if nobody shows up)', style: LowpolyTextStyles.body(size: 12, color: LowpolyColors.textMuted)),
          ],
        );

      case _Stage.playing:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTurnBadge(),
            const SizedBox(height: 20),
            _buildBoard(),
          ],
        );

      case _Stage.gameOver:
        final label = _online
            ? (_resultText == 'draw' ? "It's a draw!" : (_resultText == 'win' ? 'You won! 🎉' : 'You lost.'))
            : (_resultText == 'draw' ? "It's a draw!" : '$_resultText wins! 🎉');
        final labelColor = _resultText == 'draw'
            ? LowpolyColors.draw
            : (_online ? (_resultText == 'win' ? LowpolyColors.win : LowpolyColors.lose) : _symbolColor(_resultText!));

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: LowpolyTextStyles.display(size: 24, color: labelColor)),
            const SizedBox(height: 16),
            _buildBoard(),
            const SizedBox(height: 16),
            _buildScoreboard(online: _online),
            const SizedBox(height: 20),
            PressableSlab(
              faceColor: LowpolyColors.primary,
              shadowColor: LowpolyColors.primaryShadow,
              onTap: () => setState(() => _stage = _Stage.menu),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                child: Text('Back to menu', style: LowpolyTextStyles.body(size: 15, weight: FontWeight.w800)),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildTurnBadge() {
    final myTurn = _online ? _turn == _mySymbol : true;
    final label = _online
        ? (myTurn ? 'Your turn' : "Opponent's turn")
        : "${_turn}'s turn";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: LowpolyColors.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _symbolColor(_turn), width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_online) Text('You: $_mySymbol  •  ', style: LowpolyTextStyles.body(size: 13, color: LowpolyColors.textMuted)),
          Text(label, style: LowpolyTextStyles.body(size: 14, color: _symbolColor(_turn), weight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildScoreboard({required bool online}) {
    final score = online ? _onlineScore : _offlineScore;
    final entries = online
        ? [('Wins', score['win'] ?? 0, LowpolyColors.win), ('Losses', score['lose'] ?? 0, LowpolyColors.lose), ('Draws', score['draw'] ?? 0, LowpolyColors.draw)]
        : [('X wins', score['X'] ?? 0, LowpolyColors.primary), ('O wins', score['O'] ?? 0, LowpolyColors.secondary), ('Draws', score['draw'] ?? 0, LowpolyColors.draw)];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: LowpolyColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: entries.map((e) {
          final (title, value, color) = e;
          return Column(
            children: [
              Text('$value', style: LowpolyTextStyles.display(size: 22, color: color)),
              const SizedBox(height: 2),
              Text(title, style: LowpolyTextStyles.body(size: 11, color: LowpolyColors.textMuted, weight: FontWeight.w700)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBoard() {
    return SizedBox(
      width: 300,
      height: 300,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 9,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8),
        itemBuilder: (context, i) {
          final v = _board[i];
          final isWinningCell = _winningLine.contains(i);
          return GestureDetector(
            onTap: () => _tap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isWinningCell ? LowpolyColors.win.withOpacity(0.18) : LowpolyColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: isWinningCell ? Border.all(color: LowpolyColors.win, width: 2.5) : null,
                boxShadow: isWinningCell
                    ? [BoxShadow(color: LowpolyColors.win.withOpacity(0.5), blurRadius: 12, spreadRadius: 1)]
                    : null,
              ),
              child: Center(
                child: TweenAnimationBuilder<double>(
                  key: ValueKey('$i-$v'),
                  tween: Tween(begin: v.isEmpty ? 1.0 : 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.elasticOut,
                  builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                  child: Text(
                    v,
                    style: LowpolyTextStyles.display(size: 48, color: v.isNotEmpty ? _symbolColor(v) : Colors.transparent),
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
