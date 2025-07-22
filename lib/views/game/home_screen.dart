import 'package:buscando_minas/views/game/difficulty_selection_screen.dart';
import 'package:buscando_minas/views/multiplayer_menu_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/retro_bg.png'),
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
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'BUSCANDO MINAS',
                  style: TextStyle(
                    fontFamily: 'PressStart2P',
                    fontSize: 24,
                    color: Colors.greenAccent,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(
                        blurRadius: 10,
                        color: Colors.greenAccent,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                _buildMenuButton(context, '🎮 JUGAR', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DifficultySelectionScreen(),
                    ),
                  );
                }),
                const SizedBox(height: 20),
                _buildMenuButton(context, '👥 MULTIJUGADOR', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MultiplayerMenuScreen(),
                    ),
                  );
                }),
                const SizedBox(height: 20),
                _buildMenuButton(context, '❌ SALIR', () {
                  // Implementar salida
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, String label, VoidCallback onPressed) {
    return SizedBox(
      width: 280,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.greenAccent,
          padding: const EdgeInsets.symmetric(vertical: 18),
          side: const BorderSide(color: Colors.greenAccent, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
          ),
          elevation: 8,
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