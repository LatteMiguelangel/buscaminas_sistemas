enum NetEventType {
  gameStart,
  revealTile,
  flagTile,
  turnChange,
  endGame,
  stateUpdate,
}

class NetEvent {
  final NetEventType type;
  final Map<String, dynamic> data;

  NetEvent({required this.type, required this.data});

  factory NetEvent.fromJson(Map<String, dynamic> json) {
    return NetEvent(
      type: NetEventType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse:
            () =>
                throw ArgumentError('Tipo de evento inválido: ${json['type']}'),
      ),
      data: Map<String, dynamic>.from(json['data']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name, // Lo convertimos a string al serializar
      'data': data,
    };
  }
}
