import 'dart:convert';

enum EventType {
  gameStart,
  revealTile,
  flagTile,
  stateUpdate,
  open,
}

class GameStartData {
  final int width;
  final int height;
  final int numberOfBombs;
  final int seed;

  GameStartData({
    required this.width,
    required this.height,
    required this.numberOfBombs,
    required this.seed,
  });

  Map<String, dynamic> toJson() => {
        'width': width,
        'height': height,
        'numberOfBombs': numberOfBombs,
        'seed': seed,
      };

  static GameStartData fromJson(Map<String, dynamic> json) {
    return GameStartData(
      width: json['width'] as int,
      height: json['height'] as int,
      numberOfBombs: json['numberOfBombs'] as int,
      seed: json['seed'] as int,
    );
  }
}

class RevealTileData {
  final int index;
  RevealTileData({ required this.index });
  Map<String, dynamic> toJson() => {
        'index': index,
      };

  static RevealTileData fromJson(Map<String, dynamic> json) {
    return RevealTileData(index: json['index'] as int);
  }
}


class FlagTileData {
  final int index;
  FlagTileData({ required this.index });
  Map<String, dynamic> toJson() => {
        'index': index,
      };

  static FlagTileData fromJson(Map<String, dynamic> json) {
    return FlagTileData(index: json['index'] as int);
  }
}


class StateUpdateData {
  final Map<String, dynamic> playingStateJson;
  StateUpdateData(this.playingStateJson);
  Map<String, dynamic> toJson() => playingStateJson;
  static StateUpdateData fromJson(Map<String, dynamic> json) {
    return StateUpdateData(Map<String, dynamic>.from(json));
  }
}


class Event<T> {
  final EventType type;
  final T data;
  Event({ required this.type, required this.data });
  String toJsonString() {
    final map = {
      'type': type.toString().split('.').last,
      'data': (data as dynamic).toJson(),
    };
    return jsonEncode(map) + '\n';
  }

  static Event<dynamic> fromJsonMap(Map<String, dynamic> map) {
    final typeString = map['type'] as String;
    final type = EventType.values.firstWhere(
      (e) => e.toString().split('.').last == typeString,
      orElse: () => throw ArgumentError('Tipo desconocido: $typeString'),
    );
    final dataMap = Map<String, dynamic>.from(map['data'] as Map);
    switch (type) {
      case EventType.gameStart:
        return Event<GameStartData>(
          type: type,
          data: GameStartData.fromJson(dataMap),
        );
      case EventType.revealTile:
        return Event<RevealTileData>(
          type: type,
          data: RevealTileData.fromJson(dataMap),
        );
      case EventType.flagTile:
        return Event<FlagTileData>(
          type: type,
          data: FlagTileData.fromJson(dataMap),
        );
      case EventType.stateUpdate:
        return Event<StateUpdateData>(
          type: type,
          data: StateUpdateData.fromJson(dataMap),
        );
      case EventType.open:
        return Event<RevealTileData>(
        type: type,
        data: RevealTileData.fromJson(dataMap),
      );
    }
  }
}