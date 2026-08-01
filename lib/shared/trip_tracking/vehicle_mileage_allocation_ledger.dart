// Deterministic aggregation and duplicate protection for vehicle mileage use.
// Owns in-memory source-revision selection and period calculations. It does
// not persist records, classify raw GPS, create expenses, or change odometer
// history. Trip review and the durable allocation repository consume it.

import 'vehicle_mileage_allocation.dart';

enum VehicleMileageAllocationIngestStatus {
  accepted,
  replacedOlderRevision,
  duplicateRevision,
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
  VehicleMileageAllocationLedger(
    Iterable<VehicleMileageAllocationRecord> records,
  ) : _recordsBySource = _recordsBySourceFor(records);

  VehicleMileageAllocationLedger.empty() : _recordsBySource = const {};

  final Map<String, VehicleMileageAllocationRecord> _recordsBySource;

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
        status: VehicleMileageAllocationIngestStatus.duplicateRevision,
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
    return VehicleMileageAllocationIngestResult(
      status: existing == null
          ? VehicleMileageAllocationIngestStatus.accepted
          : VehicleMileageAllocationIngestStatus.replacedOlderRevision,
      ledger: VehicleMileageAllocationLedger(next.values),
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

  static Map<String, VehicleMileageAllocationRecord> _recordsBySourceFor(
    Iterable<VehicleMileageAllocationRecord> records,
  ) {
    final selected = <String, VehicleMileageAllocationRecord>{};
    for (final record in records) {
      if (!record.isValid) continue;
      final existing = selected[record.sourceKey];
      if (existing == null || record.sourceRevision > existing.sourceRevision) {
        selected[record.sourceKey] = record;
      }
    }
    return Map.unmodifiable(selected);
  }
}

bool _safeToken(String value) =>
    value.isNotEmpty &&
    value.length <= 160 &&
    RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(value);
