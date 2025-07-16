import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:buscando_minas/logic/bloc/game_bloc.dart';
import 'package:buscando_minas/logic/network/network_manager.dart';
import 'package:buscando_minas/logic/network/network_event.dart';
import 'package:buscando_minas/views/game_board.dart';

class HostGameScreen extends StatefulWidget {
  final GameBloc bloc;
  final NetworkHost hostManager;

  const HostGameScreen({
    super.key,
    required this.bloc,
    required this.hostManager,
  });

  @override
  State<HostGameScreen> createState() => _HostGameScreenState();
}

class _HostGameScreenState extends State<HostGameScreen> {
  @override
  void initState() {
    super.initState();

    // Escuchamos eventos del cliente
    widget.hostManager.onEvent = (event) {
      print('📩 HostGameScreen recibió evento: ${event.type}');
      switch (event.type) {
        case EventType.revealTile:
          final data = event.data as RevealTileData;
          widget.bloc.add(TapCell(data.index));
          break;
        case EventType.flagTile:
          final data = event.data as FlagTileData;
          widget.bloc.add(ToggleFlag(data.index));
          break;
        default:
          print('🔔 Evento no manejado en Host: ${event.type}');
          break;
      }
    };

    // Cada vez que el bloc actualiza estado, enviamos stateUpdate
    widget.bloc.onStateUpdated = (Playing state) {
      final evt = Event<StateUpdateData>(
        type: EventType.stateUpdate,
        data: StateUpdateData(state.toJson()),
      );
      print('→ Enviando stateUpdate: ${evt.toJsonString().trim()}');
      widget.hostManager.send(evt);
    };
  }

  @override
  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.bloc,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black54,
          title: const Center(child: Text('Host: Minesweeper')),
        ),
        body: const GameBoard(isHost: true, myPlayerId: 'host'),
      ),
    );
  }

  @override
  void dispose() {
    widget.hostManager.stop();
    super.dispose();
  }
}
