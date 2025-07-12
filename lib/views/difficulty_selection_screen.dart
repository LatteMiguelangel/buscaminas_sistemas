import 'package:buscando_minas/views/game_screen_launcher.dart';
import 'package:flutter/material.dart';

class DifficultySelectionScreen extends StatelessWidget {
  const DifficultySelectionScreen({super.key});

  void _launchGame(BuildContext context, int numberOfBombs) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreenLauncher(numberOfBombs: numberOfBombs),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: const Text('🕹️ SELECCIONA DIFICULTAD',
            style: TextStyle(fontFamily: 'Courier', color: Colors.greenAccent)),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildRetroButton(context, 'FÁCIL (10 bombas)', 10),
            _buildRetroButton(context, 'MEDIA (20 bombas)', 20),
            _buildRetroButton(context, 'DIFÍCIL (30 bombas)', 30),
            _buildCustomButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildRetroButton(BuildContext context, String label, int bombs) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.greenAccent,
          foregroundColor: Colors.black,
          textStyle: const TextStyle(
            fontFamily: 'Courier',
            fontSize: 18,
          ),
        ),
        onPressed: () => _launchGame(context, bombs),
        child: Text(label),
      ),
    );
  }

  Widget _buildCustomButton(BuildContext context) {
    final TextEditingController controller = TextEditingController();

    return Padding(
      padding: const EdgeInsets.all(10),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.yellowAccent,
          foregroundColor: Colors.black,
          textStyle: const TextStyle(
            fontFamily: 'Courier',
            fontSize: 18,
          ),
        ),
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: Colors.black87,
              title: const Text('🔧 Personalizado',
                  style: TextStyle(color: Colors.white, fontFamily: 'Courier')),
              content: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Número de bombas',
                  hintStyle: TextStyle(color: Colors.white54),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    final input = int.tryParse(controller.text);
                    if (input != null && input > 0) {
                      Navigator.pop(context);
                      _launchGame(context, input);
                    }
                  },
                  child: const Text('Iniciar',
                      style: TextStyle(color: Colors.greenAccent)),
                ),
              ],
            ),
          );
        },
        child: const Text('🎯 PERSONALIZADO'),
      ),
    );
  }
}