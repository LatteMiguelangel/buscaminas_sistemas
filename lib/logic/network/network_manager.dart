import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:buscando_minas/logic/network/network_event.dart';

class NetworkHost {
  ServerSocket? _server;
  Socket? _clientSocket;
  String? address;
  int? port;

  void Function(Event<dynamic> event)? onEvent;
  final void Function()? onClientConnected;

  NetworkHost({ this.onClientConnected, this.onEvent });

  Future<void> startServer() async {
    _server = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
    port = _server!.port;

    final interfaces = await NetworkInterface.list(
      includeLoopback: false, includeLinkLocal: false);
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

    print('✅ Cliente conectado desde '
      '${socket.remoteAddress.address}:${socket.remotePort}');
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
      cancelOnError: true,
    );
  }

  void _handleIncomingData(Uint8List data) {
    final msg = utf8.decode(data);
    LineSplitter.split(msg).forEach((line) {
      try {
        final map = jsonDecode(line) as Map<String, dynamic>;
        print('✈️ [HOST_RAW] Línea cruda del cliente: $line');
        final event = Event.fromJsonMap(map);
        print('🛬 [HOST] Evento parseado: ${event.type}, data=${event.data}');
        onEvent?.call(event);
      } catch (e) {
        print('⚠️ Error al decodificar mensaje (host): $line → $e');
      }
    });
  }

  void send(Event<dynamic> event) {
    if (_clientSocket == null) {
      print('⚠️ No hay cliente conectado');
      return;
    }
    final packet = event.toJsonString();
    print('🛰 Enviando al cliente: $packet');
    _clientSocket!.write(packet);
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
  void Function(Event<dynamic> event)? onEvent;

  NetworkClient({ this.onConnected, this.onEvent });

  Future<void> connect(String host, int port) async {
    _socket = await Socket.connect(host, port);
    print('✅ Conectado al host: $host:$port');
    onConnected?.call();
    _socket!.listen(
      _handleIncomingData,
      onDone: () {
        print('🚫 Conexión cerrada desde el host');
        _socket = null;
      },
      onError: (e) {
        print('❌ Error en cliente: $e');
      },
      cancelOnError: true,
    );
  }

  void _handleIncomingData(Uint8List data) {
    final msg = utf8.decode(data);
    LineSplitter.split(msg).forEach((line) {
      try {
        final map = jsonDecode(line) as Map<String, dynamic>;
        final event = Event.fromJsonMap(map);
        print('📥 Cliente recibió evento: ${event.type}');
        onEvent?.call(event);
      } catch (e) {
        print('⚠️ Error al decodificar mensaje (cliente): $line → $e');
      }
    });
  }

  void send(Event<dynamic> event) {
    if (_socket == null) {
      print('⚠️ No conectado al host');
      return;
    }
    final packet = event.toJsonString();
    print('📤 Cliente envía: $packet');
    _socket!.write(packet);
  }
  Future<void> disconnect() async {
    await _socket?.close();
    _socket = null;
  }
}