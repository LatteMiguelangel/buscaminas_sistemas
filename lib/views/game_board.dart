// game_board.dart
import 'package:buscando_minas/logic/model.dart';
import 'package:buscando_minas/logic/network/network_event.dart';
import 'package:buscando_minas/views/game/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:buscando_minas/logic/bloc/game_bloc.dart';
import 'package:buscando_minas/views/game/cell_view.dart';
import 'package:buscando_minas/logic/network/network_manager.dart';

class GameBoard extends StatelessWidget {
  final bool isHost;
  final String myPlayerId;
  final NetworkClient? clientManager;

  const GameBoard({
    super.key,
    required this.isHost,
    required this.myPlayerId,
    this.clientManager,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameBloc, GameState>(
      builder: (context, state) {
        if (state is Playing) {
          return _buildPlaying(context, state);
        }

        // Fin de partida: GameOver o Victory
        final bool won = state is Victory;
        final List<Cell> revealCells = (state is GameOver)
            ? state.cells
            : (state is Victory)
                ? state.cells
                    .map((c) => c is CellClosed
                        ? CellOpened(index: c.index, content: c.content)
                        : c)
                    .toList()
                : [];

        return Stack(
          children: [
            _buildGrid(context, revealCells,
                (state as dynamic).gameConfiguration!),
            Container(
              color: Colors.black54,
              alignment: Alignment.center,
              child: _buildEndDialog(context, won),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlaying(BuildContext context, Playing state) {
    final width = state.gameConfiguration!.width;
    final height = state.gameConfiguration!.height;
    final locked = state.currentPlayerId != myPlayerId;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("🚩 ${state.flagsRemaining}",
                  style: const TextStyle(color: Colors.white)),
              Text("⏱ ${_formatTime(state.elapsedSeconds)}",
                  style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
        Text(
          "🎮 Turno de: ${state.currentPlayerId}",
          style: const TextStyle(color: Colors.white),
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
                      return GestureDetector(
                        onTap: () {
                          if (locked) return;
                          if (isHost) {
                            context
                                .read<GameBloc>()
                                .add(TapCell(index, myPlayerId));
                          } else {
                            clientManager!.send(
                              NetEvent(
                                type: NetEventType.revealTile,
                                data: {
                                  'index': index,
                                  'playerId': myPlayerId,
                                },
                              ).toJson(),
                            );
                          }
                        },
                        onLongPress: () {
                          if (locked) return;
                          if (isHost) {
                            context.read<GameBloc>().add(
                                ToggleFlag(index: index, playerId: myPlayerId));
                          } else {
                            clientManager!.send(
                              NetEvent(
                                type: NetEventType.flagTile,
                                data: {
                                  'index': index,
                                  'playerId': myPlayerId,
                                },
                              ).toJson(),
                            );
                          }
                        },
                        child: CellView(
                          key: ValueKey(state.cells[index]),
                          cell: state.cells[index],
                        ),
                      );
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

  Widget _buildGrid(
      BuildContext context, List<Cell> cells, GameConfiguration config) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: config.width,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
      ),
      padding: const EdgeInsets.all(2),
      itemCount: cells.length,
      itemBuilder: (_, i) => CellView(key: ValueKey(cells[i]), cell: cells[i]),
    );
  }

  Widget _buildEndDialog(BuildContext context, bool won) {
    return AlertDialog(
      backgroundColor: Colors.black87,
      title: Text(
        won ? '🎉 ¡Ganaste!' : '💥 Has perdido',
        style: const TextStyle(color: Colors.white),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => HomeScreen()),
            );
          },
          child: const Text(
            'Volver a jugar',
            style: TextStyle(color: Colors.greenAccent),
          ),
        ),
      ],
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }
}
