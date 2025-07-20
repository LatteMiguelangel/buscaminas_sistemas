// lib/views/host_game_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:buscando_minas/logic/bloc/game_bloc.dart';
import 'package:buscando_minas/logic/model.dart';
import 'package:buscando_minas/logic/network/proxy_client.dart';
import 'package:buscando_minas/logic/network/network_event.dart';
import 'package:buscando_minas/views/game/cell_view.dart';

class HostGameScreen extends StatefulWidget {
  final GameBloc bloc;
  final ProxyClient hostManager;

  const HostGameScreen({
    Key? key,
    required this.bloc,
    required this.hostManager,
  }) : super(key: key);

  @override
  State<HostGameScreen> createState() => _HostGameScreenState();
}

class _HostGameScreenState extends State<HostGameScreen> {
  late final StreamSubscription<Event<dynamic>> _subscription;
  List<Cell>? _previousCells;

  @override
  void initState() {
    super.initState();

    // 1) Escuchar jugadas del cliente
    _subscription = widget.hostManager.events.listen(_onClientEvent);

    // 2) Enviar solo diffs (cellUpdate) en lugar de stateUpdate
    widget.bloc.onStateUpdated = (Playing newState) {
      final diffs = <CellJson>[];
      final cells = newState.cells;

      if (_previousCells == null) {
        for (final cell in cells) {
          final opened = cell is CellOpened;
          final flagged = cell is CellClosed && cell.flagged;
          if (opened || flagged) {
            diffs.add(CellJson(
              index: cell.index,
              content: cell.content.index,
              flagged: flagged,
              opened: opened,
            ));
          }
        }
      } else {
        for (var i = 0; i < cells.length; i++) {
          final oldCell = _previousCells![i];
          final newCell = cells[i];

          final opened = newCell is CellOpened;
          final flagged = newCell is CellClosed && newCell.flagged;
          final oldOpened = oldCell is CellOpened;
          final oldFlagged = oldCell is CellClosed && (oldCell as CellClosed).flagged;

          if (opened != oldOpened || flagged != oldFlagged) {
            diffs.add(CellJson(
              index: newCell.index,
              content: newCell.content.index,
              flagged: flagged,
              opened: opened,
            ));
          }
        }
      }

      // Actualizar snapshot
      _previousCells = List<Cell>.from(cells);

      // Enviar delta
      final evt = Event<CellUpdateData>(
        type: EventType.cellUpdate,
        data: CellUpdateData(diffs),
      );
      widget.hostManager.send(evt);
      debugPrint('📤 Host envía cellUpdate: ${evt.toJsonString().trim()}');
    };
  }

  void _onClientEvent(Event<dynamic> event) {
    final state = widget.bloc.state;
    if (state is! Playing || state.currentPlayerId != 'client') {
      debugPrint('🚫 Ignorado: fuera de turno o estado incorrecto');
      return;
    }
    switch (event.type) {
      case EventType.open:
        widget.bloc.add(TapCell((event.data as RevealTileData).index));
        break;
      case EventType.flagTile:
        widget.bloc.add(ToggleFlag((event.data as FlagTileData).index));
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    widget.hostManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.bloc,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black87,
          title: const Center(child: Text('Host: Buscaminas')),
        ),
        body: BlocBuilder<GameBloc, GameState>(
          builder: (context, state) {
            if (state is! Playing) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.greenAccent),
              );
            }

            final locked = state.currentPlayerId != 'host';
            final config = state.gameConfiguration!;
            final width = config.width;
            final height = config.height;

            return Column(
              children: [
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
                                        widget.bloc.add(TapCell(index));
                                      }
                                    },
                                    onLongPress: () {
                                      if (!locked) {
                                        widget.bloc.add(ToggleFlag(index));
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
