import 'package:buscando_minas/logic/bloc/game_bloc.dart';
import 'package:buscando_minas/logic/model.dart';
import 'package:buscando_minas/logic/network/network_event.dart';
import 'package:buscando_minas/logic/network/network_manager.dart';
import 'package:buscando_minas/views/host_game_screen.dart';
import 'package:flutter/material.dart';

class HostScreen extends StatefulWidget {
  const HostScreen({super.key});
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
              const Text(
                'Dirección para conectar:\n',
                style: TextStyle(color: Colors.white70),
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
                    // 1. Configuración de juego
                    final config = GameConfiguration(
                      width: generateCustomConfiguration(10).width,
                      height: generateCustomConfiguration(10).height,
                      numberOfBombs: 10,
                    );
                    final seed = DateTime.now().millisecondsSinceEpoch;
                    // 2. Creamos el evento GameStartData
                    final ev = Event<GameStartData>(
                      type: EventType.gameStart,
                      data: GameStartData(
                        width: config.width,
                        height: config.height,
                        numberOfBombs: config.numberOfBombs,
                        seed: seed,
                      ),
                    );
                    print('📤 Enviando gameStart al cliente: ${ev.toJsonString().trim()}');
                    // 3. Enviamos tras un pequeño retraso
                    Future.delayed(const Duration(milliseconds: 300), () {
                      _hostManager.send(ev);
                    });
                    // 4. Iniciamos el BLoC local y navegamos
                    final bloc = GameBloc(config)..add(InitializeGame(seed: seed));
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