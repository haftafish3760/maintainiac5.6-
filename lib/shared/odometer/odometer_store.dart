import 'package:hive_flutter/hive_flutter.dart';

import '../storage/app_storage_guard.dart';
import 'odometer_vehicle_snapshot.dart';

typedef OdometerStorageCheck = Future<AppStorageCheck> Function();

class OdometerStore {
  OdometerStore._(this._box, {OdometerStorageCheck? storageCheck})
    : _storageCheck = storageCheck ?? _defaultStorageCheck;
  OdometerStore.memory({OdometerStorageCheck? storageCheck})
    : _box = null,
      _storageCheck = storageCheck;

  static const boxName = 'vehicle_odometer_snapshots';

  final Box<dynamic>? _box;
  final OdometerStorageCheck? _storageCheck;
  final _memorySnapshots = <String, OdometerVehicleSnapshot>{};
  Future<void> _writeTail = Future<void>.value();

  static Future<OdometerStore> create({
    OdometerStorageCheck? storageCheck,
  }) async {
    final box = await Hive.openBox<dynamic>(boxName);
    return OdometerStore._(box, storageCheck: storageCheck);
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

  Future<void> saveSnapshot(OdometerVehicleSnapshot snapshot) =>
      _enqueue(() async {
        await _ensureStorageForWrite();
        if (_box == null) {
          _memorySnapshots[snapshot.vehicleId] = snapshot;
        } else {
          await _box.put(snapshot.vehicleId, snapshot.toMap());
        }
      });

  Future<void> clear() => _enqueue(() async {
    _memorySnapshots.clear();
    await _box?.clear();
  });

  static Future<AppStorageCheck> _defaultStorageCheck() =>
      AppStorageGuard.check(AppStoragePurpose.mileageTracking);

  Future<void> _ensureStorageForWrite() async {
    final check = _storageCheck;
    if (check == null) return;
    final storage = await check();
    if (!storage.hasEnoughSpace) throw StateError(storage.blockingMessage());
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final next = _writeTail.then((_) => operation());
    _writeTail = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }
}
