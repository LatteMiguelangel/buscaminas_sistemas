// lib/views/host_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:buscando_minas/logic/network/proxy_client.dart';
import 'package:buscando_minas/logic/network/network_event.dart';
import 'package:buscando_minas/logic/bloc/game_bloc.dart';
import 'package:buscando_minas/logic/model.dart';
import 'package:buscando_minas/views/host_game_screen.dart';

class HostScreen extends StatefulWidget {
  const HostScreen({Key? key}) : super(key: key);

  @override
  State<HostScreen> createState() => _HostScreenState();
}

class _HostScreenState extends State<HostScreen> {
  final _hostController = TextEditingController();
  final _portController = TextEditingController();

  late ProxyClient _proxy;
  StreamSubscription<Event<dynamic>>? _sub;

  bool _connecting = false;
  bool _connected = false;
  bool _handshakeDone = false;
  String? _error;

  @override
  void dispose() {
    _sub?.cancel();
    if (_connected) {
      // No cerramos _proxy: lo usará HostGameScreen
    }
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final host = _hostController.text.trim();
    final port = int.tryParse(_portController.text.trim());
    if (host.isEmpty || port == null) {
      setState(() => _error = 'IP o puerto inválido');
      return;
    }

    setState(() {
      _connecting = true;
      _error = null;
      _handshakeDone = false;
    });

    _proxy = ProxyClient(host: host, port: port);
    try {
      await _proxy.connect(role: 'host');
      debugPrint('✅ ProxyClient (host) conectado');

      // Hand-shake: esperar clientReady
      _sub = _proxy.events.listen((evt) {
        if (evt.type == EventType.clientReady) {
          debugPrint('✋ Handshake completo: clientReady recibido');
          setState(() => _handshakeDone = true);
        }
      });

      setState(() => _connected = true);
    } catch (e) {
      setState(() => _error = 'Error al conectar: $e');
    } finally {
      setState(() => _connecting = false);
    }
  }

  void _startGame() {
    if (!_connected || !_handshakeDone) return;

    final config = generateCustomConfiguration(10);
    final seed = DateTime.now().millisecondsSinceEpoch;

    final ev = Event<GameStartData>(
      type: EventType.gameStart,
      data: GameStartData(
        width: config.width,
        height: config.height,
        numberOfBombs: config.numberOfBombs,
        seed: seed,
      ),
    );
    _proxy.send(ev);
    debugPrint('📤 ProxyClient envía gameStart: ${ev.toJsonString().trim()}');

    final bloc = GameBloc(config, enableTimer: false)
      ..add(InitializeGame(seed: seed));

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HostGameScreen(
          bloc: bloc,
          hostManager: _proxy,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canConnect = !_connecting && !_connected;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: const Text(
          '🖥️ Hospedar partida',
          style: TextStyle(color: Colors.greenAccent),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _hostController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'IP del servidor',
                hintStyle: TextStyle(color: Colors.white54),
                border: OutlineInputBorder(),
              ),
              enabled: canConnect,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _portController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Puerto',
                hintStyle: TextStyle(color: Colors.white54),
                border: OutlineInputBorder(),
              ),
              enabled: canConnect,
            ),
            const SizedBox(height: 24),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              const SizedBox(height: 12),
            ],
            ElevatedButton(
              onPressed: canConnect ? _connect : null,
              child: _connecting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('🔗 Conectar'),
            ),
            const SizedBox(height: 20),
            if (_connected) ...[
              if (!_handshakeDone)
                const Text(
                  '⏳ Esperando cliente listo…',
                  style: TextStyle(color: Colors.white70),
                )
              else
                ElevatedButton(
                  onPressed: _startGame,
                  child: const Text('🚀 Empezar partida'),
                ),
            ] else ...[
              const Text(
                'Esperando conexión…',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ],
        ),
      ),
    );
  }
}