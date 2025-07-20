// lib/logic/network/proxy_client.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:buscando_minas/logic/network/network_event.dart';

/// Cliente TCP que se conecta al servidor-relé externo.
/// Envía un mensaje de registro inicial ("host" o "client") y
/// luego reenvía/recibe todos los [Event<T>] mediante JSON lines.
class ProxyClient {
  final String host;
  final int port;

  Socket? _socket;
  final _eventController = StreamController<Event<dynamic>>.broadcast();
  String _buffer = '';

  /// Stream de todos los eventos entrantes desde el servidor-relé.
  Stream<Event<dynamic>> get events => _eventController.stream;

  ProxyClient({required this.host, required this.port});

  /// Conecta al servidor y envía el mensaje de registro de rol.
  Future<void> connect({required String role}) async {
    _socket = await Socket.connect('192.168.1.117', 4040);

    // Enviar registro de rol
    final registerMsg = jsonEncode({'type': 'register', 'role': role});
    _socket!.writeln(registerMsg);

    // Escuchar datos entrantes
    _socket!.listen(
      _onData,
      onDone: () {
        print('❌ ProxyClient: conexión cerrada por el servidor');
        _socket = null;
        _eventController.close();
      },
      onError: (error) {
        print('⚠️ ProxyClient: error de socket: $error');
        _socket = null;
        _eventController.addError(error);
      },
      cancelOnError: false,
    );

    print('✅ ProxyClient conectado a $host:$port como "$role"');
  }

  void _onData(Uint8List raw) {
    // 1) Acumular datos entrantes
    _buffer += utf8.decode(raw);

    // 2) Partir el buffer por líneas completas
    final parts = _buffer.split('\n');
    _buffer = parts.removeLast(); // queda el fragmento incompleto

    // 3) Parsear cada línea usando el método centralizado
    for (final line in parts) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      try {
        final event = Event.fromJsonString(trimmed);
        _eventController.add(event);
        print('📥 ProxyClient recibió: ${event.type}');
      } catch (e) {
        print('⚠️ ProxyClient fallo al parsear "$trimmed": $e');
      }
    }
  }

  /// Envía un [Event] al relé externo.
  void send<T>(Event<T> event) {
    if (_socket == null) {
      print('⚠️ ProxyClient.send fallido: no conectado');
      return;
    }
    // toJsonString ya incluye '\n', pero writeln añade uno más
    final msg = event.toJsonString().trim();
    _socket!.writeln(msg);
    print('📤 ProxyClient envía: $msg');
  }

  /// Cierra la conexión y libera recursos.
  Future<void> dispose() async {
    await _socket?.close();
    await _eventController.close();
    print('🔒 ProxyClient disposed');
  }
}