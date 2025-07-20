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

    widget.clientManager.onEvent = (event) {
      debugPrint('🔔 Cliente recibió evento: ${event.type}');
      switch (event.type) {
        case EventType.gameStart:
          final data = event.data as GameStartData;
          _config = GameConfiguration(
            width: data.width,
            height: data.height,
            numberOfBombs: data.numberOfBombs,
          );
          final seed = data.seed;
          _bloc = GameBloc(
            _config,
            enableTimer: false,
          )..add(InitializeGame(seed: seed));
          if (!mounted) return;
          setState(() => _initialized = true);
          break;

        case EventType.stateUpdate:
          final data = event.data as StateUpdateData;
          debugPrint(
            '📥 Cliente stateUpdate JSON.currentPlayerId='
            '${data.playingStateJson['currentPlayerId']}',
          );
          final playing = Playing.fromJson(
            Map<String, dynamic>.from(data.playingStateJson),
            _config,
          );
          debugPrint(
            '📥 Cliente construyó Playing.currentPlayerId='
            '${playing.currentPlayerId}',
          );
          _bloc.add(SetPlayingState(playing));
          break;

        case EventType.open:
          final data = event.data as RevealTileData;
          debugPrint('📥 Cliente recibió eco open: index=${data.index}');
          break;

        default:
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