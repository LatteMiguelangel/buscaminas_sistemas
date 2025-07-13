import 'package:buscando_minas/logic/network/network_manager.dart';
import 'package:buscando_minas/logic/network/network_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:buscando_minas/logic/bloc/game_bloc.dart';
import 'package:buscando_minas/logic/model.dart';
import 'package:buscando_minas/views/game/cell_view.dart';

/// Pantalla de juego multijugador, tanto para Host como para Cliente.
class MultiplayerGameScreen extends StatefulWidget {
  // Para el Host
  final NetworkHost? hostManager;
  final GameConfiguration? hostConfig;
  final int? hostSeed;

  // Para el Cliente
  final NetworkClient? clientManager;

  // Bandera para saber si es host o cliente
  final bool isHost;

  const MultiplayerGameScreen.host({
    super.key,
    required this.hostManager,
    required this.hostConfig,
    required this.hostSeed,
  })  : clientManager = null,
        isHost = true;

  const MultiplayerGameScreen.client({
    super.key,
    required this.clientManager,
  })  : hostManager = null,
        hostConfig = null,
        hostSeed = null,
        isHost = false;

  @override
  State<MultiplayerGameScreen> createState() => _MultiplayerGameScreenState();
}

class _MultiplayerGameScreenState extends State<MultiplayerGameScreen> {
  late final GameBloc _gameBloc;
  bool _boardInitialized = false;

  @override
  void initState() {
    super.initState();

    if (widget.isHost) {
      final cfg = widget.hostConfig!;
      final seed = widget.hostSeed!;
      _gameBloc = GameBloc(cfg)..add(InitializeGame(seed: seed));
      // Registrar callback
      //widget.hostManager!.onEvent?.call; //placeholder
      _boardInitialized = true;
    } else {
      widget.clientManager!.onEvent = (NetEvent event) {
        if (event.type == NetEventType.gameStart) {
          final data = event.data;
          final width = data['width'] as int;
          final height = data['height'] as int;
          final bombs = data['numberOfBombs'] as int;
          final seed = data['seed'] as int;

          //1. Crear Config
          final config = GameConfiguration(
            width: width,
            height: height,
            numberOfBombs: bombs,
          );

          //2. Inicializar BLoC
          _gameBloc = GameBloc(config)..add(InitializeGame(seed: seed));

          setState(() {
            _boardInitialized = true;
          });
        }
      };
    }
  }

  @override
  void dispose() {
    if (widget.isHost) {
      final cfg = widget.hostConfig!;
      final seed = widget.hostSeed!;
      _gameBloc = GameBloc(cfg)..add(InitializeGame(seed: seed));
      _boardInitialized = true;
      //widget.hostManager?.stop();
    } else {
      // Cliente: esperaremos gameStart
      //widget.clientManager?.disconnect();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Si somos cliente y aún no llegó gameStart, mostramos indicador
    if (!widget.isHost && !_boardInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.greenAccent),
        ),
      );
    }

    // Una vez inicializado (host o cliente), mostramos el juego
    return BlocProvider.value(
      value: _gameBloc,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black54,
          title: Center(
            child: Text(
              widget.isHost ? '🖥️ Host: Min(es)weeper' : '🔗 Cliente: Min(es)weeper',
            ),
          ),
        ),
        body: BlocBuilder<GameBloc, GameState>(
          builder: (context, state) {
            // Aquí reutilizamos tu _gameContent, _gameOverContent y _victoryContent
            // de GameScreen. Por claridad los copiamos o extraemos a un mixin.
            // Además: bloqueamos taps si no es tu turno (próximamente).
            if (state is Playing) {
              return _gameContent(state);
            } else if (state is GameOver) {
              return _gameOverContent(context, state);
            } else if (state is Victory) {
              return _victoryContent(context, state);
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }

  // TODO: Pega aquí tu lógica de _gameContent, _gameOverContent y _victoryContent
  Widget _gameContent(Playing state) {
    final config = state.gameConfiguration!;
    final width = config.width;
    final height = config.height;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("🚩 ${state.flagsRemaining}"),
              Text("⏱️ ${_formatTime(state.elapsedSeconds)}")
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final gridSize = constraints.maxWidth;
              return Center(
                child: SizedBox(
                  width: gridSize,
                  height: gridSize,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: width,
                          crossAxisSpacing: 1,
                          mainAxisSpacing: 1,
                          childAspectRatio: width / height,
                        ),
                    padding: const EdgeInsets.all(2),
                    itemCount: state.cells.length,
                    itemBuilder: (context, index) {
                      return CellView(cell: state.cells[index]);
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _gameOverContent(BuildContext context, GameOver state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          '💥 ¡Has perdido!',
          style: TextStyle(fontSize: 24, color: Colors.red),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            context.read<GameBloc>().add(InitializeGame());
          },
          child: const Text('🔁 Jugar de nuevo'),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(); // O ir al menú
          },
          child: const Text('🏠 Volver al menú'),
        ),
      ],
    );
  }

  Widget _victoryContent(BuildContext context, Victory state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          '🎉 ¡Has ganado!',
          style: TextStyle(fontSize: 24, color: Colors.greenAccent),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            context.read<GameBloc>().add(InitializeGame());
          },
          child: const Text('🔁 Jugar de nuevo'),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('🏠 Volver al menú'),
        ),
      ],
    );
  }
  // FIXME: métodos auxiliares para manejar eventos de red:
  // void _onNetEvent(NetEvent event) { ... }
  // void _handleClientEvent(NetEvent event) { ... }
}

String _formatTime(int seconds) {
  final minutes = seconds ~/ 60;
  final secs = seconds % 60;
  return "${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
}