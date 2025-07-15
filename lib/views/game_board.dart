import 'package:buscando_minas/logic/network/network_event.dart';
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
        print('🔄 GameBoard rebuild con estado: ${state.runtimeType}');
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
                                if (!locked) {
                                  if (isHost) {
                                    context.read<GameBloc>().add(
                                          TapCell(index),
                                        );
                                  } else if (clientManager != null) {
                                    print('📨 Cliente envía revealTile: $index');
                                    clientManager!.send(
                                      NetEvent(
                                        type: NetEventType.revealTile,
                                        data: {'index': index},
                                      ).toJson(),
                                    );
                                  }
                                }
                              },
                              onLongPress: () {
                                if (!locked) {
                                  if (isHost) {
                                    context.read<GameBloc>().add(
                                          ToggleFlag(index),
                                        );
                                  } else if (clientManager != null) {
                                    print('📨 Cliente envía flagTile: $index');
                                    clientManager!.send(
                                      NetEvent(
                                        type: NetEventType.flagTile,
                                        data: {'index': index},
                                      ).toJson(),
                                    );
                                  }
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
        } else if (state is GameOver) {
          return const Center(child: Text('💥 Has perdido', style: TextStyle(color: Colors.white)));
        } else if (state is Victory) {
          return const Center(child: Text('🎉 Has ganado', style: TextStyle(color: Colors.white)));
        } else {
          return const Center(
            child: CircularProgressIndicator(color: Colors.greenAccent),
          );
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