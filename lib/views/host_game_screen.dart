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
  List<Cell> _prevCells = [];

  @override
  void initState() {
    super.initState();
    widget.hostManager.onEvent = (evt) {
      switch (evt.type) {
        case NetEventType.revealTile:
          widget.bloc.add(TapCell(evt.data['index'] as int));
          break;
        case NetEventType.flagTile:
          widget.bloc.add(ToggleFlag(evt.data['index'] as int));
          break;
        case NetEventType.stateUpdate:
          // El cliente nos envía diffs
          final data = evt.data;
          final cellsJson = data['cells'] as List<dynamic>;
          final currentState = widget.bloc.state;
          if (currentState is Playing) {
            final updatedCells = List<Cell>.from(currentState.cells);
            for (var cj in cellsJson) {
              final cell = CellSerialization.fromJson(
                  Map<String, dynamic>.from(cj as Map));
              updatedCells[cell.index] = cell;
            }
            final newPlaying = Playing(
              configuration: currentState.gameConfiguration,
              cells: updatedCells,
              flagsRemaining: data['flagsRemaining'] as int,
              elapsedSeconds: data['elapsedSeconds'] as int,
              currentPlayerId: data['currentPlayerId'] as String,
            );
            widget.bloc.add(SetPlayingState(newPlaying));
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
            if (_prevCells.isEmpty) {
              _prevCells = List.from(newCells);
              return;
            }
            final diffs = <Map<String, dynamic>>[];
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
              _prevCells = List.from(newCells);
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
