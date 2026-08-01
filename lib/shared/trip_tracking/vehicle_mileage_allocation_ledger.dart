// Deterministic aggregation and duplicate protection for vehicle mileage use.
// Owns in-memory source-revision selection and period calculations. It does
// not persist records, classify raw GPS, create expenses, or change odometer
// history. Trip review and the durable allocation repository consume it.

import 'vehicle_mileage_allocation.dart';

enum VehicleMileageAllocationIngestStatus {
  accepted,
  replacedOlderRevision,
  duplicateRevision,
  conflictingRevision,
  staleRevision,
  invalidRecord,
}

class VehicleMileageAllocationIngestResult {
  const VehicleMileageAllocationIngestResult({
    required this.status,
    required this.ledger,
  });

  final VehicleMileageAllocationIngestStatus status;
  final VehicleMileageAllocationLedger ledger;

  bool get changed =>
      status == VehicleMileageAllocationIngestStatus.accepted ||
      status == VehicleMileageAllocationIngestStatus.replacedOlderRevision;
}

class VehicleMileageAllocationLedger {
  factory VehicleMileageAllocationLedger(
    Iterable<VehicleMileageAllocationRecord> records,
  ) {
    final selection = _selectionFor(records);
    return VehicleMileageAllocationLedger._(
      selection.recordsBySource,
      selection.conflictedSourceKeys,
    );
  }

  VehicleMileageAllocationLedger.empty()
    : _recordsBySource = const {},
      _conflictedSourceKeys = const {};

  VehicleMileageAllocationLedger._(
    Map<String, VehicleMileageAllocationRecord> recordsBySource,
    Set<String> conflictedSourceKeys,
  ) : _recordsBySource = Map.unmodifiable(recordsBySource),
      _conflictedSourceKeys = Set.unmodifiable(conflictedSourceKeys);

  final Map<String, VehicleMileageAllocationRecord> _recordsBySource;
  final Set<String> _conflictedSourceKeys;

  /// Sources with conflicting payloads at the same highest revision.
  ///
  /// Their mileage is intentionally excluded until the owning evidence is
  /// reconciled. Iteration order must never decide confirmed mileage.
  Set<String> get conflictedSourceKeys => _conflictedSourceKeys;

  List<VehicleMileageAllocationRecord> get records {
    final values = _recordsBySource.values.toList(growable: false)
      ..sort((left, right) {
        final compared = left.occurredAt.compareTo(right.occurredAt);
        return compared == 0 ? left.id.compareTo(right.id) : compared;
      });
    return List.unmodifiable(values);
  }

  VehicleMileageAllocationIngestResult ingest(
    VehicleMileageAllocationRecord record,
  ) {
    if (!record.isValid) {
      return VehicleMileageAllocationIngestResult(
        status: VehicleMileageAllocationIngestStatus.invalidRecord,
        ledger: this,
      );
    }
    final existing = _recordsBySource[record.sourceKey];
    if (existing != null && existing.sourceRevision == record.sourceRevision) {
      return VehicleMileageAllocationIngestResult(
        status: _sameRecord(existing, record)
            ? VehicleMileageAllocationIngestStatus.duplicateRevision
            : VehicleMileageAllocationIngestStatus.conflictingRevision,
        ledger: this,
      );
    }
    if (existing != null && existing.sourceRevision > record.sourceRevision) {
      return VehicleMileageAllocationIngestResult(
        status: VehicleMileageAllocationIngestStatus.staleRevision,
        ledger: this,
      );
    }
    final next = Map<String, VehicleMileageAllocationRecord>.from(
      _recordsBySource,
    );
    next[record.sourceKey] = record;
    final nextConflicts = Set<String>.from(_conflictedSourceKeys)
      ..remove(record.sourceKey);
    return VehicleMileageAllocationIngestResult(
      status: existing == null
          ? VehicleMileageAllocationIngestStatus.accepted
          : VehicleMileageAllocationIngestStatus.replacedOlderRevision,
      ledger: VehicleMileageAllocationLedger._(next, nextConflicts),
    );
  }

  VehicleMileageAllocationSummary summaryFor({
    required String vehicleId,
    required DateTime from,
    required DateTime until,
  }) {
    final start = from.toUtc();
    final end = until.toUtc();
    if (!_safeToken(vehicleId) || !end.isAfter(start)) {
      return VehicleMileageAllocationSummary(
        vehicleId: vehicleId,
        from: start,
        until: end,
        businessTenths: 0,
        personalTenths: 0,
        unclassifiedTenths: 0,
        recordCount: 0,
      );
    }
    var business = 0;
    var personal = 0;
    var unclassified = 0;
    var count = 0;
    for (final record in _recordsBySource.values) {
      if (record.vehicleId != vehicleId ||
          record.occurredAt.isBefore(start) ||
          !record.occurredAt.isBefore(end)) {
        continue;
      }
      business += record.businessTenths;
      personal += record.personalTenths;
      unclassified += record.unclassifiedTenths;
      count += 1;
    }
    return VehicleMileageAllocationSummary(
      vehicleId: vehicleId,
      from: start,
      until: end,
      businessTenths: business,
      personalTenths: personal,
      unclassifiedTenths: unclassified,
      recordCount: count,
    );
  }

  static _VehicleMileageAllocationSelection _selectionFor(
    Iterable<VehicleMileageAllocationRecord> records,
  ) {
    final grouped = <String, List<VehicleMileageAllocationRecord>>{};
    for (final record in records) {
      if (!record.isValid) continue;
      grouped.putIfAbsent(record.sourceKey, () => []).add(record);
    }
    final selected = <String, VehicleMileageAllocationRecord>{};
    final conflicts = <String>{};
    for (final entry in grouped.entries) {
      final highestRevision = entry.value.fold<int>(
        -1,
        (highest, record) =>
            record.sourceRevision > highest ? record.sourceRevision : highest,
      );
      final candidates = entry.value
          .where((record) => record.sourceRevision == highestRevision)
          .toList(growable: false);
      final first = candidates.first;
      if (candidates.every((record) => _sameRecord(record, first))) {
        selected[entry.key] = first;
      } else {
        conflicts.add(entry.key);
      }
    }
    return _VehicleMileageAllocationSelection(selected, conflicts);
  }
}

class _VehicleMileageAllocationSelection {
  const _VehicleMileageAllocationSelection(
    this.recordsBySource,
    this.conflictedSourceKeys,
  );

  final Map<String, VehicleMileageAllocationRecord> recordsBySource;
  final Set<String> conflictedSourceKeys;
}

bool _sameRecord(
  VehicleMileageAllocationRecord left,
  VehicleMileageAllocationRecord right,
) =>
    left.id == right.id &&
    left.vehicleId == right.vehicleId &&
    left.sourceType == right.sourceType &&
    left.sourceId == right.sourceId &&
    left.sourceRevision == right.sourceRevision &&
    left.occurredAt == right.occurredAt &&
    left.confirmedAt == right.confirmedAt &&
    left.use == right.use &&
    left.distanceTenths == right.distanceTenths &&
    left.businessTenths == right.businessTenths &&
    left.personalTenths == right.personalTenths &&
    left.unclassifiedTenths == right.unclassifiedTenths;

bool _safeToken(String value) =>
    value.isNotEmpty &&
    value.length <= 160 &&
    RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(value);
