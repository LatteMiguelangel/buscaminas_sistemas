import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:buscando_minas/logic/network/network_event.dart';

/// Gestiona la lógica de servidor (host).
class NetworkHost {
  ServerSocket? _server;
  Socket? _clientSocket;

  /// Dirección y puerto tras arrancar el servidor.
  String? address;
  int? port;

  /// Callback para eventos entrantes (NetEvent)
  void Function(NetEvent event)? onEvent;
  final void Function()? onClientConnected;

  NetworkHost({this.onClientConnected, this.onEvent});

  Future<void> startServer() async {
    // 1. Arranca servidor en puerto dinámico
    _server = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
    port = _server!.port;

    // 2. Obtén IP local (primera IPv4 no-loopback)
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

    // 3. Escucha conexiones entrantes
    _server!.listen(_handleNewConnection);
  }

  void _handleNewConnection(Socket socket) {
    if (_clientSocket != null) return; // Sólo un cliente
    _clientSocket = socket;
    onClientConnected?.call(); // Notifica UI
    socket.listen(_handleIncomingData, onDone: (){
      //cliente desconectado
      _clientSocket = null;
    });
    
  }

  void _handleIncomingData(Uint8List data) {
    try{
      final msg = utf8.decode(data);
      final jsonMap = jsonDecode(msg) as Map<String, dynamic>;
      final event = NetEvent.fromJson(jsonMap);
      onEvent?.call(event);
    } catch (_) {/* ignora mensajes invalidos*/}
  }

  void send(Map<String, dynamic> event) {
    if (_clientSocket == null) return;
    _clientSocket!.write(jsonEncode(event));
  }

  Future<void> stop() async {
    await _clientSocket?.close();
    await _server?.close();
  }
}

/// Gestiona la lógica de cliente.
class NetworkClient {
  Socket? _socket;
  final void Function()? onConnected;
  void Function(NetEvent event)? onEvent;

  NetworkClient({this.onConnected, this.onEvent});

  Future<void> connect(String host, int port) async {
    _socket = await Socket.connect(host, port);
    onConnected?.call();
    _socket!.listen(_handleIncomingData, onDone: () {
      _socket = null;
    });
  }

  void _handleIncomingData(Uint8List data) {
    try{
      final msg = utf8.decode(data);
      final jsonMap = jsonDecode(msg) as Map<String, dynamic>;
      final event = NetEvent.fromJson(jsonMap);
      onEvent?.call(event);
    } catch (_) {/* ignora mensajes invalidos*/}
  }

  void send(Map<String, dynamic> event) {
    if (_socket == null) return;
    _socket!.write(jsonEncode(event));
  }

  Future<void> disconnect() async {
    await _socket?.close();
  }
}