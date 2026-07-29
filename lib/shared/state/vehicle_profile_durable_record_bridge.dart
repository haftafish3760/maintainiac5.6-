// Shared durable-record bridge for confirmed vehicle profile snapshots.
//
// Owns versioned serialization and validation of vehicle snapshots in the
// app-wide durable record store. It does not own vehicle editing, odometers,
// Bluetooth associations, work profiles, or cloud synchronization.
// AppStateController consumes it as a recovery mirror of its confirmed data.

import '../records/maintainiac_durable_record_store.dart';

final class VehicleProfileDurableSnapshot {
  VehicleProfileDurableSnapshot({
    required List<Map<String, dynamic>> vehicles,
    required this.activeVehicleId,
  }) : vehicles = List.unmodifiable(
         vehicles.map((vehicle) => Map<String, dynamic>.unmodifiable(vehicle)),
       );

  static const schemaVersion = 1;
  static const maximumVehicleCount = 100;

  final List<Map<String, dynamic>> vehicles;
  final String? activeVehicleId;

  bool get isValid {
    if (vehicles.isEmpty || vehicles.length > maximumVehicleCount) return false;
    final ids = <String>{};
    for (final vehicle in vehicles) {
      final id = vehicle['id'];
      final nickname = vehicle['nickname'];
      if (id is! String ||
          !_safeToken(id) ||
          nickname is! String ||
          nickname.trim().isEmpty ||
          nickname.length > 120 ||
          !ids.add(id)) {
        return false;
      }
    }
    return activeVehicleId == null ||
        (ids.contains(activeVehicleId) &&
            vehicles.any(
              (vehicle) =>
                  vehicle['id'] == activeVehicleId &&
                  vehicle['archivedAt'] == null,
            ));
  }

  Map<String, dynamic> toPayload() => {
    'schemaVersion': schemaVersion,
    'vehicles': vehicles,
    'activeVehicleId': activeVehicleId,
  };

  static VehicleProfileDurableSnapshot? fromPayload(
    Map<dynamic, dynamic> payload,
  ) {
    if (payload['schemaVersion'] != schemaVersion ||
        payload['vehicles'] is! List ||
        (payload['activeVehicleId'] != null &&
            payload['activeVehicleId'] is! String)) {
      return null;
    }
    final vehicles = <Map<String, dynamic>>[];
    for (final value in payload['vehicles'] as List) {
      if (value is! Map) return null;
      vehicles.add(Map<String, dynamic>.from(value));
    }
    final snapshot = VehicleProfileDurableSnapshot(
      vehicles: vehicles,
      activeVehicleId: payload['activeVehicleId'] as String?,
    );
    return snapshot.isValid ? snapshot : null;
  }
}

final class VehicleProfileDurableRecordBridge {
  const VehicleProfileDurableRecordBridge(this.records);

  static const recordModule = 'vehicleProfiles';
  static const recordId = 'confirmedSnapshot';

  final MaintainiacDurableRecordStore records;

  VehicleProfileDurableSnapshot? load() {
    final record = records.recordFor(recordModule, recordId);
    if (record == null || !record.lifecycle.isActive) return null;
    return VehicleProfileDurableSnapshot.fromPayload(record.payload);
  }

  Future<MaintainiacDurableRecord> save(
    VehicleProfileDurableSnapshot snapshot, {
    DateTime? now,
  }) {
    if (!snapshot.isValid) {
      throw ArgumentError('Vehicle profile durable snapshot is invalid.');
    }
    final existing = records.recordFor(recordModule, recordId);
    return records.save(
      module: recordModule,
      id: recordId,
      payload: snapshot.toPayload(),
      expectedRevision: existing?.lifecycle.revision,
      now: now,
    );
  }
}

bool _safeToken(String value) =>
    value.isNotEmpty &&
    value.length <= 96 &&
    RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(value);
