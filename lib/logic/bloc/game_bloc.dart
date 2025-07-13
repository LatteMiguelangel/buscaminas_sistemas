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
  void _togglePlayer() {
    _currentPlayerId = _currentPlayerId == 'host' ? 'client' : 'host';
  }

  GameBloc(this.configuration) : super(GameInitial(configuration)) {
    on<InitializeGame>((event, emit) {
      final cells = generateBoard(configuration, seed: event.seed);
      flagsPlaced = 0;
      _elapsedSeconds = 0;
      _currentPlayerId = 'host';
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (state is Playing) {
          _elapsedSeconds++;
          final current = state as Playing;
          emit(
            Playing(
              configuration: configuration,
              cells: current.cells,
              flagsRemaining: configuration.numberOfBombs - flagsPlaced,
              elapsedSeconds: _elapsedSeconds,
              currentPlayerId: _currentPlayerId,
            ),
          );
        }
      });

      emit(
        Playing(
          configuration: configuration,
          cells: cells,
          flagsRemaining: configuration.numberOfBombs,
          elapsedSeconds: _elapsedSeconds,
          currentPlayerId: _currentPlayerId,
        ),
      );

      _timer?.cancel();
      _elapsedSeconds = 0;

      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        _elapsedSeconds++;
        if (state is Playing) {
          add(UpdateTime());
        }
      });
    });

    on<TapCell>(_onTapCell);
    on<ToggleFlag>(_onToggleFlag);
    on<UpdateTime>((event, emit) {
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
    final state = this.state;
    if (state is! Playing) return;

    final tappedIndex = event.index;
    final cells = [...state.cells];
    final tappedCell = cells[tappedIndex];

    if (tappedCell is! CellClosed || tappedCell.flagged) return;

    if (tappedCell.content == CellContent.bomb) {
      for (int i = 0; i < cells.length; i++) {
        if (cells[i] is CellClosed &&
            (cells[i] as CellClosed).content == CellContent.bomb) {
          _timer?.cancel();
          cells[i] = CellOpened(index: i, content: CellContent.bomb);
        }
      }
      _togglePlayer();
      emit(GameOver(configuration: configuration, cells: cells, won: false));
      return;
    }

    _revealCellsRecursively(
      cells,
      tappedIndex,
      configuration.width,
      configuration.height,
    );

    emit(
      Playing(
        configuration: configuration,
        cells: cells,
        flagsRemaining: configuration.numberOfBombs - flagsPlaced,
        elapsedSeconds: _elapsedSeconds,
        currentPlayerId: _currentPlayerId,
      ),
    );
  }

  void _onToggleFlag(ToggleFlag event, Emitter<GameState> emit) {
    final state = this.state;
    if (state is! Playing) return;

    final index = event.index;
    final cell = state.cells[index];

    if (cell is! CellClosed) return;

    if (!cell.flagged && flagsPlaced >= configuration.numberOfBombs) {
      return;
    }

    final updatedCell = cell.copyWith(flagged: !cell.flagged);
    final updatedCells = [...state.cells];
    updatedCells[index] = updatedCell;

    flagsPlaced += updatedCell.flagged ? 1 : -1;
    if (_checkWinCondition(updatedCells)) {
      _timer?.cancel();
      emit(Victory(state.gameConfiguration));
    } else {
      _togglePlayer();
      emit(
        Playing(
          configuration: state.gameConfiguration,
          cells: updatedCells,
          flagsRemaining: configuration.numberOfBombs - flagsPlaced,
          elapsedSeconds: _elapsedSeconds,
          currentPlayerId: _currentPlayerId,
        ),
      );
    }
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
}
