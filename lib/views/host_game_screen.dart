import 'package:buscando_minas/views/game/home_screen.dart';
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
  NetEvent? _lastEndEvent; // para evitar duplicados

  @override
  void initState() {
    super.initState();

    // Inicializar _prevCells
    final current = widget.bloc.state;
    if (current is Playing) {
      _prevCells = List<Cell>.from(current.cells);
    } else {
      widget.bloc.stream.firstWhere((s) => s is Playing).then((s) {
        _prevCells = List<Cell>.from((s as Playing).cells);
      });
    }

    // Escucha eventos de red
    widget.hostManager.onEvent = (evt) {
      // 1) Evento de fin de partida enviado por el cliente
      if (evt.type == NetEventType.endGame && _lastEndEvent == null) {
        _lastEndEvent = evt;
        final winner = evt.data['winnerId'] as String;
        final hostWon = winner == 'host';
        _showEndDialog(hostWon);
        return;
      }

      // 2) Jugadas normales
      switch (evt.type) {
        case NetEventType.revealTile:
          widget.bloc.add(
            TapCell(evt.data['index'] as int, evt.data['playerId'] as String),
          );
          break;
        case NetEventType.flagTile:
          widget.bloc.add(
            ToggleFlag(
              index: evt.data['index'] as int,
              playerId: evt.data['playerId'] as String,
            ),
          );
          break;
        case NetEventType.stateUpdate:
          final data = evt.data;
          final state = widget.bloc.state;
          if (state is Playing) {
            final updated = List<Cell>.from(state.cells);
            for (var cj in data['cells'] as List<dynamic>) {
              final cell = CellSerialization.fromJson(
                Map<String, dynamic>.from(cj as Map),
              );
              updated[cell.index] = cell;
            }
            widget.bloc.add(
              SetPlayingState(
                Playing(
                  configuration: state.gameConfiguration,
                  cells: updated,
                  flagsRemaining: data['flagsRemaining'] as int,
                  elapsedSeconds: data['elapsedSeconds'] as int,
                  currentPlayerId: data['currentPlayerId'] as String,
                ),
              ),
            );
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
          // Partida terminada (derrota o resultado por bandera)
          if (state is GameOver || state is GameResult) {
            final isVictory = state is GameResult && state.winnerId == 'host';

            // Enviar endGame solo una vez, con estadísticas
            if (_lastEndEvent == null) {
              // Recogemos estadísticas del BLoC
              final cellsRevealedMap = widget.bloc.cellsRevealedMap;
              final correctFlagsMap = widget.bloc.correctFlagsMap;

              final data = {
                'winnerId': isVictory ? 'host' : 'client',
                'cellsRevealed': cellsRevealedMap,
                'correctFlags': correctFlagsMap,
              };
              _lastEndEvent = NetEvent(type: NetEventType.endGame, data: data);
              widget.hostManager.send(_lastEndEvent!.toJson());
            }

            // Mostrar diálogo con estadísticas
            final cellsRevealed = widget.bloc.cellsRevealedMap['host']!;
            final opponentRevealed = widget.bloc.cellsRevealedMap['client']!;
            final correctFlags = widget.bloc.correctFlagsMap['host']!;
            final opponentFlags = widget.bloc.correctFlagsMap['client']!;

            _showStatsDialog(
              won: isVictory,
              cellsRevealed: cellsRevealed,
              opponentRevealed: opponentRevealed,
              correctFlags: correctFlags,
              opponentFlags: opponentFlags,
            );
            return;
          }

          // Estado en juego: enviar diffs
          if (state is Playing) {
            final newCells = state.cells;
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
          body: GameBoard(isHost: true, myPlayerId: 'host'),
        ),
      ),
    );
  }

  void _showEndDialog(bool won) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
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

  void _showStatsDialog({
    required bool won,
    required int cellsRevealed,
    required int opponentRevealed,
    required int correctFlags,
    required int opponentFlags,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            backgroundColor: Colors.black87,
            title: Text(
              won ? '🎉 ¡Ganaste!' : '💥 Has perdido',
              style: const TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Celdas reveladas:'),
                Text('  Tú: $cellsRevealed'),
                Text('  Rival: $opponentRevealed'),
                const SizedBox(height: 8),
                Text('Banderas correctas:'),
                Text('  Tú: $correctFlags'),
                Text('  Rival: $opponentFlags'),
              ],
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
