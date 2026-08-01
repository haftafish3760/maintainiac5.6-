// Read-only Dashboard projection for durable vehicle-use allocation evidence.
//
// Owns conversion of the published allocation bucket into a transparent
// Dashboard consumer model. It does not persist, classify mileage, edit an
// Expense, expose raw location, or change odometer history. Dashboard panels
// and an Expense-owned consumer may read this projection.

import '../../../shared/trip_tracking/trip_tracking_settings_store.dart';
import '../../../shared/trip_tracking/vehicle_mileage_allocation_ledger.dart';
import '../../../shared/trip_tracking/vehicle_mileage_allocation_read_model.dart';
import '../../../shared/vehicle_mileage_allocation/vehicle_mileage_allocation_durable_store.dart';

class VehicleMileageAllocationDashboardProjection {
  const VehicleMileageAllocationDashboardProjection({
    required this.readModel,
    required this.durableRecoveryIssueCount,
    required this.duplicateSourceReviewRequired,
  });

  factory VehicleMileageAllocationDashboardProjection.fromDurableStore({
    required VehicleMileageAllocationDurableStore store,
    required TripTrackingSettings settings,
    required String vehicleId,
    required DateTime from,
    required DateTime until,
  }) {
    // Read once so the ledger, duplicate check, and recovery warning describe
    // one coherent local snapshot.
    final recovery = store.recover();
    final start = from.toUtc();
    final end = until.toUtc();
    final records = recovery.records
        .where((record) => record.allocation.vehicleId == vehicleId)
        .toList(growable: false);
    final recordsInPeriod = records
        .where((record) {
          final occurredAt = record.allocation.occurredAt.toUtc();
          return !occurredAt.isBefore(start) && occurredAt.isBefore(end);
        })
        .toList(growable: false);
    final ledger = VehicleMileageAllocationLedger(
      recordsInPeriod.map((record) => record.allocation),
    );
    final duplicateForPeriod = _hasDuplicateSourceInPeriod(
      records: recordsInPeriod,
      from: start,
      until: end,
    );
    return VehicleMileageAllocationDashboardProjection(
      readModel: VehicleMileageAllocationReadModel.fromSummary(
        settings: settings,
        summary: ledger.summaryFor(
          vehicleId: vehicleId,
          from: from,
          until: until,
        ),
      ),
      durableRecoveryIssueCount: recovery.issues.length,
      duplicateSourceReviewRequired: duplicateForPeriod,
    );
  }

  final VehicleMileageAllocationReadModel readModel;
  final int durableRecoveryIssueCount;
  final bool duplicateSourceReviewRequired;

  bool get requiresReview =>
      duplicateSourceReviewRequired || durableRecoveryIssueCount > 0;

  double? get suggestedBusinessPercent =>
      requiresReview ? null : readModel.suggestedBusinessPercent;

  String get explanation {
    if (duplicateSourceReviewRequired) {
      return 'Duplicate vehicle-use evidence needs review before a percentage can be suggested.';
    }
    if (durableRecoveryIssueCount > 0) {
      return 'Some local vehicle-use evidence needs recovery review before a percentage can be suggested.';
    }
    return readModel.explanation;
  }
}

bool _hasDuplicateSourceInPeriod({
  required Iterable<VehicleMileageAllocationDurableRecord> records,
  required DateTime from,
  required DateTime until,
}) {
  final sourceCounts = <String, int>{};
  for (final record in records) {
    final occurredAt = record.allocation.occurredAt.toUtc();
    if (occurredAt.isBefore(from) || !occurredAt.isBefore(until)) continue;
    final sourceKey = record.allocation.sourceKey;
    final nextCount = (sourceCounts[sourceKey] ?? 0) + 1;
    if (nextCount > 1) return true;
    sourceCounts[sourceKey] = nextCount;
  }
  return false;
}
