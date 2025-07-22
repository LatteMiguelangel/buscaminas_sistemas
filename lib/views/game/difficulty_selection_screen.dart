import 'package:buscando_minas/views/game/game_screen_launcher.dart';
import 'package:flutter/material.dart';

class DifficultySelectionScreen extends StatelessWidget {
  const DifficultySelectionScreen({super.key});

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
                  '🕹️ SELECCIONA DIFICULTAD',
                  style: TextStyle(
                    fontFamily: 'PressStart2P',
                    fontSize: 16,
                    color: Colors.greenAccent,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 30),
                _buildRetroButton(context, 'FÁCIL (10 BOMBAS)', 10),
                _buildRetroButton(context, 'MEDIA (20 BOMBAS)', 20),
                _buildRetroButton(context, 'DIFÍCIL (30 BOMBAS)', 30),
                _buildCustomButton(context),
                const SizedBox(height: 20),
                _buildRetroButton(
                  context,
                  '⬅️ VOLVER',
                  0,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRetroButton(BuildContext context, String label, int bombs, {VoidCallback? onPressed}) {
    return Container(
      width: 280,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.greenAccent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Colors.greenAccent, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
          ),
          textStyle: const TextStyle(
            fontFamily: 'PressStart2P',
            fontSize: 14,
          ),
        ),
        onPressed: onPressed ?? () => _launchGame(context, bombs),
        child: Text(label),
      ),
    );
  }

  Widget _buildCustomButton(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.yellowAccent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Colors.yellowAccent, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
          ),
          textStyle: const TextStyle(
            fontFamily: 'PressStart2P',
            fontSize: 14,
          ),
        ),
        onPressed: () {
          _showCustomDialog(context);
        },
        child: const Text('🎯 PERSONALIZADO'),
      ),
    );
  }

  void _showCustomDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Colors.greenAccent, width: 2),
          borderRadius: BorderRadius.circular(0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '🔧 PERSONALIZADO',
                style: TextStyle(
                  fontFamily: 'PressStart2P',
                  color: Colors.greenAccent,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontFamily: 'Courier'),
                decoration: InputDecoration(
                  hintText: 'NÚMERO DE BOMBAS',
                  hintStyle: const TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.greenAccent),
                    borderRadius: BorderRadius.circular(0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.greenAccent),
                    borderRadius: BorderRadius.circular(0),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'CANCELAR',
                      style: TextStyle(
                        fontFamily: 'PressStart2P',
                        color: Colors.redAccent,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      final input = int.tryParse(controller.text);
                      if (input != null && input > 0) {
                        Navigator.pop(context);
                        _launchGame(context, input);
                      }
                    },
                    child: const Text(
                      'INICIAR',
                      style: TextStyle(
                        fontFamily: 'PressStart2P',
                        color: Colors.greenAccent,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _launchGame(BuildContext context, int numberOfBombs) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreenLauncher(numberOfBombs: numberOfBombs),
      ),
    );
  }
}