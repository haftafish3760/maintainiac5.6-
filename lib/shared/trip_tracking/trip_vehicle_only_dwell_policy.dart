import 'trip_tracking_models.dart';
import 'trip_tracking_profile_strategy.dart';

enum TripVehicleOnlyDwellStatus {
  unavailable,
  keepTracking,
  trafficControlProtected,
  manualFallbackRecommended,
  unsafeEvidence,
}

class TripVehicleOnlyDwellDecision {
  const TripVehicleOnlyDwellDecision({
    required this.status,
    required this.reasonCode,
    required this.minimumDwell,
    required this.observedDwell,
    required this.canSurfaceManualFallback,
    required this.shouldContinueSampling,
  });

  final TripVehicleOnlyDwellStatus status;
  final String reasonCode;
  final Duration minimumDwell;
  final Duration observedDwell;
  final bool canSurfaceManualFallback;
  final bool shouldContinueSampling;

  Map<String, Object?> toSafeDashboardMap() => {
    'schemaVersion': 1,
    'status': status.name,
    'reasonCode': _safeReason(reasonCode),
    'minimumDwellSeconds': _safeDurationSeconds(minimumDwell),
    'observedDwellSeconds': _safeDurationSeconds(observedDwell),
    'canSurfaceManualFallback': canSurfaceManualFallback,
    'shouldContinueSampling': shouldContinueSampling,
    'vehicleOnlyStopRequiresUserReview': true,
    'vehicleOnlyDwellCanCreateOfficialStop': false,
    'vehicleOnlyDwellCanEndTripAutomatically': false,
    'gpsCanConfirmVehicleOnlyStop': false,
    'mapboxCanConfirmVehicleOnlyStop': false,
    'activityRecognitionCanConfirmVehicleOnlyStop': false,
    'firestoreCanCreateVehicleOnlyStop': false,
    'cloudFunctionCanCreateVehicleOnlyStop': false,
    'odometerRemainsOfficialMileageTruth': true,
    'mapsRequiredForVehicleOnlyDwell': false,
    'longTrafficLightProtected':
        status == TripVehicleOnlyDwellStatus.trafficControlProtected,
    'rawSamplesIncluded': false,
    'rawMotionPayloadIncluded': false,
    'coordinatesIncluded': false,
    'routeGeometryIncluded': false,
    'tokensIncluded': false,
  };
}

class TripVehicleOnlyDwellPolicy {
  const TripVehicleOnlyDwellPolicy._();

  static TripVehicleOnlyDwellDecision evaluate({
    required TripTrackingProfile profile,
    required Duration stationaryDuration,
    required int walkingEvidenceCount,
    required int rejectedDriftCount,
    required int acceptedDistanceCount,
    required bool acceptedVehicleMovementObserved,
    required double speedMps,
    required double horizontalAccuracyMeters,
  }) {
    final strategy = TripTrackingProfileStrategy.forProfile(profile);
    final safeStationary = _safeDuration(stationaryDuration);
    final safeWalkingCount = _safeCount(walkingEvidenceCount);
    final safeRejectedDriftCount = _safeCount(rejectedDriftCount);
    final safeAcceptedDistanceCount = _safeCount(acceptedDistanceCount);
    final minimumDwell = _minimumVehicleOnlyDwellFor(strategy);

    if (!_safeProviderValues(speedMps, horizontalAccuracyMeters) ||
        stationaryDuration.isNegative) {
      return _decision(
        status: TripVehicleOnlyDwellStatus.unsafeEvidence,
        reasonCode: 'unsafe_vehicle_only_dwell_evidence',
        minimumDwell: minimumDwell,
        observedDwell: safeStationary,
        canSurfaceManualFallback: false,
      );
    }

    if (!strategy.vehicleOnlyStopsNeedManualFallback) {
      return _decision(
        status: TripVehicleOnlyDwellStatus.unavailable,
        reasonCode: 'vehicle_only_dwell_not_needed_for_profile',
        minimumDwell: minimumDwell,
        observedDwell: safeStationary,
        canSurfaceManualFallback: false,
      );
    }

    if (safeWalkingCount > 0 ||
        !acceptedVehicleMovementObserved ||
        safeAcceptedDistanceCount == 0) {
      return _decision(
        status: TripVehicleOnlyDwellStatus.keepTracking,
        reasonCode: 'vehicle_only_dwell_waiting_for_clean_evidence',
        minimumDwell: minimumDwell,
        observedDwell: safeStationary,
        canSurfaceManualFallback: false,
      );
    }

    if (_looksLikeTrafficControl(
      strategy: strategy,
      stationaryDuration: safeStationary,
      rejectedDriftCount: safeRejectedDriftCount,
      speedMps: speedMps,
    )) {
      return _decision(
        status: TripVehicleOnlyDwellStatus.trafficControlProtected,
        reasonCode: 'vehicle_only_dwell_traffic_control_protected',
        minimumDwell: minimumDwell,
        observedDwell: safeStationary,
        canSurfaceManualFallback: false,
      );
    }

    if (safeStationary >= minimumDwell) {
      return _decision(
        status: TripVehicleOnlyDwellStatus.manualFallbackRecommended,
        reasonCode: 'vehicle_only_dwell_manual_fallback',
        minimumDwell: minimumDwell,
        observedDwell: safeStationary,
        canSurfaceManualFallback: true,
      );
    }

    return _decision(
      status: TripVehicleOnlyDwellStatus.keepTracking,
      reasonCode: 'vehicle_only_dwell_keep_tracking',
      minimumDwell: minimumDwell,
      observedDwell: safeStationary,
      canSurfaceManualFallback: false,
    );
  }
}

TripVehicleOnlyDwellDecision _decision({
  required TripVehicleOnlyDwellStatus status,
  required String reasonCode,
  required Duration minimumDwell,
  required Duration observedDwell,
  required bool canSurfaceManualFallback,
}) {
  return TripVehicleOnlyDwellDecision(
    status: status,
    reasonCode: _safeReason(reasonCode),
    minimumDwell: minimumDwell,
    observedDwell: observedDwell,
    canSurfaceManualFallback: canSurfaceManualFallback,
    shouldContinueSampling: true,
  );
}

bool _looksLikeTrafficControl({
  required TripTrackingProfileStrategy strategy,
  required Duration stationaryDuration,
  required int rejectedDriftCount,
  required double speedMps,
}) {
  if (rejectedDriftCount < 4) return false;
  if (stationaryDuration > _trafficControlCeilingFor(strategy)) return false;
  return speedMps <= 1.2;
}

Duration _minimumVehicleOnlyDwellFor(TripTrackingProfileStrategy strategy) {
  return switch (strategy.workStyle) {
    TripTrackingWorkStyle.rideshare => const Duration(minutes: 8),
    TripTrackingWorkStyle.delivery => const Duration(minutes: 6),
    TripTrackingWorkStyle.contractor => const Duration(minutes: 10),
    TripTrackingWorkStyle.generalRoad => const Duration(minutes: 10),
    TripTrackingWorkStyle.equipment => const Duration(minutes: 12),
  };
}

Duration _trafficControlCeilingFor(TripTrackingProfileStrategy strategy) {
  return switch (strategy.workStyle) {
    TripTrackingWorkStyle.rideshare => const Duration(minutes: 5),
    TripTrackingWorkStyle.delivery => const Duration(minutes: 4),
    _ => const Duration(minutes: 3),
  };
}

bool _safeProviderValues(double speedMps, double horizontalAccuracyMeters) {
  if (!speedMps.isFinite || !horizontalAccuracyMeters.isFinite) return false;
  if (speedMps < -0.5 || speedMps > 90) return false;
  return horizontalAccuracyMeters >= 0 && horizontalAccuracyMeters <= 250;
}

int _safeCount(int value) {
  if (value <= 0) return 0;
  return value > 100000 ? 100000 : value;
}

Duration _safeDuration(Duration value) {
  if (value.isNegative) return Duration.zero;
  return value > const Duration(hours: 24) ? const Duration(hours: 24) : value;
}

int _safeDurationSeconds(Duration value) => _safeDuration(value).inSeconds;

String _safeReason(String value) {
  return switch (value.trim()) {
    'unsafe_vehicle_only_dwell_evidence' =>
      'unsafe_vehicle_only_dwell_evidence',
    'vehicle_only_dwell_not_needed_for_profile' =>
      'vehicle_only_dwell_not_needed_for_profile',
    'vehicle_only_dwell_waiting_for_clean_evidence' =>
      'vehicle_only_dwell_waiting_for_clean_evidence',
    'vehicle_only_dwell_traffic_control_protected' =>
      'vehicle_only_dwell_traffic_control_protected',
    'vehicle_only_dwell_manual_fallback' =>
      'vehicle_only_dwell_manual_fallback',
    'vehicle_only_dwell_keep_tracking' => 'vehicle_only_dwell_keep_tracking',
    _ => 'unsafe_vehicle_only_dwell_evidence',
  };
}
