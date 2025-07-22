import 'package:buscando_minas/views/host_screen.dart';
import 'package:buscando_minas/views/join_screen.dart';
import 'package:flutter/material.dart';

class MultiplayerMenuScreen extends StatelessWidget {
  const MultiplayerMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/retro_bg.png'), // Puedes usar una imagen de fondo pixelada
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: Colors.black.withOpacity(0.8),
              border: Border.all(color: Colors.greenAccent, width: 2),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  // ignore: deprecated_member_use
                  color: Colors.greenAccent.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 5)
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '🌐 MULTIJUGADOR',
                  style: TextStyle(
                    fontFamily: 'PressStart2P',
                    fontSize: 20,
                    color: Colors.greenAccent,
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(
                        blurRadius: 10,
                        color: Colors.greenAccent,
                        offset: Offset(0, 0),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                _buildRetroButton(
                  context,
                  label: '🕹️ HOSPEDAR PARTIDA',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HostScreen()),
                    );
                  },
                ),
                const SizedBox(height: 20),
                _buildRetroButton(
                  context,
                  label: '🔗 UNIRSE A PARTIDA',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const JoinScreen()),
                    );
                  },
                ),
                const SizedBox(height: 20),
                _buildRetroButton(
                  context,
                  label: '⬅️ VOLVER',
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRetroButton(BuildContext context,
      {required String label, required VoidCallback onPressed}) {
    return SizedBox(
      width: 280,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.greenAccent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Colors.greenAccent, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
          ),
          elevation: 8,
          // ignore: deprecated_member_use
          shadowColor: Colors.greenAccent.withOpacity(0.5),
          textStyle: const TextStyle(
            fontFamily: 'PressStart2P',
            fontSize: 14,
            letterSpacing: 1.2,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}