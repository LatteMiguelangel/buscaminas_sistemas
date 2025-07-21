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
  final _events = StreamController<Event<dynamic>>.broadcast();
  String _buf = '';

  Stream<Event<dynamic>> get events => _events.stream;

  ProxyClient({required this.host, required this.port});

  Future<void> connect({required String role}) async {
    _socket = await Socket.connect(host, port);
    print('✅ ProxyClient connected to $host:$port as $role');

    // mando el registro
    final reg = jsonEncode({'type': 'register', 'role': role}) + '\n';
    print('🚀 [ProxyClient] SEND REGISTER → $reg');
    _socket!.write(reg);
    await _socket!.flush();

    _socket!.listen(_onData, onDone: () {
      print('❌ ProxyClient: socket closed by server');
      _socket = null;
      _events.close();
    }, onError: (e) {
      print('⚠️ ProxyClient: socket error $e');
      _socket = null;
      _events.addError(e);
    });
  }

  void _onData(Uint8List chunk) {
    _buf += utf8.decode(chunk);
    final lines = _buf.split('\n');
    _buf = lines.removeLast();
    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;
      try {
        final evt = Event.fromJsonString(line);
        _events.add(evt);
        print('📥 [ProxyClient] RECEIVED → ${evt.type}');
      } catch (e) {
        print('⚠️ [ProxyClient] failed to parse "$line": $e');
      }
    }
  }

  void send<T>(Event<T> event) {
    final msg = event.toJsonString(); // ya trae '\n'
    if (_socket == null) {
      print('⚠️ [ProxyClient] SEND failed, not connected');
      return;
    }
    print('🚀 [ProxyClient] SEND → $msg');
    _socket!.write(msg);
    _socket!.flush();
  }

  Future<void> dispose() async {
    await _socket?.close();
    await _events.close();
    print('🔒 ProxyClient disposed');
  }
}