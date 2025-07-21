import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:buscando_minas/logic/bloc/game_bloc.dart';
import 'package:buscando_minas/logic/model.dart';
import 'package:buscando_minas/logic/network/network_manager.dart';
import 'package:buscando_minas/logic/network/network_event.dart';
import 'package:buscando_minas/views/game_board.dart';

class HostGameScreen extends StatefulWidget {
  final GameBloc bloc;
  final NetworkHost hostManager;

  const HostGameScreen({
    super.key,
    required this.bloc,
    required this.hostManager,
  });

  @override
  State<HostGameScreen> createState() => _HostGameScreenState();
}

class _HostGameScreenState extends State<HostGameScreen> {
  late List<Cell> _prevCells;

  @override
  void initState() {
    super.initState();

    // 1) Si el estado ya es Playing (muy probable), inicializamos _prevCells al instante.
    final current = widget.bloc.state;
    if (current is Playing) {
      _prevCells = List<Cell>.from(current.cells);
    } else {
      // 2) Si aún no está, nos suscribimos para cuando llegue el primer Playing.
      widget.bloc.stream
        .firstWhere((s) => s is Playing)
        .then((s) {
          final p = s as Playing;
          _prevCells = List<Cell>.from(p.cells);
        });
    }

    // Escucha jugadas y diffs entrantes del cliente
    widget.hostManager.onEvent = (evt) {
      switch (evt.type) {
        case NetEventType.revealTile:
          widget.bloc.add(TapCell(evt.data['index'] as int));
          break;
        case NetEventType.flagTile:
          widget.bloc.add(ToggleFlag(evt.data['index'] as int));
          break;
        case NetEventType.stateUpdate:
          final data = evt.data;
          final List<dynamic> cellsJson = data['cells'] as List<dynamic>;
          final state = widget.bloc.state;
          if (state is Playing) {
            final updated = List<Cell>.from(state.cells);
            for (var cj in cellsJson) {
              final cell = CellSerialization.fromJson(
                Map<String, dynamic>.from(cj as Map),
              );
              updated[cell.index] = cell;
            }
            widget.bloc.add(SetPlayingState(
              Playing(
                configuration: state.gameConfiguration,
                cells: updated,
                flagsRemaining: data['flagsRemaining'] as int,
                elapsedSeconds: data['elapsedSeconds'] as int,
                currentPlayerId: data['currentPlayerId'] as String,
              ),
            ));
          }
          break;
        default:
          break;
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.bloc,
      child: BlocListener<GameBloc, GameState>(
        listener: (context, state) {
          if (state is Playing) {
            final newCells = state.cells;
            final diffs = <Map<String, dynamic>>[];

            // 3) Comparamos siempre contra _prevCells, que ya está inicializada.
            for (int i = 0; i < newCells.length; i++) {
              if (newCells[i] != _prevCells[i]) {
                diffs.add(newCells[i].toJson());
              }
            }

            if (diffs.isNotEmpty) {
              widget.hostManager.send(
                NetEvent(
                  type: NetEventType.stateUpdate,
                  data: {
                    'cells': diffs,
                    'flagsRemaining': state.flagsRemaining,
                    'elapsedSeconds': state.elapsedSeconds,
                    'currentPlayerId': state.currentPlayerId,
                  },
                ).toJson(),
              );
              _prevCells = List<Cell>.from(newCells);
            }
          }
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black54,
            title: const Center(child: Text('Host: Minesweeper')),
          ),
          body: GameBoard(
            isHost: true,
            myPlayerId: 'host',
          ),
        ),
      ),
    );
  }
}