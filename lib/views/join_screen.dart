import 'package:flutter/material.dart';
import 'package:buscando_minas/logic/network/proxy_client.dart';
import 'package:buscando_minas/views/client_game_screen.dart';

class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key});

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  final _hostController = TextEditingController();
  final _portController = TextEditingController();
  late ProxyClient _client;
  bool _connecting = false;
  String? _error;
  bool _connected = false;

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    // No cerrar _client: lo usará ClientGameScreen
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
    });

    _client = ProxyClient(host: host, port: port);
    try {
      await _client.connect(role: 'client');
      debugPrint('✅ ProxyClient (client) conectado');
      setState(() => _connected = true);
    } catch (e) {
      setState(() => _error = 'Error al conectar: $e');
    } finally {
      setState(() => _connecting = false);
    }
  }

  void _goToGame() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ClientGameScreen(client: _client),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: const Text(
          '🔍 Unirse a partida',
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
              enabled: !_connecting && !_connected,
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
              enabled: !_connecting && !_connected,
            ),
            const SizedBox(height: 24),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              const SizedBox(height: 12),
            ],
            ElevatedButton(
              onPressed:
                  (_connecting || _connected) ? null : _connect,
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
            if (_connected)
              ElevatedButton(
                onPressed: _goToGame,
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