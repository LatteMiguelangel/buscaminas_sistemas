// host_screen.dart

import 'package:buscando_minas/logic/bloc/game_bloc.dart';
import 'package:buscando_minas/logic/model.dart';
import 'package:buscando_minas/logic/network/network_event.dart';
import 'package:buscando_minas/logic/network/network_manager.dart';
import 'package:buscando_minas/views/host_game_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class HostScreen extends StatefulWidget {
  final GameConfiguration configuration;

  const HostScreen({
    super.key,
    required this.configuration,
  });

  @override
  State<HostScreen> createState() => _HostScreenState();
}

class _HostScreenState extends State<HostScreen> {
  late final NetworkHost _hostManager;
  String? _addressPort;
  bool _clientConnected = false;

  @override
  void initState() {
    super.initState();
    _hostManager = NetworkHost(
      onClientConnected: () {
        setState(() => _clientConnected = true);
      },
    );
    _startServer();
  }

  Future<void> _startServer() async {
    await _hostManager.startServer();
    setState(() {
      _addressPort = '${_hostManager.address}:${_hostManager.port}';
    });
  }

  @override
  void dispose() {
    //_hostManager.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: const Text(
          '🖥️ Hospedar partida',
          style: TextStyle(fontFamily: 'Courier', color: Colors.greenAccent),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_addressPort == null) ...[
              const CircularProgressIndicator(color: Colors.greenAccent),
              const SizedBox(height: 16),
              const Text(
                'Arrancando servidor…',
                style: TextStyle(color: Colors.white),
              ),
            ] else ...[
              Text(
                'Dirección para conectar:\n',
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              SelectableText(
                _addressPort!,
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontFamily: 'Courier',
                  fontSize: 20,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (_clientConnected) ...[
                const Text(
                  '✅ Cliente conectado',
                  style: TextStyle(color: Colors.greenAccent),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    final cfg = widget.configuration;
                    final seed = DateTime.now().millisecondsSinceEpoch;
                    final event = NetEvent(
                      type: NetEventType.gameStart,
                      data: {
                        'width': cfg.width,
                        'height': cfg.height,
                        'numberOfBombs': cfg.numberOfBombs,
                        'seed': seed,
                      },
                    );
                    if (kDebugMode) {
                      print(
                        '📤 Enviando gameStart al cliente: ${event.toJson()}',
                      );
                    }
                    Future.delayed(const Duration(milliseconds: 300), () {
                      _hostManager.send(event.toJson());
                    });
                    final bloc = GameBloc(cfg)
                      ..add(InitializeGame(seed: seed));
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HostGameScreen(
                          bloc: bloc,
                          hostManager: _hostManager,
                        ),
                      ),
                    );
                  },
                  child: const Text('🚀 Empezar partida'),
                ),
              ] else ...[
                const Text(
                  '⏳ Esperando cliente…',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
