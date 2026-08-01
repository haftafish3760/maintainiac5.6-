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
    final records = store.recordsForVehicle(vehicleId);
    final ledger = VehicleMileageAllocationLedger(
      records.map((record) => record.allocation),
    );
    final duplicateForVehicle = store.duplicateGroups().any(
      (group) => group.records.any(
        (record) => record.allocation.vehicleId == vehicleId,
      ),
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
      durableRecoveryIssueCount: store.recover().issues.length,
      duplicateSourceReviewRequired: duplicateForVehicle,
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
