import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_route_history_capture_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_sample_window_quality_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';

void main() {
  final start = DateTime.utc(2026, 7, 18, 12);

  test('sample window validation rejects remote and auth-only authority', () {
    final summary = _summary(start)
      ..addAll({
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
      final summary = _summary(start)
        ..addAll({
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
    final usable = _summary(start);
    final degraded = TripSampleWindowQualityPolicy.evaluate(
      samples: [
        _sample(start, 0, 35.0000, -80.0000),
        _sample(start, 20, 35.0002, -80.0000),
        _sample(start, 500, 36.0000, -81.0000),
      ],
      routeHistoryDecision: _routeDecision(),
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

Map<String, Object?> _summary(DateTime start) {
  return TripSampleWindowQualityPolicy.evaluate(
    samples: [
      _sample(start, 0, 35.0000, -80.0000),
      _sample(start, 15, 35.0002, -80.0000),
    ],
    routeHistoryDecision: _routeDecision(),
  ).toSafeDashboardMap();
}

TripLocationSample _sample(
  DateTime start,
  int seconds,
  double latitude,
  double longitude,
) {
  return TripLocationSample(
    latitude: latitude,
    longitude: longitude,
    recordedAt: start.add(Duration(seconds: seconds)),
    horizontalAccuracyMeters: 12,
  );
}

TripRouteHistoryCaptureDecision _routeDecision() {
  return TripRouteHistoryCapturePolicy.evaluate(
    accountTier: TripRouteHistoryAccountTier.free,
    gpsAssistedTrackingEnabled: true,
    userOptedIntoMaps: true,
    userOptedIntoRouteHistory: true,
    mapboxRuntimeAvailable: true,
    requestedDailyBudgetMb: 1,
    availableStorageMb: 2000,
    requestedSampleIntervalSeconds: 15,
  );
}
