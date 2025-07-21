part of 'game_bloc.dart';

abstract class GameEvent extends Equatable {
  const GameEvent();
  @override
  List<Object> get props => [];
}

class InitializeGame extends GameEvent {
  final int? seed;
  const InitializeGame({this.seed});

  @override
  List<Object> get props => [seed ?? 0];
}

class TapCell extends GameEvent {
  final int index;
  final String playerId;
  const TapCell(this.index, this.playerId);

  @override
  List<Object> get props => [index, playerId];
}
class ToggleFlag extends GameEvent {
  final int index;
  final String playerId;

  const ToggleFlag({required this.index, required this.playerId});
}

class UpdateTime extends GameEvent {}

class ReplaceState extends GameEvent {
  final Playing newState;
  const ReplaceState(this.newState);
  @override
  List<Object> get props => [newState];
}

class SetPlayingState extends GameEvent {
  final Playing playing;
  const SetPlayingState(this.playing);
  @override
  List<Object> get props => [playing];
}
