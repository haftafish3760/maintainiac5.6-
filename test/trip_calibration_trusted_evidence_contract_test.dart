import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_gps_dependability_rollup_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_calibration_apply_guard.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_odometer_calibration.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  final now = DateTime.utc(2026, 7, 18, 12);

  test(
    'calibration signal exposes trusted and excluded GPS evidence counts',
    () {
      const signal = TripOdometerCalibrationSignal(
        status: TripOdometerCalibrationStatus.reviewRecommended,
        eligibleSampleCount: 7,
        trustedGpsWindowCount: 7,
        excludedPoorGpsDayCount: 2,
        averageGpsToOdometerRatio: .94,
        averageDifferencePercent: 6,
        reasonCode: 'persistent_gps_odometer_drift',
      );

      final safe = signal.toSafeDashboardMap();

      expect(safe['trustedGpsWindowCount'], 7);
      expect(safe['excludedPoorGpsDayCount'], 2);
      expect(safe['poorGpsDaysExcludedFromCalibration'], isTrue);
      expect(safe['calibrationRequiresTrustedGpsWindow'], isTrue);
      expect(safe['odometerIsGlobalTruth'], isTrue);
    },
  );

  test(
    'apply guard preserves evidence counts without granting odometer truth',
    () {
      const signal = TripOdometerCalibrationSignal(
        status: TripOdometerCalibrationStatus.reviewRecommended,
        eligibleSampleCount: 7,
        trustedGpsWindowCount: 7,
        excludedPoorGpsDayCount: 2,
        averageGpsToOdometerRatio: .94,
        averageDifferencePercent: 6,
        reasonCode: 'persistent_gps_odometer_drift',
      );

      final guard = TripTrackingCalibrationApplyGuard.evaluate(
        signal: signal,
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

      expect(guard.canApplyToFutureGpsProjection, isTrue);
      expect(safe['trustedGpsWindowCount'], 7);
      expect(safe['excludedPoorGpsDayCount'], 2);
      expect(safe['excludedPoorGpsDayCountIncluded'], isTrue);
      expect(safe['poorGpsExcludedDayCountTrustedAfterValidationOnly'], isTrue);
      expect(safe['gpsDependabilityRollupRequiredForCalibration'], isTrue);
      expect(safe['oneGoodGpsWindowCannotClearBadCalibrationDay'], isTrue);
      expect(safe['calibrationCanMutateTripLog'], isFalse);
      expect(safe['canRewriteConfirmedOdometer'], isFalse);
      expect(safe['odometerIsGlobalTruth'], isTrue);
    },
  );

  test('apply summary validation rejects forged evidence counters', () {
    final safe = TripTrackingCalibrationApplyGuard.evaluate(
      signal: const TripOdometerCalibrationSignal(
        status: TripOdometerCalibrationStatus.reviewRecommended,
        eligibleSampleCount: 7,
        trustedGpsWindowCount: 7,
        excludedPoorGpsDayCount: 2,
        averageGpsToOdometerRatio: .94,
        averageDifferencePercent: 6,
        reasonCode: 'persistent_gps_odometer_drift',
      ),
      userOptedIn: true,
      userAcceptedLatestReview: true,
      minimumReviewedDays: 7,
      latestReviewedAtUtc: now,
      nowUtc: now,
      activeVehicleId: 'vehicle_1',
      reviewedVehicleId: 'vehicle_1',
      reviewedVehicleIds: const ['vehicle_1'],
    ).toSafeDashboardMap();

    final validation =
        TripTrackingCalibrationApplySummaryValidation.fromSummary(
          safe..addAll({
            'trustedGpsWindowCount': 999,
            'excludedPoorGpsDayCount': -1,
            'canRewriteConfirmedOdometer': true,
          }),
        );

    expect(validation.isRenderable, isFalse);
    expect(validation.reasons, contains('invalid_trusted_gps_window_count'));
    expect(validation.reasons, contains('invalid_excluded_poor_gps_day_count'));
    expect(validation.reasons, contains('calibration_can_mutate_trip_truth'));
  });

  test('apply guard rejects calibration when GPS rollup excludes the day', () {
    final guard = TripTrackingCalibrationApplyGuard.evaluate(
      signal: const TripOdometerCalibrationSignal(
        status: TripOdometerCalibrationStatus.reviewRecommended,
        eligibleSampleCount: 7,
        trustedGpsWindowCount: 7,
        excludedPoorGpsDayCount: 1,
        averageGpsToOdometerRatio: .94,
        averageDifferencePercent: 6,
        reasonCode: 'persistent_gps_odometer_drift',
      ),
      userOptedIn: true,
      userAcceptedLatestReview: true,
      minimumReviewedDays: 7,
      latestReviewedAtUtc: now,
      nowUtc: now,
      activeVehicleId: 'vehicle_1',
      reviewedVehicleId: 'vehicle_1',
      reviewedVehicleIds: const ['vehicle_1'],
      gpsDependabilityRollup: const TripGpsDependabilityRollupDecision(
        status: TripGpsDependabilityRollupStatus.excludedFromCalibration,
        reasonCode: 'gps_rollup_projection_paused_window_present',
        windowCount: 8,
        readyWindowCount: 7,
        reviewOnlyWindowCount: 0,
        pausedWindowCount: 1,
        unsafeWindowCount: 0,
        canUseForLiveAssist: true,
        canUseForCalibrationEvidence: false,
        requiresUserReview: true,
      ),
    );
    final safe = guard.toSafeDashboardMap();

    expect(guard.status, TripTrackingCalibrationApplyStatus.rejected);
    expect(
      guard.reasonCodes,
      contains('gps_dependability_rollup_required_for_calibration'),
    );
    expect(safe['poorGpsWindowExcludesCalibrationDay'], isTrue);
    expect(safe['interruptedGpsWindowExcludesCalibrationDay'], isTrue);
    expect(safe['unsafeGpsWindowExcludesCalibrationDay'], isTrue);
    expect(
      TripTrackingCalibrationApplySummaryValidation.fromSummary(
        safe,
      ).isRenderable,
      isTrue,
    );
  });

  test('poor GPS day is excluded instead of averaged into calibration', () {
    final reviews = <TripTrackingReviewRecord>[
      for (var day = 0; day < 6; day += 1)
        _confirmedReview(
          id: 'trusted_day_$day',
          startedAt: DateTime.utc(2026, 7, 1 + day, 8),
          filteredGpsMiles: 110,
          odometerMiles: 100,
          diagnostics: _trustedDiagnostics,
        ),
      _confirmedReview(
        id: 'poor_day_7',
        startedAt: DateTime.utc(2026, 7, 7, 8),
        filteredGpsMiles: 110,
        odometerMiles: 100,
        diagnostics: _poorDiagnostics,
      ),
    ];

    final signal = TripOdometerCalibrationSignal.evaluateConfirmedReviews(
      reviews: reviews,
      vehicleId: 'vehicle_1',
      nowUtc: DateTime.utc(2026, 7, 18, 12),
    );
    final safe = signal.toSafeDashboardMap();

    expect(signal.status, TripOdometerCalibrationStatus.insufficientHistory);
    expect(signal.eligibleSampleCount, 6);
    expect(signal.trustedGpsWindowCount, 6);
    expect(signal.excludedPoorGpsDayCount, 1);
    expect(signal.gpsAssistanceCalibrationMultiplier, 1);
    expect(safe['poorGpsDaysExcludedFromCalibration'], isTrue);
    expect(safe['poorGpsDaysCannotCountAsTrustedWindow'], isTrue);
    expect(safe['excludedPoorGpsCannotBecomeCalibrationProof'], isTrue);
    expect(safe['odometerIsGlobalTruth'], isTrue);
  });

  test('one poor segment contaminates that whole calibration day', () {
    final reviews = <TripTrackingReviewRecord>[
      for (var day = 0; day < 6; day += 1)
        _confirmedReview(
          id: 'trusted_day_$day',
          startedAt: DateTime.utc(2026, 7, 1 + day, 8),
          filteredGpsMiles: 110,
          odometerMiles: 100,
          diagnostics: _trustedDiagnostics,
        ),
      _confirmedReview(
        id: 'mixed_day_good',
        startedAt: DateTime.utc(2026, 7, 7, 8),
        filteredGpsMiles: 55,
        odometerMiles: 50,
        diagnostics: _trustedDiagnostics,
      ),
      _confirmedReview(
        id: 'mixed_day_poor',
        startedAt: DateTime.utc(2026, 7, 7, 15),
        filteredGpsMiles: 55,
        odometerMiles: 50,
        diagnostics: _poorDiagnostics,
      ),
      _confirmedReview(
        id: 'trusted_day_8',
        startedAt: DateTime.utc(2026, 7, 8, 8),
        filteredGpsMiles: 110,
        odometerMiles: 100,
        diagnostics: _trustedDiagnostics,
      ),
    ];

    final signal = TripOdometerCalibrationSignal.evaluateConfirmedReviews(
      reviews: reviews,
      vehicleId: 'vehicle_1',
      nowUtc: DateTime.utc(2026, 7, 18, 12),
    );

    expect(signal.status, TripOdometerCalibrationStatus.reviewRecommended);
    expect(signal.eligibleSampleCount, 7);
    expect(signal.trustedGpsWindowCount, 7);
    expect(signal.excludedPoorGpsDayCount, 1);
    expect(signal.averageGpsToOdometerRatio, closeTo(1.1, .001));
    expect(signal.gpsAssistanceCalibrationMultiplier, closeTo(.9091, .001));
  });

  test('recent trusted calibration days can adapt after a tire-size change', () {
    final reviews = <TripTrackingReviewRecord>[
      for (var day = 0; day < 7; day += 1)
        _confirmedReview(
          id: 'old_tire_$day',
          startedAt: DateTime.utc(2026, 6, 1 + day, 8),
          filteredGpsMiles: 90,
          odometerMiles: 100,
          diagnostics: _trustedDiagnostics,
        ),
      for (var day = 0; day < 7; day += 1)
        _confirmedReview(
          id: 'new_tire_$day',
          startedAt: DateTime.utc(2026, 7, 1 + day, 8),
          filteredGpsMiles: 110,
          odometerMiles: 100,
          diagnostics: _trustedDiagnostics,
        ),
    ];

    final signal = TripOdometerCalibrationSignal.evaluateConfirmedReviews(
      reviews: reviews,
      vehicleId: 'vehicle_1',
      nowUtc: DateTime.utc(2026, 7, 18, 12),
    );

    expect(signal.eligibleSampleCount, 7);
    expect(signal.averageGpsToOdometerRatio, closeTo(1.1, .001));
    expect(signal.gpsAssistanceCalibrationMultiplier, closeTo(.9091, .001));
  });

  test('daily GPS rollup can exclude an otherwise trusted calibration day', () {
    final reviews = <TripTrackingReviewRecord>[
      for (var day = 0; day < 7; day += 1)
        _confirmedReview(
          id: 'trusted_day_$day',
          startedAt: DateTime.utc(2026, 7, 1 + day, 8),
          filteredGpsMiles: 110,
          odometerMiles: 100,
          diagnostics: _trustedDiagnostics,
        ),
    ];

    final signal = TripOdometerCalibrationSignal.evaluateConfirmedReviews(
      reviews: reviews,
      vehicleId: 'vehicle_1',
      nowUtc: DateTime.utc(2026, 7, 18, 12),
      dailyGpsDependabilityRollups: {
        '2026-07-07': const TripGpsDependabilityRollupDecision(
          status: TripGpsDependabilityRollupStatus.excludedFromCalibration,
          reasonCode: 'gps_rollup_projection_paused_window_present',
          windowCount: 8,
          readyWindowCount: 7,
          reviewOnlyWindowCount: 0,
          pausedWindowCount: 1,
          unsafeWindowCount: 0,
          canUseForLiveAssist: true,
          canUseForCalibrationEvidence: false,
          requiresUserReview: true,
        ),
      },
    );
    final safe = signal.toSafeDashboardMap();

    expect(signal.status, TripOdometerCalibrationStatus.insufficientHistory);
    expect(signal.eligibleSampleCount, 6);
    expect(signal.trustedGpsWindowCount, 6);
    expect(signal.excludedPoorGpsDayCount, 1);
    expect(safe['poorGpsDaysExcludedFromCalibration'], isTrue);
    expect(safe['calibrationRequiresTrustedGpsWindow'], isTrue);
    expect(safe['odometerIsGlobalTruth'], isTrue);
  });

  test('stale reviewed history cannot calibrate a vehicle after the review window', () {
    final reviews = <TripTrackingReviewRecord>[
      _confirmedReview(
        id: 'stale_tire_configuration',
        startedAt: DateTime.utc(2026, 6, 1, 8),
        filteredGpsMiles: 110,
        odometerMiles: 100,
        diagnostics: _trustedDiagnostics,
      ),
      for (var day = 0; day < 6; day += 1)
        _confirmedReview(
          id: 'recent_day_$day',
          startedAt: DateTime.utc(2026, 7, 1 + day, 8),
          filteredGpsMiles: 110,
          odometerMiles: 100,
          diagnostics: _trustedDiagnostics,
        ),
    ];

    final signal = TripOdometerCalibrationSignal.evaluateConfirmedReviews(
      reviews: reviews,
      vehicleId: 'vehicle_1',
      nowUtc: DateTime.utc(2026, 7, 18, 12),
    );

    expect(signal.status, TripOdometerCalibrationStatus.insufficientHistory);
    expect(signal.eligibleSampleCount, 6);
    expect(signal.gpsAssistanceCalibrationMultiplier, 1);
  });

  test('unknown GPS diagnostics fail neutral until explicitly allowed', () {
    final reviews = <TripTrackingReviewRecord>[
      for (var day = 0; day < 7; day += 1)
        _confirmedReview(
          id: 'unknown_signal_day_$day',
          startedAt: DateTime.utc(2026, 7, 1 + day, 8),
          filteredGpsMiles: 110,
          odometerMiles: 100,
          diagnostics: const TripTrackingDiagnostics(),
        ),
    ];

    final strictSignal = TripOdometerCalibrationSignal.evaluateConfirmedReviews(
      reviews: reviews,
      vehicleId: 'vehicle_1',
      nowUtc: DateTime.utc(2026, 7, 18, 12),
    );
    final legacySignal = TripOdometerCalibrationSignal.evaluateConfirmedReviews(
      reviews: reviews,
      vehicleId: 'vehicle_1',
      nowUtc: DateTime.utc(2026, 7, 18, 12),
      requireTrustedSignalDiagnostics: false,
    );

    expect(
      strictSignal.status,
      TripOdometerCalibrationStatus.insufficientHistory,
    );
    expect(strictSignal.eligibleSampleCount, 0);
    expect(strictSignal.trustedGpsWindowCount, 0);
    expect(strictSignal.excludedPoorGpsDayCount, 7);
    expect(strictSignal.gpsAssistanceCalibrationMultiplier, 1);
    expect(
      legacySignal.status,
      TripOdometerCalibrationStatus.reviewRecommended,
    );
    expect(legacySignal.eligibleSampleCount, 7);
    expect(
      legacySignal.gpsAssistanceCalibrationMultiplier,
      closeTo(.9091, .001),
    );
  });

  test('speed conflict GPS days cannot become calibration evidence', () {
    final reviews = <TripTrackingReviewRecord>[
      for (var day = 0; day < 7; day += 1)
        _confirmedReview(
          id: 'conflicted_signal_day_$day',
          startedAt: DateTime.utc(2026, 7, 1 + day, 8),
          filteredGpsMiles: 110,
          odometerMiles: 100,
          diagnostics: const TripTrackingDiagnostics(
            receivedSamples: 100,
            acceptedSamples: 70,
            dispositionCounts: {
              TripSampleDisposition.acceptedDistance: 70,
              TripSampleDisposition.rejectedSpeedConflict: 30,
            },
          ),
        ),
    ];

    final signal = TripOdometerCalibrationSignal.evaluateConfirmedReviews(
      reviews: reviews,
      vehicleId: 'vehicle_1',
      nowUtc: DateTime.utc(2026, 7, 18, 12),
    );

    expect(signal.status, TripOdometerCalibrationStatus.insufficientHistory);
    expect(signal.eligibleSampleCount, 0);
    expect(signal.trustedGpsWindowCount, 0);
    expect(signal.excludedPoorGpsDayCount, 7);
    expect(signal.gpsAssistanceCalibrationMultiplier, 1);
  });

  test('single critical GPS reject contaminates calibration day', () {
    for (final criticalReject in const [
      TripSampleDisposition.rejectedMockLocation,
      TripSampleDisposition.rejectedFutureTimestamp,
      TripSampleDisposition.rejectedOutOfOrder,
      TripSampleDisposition.rejectedImplausibleSpeed,
      TripSampleDisposition.rejectedSpeedConflict,
      TripSampleDisposition.rejectedGap,
    ]) {
      final reviews = <TripTrackingReviewRecord>[
        for (var day = 0; day < 6; day += 1)
          _confirmedReview(
            id: 'trusted_day_${criticalReject.name}_$day',
            startedAt: DateTime.utc(2026, 7, 1 + day, 8),
            filteredGpsMiles: 110,
            odometerMiles: 100,
            diagnostics: _trustedDiagnostics,
          ),
        _confirmedReview(
          id: 'critical_reject_${criticalReject.name}',
          startedAt: DateTime.utc(2026, 7, 7, 8),
          filteredGpsMiles: 110,
          odometerMiles: 100,
          diagnostics: TripTrackingDiagnostics(
            receivedSamples: 100,
            acceptedSamples: 99,
            dispositionCounts: {
              TripSampleDisposition.acceptedDistance: 99,
              criticalReject: 1,
            },
          ),
        ),
      ];

      final signal = TripOdometerCalibrationSignal.evaluateConfirmedReviews(
        reviews: reviews,
        vehicleId: 'vehicle_1',
        nowUtc: DateTime.utc(2026, 7, 18, 12),
      );

      expect(
        signal.status,
        TripOdometerCalibrationStatus.insufficientHistory,
        reason: criticalReject.name,
      );
      expect(signal.eligibleSampleCount, 6, reason: criticalReject.name);
      expect(signal.trustedGpsWindowCount, 6, reason: criticalReject.name);
      expect(signal.excludedPoorGpsDayCount, 1, reason: criticalReject.name);
      expect(signal.gpsAssistanceCalibrationMultiplier, 1);
    }
  });
}

const _trustedDiagnostics = TripTrackingDiagnostics(
  receivedSamples: 100,
  acceptedSamples: 90,
  dispositionCounts: {
    TripSampleDisposition.acceptedDistance: 90,
    TripSampleDisposition.rejectedAccuracy: 10,
  },
);

const _poorDiagnostics = TripTrackingDiagnostics(
  receivedSamples: 100,
  acceptedSamples: 50,
  dispositionCounts: {
    TripSampleDisposition.acceptedDistance: 50,
    TripSampleDisposition.rejectedAccuracy: 50,
  },
);

TripTrackingReviewRecord _confirmedReview({
  required String id,
  required DateTime startedAt,
  required double filteredGpsMiles,
  required int odometerMiles,
  required TripTrackingDiagnostics diagnostics,
}) {
  const startingOdometer = 1000;
  return TripTrackingReviewRecord(
    id: id,
    vehicleId: 'vehicle_1',
    startingOdometer: startingOdometer,
    estimatedEndingOdometer: startingOdometer + odometerMiles,
    confirmedEndingOdometer: startingOdometer + odometerMiles,
    profile: TripTrackingProfile.roadVehicle,
    startedAt: startedAt,
    finishedAt: startedAt.add(const Duration(hours: 2)),
    odometerConfirmedAt: startedAt.add(const Duration(hours: 3)),
    engineSnapshot: TripTrackingEngineSnapshot(
      totalAcceptedMeters: filteredGpsMiles * 1609.344,
      walkingReviewSuggested: false,
      diagnostics: diagnostics,
    ),
  );
}
