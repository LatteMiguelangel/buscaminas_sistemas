import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:buscando_minas/logic/bloc/game_bloc.dart';
import 'package:buscando_minas/logic/model.dart';
import 'package:buscando_minas/logic/network/network_manager.dart';
import 'package:buscando_minas/logic/network/network_event.dart';
import 'package:buscando_minas/views/game_board.dart';

class ClientGameScreen extends StatefulWidget {
  final NetworkClient clientManager;
  const ClientGameScreen({super.key, required this.clientManager});

  @override
  State<ClientGameScreen> createState() => _ClientGameScreenState();
}

class _ClientGameScreenState extends State<ClientGameScreen> {
  late GameBloc _bloc;
  late GameConfiguration _config;
  final String _myPlayerId = 'client';
  bool _initialized = false;

  @override
  void initState() {
    super.initState();

    // Adaptamos el callback para recibir Event<T>
    widget.clientManager.onEvent = (event) {
      print('🔔 Cliente recibió evento: ${event.type}');
      switch (event.type) {

        case EventType.gameStart:
          // Data tipada como GameStartData
          final data = event.data as GameStartData;
          _config = GameConfiguration(
            width: data.width,
            height: data.height,
            numberOfBombs: data.numberOfBombs,
          );
          final seed = data.seed;
          _bloc = GameBloc(_config)..add(InitializeGame(seed: seed));
          setState(() => _initialized = true);
          break;

        case EventType.stateUpdate:
          // Data tipada como StateUpdateData
          final stateData = event.data as StateUpdateData;
          print(
            '📦 Cliente recibe stateUpdate: '
            '${(stateData.playingStateJson['cells'] as List).length} celdas',
          );
          final playing = Playing.fromJson(
            Map<String, dynamic>.from(stateData.playingStateJson),
            _config,
          );
          _bloc.add(SetPlayingState(playing));
          if (!_initialized) {
            setState(() => _initialized = true);
          }
          break;

        default:
          // Podemos manejar revealTile o flagTile si queremos reflejar taps
          break;
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.greenAccent),
        ),
      );
    }
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black54,
          title: const Center(child: Text('🔗 Cliente: Minesweeper')),
        ),
        body: GameBoard(
          isHost: false,
          myPlayerId: _myPlayerId,
          clientManager: widget.clientManager,
        ),
      ),
    );
  }
}
