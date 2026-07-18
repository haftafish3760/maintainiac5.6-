import 'trip_tracking_models.dart';
import 'trip_tracking_profile_strategy.dart';
import 'trip_tracking_signal_quality.dart';

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
    required this.acceptedDistanceCount,
    required this.rejectedDriftCount,
    required this.minimumAcceptedDistanceCount,
    required this.canSurfaceManualFallback,
    required this.shouldContinueSampling,
  });

  final TripVehicleOnlyDwellStatus status;
  final String reasonCode;
  final Duration minimumDwell;
  final Duration observedDwell;
  final int acceptedDistanceCount;
  final int rejectedDriftCount;
  final int minimumAcceptedDistanceCount;
  final bool canSurfaceManualFallback;
  final bool shouldContinueSampling;

  Map<String, Object?> toSafeDashboardMap() => {
    'schemaVersion': 1,
    'status': status.name,
    'reasonCode': _safeReason(reasonCode),
    'minimumDwellSeconds': _safeDurationSeconds(minimumDwell),
    'observedDwellSeconds': _safeDurationSeconds(observedDwell),
    'acceptedDistanceCount': _safeCount(acceptedDistanceCount),
    'rejectedDriftCount': _safeCount(rejectedDriftCount),
    'minimumAcceptedDistanceCount': _safeCount(minimumAcceptedDistanceCount),
    'hasEnoughCleanDriveEvidence':
        _safeCount(acceptedDistanceCount) >=
        _safeCount(minimumAcceptedDistanceCount),
    'canSurfaceManualFallback': canSurfaceManualFallback,
    'shouldContinueSampling': shouldContinueSampling,
    'vehicleOnlyStopRequiresUserReview': true,
    'manualFallbackRequiresActiveLocalTrip': true,
    'manualFallbackRequiresUserAction': true,
    'manualFallbackCanEditOdometer': false,
    'manualFallbackCanConfirmMileage': false,
    'manualFallbackCanInferAddress': false,
    'manualFallbackCanBackdateWithoutReview': false,
    'vehicleOnlyDwellCanCreateOfficialStop': false,
    'vehicleOnlyDwellCanEndTripAutomatically': false,
    'gpsCanConfirmVehicleOnlyStop': false,
    'mapboxCanConfirmVehicleOnlyStop': false,
    'mapboxCanInferVehicleOnlyStopAddress': false,
    'activityRecognitionCanConfirmVehicleOnlyStop': false,
    'walkingEvidenceCanBeReplayedFromCloud': false,
    'firestoreCanCreateVehicleOnlyStop': false,
    'cloudFunctionCanCreateVehicleOnlyStop': false,
    'remoteDwellCanSurfaceManualFallback': false,
    'dashboardCacheCanSurfaceManualFallback': false,
    'odometerRemainsOfficialMileageTruth': true,
    'odometerIsGlobalTruth': true,
    'dwellEvidenceCanCreateCalibration': false,
    'dwellEvidenceCanApplyCalibration': false,
    'calibrationRequiresTrustedGpsWindow': true,
    'poorGpsDaysExcludedFromCalibration': true,
    'mapsRequiredForVehicleOnlyDwell': false,
    'longTrafficLightProtected':
        status == TripVehicleOnlyDwellStatus.trafficControlProtected,
    'trafficControlCanSurfaceManualFallback': false,
    'trafficControlCanInferStopAddress': false,
    'trafficControlCanConfirmMileage': false,
    'gridlockCanCreateOfficialStop': false,
    'gridlockCanInferStopAddress': false,
    'gridlockCanConfirmMileage': false,
    'gridlockRequiresManualConfirmation': true,
    'twoPersonDeliveryRequiresManualConfirmation': true,
    'manualFallbackCannotInferJobsiteAddress': true,
    'rawSamplesIncluded': false,
    'rawMotionPayloadIncluded': false,
    'coordinatesIncluded': false,
    'routeGeometryIncluded': false,
    'tokensIncluded': false,
  };
}

class TripVehicleOnlyDwellSummaryValidation {
  const TripVehicleOnlyDwellSummaryValidation._();

  static const _allowedStatuses = {
    'unavailable',
    'keepTracking',
    'trafficControlProtected',
    'manualFallbackRecommended',
    'unsafeEvidence',
  };

  static const _allowedReasons = {
    'unsafe_vehicle_only_dwell_evidence',
    'vehicle_only_dwell_not_needed_for_profile',
    'vehicle_only_dwell_waiting_for_clean_evidence',
    'vehicle_only_dwell_needs_more_drive_evidence',
    'vehicle_only_dwell_waiting_for_trusted_gps',
    'vehicle_only_dwell_traffic_control_protected',
    'vehicle_only_dwell_manual_fallback',
    'vehicle_only_dwell_keep_tracking',
  };

  static bool isValid(Map<String, Object?> summary) {
    if (summary['schemaVersion'] != 1) return false;
    if (!_allowedStatuses.contains(summary['status'])) return false;
    if (!_allowedReasons.contains(summary['reasonCode'])) return false;
    if (!_boundedSeconds(summary['minimumDwellSeconds'])) return false;
    if (!_boundedSeconds(summary['observedDwellSeconds'])) return false;
    if (!_safeCount(summary['acceptedDistanceCount'])) return false;
    if (!_safeCount(summary['rejectedDriftCount'])) return false;
    if (!_safeCount(summary['minimumAcceptedDistanceCount'])) return false;
    if (summary['hasEnoughCleanDriveEvidence'] is! bool) return false;
    if (summary['canSurfaceManualFallback'] is! bool) return false;
    if (summary['shouldContinueSampling'] is! bool) return false;
    if (!_trueFlag(summary, 'vehicleOnlyStopRequiresUserReview')) return false;
    if (!_trueFlag(summary, 'manualFallbackRequiresActiveLocalTrip')) {
      return false;
    }
    if (!_trueFlag(summary, 'manualFallbackRequiresUserAction')) return false;
    if (!_falseFlag(summary, 'manualFallbackCanEditOdometer')) return false;
    if (!_falseFlag(summary, 'manualFallbackCanConfirmMileage')) return false;
    if (!_falseFlag(summary, 'manualFallbackCanInferAddress')) return false;
    if (!_falseFlag(summary, 'manualFallbackCanBackdateWithoutReview')) {
      return false;
    }
    if (!_falseFlag(summary, 'vehicleOnlyDwellCanCreateOfficialStop')) {
      return false;
    }
    if (!_falseFlag(summary, 'vehicleOnlyDwellCanEndTripAutomatically')) {
      return false;
    }
    if (!_falseFlag(summary, 'gpsCanConfirmVehicleOnlyStop')) return false;
    if (!_falseFlag(summary, 'mapboxCanConfirmVehicleOnlyStop')) return false;
    if (!_falseFlag(summary, 'mapboxCanInferVehicleOnlyStopAddress')) {
      return false;
    }
    if (!_falseFlag(summary, 'activityRecognitionCanConfirmVehicleOnlyStop')) {
      return false;
    }
    if (!_falseFlag(summary, 'walkingEvidenceCanBeReplayedFromCloud')) {
      return false;
    }
    if (!_falseFlag(summary, 'firestoreCanCreateVehicleOnlyStop')) return false;
    if (!_falseFlag(summary, 'cloudFunctionCanCreateVehicleOnlyStop')) {
      return false;
    }
    if (!_falseFlag(summary, 'remoteDwellCanSurfaceManualFallback')) {
      return false;
    }
    if (!_falseFlag(summary, 'dashboardCacheCanSurfaceManualFallback')) {
      return false;
    }
    if (!_trueFlag(summary, 'odometerRemainsOfficialMileageTruth')) {
      return false;
    }
    if (!_trueFlag(summary, 'odometerIsGlobalTruth')) {
      return false;
    }
    if (!_falseFlag(summary, 'dwellEvidenceCanCreateCalibration')) return false;
    if (!_falseFlag(summary, 'dwellEvidenceCanApplyCalibration')) return false;
    if (!_trueFlag(summary, 'calibrationRequiresTrustedGpsWindow')) {
      return false;
    }
    if (!_trueFlag(summary, 'poorGpsDaysExcludedFromCalibration')) return false;
    if (!_falseFlag(summary, 'mapsRequiredForVehicleOnlyDwell')) return false;
    if (summary['longTrafficLightProtected'] is! bool) return false;
    if (!_falseFlag(summary, 'trafficControlCanSurfaceManualFallback')) {
      return false;
    }
    if (!_falseFlag(summary, 'trafficControlCanInferStopAddress')) {
      return false;
    }
    if (!_falseFlag(summary, 'trafficControlCanConfirmMileage')) return false;
    if (!_falseFlag(summary, 'gridlockCanCreateOfficialStop')) return false;
    if (!_falseFlag(summary, 'gridlockCanInferStopAddress')) return false;
    if (!_falseFlag(summary, 'gridlockCanConfirmMileage')) return false;
    if (!_trueFlag(summary, 'gridlockRequiresManualConfirmation')) {
      return false;
    }
    if (!_trueFlag(summary, 'twoPersonDeliveryRequiresManualConfirmation')) {
      return false;
    }
    if (!_trueFlag(summary, 'manualFallbackCannotInferJobsiteAddress')) {
      return false;
    }
    if (!_falseFlag(summary, 'rawSamplesIncluded')) return false;
    if (!_falseFlag(summary, 'rawMotionPayloadIncluded')) return false;
    if (!_falseFlag(summary, 'coordinatesIncluded')) return false;
    if (!_falseFlag(summary, 'routeGeometryIncluded')) return false;
    if (!_falseFlag(summary, 'tokensIncluded')) return false;
    return !_containsSensitiveText(summary);
  }

  static bool _boundedSeconds(Object? value) =>
      value is int &&
      value >= 0 &&
      value <= const Duration(hours: 24).inSeconds;

  static bool _safeCount(Object? value) =>
      value is int && value >= 0 && value <= 100000;

  static bool _trueFlag(Map<String, Object?> summary, String key) =>
      summary[key] == true;

  static bool _falseFlag(Map<String, Object?> summary, String key) =>
      summary[key] == false;

  static bool _containsSensitiveText(Map<String, Object?> summary) {
    for (final entry in summary.entries) {
      final value = entry.value;
      if (value is Map || value is Iterable) return true;
      final normalized = value?.toString().toLowerCase() ?? '';
      if (normalized.contains('pk.') ||
          normalized.contains('sk.') ||
          normalized.contains('token') ||
          normalized.contains('latitude') ||
          normalized.contains('longitude') ||
          normalized.contains('coordinate') ||
          normalized.contains('geometry') ||
          normalized.contains('polyline') ||
          normalized.contains('gps trace') ||
          normalized.contains('raw sample')) {
        return true;
      }
    }
    return false;
  }
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
    TripTrackingSignalQuality signalQuality = TripTrackingSignalQuality.healthy,
  }) {
    final strategy = TripTrackingProfileStrategy.forProfile(profile);
    final safeStationary = _safeDuration(stationaryDuration);
    final safeWalkingCount = _safeCount(walkingEvidenceCount);
    final safeRejectedDriftCount = _safeCount(rejectedDriftCount);
    final safeAcceptedDistanceCount = _safeCount(acceptedDistanceCount);
    final minimumDwell = _minimumVehicleOnlyDwellFor(strategy);
    final minimumAcceptedDistanceCount = _minimumAcceptedDistanceCountFor(
      strategy,
    );

    if (_signalQualityUnsafe(signalQuality) ||
        !_safeProviderValues(speedMps, horizontalAccuracyMeters) ||
        stationaryDuration.isNegative) {
      return _decision(
        status: TripVehicleOnlyDwellStatus.unsafeEvidence,
        reasonCode: 'unsafe_vehicle_only_dwell_evidence',
        minimumDwell: minimumDwell,
        observedDwell: safeStationary,
        acceptedDistanceCount: safeAcceptedDistanceCount,
        rejectedDriftCount: safeRejectedDriftCount,
        minimumAcceptedDistanceCount: minimumAcceptedDistanceCount,
        canSurfaceManualFallback: false,
      );
    }

    if (_signalQualityBlocksDwell(signalQuality)) {
      return _decision(
        status: TripVehicleOnlyDwellStatus.keepTracking,
        reasonCode: 'vehicle_only_dwell_waiting_for_trusted_gps',
        minimumDwell: minimumDwell,
        observedDwell: safeStationary,
        acceptedDistanceCount: safeAcceptedDistanceCount,
        rejectedDriftCount: safeRejectedDriftCount,
        minimumAcceptedDistanceCount: minimumAcceptedDistanceCount,
        canSurfaceManualFallback: false,
      );
    }

    if (!strategy.vehicleOnlyStopsNeedManualFallback) {
      return _decision(
        status: TripVehicleOnlyDwellStatus.unavailable,
        reasonCode: 'vehicle_only_dwell_not_needed_for_profile',
        minimumDwell: minimumDwell,
        observedDwell: safeStationary,
        acceptedDistanceCount: safeAcceptedDistanceCount,
        rejectedDriftCount: safeRejectedDriftCount,
        minimumAcceptedDistanceCount: minimumAcceptedDistanceCount,
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
        acceptedDistanceCount: safeAcceptedDistanceCount,
        rejectedDriftCount: safeRejectedDriftCount,
        minimumAcceptedDistanceCount: minimumAcceptedDistanceCount,
        canSurfaceManualFallback: false,
      );
    }

    if (safeAcceptedDistanceCount < minimumAcceptedDistanceCount) {
      return _decision(
        status: TripVehicleOnlyDwellStatus.keepTracking,
        reasonCode: 'vehicle_only_dwell_needs_more_drive_evidence',
        minimumDwell: minimumDwell,
        observedDwell: safeStationary,
        acceptedDistanceCount: safeAcceptedDistanceCount,
        rejectedDriftCount: safeRejectedDriftCount,
        minimumAcceptedDistanceCount: minimumAcceptedDistanceCount,
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
        acceptedDistanceCount: safeAcceptedDistanceCount,
        rejectedDriftCount: safeRejectedDriftCount,
        minimumAcceptedDistanceCount: minimumAcceptedDistanceCount,
        canSurfaceManualFallback: false,
      );
    }

    if (safeStationary >= minimumDwell) {
      return _decision(
        status: TripVehicleOnlyDwellStatus.manualFallbackRecommended,
        reasonCode: 'vehicle_only_dwell_manual_fallback',
        minimumDwell: minimumDwell,
        observedDwell: safeStationary,
        acceptedDistanceCount: safeAcceptedDistanceCount,
        rejectedDriftCount: safeRejectedDriftCount,
        minimumAcceptedDistanceCount: minimumAcceptedDistanceCount,
        canSurfaceManualFallback: true,
      );
    }

    return _decision(
      status: TripVehicleOnlyDwellStatus.keepTracking,
      reasonCode: 'vehicle_only_dwell_keep_tracking',
      minimumDwell: minimumDwell,
      observedDwell: safeStationary,
      acceptedDistanceCount: safeAcceptedDistanceCount,
      rejectedDriftCount: safeRejectedDriftCount,
      minimumAcceptedDistanceCount: minimumAcceptedDistanceCount,
      canSurfaceManualFallback: false,
    );
  }
}

TripVehicleOnlyDwellDecision _decision({
  required TripVehicleOnlyDwellStatus status,
  required String reasonCode,
  required Duration minimumDwell,
  required Duration observedDwell,
  required int acceptedDistanceCount,
  required int rejectedDriftCount,
  required int minimumAcceptedDistanceCount,
  required bool canSurfaceManualFallback,
}) {
  return TripVehicleOnlyDwellDecision(
    status: status,
    reasonCode: _safeReason(reasonCode),
    minimumDwell: minimumDwell,
    observedDwell: observedDwell,
    acceptedDistanceCount: acceptedDistanceCount,
    rejectedDriftCount: rejectedDriftCount,
    minimumAcceptedDistanceCount: minimumAcceptedDistanceCount,
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
  final ceiling = _trafficControlCeilingFor(strategy);
  final extendedJitterCeiling = _extendedJitterCeilingFor(strategy);
  if (stationaryDuration > ceiling &&
      (rejectedDriftCount < 8 || stationaryDuration > extendedJitterCeiling)) {
    return false;
  }
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

Duration _extendedJitterCeilingFor(TripTrackingProfileStrategy strategy) {
  return switch (strategy.workStyle) {
    TripTrackingWorkStyle.rideshare => const Duration(minutes: 8),
    TripTrackingWorkStyle.delivery => const Duration(minutes: 6),
    _ => const Duration(minutes: 5),
  };
}

int _minimumAcceptedDistanceCountFor(TripTrackingProfileStrategy strategy) {
  return switch (strategy.workStyle) {
    TripTrackingWorkStyle.rideshare => 4,
    TripTrackingWorkStyle.delivery => 3,
    TripTrackingWorkStyle.contractor => 3,
    TripTrackingWorkStyle.generalRoad => 3,
    TripTrackingWorkStyle.equipment => 3,
  };
}

bool _safeProviderValues(double speedMps, double horizontalAccuracyMeters) {
  if (!speedMps.isFinite || !horizontalAccuracyMeters.isFinite) return false;
  if (speedMps < -0.5 || speedMps > 90) return false;
  return horizontalAccuracyMeters >= 0 && horizontalAccuracyMeters <= 250;
}

bool _signalQualityUnsafe(TripTrackingSignalQuality quality) =>
    quality == TripTrackingSignalQuality.unsafe;

bool _signalQualityBlocksDwell(TripTrackingSignalQuality quality) {
  return switch (quality) {
    TripTrackingSignalQuality.noSamples ||
    TripTrackingSignalQuality.poor ||
    TripTrackingSignalQuality.interrupted ||
    TripTrackingSignalQuality.unsafe => true,
    TripTrackingSignalQuality.healthy || TripTrackingSignalQuality.reduced =>
      false,
  };
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
    'vehicle_only_dwell_needs_more_drive_evidence' =>
      'vehicle_only_dwell_needs_more_drive_evidence',
    'vehicle_only_dwell_waiting_for_trusted_gps' =>
      'vehicle_only_dwell_waiting_for_trusted_gps',
    'vehicle_only_dwell_traffic_control_protected' =>
      'vehicle_only_dwell_traffic_control_protected',
    'vehicle_only_dwell_manual_fallback' =>
      'vehicle_only_dwell_manual_fallback',
    'vehicle_only_dwell_keep_tracking' => 'vehicle_only_dwell_keep_tracking',
    _ => 'unsafe_vehicle_only_dwell_evidence',
  };
}
