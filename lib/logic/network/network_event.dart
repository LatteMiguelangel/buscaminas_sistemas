enum NetEventType { gameStart /*, revealTile, flagTile, turnChange, endGame...*/ }

class NetEvent {
  final NetEventType type;
  final Map<String, dynamic> data;
  NetEvent({required this.type, required this.data});

  Map<String, dynamic> toJson() => {
    'type': type.toString().split('.').last,
    'data': data,
  };

  factory NetEvent.fromJson(Map<String, dynamic> json) {
    final t = NetEventType.values.firstWhere(
      (e) => e.toString().split('.').last == json['type']
    );
    return NetEvent(type: t, data: Map<String, dynamic>.from(json['data']));
  }
}