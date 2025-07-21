// game_board.dart
import 'package:buscando_minas/logic/network/network_event.dart';
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
          final config = state.gameConfiguration!;
          final width = config.width;
          final height = config.height;

          // Bloquea la UI si no es tu turno
          final locked = state.currentPlayerId != myPlayerId;

          return Column(
            children: [
              // Contadores de banderas y tiempo
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
              // Indicador de turno
              Text(
                "🎮 Turno de: ${state.currentPlayerId}",
                style: const TextStyle(color: Colors.white),
              ),
              // Tablero
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
                                  // Host ejecuta localmente el TapCell con su playerId
                                  context
                                      .read<GameBloc>()
                                      .add(TapCell(index, myPlayerId));
                                } else if (clientManager != null) {
                                  // Cliente envía petición de reveal al host
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
                                  // Host ejecuta ToggleFlag localmente
                                  context
                                      .read<GameBloc>()
                                      .add(ToggleFlag(index: index, playerId: myPlayerId));
                                } else if (clientManager != null) {
                                  // Cliente envía petición de flag al host
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
        } else if (state is GameOver) {
          return const Center(
            child: Text(
              '💥 Has perdido',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          );
        } else if (state is Victory) {
          return const Center(
            child: Text(
              '🎉 Has ganado',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          );
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