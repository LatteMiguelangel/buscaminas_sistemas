part of 'game_bloc.dart';

abstract class GameState extends Equatable {
  final GameConfiguration? gameConfiguration;
  const GameState(this.gameConfiguration);

  @override
  List<Object?> get props => [gameConfiguration];
}

class Playing extends GameState {
  final List<Cell> cells;
  final int flagsRemaining;
  final int elapsedSeconds;
  final String currentPlayerId;

  const Playing({
    required GameConfiguration? configuration,
    required this.cells,
    required this.flagsRemaining,
    this.elapsedSeconds = 0,
    required this.currentPlayerId,
  }) : super(configuration);

  @override
  List<Object?> get props => [
    gameConfiguration,
    cells,
    flagsRemaining,
    elapsedSeconds,
    currentPlayerId,
  ];

  factory Playing.fromJson(
    Map<String, dynamic> json,
    GameConfiguration config,
  ) {
    final cellList =
        (json['cells'] as List)
            .map((e) => CellSerialization.fromJson(e as Map<String, dynamic>))
            .toList();
    return Playing(
      configuration: config,
      cells: cellList,
      flagsRemaining: json['flagsRemaining'] as int,
      elapsedSeconds: json['elapsedSeconds'] as int,
      currentPlayerId: json['currentPlayerId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cells': cells.map((c) => c.toJson()).toList(),
      'flagsRemaining': flagsRemaining,
      'elapsedSeconds': elapsedSeconds,
      'currentPlayerId': currentPlayerId,
      'configuration': {
        'width': gameConfiguration?.width,
        'height': gameConfiguration?.height,
        'numberOfBombs': gameConfiguration?.numberOfBombs,
      },
    };
  }
}

class GameInitial extends GameState {
  const GameInitial(super.gameConfiguration);
}

class GameOver extends GameState {
  final List<Cell> cells;
  final bool won;

  const GameOver({
    required GameConfiguration? configuration,
    required this.cells,
    required this.won,
  }) : super(configuration);

  @override
  List<Object?> get props => super.props..addAll([cells, won]);
}

class Victory extends GameState {
  final List<Cell> cells;
  const Victory({
    required GameConfiguration? configuration,
    required this.cells,
  }) : super(configuration);

  @override
  List<Object?> get props => super.props..add(cells);
}

class GameResult extends GameState {
  final String winnerId;
  final Map<String, int> cellsRevealed;
  final Map<String, int> correctFlags;
  const GameResult({
    required GameConfiguration? configuration,
    required this.winnerId,
    required this.cellsRevealed,
    required this.correctFlags,
  }) : super(configuration);

  @override
  List<Object?> get props => [
    gameConfiguration,
    winnerId,
    cellsRevealed,
    correctFlags,
  ];
}
