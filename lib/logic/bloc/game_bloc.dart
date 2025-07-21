// lib/logic/bloc/game_bloc.dart

import 'dart:async';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:buscando_minas/logic/model.dart';
import 'package:buscando_minas/logic/network/network_event.dart'; // ← para CellJson
import 'package:equatable/equatable.dart';

part 'game_event.dart';
part 'game_state.dart';

List<Cell> generateBoard(GameConfiguration config, {int? seed}) {
  final rand = seed != null ? Random(seed) : Random();
  int width = config.width;
  int height = config.height;
  int total = width * height;

  List<int> bombIndexes = List.generate(total, (i) => i)..shuffle(rand);
  bombIndexes = bombIndexes.sublist(0, config.numberOfBombs);

  List<Cell> cells = List.generate(total, (i) {
    return CellClosed(index: i, content: CellContent.zero);
  });

  for (var i in bombIndexes) {
    cells[i] = CellClosed(index: i, content: CellContent.bomb);
  }

  for (int i = 0; i < total; i++) {
    if (cells[i].content == CellContent.bomb) continue;

    int bombCount = 0;
    int x = i % width;
    int y = i ~/ width;

    for (int dx = -1; dx <= 1; dx++) {
      for (int dy = -1; dy <= 1; dy++) {
        if (dx == 0 && dy == 0) continue;
        int nx = x + dx;
        int ny = y + dy;
        if (nx >= 0 && nx < width && ny >= 0 && ny < height) {
          int ni = ny * width + nx;
          if (cells[ni].content == CellContent.bomb) {
            bombCount++;
          }
        }
      }
    }
    cells[i] = CellClosed(index: i, content: CellContent.values[bombCount]);
  }
  return cells;
}

class GameBloc extends Bloc<GameEvent, GameState> {
  final GameConfiguration configuration;
  final bool enableTimer;
  int flagsPlaced = 0;
  Timer? _timer;
  int _elapsedSeconds = 0;
  String _currentPlayerId = 'host';

  /// Callback que el HostGameScreen usa para emitir diffs.
  void Function(Playing)? onStateUpdated;

  GameBloc(this.configuration, {this.enableTimer = true})
    : super(GameInitial(configuration)) {
    on<InitializeGame>(_onInitializeGame);
    on<TapCell>(_onTapCell);
    on<ToggleFlag>(_onToggleFlag);
    on<UpdateTime>(_onUpdateTime);
    on<ReplaceState>(_onReplaceState);
    on<SetPlayingState>(_onSetPlayingState);
    on<ApplyCellUpdates>(_onApplyCellUpdates);
  }

  void _onInitializeGame(InitializeGame event, Emitter<GameState> emit) {
    final cells = generateBoard(configuration, seed: event.seed);
    flagsPlaced = 0;
    _elapsedSeconds = 0;
    _currentPlayerId = 'host';
    _timer?.cancel();
    final newState = Playing(
      configuration: configuration,
      cells: cells,
      flagsRemaining: configuration.numberOfBombs,
      elapsedSeconds: _elapsedSeconds,
      currentPlayerId: _currentPlayerId,
    );
    emit(newState);
    onStateUpdated?.call(newState);
    _timer?.cancel();
    _elapsedSeconds = 0;
    if (enableTimer) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        _elapsedSeconds++;
        if (state is Playing) add(UpdateTime());
      });
    }
  }

  void _onUpdateTime(UpdateTime event, Emitter<GameState> emit) {
    if (!enableTimer) return;
    final currentState = state;
    if (currentState is Playing) {
      final newState = Playing(
        configuration: configuration,
        cells: currentState.cells,
        flagsRemaining: configuration.numberOfBombs - flagsPlaced,
        elapsedSeconds: _elapsedSeconds,
        currentPlayerId: currentState.currentPlayerId,
      );
      emit(newState);
    }
  }

  void _onTapCell(TapCell event, Emitter<GameState> emit) {
    final state = this.state;
    if (state is! Playing) return;
    if (state.currentPlayerId != _currentPlayerId) return;

    final tappedIndex = event.index;
    final cells = [...state.cells];
    final tappedCell = cells[tappedIndex];

    if (tappedCell is! CellClosed || tappedCell.flagged) return;

    if (tappedCell.content == CellContent.bomb) {
      for (int i = 0; i < cells.length; i++) {
        if (cells[i] is CellClosed &&
            (cells[i] as CellClosed).content == CellContent.bomb) {
          cells[i] = CellOpened(index: i, content: CellContent.bomb);
        }
      }
      _togglePlayer();
      emit(GameOver(configuration: configuration, cells: cells, won: false));
      onStateUpdated?.call(state);
      return;
    }

    _revealCellsRecursively(
      cells,
      tappedIndex,
      configuration.width,
      configuration.height,
    );
    _togglePlayer();

    final newState = Playing(
      configuration: configuration,
      cells: cells,
      flagsRemaining: configuration.numberOfBombs - flagsPlaced,
      elapsedSeconds: _elapsedSeconds,
      currentPlayerId: _currentPlayerId,
    );
    emit(newState);
    onStateUpdated?.call(newState);
  }

  void _onToggleFlag(ToggleFlag event, Emitter<GameState> emit) {
    final state = this.state;
    if (state is! Playing) return;
    if (state.currentPlayerId != _currentPlayerId) return;

    final index = event.index;
    final cell = state.cells[index] as CellClosed;
    if (cell.flagged == false && flagsPlaced >= configuration.numberOfBombs) {
      return;
    }

    final updatedCell = cell.copyWith(flagged: !cell.flagged);
    final updatedCells = [...state.cells]..[index] = updatedCell;
    flagsPlaced += updatedCell.flagged ? 1 : -1;

    if (_checkWinCondition(updatedCells)) {
      _timer?.cancel();
      emit(Victory(configuration));
      onStateUpdated?.call(state);
    } else {
      _togglePlayer();
      final newState = Playing(
        configuration: configuration,
        cells: updatedCells,
        flagsRemaining: configuration.numberOfBombs - flagsPlaced,
        elapsedSeconds: _elapsedSeconds,
        currentPlayerId: _currentPlayerId,
      );
      emit(newState);
      onStateUpdated?.call(newState);
    }
  }

  void _onReplaceState(ReplaceState event, Emitter<GameState> emit) {
    emit(event.newState);
  }

  void _onSetPlayingState(SetPlayingState event, Emitter<GameState> emit) {
    final playing = event.playing;
    _elapsedSeconds = playing.elapsedSeconds;
    _currentPlayerId = playing.currentPlayerId;
    flagsPlaced =
        playing.cells.where((c) => c is CellClosed && (c).flagged).length;
    emit(playing);
  }

  void _onApplyCellUpdates(ApplyCellUpdates event, Emitter<GameState> emit) {
    final current = state;
    if (current is! Playing) return;

    // 1) Reconstruir lista de celdas aplicando cada delta
    final updatedCells = List<Cell>.from(current.cells);
    for (final upd in event.updates) {
      final content = CellContent.values[upd.content];
      final idx = upd.index;

      if (upd.opened) {
        updatedCells[idx] = CellOpened(index: idx, content: content);
      } else {
        updatedCells[idx] = CellClosed(
          index: idx,
          content: content,
          flagged: upd.flagged,
        );
      }
    }

    // 2) Recalcular flags restantes
    final newFlagsPlaced =
        updatedCells.whereType<CellClosed>().where((c) => c.flagged).length;

    // 3) Actualizar tu variable interna de quién tiene el turno ahora
    _currentPlayerId = event.nextPlayerId;

    // 4) Emitir el nuevo estado con el turno correcto
    final newState = Playing(
      configuration: current.gameConfiguration!,
      cells: updatedCells,
      flagsRemaining: current.gameConfiguration!.numberOfBombs - newFlagsPlaced,
      elapsedSeconds: current.elapsedSeconds,
      currentPlayerId: event.nextPlayerId,
    );

    emit(newState);
  }

  void _revealCellsRecursively(
    List<Cell> cells,
    int index,
    int width,
    int height,
  ) {
    if (index < 0 || index >= cells.length) return;
    if (cells[index] is CellOpened) return;

    final current = cells[index] as CellClosed;
    if (current.flagged || current.content == CellContent.bomb) return;

    cells[index] = CellOpened(index: index, content: current.content);

    if (current.content == CellContent.zero) {
      int x = index % width;
      int y = index ~/ width;

      for (int dx = -1; dx <= 1; dx++) {
        for (int dy = -1; dy <= 1; dy++) {
          if (dx == 0 && dy == 0) continue;
          int nx = x + dx;
          int ny = y + dy;
          if (nx >= 0 && nx < width && ny >= 0 && ny < height) {
            int ni = ny * width + nx;
            _revealCellsRecursively(cells, ni, width, height);
          }
        }
      }
    }
  }

  bool _checkWinCondition(List<Cell> cells) {
    final flagged =
        cells.where((cell) => cell is CellClosed && cell.flagged).toList();
    if (flagged.length != configuration.numberOfBombs) return false;
    for (var cell in flagged) {
      if (!cell.hasBomb) return false;
    }
    return true;
  }

  void _togglePlayer() {
    _currentPlayerId = _currentPlayerId == 'host' ? 'client' : 'host';
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
