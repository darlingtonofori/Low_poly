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

const BOT_WAIT_MS = 6000; // how long a player waits alone before a bot joins

const queues = { tictactoe: [] };
const matches = {};
let matchCounter = 0;

function clearBotTimer(entry) {
  if (entry?.botTimer) clearTimeout(entry.botTimer);
}

function removeFromQueue(gameId, socketId) {
  const queue = queues[gameId];
  const idx = queue.findIndex((e) => e.socket.id === socketId);
  if (idx !== -1) {
    clearBotTimer(queue[idx]);
    queue.splice(idx, 1);
  }
}

function startMatch(gameId, playerA, playerB, botSide) {
  const matchId = `m${++matchCounter}`;

  if (gameId === 'tictactoe') {
    const match = ticTacToe.createMatch(
      botSide === 'X' ? 'BOT' : playerA.id,
      botSide === 'O' ? 'BOT' : (botSide === 'X' ? playerA.id : playerB.id)
    );
    matches[matchId] = { gameId, ...match, bot: botSide || null };

    if (playerA) {
      playerA.join(matchId);
      const mySymbol = botSide === 'X' ? 'O' : 'X';
      playerA.emit('match:found', { matchId, symbol: mySymbol, board: match.board, turn: match.turn });
    }
    if (playerB) {
      playerB.join(matchId);
      playerB.emit('match:found', { matchId, symbol: 'O', board: match.board, turn: match.turn });
    }

    maybeBotMove(matchId);
  }
}

function tryMatch(gameId) {
  const queue = queues[gameId];
  if (queue.length < 2) return;

  const [entryA, entryB] = queue.splice(0, 2);
  clearBotTimer(entryA);
  clearBotTimer(entryB);
  startMatch(gameId, entryA.socket, entryB.socket, null);
}

function botMoveIndex(board) {
  const empty = board.map((v, i) => (v === '' ? i : null)).filter((v) => v !== null);
  if (empty.length === 0) return null;
  return empty[Math.floor(Math.random() * empty.length)];
}

function maybeBotMove(matchId) {
  const match = matches[matchId];
  if (!match || !match.bot) return;
  if (match.turn !== match.bot) return;

  setTimeout(() => {
    const current = matches[matchId];
    if (!current) return;
    const index = botMoveIndex(current.board);
    if (index === null) return;
    applyMoveAndBroadcast(matchId, current.bot, index);
  }, 500 + Math.random() * 700);
}

function applyMoveAndBroadcast(matchId, symbol, index) {
  const match = matches[matchId];
  if (!match) return;

  const result = ticTacToe.applyMove(match, symbol, index);
  if (!result.ok) return;

  io.to(matchId).emit('match:update', { board: match.board, turn: match.turn });

  if (result.winner) {
    const winnerSymbol = result.winner;
    if (match.players.X !== 'BOT') {
      io.to(match.players.X).emit('match:over', {
        result: winnerSymbol === 'draw' ? 'draw' : winnerSymbol === 'X' ? 'win' : 'lose',
      });
    }
    if (match.players.O !== 'BOT') {
      io.to(match.players.O).emit('match:over', {
        result: winnerSymbol === 'draw' ? 'draw' : winnerSymbol === 'O' ? 'win' : 'lose',
      });
    }
    delete matches[matchId];
  } else {
    maybeBotMove(matchId);
  }
}

io.on('connection', (socket) => {
  let username = 'Player';

  socket.on('identify', (data) => {
    username = data?.username || username;
  });

  socket.on('queue:join', ({ gameId }) => {
    if (!queues[gameId]) return;

    const entry = { socket, botTimer: null };
    entry.botTimer = setTimeout(() => {
      removeFromQueue(gameId, socket.id);
      startMatch(gameId, socket, null, 'O');
    }, BOT_WAIT_MS);

    queues[gameId].push(entry);
    tryMatch(gameId);
  });

  socket.on('queue:leave', ({ gameId }) => {
    if (!queues[gameId]) return;
    removeFromQueue(gameId, socket.id);
  });

  socket.on('match:move', ({ matchId, move }) => {
    const match = matches[matchId];
    if (!match) return;

    const symbol = match.players.X === socket.id ? 'X' : match.players.O === socket.id ? 'O' : null;
    if (!symbol) return;

    applyMoveAndBroadcast(matchId, symbol, move);
  });

  socket.on('disconnect', () => {
    for (const gameId of Object.keys(queues)) {
      removeFromQueue(gameId, socket.id);
    }
  });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => console.log(`Lowpoly backend running on port ${PORT}`));
