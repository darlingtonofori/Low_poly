import 'package:socket_io_client/socket_io_client.dart' as io;

/// Central socket connection to your VPS backend.
const String kServerUrl = 'http://169.255.56.63:3001';

class SocketService {
  SocketService._();
  static final SocketService instance = SocketService._();

  io.Socket? _socket;

  io.Socket get socket {
    _socket ??= io.io(
      kServerUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );
    return _socket!;
  }

  void connect(String username) {
    socket.connect();
    socket.onConnect((_) {
      socket.emit('identify', {'username': username});
    });
  }

  void joinQueue(String gameId) {
    socket.emit('queue:join', {'gameId': gameId});
  }

  void leaveQueue(String gameId) {
    socket.emit('queue:leave', {'gameId': gameId});
  }

  void sendMove(String matchId, dynamic move) {
    socket.emit('match:move', {'matchId': matchId, 'move': move});
  }

  void dispose() {
    _socket?.dispose();
    _socket = null;
  }
}
