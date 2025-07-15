import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:buscando_minas/logic/bloc/game_bloc.dart';
import 'package:buscando_minas/logic/network/network_manager.dart';
import 'package:buscando_minas/logic/network/network_event.dart';
import 'package:buscando_minas/views/game_board.dart';

class HostGameScreen extends StatelessWidget {
  final GameBloc bloc;
  final NetworkHost hostManager;

  const HostGameScreen({
    super.key,
    required this.bloc,
    required this.hostManager,
  });

  @override
  Widget build(BuildContext context) {
    // Escucha eventos del cliente
    hostManager.onEvent = (evt) {
      print('📩 Host recibió evento: ${evt.type}');

      if (evt.type == NetEventType.revealTile) {
        print('🎯 Host aplica reveal en: ${evt.data['index']}');
        bloc.add(TapCell(evt.data['index'] as int));
      } else if (evt.type == NetEventType.flagTile) {
        print('🚩 Host aplica flag en: ${evt.data['index']}');
        bloc.add(ToggleFlag(evt.data['index'] as int));
      } else if (evt.type == NetEventType.stateUpdate) {
        print('🔄 Host recibe estado completo del cliente');
        final map = evt.data;
        final playing = Playing.fromJson(map, bloc.configuration);
        bloc.add(SetPlayingState(playing));
      }
    };

    return BlocProvider.value(
      value: bloc,
      child: BlocBuilder<GameBloc, GameState>(
        builder: (context, state) {
          return BlocListener<GameBloc, GameState>(
            listener: (context, state) {
              if (state is Playing) {
                print('📤 Host envía stateUpdate con ${state.cells.length} celdas');
                final evt = NetEvent(
                  type: NetEventType.stateUpdate,
                  data: state.toJson(),
                );
                hostManager.send(evt.toJson());
              }
            },
            child: Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.black54,
                title: const Center(child: Text('Host: Minesweeper')),
              ),
              body: GameBoard(
                isHost: true,
                myPlayerId: 'host',
              ),
            ),
          );
        },
      ),
    );
  }
}