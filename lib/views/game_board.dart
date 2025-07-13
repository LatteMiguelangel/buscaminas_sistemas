import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:buscando_minas/logic/bloc/game_bloc.dart';
import 'package:buscando_minas/views/game/cell_view.dart';
import 'package:buscando_minas/logic/network/network_manager.dart';

class GameBoard extends StatelessWidget {
  final bool isHost;
  final String? myPlayerId;
  final NetworkClient? clientManager;

  const GameBoard({
    super.key,
    required this.isHost,
    this.myPlayerId,
    this.clientManager,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameBloc, GameState>(
      builder: (context, state) {
        if (state is Playing) {
          final config = state.gameConfiguration!;
          final width = config.width;
          final height = config.height;
          final locked = !isHost && state.currentPlayerId != myPlayerId;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("🚩 ${state.flagsRemaining}"),
                    Text("⏱ ${_formatTime(state.elapsedSeconds)}"),
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
                            return GestureDetector(
                              onTap: locked
                                  ? null
                                  : () {
                                      if (isHost) {
                                        context
                                            .read<GameBloc>()
                                            .add(TapCell(index));
                                      } else {
                                        clientManager!.send({
                                          'type': 'revealTile',
                                          'data': {
                                            'index': index,
                                            'playerId': myPlayerId,
                                          },
                                        });
                                      }
                                    },
                              onLongPress: locked
                                  ? null
                                  : () {
                                      if (isHost) {
                                        context
                                            .read<GameBloc>()
                                            .add(ToggleFlag(index));
                                      } else {
                                        clientManager!.send({
                                          'type': 'flagTile',
                                          'data': {
                                            'index': index,
                                            'playerId': myPlayerId,
                                          },
                                        });
                                      }
                                    },
                              child: CellView(cell: state.cells[index]),
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
        } else if (state is GameOver) {
          return Center(child: Text('💥 Has perdido'));
        } else if (state is Victory) {
          return Center(child: Text('🎉 Has ganado'));
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }
}