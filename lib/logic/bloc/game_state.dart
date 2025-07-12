part of 'game_bloc.dart';

abstract class GameState extends Equatable {
  final GameConfiguration? gameConfiguration;
  const GameState(this.gameConfiguration);

  @override
  List<Object?> get props => [gameConfiguration];
}

class GameInitial extends GameState {
  const GameInitial(super.gameConfiguration);
}

class Playing extends GameState {
  final List<Cell> cells;
  final int flagsRemaining;
  final int elapsedSeconds;

  const Playing({
    GameConfiguration? configuration,
    required this.cells,
    required this.flagsRemaining,
    this.elapsedSeconds = 0,
  }) : super(configuration);

  @override
  List<Object?> get props => super.props..addAll([cells, flagsRemaining, elapsedSeconds]);
}

class GameOver extends GameState {
  final List<Cell> cells;
  final bool won;

  const GameOver({
    GameConfiguration? configuration,
    required this.cells,
    required this.won,
  }) : super(configuration);

  @override
  List<Object?> get props => super.props..addAll([cells, won]);
}

class Victory extends GameState {
  const Victory(super.gameConfiguration);
  @override
  List<Object?> get props => super.props..addAll([]);
}
