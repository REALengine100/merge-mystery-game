import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/text.dart';
import 'package:flutter/painting.dart';
import '../models/grid_model.dart';
import '../systems/energy_system.dart';
import 'item_component.dart';
import 'merge_board.dart';

class SpawnerWidget extends PositionComponent with TapCallbacks {
SpawnerWidget({
required this.energy,
required this.board,
required this.chainId,
required double extent,
Vector2? position,
this.energyCost = 1,
this.spawnLevel = 1,
this.onSpawn,
this.onNoEnergy,
this.onBoardFull,
}) : super(size: Vector2.all(extent), position: position, anchor: Anchor.center);

final EnergySystem energy;
final MergeBoard board;
final String chainId;
final int energyCost;
final int spawnLevel;

final void Function(GridPosition cell)? onSpawn;
final VoidCallback? onNoEnergy;
final VoidCallback? onBoardFull;

static const double _shakeDuration = 0.3;
double _shakeTime = 0;
String _energyText = '';
String _timerText = '';

late final TextComponent _energyLabel;
late final TextComponent _timerLabel;
late final TextComponent _nameLabel;

late final Color _accent = ItemComponent.colorFor(Item(id: 0, chainId: chainId, level: 1));

late final RRect _body = RRect.fromRectAndRadius(size.toRect(), Radius.circular(size.x * 0.2));
late final RRect _icon = RRect.fromRectAndRadius(
Rect.fromCenter(center: Offset(size.x * 0.5, size.y * 0.33), width: size.x * 0.5, height: size.x * 0.5),
Radius.circular(size.x * 0.14),
);

late final Path _bolt = _buildBolt();
late final Paint _bodyPaint = Paint()..color = const Color(0xFF2A2644);
late final Paint _borderPaint = Paint()
..style = PaintingStyle.stroke
..strokeWidth = size.x * 0.03
..color = _accent;
late final Paint _iconPaint = Paint()..color = _accent;
late final Paint _plusPaint = Paint()
..color = const Color(0xFFFFFFFF)
..strokeWidth = size.x * 0.06
..strokeCap = StrokeCap.round;
late final Paint _boltPaint = Paint()..color = const Color(0xFFFFD54F);
late final Paint _dimPaint = Paint()..color = const Color(0x88000000);

@override
Future<void> onLoad() async {
_nameLabel = TextComponent(
text: ItemChains.get(chainId).name,
anchor: Anchor.center,
position: Vector2(size.x * 0.5, size.y * 0.66),
textRenderer: _text(size.x * 0.12, const Color(0xFFFFFFFF)),
);
_energyLabel = TextComponent(
text: '',
anchor: Anchor.center,
position: Vector2(size.x * 0.58, size.y * 0.80),
textRenderer: _text(size.x * 0.13, const Color(0xFFFFD54F)),
);
_timerLabel = TextComponent(
text: '',
anchor: Anchor.center,
position: Vector2(size.x * 0.5, size.y * 0.92),
textRenderer: _text(size.x * 0.09, const Color(0xFFB8B3D6)),
);
await addAll([_nameLabel, _energyLabel, _timerLabel]);
_syncLabels();
}

TextPaint _text(double fontSize, Color color) => TextPaint(
style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w800),
);

Path _buildBolt() {
final height = size.y * 0.15;
final width = height * 0.6;
final origin = Offset(size.x * 0.14, size.y * 0.725);
const points = <Offset>[
Offset(0.58, 0.0),
Offset(0.18, 0.55),
Offset(0.46, 0.55),
Offset(0.38, 1.0),
Offset(0.82, 0.40),
Offset(0.54, 0.40),
 ];
final path = Path();
for (var i = 0; i < points.length; i++) {
final x = origin.dx + points[i].dx * width;
final y = origin.dy + points[i].dy * height;
i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
}
return path..close();
}

@override
void update(double dt) {
super.update(dt);
energy.refresh();
_syncLabels();

if (_shakeTime > 0) {
_shakeTime = max(0, _shakeTime - dt);
angle = sin(_shakeTime * 60) * 0.09 * (_shakeTime / _shakeDuration);
} else if (angle != 0) {
angle = 0;
}
}

void _syncLabels() {
final energyText = ' {energy.maxEnergy}';
if (energyText != _energyText) {
_energyText = energyText;
_energyLabel.text = energyText;
}

final timerText = energy.isFull ? 'FULL' : _format(energy.timeUntilNext());
if (timerText != _timerText) {
_timerText = timerText;
_timerLabel.text = timerText;
}
}

String _format(Duration duration) {
final seconds = (duration.inMilliseconds / 1000).ceil();
final minutes = seconds ~/ 60;
return ' {(seconds % 60).toString().padLeft(2, '0')}';
}

@override
void render(Canvas canvas) {
canvas.drawRRect(_body, _bodyPaint);
canvas.drawRRect(_icon, _iconPaint);

final cx = size.x * 0.5;
final cy = size.y * 0.33;
final arm = size.x * 0.12;
canvas.drawLine(Offset(cx - arm, cy), Offset(cx + arm, cy), _plusPaint);
canvas.drawLine(Offset(cx, cy - arm), Offset(cx, cy + arm), _plusPaint);

canvas.drawPath(_bolt, _boltPaint);
canvas.drawRRect(_body, _borderPaint);

if (!energy.hasEnough(energyCost) || board.isFull) {
canvas.drawRRect(_body, _dimPaint);
}
}

@override
void onTapDown(TapDownEvent event) => scale = Vector2.all(0.94);
@override
void onTapUp(TapUpEvent event) {
scale = Vector2.all(1);
trySpawn();
}
@override
void onTapCancel(TapCancelEvent event) => scale = Vector2.all(1);

bool trySpawn() {
energy.refresh();
if (board.isFull) {
_reject();
onBoardFull?.call();
return false;
}
if (!energy.tryConsume(energyCost)) {
_reject();
onNoEnergy?.call();
return false;
}

final origin = board.absoluteToLocal(absoluteCenter);
final cell = board.spawnItemNear(chainId, nearPoint: origin, flyFrom: origin, level: spawnLevel);

if (cell == null) {
energy.add(energyCost);
_reject();
return false;
}

onSpawn?.call(cell);
return true;
}

void _reject() => _shakeTime = _shakeDuration;
}
