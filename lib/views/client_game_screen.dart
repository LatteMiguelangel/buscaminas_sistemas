import 'package:buscando_minas/views/game/home_screen.dart';
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

  // Para procesar un solo endGame
  NetEvent? _lastEndEvent;

  @override
  void initState() {
    super.initState();

    widget.clientManager.onEvent = (NetEvent evt) {
      // 1) Si viene endGame del host
      if (evt.type == NetEventType.endGame && _lastEndEvent == null) {
        _lastEndEvent = evt;
        final winner = evt.data['winnerId'] as String;
        final clientWon = winner == 'client';
        _showEndDialog(clientWon);
        return;
      }

      // 2) Eventos normales
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
          // Capturamos el primer estado Playing
          _bloc.stream.firstWhere((s) => s is Playing).then((s) {
            final p = s as Playing;
            _prevCells = List<Cell>.from(p.cells);
            setState(() => _initialized = true);
          });
          break;

        case NetEventType.stateUpdate:
          final data = evt.data;
          final currentState = _bloc.state;
          if (currentState is Playing) {
            final updated = List<Cell>.from(currentState.cells);
            for (var cj in data['cells'] as List<dynamic>) {
              final cell = CellSerialization.fromJson(
                Map<String, dynamic>.from(cj as Map),
              );
              updated[cell.index] = cell;
            }
            _bloc.add(SetPlayingState(
              Playing(
                configuration: currentState.gameConfiguration,
                cells: updated,
                flagsRemaining: data['flagsRemaining'] as int,
                elapsedSeconds: data['elapsedSeconds'] as int,
                currentPlayerId: data['currentPlayerId'] as String,
              ),
            ));
          }
          break;

        case NetEventType.revealTile:
          _bloc.add(TapCell(
            evt.data['index'] as int,
            evt.data['playerId'] as String,
          ));
          break;

        case NetEventType.flagTile:
          _bloc.add(ToggleFlag(
            index: evt.data['index'] as int,
            playerId: evt.data['playerId'] as String,
          ));
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
          // 3) Si el cliente termina localmente, avisamos al host
          if ((state is GameOver || state is Victory) && _lastEndEvent == null) {
            final clientWon = state is Victory;
            _lastEndEvent = NetEvent(
              type: NetEventType.endGame,
              data: {'winnerId': clientWon ? 'client' : 'host'},
            );
            widget.clientManager.send(_lastEndEvent!.toJson());
            _showEndDialog(clientWon);
            return;
          }

          // 4) Difusión de diffs tras jugada propia
          if (state is Playing) {
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

  void _showEndDialog(bool won) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black87,
        title: Text(
          won ? '🎉 ¡Ganaste!' : '💥 Has perdido',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => HomeScreen()),
              );
            },
            child: const Text(
              'Volver a jugar',
              style: TextStyle(color: Colors.greenAccent),
            ),
          ),
        ],
      ),
    );
  }
}
