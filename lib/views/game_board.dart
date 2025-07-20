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
        // Debug debugPrint para ver el rebuild y estado
        debugPrint('🔄 GameBoard rebuild con estado: ${state.runtimeType}');

        if (state is Playing) {
          // Si no es tu turno, bloqueamos interacciones (absorb pointer + opacidad)
          final locked = state.currentPlayerId != myPlayerId;
          debugPrint(
            '🔒 GameBoard: currentPlayerId=${state.currentPlayerId} | '
            'myPlayerId=$myPlayerId → locked=$locked',
          );

          final config = state.gameConfiguration!;
          final width = config.width;
          final height = config.height;

          return Column(
            children: [
              // Barra superior con info de flags, turno y tiempo
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

              // Tablero en sí
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
                                      // Host maneja la lógica local y emite evento BLoC
                                      context.read<GameBloc>().add(
                                        TapCell(index),
                                      );
                                      return;
                                    }
                                    // Cliente envía evento al host via NetworkClient
                                    debugPrint(
                                      '🖱 Cliente: tap en índice $index',
                                    );
                                    if (!locked && clientManager != null) {
                                      clientManager?.send(
                                        Event(
                                          type: EventType.open,
                                          data: {'index': index},
                                        ),
                                      );
                                    }
                                    debugPrint(
                                      '📤 Cliente envía open: ${Event(type: EventType.open, data: {'index': index}).toJsonString().trim()}',
                                    );
                                  },
                                  onLongPress: () {
                                    debugPrint('$isHost');
                                    if (isHost) {
                                      // Host maneja toggle bandera local
                                      debugPrint(
                                        '🖱 Host: longPress en índice $index',
                                      );
                                      context.read<GameBloc>().add(
                                        ToggleFlag(index),
                                      );
                                      return;
                                    }
                                    // Cliente envía toggle flag al host
                                    debugPrint(
                                      '🖱 Cliente: intentando enviar flagTile para index=$index',
                                    );
                                    final ev = Event<FlagTileData>(
                                      type: EventType.flagTile,
                                      data: FlagTileData(index: index),
                                    );
                                    clientManager!.send(ev);
                                    debugPrint(
                                      '✅ Cliente: flagTile($index) enviado',
                                    );
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
