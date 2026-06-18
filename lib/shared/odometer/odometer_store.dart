import 'package:hive_flutter/hive_flutter.dart';

import 'odometer_vehicle_snapshot.dart';

class OdometerStore {
  OdometerStore._(this._box);
  OdometerStore.memory() : _box = null;

  static const boxName = 'vehicle_odometer_snapshots';

  final Box<dynamic>? _box;
  final _memorySnapshots = <String, OdometerVehicleSnapshot>{};

  static Future<OdometerStore> create() async {
    final box = await Hive.openBox<dynamic>(boxName);
    return OdometerStore._(box);
  }

  OdometerVehicleSnapshot snapshotForVehicle(
    String vehicleId, {
    int fallbackReading = 298150,
  }) {
    final value = _box == null
        ? _memorySnapshots[vehicleId]
        : _box.get(vehicleId);
    if (value is OdometerVehicleSnapshot) return value;
    if (value is Map) return OdometerVehicleSnapshot.fromMap(value);
    final now = DateTime.now();
    return OdometerVehicleSnapshot(
      vehicleId: vehicleId,
      currentReading: fallbackReading,
      updatedAt: now,
      history: const [],
    );
  }

  Future<OdometerVehicleSnapshot> loadSnapshotForVehicle(
    String vehicleId, {
    int fallbackReading = 298150,
  }) async {
    return snapshotForVehicle(vehicleId, fallbackReading: fallbackReading);
  }

  Future<void> saveSnapshot(OdometerVehicleSnapshot snapshot) async {
    if (_box == null) {
      _memorySnapshots[snapshot.vehicleId] = snapshot;
    } else {
      await _box.put(snapshot.vehicleId, snapshot.toMap());
    }
  }

  Future<void> clear() async {
    _memorySnapshots.clear();
    await _box?.clear();
  }
}
