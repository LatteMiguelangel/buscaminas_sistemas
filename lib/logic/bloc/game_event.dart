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
  const TapCell(this.index);

  @override
  List<Object> get props => [index];
}
class ToggleFlag extends GameEvent {
  final int index;
  const ToggleFlag(this.index);
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
}

class ApplyCellUpdates extends GameEvent {
  final List<CellJson> updates;
  const ApplyCellUpdates(this.updates);

  @override
  List<Object> get props => [updates];
}