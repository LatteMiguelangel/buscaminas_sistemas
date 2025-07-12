import 'package:buscando_minas/views/host_screen.dart';
import 'package:buscando_minas/views/join_screen.dart';
import 'package:flutter/material.dart';


class MultiplayerMenuScreen extends StatelessWidget {
  const MultiplayerMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: const Text(
          '🌐 MULTIJUGADOR',
          style: TextStyle(fontFamily: 'Courier', color: Colors.greenAccent),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildButton(
              context,
              label: '🕹️ Hospedar partida',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HostScreen()),
                );
              },
            ),
            const SizedBox(height: 20),
            _buildButton(
              context,
              label: '🔗 Unirse a partida',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const JoinScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context,
      {required String label, required VoidCallback onPressed}) {
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