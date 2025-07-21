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
    super.key,
    required this.proxy,
    required this.isHost,
  });

  @override
  _MultiplayerGameScreenState createState() => _MultiplayerGameScreenState();
}

class _MultiplayerGameScreenState extends State<MultiplayerGameScreen> {
  late final String _myId;
  late StreamSubscription<Event<dynamic>> _sub;

  // Lobby
  bool _clientReady = false;
  bool _gameStarting = false;
  bool _inGame = false;

  // Juego
  late GameConfiguration _config;
  late GameBloc _bloc;
  List<Cell>? _previousCells;

  static const _defaultWidth = 8;
  static const _defaultHeight = 8;
  static const _defaultBombs = 10;

  @override
  void initState() {
    super.initState();
    _myId = widget.isHost ? 'host' : 'client';
    _config = GameConfiguration(
      width: _defaultWidth,
      height: _defaultHeight,
      numberOfBombs: _defaultBombs,
    );

    // 1) Escuchar todo lo que venga del relé
    _sub = widget.proxy.events.listen(_handleEvent);
  }

  void _handleEvent(Event<dynamic> event) {
    switch (event.type) {
      // 2) Host recibe confirmación de proxy (cliente listo)
      case EventType.clientReady:
        if (widget.isHost) {
          setState(() => _clientReady = true);
        }
        break;

      // 3) Ambos reciben gameStart: host lo envía, cliente lo aplica
      case EventType.gameStart:
        if (!_inGame) {
          final data = event.data as GameStartData;
          _config = GameConfiguration(
            width: data.width,
            height: data.height,
            numberOfBombs: data.numberOfBombs,
          );
          _startBloc(seed: data.seed);
        }
        break;

      // 4) Host procesa taps/flags del cliente
      case EventType.open:
      case EventType.flagTile:
        if (widget.isHost && _inGame) {
          final idx = (event.data as dynamic).index as int;
          final ev =
              event.type == EventType.open ? TapCell(idx) : ToggleFlag(idx);
          _bloc.add(ev);
        }
        break;

      // 5) Cliente aplica diffs enviados por el host
      case EventType.cellUpdate:
        if (!widget.isHost && _inGame) {
          final data = event.data as CellUpdateData;
          _bloc.add(ApplyCellUpdates(data.updates, data.nextPlayerId));
        }
        break;

      default:
        // register, errores, etc.
        break;
    }
  }

  /// Inicializa el BLoC y engancha el envío de cellUpdate (solo host).
  void _startBloc({required int seed}) {
    _bloc = GameBloc(_config, enableTimer: !widget.isHost)
      ..add(InitializeGame(seed: seed));

    if (widget.isHost) {
      _bloc.onStateUpdated = _sendCellUpdates;
      // marcamos que ya arrancó el juego
      setState(() {
        _inGame = true;
        _gameStarting = false;
      });
    } else {
      // cliente también entra en juego
      setState(() => _inGame = true);
    }
  }

  /// Solo host: calcula diffs y envía cellUpdate con nextPlayerId
  void _sendCellUpdates(Playing state) {
    final diffs = <CellJson>[];
    final cells = state.cells;

    if (_previousCells == null) {
      for (var c in cells) {
        final opened = c is CellOpened;
        final flagged = c is CellClosed && c.flagged;
        if (opened || flagged) {
          diffs.add(CellJson(
            index: c.index,
            content: c.content.index,
            flagged: flagged,
            opened: opened,
          ));
        }
      }
    } else {
      for (var i = 0; i < cells.length; i++) {
        final oldC = _previousCells![i];
        final newC = cells[i];
        final opened = newC is CellOpened;
        final flagged = newC is CellClosed && newC.flagged;
        final oldOpened = oldC is CellOpened;
        final oldFlagged = oldC is CellClosed && (oldC as CellClosed).flagged;
        if (opened != oldOpened || flagged != oldFlagged) {
          diffs.add(CellJson(
            index: newC.index,
            content: newC.content.index,
            flagged: flagged,
            opened: opened,
          ));
        }
      }
    }

    _previousCells = List<Cell>.from(cells);
    final evt = Event<CellUpdateData>(
      type: EventType.cellUpdate,
      data: CellUpdateData(diffs, state.currentPlayerId),
    );
    widget.proxy.send(evt);
    debugPrint('📤 Host envía cellUpdate: ${evt.toJsonString().trim()}');
  }

  /// Botón “Iniciar partida” en el lobby del host
  void _onStartPressed() {
    setState(() => _gameStarting = true);

    final seed = DateTime.now().millisecondsSinceEpoch;
    // 1) Arrancar el BLoC local
    _startBloc(seed: seed);

    // 2) Notificar al cliente
    widget.proxy.send(
      Event<GameStartData>(
        type: EventType.gameStart,
        data: GameStartData(
          width: _config.width,
          height: _config.height,
          numberOfBombs: _config.numberOfBombs,
          seed: seed,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _sub.cancel();
    widget.proxy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ------ LOBBY ------
    if (!_inGame) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black87,
          title: Text(
            widget.isHost ? 'Host Lobby' : 'Cliente Lobby',
            style: const TextStyle(color: Colors.greenAccent),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: widget.isHost
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _clientReady
                          ? 'Cliente conectado'
                          : 'Esperando cliente…',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _clientReady && !_gameStarting
                          ? _onStartPressed
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        foregroundColor: Colors.black,
                      ),
                      child: Text(_gameStarting
                          ? 'Iniciando…'
                          : 'Iniciar partida'),
                    ),
                  ],
                )
              : const Text(
                  'Esperando al host para iniciar',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
        ),
      );
    }

    // ------ PARTIDA EN CURSO ------
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
          builder: (ctx, state) {
            if (state is! Playing) {
              return const Center(
                child: CircularProgressIndicator(
                    color: Colors.greenAccent),
              );
            }

            final locked = state.currentPlayerId != _myId;
            final width = state.gameConfiguration!.width;
            final height = state.gameConfiguration!.height;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '🚩 ${state.flagsRemaining}',
                        style:
                            const TextStyle(color: Colors.white),
                      ),
                      Text(
                        locked
                            ? '⚪ Turno oponente'
                            : '⬢ Tu turno',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '⏱ ${state.elapsedSeconds ~/ 60}'
                        ':${(state.elapsedSeconds % 60).toString().padLeft(2, '0')}',
                        style:
                            const TextStyle(color: Colors.white),
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
                        builder: (c, cons) {
                          final gridSize = cons.maxWidth;
                          return Center(
                            child: SizedBox(
                              width: gridSize,
                              height: gridSize,
                              child: GridView.builder(
                                padding:
                                    const EdgeInsets.all(2),
                                physics:
                                    const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: width,
                                  crossAxisSpacing: 1,
                                  mainAxisSpacing: 1,
                                  childAspectRatio:
                                      width / height,
                                ),
                                itemCount: state.cells.length,
                                itemBuilder: (c, i) {
                                  return GestureDetector(
                                    onTap: () {
                                      if (!locked) {
                                        _bloc.add(TapCell(i));
                                        widget.proxy.send(
                                          Event<RevealTileData>(
                                            type: EventType.open,
                                            data: RevealTileData(
                                                index: i),
                                          ),
                                        );
                                      }
                                    },
                                    onLongPress: () {
                                      if (!locked) {
                                        _bloc.add(ToggleFlag(i));
                                        widget.proxy.send(
                                          Event<FlagTileData>(
                                            type: EventType.flagTile,
                                            data: FlagTileData(
                                                index: i),
                                          ),
                                        );
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
}