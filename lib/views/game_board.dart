// views/game_board.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:buscando_minas/logic/bloc/game_bloc.dart';
import 'package:buscando_minas/views/game/cell_view.dart';
import 'package:buscando_minas/logic/network/network_manager.dart';
import 'package:buscando_minas/logic/network/network_event.dart';

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
          final locked = state.currentPlayerId != myPlayerId;
          print(
            '🔒 GameBoard: currentPlayerId=${state.currentPlayerId} | '
            'myPlayerId=$myPlayerId → locked=$locked',
          );
          final config = state.gameConfiguration!;
          final width = config.width;
          final height = config.height;

          return Column(
            children: [
              // Encabezado: banderas, turno y temporizador
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("🚩 ${state.flagsRemaining}"),
                    Text(
                      state.currentPlayerId == myPlayerId
                          ? "⬢ Tu turno"
                          : "⚪ Turno oponente",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text("⏱ ${_formatTime(state.elapsedSeconds)}"),
                  ],
                ),
              ),

              // Tablero de juego
              Expanded(
                child: AbsorbPointer(
                  absorbing: locked,
                  child: Opacity(
                    opacity: locked ? 0.6 : 1.0,
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
                                    if (isHost) {
                                      // Host hace jugada local
                                      print('🖱 Host: tap en índice $index');
                                      context.read<GameBloc>().add(
                                        TapCell(index),
                                      );
                                    } else {
                                      print('🖱 Cliente: tap en índice $index');

                                      // Jugada local en cliente (solo visualmente)
                                      context.read<GameBloc>().add(
                                        TapCell(index),
                                      );

                                      // Enviar al host para que lo procese oficialmente
                                      final event = Event<RevealTileData>(
                                        type: EventType.open,
                                        data: RevealTileData(index: index),
                                      );
                                      clientManager!.send(event);
                                      print(
                                        '📤 Cliente: envío jugada al host → index=$index',
                                      );
                                    }
                                  },
                                  onLongPress: () {
                                    if (isHost) {
                                      // Host pone/quita bandera local
                                      print(
                                        '🖱 Host: longPress en índice $index',
                                      );
                                      context.read<GameBloc>().add(
                                        ToggleFlag(index),
                                      );
                                    } else {
                                      // Cliente envía flagTile
                                      print(
                                        '🖱 Cliente: intentando enviar flagTile para index=$index',
                                      );
                                      final ev = Event<FlagTileData>(
                                        type: EventType.flagTile,
                                        data: FlagTileData(index: index),
                                      );
                                      clientManager!.send(ev);
                                      print(
                                        '✅ Cliente: flagTile($index) enviado',
                                      );
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
                ),
              ),
            ],
          );
        } else if (state is GameOver) {
          return const Center(
            child: Text(
              '💥 Has perdido',
              style: TextStyle(color: Colors.red, fontSize: 24),
            ),
          );
        } else if (state is Victory) {
          return const Center(
            child: Text(
              '🎉 ¡Has ganado!',
              style: TextStyle(color: Colors.greenAccent, fontSize: 24),
            ),
          );
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
