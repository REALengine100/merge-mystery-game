import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../main.dart';

class GameScreen extends StatelessWidget {
const GameScreen({super.key, required this.game});
final MergeGame game;

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: const Color(0xFF1E1B2E),
body: SafeArea(
child: Stack(
children: [
GameWidget(
game: game,
overlayBuilderMap: {
'HUD': (context, MergeGame gameInstance) => TopBarWidget(game: gameInstance),
'Orders': (context, MergeGame gameInstance) => OrderPanelWidget(game: gameInstance),
},
initialActiveOverlays: const ['HUD', 'Orders'],
),
],
),
),
);
}
}

class TopBarWidget extends StatelessWidget {
const TopBarWidget({super.key, required this.game});
final MergeGame game;

@override
Widget build(BuildContext context) {
return Padding(
padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
child: Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
ListenableBuilder(
listenable: game.orderManager,
builder: (context, _) => _infoChip(icon: Icons.monetization_on, color: Colors.amber, text: ' {game.energy.energy}/$`{game.energy.maxEnergy}'),
),
 ],
),
);
}

Widget _infoChip({required IconData icon, required Color color, required String text}) {
return Container(
padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
decoration: BoxDecoration(
color: const Color(0xFF2A2644),
borderRadius: BorderRadius.circular(20),
border: Border.all(color: color.withOpacity(0.5), width: 1.5),
),
child: Row(
children: [
Icon(icon, color: color, size: 20),
const SizedBox(width: 6),
Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
 ],
),
);
}
}

class OrderPanelWidget extends StatelessWidget {
const OrderPanelWidget({super.key, required this.game});
final MergeGame game;

@override
Widget build(BuildContext context) {
return Positioned(
top: 55,
left: 16,
right: 16,
child: SizedBox(
height: 80,
child: ListenableBuilder(
listenable: game.orderManager,
builder: (context, _) {
final orders = game.orderManager.activeOrders;
return ListView.builder(
scrollDirection: Axis.horizontal,
itemCount: orders.length,
itemBuilder: (context, index) {
final order = orders[index];
return Container(
width: 125,
margin: const EdgeInsets.only(right: 10),
padding: const EdgeInsets.all(8),
decoration: BoxDecoration(
color: const Color(0xFF2A2644).withOpacity(0.95),
borderRadius: BorderRadius.circular(12),
border: Border.all(color: Colors.purpleAccent.withOpacity(0.4)),
),
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Text('Need: ${order.chainId} L${order.level}', style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
const SizedBox(height: 4),
Text('💰 +`${order.coinReward} Coins', style: const TextStyle(color: Colors.amberAccent, fontSize: 11)),
 ],
),
);
},
);
},
),
),
);
}
}
