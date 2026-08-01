// Revision-safe sync from confirmed odometer evidence to the allocation bucket.
//
// Owns opt-in-aware, idempotent persistence of allocation records through the
// published durable-store contract. It does not own the durable store, alter
// odometer history, classify GPS, change Expense records, or delete history.
// The app bootstrap and Dashboard projections consume this coordinator.
// odometerIsGlobalTruth: true.

import '../odometer/odometer_validation.dart';
import '../vehicle_mileage_allocation/vehicle_mileage_allocation_durable_store.dart';
import 'trip_tracking_settings_store.dart';
import 'vehicle_mileage_allocation.dart';
import 'vehicle_mileage_allocation_odometer_adapter.dart';

class VehicleMileageAllocationDurableSyncResult {
  const VehicleMileageAllocationDurableSyncResult({
    required this.savedCount,
    required this.unchangedCount,
    required this.skippedByOptIn,
    required this.rejectedCount,
    required this.failures,
  });

  final int savedCount;
  final int unchangedCount;
  final int skippedByOptIn;
  final int rejectedCount;
  final List<String> failures;

  bool get hasFailures => failures.isNotEmpty;
}

/// Synchronizes only records with an explicit mileage-use review.
///
/// A later review of the same odometer event updates the same durable ID with
/// a newer source revision. Opting out retains prior durable evidence intact
/// and prevents additional writes; it does not silently erase user history.
class VehicleMileageAllocationDurableSync {
  VehicleMileageAllocationDurableSync({
    required VehicleMileageAllocationDurableStore store,
  }) : _store = store;

  final VehicleMileageAllocationDurableStore _store;
  Future<void> _pending = Future<void>.value();

  Future<VehicleMileageAllocationDurableSyncResult> sync({
    required TripTrackingSettings settings,
    required String vehicleId,
    required Iterable<OdometerReadingEvent> history,
    DateTime? confirmedAt,
  }) {
    final operation = _pending.then(
      (_) => _syncNow(
        settings: settings,
        vehicleId: vehicleId,
        history: history,
        confirmedAt: confirmedAt,
      ),
    );
    _pending = operation.then<void>((_) {}, onError: (error, stackTrace) {});
    return operation;
  }

  Future<VehicleMileageAllocationDurableSyncResult> _syncNow({
    required TripTrackingSettings settings,
    required String vehicleId,
    required Iterable<OdometerReadingEvent> history,
    DateTime? confirmedAt,
  }) async {
    if (!settings.vehicleMileageAllocationEnabled) {
      return const VehicleMileageAllocationDurableSyncResult(
        savedCount: 0,
        unchangedCount: 0,
        skippedByOptIn: 0,
        rejectedCount: 0,
        failures: [],
      );
    }
    // A malformed durable allocation may be a recoverable historical record.
    // Do not let a new sync overwrite any allocation bucket while that record
    // needs review; the durable owner retains the original evidence intact.
    if (_store.recover().issues.isNotEmpty) {
      return const VehicleMileageAllocationDurableSyncResult(
        savedCount: 0,
        unchangedCount: 0,
        skippedByOptIn: 0,
        rejectedCount: 0,
        failures: ['durable-recovery-review-required'],
      );
    }
    var saved = 0;
    var unchanged = 0;
    var rejected = 0;
    final failures = <String>[];
    for (final event in history) {
      final id = 'odometer-${event.id}';
      final existing = _store.recordFor(id, includeDeleted: true);
      final candidate = vehicleMileageAllocationFromOdometerEvent(
        event,
        vehicleId: vehicleId,
        sourceRevision: existing?.allocation.sourceRevision ?? 0,
        confirmedAt: confirmedAt,
      );
      if (candidate == null) {
        rejected += 1;
        continue;
      }
      if (existing != null && _sameAllocation(existing.allocation, candidate)) {
        unchanged += 1;
        continue;
      }
      final next = existing == null
          ? candidate
          : _withSourceRevision(
              candidate,
              existing.allocation.sourceRevision + 1,
            );
      try {
        await _store.save(
          next,
          expectedRevision: existing?.lifecycle.revision,
          now: confirmedAt,
        );
        saved += 1;
      } catch (_) {
        failures.add(id);
      }
    }
    return VehicleMileageAllocationDurableSyncResult(
      savedCount: saved,
      unchangedCount: unchanged,
      skippedByOptIn: 0,
      rejectedCount: rejected,
      failures: List.unmodifiable(failures),
    );
  }
}

bool _sameAllocation(
  VehicleMileageAllocationRecord left,
  VehicleMileageAllocationRecord right,
) {
  final normalized = _withSourceRevision(right, left.sourceRevision);
  return left.toMap().toString() == normalized.toMap().toString();
}

VehicleMileageAllocationRecord _withSourceRevision(
  VehicleMileageAllocationRecord allocation,
  int sourceRevision,
) => VehicleMileageAllocationRecord(
  id: allocation.id,
  vehicleId: allocation.vehicleId,
  sourceType: allocation.sourceType,
  sourceId: allocation.sourceId,
  sourceRevision: sourceRevision,
  occurredAt: allocation.occurredAt,
  confirmedAt: allocation.confirmedAt,
  use: allocation.use,
  distanceTenths: allocation.distanceTenths,
  businessTenths: allocation.businessTenths,
  personalTenths: allocation.personalTenths,
  unclassifiedTenths: allocation.unclassifiedTenths,
);
