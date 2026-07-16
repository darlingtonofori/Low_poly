import 'package:socket_io_client/socket_io_client.dart' as io;

/// Central socket connection to your VPS backend.
///
/// CHANGE THIS to your actual VPS address (and use wss:// with a domain +
/// reverse proxy + SSL once you're past local testing — never ship http/ws
/// unencrypted to real users).
const String kServerUrl = 'http://YOUR_VPS_IP:3000';

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
