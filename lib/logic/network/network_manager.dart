import 'dart:io';
import 'dart:convert';
import 'package:buscando_minas/logic/network/network_event.dart';
import 'package:flutter/foundation.dart';

class NetworkHost {
  ServerSocket? _server;
  Socket? _clientSocket;

  String? address;
  int? port;

  void Function(NetEvent event)? onEvent;
  final void Function()? onClientConnected;

  NetworkHost({this.onClientConnected, this.onEvent});

  Future<void> startServer() async {
    _server = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
    port = _server!.port;

    final interfaces = await NetworkInterface.list(
      includeLoopback: false,
      includeLinkLocal: false,
    );
    for (var iface in interfaces) {
      for (var addr in iface.addresses) {
        if (addr.type == InternetAddressType.IPv4) {
          address = addr.address;
          break;
        }
      }
      if (address != null) break;
    }
    _server!.listen(_handleNewConnection);
  }

  void _handleNewConnection(Socket socket) {
    if (_clientSocket != null) return;
    _clientSocket = socket;
    print(
      '✅ Cliente conectado desde ${socket.remoteAddress.address}:${socket.remotePort}',
    );
    onClientConnected?.call();
    socket.listen(
      _handleIncomingData,
      onDone: () {
        print('❌ Cliente desconectado');
        _clientSocket = null;
      },
      onError: (e) {
        print('❌ Error en socket: $e');
      },
    );
  }

  void _handleIncomingData(Uint8List data) {
    final msg = utf8.decode(data);
    LineSplitter.split(msg).forEach((line) {
      try {
        final jsonMap = jsonDecode(line) as Map<String, dynamic>;
        final event = NetEvent.fromJson(jsonMap);
        onEvent?.call(event);
      } catch (_) {
        print('⚠️ Error al decodificar mensaje (host): $line');
      }
    });
  }

  void send(Map<String, dynamic> event) {
    if (_clientSocket == null) {
      print('⚠️ No hay cliente conectado, no se puede enviar el evento');
      return;
    }
    final jsonData = jsonEncode(event);
    print('🛰 Enviando JSON: $jsonData');
    _clientSocket!.write('$jsonData\n');
  }

  void stop() {
    print('🛑 Cerrando servidor');
    _clientSocket?.close();
    _server?.close();
  }
}

class NetworkClient {
  Socket? _socket;
  final void Function()? onConnected;
  void Function(NetEvent event)? onEvent;
  NetworkClient({this.onConnected, this.onEvent});
  Future<void> connect(String host, int port) async {
    _socket = await Socket.connect(host, port);
    print('✅ Conectado al host: $host:$port');
    onConnected?.call();
    _socket!.listen(
      _handleIncomingData,
      onDone: () {
        print("Conexión cerrada desde el cliente");
        _socket = null;
      },
      onError: (e) {
        print('❌ Error en cliente: $e');
      },
    );
  }

  void _handleIncomingData(Uint8List data) {
    try {
      final msg = utf8.decode(data);
      print('📦 Mensaje recibido del host: $msg');
      for (final line in LineSplitter.split(msg)) {
        try {
          final jsonMap = jsonDecode(line) as Map<String, dynamic>;
          final event = NetEvent.fromJson(jsonMap);
          onEvent?.call(event);
        } catch (e) {
          print('⚠️ Error al decodificar mensaje (cliente): $line');
        }
      }
    } catch (e) {
      print('⚠️ Error al manejar mensaje: $e');
    }
  }

  void send(Map<String, dynamic> event) {
    if (_socket == null) return;
    _socket!.write('${jsonEncode(event)}\n');
  }

  Future<void> disconnect() async {
    await _socket?.close();
  }
}
