import 'dart:math';
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'merge_board.dart';
import 'spawner_widget.dart';
import 'grid_model.dart';
import 'energy_system.dart';
import 'order_manager.dart';
import 'save_manager.dart';
import 'game_screen.dart';

class MergeGame extends FlameGame {
  static const List<String> _chains = ['wood', 'stone', 'flower'];

  late final GridModel grid;
  late final MergeBoard board;
  late final EnergySystem energy;
  late final OrderManager orderManager;

  @override
  Color backgroundColor() => const Color(0xFF1E1B2E);

  @override
  Future<void> onLoad() async {
    grid = await GameSaveManager.loadGrid();
    energy = await GameSaveManager.loadEnergy();
    orderManager = await GameSaveManager.loadOrders();

    if (grid.isEmptyGrid) {
      final random = Random();
      for (var i = 0; i < 6; i++) {
        grid.spawnRandom(_chains[random.nextInt(_chains.length)], random: random);
      }
    }

    final cellSize = min(size.x / grid.cols, size.y * 0.62 / grid.rows);
    board = MergeBoard(
      grid: grid,
      cellSize: cellSize,
      onMove: (result) => _autoSave(),
    )..position = Vector2((size.x - cellSize * grid.cols) / 2, size.y * 0.15);

    await add(board);

    final extent = min(size.x / 3.6, cellSize * 1.8);
    final spawnerY = board.position.y + board.size.y + extent * 0.55;

    for (var i = 0; i < _chains.length; i++) {
      await add(
        SpawnerWidget(
          energy: energy,
          board: board,
          chainId: _chains[i],
          extent: extent,
          position: Vector2(size.x * (i + 0.5) / _chains.length, spawnerY),
          onSpawn: (cell) => _autoSave(),
          onNoEnergy: () => debugPrint('Not enough energy'),
          onBoardFull: () => debugPrint('Board is full'),
        ),
      );
    }
  }

  Future<void> _autoSave() async {
    await GameSaveManager.saveGame(
      grid: grid,
      energy: energy,
      orderManager: orderManager,
    );
  }
}

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GameScreenRoot(),
    ),
  );
}

class GameScreenRoot extends StatefulWidget {
  const GameScreenRoot({super.key});

  @override
  State<GameScreenRoot> createState() => _GameScreenRootState();
}

class _GameScreenRootState extends State<GameScreenRoot> {
  late final MergeGame _game;

  @override
  void initState() {
    super.initState();
    _game = MergeGame();
  }

  @override
  Widget build(BuildContext context) {
    return GameScreen(game: _game);
  }
}
