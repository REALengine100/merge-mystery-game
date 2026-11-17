import 'dart:math';

/// Defines a merge chain (e.g. wood: level 1 -> 2 -> ... -> maxLevel).
class ItemChain {
final String id;
final String name;
final int maxLevel;

const ItemChain({
required this.id,
required this.name,
this.maxLevel = 10,
});
}

/// Registry of all merge chains. Register your own at startup.
class ItemChains {
ItemChains._();

static final Map<String, ItemChain> _chains = {
'wood': const ItemChain(id: 'wood', name: 'Wood', maxLevel: 10),
'stone': const ItemChain(id: 'stone', name: 'Stone', maxLevel: 10),
'flower': const ItemChain(id: 'flower', name: 'Flower', maxLevel: 8),
};

static void register(ItemChain chain) => _chains[chain.id] = chain;

static ItemChain get(String id) {
final chain = _chains[id];
if (chain == null) {
throw ArgumentError('Unknown item chain: $`id');
}
return chain;
}

static bool exists(String id) => _chains.containsKey(id);

static Iterable<ItemChain> get all => _chains.values;
}

/// Immutable board item. Levels start at 1.
class Item {
final int id;
final String chainId;
final int level;

const Item({
required this.id,
required this.chainId,
required this.level,
});

ItemChain get chain => ItemChains.get(chainId);

bool get isMaxLevel => level >= chain.maxLevel;

bool canMergeWith(Item other) =>
id != other.id &&
chainId == other.chainId &&
level == other.level &&
!isMaxLevel;

Item copyWith({int? id, String? chainId, int? level}) => Item(
id: id ?? this.id,
chainId: chainId ?? this.chainId,
level: level ?? this.level,
);

Map<String, dynamic> toJson() => {
'id': id,
'chainId': chainId,
'level': level,
};

factory Item.fromJson(Map<String, dynamic> json) => Item(
id: json['id'] as int,
chainId: json['chainId'] as String,
level: json['level'] as int,
);

@override
bool operator ==(Object other) =>
identical(this, other) ||
other is Item &&
other.id == id &&
other.chainId == chainId &&
other.level == level;

@override
int get hashCode => Object.hash(id, chainId, level);

@override
String toString() => 'Item(#$id $chainId L`$level)';
}

/// Immutable grid coordinate.
class GridPosition {
final int row;
final int col;

const GridPosition(this.row, this.col);

@override
bool operator ==(Object other) =>
identical(this, other) ||
other is GridPosition && other.row == row && other.col == col;

@override
int get hashCode => Object.hash(row, col);

@override
String toString() => '( col)';
}

enum MoveType { none, placed, merged, swapped }

class MoveResult {
final MoveType type;
final GridPosition? from;
final GridPosition? to;
final Item? resultItem;
final Item? displacedItem;

const MoveResult({
required this.type,
this.from,
this.to,
this.resultItem,
this.displacedItem,
});

static const MoveResult none = MoveResult(type: MoveType.none);

bool get changed => type != MoveType.none;

@override
String toString() => 'MoveResult( from ->  resultItem)';
}

/// Pure-Dart 2D grid
class GridModel {
final int rows;
final int cols;
final List<Item?> _cells;
int _nextId;

GridModel({this.rows = 7, this.cols = 7})
: assert(rows > 0 && cols > 0),
_cells = List<Item?>.filled(rows * cols, null),
_nextId = 1;

int get cellCount => rows * cols;

int get itemCount {
var count = 0;
for (final cell in _cells) {
if (cell != null) count++;
}
return count;
}

bool get isFull => itemCount == cellCount;

bool get isEmptyGrid => itemCount == 0;

bool isInBounds(GridPosition p) =>
p.row >= 0 && p.row < rows && p.col >= 0 && p.col < cols;

int _index(GridPosition p) => p.row * cols + p.col;

GridPosition _positionOf(int index) =>
GridPosition(index ~/ cols, index % cols);

void _checkBounds(GridPosition p) {
if (!isInBounds(p)) {
throw RangeError('Position  {rows}x$`cols grid');
}
}

Item? itemAt(GridPosition p) {
_checkBounds(p);
return _cells[_index(p)];
}

bool isEmpty(GridPosition p) => itemAt(p) == null;

List<GridPosition> get emptyPositions {
final result = <GridPosition>[];
for (var i = 0; i < _cells.length; i++) {
if (_cells[i] == null) result.add(_positionOf(i));
}
return result;
}

void forEachItem(void Function(GridPosition position, Item item) action) {
for (var i = 0; i < _cells.length; i++) {
final item = _cells[i];
if (item != null) action(_positionOf(i), item);
}
}

Item createItem(String chainId, {int level = 1}) {
final chain = ItemChains.get(chainId);
if (level < 1 || level > chain.maxLevel) {
throw RangeError(
'Level $level is invalid for chain "$chainId" (1..`${chain.maxLevel})',
);
}
return Item(id: _nextId++, chainId: chainId, level: level);
}

bool placeItem(Item item, GridPosition p) {
_checkBounds(p);
final i = _index(p);
if (_cells[i] != null) return false;
_cells[i] = item;
return true;
}

GridPosition? spawnRandom(String chainId, {int level = 1, Random? random}) {
final empties = emptyPositions;
if (empties.isEmpty) return null;
final rng = random ?? Random();
final position = empties[rng.nextInt(empties.length)];
placeItem(createItem(chainId, level: level), position);
return position;
}

Item? removeAt(GridPosition p) {
_checkBounds(p);
final i = _index(p);
final item = _cells[i];
_cells[i] = null;
return item;
}

void clear() {
for (var i = 0; i < _cells.length; i++) {
_cells[i] = null;
}
}

bool canMerge(GridPosition a, GridPosition b) {
if (a == b) return false;
final itemA = itemAt(a);
final itemB = itemAt(b);
if (itemA == null || itemB == null) return false;
return itemA.canMergeWith(itemB);
}

MoveResult moveItem(GridPosition from, GridPosition to) {
_checkBounds(from);
_checkBounds(to);
if (from == to) return MoveResult.none;

final source = _cells[_index(from)];
if (source == null) return MoveResult.none;
final target = _cells[_index(to)];

if (target == null) {
_cells[_index(to)] = source;
_cells[_index(from)] = null;
return MoveResult(
type: MoveType.placed,
from: from,
to: to,
resultItem: source,
);
}

if (source.canMergeWith(target)) {
final merged = Item(
id: _nextId++,
chainId: source.chainId,
level: source.level + 1,
);
_cells[_index(to)] = merged;
_cells[_index(from)] = null;
return MoveResult(
type: MoveType.merged,
from: from,
to: to,
resultItem: merged,
);
}

_cells[_index(to)] = source;
_cells[_index(from)] = target;
return MoveResult(
type: MoveType.swapped,
from: from,
to: to,
resultItem: source,
displacedItem: target,
);
}

Map<String, dynamic> toJson() => {
'rows': rows,
'cols': cols,
'nextId': _nextId,
'cells': _cells.map((item) => item?.toJson()).toList(),
};

factory GridModel.fromJson(Map<String, dynamic> json) {
final rows = json['rows'] as int;
final cols = json['cols'] as int;
final cells = json['cells'] as List<dynamic>;
if (cells.length != rows * cols) {
throw FormatException(
'Saved grid has  {rows * cols}',
);
}

final grid = GridModel(rows: rows, cols: cols);
grid._nextId = json['nextId'] as int;
for (var i = 0; i < cells.length; i++) {
final raw = cells[i];
if (raw != null) {
grid._cells[i] = Item.fromJson(raw as Map<String, dynamic>);
}
}
return grid;
}
}
