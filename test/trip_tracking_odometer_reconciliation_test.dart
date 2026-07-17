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

  test('negative persisted GPS distance fails closed', () {
    final result = TripOdometerReconciliation.compare(
      review: TripTrackingReviewRecord(
        id: 'trip_negative_gps_distance',
        vehicleId: 'vehicle_1',
        startingOdometer: 1000,
        estimatedEndingOdometer: 1020,
        profile: TripTrackingProfile.roadVehicle,
        startedAt: DateTime.utc(2026, 7, 13, 12),
        finishedAt: DateTime.utc(2026, 7, 13, 14),
        engineSnapshot: const TripTrackingEngineSnapshot(
          totalAcceptedMeters: -1609.344,
          walkingReviewSuggested: false,
        ),
      ),
      confirmedEndingOdometer: 1020,
    );

    expect(result.status, TripOdometerReconciliationStatus.invalid);
    expect(result.filteredGpsMiles, 0);
  });

  test('invalid local review records cannot produce mileage advice', () {
    final malformed = TripTrackingReviewRecord.fromMap({
      'id': 'trip_invalid_reconcile',
      'vehicleId': 'vehicle_1',
      'startingOdometer': 1000,
      'estimatedEndingOdometer': 1020,
      'profile': 'roadVehicle',
      'engineSnapshot': {
        'totalAcceptedMeters': 32186.88,
        'walkingReviewSuggested': false,
      },
    });

    final result = TripOdometerReconciliation.compare(
      review: malformed,
      confirmedEndingOdometer: 1020,
    );

    expect(result.status, TripOdometerReconciliationStatus.invalid);
    expect(result.confirmedOdometerDeltaMiles, 0);
    expect(result.filteredGpsMiles, 0);
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

  test('odometer continuity rejects out-of-order same-vehicle timelines', () {
    final previous = review.copyWith(
      confirmedEndingOdometer: 1020,
      odometerConfirmedAt: DateTime.utc(2026, 7, 13, 14, 5),
    );
    final overlapping = TripTrackingReviewRecord(
      id: 'trip_overlap_timeline',
      vehicleId: 'vehicle_1',
      startingOdometer: 1021,
      estimatedEndingOdometer: 1030,
      profile: TripTrackingProfile.roadVehicle,
      startedAt: DateTime.utc(2026, 7, 13, 13, 30),
      finishedAt: DateTime.utc(2026, 7, 13, 15),
      engineSnapshot: const TripTrackingEngineSnapshot(
        totalAcceptedMeters: 14484.096,
        walkingReviewSuggested: false,
      ),
    );

    final check = TripOdometerContinuityCheck.betweenReviews(
      previous: previous,
      next: overlapping,
    );

    expect(check.status, TripOdometerContinuityStatus.invalid);
    expect(check.shouldBlockConfirmation, isTrue);
    expect(check.reasonCode, 'invalid_odometer_continuity_input');
  });

  test('odometer continuity rejects malformed same-vehicle records', () {
    final previous = TripTrackingReviewRecord(
      id: '   ',
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
      confirmedEndingOdometer: 1020,
      odometerConfirmedAt: DateTime.utc(2026, 7, 13, 14, 5),
    );
    final next = TripTrackingReviewRecord(
      id: 'trip_after_malformed',
      vehicleId: 'vehicle_1',
      startingOdometer: 1020,
      estimatedEndingOdometer: 1030,
      profile: TripTrackingProfile.roadVehicle,
      startedAt: DateTime.utc(2026, 7, 13, 14, 10),
      finishedAt: DateTime.utc(2026, 7, 13, 15),
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
    expect(check.reasonCode, 'invalid_odometer_continuity_input');
  });

  test('odometer continuity rejects premature prior confirmations', () {
    final previous = review.copyWith(
      confirmedEndingOdometer: 1020,
      odometerConfirmedAt: DateTime.utc(2026, 7, 13, 13, 59),
    );
    final next = TripTrackingReviewRecord(
      id: 'trip_after_premature_confirmation',
      vehicleId: 'vehicle_1',
      startingOdometer: 1020,
      estimatedEndingOdometer: 1030,
      profile: TripTrackingProfile.roadVehicle,
      startedAt: DateTime.utc(2026, 7, 13, 14, 10),
      finishedAt: DateTime.utc(2026, 7, 13, 15),
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
    expect(check.reasonCode, 'invalid_odometer_continuity_input');
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
          filteredGpsMiles: double.nan,
          absoluteDifferenceMiles: 6,
          differencePercent: 6,
        ),
        TripOdometerReconciliation(
          status: TripOdometerReconciliationStatus.reviewRecommended,
          confirmedOdometerDeltaMiles: -100,
          filteredGpsMiles: 94,
          absoluteDifferenceMiles: 6,
          differencePercent: 6,
        ),
      ],
    );

    expect(signal.status, TripOdometerCalibrationStatus.insufficientHistory);
    expect(signal.eligibleSampleCount, 0);
  });

  test(
    'calibration recomputes drift instead of trusting stored percentages',
    () {
      final history = List.generate(
        7,
        (_) => const TripOdometerReconciliation(
          status: TripOdometerReconciliationStatus.reviewRecommended,
          confirmedOdometerDeltaMiles: 100,
          filteredGpsMiles: 50,
          absoluteDifferenceMiles: 50,
          differencePercent: 1,
        ),
      );

      final signal = TripOdometerCalibrationSignal.evaluate(history: history);

      expect(signal.status, TripOdometerCalibrationStatus.insufficientHistory);
      expect(signal.eligibleSampleCount, 0);
      expect(signal.reasonCode, 'needs_more_reviewed_days');
    },
  );

  test('calibration ignores extreme reviewed outliers', () {
    final history = [
      ...List.generate(
        7,
        (_) => const TripOdometerReconciliation(
          status: TripOdometerReconciliationStatus.reviewRecommended,
          confirmedOdometerDeltaMiles: 100,
          filteredGpsMiles: 94,
          absoluteDifferenceMiles: 6,
          differencePercent: 6,
        ),
      ),
      const TripOdometerReconciliation(
        status: TripOdometerReconciliationStatus.reviewRecommended,
        confirmedOdometerDeltaMiles: 100,
        filteredGpsMiles: 2,
        absoluteDifferenceMiles: 98,
        differencePercent: 98,
      ),
    ];

    final signal = TripOdometerCalibrationSignal.evaluate(history: history);

    expect(signal.status, TripOdometerCalibrationStatus.reviewRecommended);
    expect(signal.eligibleSampleCount, 7);
    expect(signal.averageGpsToOdometerRatio, closeTo(.94, .001));
    expect(signal.gpsAssistanceCalibrationMultiplier, closeTo(1.0638, .001));
  });

  test('calibration rejects non-finite thresholds', () {
    final signal = TripOdometerCalibrationSignal.evaluate(
      history: const [],
      minimumOdometerMiles: double.infinity,
    );
    final percentSignal = TripOdometerCalibrationSignal.evaluate(
      history: const [],
      reviewDifferencePercent: double.nan,
    );
    final outlierSignal = TripOdometerCalibrationSignal.evaluate(
      history: const [],
      maximumEligibleDifferencePercent: 3,
    );

    expect(signal.status, TripOdometerCalibrationStatus.insufficientHistory);
    expect(signal.reasonCode, 'invalid_calibration_threshold');
    expect(
      percentSignal.status,
      TripOdometerCalibrationStatus.insufficientHistory,
    );
    expect(percentSignal.reasonCode, 'invalid_calibration_threshold');
    expect(
      outlierSignal.status,
      TripOdometerCalibrationStatus.insufficientHistory,
    );
    expect(outlierSignal.reasonCode, 'invalid_calibration_threshold');
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

  test(
    'calibration multiplier is bounded against extreme advisory signals',
    () {
      const lowGpsSignal = TripOdometerCalibrationSignal(
        status: TripOdometerCalibrationStatus.reviewRecommended,
        eligibleSampleCount: 7,
        averageGpsToOdometerRatio: .2,
        averageDifferencePercent: 80,
        reasonCode: 'extreme_low_gps_signal',
      );
      const highGpsSignal = TripOdometerCalibrationSignal(
        status: TripOdometerCalibrationStatus.reviewRecommended,
        eligibleSampleCount: 7,
        averageGpsToOdometerRatio: 2,
        averageDifferencePercent: 100,
        reasonCode: 'extreme_high_gps_signal',
      );

      expect(lowGpsSignal.gpsAssistanceCalibrationMultiplier, 1.25);
      expect(highGpsSignal.gpsAssistanceCalibrationMultiplier, .8);
      expect(lowGpsSignal.canOverwriteConfirmedOdometer, isFalse);
      expect(highGpsSignal.canOverwriteConfirmedOdometer, isFalse);
    },
  );
}
