// lib/logic/network/proxy_client.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:buscando_minas/logic/network/network_event.dart';

class ProxyClient {
  final String host;
  final int port;

  Socket? _socket;
  late final StreamSubscription<Uint8List> _socketSub;
  final StreamController<Event<dynamic>> _events =
      StreamController<Event<dynamic>>.broadcast();
  final StringBuffer _buffer = StringBuffer();

  /// Stream de eventos entrantes (gameStart, cellUpdate, etc.).
  Stream<Event<dynamic>> get events => _events.stream;

  ProxyClient({required this.host, required this.port});

  /// Conecta al servidor y registra el rol ('host' o 'client').
  Future<void> connect({required String role}) async {
    _socket = await Socket.connect(host, port);
    print('✅ ProxyClient connected to $host:$port as $role');

    // 1) Enviar registro
    final registerMsg = jsonEncode({'type': 'register', 'role': role}) + '\n';
    print('🚀 [ProxyClient] SEND REGISTER → $registerMsg');
    _socket!.add(utf8.encode(registerMsg));

    // 2) Escuchar datos entrantes
    _socketSub = _socket!.listen(
      _onData,
      onDone: () {
        print('❌ ProxyClient: socket closed by server');
        _events.close();
        _socket = null;
      },
      onError: (error) {
        print('⚠️ ProxyClient: socket error $error');
        _events.addError(error);
        _events.close();
        _socket = null;
      },
    );
  }

  /// Procesa chunks de bytes, reconstruye líneas JSON y dispara eventos.
  void _onData(Uint8List chunk) {
    _buffer.write(utf8.decode(chunk));
    final content = _buffer.toString();
    final lines = content.split('\n');
    _buffer.clear();

    // Procesar todas las líneas completas
    for (var i = 0; i < lines.length - 1; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      try {
        final evt = Event.fromJsonString(line);
        print('📥 [ProxyClient] RECEIVED → ${evt.type}');
        _events.add(evt);
      } catch (e) {
        print('⚠️ [ProxyClient] failed to parse \"$line\": $e');
      }
    }

    // Guardar fragmento incompleto para la próxima lectura
    _buffer.write(lines.last);
  }

  /// Envía un evento (open, flagTile, etc.) al servidor.
  void send<T>(Event<T> event) {
    if (_socket == null) {
      print('⚠️ [ProxyClient] SEND failed, not connected');
      return;
    }
    final msg = event.toJsonString(); // ya incluye '\n'
    print('🚀 [ProxyClient] SEND → $msg');
    _socket!.add(utf8.encode(msg));
  }

  /// Cierra la conexión y el stream de eventos.
  Future<void> dispose() async {
    await _socketSub.cancel();
    await _socket?.close();
    await _events.close();
    print('🔒 ProxyClient disposed');
  }
}