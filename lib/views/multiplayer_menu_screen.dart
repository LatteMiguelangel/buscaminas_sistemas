// lib/views/multiplayer_menu_screen.dart

import 'package:flutter/material.dart';
import 'package:buscando_minas/logic/network/proxy_client.dart';
import 'package:buscando_minas/views/multiplayer_game_screen.dart';

class MultiplayerMenuScreen extends StatelessWidget {
  const MultiplayerMenuScreen({super.key});

  // Ajusta esto a la IP/puerto de tu servidor-relé
  static const _serverIp = '192.168.1.117';
  static const _serverPort = 4040;

  Future<void> _startGame(BuildContext context, bool isHost) async {
    // 1) creamos y conectamos el proxy
    final proxy = ProxyClient(host: _serverIp, port: _serverPort);
    await proxy.connect(role: isHost ? 'host' : 'client');

    // 2) capturamos el Navigator ANTES del await
    final navigator = Navigator.of(context);

    // 3) navegamos sin usar `context` tras el await
    navigator.push(
      MaterialPageRoute(
        builder: (_) => MultiplayerGameScreen(
          proxy: proxy,
          isHost: isHost,
        ),
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
          '🌐 MULTIJUGADOR',
          style: TextStyle(
            fontFamily: 'Courier',
            color: Colors.greenAccent,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildButton(
              label: '🕹️ Hospedar partida',
              onPressed: () => _startGame(context, true),
            ),
            const SizedBox(height: 20),
            _buildButton(
              label: '🔗 Unirse a partida',
              onPressed: () => _startGame(context, false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 200,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.greenAccent,
          foregroundColor: Colors.black,
          textStyle: const TextStyle(
            fontFamily: 'Courier',
            fontSize: 16,
          ),
        ),
        child: Text(label, textAlign: TextAlign.center),
      ),
    );
  }
}