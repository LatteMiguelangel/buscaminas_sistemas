// server/bin/game_server.dart

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

void main() async {
  const port = 4040;
  final server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
  print('▶️ Servidor Dart iniciado en puerto $port');

  Socket? hostSocket;
  Socket? clientSocket;

  server.listen((socket) {
    print('🔗 Conexión de ${socket.remoteAddress.address}:${socket.remotePort}');

    // Buffer para reensamblar JSON-lines
    String buffer = '';

    socket.listen((Uint8List raw) {
      // 1) Acumula en el buffer
      buffer += utf8.decode(raw);

      // 2) Parte en líneas completas
      final parts = buffer.split('\n');
      buffer = parts.removeLast(); // lo que quedó incompleto

      for (final line in parts) {
        final msg = line.trim();
        if (msg.isEmpty) continue;

        print('📥 [RAW] $msg');
        try {
          final map = jsonDecode(msg) as Map<String, dynamic>;
          final type = map['type'] as String;

          // Registro de rol
          if (type == 'register') {
            final role = map['role'] as String;
            if (role == 'host') {
              hostSocket = socket;
              print('🏠 Host registrado');
            } else {
              clientSocket = socket;
              print('👤 Cliente registrado');
              // Notificar al host
              if (hostSocket != null) {
                hostSocket!
                    .writeln(jsonEncode({'type': 'clientReady', 'data': {}}));
                print('✈️ [SERVER→HOST] clientReady');
              }
            }
            continue;
          }

          // Reenvío de línea tal cual llegó
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
      }
    }, onDone: () {
      if (socket == hostSocket) hostSocket = null;
      if (socket == clientSocket) clientSocket = null;
      print('❌ Desconexión de ${socket.remoteAddress.address}');
    });
  });
}
