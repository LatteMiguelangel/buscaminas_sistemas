import 'dart:convert';
import 'dart:io';

void main() async {
  const port = 4040;
  final server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
  print('▶️ Servidor Dart iniciado en puerto $port');

  Socket? hostSocket;
  Socket? clientSocket;

  server.listen((socket) {
    print(
        '🔗 Conexión de ${socket.remoteAddress.address}:${socket.remotePort}');
    socket.listen((raw) {
      final msg = utf8.decode(raw).trim();
      if (msg.isEmpty) return;
      print('📥 [RAW] $msg');

      try {
        final map = jsonDecode(msg) as Map<String, dynamic>;
        final type = map['type'] as String;

        // Registro de rol al inicio
        if (type == 'register') {
          final role = map['role'] as String;
          if (role == 'host') {
            hostSocket = socket;
            print('🏠 Host registrado');
          } else if (role == 'client') {
            clientSocket = socket;
            print('👤 Cliente registrado');

            // Notificar al host que el cliente ya está preparado
            if (hostSocket != null) {
              hostSocket!.writeln(
                jsonEncode({'type': 'clientReady', 'data': {}}),
              );
              print('✈️ [SERVER→HOST] clientReady');
            }
          }
          return;
        }

        // Reenvío según origen
        if (socket == hostSocket && clientSocket != null) {
          clientSocket!.writeln(msg);
          print('✈️ [HOST→CLIENTE] $msg');
        } else if (socket == clientSocket && hostSocket != null) {
          hostSocket!.writeln(msg);
          print('✈️ [CLIENTE→HOST] $msg');
        }
      } catch (e) {
        print('⚠️ Error procesando mensaje: $e');
      }
    }, onDone: () {
      if (socket == hostSocket) hostSocket = null;
      if (socket == clientSocket) clientSocket = null;
      print('❌ Desconexión de ${socket.remoteAddress.address}');
    });
  });
}
