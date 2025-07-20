import 'package:buscando_minas/logic/network/network_manager.dart';
import 'package:buscando_minas/views/client_game_screen.dart';
import 'package:flutter/material.dart';

class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key});

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  final _hostController = TextEditingController();
  final _portController = TextEditingController();
  late final NetworkClient _clientManager;
  bool _connected = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _clientManager = NetworkClient(
      onConnected: () {
        setState(() {
          _connected = true;
          _error = null;
        });
      },
      // Podemos dejarlo vacío o con un log genérico:
      onEvent: (event) {
        // Un log provisional: 
        debugPrint('📥 Cliente recibió evento preliminar: ${event.toJsonString().trim()}');
      },
    );
  }

  Future<void> _connect() async {
    final host = _hostController.text.trim();
    final port = int.tryParse(_portController.text.trim());
    if (host.isEmpty || port == null) {
      setState(() => _error = 'IP o puerto inválido');
      return;
    }
    try {
      await _clientManager.connect(host, port);
    } catch (e) {
      setState(() => _error = 'Error al conectar: $e');
    }
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: const Text(
          '🔍 Unirse a partida',
          style: TextStyle(fontFamily: 'Courier', color: Colors.greenAccent),
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
                hintText: 'IP del host',
                hintStyle: TextStyle(color: Colors.white54),
                border: OutlineInputBorder(),
              ),
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
            ),
            const SizedBox(height: 24),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              const SizedBox(height: 12),
            ],
            ElevatedButton(
              onPressed: _connect,
              child: const Text('🔗 Conectar'),
            ),
            const SizedBox(height: 20),
            if (_connected)
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ClientGameScreen(clientManager: _clientManager),
                    ),
                  );
                },
                child: const Text('✅ Conectado: Unirse'),
              )
            else
              const Text(
                'Esperando conexión…',
                style: TextStyle(color: Colors.white70),
              ),
          ],
        ),
      ),
    );
  }
}