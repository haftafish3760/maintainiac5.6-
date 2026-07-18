import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_calibration_apply_guard.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_odometer_calibration.dart';

void main() {
  final now = DateTime.utc(2026, 7, 18, 12);

  TripOdometerCalibrationSignal signal({
    TripOdometerCalibrationStatus status =
        TripOdometerCalibrationStatus.reviewRecommended,
    int samples = 7,
    double ratio = .94,
    double differencePercent = 6,
    String reason = 'persistent_gps_odometer_drift',
    int? trustedGpsWindowCount,
    int excludedPoorGpsDayCount = 0,
  }) => TripOdometerCalibrationSignal(
    status: status,
    eligibleSampleCount: samples,
    trustedGpsWindowCount: trustedGpsWindowCount,
    excludedPoorGpsDayCount: excludedPoorGpsDayCount,
    averageGpsToOdometerRatio: ratio,
    averageDifferencePercent: differencePercent,
    reasonCode: reason,
  );

  test('calibration cannot apply without explicit user opt-in', () {
    final guard = TripTrackingCalibrationApplyGuard.evaluate(
      signal: signal(),
      userOptedIn: false,
      userAcceptedLatestReview: true,
      minimumReviewedDays: 7,
      latestReviewedAtUtc: now,
      nowUtc: now,
    );

    expect(guard.status, TripTrackingCalibrationApplyStatus.disabled);
    expect(guard.multiplier, 1);
    expect(guard.canApplyToFutureGpsProjection, isFalse);
    expect(guard.reasonCodes, contains('calibration_user_opt_in_required'));
  });

  test('calibration waits for multiple reviewed odometer days', () {
    final guard = TripTrackingCalibrationApplyGuard.evaluate(
      signal: signal(
        status: TripOdometerCalibrationStatus.insufficientHistory,
        samples: 6,
        reason: 'needs_more_reviewed_days',
      ),
      userOptedIn: true,
      userAcceptedLatestReview: true,
      minimumReviewedDays: 7,
      latestReviewedAtUtc: now,
      nowUtc: now,
    );

    expect(guard.status, TripTrackingCalibrationApplyStatus.waitingForHistory);
    expect(guard.reasonCodes, contains('more_reviewed_odometer_days_required'));
  });

  test('persistent drift requires accepted user review before applying', () {
    final guard = TripTrackingCalibrationApplyGuard.evaluate(
      signal: signal(),
      userOptedIn: true,
      userAcceptedLatestReview: false,
      minimumReviewedDays: 7,
      latestReviewedAtUtc: now,
      nowUtc: now,
    );

    expect(guard.status, TripTrackingCalibrationApplyStatus.reviewRequired);
    expect(guard.canApplyToFutureGpsProjection, isFalse);
    expect(guard.reasonCodes, contains('user_must_accept_calibration_review'));
  });

  test('accepted calibration applies only to future GPS projections', () {
    final guard = TripTrackingCalibrationApplyGuard.evaluate(
      signal: signal(),
      userOptedIn: true,
      userAcceptedLatestReview: true,
      minimumReviewedDays: 7,
      latestReviewedAtUtc: now,
      nowUtc: now,
      activeVehicleId: 'vehicle_1',
      reviewedVehicleId: 'vehicle_1',
      reviewedVehicleIds: const ['vehicle_1'],
    );
    final safe = guard.toSafeDashboardMap();

    expect(
      guard.status,
      TripTrackingCalibrationApplyStatus.readyForFutureProjection,
    );
    expect(guard.multiplier, closeTo(1.0638, .001));
    expect(guard.canApplyToFutureGpsProjection, isTrue);
    expect(safe['appliesToPastTrips'], isFalse);
    expect(safe['canRewriteConfirmedOdometer'], isFalse);
    expect(safe['canApplySilently'], isFalse);
    expect(safe['calibrationCanChangeDisplayedConfirmedMiles'], isFalse);
    expect(safe['calibrationCanMutateTripLog'], isFalse);
    expect(safe['calibrationCanPurgeLocalDataAfterBackup'], isFalse);
    expect(safe['calibrationCanBypassVehicleProfile'], isFalse);
    expect(safe['calibrationCanApplyAcrossVehicles'], isFalse);
    expect(safe['calibrationRequiresSingleVehicleHistory'], isTrue);
    expect(safe['calibrationRequiresLocalReviewedOdometerHistory'], isTrue);
    expect(safe['continuousCalibrationAverageRequired'], isTrue);
    expect(safe['poorGpsDaysExcludedFromCalibration'], isTrue);
    expect(safe['calibrationRequiresTrustedGpsWindow'], isTrue);
    expect(safe['trustedGpsWindowCount'], 7);
    expect(safe['excludedPoorGpsDayCount'], 0);
    expect(safe['excludedPoorGpsDayCountIncluded'], isTrue);
    expect(safe['poorGpsExcludedDayCountTrustedAfterValidationOnly'], isTrue);
    expect(safe['singleDayCalibrationRejected'], isTrue);
    expect(safe['calibrationAverageVehicleScoped'], isTrue);
    expect(safe['calibrationRequiresOwnershipOrExplicitAccess'], isTrue);
    expect(safe['fleetObserverCanApplyCalibration'], isFalse);
    expect(safe['calibrationVehicleIdIncluded'], isFalse);
    expect(safe['rawVehicleIdsIncluded'], isFalse);
    expect(safe['remoteCalibrationCanRewritePastTrips'], isFalse);
    expect(safe['mapboxRouteDistanceCanBecomeOfficial'], isFalse);
    expect(safe['settingsCanDisableCalibrationAssist'], isTrue);
    expect(safe['settingsCanResetCalibrationPrompt'], isTrue);
    expect(safe['odometerIsGlobalTruth'], isTrue);
    expect(safe['odometerRemainsCanonical'], isTrue);
    expect(safe['physicalOdometerIsCanonical'], isTrue);
    expect(safe['gpsCanOverrideOdometer'], isFalse);
    expect(safe['mapboxCanOverrideOdometer'], isFalse);
    expect(safe['firebaseMirrorCanOverrideOdometer'], isFalse);
    expect(safe['cloudFunctionCanOverrideOdometer'], isFalse);
    expect(safe['importedFileCanOverrideOdometer'], isFalse);
    expect(safe['localCacheCanOverrideOdometer'], isFalse);
    expect(safe['sensorFusionCanOverrideOdometer'], isFalse);
    expect(safe['calibrationAppliesToFutureGpsProjectionOnly'], isTrue);
    expect(safe['gpsEstimateRemainsNonCanonical'], isTrue);
  });

  test('calibration tire review is advisory and never creates records', () {
    final safe = TripTrackingCalibrationApplyGuard.evaluate(
      signal: signal(differencePercent: 9),
      userOptedIn: true,
      userAcceptedLatestReview: true,
      minimumReviewedDays: 7,
      latestReviewedAtUtc: now,
      nowUtc: now,
      activeVehicleId: 'vehicle_1',
      reviewedVehicleId: 'vehicle_1',
      reviewedVehicleIds: const ['vehicle_1'],
    ).toSafeDashboardMap();

    expect(safe['tireOrSpeedometerReviewIsAdvisory'], isTrue);
    expect(safe['tireChangeDoesNotCreateMaintenanceEntry'], isTrue);
    expect(safe['calibrationCanCreateMaintenanceRecord'], isFalse);
    expect(safe['calibrationCanLowerConfirmedOdometer'], isFalse);
    expect(safe['remoteCalibrationCanEnableSetting'], isFalse);
    expect(safe['remoteCalibrationCanResetPrompt'], isFalse);
    expect(safe['mapboxCanTriggerTirePrompt'], isFalse);
    expect(safe['gpsCanAutoApplyCalibration'], isFalse);
  });

  test('review calibration requires a current accepted review timestamp', () {
    final missing = TripTrackingCalibrationApplyGuard.evaluate(
      signal: signal(),
      userOptedIn: true,
      userAcceptedLatestReview: true,
      minimumReviewedDays: 7,
      latestReviewedAtUtc: null,
      nowUtc: now,
    );
    final stale = TripTrackingCalibrationApplyGuard.evaluate(
      signal: signal(),
      userOptedIn: true,
      userAcceptedLatestReview: true,
      minimumReviewedDays: 7,
      latestReviewedAtUtc: now.subtract(const Duration(days: 45)),
      nowUtc: now,
    );

    expect(missing.status, TripTrackingCalibrationApplyStatus.rejected);
    expect(missing.reasonCodes, contains('missing_latest_review_timestamp'));
    expect(missing.canApplyToFutureGpsProjection, isFalse);
    expect(stale.status, TripTrackingCalibrationApplyStatus.rejected);
    expect(stale.reasonCodes, contains('stale_review_timestamp'));
    expect(
      stale.toSafeDashboardMap()['staleCalibrationReviewRejected'],
      isTrue,
    );
  });

  test('runaway calibration history counts fail neutral before applying', () {
    final guard = TripTrackingCalibrationApplyGuard.evaluate(
      signal: signal(samples: 500),
      userOptedIn: true,
      userAcceptedLatestReview: true,
      minimumReviewedDays: 7,
      latestReviewedAtUtc: now,
      nowUtc: now,
    );
    final safe = guard.toSafeDashboardMap();

    expect(guard.status, TripTrackingCalibrationApplyStatus.rejected);
    expect(guard.reasonCodes, contains('excessive_sample_count'));
    expect(guard.multiplier, 1);
    expect(guard.canApplyToFutureGpsProjection, isFalse);
    expect(safe['excessiveHistoryCountRejected'], isTrue);
    expect(safe['canRewriteConfirmedOdometer'], isFalse);
  });

  test('calibration rejects mismatched trusted GPS window evidence', () {
    final guard = TripTrackingCalibrationApplyGuard.evaluate(
      signal: signal(
        samples: 7,
        trustedGpsWindowCount: 6,
        excludedPoorGpsDayCount: 1,
      ),
      userOptedIn: true,
      userAcceptedLatestReview: true,
      minimumReviewedDays: 7,
      latestReviewedAtUtc: now,
      nowUtc: now,
    );
    final safe = guard.toSafeDashboardMap();

    expect(guard.status, TripTrackingCalibrationApplyStatus.rejected);
    expect(
      guard.reasonCodes,
      contains('trusted_gps_window_count_below_eligible_days'),
    );
    expect(guard.canApplyToFutureGpsProjection, isFalse);
    expect(safe['trustedGpsWindowCount'], 6);
    expect(safe['excludedPoorGpsDayCount'], 1);
    expect(safe['poorGpsDaysExcludedFromCalibration'], isTrue);
    expect(safe['calibrationRequiresTrustedGpsWindow'], isTrue);
  });

  test('calibration rejects mixed or mismatched vehicle history', () {
    final mixed = TripTrackingCalibrationApplyGuard.evaluate(
      signal: signal(),
      userOptedIn: true,
      userAcceptedLatestReview: true,
      minimumReviewedDays: 7,
      latestReviewedAtUtc: now,
      nowUtc: now,
      activeVehicleId: 'vehicle_1',
      reviewedVehicleIds: const ['vehicle_1', 'vehicle_2'],
    );
    final mismatch = TripTrackingCalibrationApplyGuard.evaluate(
      signal: signal(),
      userOptedIn: true,
      userAcceptedLatestReview: true,
      minimumReviewedDays: 7,
      latestReviewedAtUtc: now,
      nowUtc: now,
      activeVehicleId: 'vehicle_1',
      reviewedVehicleId: 'vehicle_2',
    );
    final unsafe = TripTrackingCalibrationApplyGuard.evaluate(
      signal: signal(),
      userOptedIn: true,
      userAcceptedLatestReview: true,
      minimumReviewedDays: 7,
      latestReviewedAtUtc: now,
      nowUtc: now,
      activeVehicleId: 'vehicle/../2',
      reviewedVehicleIds: const ['vehicle_1'],
    );

    expect(mixed.status, TripTrackingCalibrationApplyStatus.rejected);
    expect(mixed.reasonCodes, contains('mixed_vehicle_calibration_history'));
    expect(mismatch.status, TripTrackingCalibrationApplyStatus.rejected);
    expect(mismatch.reasonCodes, contains('calibration_vehicle_mismatch'));
    expect(unsafe.status, TripTrackingCalibrationApplyStatus.rejected);
    expect(unsafe.reasonCodes, contains('unsafe_active_vehicle_id'));
    expect(mixed.multiplier, 1);
    expect(mismatch.canApplyToFutureGpsProjection, isFalse);
    expect(
      unsafe.toSafeDashboardMap()['calibrationCanApplyAcrossVehicles'],
      isFalse,
    );
  });

  test('stable calibration keeps a neutral multiplier', () {
    final guard = TripTrackingCalibrationApplyGuard.evaluate(
      signal: signal(
        status: TripOdometerCalibrationStatus.stable,
        ratio: 1.01,
        differencePercent: 1,
        reason: 'calibration_stable',
      ),
      userOptedIn: true,
      userAcceptedLatestReview: false,
      minimumReviewedDays: 7,
      latestReviewedAtUtc: now,
      nowUtc: now,
    );

    expect(
      guard.status,
      TripTrackingCalibrationApplyStatus.readyForFutureProjection,
    );
    expect(guard.multiplier, 1);
    expect(
      guard.reasonCodes,
      contains('calibration_stable_neutral_multiplier'),
    );
  });

  test('malformed or future calibration signals fail neutral', () {
    final malformed = TripTrackingCalibrationApplyGuard.evaluate(
      signal: signal(
        samples: -1,
        ratio: double.nan,
        differencePercent: double.infinity,
        reason: 'token=pk.secret lat=35.1',
      ),
      userOptedIn: true,
      userAcceptedLatestReview: true,
      minimumReviewedDays: 7,
      latestReviewedAtUtc: now.add(const Duration(days: 1)),
      nowUtc: now,
    );
    final safe = malformed.toSafeDashboardMap();

    expect(malformed.status, TripTrackingCalibrationApplyStatus.rejected);
    expect(malformed.multiplier, 1);
    expect(malformed.canApplyToFutureGpsProjection, isFalse);
    expect(
      malformed.reasonCodes,
      containsAll([
        'negative_sample_count',
        'invalid_gps_odometer_ratio',
        'invalid_difference_percent',
        'unknown_signal_reason',
        'future_review_timestamp',
      ]),
    );
    expect(safe['remoteCalibrationCanOverrideLocalState'], isFalse);
    expect(safe['firestoreCanApplyCalibration'], isFalse);
    expect(safe['mapboxCanApplyCalibration'], isFalse);
    expect(safe['cloudFunctionCanApplyCalibration'], isFalse);
    expect(safe['importedFileCanApplyCalibration'], isFalse);
    expect(safe['dashboardCacheCanApplyCalibration'], isFalse);
    expect(safe.toString(), isNot(contains('pk.secret')));
    expect(safe.toString(), isNot(contains('35.1')));
  });

  test('safe calibration apply summary excludes raw history and tokens', () {
    final safe = TripTrackingCalibrationApplyGuard.evaluate(
      signal: signal(),
      userOptedIn: true,
      userAcceptedLatestReview: true,
      minimumReviewedDays: 7,
      latestReviewedAtUtc: now,
      nowUtc: now,
    ).toSafeDashboardMap();

    expect(safe['rawReviewedTripsIncluded'], isFalse);
    expect(safe['rawGpsIncluded'], isFalse);
    expect(safe['preciseLocationIncluded'], isFalse);
    expect(safe['tokensIncluded'], isFalse);
    expect(safe['userOptInRequired'], isTrue);
    expect(safe['reviewAcceptanceRequired'], isTrue);
    expect(safe['calibrationCanChangeDisplayedConfirmedMiles'], isFalse);
    expect(safe['calibrationCanMutateTripLog'], isFalse);
    expect(safe['remoteCalibrationCanRewritePastTrips'], isFalse);
    expect(safe['mapboxRouteDistanceCanBecomeOfficial'], isFalse);
    expect(safe['requiresMultipleReviewedOdometerDays'], isTrue);
    expect(safe['latestReviewTimestampRequired'], isTrue);
    expect(safe['calibrationRequiresSingleVehicleHistory'], isTrue);
    expect(safe['calibrationRequiresLocalReviewedOdometerHistory'], isTrue);
    expect(safe['calibrationRequiresOwnershipOrExplicitAccess'], isTrue);
    expect(safe['calibrationVehicleIdIncluded'], isFalse);
    expect(safe['rawVehicleIdsIncluded'], isFalse);
  });

  test('remote calibration history cannot apply even when reviewed', () {
    final firestore = TripTrackingCalibrationApplyGuard.evaluate(
      signal: signal(),
      userOptedIn: true,
      userAcceptedLatestReview: true,
      minimumReviewedDays: 7,
      latestReviewedAtUtc: now,
      nowUtc: now,
      currentUserId: 'driver_1',
      calibrationOwnerUserId: 'driver_1',
      historySource: TripTrackingCalibrationHistorySource.firestoreMirror,
    );
    final mapbox = TripTrackingCalibrationApplyGuard.evaluate(
      signal: signal(),
      userOptedIn: true,
      userAcceptedLatestReview: true,
      minimumReviewedDays: 7,
      latestReviewedAtUtc: now,
      nowUtc: now,
      currentUserId: 'driver_1',
      calibrationOwnerUserId: 'driver_1',
      historySource: TripTrackingCalibrationHistorySource.mapbox,
    );

    expect(firestore.status, TripTrackingCalibrationApplyStatus.rejected);
    expect(
      firestore.reasonCodes,
      contains('local_reviewed_odometer_history_required'),
    );
    expect(mapbox.canApplyToFutureGpsProjection, isFalse);
    expect(
      mapbox.reasonCodes,
      contains('local_reviewed_odometer_history_required'),
    );
  });

  test('calibration owner mismatch and fleet observer mode fail closed', () {
    final mismatch = TripTrackingCalibrationApplyGuard.evaluate(
      signal: signal(),
      userOptedIn: true,
      userAcceptedLatestReview: true,
      minimumReviewedDays: 7,
      latestReviewedAtUtc: now,
      nowUtc: now,
      currentUserId: 'manager_1',
      calibrationOwnerUserId: 'driver_1',
    );
    final shared = TripTrackingCalibrationApplyGuard.evaluate(
      signal: signal(),
      userOptedIn: true,
      userAcceptedLatestReview: true,
      minimumReviewedDays: 7,
      latestReviewedAtUtc: now,
      nowUtc: now,
      currentUserId: 'manager_1',
      calibrationOwnerUserId: 'driver_1',
      explicitSharedVehicleAccess: true,
    );
    final observer = TripTrackingCalibrationApplyGuard.evaluate(
      signal: signal(),
      userOptedIn: true,
      userAcceptedLatestReview: true,
      minimumReviewedDays: 7,
      latestReviewedAtUtc: now,
      nowUtc: now,
      currentUserId: 'manager_1',
      calibrationOwnerUserId: 'driver_1',
      explicitSharedVehicleAccess: true,
      fleetObserverMode: true,
    );

    expect(mismatch.status, TripTrackingCalibrationApplyStatus.rejected);
    expect(
      mismatch.reasonCodes,
      contains('calibration_owner_or_explicit_access_required'),
    );
    expect(
      shared.status,
      TripTrackingCalibrationApplyStatus.readyForFutureProjection,
    );
    expect(observer.status, TripTrackingCalibrationApplyStatus.rejected);
    expect(observer.reasonCodes, contains('fleet_observer_read_only'));
  });

  test('unsafe user ids are rejected without leaking tokens', () {
    final guard = TripTrackingCalibrationApplyGuard.evaluate(
      signal: signal(),
      userOptedIn: true,
      userAcceptedLatestReview: true,
      minimumReviewedDays: 7,
      latestReviewedAtUtc: now,
      nowUtc: now,
      currentUserId: 'pk.public-token',
      calibrationOwnerUserId: 'driver_1',
    );

    expect(guard.status, TripTrackingCalibrationApplyStatus.rejected);
    expect(guard.reasonCodes, contains('unsafe_current_user_id'));
    expect(guard.toSafeDashboardMap().toString(), isNot(contains('pk.')));
  });

  test('safe calibration apply summary validates as renderable', () {
    final validation =
        TripTrackingCalibrationApplySummaryValidation.fromSummary(
          TripTrackingCalibrationApplyGuard.evaluate(
            signal: signal(),
            userOptedIn: true,
            userAcceptedLatestReview: true,
            minimumReviewedDays: 7,
            latestReviewedAtUtc: now,
            nowUtc: now,
          ).toSafeDashboardMap(),
        );

    expect(validation.isRenderable, isTrue);
    expect(
      validation.status,
      TripTrackingCalibrationApplyStatus.readyForFutureProjection,
    );
    expect(validation.reasons, isEmpty);
  });

  test(
    'calibration summary rejects mutation, remote, and sensitive claims',
    () {
      final validation =
          TripTrackingCalibrationApplySummaryValidation.fromSummary(
            TripTrackingCalibrationApplyGuard.evaluate(
              signal: signal(),
              userOptedIn: true,
              userAcceptedLatestReview: true,
              minimumReviewedDays: 7,
              latestReviewedAtUtc: now,
              nowUtc: now,
            ).toSafeDashboardMap()..addAll({
              'appliesToPastTrips': true,
              'canRewriteConfirmedOdometer': true,
              'canApplySilently': true,
              'calibrationCanChangeDisplayedConfirmedMiles': true,
              'calibrationCanMutateTripLog': true,
              'calibrationCanPurgeLocalDataAfterBackup': true,
              'calibrationCanBypassVehicleProfile': true,
              'calibrationCanApplyAcrossVehicles': true,
              'calibrationRequiresSingleVehicleHistory': false,
              'calibrationRequiresLocalReviewedOdometerHistory': false,
              'continuousCalibrationAverageRequired': false,
              'poorGpsDaysExcludedFromCalibration': false,
              'calibrationRequiresTrustedGpsWindow': false,
              'singleDayCalibrationRejected': false,
              'calibrationAverageVehicleScoped': false,
              'calibrationRequiresOwnershipOrExplicitAccess': false,
              'settingsCanDisableCalibrationAssist': false,
              'settingsCanResetCalibrationPrompt': false,
              'fleetObserverCanApplyCalibration': true,
              'calibrationVehicleIdIncluded': true,
              'rawVehicleIdsIncluded': true,
              'remoteCalibrationCanRewritePastTrips': true,
              'mapboxRouteDistanceCanBecomeOfficial': true,
              'firestoreCanApplyCalibration': true,
              'mapboxCanApplyCalibration': true,
              'cloudFunctionCanApplyCalibration': true,
              'importedFileCanApplyCalibration': true,
              'dashboardCacheCanApplyCalibration': true,
              'remoteCalibrationCanOverrideLocalState': true,
              'remoteCalibrationCanEnableSetting': true,
              'remoteCalibrationCanResetPrompt': true,
              'mapboxCanTriggerTirePrompt': true,
              'gpsCanAutoApplyCalibration': true,
              'odometerIsGlobalTruth': false,
              'physicalOdometerIsCanonical': false,
              'gpsCanOverrideOdometer': true,
              'mapboxCanOverrideOdometer': true,
              'firebaseMirrorCanOverrideOdometer': true,
              'cloudFunctionCanOverrideOdometer': true,
              'importedFileCanOverrideOdometer': true,
              'localCacheCanOverrideOdometer': true,
              'sensorFusionCanOverrideOdometer': true,
              'calibrationAppliesToFutureGpsProjectionOnly': false,
              'tireChangeDoesNotCreateMaintenanceEntry': false,
              'calibrationCanLowerConfirmedOdometer': true,
              'calibrationCanCreateMaintenanceRecord': true,
              'rawReviewedTripsIncluded': true,
              'rawGpsIncluded': true,
              'preciseLocationIncluded': true,
              'tokensIncluded': true,
              'debug': 'sk.secret 35.123456,-80.123456',
            }),
          );

      expect(validation.isRenderable, isFalse);
      expect(validation.reasons, contains('calibration_can_mutate_trip_truth'));
      expect(
        validation.reasons,
        contains('remote_or_map_can_apply_calibration'),
      );
      expect(
        validation.reasons,
        contains('remote_or_sensor_can_control_prompt'),
      );
      expect(
        validation.reasons,
        contains('calibration_review_boundary_missing'),
      );
      expect(validation.reasons, contains('odometer_truth_boundary_missing'));
      expect(
        validation.reasons,
        contains('summary_contains_sensitive_calibration_material'),
      );
      expect(validation.reasons, contains('summary_contains_sensitive_text'));
    },
  );
}
