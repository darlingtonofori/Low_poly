class LowpolyGame {
  final String id;
  final String name;
  final String icon; // material icon name key, resolved in UI
  final bool implemented;

  const LowpolyGame({
    required this.id,
    required this.name,
    required this.icon,
    this.implemented = false,
  });
}

const List<LowpolyGame> allGames = [
  LowpolyGame(id: 'tictactoe', name: 'Tic-Tac-Toe', icon: 'grid_3x3', implemented: true),
  LowpolyGame(id: 'chess', name: 'Chess', icon: 'castle'),
  LowpolyGame(id: 'ludo', name: 'Ludo', icon: 'casino'),
];
