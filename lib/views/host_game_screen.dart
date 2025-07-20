// ignore_for_file: avoid_print

import 'dart:async';

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
  late final StreamSubscription<Event<dynamic>> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.hostManager.events.listen(_onClientEvent);
    widget.bloc.onStateUpdated = _onStateUpdated;
  }

  void _onClientEvent(Event<dynamic> event) {
    final state = widget.bloc.state;
    if (state is! Playing || state.currentPlayerId != 'client') return;

    switch (event.type) {
      case EventType.open:
        final idx = (event.data as Map)['index'] as int;
        widget.bloc.add(TapCell(idx));
        break;
      case EventType.flagTile:
        final data = event.data as FlagTileData;
        widget.bloc.add(ToggleFlag(data.index));
        break;
      default:
    }
  }

  void _onStateUpdated(Playing state) {
    final evt = Event<StateUpdateData>(
      type: EventType.stateUpdate,
      data: StateUpdateData(state.toJson()),
    );
    widget.hostManager.send(evt);
  }

  @override
  void dispose() {
    _subscription.cancel();
    widget.hostManager.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.bloc,
      child: const Scaffold(
        backgroundColor: Colors.black,
        body: GameBoard(isHost: true, myPlayerId: 'host'),
      ),
    );
  }
}
