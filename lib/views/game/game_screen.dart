import 'package:buscando_minas/logic/bloc/game_bloc.dart';
import 'package:buscando_minas/logic/model.dart';
import 'package:buscando_minas/views/game/cell_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GameScreen extends StatelessWidget {
  final int numberOfBombs;
  const GameScreen({super.key, required this.numberOfBombs});

  @override
  Widget build(BuildContext context) {
    final configuration = generateCustomConfiguration(numberOfBombs);
    final width = configuration.width;
    final height = configuration.height;
    return BlocProvider(
      create: (context) => GameBloc(configuration)..add(InitializeGame()),
      child: BlocBuilder<GameBloc, GameState>(
        builder:
            (context, state) => Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.black54,
                title: const Center(child: Text('MINESWEEPER')),
              ),
              body: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black, Colors.black],
                  ),
                ),
                child: Builder(
                  builder: (_) {
                    if (state is Playing) {
                      return _gameContent(state, width, height);
                    } else if (state is GameOver) {
                      return _gameOverContent(context, state);
                    } else if (state is Victory) {
                      return _victoryContent(context, state);
                    } else {
                      return _loading();
                    }
                  },
                ),
              ),
            ),
      ),
    );
  }

  Widget _loading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _gameContent(Playing state, int width, int height) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("🚩 ${state.flagsRemaining}"),
              Text("⏱️ ${_formatTime(state.elapsedSeconds)}")
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final gridSize = constraints.maxWidth;
              return Center(
                child: SizedBox(
                  width: gridSize,
                  height: gridSize,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: width,
                          crossAxisSpacing: 1,
                          mainAxisSpacing: 1,
                          childAspectRatio: width / height,
                        ),
                    padding: const EdgeInsets.all(2),
                    itemCount: state.cells.length,
                    itemBuilder: (context, index) {
                      return CellView(cell: state.cells[index]);
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _gameOverContent(BuildContext context, GameOver state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          '💥 ¡Has perdido!',
          style: TextStyle(fontSize: 24, color: Colors.red),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            context.read<GameBloc>().add(InitializeGame());
          },
          child: const Text('🔁 Jugar de nuevo'),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(); // O ir al menú
          },
          child: const Text('🏠 Volver al menú'),
        ),
      ],
    );
  }

  Widget _victoryContent(BuildContext context, Victory state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          '🎉 ¡Has ganado!',
          style: TextStyle(fontSize: 24, color: Colors.greenAccent),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            context.read<GameBloc>().add(InitializeGame());
          },
          child: const Text('🔁 Jugar de nuevo'),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('🏠 Volver al menú'),
        ),
      ],
    );
  }
}

String _formatTime(int seconds) {
  final minutes = seconds ~/ 60;
  final secs = seconds % 60;
  return "${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
}