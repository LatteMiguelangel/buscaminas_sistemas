import 'package:flutter/material.dart';
import 'package:buscando_minas/views/game_screen.dart';

class GameScreenLauncher extends StatelessWidget {
  final int numberOfBombs;

  const GameScreenLauncher({super.key, required this.numberOfBombs});

  @override
  Widget build(BuildContext context) {
    return GameScreen(numberOfBombs: numberOfBombs);
  }
}