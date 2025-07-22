import 'dart:async';
import 'dart:math';
import 'package:bloc/bloc.dart';
import 'package:buscando_minas/logic/model.dart';
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
  int flagsPlaced = 0;
  Timer? _timer;
  int _elapsedSeconds = 0;
  String _currentPlayerId = 'host';
  final Map<int, String> _flagOwners = {};
  final Map<String, int> _correctFlags = {'host': 0, 'client': 0};
  final Map<String, int> _cellsRevealed = {'host': 0, 'client': 0};
  void _togglePlayer() {
    _currentPlayerId = _currentPlayerId == 'host' ? 'client' : 'host';
    print('🔄 Cambio de turno a: $_currentPlayerId');
  }

  GameBloc(this.configuration) : super(GameInitial(configuration)) {
    on<InitializeGame>((event, emit) {
      final cells = generateBoard(configuration, seed: event.seed);
      flagsPlaced = 0;
      _elapsedSeconds = 0;
      _currentPlayerId = 'host';

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (isClosed || emit.isDone) return;
        add(UpdateTime());
      });

      emit(
        Playing(
          configuration: configuration,
          cells: cells,
          flagsRemaining: configuration.numberOfBombs - flagsPlaced,
          elapsedSeconds: _elapsedSeconds,
          currentPlayerId: _currentPlayerId,
        ),
      );
    });

    on<TapCell>(_onTapCell);
    on<ToggleFlag>(_onToggleFlag);
    on<UpdateTime>((event, emit) {
      _elapsedSeconds++;
      final currentState = state;
      if (currentState is Playing) {
        emit(
          Playing(
            configuration: configuration,
            cells: currentState.cells,
            flagsRemaining: configuration.numberOfBombs - flagsPlaced,
            elapsedSeconds: _elapsedSeconds,
            currentPlayerId: _currentPlayerId,
          ),
        );
      }
    });

    on<ReplaceState>((event, emit) {
      emit(event.newState);
    });

    on<SetPlayingState>((event, emit) {
      emit(event.playing);
    });
  }

  void _onTapCell(TapCell event, Emitter<GameState> emit) {
    // 1) Validación de turno
    if (event.playerId != _currentPlayerId) return;

    final currentState = state;
    if (currentState is! Playing) return;

    final tappedIndex = event.index;
    final oldCells = currentState.cells;
    final tappedCell = oldCells[tappedIndex];
    if (tappedCell is! CellClosed || tappedCell.flagged) return;

    final updatedCells = List<Cell>.from(oldCells);

    if (tappedCell.content == CellContent.bomb) {
      for (int i = 0; i < updatedCells.length; i++) {
        final cell = updatedCells[i];
        if (cell is CellClosed && cell.content == CellContent.bomb) {
          updatedCells[i] = CellOpened(index: i, content: CellContent.bomb);
        }
      }
      _timer?.cancel();
      emit(
        GameOver(configuration: configuration, cells: updatedCells, won: false),
      );
      return;
    }

    final before = updatedCells.whereType<CellOpened>().length;
    _revealCellsRecursively(
      updatedCells,
      tappedIndex,
      configuration.width,
      configuration.height,
    );
    final after = updatedCells.whereType<CellOpened>().length;

    //  Actualizamos el contador de forma segura:
    final prevCount = _cellsRevealed[event.playerId] ?? 0;
    _cellsRevealed[event.playerId] = prevCount + (after - before);

    _togglePlayer(); //change

    emit(
      Playing(
        configuration: configuration,
        cells: updatedCells,
        flagsRemaining: configuration.numberOfBombs - flagsPlaced,
        elapsedSeconds: _elapsedSeconds,
        currentPlayerId: _currentPlayerId,
      ),
    );
  }

  void _onToggleFlag(ToggleFlag event, Emitter<GameState> emit) {
    if (event.playerId != _currentPlayerId) return;

    final currentState = state;
    if (currentState is! Playing) return;

    final index = event.index;
    final cell = currentState.cells[index];
    if (cell is! CellClosed) return;

    final wasFlagged = cell.flagged;

    if (wasFlagged) {
      if (_flagOwners[index] != event.playerId) {
        return;
      }
    } else {
      if (flagsPlaced >= configuration.numberOfBombs) {
        return;
      }
    }

    final newFlagged = !wasFlagged;
    if (newFlagged) {
      flagsPlaced++;
      _flagOwners[index] = event.playerId;
    } else {
      flagsPlaced--;
      _flagOwners.remove(index);
    }

    // Si acaba de colocar (newFlagged==true) sobre bomba, sumamos correcto
    if (newFlagged && (cell.content == CellContent.bomb)) {
      _correctFlags[event.playerId] = _correctFlags[event.playerId]! + 1;
    }
    // Si acaba de quitar bandera de bomba, restamos
    if (!newFlagged && (cell.content == CellContent.bomb)) {
      _correctFlags[event.playerId] = _correctFlags[event.playerId]! - 1;
    }

    final updatedCells = List<Cell>.from(currentState.cells);
    updatedCells[index] = (cell).copyWith(flagged: newFlagged);

    if (flagsPlaced == configuration.numberOfBombs) {
      // 1) Desempate por banderas correctas
      final hostFlags = _correctFlags['host']!;
      final clientFlags = _correctFlags['client']!;
      String winner =
          hostFlags != clientFlags
              ? (hostFlags > clientFlags ? 'host' : 'client')
              : // 2) desempate por celdas reveladas
              (_cellsRevealed['host']! > _cellsRevealed['client']!
                  ? 'host'
                  : 'client');
      _timer?.cancel();
      emit(
        GameResult(
          configuration: configuration,
          winnerId: winner,
          cellsRevealed: Map.from(_cellsRevealed),
          correctFlags: Map.from(_correctFlags),
        ),
      );
      return; // salimos, no llegamos al emit de Playing
    }
    emit(
      Playing(
        configuration: configuration,
        cells: updatedCells,
        flagsRemaining: configuration.numberOfBombs - flagsPlaced,
        elapsedSeconds: _elapsedSeconds,
        currentPlayerId: _currentPlayerId,
      ),
    );
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
}
