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
    widget.clientManager.onEvent = (NetEvent evt) {
      print('🔔 Cliente recibió evento: $evt');
      switch (evt.type) {
        case NetEventType.gameStart:
          final d = evt.data;
          _config = GameConfiguration(
            width: d['width'] as int,
            height: d['height'] as int,
            numberOfBombs: d['numberOfBombs'] as int,
          );
          final seed = d['seed'] as int;
          _bloc = GameBloc(_config)..add(InitializeGame(seed: seed));
          setState(() => _initialized = true);
          break;
        case NetEventType.stateUpdate:
          final map = evt.data;
          print(
            '📦 Cliente recibe stateUpdate: ${map['cells']?.length} celdas',
          );
          final playing = Playing.fromJson(map, _config);
          _bloc.add(SetPlayingState(playing));
          if (!_initialized) {
            setState(() => _initialized = true);
          }
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
