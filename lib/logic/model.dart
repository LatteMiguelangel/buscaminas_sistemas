import 'package:equatable/equatable.dart';

enum CellContent {
  zero,
  one,
  two,
  three,
  four,
  five,
  six,
  seven,
  eight,
  bomb,
  empty,
}

abstract class Cell extends Equatable {
  final CellContent content;
  final int index;
  final String? flagPlayerId;

  const Cell(this.flagPlayerId, {required this.index, required this.content});

  @override
  List<Object?> get props => [index, content, flagPlayerId];
}

extension CellExtension on Cell {
  bool get hasBomb =>
      this is CellClosed && (this as CellClosed).content == CellContent.bomb;
}

class CellClosed extends Cell {
  final bool flagged;

  const CellClosed(
    super.flagPlayerId, {
    required super.index,
    required super.content,
    this.flagged = false,
  });

  CellClosed copyWith({
    CellContent? content,
    bool? flagged,
    String? flagPlayerId,
  }) {
    return CellClosed(
      flagPlayerId ?? this.flagPlayerId, // primer parámetro posicional
      index: index,
      content: content ?? this.content,
      flagged: flagged ?? this.flagged,
    );
  }

  @override
  List<Object?> get props => super.props..add(flagged);
}

class CellOpened extends Cell {
  const CellOpened(
    super.flagPlayerId, {
    required super.index,
    required super.content,
  });
}



class GameConfiguration {
  final int width;
  final int height;
  final int numberOfBombs;

  const GameConfiguration({
    required this.width,
    required this.height,
    required this.numberOfBombs,
  });
}

GameConfiguration generateCustomConfiguration(int numberOfBombs) {
  if (numberOfBombs <= 10) {
    return GameConfiguration(width: 8, height: 8, numberOfBombs: numberOfBombs);
  } else if (numberOfBombs <= 30) {
    return GameConfiguration(
      width: 16,
      height: 16,
      numberOfBombs: numberOfBombs,
    );
  } else {
    return GameConfiguration(
      width: 30,
      height: 16,
      numberOfBombs: numberOfBombs,
    );
  }
}

extension CellSerialization on Cell {
  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'content': content.index,
      'flagged': this is CellClosed ? (this as CellClosed).flagged : false,
      'opened': this is CellOpened,
      'flagPlayerId':
          flagPlayerId, // importante para reconstruir Cell correctamente
    };
  }

  static Cell fromJson(Map<String, dynamic> json) {
    final content = CellContent.values[json['content'] as int];
    final idx = json['index'] as int;
    final opened = json['opened'] as bool;
    final flagged = json['flagged'] as bool? ?? false;
    final flagPlayerId = json['flagPlayerId'] as String?;

    if (opened) {
      return CellOpened(flagPlayerId, index: idx, content: content);
    } else {
      return CellClosed(
        flagPlayerId,
        index: idx,
        content: content,
        flagged: flagged,
      );
    }
  }
}
