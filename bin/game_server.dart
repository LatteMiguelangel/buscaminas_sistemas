// bin/game_server.dart

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:buscando_minas/logic/bloc/game_bloc.dart';
import 'package:buscando_minas/logic/model.dart';
import 'package:buscando_minas/logic/network/network_event.dart';

void main() async {
  const port = 4040;
  final server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
  print('▶️ Servidor Dart iniciado en puerto $port');

  Socket? hostSocket;
  Socket? clientSocket;

  late GameConfiguration config;
  late GameBloc bloc;
  List<Cell>? previousCells; // null hasta recibir primer estado

  void broadcast(Event<dynamic> evt) {
    final jsonStr = evt.toJsonString();
    if (hostSocket != null) hostSocket!.writeln(jsonStr);
    if (clientSocket != null) clientSocket!.writeln(jsonStr);
    print('✈️ [SERVER→ALL] $jsonStr');
  }

  server.listen((socket) {
    print(
        '🔗 Conexión de ${socket.remoteAddress.address}:${socket.remotePort}');
    final buffer = StringBuffer();

    socket.listen((Uint8List raw) {
      buffer.write(utf8.decode(raw));
      final content = buffer.toString();
      final lines = content.split('\n');

      // conserva posible fragmento para la próxima lectura
      buffer.clear();
      buffer.write(lines.last);

      for (var i = 0; i < lines.length - 1; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        print('📥 [RAW] $line');

        try {
          final map = jsonDecode(line) as Map<String, dynamic>;
          final type = map['type'] as String;

          // 1) Registro de rol
          if (type == 'register') {
            final role = map['role'] as String;
            if (role == 'host') {
              hostSocket = socket;
              print('🏠 Host registrado');
            } else {
              clientSocket = socket;
              print('👤 Cliente registrado');
            }

            // 2) Cuando ambos están conectados, inicializar juego
            if (hostSocket != null &&
                clientSocket != null &&
                previousCells == null) {
              config = GameConfiguration(
                width: 8,
                height: 8,
                numberOfBombs: 10,
              );
              final seed = DateTime.now().millisecondsSinceEpoch;

              bloc = GameBloc(config, enableTimer: false)
                ..add(InitializeGame(seed: seed));

              // previousCells se mantiene null hasta el primer update
              previousCells = null;

              // 3) Callback para diffs tras cada jugada
              bloc.onStateUpdated = (Playing state) {
                final cells = state.cells;

                // Primer estado: solo guardamos snapshot, no emitimos diffs
                if (previousCells == null) {
                  previousCells = List<Cell>.from(cells);
                  return;
                }

                // A partir de aquí, calculamos los diffs
                final diffs = <CellJson>[];
                for (var j = 0; j < cells.length; j++) {
                  final oldC = previousCells![j];
                  final newC = cells[j];
                  final opened = newC is CellOpened;
                  final flagged = newC is CellClosed && newC.flagged;
                  final oldOpened = oldC is CellOpened;
                  final oldFlagged =
                      oldC is CellClosed && (oldC as CellClosed).flagged;

                  if (opened != oldOpened || flagged != oldFlagged) {
                    diffs.add(CellJson(
                      index: newC.index,
                      content: newC.content.index,
                      opened: opened,
                      flagged: flagged,
                    ));
                  }
                }

                previousCells = List<Cell>.from(cells);

                // Emitir diffs solo si hay cambios
                if (diffs.isNotEmpty) {
                  broadcast(Event<CellUpdateData>(
                    type: EventType.cellUpdate,
                    data: CellUpdateData(diffs, state.currentPlayerId),
                  ));
                }
              };

              // 4) Emitir gameStart inicial
              broadcast(Event<GameStartData>(
                type: EventType.gameStart,
                data: GameStartData(
                  width: config.width,
                  height: config.height,
                  numberOfBombs: config.numberOfBombs,
                  seed: seed,
                ),
              ));
            }

            continue;
          }

          // 5) Procesar jugadas open / flagTile
          if (previousCells != null && (type == 'open' || type == 'flagTile')) {
            final evt = Event.fromJsonString(line);
            if (evt.type == EventType.open) {
              final idx = (evt.data as RevealTileData).index;
              print('🎯 [SERVER] TapCell($idx)');
              bloc.add(TapCell(idx));
            } else {
              final idx = (evt.data as FlagTileData).index;
              print('🎯 [SERVER] ToggleFlag($idx)');
              bloc.add(ToggleFlag(idx));
            }
          }
        } catch (e) {
          print('⚠️ Error procesando mensaje: $e');
        }
      }
    }, onDone: () {
      if (socket == hostSocket) hostSocket = null;
      if (socket == clientSocket) clientSocket = null;
      print('❌ ${socket.remoteAddress.address} desconectado');
    });
  });
}
