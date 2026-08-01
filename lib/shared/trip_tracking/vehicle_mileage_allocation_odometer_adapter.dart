// Converts confirmed odometer intervals into vehicle-allocation evidence.
// Owns only this one-way translation from canonical odometer history. It does
// not edit odometer events, infer GPS classification, persist allocations, or
// allocate an expense. The allocation ledger consumes its output.
// odometerIsGlobalTruth: true.

import '../odometer/odometer_mileage_review.dart';
import '../odometer/odometer_validation.dart';
import 'vehicle_mileage_allocation.dart';

/// Returns allocation evidence only for a confirmed, forward odometer delta.
///
/// Odometer corrections and events without a user mileage review are excluded:
/// they must never become financial-use evidence by implication.
VehicleMileageAllocationRecord? vehicleMileageAllocationFromOdometerEvent(
  OdometerReadingEvent event, {
  required String vehicleId,
  int sourceRevision = 0,
  DateTime? confirmedAt,
}) {
  if (!event.affectsCurrentReading ||
      event.previousReading == null ||
      event.effectiveReadingTenths < event.effectivePreviousReadingTenths! ||
      event.correctionReview != null) {
    return null;
  }
  final review = event.mileageReview;
  if (review == null || review.use == OdometerMileageUse.calibration) {
    return null;
  }
  final distanceTenths =
      event.effectiveReadingTenths - event.effectivePreviousReadingTenths!;
  final use = _allocationUseFor(review, distanceTenths);
  if (use == null) return null;
  final businessTenths = review.businessTenthsForDelta(distanceTenths);
  final occurredAt = event.recordedAt.toUtc();
  final requestedConfirmedAt = (confirmedAt ?? event.recordedAt).toUtc();
  return VehicleMileageAllocationRecord.confirmed(
    id: 'odometer-${event.id}',
    vehicleId: vehicleId,
    sourceType: event.sourceType?.trim().isNotEmpty == true
        ? event.sourceType!.trim()
        : 'odometer_event',
    sourceId: event.sourceId?.trim().isNotEmpty == true
        ? event.sourceId!.trim()
        : event.id,
    sourceRevision: sourceRevision,
    occurredAt: occurredAt,
    confirmedAt: requestedConfirmedAt.isBefore(occurredAt)
        ? occurredAt
        : requestedConfirmedAt,
    use: use,
    distanceTenths: distanceTenths,
    businessTenths: businessTenths,
  );
}

VehicleMileageAllocationUse? _allocationUseFor(
  OdometerMileageReview review,
  int deltaTenths,
) {
  switch (review.use) {
    case OdometerMileageUse.business:
      return VehicleMileageAllocationUse.business;
    case OdometerMileageUse.personal:
      return VehicleMileageAllocationUse.personal;
    case OdometerMileageUse.unresolved:
      return VehicleMileageAllocationUse.unclassified;
    case OdometerMileageUse.calibration:
      return null;
    case OdometerMileageUse.split:
      final business = review.businessTenthsForDelta(deltaTenths);
      if (business <= 0) return VehicleMileageAllocationUse.personal;
      if (business >= deltaTenths) return VehicleMileageAllocationUse.business;
      return VehicleMileageAllocationUse.split;
  }
}
