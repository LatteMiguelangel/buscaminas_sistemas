// lib/views/client_game_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:buscando_minas/logic/bloc/game_bloc.dart';
import 'package:buscando_minas/logic/model.dart';
import 'package:buscando_minas/logic/network/proxy_client.dart';
import 'package:buscando_minas/logic/network/network_event.dart';
import 'package:buscando_minas/views/game/cell_view.dart';

class ClientGameScreen extends StatefulWidget {
  /// Cliente proxy que habla con el servidor-relé.
  final ProxyClient client;

  const ClientGameScreen({
    super.key,
    required this.client,
  });

  @override
  State<ClientGameScreen> createState() => _ClientGameScreenState();
}

class _ClientGameScreenState extends State<ClientGameScreen> {
  late final StreamSubscription<Event<dynamic>> _subscription;
  late GameBloc _bloc;
  late GameConfiguration _config;
  bool _initialized = false;
  final String _myPlayerId = 'client';

  @override
  void initState() {
    super.initState();
    // Nos suscribimos al stream de eventos del proxy
    _subscription = widget.client.events.listen(_handleEvent);
  }

  void _handleEvent(Event<dynamic> event) {
    debugPrint('📥 Cliente recibió evento: ${event.type}');
    switch (event.type) {
      case EventType.gameStart:
        final data = event.data as GameStartData;
        _config = GameConfiguration(
          width: data.width,
          height: data.height,
          numberOfBombs: data.numberOfBombs,
        );
        final seed = data.seed;
        _bloc = GameBloc(_config, enableTimer: false)
          ..add(InitializeGame(seed: seed));
        setState(() => _initialized = true);
        break;

      case EventType.cellUpdate:
        final data = event.data as CellUpdateData;
        _bloc.add(ApplyCellUpdates(data.updates));
        break;

      default:
        // Ignoramos otros eventos
        break;
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    widget.client.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      // Esperamos a recibir gameStart para inicializar
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.greenAccent),
        ),
      );
    }

    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black87,
          title: const Center(child: Text('Cliente: Buscaminas')),
        ),
        body: BlocBuilder<GameBloc, GameState>(
          builder: (context, state) {
            if (state is! Playing) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.greenAccent),
              );
            }

            final locked = state.currentPlayerId != _myPlayerId;
            final config = state.gameConfiguration!;
            final width = config.width;
            final height = config.height;

            return Column(
              children: [
                // Barra superior con flags, turno y tiempo
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('🚩 ${state.flagsRemaining}',
                          style: const TextStyle(color: Colors.white)),
                      Text(
                        locked ? '⚪ Turno oponente' : '⬢ Tu turno',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text('⏱ ${_formatTime(state.elapsedSeconds)}',
                          style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                ),

                // Tablero
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
                                padding: const EdgeInsets.all(2),
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: width,
                                  crossAxisSpacing: 1,
                                  mainAxisSpacing: 1,
                                  childAspectRatio: width / height,
                                ),
                                itemCount: state.cells.length,
                                itemBuilder: (context, index) {
                                  return GestureDetector(
                                    onTap: () {
                                      if (!locked) {
                                        debugPrint(
                                            '🖱 Cliente enviando OPEN index=$index');
                                        widget.client.send(
                                          Event<RevealTileData>(
                                            type: EventType.open,
                                            data: RevealTileData(index: index),
                                          ),
                                        );
                                      }
                                    },
                                    onLongPress: () {
                                      if (!locked) {
                                        debugPrint(
                                            '🖱 Cliente enviando FLAG index=$index');
                                        widget.client.send(
                                          Event<FlagTileData>(
                                            type: EventType.flagTile,
                                            data: FlagTileData(index: index),
                                          ),
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
          },
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${secs.toString().padLeft(2, '0')}';
  }
}