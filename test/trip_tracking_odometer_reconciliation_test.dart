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

  test('non-finite reconciliation thresholds fail closed', () {
    final result = TripOdometerReconciliation.compare(
      review: review,
      confirmedEndingOdometer: 1020,
      materialDifferenceMiles: double.nan,
    );

    expect(result.status, TripOdometerReconciliationStatus.invalid);
  });

  test('a next trip cannot start below the previous confirmed ending', () {
    final previous = review.copyWith(
      confirmedEndingOdometer: 1020,
      odometerConfirmedAt: DateTime.utc(2026, 7, 13, 14, 5),
    );
    final next = TripTrackingReviewRecord(
      id: 'trip_next_overlap',
      vehicleId: 'vehicle_1',
      startingOdometer: 1019,
      estimatedEndingOdometer: 1030,
      profile: TripTrackingProfile.roadVehicle,
      startedAt: DateTime.utc(2026, 7, 14, 12),
      finishedAt: DateTime.utc(2026, 7, 14, 14),
      engineSnapshot: const TripTrackingEngineSnapshot(
        totalAcceptedMeters: 16093.44,
        walkingReviewSuggested: false,
      ),
    );

    final check = TripOdometerContinuityCheck.betweenReviews(
      previous: previous,
      next: next,
    );

    expect(check.status, TripOdometerContinuityStatus.invalid);
    expect(check.shouldBlockConfirmation, isTrue);
    expect(check.odometerGapMiles, -1);
    expect(
      check.reasonCode,
      'starting_odometer_below_previous_confirmed_ending',
    );
  });

  test('a large untracked same-vehicle odometer gap recommends review', () {
    final previous = review.copyWith(
      confirmedEndingOdometer: 1020,
      odometerConfirmedAt: DateTime.utc(2026, 7, 13, 14, 5),
    );
    final next = TripTrackingReviewRecord(
      id: 'trip_next_gap',
      vehicleId: 'vehicle_1',
      startingOdometer: 1100,
      estimatedEndingOdometer: 1110,
      profile: TripTrackingProfile.roadVehicle,
      startedAt: DateTime.utc(2026, 7, 14, 12),
      finishedAt: DateTime.utc(2026, 7, 14, 14),
      engineSnapshot: const TripTrackingEngineSnapshot(
        totalAcceptedMeters: 16093.44,
        walkingReviewSuggested: false,
      ),
    );

    final check = TripOdometerContinuityCheck.betweenReviews(
      previous: previous,
      next: next,
      materialUntrackedGapMiles: 50,
    );

    expect(check.status, TripOdometerContinuityStatus.reviewRecommended);
    expect(check.shouldBlockConfirmation, isFalse);
    expect(check.odometerGapMiles, 80);
    expect(check.reasonCode, 'large_untracked_odometer_gap');
  });

  test('odometer continuity ignores other vehicles and normal gaps', () {
    final previous = review.copyWith(
      confirmedEndingOdometer: 1020,
      odometerConfirmedAt: DateTime.utc(2026, 7, 13, 14, 5),
    );
    final otherVehicle = TripTrackingReviewRecord(
      id: 'trip_other_vehicle',
      vehicleId: 'vehicle_2',
      startingOdometer: 1,
      estimatedEndingOdometer: 20,
      profile: TripTrackingProfile.roadVehicle,
      startedAt: DateTime.utc(2026, 7, 14, 12),
      finishedAt: DateTime.utc(2026, 7, 14, 14),
      engineSnapshot: const TripTrackingEngineSnapshot(
        totalAcceptedMeters: 16093.44,
        walkingReviewSuggested: false,
      ),
    );
    final aligned = TripTrackingReviewRecord(
      id: 'trip_aligned_vehicle',
      vehicleId: 'vehicle_1',
      startingOdometer: 1025,
      estimatedEndingOdometer: 1035,
      profile: TripTrackingProfile.roadVehicle,
      startedAt: DateTime.utc(2026, 7, 14, 12),
      finishedAt: DateTime.utc(2026, 7, 14, 14),
      engineSnapshot: const TripTrackingEngineSnapshot(
        totalAcceptedMeters: 16093.44,
        walkingReviewSuggested: false,
      ),
    );

    expect(
      TripOdometerContinuityCheck.betweenReviews(
        previous: previous,
        next: otherVehicle,
      ).status,
      TripOdometerContinuityStatus.insufficientData,
    );
    expect(
      TripOdometerContinuityCheck.betweenReviews(
        previous: previous,
        next: aligned,
      ).status,
      TripOdometerContinuityStatus.aligned,
    );
  });

  test(
    'persistent seven-day GPS odometer drift recommends calibration review',
    () {
      final history = List.generate(
        7,
        (_) => const TripOdometerReconciliation(
          status: TripOdometerReconciliationStatus.reviewRecommended,
          confirmedOdometerDeltaMiles: 100,
          filteredGpsMiles: 94,
          absoluteDifferenceMiles: 6,
          differencePercent: 6,
        ),
      );

      final signal = TripOdometerCalibrationSignal.evaluate(history: history);

      expect(signal.status, TripOdometerCalibrationStatus.reviewRecommended);
      expect(signal.eligibleSampleCount, 7);
      expect(signal.averageGpsToOdometerRatio, closeTo(.94, .001));
      expect(signal.gpsAssistanceCalibrationMultiplier, closeTo(1.0638, .001));
      expect(signal.reasonCode, 'persistent_gps_odometer_drift');
      expect(signal.canOverwriteConfirmedOdometer, isFalse);
    },
  );

  test('calibration waits for enough reviewed driving days', () {
    final signal = TripOdometerCalibrationSignal.evaluate(
      history: const [
        TripOdometerReconciliation(
          status: TripOdometerReconciliationStatus.reviewRecommended,
          confirmedOdometerDeltaMiles: 100,
          filteredGpsMiles: 94,
          absoluteDifferenceMiles: 6,
          differencePercent: 6,
        ),
      ],
    );

    expect(signal.status, TripOdometerCalibrationStatus.insufficientHistory);
    expect(signal.reasonCode, 'needs_more_reviewed_days');
  });

  test('mixed drift directions do not trigger a tire-size style warning', () {
    final history = List.generate(7, (index) {
      final gpsMiles = index.isEven ? 94.0 : 106.0;
      return TripOdometerReconciliation(
        status: TripOdometerReconciliationStatus.reviewRecommended,
        confirmedOdometerDeltaMiles: 100,
        filteredGpsMiles: gpsMiles,
        absoluteDifferenceMiles: 6,
        differencePercent: 6,
      );
    });

    final signal = TripOdometerCalibrationSignal.evaluate(history: history);

    expect(signal.status, TripOdometerCalibrationStatus.stable);
    expect(signal.reasonCode, 'calibration_stable');
  });

  test('calibration ignores non-finite reviewed history values', () {
    final signal = TripOdometerCalibrationSignal.evaluate(
      history: const [
        TripOdometerReconciliation(
          status: TripOdometerReconciliationStatus.reviewRecommended,
          confirmedOdometerDeltaMiles: double.infinity,
          filteredGpsMiles: 94,
          absoluteDifferenceMiles: 6,
          differencePercent: 6,
        ),
        TripOdometerReconciliation(
          status: TripOdometerReconciliationStatus.reviewRecommended,
          confirmedOdometerDeltaMiles: 100,
          filteredGpsMiles: 94,
          absoluteDifferenceMiles: 6,
          differencePercent: double.nan,
        ),
      ],
    );

    expect(signal.status, TripOdometerCalibrationStatus.insufficientHistory);
    expect(signal.eligibleSampleCount, 0);
  });

  test('calibration multiplier falls back safely for malformed signals', () {
    const signal = TripOdometerCalibrationSignal(
      status: TripOdometerCalibrationStatus.reviewRecommended,
      eligibleSampleCount: 7,
      averageGpsToOdometerRatio: double.nan,
      averageDifferencePercent: 6,
      reasonCode: 'malformed_external_signal',
    );

    expect(signal.gpsAssistanceCalibrationMultiplier, 1);
    expect(signal.canOverwriteConfirmedOdometer, isFalse);
  });
}
