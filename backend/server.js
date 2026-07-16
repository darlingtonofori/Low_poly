const express = require('express');
const cors = require('cors');
const http = require('http');
const { Server } = require('socket.io');
const ticTacToe = require('./games/ticTacToe');

const app = express();
app.use(cors());
app.get('/health', (req, res) => res.json({ status: 'ok' }));

const server = http.createServer(app);
const io = new Server(server, { cors: { origin: '*' } });

// gameId -> array of waiting sockets
const queues = { tictactoe: [] };

// matchId -> { board, turn, players: {X: socketId, O: socketId} }
const matches = {};

let matchCounter = 0;

function tryMatch(gameId) {
  const queue = queues[gameId];
  if (queue.length < 2) return;

  const [playerA, playerB] = queue.splice(0, 2);
  const matchId = `m${++matchCounter}`;

  if (gameId === 'tictactoe') {
    const match = ticTacToe.createMatch(playerA.id, playerB.id);
    matches[matchId] = { gameId, ...match };

    playerA.join(matchId);
    playerB.join(matchId);

    playerA.emit('match:found', { matchId, symbol: 'X', board: match.board, turn: match.turn });
    playerB.emit('match:found', { matchId, symbol: 'O', board: match.board, turn: match.turn });
  }
}

io.on('connection', (socket) => {
  let username = 'Player';

  socket.on('identify', (data) => {
    username = data?.username || username;
  });

  socket.on('queue:join', ({ gameId }) => {
    if (!queues[gameId]) return;
    queues[gameId].push(socket);
    tryMatch(gameId);
  });

  socket.on('queue:leave', ({ gameId }) => {
    if (!queues[gameId]) return;
    queues[gameId] = queues[gameId].filter((s) => s.id !== socket.id);
  });

  socket.on('match:move', ({ matchId, move }) => {
    const match = matches[matchId];
    if (!match) return;

    const symbol = match.players.X === socket.id ? 'X' : match.players.O === socket.id ? 'O' : null;
    if (!symbol) return;

    const result = ticTacToe.applyMove(match, symbol, move);
    if (!result.ok) return; // illegal move — silently ignored, client stays authoritative-server-trusting

    io.to(matchId).emit('match:update', { board: match.board, turn: match.turn });

    if (result.winner) {
      const winnerSymbol = result.winner;
      io.to(match.players.X).emit('match:over', {
        result: winnerSymbol === 'draw' ? 'draw' : winnerSymbol === 'X' ? 'win' : 'lose',
      });
      io.to(match.players.O).emit('match:over', {
        result: winnerSymbol === 'draw' ? 'draw' : winnerSymbol === 'O' ? 'win' : 'lose',
      });
      delete matches[matchId];
    }
  });

  socket.on('disconnect', () => {
    for (const gameId of Object.keys(queues)) {
      queues[gameId] = queues[gameId].filter((s) => s.id !== socket.id);
    }
    // NOTE: for v1 we don't handle mid-match disconnects gracefully yet —
    // add an opponent-forfeit timeout here later.
  });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => console.log(`Lowpoly backend running on port ${PORT}`));
