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
  final Map<int, String> _flagOwners = {}; // índice → jugador dueño
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

    // Bombazo?
    if (tappedCell.content == CellContent.bomb) {
      // Revelar todas las bombas
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

    // Revelado normal
    _revealCellsRecursively(
      updatedCells,
      tappedIndex,
      configuration.width,
      configuration.height,
    );

    // 2) Cambiamos turno
    _togglePlayer();

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
    // 1) Validación de turno (igual que tap)
    if (event.playerId != _currentPlayerId) return;

    final currentState = state;
    if (currentState is! Playing) return;

    final index = event.index;
    final cell = currentState.cells[index];
    if (cell is! CellClosed) return;

    final wasFlagged = cell.flagged;

    // 2) Si ya estaba marcada, solo el dueño puede quitarla
    if (wasFlagged) {
      if (_flagOwners[index] != event.playerId) {
        return; // otro jugador no puede desmarcar
      }
    }
    // 3) Si no estaba marcada, validar límite de banderas
    else {
      if (flagsPlaced >= configuration.numberOfBombs) {
        return; // no hay más banderas disponibles
      }
    }

    // 4) Toggle y actualizar flagsPlaced y dueños
    final newFlagged = !wasFlagged;
    if (newFlagged) {
      flagsPlaced++;
      _flagOwners[index] = event.playerId;
    } else {
      flagsPlaced--;
      _flagOwners.remove(index);
    }

    // 5) Construir nuevo estado de celdas
    final updatedCells = List<Cell>.from(currentState.cells);
    updatedCells[index] = (cell).copyWith(flagged: newFlagged);

    // 5.5) Comprobar victoria si acabamos de colocar la última bandera
    if (flagsPlaced == configuration.numberOfBombs){
      final bombIndexes = updatedCells
        .whereType<CellClosed>()
        .where((c) => c.content == CellContent.bomb)
        .map((c) => c.index)
        .toSet();
      final flaggedIndexes = _flagOwners.keys.toSet();
      if (flaggedIndexes.length == bombIndexes.length && flaggedIndexes.difference(bombIndexes).isEmpty) {
        _timer?.cancel();
        emit(Victory(configuration: configuration, cells: updatedCells));
        return;
      }
    }

    // 6) Emitir sin cambiar turno
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
