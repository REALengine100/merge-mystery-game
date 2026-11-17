import 'dart:ui';
import 'package:flame/components.dart';
import '../models/grid_model.dart';
import 'item_component.dart';

typedef MoveCallback = void Function(MoveResult result);

class MergeBoard extends PositionComponent implements ItemDragListener {
MergeBoard({
required this.grid,
required this.cellSize,
this.allowSwap = false,
this.onMove,
}) : super(size: Vector2(grid.cols * cellSize, grid.rows * cellSize));

final GridModel grid;
final double cellSize;
final bool allowSwap;
final MoveCallback? onMove;

static const int _dragPriority = 100;
static const int _restPriority = 0;

final Map<int, ItemComponent> _components = {};
final Set<GridPosition> _busyCells = {};

GridPosition? _hoverCell;
bool _hoverValid = false;

final Paint _cellLightPaint = Paint()..color = const Color(0xFF3A3556);
final Paint _cellDarkPaint = Paint()..color = const Color(0xFF302C49);
final Paint _validPaint = Paint()..color = const Color(0x6643D17A);
final Paint _invalidPaint = Paint()..color = const Color(0x55E0524D);

@override
Future<void> onLoad() async {
grid.forEachItem((position, item) {
_addItemComponent(item, position);
});
}

bool get isFull => grid.isFull;

GridPosition? spawnItem(String chainId, {int level = 1}) {
final position = grid.spawnRandom(chainId, level: level);
if (position == null) return null;
_addItemComponent(grid.itemAt(position)!, position).playPop();
return position;
}

GridPosition? spawnItemNear(
String chainId, {
required Vector2 nearPoint,
Vector2? flyFrom,
int level = 1,
}) {
final cell = nearestEmptyCell(nearPoint);
if (cell == null) return null;

final item = grid.createItem(chainId, level: level);
grid.placeItem(item, cell);

final component = _addItemComponent(item, cell, startPosition: flyFrom);
component.playPop();
if (flyFrom != null) {
component.glideTo(cellCenter(cell), duration: 0.28);
}
return cell;
}

GridPosition? nearestEmptyCell(Vector2 point) {
GridPosition? best;
var bestDistance = double.infinity;

for (final cell in grid.emptyPositions) {
final center = cellCenter(cell);
final dx = center.x - point.x;
final dy = center.y - point.y;
final distance = dx * dx + dy * dy;
if (distance < bestDistance) {
bestDistance = distance;
best = cell;
}
}
return best;
}

Vector2 cellCenter(GridPosition cell) => Vector2(
(cell.col + 0.5) * cellSize,
(cell.row + 0.5) * cellSize,
);

GridPosition? cellAtPoint(Vector2 point) {
final col = (point.x / cellSize).floor();
final row = (point.y / cellSize).floor();
final cell = GridPosition(row, col);
return grid.isInBounds(cell) ? cell : null;
}

@override
void render(Canvas canvas) {
final inset = cellSize * 0.04;
final radius = Radius.circular(cellSize * 0.18);

for (var row = 0; row < grid.rows; row++) {
for (var col = 0; col < grid.cols; col++) {
final rect = Rect.fromLTWH(
col * cellSize + inset,
row * cellSize + inset,
cellSize - inset * 2,
cellSize - inset * 2,
);
final paint = (row + col).isEven ? _cellLightPaint : _cellDarkPaint;
canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), paint);
}
}

final hover = _hoverCell;
if (hover != null) {
final rect = Rect.fromLTWH(
hover.col * cellSize + inset,
hover.row * cellSize + inset,
cellSize - inset * 2,
cellSize - inset * 2,
);
canvas.drawRRect(
RRect.fromRectAndRadius(rect, radius),
_hoverValid ? _validPaint : _invalidPaint,
);
}
}

@override
void onItemDragStart(ItemComponent component) {
component.priority = _dragPriority;
_updateHover(component);
}

@override
void onItemDragUpdate(ItemComponent component) {
_updateHover(component);
}

@override
void onItemDragEnd(ItemComponent component) {
_clearHover();
component.priority = _restPriority;

final from = component.cell;
final to = cellAtPoint(component.position);

final stillValid = grid.itemAt(from) == component.item;
if (!stillValid || to == null || to == from || !_isValidDrop(from, to)) {
_snapBack(component);
return;
}

_commitMove(component, from, to);
}

@override
void onItemDragCancel(ItemComponent component) {
_clearHover();
component.priority = _restPriority;
_snapBack(component);
}

bool _isValidDrop(GridPosition from, GridPosition to) {
if (from == to) return false;
if (_busyCells.contains(to)) return false;
final targetItem = grid.itemAt(to);
if (targetItem != null && (_components[targetItem.id]?.locked ?? false)) {
return false;
}
return targetItem == null || grid.canMerge(from, to) || allowSwap;
}

void _updateHover(ItemComponent component) {
final cell = cellAtPoint(component.position);
if (cell == null || cell == component.cell) {
_clearHover();
return;
}
_hoverCell = cell;
_hoverValid = _isValidDrop(component.cell, cell);
}

void _clearHover() {
_hoverCell = null;
_hoverValid = false;
}

void _snapBack(ItemComponent component) {
_glideToCell(component, duration: 0.2);
}

void _glideToCell(ItemComponent component, {double duration = 0.18}) {
component.locked = true;
component.glideTo(
cellCenter(component.cell),
duration: duration,
onDone: () => component.locked = false,
);
}

void _commitMove(ItemComponent source, GridPosition from, GridPosition to) {
final targetItem = grid.itemAt(to);
final target = targetItem == null ? null : _components[targetItem.id];
final result = grid.moveItem(from, to);

switch (result.type) {
case MoveType.placed:
source.cell = to;
_glideToCell(source);
case MoveType.merged:
_playMerge(source, target, result);
case MoveType.swapped:
source.cell = to;
if (target != null) target.cell = from;
_glideToCell(source);
if (target != null) _glideToCell(target);
case MoveType.none:
_snapBack(source);
return;
}

onMove?.call(result);
}

void _playMerge(ItemComponent source, ItemComponent? target, MoveResult result) {
final to = result.to!;
final mergedItem = result.resultItem!;

_busyCells.add(to);
source.locked = true;
target?.locked = true;

source.glideTo(
cellCenter(to),
duration: 0.12,
onDone: () {
_removeComponent(source);
if (target != null) _removeComponent(target);
_addItemComponent(mergedItem, to).playPop();
_busyCells.remove(to);
},
);
}

ItemComponent _addItemComponent(Item item, GridPosition cell, {Vector2? startPosition}) {
final component = ItemComponent(
item: item,
cell: cell,
listener: this,
extent: cellSize * 0.86,
)
..position = startPosition ?? cellCenter(cell)
..priority = _restPriority;
_components[item.id] = component;
add(component);
return component;
}

void _removeComponent(ItemComponent component) {
_components.remove(component.item.id);
component.removeFromParent();
}
}
