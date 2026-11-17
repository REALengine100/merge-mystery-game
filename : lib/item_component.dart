import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/text.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';
import '../models/grid_model.dart';

abstract class ItemDragListener {
void onItemDragStart(ItemComponent component);
void onItemDragUpdate(ItemComponent component);
void onItemDragEnd(ItemComponent component);
void onItemDragCancel(ItemComponent component);
}

class ItemComponent extends PositionComponent with DragCallbacks {
ItemComponent({
required this.item,
required this.cell,
required this.listener,
required double extent,
}) : super(size: Vector2.all(extent), anchor: Anchor.center);

final Item item;
final ItemDragListener listener;
GridPosition cell;
bool locked = false;

bool _dragging = false;
bool get isDragging => _dragging;

static const double _liftScale = 1.12;
late final Vector2 _center = size / 2;

late final Paint _fillPaint = Paint()..color = colorFor(item);
late final Paint _glossPaint = Paint()..color = const Color(0x33FFFFFF);
late final Paint _shadowPaint = Paint()..color = const Color(0x55000000);

late final Paint _borderPaint = Paint()
..style = PaintingStyle.stroke
..strokeWidth = size.x * 0.045
..color = item.isMaxLevel ? const Color(0xFFFFD54F) : const Color(0x66FFFFFF);

late final TextPaint _levelPaint = TextPaint(
style: TextStyle(
color: const Color(0xFFFFFFFF),
fontSize: size.x * 0.42,
fontWeight: FontWeight.w800,
),
);

static Color colorFor(Item item) {
var hue = 0;
for (final unit in item.chainId.codeUnits) {
hue = (hue * 31 + unit) % 360;
}
final lightness = (0.36 + 0.03 * (item.level - 1)).clamp(0.36, 0.6);
return HSLColor.fromAHSL(1, hue.toDouble(), 0.62, lightness.toDouble()).toColor();
}

void glideTo(Vector2 destination, {double duration = 0.18, VoidCallback? onDone}) {
for (final effect in children.whereType<MoveEffect>().toList()) {
effect.removeFromParent();
}
add(
MoveEffect.to(
destination,
EffectController(duration: duration, curve: Curves.easeOutCubic),
onComplete: onDone,
),
);
}

void playPop() {
locked = true;
scale = Vector2.all(0.4);
add(
ScaleEffect.to(
Vector2.all(1),
EffectController(duration: 0.28, curve: Curves.easeOutBack),
onComplete: () => locked = false,
),
);
}

@override
void render(Canvas canvas) {
final radius = Radius.circular(size.x * 0.22);
final body = RRect.fromRectAndRadius(size.toRect(), radius);

canvas.save();
if (_dragging) {
canvas.translate(_center.x, _center.y);
canvas.scale(_liftScale);
canvas.translate(-_center.x, -_center.y);
canvas.drawRRect(body.shift(Offset(0, size.y * 0.08)), _shadowPaint);
}

canvas.drawRRect(body, _fillPaint);

final glossRect = Rect.fromLTWH(size.x * 0.08, size.y * 0.06, size.x * 0.84, size.y * 0.36);
canvas.drawRRect(RRect.fromRectAndRadius(glossRect, Radius.circular(size.x * 0.16)), _glossPaint);

canvas.drawRRect(body, _borderPaint);
_levelPaint.render(canvas, '${item.level}', _center, anchor: Anchor.center);
canvas.restore();
}

@override
void onDragStart(DragStartEvent event) {
super.onDragStart(event);
if (locked) return;
_dragging = true;
listener.onItemDragStart(this);
}

@override
void onDragUpdate(DragUpdateEvent event) {
super.onDragUpdate(event);
if (!_dragging) return;
position += event.localDelta;
listener.onItemDragUpdate(this);
}

@override
void onDragEnd(DragEndEvent event) {
super.onDragEnd(event);
if (!_dragging) return;
_dragging = false;
listener.onItemDragEnd(this);
}

@override
void onDragCancel(DragCancelEvent event) {
super.onDragCancel(event);
if (!_dragging) return;
_dragging = false;
listener.onItemDragCancel(this);
}
}
