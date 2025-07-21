import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:buscando_minas/logic/bloc/game_bloc.dart';
import 'package:buscando_minas/logic/model.dart';
import 'package:buscando_minas/logic/network/network_manager.dart';
import 'package:buscando_minas/logic/network/network_event.dart';
import 'package:buscando_minas/views/game_board.dart';

class ClientGameScreen extends StatefulWidget {
  final NetworkClient clientManager;
  const ClientGameScreen({super.key, required this.clientManager});

  @override
  State<ClientGameScreen> createState() => _ClientGameScreenState();
}

class _ClientGameScreenState extends State<ClientGameScreen> {
  late GameBloc _bloc;
  late GameConfiguration _config;
  final String _myPlayerId = 'client';
  bool _initialized = false;

  // Para calcular diffs locales tras cada jugada
  List<Cell> _prevCells = [];

  @override
  void initState() {
    super.initState();

    widget.clientManager.onEvent = (NetEvent evt) {
      switch (evt.type) {
        case NetEventType.gameStart:
          final d = evt.data;
          _config = GameConfiguration(
            width: d['width'] as int,
            height: d['height'] as int,
            numberOfBombs: d['numberOfBombs'] as int,
          );
          final seed = d['seed'] as int;
          _bloc = GameBloc(_config)..add(InitializeGame(seed: seed));
          setState(() => _initialized = true);
          break;

        case NetEventType.stateUpdate:
          // El host nos envía un diff: sólo celdas cambiadas
          final data = evt.data;
          final cellsJson = data['cells'] as List<dynamic>;
          final currentState = _bloc.state;
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
            _bloc.add(SetPlayingState(newPlaying));
          }
          break;

        default:
          break;
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.greenAccent),
        ),
      );
    }

    return BlocProvider.value(
      value: _bloc,
      child: BlocListener<GameBloc, GameState>(
        listener: (context, state) {
          if (state is Playing) {
            // Enviar sólo diffs tras nuestra jugada
            if (_prevCells.isEmpty) {
              _prevCells = List.from(state.cells);
              return;
            }
            final diffs = <Map<String, dynamic>>[];
            for (int i = 0; i < state.cells.length; i++) {
              if (state.cells[i] != _prevCells[i]) {
                diffs.add(state.cells[i].toJson());
              }
            }
            if (diffs.isNotEmpty) {
              widget.clientManager.send(
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
              _prevCells = List.from(state.cells);
            }
          }
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black54,
            title: const Center(child: Text('🔗 Cliente: Minesweeper')),
          ),
          body: GameBoard(
            isHost: false,
            myPlayerId: _myPlayerId,
            clientManager: widget.clientManager,
          ),
        ),
      ),
    );
  }
}
