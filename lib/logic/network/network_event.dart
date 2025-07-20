// lib/logic/network/network_event.dart

import 'dart:convert';

enum EventType {
  gameStart,
  open,
  flagTile,
  cellUpdate,
  stateUpdate,
  clientReady,
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

class CellUpdateData {
  final List<CellJson> updates;

  CellUpdateData(this.updates);

  Map<String, dynamic> toJson() => {
        'updates': updates.map((c) => c.toJson()).toList(),
      };

  static CellUpdateData fromJson(Map<String, dynamic> json) {
    final list = List<Map<String, dynamic>>.from(json['updates'] as List);
    return CellUpdateData(
      list.map((m) => CellJson.fromJson(m)).toList(),
    );
  }
}

class CellJson {
  final int index;
  final int content;
  final bool flagged;
  final bool opened;

  CellJson({
    required this.index,
    required this.content,
    required this.flagged,
    required this.opened,
  });

  Map<String, dynamic> toJson() => {
        'index': index,
        'content': content,
        'flagged': flagged,
        'opened': opened,
      };

  static CellJson fromJson(Map<String, dynamic> m) => CellJson(
        index: m['index'] as int,
        content: m['content'] as int,
        flagged: m['flagged'] as bool,
        opened: m['opened'] as bool,
      );
}

class RevealTileData {
  final int index;

  RevealTileData({required this.index});

  Map<String, dynamic> toJson() => {'index': index};

  static RevealTileData fromJson(Map<String, dynamic> json) {
    return RevealTileData(index: json['index'] as int);
  }
}

class FlagTileData {
  final int index;

  FlagTileData({required this.index});

  Map<String, dynamic> toJson() => {'index': index};

  static FlagTileData fromJson(Map<String, dynamic> json) {
    return FlagTileData(index: json['index'] as int);
  }
}

class EmptyData {
  Map<String, dynamic> toJson() => {};

  static EmptyData fromJson(Map<String, dynamic> json) => EmptyData();
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

  Event({required this.type, required this.data});

  /// Serializa a JSON lineal, con salto de línea al final.
  String toJsonString() {
    final map = {
      'type': type.toString().split('.').last,
      'data': (data as dynamic).toJson(),
    };
    return '${jsonEncode(map)}\n';
  }

  /// Crea un Event desde un Map decodificado.
  static Event<dynamic> fromJsonMap(Map<String, dynamic> map) {
    final typeString = map['type'] as String;
    final type = EventType.values.firstWhere(
      (e) => e.toString().split('.').last == typeString,
      orElse: () =>
          throw ArgumentError('Tipo desconocido en protocolo: $typeString'),
    );
    final dataMap = Map<String, dynamic>.from(map['data'] as Map);

    switch (type) {
      case EventType.gameStart:
        return Event<GameStartData>(
          type: type,
          data: GameStartData.fromJson(dataMap),
        );

      case EventType.open:
        return Event<RevealTileData>(
          type: type,
          data: RevealTileData.fromJson(dataMap),
        );

      case EventType.flagTile:
        return Event<FlagTileData>(
          type: type,
          data: FlagTileData.fromJson(dataMap),
        );

      case EventType.cellUpdate:
        return Event<CellUpdateData>(
          type: type,
          data: CellUpdateData.fromJson(dataMap),
        );

      case EventType.stateUpdate:
        return Event<StateUpdateData>(
          type: type,
          data: StateUpdateData.fromJson(dataMap),
        );

      case EventType.clientReady:
        return Event<EmptyData>(
          type: type,
          data: EmptyData.fromJson(dataMap),
        );
    }
  }

  /// Parsea un String JSON lineal y devuelve el Event.
  /// Usa [fromJsonMap] internamente.
  static Event<dynamic> fromJsonString(String jsonStr) {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return fromJsonMap(map);
  }
}
