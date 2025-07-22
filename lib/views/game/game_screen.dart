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
        builder: (context, state) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: const Center(
              child: Text(
                'MINESWEEPER',
                style: TextStyle(
                  fontFamily: 'PressStart2P',
                  color: Colors.greenAccent,
                  fontSize: 16,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            elevation: 0,
            // ignore: deprecated_member_use
            shadowColor: Colors.greenAccent.withOpacity(0.3),
          ),
          body: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/retro_bg.png'),
                fit: BoxFit.cover,
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.greenAccent),
          const SizedBox(height: 20),
          Text(
            'CARGANDO...',
            style: TextStyle(
              fontFamily: 'PressStart2P',
              color: Colors.greenAccent,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _gameContent(Playing state, int width, int height) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.7),
            border: Border.all(color: Colors.greenAccent, width: 1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "🚩 ${state.flagsRemaining}",
                style: const TextStyle(
                  fontFamily: 'PressStart2P',
                  color: Colors.greenAccent,
                  fontSize: 14,
                ),
              ),
              Text(
                "⏱ ${_formatTime(state.elapsedSeconds)}",
                style: const TextStyle(
                  fontFamily: 'PressStart2P',
                  color: Colors.greenAccent,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final gridSize = constraints.maxWidth;
              return Center(
                child: Container(
                  width: gridSize,
                  height: gridSize,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    // ignore: deprecated_member_use
                    border: Border.all(color: Colors.greenAccent.withOpacity(0.5), width: 2),
                  ),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: width,
                      crossAxisSpacing: 1,
                      mainAxisSpacing: 1,
                      childAspectRatio: width / height,
                    ),
                    itemCount: state.cells.length,
                    itemBuilder: (context, index) {
                      return CellView(cell: state.cells[index], isClientFlag: false,);
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
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          // ignore: deprecated_member_use
          color: Colors.black.withOpacity(0.9),
          border: Border.all(color: Colors.redAccent, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '💥 GAME OVER',
              style: TextStyle(
                fontFamily: 'PressStart2P',
                fontSize: 24,
                color: Colors.redAccent,
                shadows: [
                  Shadow(
                    blurRadius: 10,
                    // ignore: deprecated_member_use
                    color: Colors.redAccent.withOpacity(0.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            _buildRetroButton(
              context,
              '🔁 JUGAR DE NUEVO',
              onPressed: () {
                context.read<GameBloc>().add(InitializeGame());
              }, label: '',
            ),
            const SizedBox(height: 15),
            _buildRetroButton(
              context,
              '🏠 MENÚ PRINCIPAL',
              onPressed: () {
                Navigator.of(context).pop();
              }, label: '',
            ),
          ],
        ),
      ),
    );
  }

  Widget _victoryContent(BuildContext context, Victory state) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          // ignore: deprecated_member_use
          color: Colors.black.withOpacity(0.9),
          border: Border.all(color: Colors.greenAccent, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🎉 VICTORIA!',
              style: TextStyle(
                fontFamily: 'PressStart2P',
                fontSize: 24,
                color: Colors.greenAccent,
                shadows: [
                  Shadow(
                    blurRadius: 10,
                    // ignore: deprecated_member_use
                    color: Colors.greenAccent.withOpacity(0.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Tiempo: ${_formatTime(state.elapsedSeconds ?? 0)}',
              style: const TextStyle(
                fontFamily: 'PressStart2P',
                color: Colors.greenAccent,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 30),
            _buildRetroButton(
              context,
              '🔁 JUGAR DE NUEVO',
              onPressed: () {
                context.read<GameBloc>().add(InitializeGame());
              }, label: '',
            ),
            const SizedBox(height: 15),
            _buildRetroButton(
              context,
              '🏠 MENÚ PRINCIPAL',
              onPressed: () {
                Navigator.of(context).pop();
              }, label: '',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRetroButton(BuildContext context, String s,
      {required String label, required VoidCallback onPressed}) {
    return SizedBox(
      width: 250,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.greenAccent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Colors.greenAccent, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
          ),
          elevation: 8,
          // ignore: deprecated_member_use
          shadowColor: Colors.greenAccent.withOpacity(0.3),
          textStyle: const TextStyle(
            fontFamily: 'PressStart2P',
            fontSize: 12,
            letterSpacing: 1.2,
          ),
        ),
        child: Text(label),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }
}

extension on Victory {
  int? get elapsedSeconds => null;
}