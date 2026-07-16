// Authoritative Tic-Tac-Toe logic. The server owns truth — clients only
// send a cell index, never a board state, so nobody can fake a win.

const LINES = [
  [0, 1, 2], [3, 4, 5], [6, 7, 8],
  [0, 3, 6], [1, 4, 7], [2, 5, 8],
  [0, 4, 8], [2, 4, 6],
];

function createMatch(playerA, playerB) {
  return {
    board: Array(9).fill(''),
    turn: 'X',
    players: {
      X: playerA,
      O: playerB,
    },
  };
}

function checkWinner(board) {
  for (const [a, b, c] of LINES) {
    if (board[a] && board[a] === board[b] && board[b] === board[c]) {
      return board[a];
    }
  }
  if (!board.includes('')) return 'draw';
  return null;
}

/**
 * Applies a move if legal.
 * @returns {ok: boolean, reason?: string, winner?: string|null}
 */
function applyMove(match, symbol, index) {
  if (symbol !== match.turn) return { ok: false, reason: 'not_your_turn' };
  if (index < 0 || index > 8) return { ok: false, reason: 'bad_index' };
  if (match.board[index] !== '') return { ok: false, reason: 'occupied' };

  match.board[index] = symbol;
  const winner = checkWinner(match.board);
  match.turn = symbol === 'X' ? 'O' : 'X';

  return { ok: true, winner };
}

module.exports = { createMatch, applyMove, checkWinner };
