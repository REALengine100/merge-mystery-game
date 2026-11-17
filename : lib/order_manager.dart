import 'package:flutter/foundation.dart';
import 'grid_model.dart';

class Order {
  final String id;
  final String chainId;
  final int level;
  final int coinReward;
  final int xpReward;

  const Order({
    required this.id,
    required this.chainId,
    required this.level,
    required this.coinReward,
    required this.xpReward,
  });

  bool matches(Item item) => item.chainId == chainId && item.level == level;
}

class OrderManager extends ChangeNotifier {
  OrderManager({int initialCoins = 100, int initialXp = 0})
      : _coins = initialCoins,
        _xp = initialXp {
    _generateOrders();
  }

  int _coins;
  int _xp;
  final List<Order> _activeOrders = [];

  int get coins => _coins;
  int get xp => _xp;
  List<Order> get activeOrders => List.unmodifiable(_activeOrders);

  void _generateOrders() {
    if (_activeOrders.isNotEmpty) return;
    _activeOrders.addAll([
      const Order(
        id: 'order_1',
        chainId: 'wood',
        level: 2,
        coinReward: 15,
        xpReward: 10,
      ),
      const Order(
        id: 'order_2',
        chainId: 'stone',
        level: 2,
        coinReward: 20,
        xpReward: 15,
      ),
      const Order(
        id: 'order_3',
        chainId: 'flower',
        level: 1,
        coinReward: 10,
        xpReward: 5,
      ),
    ]);
  }

  bool fulfillOrder(Order order, Item item) {
    if (!order.matches(item)) return false;
    final removed = _activeOrders.remove(order);
    if (!removed) return false;

    _coins += order.coinReward;
    _xp += order.xpReward;
    _replenishOrder();
    notifyListeners();
    return true;
  }

  void _replenishOrder() {
    const chains = ['wood', 'stone', 'flower'];
    final chain = chains[DateTime.now().millisecond % chains.length];
    final level = 1 + (DateTime.now().second % 2);

    _activeOrders.add(
      Order(
        id: 'order_${DateTime.now().millisecondsSinceEpoch}',
        chainId: chain,
        level: level,
        coinReward: level * 15,
        xpReward: level * 10,
      ),
    );
  }

  Map<String, dynamic> toJson() => {'coins': _coins, 'xp': _xp};

  factory OrderManager.fromJson(Map<String, dynamic> json) {
    return OrderManager(
      initialCoins: json['coins'] as int? ?? 100,
      initialXp: json['xp'] as int? ?? 0,
    );
  }
}
