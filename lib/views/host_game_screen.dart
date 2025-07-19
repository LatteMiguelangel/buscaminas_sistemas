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

    print('🟢 Host: esperando eventos del cliente...');

    widget.hostManager.onEvent = (event) {
      final currentState = widget.bloc.state;

      print('📥 Evento recibido del cliente: ${event.type}');
      print('🎯 Estado actual del host: $currentState');

      if (currentState is! Playing ||
          currentState.currentPlayerId != 'client') {
        print('🔕 Ignorando evento fuera de turno: ${event.type}');
        return;
      }

      switch (event.type) {
        case EventType.open:
          final index = event.data['index'] as int;
          print('✅ Host: TapCell recibido del cliente en índice $index');
          widget.bloc.add(TapCell(index));
          break;
        case EventType.flagTile:
          final data = event.data as FlagTileData;
          print('🚩 Host: bandera recibida en índice ${data.index}');
          widget.bloc.add(ToggleFlag(data.index));
          break;
        default:
          print('⚠️ Evento desconocido recibido: ${event.type}');
      }
    };

    widget.bloc.onStateUpdated = (Playing state) {
      print('📡 Host onStateUpdated: turno=${state.currentPlayerId}');

      // Solo se envía al cliente el nuevo estado
      final evt = Event<StateUpdateData>(
        type: EventType.stateUpdate,
        data: StateUpdateData(state.toJson()),
      );

      widget.hostManager.send(evt);
      print('📤 Host: stateUpdate enviado al cliente');
    };
  }

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
