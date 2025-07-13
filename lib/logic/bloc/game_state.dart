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
  final String currentPlayerId;

  const Playing({
    GameConfiguration? configuration,
    required this.cells,
    required this.flagsRemaining,
    this.elapsedSeconds = 0,
    required this.currentPlayerId,
  }) : super(configuration);

  @override
  List<Object?> get props => super.props
    ..addAll([cells, flagsRemaining, elapsedSeconds, currentPlayerId]);

  /// Fábrica para reconstruir desde JSON y config
  factory Playing.fromJson(Map<String, dynamic> json, GameConfiguration config) {
    final cellList = (json['cells'] as List)
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

  /// Convierte a JSON para enviar
  Map<String, dynamic> toJson() {
    return {
      'cells': cells.map((c) => c.toJson()).toList(),
      'flagsRemaining': flagsRemaining,
      'elapsedSeconds': elapsedSeconds,
      'currentPlayerId': currentPlayerId,
    };
  }
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
