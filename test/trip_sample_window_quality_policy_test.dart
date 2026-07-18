import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_route_history_capture_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_sample_window_quality_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_signal_quality.dart';

void main() {
  final start = DateTime.utc(2026, 7, 18, 12);

  TripLocationSample sample(
    int seconds,
    double latitude,
    double longitude, {
    double accuracy = 12,
    double? speed,
    bool? mocked,
  }) {
    return TripLocationSample(
      latitude: latitude,
      longitude: longitude,
      recordedAt: start.add(Duration(seconds: seconds)),
      horizontalAccuracyMeters: accuracy,
      speedMetersPerSecond: speed,
      mockedLocation: mocked,
    );
  }

  TripRouteHistoryCaptureDecision routeDecision({
    bool optedIntoMaps = true,
    bool optedIntoHistory = true,
    int storageMb = 2000,
    double budgetMb = 1,
    int intervalSeconds = 15,
  }) {
    return TripRouteHistoryCapturePolicy.evaluate(
      accountTier: TripRouteHistoryAccountTier.free,
      gpsAssistedTrackingEnabled: true,
      userOptedIntoMaps: optedIntoMaps,
      userOptedIntoRouteHistory: optedIntoHistory,
      mapboxRuntimeAvailable: optedIntoMaps,
      requestedDailyBudgetMb: budgetMb,
      availableStorageMb: storageMb,
      requestedSampleIntervalSeconds: intervalSeconds,
    );
  }

  test('usable sample window can feed live odometer projection only', () {
    final decision = TripSampleWindowQualityPolicy.evaluate(
      samples: [
        sample(0, 35.0000, -80.0000, speed: 4),
        sample(15, 35.0003, -80.0000, speed: 4),
        sample(30, 35.0006, -80.0000, speed: 4),
      ],
      routeHistoryDecision: routeDecision(),
    );

    expect(decision.status, TripSampleWindowQualityStatus.usableForTracking);
    expect(decision.canFeedLiveOdometerProjection, isTrue);
    expect(decision.canPersistCompactRoutePoint, isTrue);
    expect(decision.acceptedDistanceMeters, greaterThan(50));
  });

  test('stationary speed reports pause GPS jitter projection', () {
    final decision = TripSampleWindowQualityPolicy.evaluate(
      samples: [
        sample(0, 35.0000, -80.0000, speed: 0),
        sample(15, 35.0004, -80.0000, speed: 0.2),
        sample(30, 35.0008, -80.0000, speed: 0.1),
      ],
      routeHistoryDecision: routeDecision(),
    );
    final safe = decision.toSafeDashboardMap();

    expect(decision.status, TripSampleWindowQualityStatus.usableForTracking);
    expect(decision.reasonCode, 'sample_window_projection_paused');
    expect(decision.acceptedDistanceMeters, greaterThan(75));
    expect(decision.canFeedLiveOdometerProjection, isFalse);
    expect(decision.canPersistCompactRoutePoint, isFalse);
    expect(safe['sampleWindowRequiresMovementCorroboration'], isTrue);
    expect(safe['sampleWindowCanConfirmOdometer'], isFalse);
  });

  test('route storage can pause without stopping GPS tracking', () {
    final history = routeDecision(budgetMb: 0.25);
    final decision = TripSampleWindowQualityPolicy.evaluate(
      samples: [sample(0, 35.0000, -80.0000), sample(15, 35.0003, -80.0000)],
      routeHistoryDecision: history,
      persistedRoutePointsToday: history.maximumRetainedPointsPerDay,
    );
    final safe = decision.toSafeDashboardMap();

    expect(decision.status, TripSampleWindowQualityStatus.routeStoragePaused);
    expect(decision.canFeedLiveOdometerProjection, isTrue);
    expect(decision.canPersistCompactRoutePoint, isFalse);
    expect(safe['routeStorageCanPauseWithoutStoppingTrip'], isTrue);
    expect(safe['sampleWindowCanConfirmOdometer'], isFalse);
    expect(safe['sampleWindowCanSetGlobalTruth'], isFalse);
    expect(safe['sampleWindowCanChangeOfficialMileage'], isFalse);
    expect(safe['sampleWindowRequiresLocalDeviceSource'], isTrue);
    expect(safe['sampleWindowRequiresOwnershipValidation'], isTrue);
    expect(safe['sampleWindowRequiresIntakeGuardBeforeEvaluation'], isTrue);
    expect(safe['sampleWindowRequiresTrustedGpsSignal'], isTrue);
    expect(safe['simulatorWindowRequiresExplicitTestHarness'], isTrue);
    expect(safe['simulatorWindowCannotWriteProductionHistory'], isTrue);
    expect(safe['authenticationAloneAuthorizesWindowUse'], isFalse);
  });

  test(
    'maps disabled still allows tracking but not compact route persistence',
    () {
      final decision = TripSampleWindowQualityPolicy.evaluate(
        samples: [sample(0, 35.0000, -80.0000), sample(30, 35.0002, -80.0000)],
        routeHistoryDecision: routeDecision(optedIntoMaps: false),
      );
      final safe = decision.toSafeDashboardMap();

      expect(decision.status, TripSampleWindowQualityStatus.usableForTracking);
      expect(decision.canFeedLiveOdometerProjection, isTrue);
      expect(decision.canPersistCompactRoutePoint, isFalse);
      expect(safe['mapsRequiredForGpsTracking'], isFalse);
    },
  );

  test('bad accuracy mocked samples and impossible speed are rejected', () {
    final decision = TripSampleWindowQualityPolicy.evaluate(
      samples: [
        sample(0, 35.0000, -80.0000, accuracy: 500),
        sample(10, 35.0001, -80.0000, mocked: true),
        sample(20, 35.0002, -80.0000, speed: 90),
      ],
      routeHistoryDecision: routeDecision(),
    );

    expect(decision.status, TripSampleWindowQualityStatus.degradedTrackingOnly);
    expect(decision.validSampleCount, 0);
    expect(decision.rejectedSampleCount, 3);
    expect(decision.canFeedLiveOdometerProjection, isFalse);
  });

  test('reported GPS speed boundary accepts 70 mps and rejects above it', () {
    final boundary = TripSampleWindowQualityPolicy.evaluate(
      samples: [
        sample(0, 35.0000, -80.0000, speed: 70),
        sample(30, 35.0002, -80.0000, speed: 70),
      ],
      routeHistoryDecision: routeDecision(),
    );
    final aboveBoundary = TripSampleWindowQualityPolicy.evaluate(
      samples: [
        sample(0, 35.0000, -80.0000, speed: 70.1),
        sample(30, 35.0002, -80.0000, speed: 70.1),
      ],
      routeHistoryDecision: routeDecision(),
    );
    final malformed = TripSampleWindowQualityPolicy.evaluate(
      samples: [
        sample(0, 35.0000, -80.0000, speed: double.nan),
        sample(30, 35.0002, -80.0000, speed: double.infinity),
      ],
      routeHistoryDecision: routeDecision(),
    );

    expect(boundary.status, TripSampleWindowQualityStatus.usableForTracking);
    expect(boundary.validSampleCount, 2);
    expect(boundary.rejectedSampleCount, 0);
    expect(
      aboveBoundary.status,
      TripSampleWindowQualityStatus.degradedTrackingOnly,
    );
    expect(aboveBoundary.validSampleCount, 0);
    expect(aboveBoundary.rejectedSampleCount, 2);
    expect(malformed.validSampleCount, 0);
    expect(malformed.rejectedSampleCount, 2);
    expect(malformed.canFeedLiveOdometerProjection, isFalse);
  });

  test(
    'poor or interrupted GPS pauses projection and compact route points',
    () {
      for (final quality in const [
        TripTrackingSignalQuality.noSamples,
        TripTrackingSignalQuality.poor,
        TripTrackingSignalQuality.interrupted,
      ]) {
        final decision = TripSampleWindowQualityPolicy.evaluate(
          samples: [
            sample(0, 35.0000, -80.0000),
            sample(15, 35.0002, -80.0000),
            sample(30, 35.0004, -80.0000),
          ],
          routeHistoryDecision: routeDecision(),
          signalQuality: quality,
        );
        final safe = decision.toSafeDashboardMap();

        expect(
          decision.status,
          TripSampleWindowQualityStatus.usableForTracking,
        );
        expect(decision.canFeedLiveOdometerProjection, isFalse);
        expect(decision.canPersistCompactRoutePoint, isFalse);
        expect(safe['poorGpsPausesLiveProjection'], isTrue);
        expect(safe['interruptedGpsPausesLiveProjection'], isTrue);
        expect(safe['missingGpsPausesLiveProjection'], isTrue);
        expect(
          TripSampleWindowQualitySummaryValidation.fromSummary(
            safe,
          ).isRenderable,
          isTrue,
        );
      }
    },
  );

  test('unsafe GPS rejects the sample window before live projection', () {
    final decision = TripSampleWindowQualityPolicy.evaluate(
      samples: [sample(0, 35.0000, -80.0000), sample(15, 35.0002, -80.0000)],
      routeHistoryDecision: routeDecision(),
      signalQuality: TripTrackingSignalQuality.unsafe,
    );
    final safe = decision.toSafeDashboardMap();

    expect(decision.status, TripSampleWindowQualityStatus.unsafeRejected);
    expect(decision.reasonCode, 'sample_window_unsafe_gps_signal');
    expect(decision.canFeedLiveOdometerProjection, isFalse);
    expect(decision.canPersistCompactRoutePoint, isFalse);
    expect(safe['unsafeGpsBlocksSampleWindow'], isTrue);
  });

  test('future samples are rejected when an evaluation clock is supplied', () {
    final decision = TripSampleWindowQualityPolicy.evaluate(
      evaluationNow: start.add(const Duration(minutes: 10)),
      maximumFutureSkew: const Duration(seconds: 30),
      samples: [
        sample(580, 35.0000, -80.0000),
        sample(600, 35.0002, -80.0000),
        sample(720, 35.0004, -80.0000),
      ],
      routeHistoryDecision: routeDecision(),
    );
    final safe = decision.toSafeDashboardMap();

    expect(decision.status, TripSampleWindowQualityStatus.degradedTrackingOnly);
    expect(decision.validSampleCount, 2);
    expect(decision.rejectedSampleCount, 1);
    expect(decision.canFeedLiveOdometerProjection, isTrue);
    expect(safe['futureSamplesRejected'], isTrue);
    expect(safe['remoteWindowCanRepairInvalidSamples'], isFalse);
  });

  test('duplicate timestamps reject a segment before live projection', () {
    final decision = TripSampleWindowQualityPolicy.evaluate(
      samples: [
        sample(0, 35.0000, -80.0000),
        sample(0, 35.0002, -80.0000),
        sample(20, 35.0004, -80.0000),
      ],
      routeHistoryDecision: routeDecision(),
    );
    final safe = decision.toSafeDashboardMap();

    expect(decision.status, TripSampleWindowQualityStatus.degradedTrackingOnly);
    expect(decision.rejectedGapSegmentCount, 1);
    expect(decision.acceptedSegmentCount, 1);
    expect(decision.canFeedLiveOdometerProjection, isFalse);
    expect(safe['duplicateOrOutOfOrderSegmentsRejected'], isTrue);
    expect(safe['sampleWindowCanConfirmOdometer'], isFalse);
  });

  test('stale samples fail closed instead of reviving old daytime mileage', () {
    final decision = TripSampleWindowQualityPolicy.evaluate(
      evaluationNow: start.add(const Duration(hours: 12)),
      maximumSampleAge: const Duration(minutes: 30),
      samples: [
        sample(0, 35.0000, -80.0000),
        sample(20, 35.0002, -80.0000),
        sample(43_100, 35.0004, -80.0000),
      ],
      routeHistoryDecision: routeDecision(),
    );
    final safe = decision.toSafeDashboardMap();

    expect(decision.status, TripSampleWindowQualityStatus.degradedTrackingOnly);
    expect(decision.validSampleCount, 1);
    expect(decision.rejectedSampleCount, 2);
    expect(decision.canFeedLiveOdometerProjection, isFalse);
    expect(safe['staleSamplesRejectedWhenEvaluationClockProvided'], isTrue);
    expect(safe['remoteWindowCanOverrideLocalTrip'], isFalse);
  });

  test('epoch timestamps are rejected even without a device clock', () {
    final epoch = TripLocationSample(
      latitude: 35,
      longitude: -80,
      recordedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      horizontalAccuracyMeters: 10,
    );
    final decision = TripSampleWindowQualityPolicy.evaluate(
      samples: [epoch, sample(20, 35.0002, -80.0000)],
      routeHistoryDecision: routeDecision(),
    );

    expect(decision.status, TripSampleWindowQualityStatus.degradedTrackingOnly);
    expect(decision.validSampleCount, 1);
    expect(decision.rejectedSampleCount, 1);
    expect(decision.canFeedLiveOdometerProjection, isFalse);
  });

  test('jumped segments fail closed instead of inflating distance', () {
    final decision = TripSampleWindowQualityPolicy.evaluate(
      samples: [sample(0, 35.0000, -80.0000), sample(10, 36.0000, -81.0000)],
      routeHistoryDecision: routeDecision(),
    );

    expect(decision.status, TripSampleWindowQualityStatus.unsafeRejected);
    expect(decision.acceptedDistanceMeters, 0);
    expect(decision.canFeedLiveOdometerProjection, isFalse);
  });

  test('large gaps degrade and pause live projection safely', () {
    final decision = TripSampleWindowQualityPolicy.evaluate(
      samples: [
        sample(0, 35.0000, -80.0000),
        sample(30, 35.0002, -80.0000),
        sample(500, 35.0004, -80.0000),
      ],
      routeHistoryDecision: routeDecision(),
      maximumAcceptedGapSeconds: 60,
    );

    expect(decision.status, TripSampleWindowQualityStatus.degradedTrackingOnly);
    expect(decision.reasonCode, 'sample_window_projection_paused');
    expect(decision.canFeedLiveOdometerProjection, isFalse);
    expect(decision.acceptedSegmentCount, 1);
    expect(decision.rejectedGapSegmentCount, 1);
    expect(decision.rejectedSampleCount, 1);
    expect(decision.maximumGapSeconds, 470);
  });

  test('broken sample windows pause live odometer projection', () {
    final decision = TripSampleWindowQualityPolicy.evaluate(
      samples: [
        sample(0, 35.0000, -80.0000),
        sample(20, 35.0002, -80.0000),
        sample(500, 36.0000, -81.0000),
        sample(900, 36.5000, -81.5000),
        sample(1300, 37.0000, -82.0000),
      ],
      routeHistoryDecision: routeDecision(),
      maximumAcceptedGapSeconds: 60,
    );
    final safe = decision.toSafeDashboardMap();

    expect(decision.status, TripSampleWindowQualityStatus.degradedTrackingOnly);
    expect(decision.reasonCode, 'sample_window_projection_paused');
    expect(decision.acceptedSegmentCount, 1);
    expect(decision.rejectedGapSegmentCount, greaterThanOrEqualTo(3));
    expect(
      decision.maximumConsecutiveRejectedSegments,
      greaterThanOrEqualTo(3),
    );
    expect(decision.canFeedLiveOdometerProjection, isFalse);
    expect(safe['projectionPausesOnSparseOrBrokenWindow'], isTrue);
    expect(safe['segmentRejectionReasonsCounted'], isTrue);
  });

  test('segment rejection accounting separates jumps from speed failures', () {
    final decision = TripSampleWindowQualityPolicy.evaluate(
      samples: [
        sample(0, 35.0000, -80.0000),
        sample(10, 35.0002, -80.0000),
        sample(20, 35.5000, -80.5000),
      ],
      routeHistoryDecision: routeDecision(),
      maximumPointJumpMeters: 1000,
    );
    final safe = decision.toSafeDashboardMap();

    expect(decision.status, TripSampleWindowQualityStatus.degradedTrackingOnly);
    expect(decision.acceptedSegmentCount, 1);
    expect(decision.rejectedJumpSegmentCount, 1);
    expect(decision.rejectedSpeedSegmentCount, 1);
    expect(decision.canFeedLiveOdometerProjection, isFalse);
    expect(safe['rejectedJumpSegmentCount'], 1);
    expect(safe['rejectedSpeedSegmentCount'], 1);
    expect(safe['sampleWindowCanConfirmOdometer'], isFalse);
  });

  test('equal accepted and rejected segment counts pause live projection', () {
    final decision = TripSampleWindowQualityPolicy.evaluate(
      samples: [
        sample(0, 35.0000, -80.0000),
        sample(20, 35.0002, -80.0000),
        sample(40, 35.7000, -80.7000),
        sample(60, 36.0000, -81.0000),
        sample(80, 36.0002, -81.0000),
      ],
      routeHistoryDecision: routeDecision(),
      maximumPointJumpMeters: 1000,
    );

    expect(decision.status, TripSampleWindowQualityStatus.degradedTrackingOnly);
    expect(decision.acceptedSegmentCount, 2);
    expect(decision.rejectedJumpSegmentCount, 2);
    expect(decision.canFeedLiveOdometerProjection, isFalse);
    expect(decision.reasonCode, 'sample_window_projection_paused');
  });

  test('safe dashboard map never exposes raw route or token data', () {
    final safe = TripSampleWindowQualityPolicy.evaluate(
      samples: [sample(0, 35.0000, -80.0000), sample(15, 35.0002, -80.0000)],
      routeHistoryDecision: routeDecision(),
    ).toSafeDashboardMap();

    expect(safe['rawSamplesIncluded'], isFalse);
    expect(safe['coordinatesIncluded'], isFalse);
    expect(safe['routeGeometryIncluded'], isFalse);
    expect(safe['tokensIncluded'], isFalse);
    expect(safe['remoteWindowCanOverrideLocalTrip'], isFalse);
    expect(safe['remoteWindowCanRepairInvalidSamples'], isFalse);
    expect(safe['odometerRemainsOfficialMileageTruth'], isTrue);
    expect(safe['sampleTimestampsValidated'], isTrue);
    expect(safe['acceptedSegmentCount'], 1);
    expect(safe['rejectedGapSegmentCount'], 0);
  });

  test('sample window summary validation accepts safe advisory windows', () {
    final summary = TripSampleWindowQualityPolicy.evaluate(
      samples: [sample(0, 35.0000, -80.0000), sample(15, 35.0002, -80.0000)],
      routeHistoryDecision: routeDecision(),
    ).toSafeDashboardMap();

    final validation = TripSampleWindowQualitySummaryValidation.fromSummary(
      summary,
    );

    expect(validation.isRenderable, isTrue);
    expect(validation.status, TripSampleWindowQualityStatus.usableForTracking);
    expect(validation.reasons, isEmpty);
  });

  test('sample window validation rejects remote and auth-only authority', () {
    final summary =
        TripSampleWindowQualityPolicy.evaluate(
          samples: [
            sample(0, 35.0000, -80.0000),
            sample(15, 35.0002, -80.0000),
          ],
          routeHistoryDecision: routeDecision(),
        ).toSafeDashboardMap()..addAll({
          'sampleWindowRequiresLocalDeviceSource': false,
          'sampleWindowRequiresOwnershipValidation': false,
          'sampleWindowRequiresIntakeGuardBeforeEvaluation': false,
          'sampleWindowRequiresDeviceCapabilityContext': false,
          'sampleWindowRequiresMonotonicSampleOrder': false,
          'sampleWindowRequiresPermissionContinuity': false,
          'sampleWindowRequiresTrustedGpsSignal': false,
          'poorGpsPausesLiveProjection': false,
          'interruptedGpsPausesLiveProjection': false,
          'missingGpsPausesLiveProjection': false,
          'unsafeGpsBlocksSampleWindow': false,
          'simulatorWindowRequiresExplicitTestHarness': false,
          'simulatorWindowCannotWriteProductionHistory': false,
          'authenticationAloneAuthorizesWindowUse': true,
          'mapboxCanOverrideWindowQuality': true,
          'firestoreCanOverrideWindowQuality': true,
          'remoteWindowCanOverrideLocalTrip': true,
          'remoteWindowCanRepairInvalidSamples': true,
          'mapboxCanFillSampleGaps': true,
          'cloudFunctionCanRepairSampleWindow': true,
        });

    final validation = TripSampleWindowQualitySummaryValidation.fromSummary(
      summary,
    );

    expect(validation.isRenderable, isFalse);
    expect(
      validation.reasons,
      contains('sample_window_authorization_boundary_missing'),
    );
    expect(
      validation.reasons,
      contains('sample_window_gps_quality_boundary_missing'),
    );
    expect(validation.reasons, contains('remote_can_override_sample_window'));
  });

  test(
    'sample window validation rejects trip truth and sensitive payloads',
    () {
      final summary =
          TripSampleWindowQualityPolicy.evaluate(
            samples: [
              sample(0, 35.0000, -80.0000),
              sample(15, 35.0002, -80.0000),
            ],
            routeHistoryDecision: routeDecision(),
          ).toSafeDashboardMap()..addAll({
            'sampleWindowCanConfirmOdometer': true,
            'sampleWindowCanSetGlobalTruth': true,
            'sampleWindowCanChangeOfficialMileage': true,
            'sampleWindowCanCreateOfficialStop': true,
            'sampleWindowCanBypassStopDebounce': true,
            'sampleWindowCanAutocorrectCalibration': true,
            'sampleWindowCanDeleteTripData': true,
            'duplicateOrOutOfOrderSegmentsRejected': false,
            'odometerRemainsOfficialMileageTruth': false,
            'rawSamplesIncluded': true,
            'coordinatesIncluded': true,
            'preciseTimestampsIncluded': true,
            'routeGeometryIncluded': true,
            'tokensIncluded': true,
            'debug': 'pk.redacted 35.123456,-80.123456',
          });

      final validation = TripSampleWindowQualitySummaryValidation.fromSummary(
        summary,
      );

      expect(validation.isRenderable, isFalse);
      expect(
        validation.reasons,
        contains('sample_window_claims_trip_truth_authority'),
      );
      expect(
        validation.reasons,
        contains('summary_contains_sensitive_sample_material'),
      );
    },
  );

  test('sample window validation rejects status authority mismatch', () {
    final usable = TripSampleWindowQualityPolicy.evaluate(
      samples: [sample(0, 35.0000, -80.0000), sample(15, 35.0002, -80.0000)],
      routeHistoryDecision: routeDecision(),
    ).toSafeDashboardMap();
    final degraded = TripSampleWindowQualityPolicy.evaluate(
      samples: [
        sample(0, 35.0000, -80.0000),
        sample(20, 35.0002, -80.0000),
        sample(500, 36.0000, -81.0000),
      ],
      routeHistoryDecision: routeDecision(),
      maximumAcceptedGapSeconds: 60,
    ).toSafeDashboardMap();

    final forgedUsable = TripSampleWindowQualitySummaryValidation.fromSummary({
      ...usable,
      'canFeedLiveOdometerProjection': false,
      'acceptedSegmentCount': 0,
    });
    final forgedDegraded =
        TripSampleWindowQualitySummaryValidation.fromSummary({
          ...degraded,
          'canFeedLiveOdometerProjection': true,
          'canPersistCompactRoutePoint': true,
        });

    expect(forgedUsable.isRenderable, isFalse);
    expect(forgedDegraded.isRenderable, isFalse);
    expect(
      forgedUsable.reasons,
      contains('sample_window_status_conflicts_with_authority'),
    );
    expect(
      forgedDegraded.reasons,
      contains('sample_window_status_conflicts_with_authority'),
    );
  });
}
