import 'dart:math';
import 'package:flutter/foundation.dart';

class EnergySystem extends ChangeNotifier {
EnergySystem({
this.maxEnergy = 10,
this.regenInterval = const Duration(minutes: 2),
int? initialEnergy,
DateTime? now,
}) : assert(maxEnergy > 0),
assert(regenInterval > Duration.zero),
_energy = max(0, initialEnergy ?? maxEnergy),
_lastRegenAt = now ?? DateTime.now();

final int maxEnergy;
final Duration regenInterval;
int _energy;
DateTime _lastRegenAt;

int get energy => _energy;
bool get isFull => _energy >= maxEnergy;

bool hasEnough([int amount = 1]) => _energy >= amount;

Duration timeUntilNext([DateTime? now]) {
if (isFull) return Duration.zero;
final elapsed = (now ?? DateTime.now()).difference(_lastRegenAt);
final remaining = regenInterval - elapsed;
return remaining.isNegative ? Duration.zero : remaining;
}

bool refresh([DateTime? now]) {
final time = now ?? DateTime.now();
if (isFull) {
_lastRegenAt = time;
return false;
}
final elapsed = time.difference(_lastRegenAt);
if (elapsed.isNegative) {
_lastRegenAt = time;
return false;
}
final gained = elapsed.inMicroseconds ~/ regenInterval.inMicroseconds;
if (gained <= 0) return false;

_energy = min(maxEnergy, _energy + gained);
_lastRegenAt = isFull ? time : _lastRegenAt + regenInterval * gained;
notifyListeners();
return true;
}

bool tryConsume([int amount = 1, DateTime? now]) {
assert(amount > 0);
final time = now ?? DateTime.now();
refresh(time);
if (_energy < amount) return false;
if (isFull) _lastRegenAt = time;
_energy -= amount;
notifyListeners();
return true;
}

void add(int amount, {bool allowOverflow = false}) {
if (amount <= 0) return;
refresh();
_energy = allowOverflow ? _energy + amount : min(maxEnergy, _energy + amount);
notifyListeners();
}

Map<String, dynamic> toJson() => {
'energy': _energy,
'lastRegenAt': _lastRegenAt.toIso8601String(),
};

factory EnergySystem.fromJson(Map<String, dynamic> json, {int maxEnergy = 10, Duration regenInterval = const Duration(minutes: 2)}) {
final system = EnergySystem(
maxEnergy: maxEnergy,
regenInterval: regenInterval,
initialEnergy: json['energy'] as int,
now: DateTime.parse(json['lastRegenAt'] as String),
);
system.refresh();
return system;
}
}
