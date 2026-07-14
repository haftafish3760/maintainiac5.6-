import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_odometer_reconciliation.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  final review = TripTrackingReviewRecord(
    id: 'trip_reconcile',
    vehicleId: 'vehicle_1',
    startingOdometer: 1000,
    estimatedEndingOdometer: 1020,
    profile: TripTrackingProfile.roadVehicle,
    startedAt: DateTime.utc(2026, 7, 13, 12),
    finishedAt: DateTime.utc(2026, 7, 13, 14),
    engineSnapshot: const TripTrackingEngineSnapshot(
      totalAcceptedMeters: 32186.88,
      walkingReviewSuggested: false,
    ),
  );

  test('confirmed odometer remains authoritative when GPS is aligned', () {
    final result = TripOdometerReconciliation.compare(
      review: review,
      confirmedEndingOdometer: 1020,
    );

    expect(result.status, TripOdometerReconciliationStatus.aligned);
    expect(result.confirmedOdometerDeltaMiles, 20);
    expect(result.filteredGpsMiles, closeTo(20, .001));
  });

  test(
    'material GPS discrepancy is surfaced without changing odometer truth',
    () {
      final result = TripOdometerReconciliation.compare(
        review: review,
        confirmedEndingOdometer: 1035,
      );

      expect(result.status, TripOdometerReconciliationStatus.reviewRecommended);
      expect(result.confirmedOdometerDeltaMiles, 35);
      expect(result.filteredGpsMiles, closeTo(20, .001));
    },
  );

  test('a decreasing confirmed odometer is rejected as invalid', () {
    final result = TripOdometerReconciliation.compare(
      review: review,
      confirmedEndingOdometer: 999,
    );

    expect(result.status, TripOdometerReconciliationStatus.invalid);
  });
}
