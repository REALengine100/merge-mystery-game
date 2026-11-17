import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'grid_model.dart';
import 'energy_system.dart';
import 'order_manager.dart';

class GameSaveManager {
  static const String _keyGrid = 'saved_grid_data';
  static const String _keyEnergy = 'saved_energy_data';
  static const String _keyOrders = 'saved_orders_data';

  static Future<void> saveGame({
    required GridModel grid,
    required EnergySystem energy,
    required OrderManager orderManager,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyGrid, jsonEncode(grid.toJson()));
    await prefs.setString(_keyEnergy, jsonEncode(energy.toJson()));
    await prefs.setString(_keyOrders, jsonEncode(orderManager.toJson()));
  }

  static Future<GridModel> loadGrid() async {
    final prefs = await SharedPreferences.getInstance();
    final gridString = prefs.getString(_keyGrid);
    if (gridString == null) return GridModel(rows: 7, cols: 7);
    try {
      return GridModel.fromJson(jsonDecode(gridString));
    } catch (_) {
      return GridModel(rows: 7, cols: 7);
    }
  }

  static Future<EnergySystem> loadEnergy() async {
    final prefs = await SharedPreferences.getInstance();
    final energyString = prefs.getString(_keyEnergy);
    if (energyString == null) return EnergySystem();
    try {
      return EnergySystem.fromJson(jsonDecode(energyString));
    } catch (_) {
      return EnergySystem();
    }
  }

  static Future<OrderManager> loadOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final orderString = prefs.getString(_keyOrders);
    if (orderString == null) return OrderManager();
    try {
      return OrderManager.fromJson(jsonDecode(orderString));
    } catch (_) {
      return OrderManager();
    }
  }
}
