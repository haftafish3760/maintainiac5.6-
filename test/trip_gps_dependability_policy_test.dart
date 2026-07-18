import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_gps_dependability_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_route_history_capture_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_sample_window_quality_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_signal_quality.dart';

void main() {
  TripTrackingSignalQualitySummary signal({
    TripTrackingSignalQuality quality = TripTrackingSignalQuality.healthy,
    String reasonCode = 'gps_signal_healthy',
    int receivedSamples = 8,
    int acceptedSamples = 8,
    bool requiresUserReview = false,
  }) {
    return TripTrackingSignalQualitySummary(
      quality: quality,
      reasonCode: reasonCode,
      receivedSamples: receivedSamples,
      acceptedSamples: acceptedSamples,
      rejectedSamples: receivedSamples - acceptedSamples,
      acceptanceRate: acceptedSamples / receivedSamples,
      requiresUserReview: requiresUserReview,
    );
  }

  TripSampleWindowQualityDecision window({
    TripTrackingSignalQuality signalQuality = TripTrackingSignalQuality.healthy,
  }) {
    return TripSampleWindowQualityPolicy.evaluate(
      samples: [
        TripLocationSample(
          latitude: 35,
          longitude: -80,
          recordedAt: DateTime.utc(2026, 7, 18, 12),
          horizontalAccuracyMeters: 8,
          speedMetersPerSecond: 12,
        ),
        TripLocationSample(
          latitude: 35.001,
          longitude: -80,
          recordedAt: DateTime.utc(2026, 7, 18, 12, 0, 20),
          horizontalAccuracyMeters: 8,
          speedMetersPerSecond: 12,
        ),
        TripLocationSample(
          latitude: 35.002,
          longitude: -80,
          recordedAt: DateTime.utc(2026, 7, 18, 12, 0, 40),
          horizontalAccuracyMeters: 8,
          speedMetersPerSecond: 12,
        ),
      ],
      routeHistoryDecision: const TripRouteHistoryCaptureDecision(
        plan: TripRouteHistoryPlan.compactGpsTrace,
        reason: TripRouteHistoryReason.compactTraceAllowed,
        recommendedSampleIntervalSeconds: 15,
        maximumRetainedPointsPerDay: 2500,
        dailyBudgetMb: 1,
        canUseMapbox: false,
        canCaptureRouteHistory: true,
      ),
      signalQuality: signalQuality,
    );
  }

  test(
    'healthy signal and usable samples unlock high-confidence assistance',
    () {
      final decision = TripGpsDependabilityPolicy.evaluate(
        profile: TripTrackingProfile.deliveryVehicle,
        signalSummary: signal(),
        sampleWindow: window(),
      );
      final safe = decision.toSafeDashboardMap();
      final validation = TripGpsDependabilitySummaryValidation.fromSummary(
        safe,
      );

      expect(decision.status, TripGpsDependabilityStatus.readyForAssist);
      expect(decision.confidence, TripTrackingConfidence.high);
      expect(decision.canFeedLiveOdometerProjection, isTrue);
      expect(decision.canPersistCompactRoutePoint, isTrue);
      expect(decision.canOpenStopReview, isTrue);
      expect(decision.canContributeToCalibration, isTrue);
      expect(safe['gpsAssistedTrackingWorksWithoutMaps'], isTrue);
      expect(safe['mapsRequiredForGpsDependability'], isFalse);
      expect(safe['odometerIsGlobalTruth'], isTrue);
      expect(safe['gpsCanReplaceOdometer'], isFalse);
      expect(safe['gpsCanCreateOfficialStop'], isFalse);
      expect(safe['coordinatesIncluded'], isFalse);
      expect(validation.isRenderable, isTrue);
      expect(validation.status, TripGpsDependabilityStatus.readyForAssist);
      expect(validation.reason, 'gps_dependability_ready');
    },
  );

  test('reduced GPS stays advisory and never bypasses stop debounce', () {
    final decision = TripGpsDependabilityPolicy.evaluate(
      profile: TripTrackingProfile.rideshareVehicle,
      signalSummary: signal(
        quality: TripTrackingSignalQuality.reduced,
        reasonCode: 'gps_signal_reduced_but_usable',
        receivedSamples: 10,
        acceptedSamples: 7,
      ),
      sampleWindow: window(signalQuality: TripTrackingSignalQuality.reduced),
    );
    final safe = decision.toSafeDashboardMap();

    expect(decision.status, TripGpsDependabilityStatus.reviewOnly);
    expect(decision.confidence, TripTrackingConfidence.medium);
    expect(decision.canFeedLiveOdometerProjection, isTrue);
    expect(decision.canOpenStopReview, isFalse);
    expect(safe['reducedGpsIsReviewOnly'], isTrue);
    expect(safe['stopReviewRequiresTrustedGpsAndDebounce'], isTrue);
    expect(safe['gpsCanConfirmOfficialMileage'], isFalse);
  });

  test(
    'poor or interrupted GPS pauses projection but keeps sampling alive',
    () {
      for (final entry in [
        (
          TripTrackingSignalQuality.poor,
          'gps_signal_poor_measurement_quality',
          'gps_poor_signal_pauses_projection',
        ),
        (
          TripTrackingSignalQuality.interrupted,
          'gps_signal_interrupted_by_gap',
          'gps_interrupted_signal_pauses_projection',
        ),
      ]) {
        final decision = TripGpsDependabilityPolicy.evaluate(
          profile: TripTrackingProfile.contractorVehicle,
          signalSummary: signal(
            quality: entry.$1,
            reasonCode: entry.$2,
            receivedSamples: 8,
            acceptedSamples: 3,
            requiresUserReview: true,
          ),
          sampleWindow: window(signalQuality: entry.$1),
        );

        expect(decision.status, TripGpsDependabilityStatus.projectionPaused);
        expect(decision.reasonCode, entry.$3);
        expect(decision.canFeedLiveOdometerProjection, isFalse);
        expect(decision.canPersistCompactRoutePoint, isFalse);
        expect(decision.canOpenStopReview, isFalse);
        expect(decision.canContributeToCalibration, isFalse);
        expect(decision.shouldContinueSampling, isTrue);
        expect(decision.requiresUserReview, isTrue);
      }
    },
  );

  test(
    'permission device and battery gates pause without inventing mileage',
    () {
      final baseWindow = window();
      final noPermission = TripGpsDependabilityPolicy.evaluate(
        profile: TripTrackingProfile.roadVehicle,
        signalSummary: signal(),
        sampleWindow: baseWindow,
        permissionContinuityTrusted: false,
      );
      final noDeviceTrust = TripGpsDependabilityPolicy.evaluate(
        profile: TripTrackingProfile.roadVehicle,
        signalSummary: signal(),
        sampleWindow: baseWindow,
        deviceCapabilityTrusted: false,
      );
      final lowBattery = TripGpsDependabilityPolicy.evaluate(
        profile: TripTrackingProfile.roadVehicle,
        signalSummary: signal(),
        sampleWindow: baseWindow,
        batteryAllowsGps: false,
      );

      expect(noPermission.reasonCode, 'gps_permission_continuity_required');
      expect(noDeviceTrust.reasonCode, 'gps_device_capability_required');
      expect(lowBattery.reasonCode, 'gps_battery_policy_paused');
      expect(noPermission.shouldContinueSampling, isFalse);
      expect(noDeviceTrust.shouldContinueSampling, isFalse);
      expect(lowBattery.requiresUserReview, isFalse);
      expect(
        lowBattery
            .toSafeDashboardMap()['gpsDependabilityRequiresBatteryAllowance'],
        isTrue,
      );
    },
  );

  test('unsafe signal or sample window blocks all assistance fail-closed', () {
    final decision = TripGpsDependabilityPolicy.evaluate(
      profile: TripTrackingProfile.deliveryVehicle,
      signalSummary: signal(
        quality: TripTrackingSignalQuality.unsafe,
        reasonCode: 'gps_signal_unsafe_provider_evidence',
        receivedSamples: 8,
        acceptedSamples: 1,
        requiresUserReview: true,
      ),
      sampleWindow: window(signalQuality: TripTrackingSignalQuality.unsafe),
    );
    final safe = decision.toSafeDashboardMap();

    expect(decision.status, TripGpsDependabilityStatus.unsafeBlocked);
    expect(decision.canFeedLiveOdometerProjection, isFalse);
    expect(decision.canPersistCompactRoutePoint, isFalse);
    expect(decision.canOpenStopReview, isFalse);
    expect(decision.canContributeToCalibration, isFalse);
    expect(safe['unsafeGpsBlocksAllAssistance'], isTrue);
    expect(safe['mapboxCanOverrideGpsDependability'], isFalse);
    expect(safe['firestoreCanOverrideGpsDependability'], isFalse);
    expect(safe['cloudFunctionCanOverrideGpsDependability'], isFalse);
    expect(safe.toString(), isNot(contains('-80')));
  });

  test('summary validation rejects malformed authority and remote truth', () {
    final summary =
        TripGpsDependabilityPolicy.evaluate(
          profile: TripTrackingProfile.deliveryVehicle,
          signalSummary: signal(),
          sampleWindow: window(),
        ).toSafeDashboardMap()..addAll({
          'schemaVersion': 2,
          'status': 'forceReady',
          'reasonCode': 'gps_dependability_ready',
          'profile': 'fleetGodMode',
          'confidence': 'certain',
          'signalQuality': 'perfect',
          'gpsAssistedTrackingWorksWithoutMaps': false,
          'mapsRequiredForGpsDependability': true,
          'gpsDependabilityRequiresIntakeGuard': false,
          'gpsDependabilityRequiresSampleWindowPolicy': false,
          'gpsDependabilityRequiresSignalQualityPolicy': false,
          'gpsDependabilityRequiresDeviceCapabilityContext': false,
          'gpsDependabilityRequiresPermissionContinuity': false,
          'gpsDependabilityRequiresBatteryAllowance': false,
          'reducedGpsIsReviewOnly': false,
          'poorGpsPausesProjection': false,
          'interruptedGpsPausesProjection': false,
          'unsafeGpsBlocksAllAssistance': false,
          'stopReviewRequiresTrustedGpsAndDebounce': false,
          'calibrationRequiresTrustedGpsAndOdometerReview': false,
          'odometerRemainsOfficialMileageTruth': false,
          'odometerIsGlobalTruth': false,
          'gpsCanReplaceOdometer': true,
          'gpsCanConfirmOfficialMileage': true,
          'gpsCanCreateOfficialStop': true,
          'mapboxCanOverrideGpsDependability': true,
          'firestoreCanOverrideGpsDependability': true,
          'cloudFunctionCanOverrideGpsDependability': true,
          'remoteTotalsCanBecomeCanonical': true,
          'rawSamplesIncluded': true,
          'coordinatesIncluded': true,
          'routeGeometryIncluded': true,
          'tokensIncluded': true,
          'debug': 'pk.public -80.123456',
        });
    final validation = TripGpsDependabilitySummaryValidation.fromSummary(
      summary,
    );

    expect(validation.isRenderable, isFalse);
    expect(
      validation.reasons,
      containsAll([
        'unsupported_schema',
        'invalid_gps_dependability_status',
        'invalid_gps_dependability_profile',
        'invalid_gps_dependability_confidence',
        'invalid_gps_dependability_signal_quality',
        'maps_boundary_missing',
        'gps_dependency_boundary_missing',
        'gps_quality_boundary_missing',
        'gps_can_create_trip_truth',
        'remote_can_override_gps_dependability',
        'summary_contains_sensitive_trip_material',
        'summary_contains_sensitive_text',
      ]),
    );
  });

  test('summary validation rejects unsafe reason text', () {
    final summary = TripGpsDependabilityPolicy.evaluate(
      profile: TripTrackingProfile.roadVehicle,
      signalSummary: signal(),
      sampleWindow: window(),
    ).toSafeDashboardMap()..['reasonCode'] = 'lat=-80.123456 sk.secret';
    final validation = TripGpsDependabilitySummaryValidation.fromSummary(
      summary,
    );

    expect(validation.isRenderable, isFalse);
    expect(validation.reasons, contains('invalid_gps_dependability_reason'));
    expect(validation.reasons, contains('summary_contains_sensitive_text'));
  });
}
