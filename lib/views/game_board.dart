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
          final config = state.gameConfiguration!;
          final width = config.width;
          final height = config.height;
          print('🎯 Cliente recibió tablero: celda[0] = ${state.cells[0].content}');

          // Bloqueo unificado: solo puedo jugar si currentPlayerId == myPlayerId
          final locked = state.currentPlayerId != myPlayerId;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Contador de banderas
                    Text("🚩 ${state.flagsRemaining}"),
                    // Indicador de turno
                    Text(
                      state.currentPlayerId == myPlayerId
                          ? "⬢ Tu turno"
                          : "⚪ Turno oponente",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    // Temporizador
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
                              onTap: () {
                                // Solo si no está bloqueado
                                if (locked) return;

                                if (isHost) {
                                  // Jugador host hace jugada local
                                  context.read<GameBloc>().add(TapCell(index));
                                } else {
                                  // Cliente envía evento revealTile
                                  print('📤 Cliente envía revealTile: $index');
                                  print('🛫 [CLIENTE] Enviando revealTile index=$index');
                                  final ev = Event<RevealTileData>(
                                    type: EventType.revealTile,
                                    data: RevealTileData(index: index),
                                  );
                                  clientManager!.send(ev);
                                }
                              },
                              onLongPress: () {
                                // Solo si no está bloqueado
                                if (locked) return;

                                if (isHost) {
                                  // Jugador host pone/quita bandera local
                                  context.read<GameBloc>().add(ToggleFlag(index));
                                } else {
                                  // Cliente envía evento flagTile
                                  print('📤 Cliente envía flagTile: $index');
                                  print('🛫 [CLIENTE] Enviando flagTile index=$index');
                                  final ev = Event<FlagTileData>(
                                    type: EventType.flagTile,
                                    data: FlagTileData(index: index),
                                  );
                                  clientManager!.send(ev);
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
          return const Center(child: Text('💥 Has perdido'));
        } else if (state is Victory) {
          return const Center(child: Text('🎉 Has ganado'));
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
