import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:buscando_minas/logic/network/network_event.dart';
import 'package:flutter/widgets.dart';

class NetworkHost {
  ServerSocket? _server;
  Socket? _clientSocket;
  String? address;
  int? port;

  void Function(Event<dynamic> event)? onEvent;
  final void Function()? onClientConnected;

  // ➊ StreamController para difundir eventos entrantes
  final _eventController = StreamController<Event<dynamic>>.broadcast();
  // ➋ Exponemos un Stream público
  Stream<Event<dynamic>> get events => _eventController.stream;


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

  final StringBuffer _buffer = StringBuffer();

  void _handleNewConnection(Socket socket) {
    if (_clientSocket != null) return;
    _clientSocket = socket;

    debugPrint(
      '✅ Cliente conectado desde '
      '${socket.remoteAddress.address}:${socket.remotePort}',
    );
    onClientConnected?.call();

    socket.listen(
      _handleIncomingData,
      onDone: () {
        debugPrint('❌ Cliente desconectado');
        _clientSocket = null;
        _buffer.clear();
      },
      onError: (e) {
        debugPrint('❌ Error en socket: $e');
        _buffer.clear();
      },
      cancelOnError: true,
    );
  }

  void _handleIncomingData(Uint8List data) {
    final msg = utf8.decode(data);
    _buffer.write(msg);

    String bufferedStr = _buffer.toString();
    int lastNewline = bufferedStr.lastIndexOf('\n');

    if (lastNewline != -1) {
      // Tenemos al menos una línea completa
      final lines = bufferedStr.substring(0, lastNewline).split('\n');
      for (var line in lines) {
        if (line.trim().isEmpty) continue;
        try {
          final map = jsonDecode(line) as Map<String, dynamic>;
          debugPrint('✈️ [HOST_RAW] Línea cruda del cliente: $line');
          final event = Event.fromJsonMap(map);
          _eventController.add(event);
          debugPrint('🛬 [HOST] Evento parseado: ${event.type}, data=${event.data}');
          onEvent?.call(event);
        } catch (e) {
          debugPrint('⚠️ Error al decodificar mensaje (host): $line → $e');
        }
      }
      // Guardamos solo la parte incompleta que quedó
      _buffer.clear();
      _buffer.write(bufferedStr.substring(lastNewline + 1));
    }
  }

  void send(Event<dynamic> event) {
    if (_clientSocket == null) {
      debugPrint('⚠️ No hay cliente conectado');
      return;
    }
    final packet = '${event.toJsonString()}\n';
    debugPrint('🛰 Enviando al cliente: $packet');
    _clientSocket!.write(packet);
  }

  void stop() {
    debugPrint('🛑 Cerrando servidor');
    _clientSocket?.close();
    _server?.close();
    _eventController.close();
  }
}

class NetworkClient {
  Socket? _socket;
  final void Function()? onConnected;
  void Function(Event<dynamic> event)? onEvent;

  final StringBuffer _buffer = StringBuffer();

  NetworkClient({this.onConnected, this.onEvent});

  Future<void> connect(String host, int port) async {
    _socket = await Socket.connect(host, port);
    debugPrint('✅ Conectado al host: $host:$port');
    onConnected?.call();
    _socket!.listen(
      _handleIncomingData,
      onDone: () {
        debugPrint('🚫 Conexión cerrada desde el host');
        _socket = null;
        _buffer.clear();
      },
      onError: (e) {
        debugPrint('❌ Error en cliente: $e');
        _buffer.clear();
      },
      cancelOnError: true,
    );
  }

  void _handleIncomingData(Uint8List data) {
    final msg = utf8.decode(data);
    _buffer.write(msg);

    String bufferedStr = _buffer.toString();
    int lastNewline = bufferedStr.lastIndexOf('\n');

    if (lastNewline != -1) {
      final lines = bufferedStr.substring(0, lastNewline).split('\n');
      for (var line in lines) {
        if (line.trim().isEmpty) continue;
        try {
          final map = jsonDecode(line) as Map<String, dynamic>;
          final event = Event.fromJsonMap(map);
          debugPrint('📥 Cliente recibió evento: ${event.type}');
          onEvent?.call(event);
        } catch (e) {
          debugPrint('⚠️ Error al decodificar mensaje (cliente): $line → $e');
        }
      }
      _buffer.clear();
      _buffer.write(bufferedStr.substring(lastNewline + 1));
    }
  }

  void send(Event<dynamic> event) {
    final jsonData = event.toJsonString();
    debugPrint('📤 Cliente envía: $jsonData');
    _socket?.write('$jsonData\n');
  }

  Future<void> disconnect() async {
    await _socket?.close();
    _socket = null;
  }
}
