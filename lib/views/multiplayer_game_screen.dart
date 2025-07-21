// lib/views/multiplayer_game_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:buscando_minas/logic/bloc/game_bloc.dart';
import 'package:buscando_minas/logic/model.dart';
import 'package:buscando_minas/logic/network/proxy_client.dart';
import 'package:buscando_minas/logic/network/network_event.dart';
import 'package:buscando_minas/views/game/cell_view.dart';

class MultiplayerGameScreen extends StatefulWidget {
  final ProxyClient proxy;
  final bool isHost;

  const MultiplayerGameScreen({
    Key? key,
    required this.proxy,
    required this.isHost,
  }) : super(key: key);

  @override
  State<MultiplayerGameScreen> createState() => _MultiplayerGameScreenState();
}

class _MultiplayerGameScreenState extends State<MultiplayerGameScreen> {
  late final String _myId;
  late final StreamSubscription<Event<dynamic>> _sub;
  late final GameBloc _bloc;
  bool _inGame = false;
  late final GameConfiguration _config;

  @override
  void initState() {
    super.initState();
    _myId = widget.isHost ? 'host' : 'client';

    // 1) Escuchar solo gameStart y cellUpdate
    _sub = widget.proxy.events.listen(
      _onEvent,
      onError: (e) => debugPrint('⚠️ [$_myId] ProxyClient error: $e'),
      onDone: () => debugPrint('🔒 [$_myId] ProxyClient closed'),
    );
  }

  void _onEvent(Event<dynamic> evt) {
    debugPrint('🔄 [$_myId] Received → ${evt.type}');
    if (evt.type == EventType.gameStart) {
      final d = evt.data as GameStartData;
      _config = GameConfiguration(
        width: d.width,
        height: d.height,
        numberOfBombs: d.numberOfBombs,
      );
      _bloc = GameBloc(_config, enableTimer: false)
        ..add(InitializeGame(seed: d.seed));
      setState(() => _inGame = true);
    } else if (evt.type == EventType.cellUpdate && _inGame) {
      final d = evt.data as CellUpdateData;
      debugPrint(
          '📥 [$_myId] cellUpdate diffs=${d.updates.length}, next=${d.nextPlayerId}');
      _bloc.add(ApplyCellUpdates(d.updates, d.nextPlayerId));
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    widget.proxy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_inGame) {
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
          backgroundColor: Colors.black87,
          title: Text(
            widget.isHost ? 'Host: Buscaminas' : 'Cliente: Buscaminas',
            style: const TextStyle(color: Colors.greenAccent),
          ),
          centerTitle: true,
        ),
        body: BlocBuilder<GameBloc, GameState>(
          builder: (_, state) {
            if (state is! Playing) {
              return const Center(
                child: CircularProgressIndicator(
                    color: Colors.greenAccent),
              );
            }

            final locked = state.currentPlayerId != _myId;
            debugPrint(
                '🔒 [$_myId] locked=$locked, turn=${state.currentPlayerId}');

            final w = _config.width;
            final h = _config.height;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text('🚩 ${state.flagsRemaining}',
                          style: const TextStyle(color: Colors.white)),
                      Text(
                        locked
                            ? '⏳ Turno ${state.currentPlayerId}'
                            : '⬢ Tu turno',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '⏱ ${_formatTime(state.elapsedSeconds)}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: AbsorbPointer(
                    absorbing: locked,
                    child: Opacity(
                      opacity: locked ? 0.6 : 1.0,
                      child: LayoutBuilder(
                        builder: (_, cons) {
                          final size = cons.maxWidth;
                          return Center(
                            child: SizedBox(
                              width: size,
                              height: size,
                              child: GridView.builder(
                                padding: const EdgeInsets.all(2),
                                physics:
                                    const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: w,
                                  crossAxisSpacing: 1,
                                  mainAxisSpacing: 1,
                                  childAspectRatio: w / h,
                                ),
                                itemCount: state.cells.length,
                                itemBuilder: (_, i) {
                                  return GestureDetector(
                                    onTap: () {
                                      debugPrint(
                                          '🤚 [$_myId] tap idx=$i');
                                      if (!locked) {
                                        widget.proxy.send(
                                          Event<RevealTileData>(
                                            type: EventType.open,
                                            data:
                                                RevealTileData(index: i),
                                          ),
                                        );
                                        debugPrint(
                                            '📤 [$_myId] send open idx=$i');
                                      }
                                    },
                                    onLongPress: () {
                                      debugPrint(
                                          '🤏 [$_myId] long idx=$i');
                                      if (!locked) {
                                        widget.proxy.send(
                                          Event<FlagTileData>(
                                            type:
                                                EventType.flagTile,
                                            data:
                                                FlagTileData(index: i),
                                          ),
                                        );
                                        debugPrint(
                                            '📤 [$_myId] send flag idx=$i');
                                      }
                                    },
                                    child: CellView(
                                        cell: state.cells[i]),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    final mm = m.toString().padLeft(2, "0");
    final ss = s.toString().padLeft(2, "0");
    return '$mm:$ss';
  }
}
