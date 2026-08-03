import '../records/maintainiac_durable_record_store.dart';
import '../records/maintainiac_record_lifecycle.dart';
import '../firebase/maintainiac_durable_cloud_backup_gateway.dart';
import '../firebase/maintainiac_firestore_upload_queue.dart';
import '../trip_tracking/vehicle_mileage_allocation.dart';

/// Durable storage adapter for the Trip Tracking-owned allocation contract.
///
/// It preserves the source record exactly as confirmed by the user. It does
/// not classify GPS, derive trip mileage, identify Bluetooth devices, or make
/// expense decisions. The shared durable-record lifecycle owns revisions,
/// timestamps, deletion state, and immutable audit metadata around it.
class VehicleMileageAllocationDurableStore {
  VehicleMileageAllocationDurableStore({
    required MaintainiacDurableRecordStore records,
  }) : _records = records;

  static const module = 'vehicleMileageAllocation';
  static const schemaVersion = 1;
  static const cloudSchemaVersions = <String, int>{module: schemaVersion};

  final MaintainiacDurableRecordStore _records;

  Future<VehicleMileageAllocationDurableRecord> save(
    VehicleMileageAllocationRecord allocation, {
    int? expectedRevision,
    DateTime? now,
  }) async {
    if (!allocation.isValid) {
      throw ArgumentError.value(
        allocation,
        'allocation',
        'Invalid allocation.',
      );
    }
    final saved = await _records.save(
      module: module,
      id: allocation.id,
      payload: _payload(allocation),
      expectedRevision: expectedRevision,
      now: now,
    );
    return VehicleMileageAllocationDurableRecord.fromDurableRecord(saved);
  }

  Future<VehicleMileageAllocationDurableRecord?> delete(
    String allocationRecordId, {
    DateTime? now,
  }) async {
    final deleted = await _records.delete(module, allocationRecordId, now: now);
    return deleted == null
        ? null
        : VehicleMileageAllocationDurableRecord.fromDurableRecord(deleted);
  }

  VehicleMileageAllocationDurableRecord? recordFor(
    String allocationRecordId, {
    bool includeDeleted = false,
  }) {
    final record = _records.recordFor(module, allocationRecordId);
    if (record == null || (!includeDeleted && record.lifecycle.isDeleted)) {
      return null;
    }
    try {
      return VehicleMileageAllocationDurableRecord.fromDurableRecord(record);
    } on FormatException {
      return null;
    }
  }

  /// Returns valid data alongside recovery issues. Nothing malformed is
  /// deleted or overwritten automatically.
  VehicleMileageAllocationDurableRecovery recover({
    bool includeDeleted = false,
  }) {
    final records = <VehicleMileageAllocationDurableRecord>[];
    final issues = <VehicleMileageAllocationDurableRecoveryIssue>[
      for (final issue in _records.integrityIssues(module: module))
        VehicleMileageAllocationDurableRecoveryIssue(
          storageKey: issue.storageKey,
          reason: 'The durable record could not be decoded.',
        ),
    ];
    for (final record in _records.recordsFor(
      module,
      includeDeleted: includeDeleted,
    )) {
      try {
        records.add(
          VehicleMileageAllocationDurableRecord.fromDurableRecord(record),
        );
      } on FormatException {
        issues.add(
          VehicleMileageAllocationDurableRecoveryIssue(
            storageKey: record.storageKey,
            reason: 'The vehicle mileage-allocation payload is malformed.',
          ),
        );
      }
    }
    return VehicleMileageAllocationDurableRecovery(
      records: records,
      issues: issues,
    );
  }

  List<VehicleMileageAllocationDurableRecord> recordsForVehicle(
    String vehicleId, {
    bool includeDeleted = false,
  }) => recover(includeDeleted: includeDeleted).records
      .where((record) => record.allocation.vehicleId == vehicleId)
      .toList(growable: false);

  /// Stages this bucket through the sole shared cloud gateway. It only writes
  /// to the local retry queue; the user-controlled sync coordinator owns any
  /// later network attempt and server-authorized Firestore commit.
  Future<List<MaintainiacFirestoreQueuedDocument>> queueForBackup({
    required MaintainiacDurableCloudBackupGateway gateway,
    required String organizationId,
    DateTime? queuedAtUtc,
  }) => gateway.queueModule(
    organizationId: organizationId,
    module: module,
    schemaVersion: schemaVersion,
    queuedAtUtc: queuedAtUtc,
  );

  /// Duplicate candidates are surfaced, never silently merged or deleted.
  /// The Trip Tracking ledger remains responsible for source-revision choice.
  List<VehicleMileageAllocationDurableDuplicateGroup> duplicateGroups() {
    final groups = <String, List<VehicleMileageAllocationDurableRecord>>{};
    for (final record in recover().records) {
      groups.putIfAbsent(record.allocation.sourceKey, () => []).add(record);
    }
    return groups.entries
        .where((entry) => entry.value.length > 1)
        .map(
          (entry) => VehicleMileageAllocationDurableDuplicateGroup(
            sourceKey: entry.key,
            records: entry.value,
          ),
        )
        .toList(growable: false);
  }

  static Map<String, dynamic> _payload(
    VehicleMileageAllocationRecord allocation,
  ) => {
    'schema': 'vehicle_mileage_allocation_durable_record_v1',
    'schemaVersion': schemaVersion,
    'dateRange': {
      'start': allocation.occurredAt.toUtc().toIso8601String(),
      'end': allocation.occurredAt.toUtc().toIso8601String(),
    },
    'reviewStatus': allocation.use.name,
    'allocation': allocation.toMap(),
  };
}

class VehicleMileageAllocationDurableRecord {
  const VehicleMileageAllocationDurableRecord({
    required this.allocation,
    required this.lifecycle,
  });

  factory VehicleMileageAllocationDurableRecord.fromDurableRecord(
    MaintainiacDurableRecord record,
  ) {
    final payload = record.payload;
    final range = payload['dateRange'];
    final allocationMap = payload['allocation'];
    if (record.module != VehicleMileageAllocationDurableStore.module ||
        payload['schema'] != 'vehicle_mileage_allocation_durable_record_v1' ||
        payload['schemaVersion'] !=
            VehicleMileageAllocationDurableStore.schemaVersion ||
        payload['reviewStatus'] is! String ||
        range is! Map ||
        range['start'] is! String ||
        range['end'] is! String ||
        allocationMap is! Map) {
      throw const FormatException(
        'Mileage allocation durable record is invalid.',
      );
    }
    final allocation = VehicleMileageAllocationRecord.fromMap(allocationMap);
    final start = DateTime.tryParse(range['start'] as String);
    final end = DateTime.tryParse(range['end'] as String);
    if (allocation == null ||
        allocation.id != record.id ||
        payload['reviewStatus'] != allocation.use.name ||
        start == null ||
        end == null ||
        !start.toUtc().isAtSameMomentAs(allocation.occurredAt.toUtc()) ||
        !end.toUtc().isAtSameMomentAs(allocation.occurredAt.toUtc())) {
      throw const FormatException(
        'Mileage allocation durable record is invalid.',
      );
    }
    return VehicleMileageAllocationDurableRecord(
      allocation: allocation,
      lifecycle: record.lifecycle,
    );
  }

  final VehicleMileageAllocationRecord allocation;
  final MaintainiacRecordLifecycle lifecycle;

  String get id => allocation.id;
}

class VehicleMileageAllocationDurableRecovery {
  VehicleMileageAllocationDurableRecovery({
    required Iterable<VehicleMileageAllocationDurableRecord> records,
    required Iterable<VehicleMileageAllocationDurableRecoveryIssue> issues,
  }) : records = List.unmodifiable(
         List<VehicleMileageAllocationDurableRecord>.from(records),
       ),
       issues = List.unmodifiable(
         List<VehicleMileageAllocationDurableRecoveryIssue>.from(issues),
       );

  final List<VehicleMileageAllocationDurableRecord> records;
  final List<VehicleMileageAllocationDurableRecoveryIssue> issues;
}

class VehicleMileageAllocationDurableRecoveryIssue {
  const VehicleMileageAllocationDurableRecoveryIssue({
    required this.storageKey,
    required this.reason,
  });

  final String storageKey;
  final String reason;
}

class VehicleMileageAllocationDurableDuplicateGroup {
  VehicleMileageAllocationDurableDuplicateGroup({
    required this.sourceKey,
    required Iterable<VehicleMileageAllocationDurableRecord> records,
  }) : records = List.unmodifiable(
         List<VehicleMileageAllocationDurableRecord>.from(records),
       );

  final String sourceKey;
  final List<VehicleMileageAllocationDurableRecord> records;
}
