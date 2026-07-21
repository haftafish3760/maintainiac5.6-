import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_odometer_calibration.dart';
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
      expect(result.toSafeDashboardMap(), {
        'schemaVersion': 1,
        'status': 'reviewRecommended',
        'confirmedOdometerDeltaMiles': 35.0,
        'filteredGpsMiles': 20.0,
        'absoluteDifferenceMiles': 15.0,
        'differencePercent': 42.9,
        'shouldPromptUser': true,
        'userReviewRequiredBeforeChange': true,
        'odometerRemainsCanonical': true,
        'odometerIsGlobalTruth': true,
        'gpsCanReplaceOdometer': false,
        'gpsCanSetGlobalTruth': false,
        'gpsCanChangeOfficialMileage': false,
        'mapboxCanReplaceOdometer': false,
        'mapboxCanSetGlobalTruth': false,
        'mapboxCanChangeOfficialMileage': false,
        'calibrationCanApplySilently': false,
        'externalMileageTrustedAfterValidationOnly': true,
        'remoteTotalsCanBecomeCanonical': false,
        'remoteTotalsCanConfirmOdometer': false,
        'remoteTotalsCanSetGlobalTruth': false,
        'remoteTotalsCanChangeOfficialMileage': false,
        'mapboxRouteCanConfirmOdometer': false,
        'firestoreCanOverrideOdometerTruth': false,
        'mapboxCanOverrideOdometerTruth': false,
        'rawLocationIncluded': false,
        'rawTripRecordsIncluded': false,
        'tokensIncluded': false,
      });
    },
  );

  test('a decreasing confirmed odometer is rejected as invalid', () {
    final result = TripOdometerReconciliation.compare(
      review: review,
      confirmedEndingOdometer: 999,
    );

    expect(result.status, TripOdometerReconciliationStatus.invalid);
  });

  test(
    'live odometer entry validation blocks impossible decreasing entries',
    () {
      final validation = TripOdometerEntryValidation.validate(
        startingOdometer: 1020,
        endingOdometer: 1019,
        previousConfirmedEndingOdometer: 1010,
        averageDailyMiles: 40,
      );
      final summary = validation.toSafeDashboardMap();

      expect(validation.status, TripOdometerEntryValidationStatus.invalid);
      expect(validation.shouldBlockConfirmation, isTrue);
      expect(validation.reasonCode, 'ending_odometer_below_starting_odometer');
      expect(summary['reasonCode'], 'ending_odometer_below_starting_odometer');
      expect(summary['shouldBlockConfirmation'], isTrue);
      expect(summary['odometerRemainsCanonical'], isTrue);
      expect(summary['gpsCanCorrectEntryAutomatically'], isFalse);
      expect(summary['mapboxCanCorrectEntryAutomatically'], isFalse);
      expect(summary['remoteBackupCanCorrectEntryAutomatically'], isFalse);
    },
  );

  test('live odometer entry validation blocks rollback from prior day', () {
    final validation = TripOdometerEntryValidation.validate(
      startingOdometer: 1019,
      endingOdometer: 1030,
      previousConfirmedEndingOdometer: 1020,
    );

    expect(validation.status, TripOdometerEntryValidationStatus.invalid);
    expect(validation.shouldPromptUser, isTrue);
    expect(
      validation.reasonCode,
      'starting_odometer_below_previous_confirmed_ending',
    );
    expect(validation.toSafeDashboardMap()['rawTripRecordsIncluded'], isFalse);
  });

  test('live odometer entry validation reviews large gaps and anomalies', () {
    final gap = TripOdometerEntryValidation.validate(
      startingOdometer: 1100,
      endingOdometer: 1120,
      previousConfirmedEndingOdometer: 1020,
      averageDailyMiles: 40,
    );
    final high = TripOdometerEntryValidation.validate(
      startingOdometer: 1020,
      endingOdometer: 1200,
      previousConfirmedEndingOdometer: 1020,
      averageDailyMiles: 40,
    );
    final low = TripOdometerEntryValidation.validate(
      startingOdometer: 1020,
      endingOdometer: 1040,
      previousConfirmedEndingOdometer: 1020,
      averageDailyMiles: 100,
    );

    expect(gap.status, TripOdometerEntryValidationStatus.reviewRecommended);
    expect(gap.reasonCode, 'large_untracked_odometer_gap');
    expect(high.status, TripOdometerEntryValidationStatus.reviewRecommended);
    expect(high.reasonCode, 'unusually_high_odometer_delta');
    expect(low.status, TripOdometerEntryValidationStatus.reviewRecommended);
    expect(low.reasonCode, 'unusually_low_odometer_delta');
    expect(high.shouldBlockConfirmation, isFalse);
    expect(low.toSafeDashboardMap()['manualReviewRequired'], isTrue);
  });

  test('live odometer entry validation accepts ordinary entries', () {
    final validation = TripOdometerEntryValidation.validate(
      startingOdometer: 1020,
      endingOdometer: 1060,
      previousConfirmedEndingOdometer: 1020,
      averageDailyMiles: 40,
    );

    expect(validation.status, TripOdometerEntryValidationStatus.valid);
    expect(validation.shouldPromptUser, isFalse);
    expect(validation.deltaMiles, 40);
    expect(validation.reasonCode, 'odometer_entry_validated');
    expect(validation.toSafeDashboardMap()['rawLocationIncluded'], isFalse);
  });

  test('near-zero odometer after meaningful GPS movement requires review', () {
    final validation = TripOdometerEntryValidation.validate(
      startingOdometer: 1020,
      endingOdometer: 1020,
      gpsAssistedDistanceMeters: 25 * 1609.344,
    );

    expect(
      validation.status,
      TripOdometerEntryValidationStatus.reviewRecommended,
    );
    expect(
      validation.reasonCode,
      'near_zero_odometer_after_meaningful_gps_movement',
    );
    expect(validation.shouldBlockConfirmation, isFalse);
    expect(
      validation.toSafeDashboardMap()['gpsCanCorrectEntryAutomatically'],
      isFalse,
    );
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
    expect(check.toSafeDashboardMap(), {
      'schemaVersion': 1,
      'status': 'invalid',
      'odometerGapMiles': -1,
      'reasonCode': 'starting_odometer_below_previous_confirmed_ending',
      'shouldBlockConfirmation': true,
      'shouldPromptUser': true,
      'manualReviewRequired': true,
      'odometerRemainsCanonical': true,
      'odometerIsGlobalTruth': true,
      'gpsCanFillGapAutomatically': false,
      'gpsCanSetGlobalTruth': false,
      'gpsCanChangeOfficialMileage': false,
      'mapboxCanFillGapAutomatically': false,
      'mapboxCanSetGlobalTruth': false,
      'mapboxCanChangeOfficialMileage': false,
      'remoteBackupCanFillGapAutomatically': false,
      'continuityTrustedAfterValidationOnly': true,
      'firestoreCanOverrideContinuity': false,
      'mapboxCanOverrideContinuity': false,
      'remoteContinuityCanConfirmOdometer': false,
      'remoteContinuityCanSetGlobalTruth': false,
      'remoteContinuityCanChangeOfficialMileage': false,
      'userReviewRequiredBeforeGapAcceptance': true,
      'rawTripRecordsIncluded': false,
      'rawLocationIncluded': false,
      'tokensIncluded': false,
    });
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

  test('odometer continuity normalizes legacy padded vehicle ids', () {
    final previous = TripTrackingReviewRecord(
      id: 'trip_previous_padded_vehicle',
      vehicleId: ' vehicle_1 ',
      startingOdometer: 1000,
      estimatedEndingOdometer: 1020,
      confirmedEndingOdometer: 1020,
      odometerConfirmedAt: DateTime.utc(2026, 7, 13, 14, 5),
      profile: TripTrackingProfile.roadVehicle,
      startedAt: DateTime.utc(2026, 7, 13, 12),
      finishedAt: DateTime.utc(2026, 7, 13, 14),
      engineSnapshot: const TripTrackingEngineSnapshot(
        totalAcceptedMeters: 20 * 1609.344,
        walkingReviewSuggested: false,
      ),
    );
    final next = TripTrackingReviewRecord(
      id: 'trip_next_padded_vehicle',
      vehicleId: 'vehicle_1',
      startingOdometer: 1025,
      estimatedEndingOdometer: 1035,
      profile: TripTrackingProfile.roadVehicle,
      startedAt: DateTime.utc(2026, 7, 14, 12),
      finishedAt: DateTime.utc(2026, 7, 14, 14),
      engineSnapshot: const TripTrackingEngineSnapshot(
        totalAcceptedMeters: 10 * 1609.344,
        walkingReviewSuggested: false,
      ),
    );

    final check = TripOdometerContinuityCheck.betweenReviews(
      previous: previous,
      next: next,
    );

    expect(check.status, TripOdometerContinuityStatus.aligned);
    expect(check.odometerGapMiles, 5);
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
      expect(
        signal.toSafeDashboardMap()['calibrationRequiresUserOptIn'],
        isTrue,
      );
      expect(
        signal.toSafeDashboardMap()['calibrationRequiresMultipleReviewedTrips'],
        isTrue,
      );
      expect(
        signal.toSafeDashboardMap()['poorGpsDaysExcludedFromCalibration'],
        isTrue,
      );
      expect(
        signal.toSafeDashboardMap()['calibrationRequiresTrustedGpsWindow'],
        isTrue,
      );
      expect(
        signal.toSafeDashboardMap()['calibrationCanRewritePastTrips'],
        isFalse,
      );
      expect(signal.toSafeDashboardMap()['canApplySilently'], isFalse);
      expect(signal.toSafeDashboardMap()['tireSizeReviewSuggested'], isTrue);
      expect(
        signal.toSafeDashboardMap()['speedometerCalibrationReviewSuggested'],
        isTrue,
      );
      expect(
        signal.toSafeDashboardMap()['remoteHistoryCanCreateCalibration'],
        isFalse,
      );
      expect(
        signal.toSafeDashboardMap()['mapboxRouteCanCreateCalibration'],
        isFalse,
      );
      expect(
        signal.toSafeDashboardMap()['gpsAssistanceCalibrationMultiplier'],
        1.0638,
      );
      expect(signal.toSafeDashboardMap()['odometerRemainsCanonical'], isTrue);
      expect(signal.toSafeDashboardMap()['odometerIsGlobalTruth'], isTrue);
      expect(signal.toSafeDashboardMap()['rawLocationIncluded'], isFalse);
      expect(signal.toSafeDashboardMap()['tokensIncluded'], isFalse);
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

  test('calibration history is built only from confirmed odometer reviews', () {
    final confirmedAt = DateTime.utc(2026, 7, 14, 12);
    final reviews = [
      ...List.generate(
        7,
        (index) => TripTrackingReviewRecord(
          id: 'trip_confirmed_$index',
          vehicleId: 'vehicle_1',
          startingOdometer: 1000 + (index * 100),
          estimatedEndingOdometer: 1100 + (index * 100),
          confirmedEndingOdometer: 1100 + (index * 100),
          odometerConfirmedAt: confirmedAt.add(Duration(days: index)),
          profile: TripTrackingProfile.roadVehicle,
          startedAt: DateTime.utc(2026, 7, 1 + index, 8),
          finishedAt: DateTime.utc(2026, 7, 1 + index, 10),
          engineSnapshot: const TripTrackingEngineSnapshot(
            totalAcceptedMeters: 94 * 1609.344,
            walkingReviewSuggested: false,
          ),
        ),
      ),
      review.copyWith(
        confirmedEndingOdometer: 1020,
        odometerConfirmedAt: review.startedAt,
      ),
      TripTrackingReviewRecord(
        id: 'trip_unconfirmed',
        vehicleId: 'vehicle_1',
        startingOdometer: 5000,
        estimatedEndingOdometer: 5100,
        profile: TripTrackingProfile.roadVehicle,
        startedAt: DateTime.utc(2026, 7, 20, 8),
        finishedAt: DateTime.utc(2026, 7, 20, 10),
        engineSnapshot: const TripTrackingEngineSnapshot(
          totalAcceptedMeters: 200 * 1609.344,
          walkingReviewSuggested: false,
        ),
      ),
    ];

    final signal = TripOdometerCalibrationSignal.evaluateConfirmedReviews(
      reviews: reviews,
      requireTrustedSignalDiagnostics: false,
    );

    expect(signal.status, TripOdometerCalibrationStatus.reviewRecommended);
    expect(signal.eligibleSampleCount, 7);
    expect(signal.averageGpsToOdometerRatio, closeTo(.94, .001));
    expect(signal.canOverwriteConfirmedOdometer, isFalse);
  });

  test(
    'calibration excludes reviewed days with poor GPS signal diagnostics',
    () {
      final confirmedAt = DateTime.utc(2026, 7, 14, 12);
      final reviews = <TripTrackingReviewRecord>[
        ...List.generate(
          7,
          (index) => TripTrackingReviewRecord(
            id: 'trip_signal_quality_$index',
            vehicleId: 'vehicle_1',
            startingOdometer: 1000 + (index * 100),
            estimatedEndingOdometer: 1100 + (index * 100),
            confirmedEndingOdometer: 1100 + (index * 100),
            odometerConfirmedAt: confirmedAt.add(Duration(days: index)),
            profile: TripTrackingProfile.roadVehicle,
            startedAt: DateTime.utc(2026, 7, 1 + index, 8),
            finishedAt: DateTime.utc(2026, 7, 1 + index, 10),
            engineSnapshot: TripTrackingEngineSnapshot(
              totalAcceptedMeters: 94 * 1609.344,
              walkingReviewSuggested: false,
              diagnostics: index == 0
                  ? const TripTrackingDiagnostics(
                      receivedSamples: 100,
                      acceptedSamples: 55,
                      dispositionCounts: {
                        TripSampleDisposition.acceptedDistance: 55,
                        TripSampleDisposition.rejectedAccuracy: 45,
                      },
                    )
                  : const TripTrackingDiagnostics(
                      receivedSamples: 100,
                      acceptedSamples: 90,
                      dispositionCounts: {
                        TripSampleDisposition.acceptedDistance: 90,
                        TripSampleDisposition.rejectedAccuracy: 10,
                      },
                    ),
            ),
          ),
        ),
        TripTrackingReviewRecord(
          id: 'trip_signal_quality_same_day_clean',
          vehicleId: 'vehicle_1',
          startingOdometer: 1100,
          estimatedEndingOdometer: 1200,
          confirmedEndingOdometer: 1200,
          odometerConfirmedAt: confirmedAt.add(const Duration(hours: 1)),
          profile: TripTrackingProfile.roadVehicle,
          startedAt: DateTime.utc(2026, 7, 1, 13),
          finishedAt: DateTime.utc(2026, 7, 1, 15),
          engineSnapshot: const TripTrackingEngineSnapshot(
            totalAcceptedMeters: 110 * 1609.344,
            walkingReviewSuggested: false,
            diagnostics: TripTrackingDiagnostics(
              receivedSamples: 100,
              acceptedSamples: 90,
              dispositionCounts: {
                TripSampleDisposition.acceptedDistance: 90,
                TripSampleDisposition.rejectedAccuracy: 10,
              },
            ),
          ),
        ),
      ];

      final signal = TripOdometerCalibrationSignal.evaluateConfirmedReviews(
        reviews: reviews,
      );

      expect(signal.status, TripOdometerCalibrationStatus.insufficientHistory);
      expect(signal.eligibleSampleCount, 6);
      expect(signal.trustedGpsWindowCount, 6);
      expect(signal.excludedPoorGpsDayCount, 1);
      expect(signal.reasonCode, 'needs_more_reviewed_days');
      expect(
        signal.toSafeDashboardMap()['poorGpsDaysExcludedFromCalibration'],
        isTrue,
      );
      expect(signal.toSafeDashboardMap()['trustedGpsWindowCount'], 6);
      expect(signal.toSafeDashboardMap()['excludedPoorGpsDayCount'], 1);
      expect(signal.toSafeDashboardMap()['odometerIsGlobalTruth'], isTrue);
    },
  );

  test(
    'calibration ignores future-dated odometer confirmations when now is provided',
    () {
      final now = DateTime.utc(2026, 7, 14, 12);
      final reviews = [
        ...List.generate(
          6,
          (index) => TripTrackingReviewRecord(
            id: 'trip_confirmed_now_$index',
            vehicleId: 'vehicle_1',
            startingOdometer: 1000 + (index * 100),
            estimatedEndingOdometer: 1100 + (index * 100),
            confirmedEndingOdometer: 1100 + (index * 100),
            odometerConfirmedAt: now.subtract(Duration(days: index)),
            profile: TripTrackingProfile.roadVehicle,
            startedAt: DateTime.utc(2026, 7, 1 + index, 8),
            finishedAt: DateTime.utc(2026, 7, 1 + index, 10),
            engineSnapshot: const TripTrackingEngineSnapshot(
              totalAcceptedMeters: 94 * 1609.344,
              walkingReviewSuggested: false,
            ),
          ),
        ),
        TripTrackingReviewRecord(
          id: 'trip_future_confirmation',
          vehicleId: 'vehicle_1',
          startingOdometer: 2000,
          estimatedEndingOdometer: 2100,
          confirmedEndingOdometer: 2100,
          odometerConfirmedAt: now.add(const Duration(days: 30)),
          profile: TripTrackingProfile.roadVehicle,
          startedAt: DateTime.utc(2026, 7, 7, 8),
          finishedAt: DateTime.utc(2026, 7, 7, 10),
          engineSnapshot: const TripTrackingEngineSnapshot(
            totalAcceptedMeters: 94 * 1609.344,
            walkingReviewSuggested: false,
          ),
        ),
      ];

      final signal = TripOdometerCalibrationSignal.evaluateConfirmedReviews(
        reviews: reviews,
        nowUtc: now,
        requireTrustedSignalDiagnostics: false,
      );

      expect(signal.status, TripOdometerCalibrationStatus.insufficientHistory);
      expect(signal.eligibleSampleCount, 6);
      expect(signal.reasonCode, 'needs_more_reviewed_days');
      expect(signal.canOverwriteConfirmedOdometer, isFalse);
    },
  );

  test('strict calibration excludes days without trusted GPS diagnostics', () {
    final confirmedAt = DateTime.utc(2026, 7, 14, 12);
    final reviews = List.generate(
      7,
      (index) => TripTrackingReviewRecord(
        id: 'trip_unknown_signal_$index',
        vehicleId: 'vehicle_1',
        startingOdometer: 1000 + (index * 100),
        estimatedEndingOdometer: 1100 + (index * 100),
        confirmedEndingOdometer: 1100 + (index * 100),
        odometerConfirmedAt: confirmedAt.add(Duration(days: index)),
        profile: TripTrackingProfile.roadVehicle,
        startedAt: DateTime.utc(2026, 7, 1 + index, 8),
        finishedAt: DateTime.utc(2026, 7, 1 + index, 10),
        engineSnapshot: const TripTrackingEngineSnapshot(
          totalAcceptedMeters: 94 * 1609.344,
          walkingReviewSuggested: false,
        ),
      ),
    );

    final legacySignal = TripOdometerCalibrationSignal.evaluateConfirmedReviews(
      reviews: reviews,
      requireTrustedSignalDiagnostics: false,
    );
    final defaultSignal =
        TripOdometerCalibrationSignal.evaluateConfirmedReviews(
          reviews: reviews,
        );

    expect(
      legacySignal.status,
      TripOdometerCalibrationStatus.reviewRecommended,
    );
    expect(
      defaultSignal.status,
      TripOdometerCalibrationStatus.insufficientHistory,
    );
    expect(defaultSignal.eligibleSampleCount, 0);
    expect(defaultSignal.excludedPoorGpsDayCount, 7);
    expect(defaultSignal.reasonCode, 'needs_more_reviewed_days');
    expect(
      defaultSignal.toSafeDashboardMap()['poorGpsDaysExcludedFromCalibration'],
      isTrue,
    );
    expect(
      defaultSignal
          .toSafeDashboardMap()['unknownSignalDiagnosticsExcludedByDefault'],
      isTrue,
    );
  });

  test('calibration requires distinct reviewed driving days', () {
    final confirmedAt = DateTime.utc(2026, 7, 14, 12);
    final reviews = List.generate(
      7,
      (index) => TripTrackingReviewRecord(
        id: 'trip_same_day_$index',
        vehicleId: 'vehicle_1',
        startingOdometer: 1000 + (index * 10),
        estimatedEndingOdometer: 1010 + (index * 10),
        confirmedEndingOdometer: 1010 + (index * 10),
        odometerConfirmedAt: confirmedAt.add(Duration(minutes: index)),
        profile: TripTrackingProfile.roadVehicle,
        startedAt: DateTime.utc(2026, 7, 14, 8, index),
        finishedAt: DateTime.utc(2026, 7, 14, 8, index + 1),
        engineSnapshot: const TripTrackingEngineSnapshot(
          totalAcceptedMeters: 9.4 * 1609.344,
          walkingReviewSuggested: false,
        ),
      ),
    );

    final signal = TripOdometerCalibrationSignal.evaluateConfirmedReviews(
      reviews: reviews,
      requireTrustedSignalDiagnostics: false,
    );

    expect(signal.status, TripOdometerCalibrationStatus.insufficientHistory);
    expect(signal.eligibleSampleCount, 1);
    expect(signal.reasonCode, 'needs_more_reviewed_days');
  });

  test('calibration aggregates multiple reviewed trips on the same day', () {
    final confirmedAt = DateTime.utc(2026, 7, 14, 12);
    final reviews = [
      for (var day = 0; day < 7; day++)
        for (var trip = 0; trip < 2; trip++)
          TripTrackingReviewRecord(
            id: 'trip_daily_${day}_$trip',
            vehicleId: 'vehicle_1',
            startingOdometer: 1000 + (day * 100) + (trip * 50),
            estimatedEndingOdometer: 1050 + (day * 100) + (trip * 50),
            confirmedEndingOdometer: 1050 + (day * 100) + (trip * 50),
            odometerConfirmedAt: confirmedAt.add(Duration(days: day)),
            profile: TripTrackingProfile.roadVehicle,
            startedAt: DateTime.utc(2026, 7, 1 + day, 8 + trip),
            finishedAt: DateTime.utc(2026, 7, 1 + day, 9 + trip),
            engineSnapshot: const TripTrackingEngineSnapshot(
              totalAcceptedMeters: 47 * 1609.344,
              walkingReviewSuggested: false,
            ),
          ),
    ];

    final signal = TripOdometerCalibrationSignal.evaluateConfirmedReviews(
      reviews: reviews,
      requireTrustedSignalDiagnostics: false,
    );

    expect(signal.status, TripOdometerCalibrationStatus.reviewRecommended);
    expect(signal.eligibleSampleCount, 7);
    expect(signal.averageGpsToOdometerRatio, closeTo(.94, .001));
    expect(signal.reasonCode, 'persistent_gps_odometer_drift');
  });

  test('calibration uses a recent reviewed-day window for tire changes', () {
    final confirmedAt = DateTime.utc(2026, 7, 14, 12);
    final olderOppositeDrift = List.generate(
      20,
      (index) => TripTrackingReviewRecord(
        id: 'trip_old_tires_$index',
        vehicleId: 'vehicle_1',
        startingOdometer: 1000 + (index * 100),
        estimatedEndingOdometer: 1100 + (index * 100),
        confirmedEndingOdometer: 1100 + (index * 100),
        odometerConfirmedAt: confirmedAt.add(Duration(days: index)),
        profile: TripTrackingProfile.roadVehicle,
        startedAt: DateTime.utc(2026, 6, 1 + index, 8),
        finishedAt: DateTime.utc(2026, 6, 1 + index, 10),
        engineSnapshot: const TripTrackingEngineSnapshot(
          totalAcceptedMeters: 106 * 1609.344,
          walkingReviewSuggested: false,
        ),
      ),
    );
    final recentNewTires = List.generate(
      7,
      (index) => TripTrackingReviewRecord(
        id: 'trip_new_tires_$index',
        vehicleId: 'vehicle_1',
        startingOdometer: 4000 + (index * 100),
        estimatedEndingOdometer: 4100 + (index * 100),
        confirmedEndingOdometer: 4100 + (index * 100),
        odometerConfirmedAt: confirmedAt.add(Duration(days: 30 + index)),
        profile: TripTrackingProfile.roadVehicle,
        startedAt: DateTime.utc(2026, 7, 1 + index, 8),
        finishedAt: DateTime.utc(2026, 7, 1 + index, 10),
        engineSnapshot: const TripTrackingEngineSnapshot(
          totalAcceptedMeters: 94 * 1609.344,
          walkingReviewSuggested: false,
        ),
      ),
    );

    final signal = TripOdometerCalibrationSignal.evaluateConfirmedReviews(
      reviews: [...olderOppositeDrift, ...recentNewTires],
      maximumReviewedDays: 7,
      requireTrustedSignalDiagnostics: false,
    );

    expect(signal.status, TripOdometerCalibrationStatus.reviewRecommended);
    expect(signal.eligibleSampleCount, 7);
    expect(signal.averageGpsToOdometerRatio, closeTo(.94, .001));
    expect(signal.reasonCode, 'persistent_gps_odometer_drift');
    expect(signal.canOverwriteConfirmedOdometer, isFalse);
  });

  test(
    'calibration history fails closed when confirmed reviews mix vehicles',
    () {
      final confirmedAt = DateTime.utc(2026, 7, 14, 12);
      final reviews = List.generate(
        7,
        (index) => TripTrackingReviewRecord(
          id: 'trip_mixed_vehicle_$index',
          vehicleId: index == 0 ? 'vehicle_2' : 'vehicle_1',
          startingOdometer: 1000 + (index * 100),
          estimatedEndingOdometer: 1100 + (index * 100),
          confirmedEndingOdometer: 1100 + (index * 100),
          odometerConfirmedAt: confirmedAt.add(Duration(days: index)),
          profile: TripTrackingProfile.roadVehicle,
          startedAt: DateTime.utc(2026, 7, 1 + index, 8),
          finishedAt: DateTime.utc(2026, 7, 1 + index, 10),
          engineSnapshot: const TripTrackingEngineSnapshot(
            totalAcceptedMeters: 94 * 1609.344,
            walkingReviewSuggested: false,
          ),
        ),
      );

      final mixedSignal =
          TripOdometerCalibrationSignal.evaluateConfirmedReviews(
            reviews: reviews,
          );
      final scopedSignal =
          TripOdometerCalibrationSignal.evaluateConfirmedReviews(
            reviews: reviews,
            vehicleId: 'vehicle_1',
            minimumSamples: 6,
            requireTrustedSignalDiagnostics: false,
          );

      expect(
        mixedSignal.status,
        TripOdometerCalibrationStatus.insufficientHistory,
      );
      expect(mixedSignal.reasonCode, 'mixed_vehicle_calibration_history');
      expect(
        scopedSignal.status,
        TripOdometerCalibrationStatus.reviewRecommended,
      );
      expect(scopedSignal.eligibleSampleCount, 6);
    },
  );

  test(
    'calibration ignores invalid confirmed-looking timelines before mix check',
    () {
      final confirmedAt = DateTime.utc(2026, 7, 14, 12);
      final reviews = [
        ...List.generate(
          7,
          (index) => TripTrackingReviewRecord(
            id: 'trip_valid_vehicle_$index',
            vehicleId: 'vehicle_1',
            startingOdometer: 1000 + (index * 100),
            estimatedEndingOdometer: 1100 + (index * 100),
            confirmedEndingOdometer: 1100 + (index * 100),
            odometerConfirmedAt: confirmedAt.add(Duration(days: index)),
            profile: TripTrackingProfile.roadVehicle,
            startedAt: DateTime.utc(2026, 7, 1 + index, 8),
            finishedAt: DateTime.utc(2026, 7, 1 + index, 10),
            engineSnapshot: const TripTrackingEngineSnapshot(
              totalAcceptedMeters: 94 * 1609.344,
              walkingReviewSuggested: false,
            ),
          ),
        ),
        TripTrackingReviewRecord(
          id: 'trip_invalid_other_vehicle',
          vehicleId: 'vehicle_2',
          startingOdometer: 1000,
          estimatedEndingOdometer: 1100,
          confirmedEndingOdometer: 1100,
          odometerConfirmedAt: confirmedAt,
          profile: TripTrackingProfile.roadVehicle,
          startedAt: DateTime.utc(2026, 7, 20, 8),
          finishedAt: DateTime.utc(2026, 7, 20, 10),
          engineSnapshot: const TripTrackingEngineSnapshot(
            totalAcceptedMeters: 200 * 1609.344,
            walkingReviewSuggested: false,
          ),
          hasValidTimeline: false,
        ),
      ];

      final signal = TripOdometerCalibrationSignal.evaluateConfirmedReviews(
        reviews: reviews,
        requireTrustedSignalDiagnostics: false,
      );

      expect(signal.status, TripOdometerCalibrationStatus.reviewRecommended);
      expect(signal.eligibleSampleCount, 7);
      expect(signal.reasonCode, 'persistent_gps_odometer_drift');
    },
  );

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

  test(
    'calibration weights longer reviewed trips over short noisy errands',
    () {
      final history = [
        ...List.generate(
          6,
          (_) => const TripOdometerReconciliation(
            status: TripOdometerReconciliationStatus.reviewRecommended,
            confirmedOdometerDeltaMiles: 10,
            filteredGpsMiles: 8,
            absoluteDifferenceMiles: 2,
            differencePercent: 20,
          ),
        ),
        const TripOdometerReconciliation(
          status: TripOdometerReconciliationStatus.aligned,
          confirmedOdometerDeltaMiles: 500,
          filteredGpsMiles: 495,
          absoluteDifferenceMiles: 5,
          differencePercent: 1,
        ),
      ];

      final signal = TripOdometerCalibrationSignal.evaluate(history: history);

      expect(signal.status, TripOdometerCalibrationStatus.stable);
      expect(signal.eligibleSampleCount, 7);
      expect(signal.averageGpsToOdometerRatio, closeTo(543 / 560, .001));
      expect(signal.averageDifferencePercent, closeTo(17 / 560 * 100, .001));
      expect(signal.reasonCode, 'gps_odometer_variance_too_high');
    },
  );

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

  test('calibration does not suggest correction for inconsistent drift', () {
    final history = [4, 5, 6, 7, 8, 9, 10]
        .map(
          (difference) => TripOdometerReconciliation(
            status: TripOdometerReconciliationStatus.reviewRecommended,
            confirmedOdometerDeltaMiles: 100,
            filteredGpsMiles: 100.0 - difference,
            absoluteDifferenceMiles: difference.toDouble(),
            differencePercent: difference.toDouble(),
          ),
        )
        .toList(growable: false);

    final signal = TripOdometerCalibrationSignal.evaluate(history: history);

    expect(signal.status, TripOdometerCalibrationStatus.stable);
    expect(signal.reasonCode, 'gps_odometer_variance_too_high');
    expect(signal.differenceSpreadPercent, 6.0);
    expect(
      signal.toSafeDashboardMap()['reasonCode'],
      'gps_odometer_variance_too_high',
    );
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
    final badWindowSignal =
        TripOdometerCalibrationSignal.evaluateConfirmedReviews(
          reviews: const [],
          maximumReviewedDays: 6,
        );
    expect(
      badWindowSignal.status,
      TripOdometerCalibrationStatus.insufficientHistory,
    );
    expect(badWindowSignal.reasonCode, 'invalid_calibration_threshold');
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

  test('calibration vehicle matching normalizes legacy padded ids', () {
    final confirmedAt = DateTime.utc(2026, 7, 14, 12);
    final reviews = List.generate(
      7,
      (index) => TripTrackingReviewRecord(
        id: 'trip_padded_vehicle_$index',
        vehicleId: index.isEven ? 'vehicle_1' : ' vehicle_1 ',
        startingOdometer: 1000 + (index * 100),
        estimatedEndingOdometer: 1100 + (index * 100),
        confirmedEndingOdometer: 1100 + (index * 100),
        odometerConfirmedAt: confirmedAt.add(Duration(days: index)),
        profile: TripTrackingProfile.roadVehicle,
        startedAt: DateTime.utc(2026, 7, 1 + index, 8),
        finishedAt: DateTime.utc(2026, 7, 1 + index, 10),
        engineSnapshot: const TripTrackingEngineSnapshot(
          totalAcceptedMeters: 94 * 1609.344,
          walkingReviewSuggested: false,
        ),
      ),
    );

    final signal = TripOdometerCalibrationSignal.evaluateConfirmedReviews(
      reviews: reviews,
      vehicleId: ' vehicle_1 ',
      requireTrustedSignalDiagnostics: false,
    );

    expect(signal.status, TripOdometerCalibrationStatus.reviewRecommended);
    expect(signal.eligibleSampleCount, 7);
    expect(signal.reasonCode, 'persistent_gps_odometer_drift');
  });

  test('calibration signal provides safe tire-size review guidance', () {
    const signal = TripOdometerCalibrationSignal(
      status: TripOdometerCalibrationStatus.reviewRecommended,
      eligibleSampleCount: 7,
      averageGpsToOdometerRatio: 1.06,
      averageDifferencePercent: 6.234,
      reasonCode: 'persistent_gps_odometer_drift',
    );

    expect(signal.maySuggestTireOrSpeedometerReview, isTrue);
    expect(signal.userReviewPrompt, contains('tire size'));
    expect(signal.userReviewPrompt, contains('speedometer calibration'));
    expect(signal.userReviewPrompt, contains('advisory calibration'));
    expect(signal.toSafeDashboardMap(), {
      'schemaVersion': 1,
      'status': 'reviewRecommended',
      'eligibleSampleCount': 7,
      'trustedGpsWindowCount': 7,
      'excludedPoorGpsDayCount': 0,
      'averageDifferencePercent': 6.2,
      'differenceSpreadPercent': 0.0,
      'reasonCode': 'persistent_gps_odometer_drift',
      'shouldPromptUser': true,
      'maySuggestTireOrSpeedometerReview': true,
      'tireSizeReviewSuggested': true,
      'speedometerCalibrationReviewSuggested': true,
      'canOverwriteConfirmedOdometer': false,
      'calibrationCanSetGlobalTruth': false,
      'calibrationCanChangeGlobalTruth': false,
      'calibrationCanConfirmOfficialMileage': false,
      'calibrationRequiresUserOptIn': true,
      'calibrationRequiresMultipleReviewedTrips': true,
      'continuousCalibrationAverageRequired': true,
      'poorGpsDaysExcludedFromCalibration': true,
      'calibrationRequiresTrustedGpsWindow': true,
      'controllerRequiresTrustedSignalDiagnostics': true,
      'unknownSignalDiagnosticsFailNeutralInController': true,
      'poorGpsDaysCannotCountAsTrustedWindow': true,
      'unknownSignalDiagnosticsCannotCountAsTrustedWindow': true,
      'unknownSignalDiagnosticsExcludedByDefault': true,
      'excludedPoorGpsCannotBecomeCalibrationProof': true,
      'singleDayCalibrationRejected': true,
      'calibrationRequiresVehicleScopedHistory': true,
      'calibrationCanRewritePastTrips': false,
      'canApplySilently': false,
      'gpsAssistCanOnlyScaleFutureProjectionAfterOptIn': true,
      'calibrationCanChangeDisplayedConfirmedMiles': false,
      'calibrationCanMutateTripLog': false,
      'calibrationCanLowerConfirmedOdometer': false,
      'calibrationCanCreateMaintenanceRecord': false,
      'mapboxRouteDistanceCanBecomeOfficial': false,
      'calibrationTrustedAfterReviewedHistoryOnly': true,
      'remoteHistoryCanCreateCalibration': false,
      'remoteCalibrationCanApplySilently': false,
      'remoteCalibrationCanEnableSetting': false,
      'remoteCalibrationCanResetPrompt': false,
      'firestoreCanOverrideCalibration': false,
      'mapboxRouteCanCreateCalibration': false,
      'mapboxCanOverrideCalibration': false,
      'mapboxCanTriggerTirePrompt': false,
      'gpsCanAutoApplyCalibration': false,
      'gpsAssistanceCalibrationMultiplier': 0.9434,
      'odometerIsGlobalTruth': true,
      'odometerRemainsCanonical': true,
      'physicalOdometerRequiredForOfficialMileage': true,
      'confirmedOdometerOverridesExternalMileage': true,
      'externalMileageCannotBecomeGlobalTruth': true,
      'gpsDistanceCanOnlyAdviseMileageReview': true,
      'mapMatchingCanOnlyAdviseMileageReview': true,
      'optimizationCannotChangeOfficialMileage': true,
      'gpsAssistAdvisoryOnly': true,
      'mapboxAssistAdvisoryOnly': true,
      'rawReviewedTripsIncluded': false,
      'rawLocationIncluded': false,
      'tokensIncluded': false,
    });
  });

  test('safe calibration summaries reject unknown reason text', () {
    const signal = TripOdometerCalibrationSignal(
      status: TripOdometerCalibrationStatus.reviewRecommended,
      eligibleSampleCount: -3,
      averageGpsToOdometerRatio: .98,
      averageDifferencePercent: double.nan,
      reasonCode: 'token=pk.secret latitude=35.1',
    );

    final summary = signal.toSafeDashboardMap();

    expect(signal.maySuggestTireOrSpeedometerReview, isFalse);
    expect(signal.userReviewPrompt, isEmpty);
    expect(summary['eligibleSampleCount'], 0);
    expect(summary['averageDifferencePercent'], 0);
    expect(summary['reasonCode'], 'unknown_calibration_state');
    expect(summary['shouldPromptUser'], isFalse);
    expect(summary['maySuggestTireOrSpeedometerReview'], isFalse);
    expect(summary['remoteCalibrationCanApplySilently'], isFalse);
    expect(summary['firestoreCanOverrideCalibration'], isFalse);
    expect(summary['mapboxCanOverrideCalibration'], isFalse);
    expect(summary.toString(), isNot(contains('pk.secret')));
    expect(summary.toString(), isNot(contains('35.1')));
  });

  test('safe odometer summaries sanitize malformed public fields', () {
    const reconciliation = TripOdometerReconciliation(
      status: TripOdometerReconciliationStatus.reviewRecommended,
      confirmedOdometerDeltaMiles: double.nan,
      filteredGpsMiles: double.infinity,
      absoluteDifferenceMiles: -1,
      differencePercent: double.nan,
    );
    const continuity = TripOdometerContinuityCheck(
      status: TripOdometerContinuityStatus.reviewRecommended,
      odometerGapMiles: 75,
      reasonCode: 'token=pk.secret latitude=35.1',
    );

    expect(reconciliation.toSafeDashboardMap()['filteredGpsMiles'], 0);
    expect(reconciliation.toSafeDashboardMap()['differencePercent'], 0);
    expect(
      reconciliation
          .toSafeDashboardMap()['externalMileageTrustedAfterValidationOnly'],
      isTrue,
    );
    expect(
      reconciliation.toSafeDashboardMap()['remoteTotalsCanBecomeCanonical'],
      isFalse,
    );
    expect(
      reconciliation.toSafeDashboardMap()['mapboxCanOverrideOdometerTruth'],
      isFalse,
    );
    expect(
      continuity.toSafeDashboardMap()['reasonCode'],
      'invalid_odometer_continuity_input',
    );
    expect(
      continuity.toSafeDashboardMap()['continuityTrustedAfterValidationOnly'],
      isTrue,
    );
    expect(
      continuity.toSafeDashboardMap()['firestoreCanOverrideContinuity'],
      isFalse,
    );
    expect(
      continuity.toSafeDashboardMap().toString(),
      isNot(contains('pk.secret')),
    );
    expect(continuity.toSafeDashboardMap()['rawLocationIncluded'], isFalse);
  });
}
