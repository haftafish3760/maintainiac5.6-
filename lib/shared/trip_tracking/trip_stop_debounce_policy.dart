import 'trip_stop_classification.dart';
import 'trip_stop_debounce_evidence_digest.dart';
import 'trip_stop_false_positive_guard.dart';
import 'trip_tracking_models.dart';
import 'trip_tracking_profile_strategy.dart';
import 'trip_vehicle_only_dwell_policy.dart';
import 'trip_walking_evidence_recency_guard.dart';

enum TripStopDebounceStatus {
  keepTracking,
  waitingForEvidence,
  readyForReview,
  trafficControlProtected,
  unsafeEvidence,
}

class TripStopDebounceObservation {
  const TripStopDebounceObservation({
    required this.motionState,
    required this.stationaryDuration,
    required this.walkingEvidenceCount,
    required this.walkingEvidenceSpan,
    required this.rejectedDriftCount,
    required this.rejectedUnsafeCount,
    required this.acceptedDistanceCount,
    required this.acceptedVehicleMovementObserved,
    required this.speedMps,
    required this.horizontalAccuracyMeters,
    this.latestWalkingEvidenceAt,
    this.observedAt,
  });

  final TripMotionState motionState;
  final Duration stationaryDuration;
  final int walkingEvidenceCount;
  final Duration walkingEvidenceSpan;
  final int rejectedDriftCount;
  final int rejectedUnsafeCount;
  final int acceptedDistanceCount;
  final bool acceptedVehicleMovementObserved;
  final double speedMps;
  final double horizontalAccuracyMeters;
  final DateTime? latestWalkingEvidenceAt;
  final DateTime? observedAt;
}

class TripStopDebounceDecision {
  const TripStopDebounceDecision({
    required this.status,
    required this.profile,
    required this.classification,
    required this.reasonCode,
    required this.evidenceDigest,
    required this.needsWalkingReview,
    required this.protectedTrafficControl,
    required this.shouldContinueSampling,
    required this.canOpenReview,
    this.vehicleOnlyDwell,
  });

  final TripStopDebounceStatus status;
  final TripTrackingProfile profile;
  final TripStopClassification classification;
  final String reasonCode;
  final TripStopDebounceEvidenceDigest evidenceDigest;
  final bool needsWalkingReview;
  final bool protectedTrafficControl;
  final bool shouldContinueSampling;
  final bool canOpenReview;
  final TripVehicleOnlyDwellDecision? vehicleOnlyDwell;

  Map<String, Object?> toSafeDashboardMap() => {
    'schemaVersion': 1,
    'status': status.name,
    'reasonCode': _safeReason(reasonCode),
    'classification': classification.toSafeSummary(),
    'evidenceDigest': evidenceDigest.toSafeDashboardMap(),
    'vehicleOnlyDwell': vehicleOnlyDwell?.toSafeDashboardMap(),
    'falsePositiveGuard': TripStopFalsePositiveGuard.evaluate(
      profile: profile,
      status: status.name,
      classification: classification.toSafeSummary(),
      vehicleOnlyDwell: vehicleOnlyDwell?.toSafeDashboardMap(),
      needsWalkingReview: needsWalkingReview,
      protectedTrafficControl: protectedTrafficControl,
      canOpenReview: canOpenReview,
    ).toSafeDashboardMap(),
    'needsWalkingReview': needsWalkingReview,
    'protectedTrafficControl': protectedTrafficControl,
    'shouldContinueSampling': shouldContinueSampling,
    'canOpenReview': canOpenReview,
    'gpsAssistedOnly': true,
    'mapsRequiredForStopDebounce': false,
    'mapboxCanCreateStop': false,
    'mapboxCanConfirmStop': false,
    'mapboxDirectionsCanConfirmStop': false,
    'mapboxMatrixCanConfirmStop': false,
    'mapboxMapMatchingCanReplaceMileage': false,
    'mapboxOptimizationCanCreateStopOrder': false,
    'mapboxTrafficSignalCanCreateStop': false,
    'mapboxGeocodeCanConfirmStopAddress': false,
    'firestoreCanCreateStop': false,
    'cloudFunctionCanCreateStop': false,
    'remoteDebounceCanOverrideLocalTrip': false,
    'remoteDebounceCanOpenReview': false,
    'remoteDebounceCanEndTrip': false,
    'importedDebounceCanOpenReview': false,
    'dashboardCacheCanOpenReview': false,
    'authenticatedUserStillNeedsAuthorization': true,
    'localTripLogRequiredForReview': true,
    'malformedStopDebounceObservationFailsClosed': true,
    'stopReviewCannotCommitWithoutUserAction': true,
    'walkingEvidenceCanOnlySuggestReview': true,
    'walkingEvidenceRequiresCurrentDeviceSensor': true,
    'walkingEvidenceCannotBeReplayedFromCloud': true,
    'walkingEvidenceCannotCommitStop': true,
    'currentVehicleSpeedMustAllowStopReview': true,
    'movingVehicleCannotOpenStopReview': true,
    'vehicleOnlyDwellCanOnlySuggestManualFallback': true,
    'vehicleOnlyDwellCanCreateOfficialStop': false,
    'vehicleOnlyDwellCannotInferAddress': true,
    'longStoplightCannotCreateOfficialStop': true,
    'gridlockCannotCreateOfficialStop': true,
    'twoPersonDeliveryRequiresManualConfirmation': true,
    'driverProfileThresholdsAreLocalPolicy': true,
    'activityRecognitionCanCreateOfficialStop': false,
    'stopEvidenceCanCreateCalibration': false,
    'walkingEvidenceCanCreateCalibration': false,
    'trafficControlCanCreateCalibration': false,
    'calibrationRequiresTrustedGpsWindow': true,
    'poorGpsDaysExcludedFromCalibration': true,
    'stopReviewRequiredForOfficialStop': true,
    'odometerRemainsOfficialMileageTruth': true,
    'odometerIsGlobalTruth': true,
    'rawSamplesIncluded': false,
    'coordinatesIncluded': false,
    'routeGeometryIncluded': false,
    'tokensIncluded': false,
  };
}

class TripStopDebouncePolicy {
  const TripStopDebouncePolicy._();

  static TripStopDebounceDecision evaluate({
    required TripTrackingProfile profile,
    required TripStopDebounceObservation observation,
  }) {
    final strategy = TripTrackingProfileStrategy.forProfile(profile);
    final unsafe = _unsafeObservation(observation);
    final acceptedDistanceCount = _safeCount(observation.acceptedDistanceCount);
    final rejectedDriftCount = _safeCount(observation.rejectedDriftCount);
    final rejectedUnsafeCount = unsafe
        ? _safeCount(observation.rejectedUnsafeCount) + 3
        : _safeCount(observation.rejectedUnsafeCount);
    final rawWalkingCount = _safeCount(observation.walkingEvidenceCount);
    final stationaryDuration = _safeDuration(observation.stationaryDuration);
    final rawWalkingSpan = _safeDuration(observation.walkingEvidenceSpan);
    final minimumStationary = _minimumStationaryFor(strategy);
    final walkingRecency = TripWalkingEvidenceRecencyGuard.evaluate(
      strategy: strategy,
      walkingEvidenceCount: rawWalkingCount,
      walkingEvidenceSpan: rawWalkingSpan,
      observedAt: observation.observedAt,
      latestWalkingEvidenceAt: observation.latestWalkingEvidenceAt,
    );
    final walkingCount = walkingRecency.walkingEvidenceCount;
    final walkingSpan = walkingRecency.walkingEvidenceSpan;
    final walkingBurstProtected = _looksLikeWalkingBurst(
      strategy: strategy,
      walkingCount: walkingCount,
      walkingSpan: walkingSpan,
    );
    final evidenceDigest = TripStopDebounceEvidenceDigest(
      profile: profile,
      acceptedDistanceCount: acceptedDistanceCount,
      rejectedDriftCount: rejectedDriftCount,
      rejectedUnsafeCount: rejectedUnsafeCount,
      walkingEvidenceCount: walkingCount,
      stationaryDuration: stationaryDuration,
      walkingEvidenceSpan: walkingSpan,
      minimumStationary: minimumStationary,
      minimumWalkingEvidenceSpacing: strategy.minimumWalkingEvidenceSpacing,
      acceptedVehicleMovementObserved:
          observation.acceptedVehicleMovementObserved,
      providerValuesUsable: !unsafe,
      walkingBurstProtected: walkingBurstProtected,
      walkingEvidenceCurrent: walkingRecency.usable,
      walkingEvidenceRecency: walkingRecency,
    );
    final vehicleOnlyDwell = TripVehicleOnlyDwellPolicy.evaluate(
      profile: profile,
      stationaryDuration: stationaryDuration,
      walkingEvidenceCount: walkingCount,
      rejectedDriftCount: rejectedDriftCount,
      acceptedDistanceCount: acceptedDistanceCount,
      acceptedVehicleMovementObserved:
          observation.acceptedVehicleMovementObserved,
      speedMps: observation.speedMps,
      horizontalAccuracyMeters: observation.horizontalAccuracyMeters,
    );

    if (unsafe || rejectedUnsafeCount >= 3) {
      return _decision(
        status: TripStopDebounceStatus.unsafeEvidence,
        reasonCode: 'unsafe_stop_debounce_evidence',
        profile: profile,
        motionState: observation.motionState,
        evidenceDigest: evidenceDigest,
        needsWalkingReview: false,
        vehicleOnlyDwell: vehicleOnlyDwell,
        excludedWalkingCount: walkingCount,
        rejectedDriftCount: rejectedDriftCount,
        rejectedUnsafeCount: rejectedUnsafeCount,
        acceptedDistanceCount: acceptedDistanceCount,
      );
    }

    if (!observation.acceptedVehicleMovementObserved ||
        acceptedDistanceCount == 0) {
      return _decision(
        status: TripStopDebounceStatus.waitingForEvidence,
        reasonCode: 'vehicle_movement_required_before_stop_review',
        profile: profile,
        motionState: observation.motionState,
        evidenceDigest: evidenceDigest,
        needsWalkingReview: walkingCount > 0,
        vehicleOnlyDwell: vehicleOnlyDwell,
        excludedWalkingCount: walkingCount,
        rejectedDriftCount: rejectedDriftCount,
        rejectedUnsafeCount: rejectedUnsafeCount,
        acceptedDistanceCount: 0,
      );
    }

    if (walkingRecency.rejected && rawWalkingCount > 0) {
      return _decision(
        status: TripStopDebounceStatus.waitingForEvidence,
        reasonCode: walkingRecency.reasonCode,
        profile: profile,
        motionState: TripMotionState.stopCandidate,
        evidenceDigest: evidenceDigest,
        needsWalkingReview: false,
        vehicleOnlyDwell: vehicleOnlyDwell,
        excludedWalkingCount: 0,
        rejectedDriftCount: rejectedDriftCount,
        rejectedUnsafeCount: rejectedUnsafeCount,
        acceptedDistanceCount: acceptedDistanceCount,
      );
    }

    final hasWalkingStopEvidence = strategy.hasWalkingStopEvidence(
      walkingEvidenceCount: walkingCount,
      observedAt:
          observation.observedAt ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      latestWalkingEvidenceAt: observation.latestWalkingEvidenceAt,
      walkingEvidenceSpan: walkingSpan,
    );
    final sustainedStationary = stationaryDuration >= minimumStationary;
    final trafficControlProtected = _looksLikeTrafficControl(
      strategy: strategy,
      observation: observation,
      stationaryDuration: stationaryDuration,
      rejectedDriftCount: rejectedDriftCount,
      walkingCount: walkingCount,
    );

    if (trafficControlProtected) {
      return _decision(
        status: TripStopDebounceStatus.trafficControlProtected,
        reasonCode: 'traffic_control_debounce_protected',
        profile: profile,
        motionState: observation.motionState,
        evidenceDigest: evidenceDigest,
        needsWalkingReview: false,
        vehicleOnlyDwell: vehicleOnlyDwell,
        excludedWalkingCount: 0,
        rejectedDriftCount: rejectedDriftCount,
        rejectedUnsafeCount: rejectedUnsafeCount,
        acceptedDistanceCount: acceptedDistanceCount,
      );
    }

    if (vehicleOnlyDwell.status ==
        TripVehicleOnlyDwellStatus.trafficControlProtected) {
      return _decision(
        status: TripStopDebounceStatus.trafficControlProtected,
        reasonCode: 'vehicle_only_dwell_traffic_control_protected',
        profile: profile,
        motionState: TripMotionState.stopCandidate,
        evidenceDigest: evidenceDigest,
        needsWalkingReview: false,
        vehicleOnlyDwell: vehicleOnlyDwell,
        excludedWalkingCount: 0,
        rejectedDriftCount: rejectedDriftCount,
        rejectedUnsafeCount: rejectedUnsafeCount,
        acceptedDistanceCount: acceptedDistanceCount,
      );
    }

    if (vehicleOnlyDwell.status ==
        TripVehicleOnlyDwellStatus.manualFallbackRecommended) {
      return _decision(
        status: TripStopDebounceStatus.waitingForEvidence,
        reasonCode: 'vehicle_only_dwell_manual_fallback',
        profile: profile,
        motionState: TripMotionState.stopCandidate,
        evidenceDigest: evidenceDigest,
        needsWalkingReview: false,
        vehicleOnlyDwell: vehicleOnlyDwell,
        excludedWalkingCount: walkingCount,
        rejectedDriftCount: rejectedDriftCount,
        rejectedUnsafeCount: rejectedUnsafeCount,
        acceptedDistanceCount: acceptedDistanceCount,
      );
    }

    if (!_speedAllowsStopReview(observation.speedMps) && walkingCount > 0) {
      return _decision(
        status: TripStopDebounceStatus.waitingForEvidence,
        reasonCode: 'vehicle_speed_blocks_stop_review',
        profile: profile,
        motionState: TripMotionState.stopCandidate,
        evidenceDigest: evidenceDigest,
        needsWalkingReview: false,
        vehicleOnlyDwell: vehicleOnlyDwell,
        excludedWalkingCount: walkingCount,
        rejectedDriftCount: rejectedDriftCount,
        rejectedUnsafeCount: rejectedUnsafeCount,
        acceptedDistanceCount: acceptedDistanceCount,
      );
    }

    if (walkingBurstProtected) {
      return _decision(
        status: TripStopDebounceStatus.waitingForEvidence,
        reasonCode: 'walking_burst_debounce_protected',
        profile: profile,
        motionState: TripMotionState.stopCandidate,
        evidenceDigest: evidenceDigest,
        needsWalkingReview: false,
        vehicleOnlyDwell: vehicleOnlyDwell,
        excludedWalkingCount: walkingCount,
        rejectedDriftCount: rejectedDriftCount,
        rejectedUnsafeCount: rejectedUnsafeCount,
        acceptedDistanceCount: acceptedDistanceCount,
      );
    }

    if (hasWalkingStopEvidence && sustainedStationary) {
      return _decision(
        status: TripStopDebounceStatus.readyForReview,
        reasonCode: 'walking_stop_debounce_ready',
        profile: profile,
        motionState: observation.motionState,
        evidenceDigest: evidenceDigest,
        needsWalkingReview: true,
        vehicleOnlyDwell: vehicleOnlyDwell,
        excludedWalkingCount: walkingCount,
        rejectedDriftCount: rejectedDriftCount,
        rejectedUnsafeCount: rejectedUnsafeCount,
        acceptedDistanceCount: acceptedDistanceCount,
      );
    }

    final stopCandidate =
        observation.motionState == TripMotionState.stopCandidate ||
        observation.motionState == TripMotionState.stopped ||
        sustainedStationary;
    if (stopCandidate) {
      return _decision(
        status: TripStopDebounceStatus.waitingForEvidence,
        reasonCode: 'stop_debounce_waiting_for_confirmation',
        profile: profile,
        motionState: TripMotionState.stopCandidate,
        evidenceDigest: evidenceDigest,
        needsWalkingReview: false,
        vehicleOnlyDwell: vehicleOnlyDwell,
        excludedWalkingCount: walkingCount,
        rejectedDriftCount: rejectedDriftCount,
        rejectedUnsafeCount: rejectedUnsafeCount,
        acceptedDistanceCount: acceptedDistanceCount,
      );
    }

    return _decision(
      status: TripStopDebounceStatus.keepTracking,
      reasonCode: 'stop_debounce_keep_tracking',
      profile: profile,
      motionState: observation.motionState,
      evidenceDigest: evidenceDigest,
      needsWalkingReview: false,
      vehicleOnlyDwell: vehicleOnlyDwell,
      excludedWalkingCount: walkingCount,
      rejectedDriftCount: rejectedDriftCount,
      rejectedUnsafeCount: rejectedUnsafeCount,
      acceptedDistanceCount: acceptedDistanceCount,
    );
  }
}

TripStopDebounceDecision _decision({
  required TripStopDebounceStatus status,
  required String reasonCode,
  required TripTrackingProfile profile,
  required TripMotionState motionState,
  required TripStopDebounceEvidenceDigest evidenceDigest,
  required bool needsWalkingReview,
  TripVehicleOnlyDwellDecision? vehicleOnlyDwell,
  required int excludedWalkingCount,
  required int rejectedDriftCount,
  required int rejectedUnsafeCount,
  required int acceptedDistanceCount,
}) {
  final classification = TripStopClassifier.classify(
    profile: profile,
    motionState: motionState,
    needsWalkingReview: needsWalkingReview,
    excludedWalkingCount: excludedWalkingCount,
    rejectedDriftCount: rejectedDriftCount,
    rejectedUnsafeCount: rejectedUnsafeCount,
    acceptedDistanceCount: acceptedDistanceCount,
  );
  final canOpenReview =
      status == TripStopDebounceStatus.readyForReview &&
      classification.requiresUserReview &&
      classification.canSuggestStop;
  return TripStopDebounceDecision(
    status: status,
    profile: profile,
    classification: classification,
    reasonCode: reasonCode,
    evidenceDigest: evidenceDigest,
    needsWalkingReview: needsWalkingReview,
    protectedTrafficControl:
        status == TripStopDebounceStatus.trafficControlProtected,
    shouldContinueSampling: !canOpenReview,
    canOpenReview: canOpenReview,
    vehicleOnlyDwell: vehicleOnlyDwell,
  );
}

bool _unsafeObservation(TripStopDebounceObservation value) {
  if (!value.speedMps.isFinite || !value.horizontalAccuracyMeters.isFinite) {
    return true;
  }
  if (value.speedMps < -0.5 || value.speedMps > 90) return true;
  if (value.horizontalAccuracyMeters < 0 ||
      value.horizontalAccuracyMeters > 250) {
    return true;
  }
  return value.stationaryDuration < Duration.zero ||
      value.walkingEvidenceSpan < Duration.zero;
}

bool _looksLikeTrafficControl({
  required TripTrackingProfileStrategy strategy,
  required TripStopDebounceObservation observation,
  required Duration stationaryDuration,
  required int rejectedDriftCount,
  required int walkingCount,
}) {
  if (walkingCount > 0) return false;
  if (observation.motionState == TripMotionState.stopped) return false;
  if (stationaryDuration > _trafficControlCeilingFor(strategy)) return false;
  if (rejectedDriftCount < 4) return false;
  return observation.speedMps <= 1.2;
}

bool _looksLikeWalkingBurst({
  required TripTrackingProfileStrategy strategy,
  required int walkingCount,
  required Duration walkingSpan,
}) {
  if (!strategy.usesWalkingStopEvidence) return false;
  if (walkingCount < strategy.walkingConfirmationCount) return false;
  return walkingSpan < strategy.minimumWalkingEvidenceSpacing;
}

bool _speedAllowsStopReview(double speedMps) =>
    speedMps.isFinite && speedMps <= 1.4;

Duration _minimumStationaryFor(TripTrackingProfileStrategy strategy) {
  if (strategy.workStyle == TripTrackingWorkStyle.rideshare) {
    return const Duration(seconds: 45);
  }
  if (strategy.workStyle == TripTrackingWorkStyle.contractor) {
    return const Duration(seconds: 25);
  }
  if (strategy.workStyle == TripTrackingWorkStyle.delivery) {
    return const Duration(seconds: 20);
  }
  return const Duration(seconds: 35);
}

Duration _trafficControlCeilingFor(TripTrackingProfileStrategy strategy) {
  if (strategy.workStyle == TripTrackingWorkStyle.rideshare) {
    return const Duration(minutes: 5);
  }
  if (strategy.workStyle == TripTrackingWorkStyle.delivery) {
    return const Duration(minutes: 4);
  }
  return const Duration(minutes: 3);
}

int _safeCount(int value) {
  if (value <= 0) return 0;
  return value > 100000 ? 100000 : value;
}

Duration _safeDuration(Duration value) {
  if (value.isNegative) return Duration.zero;
  return value > const Duration(hours: 24) ? const Duration(hours: 24) : value;
}

String _safeReason(String value) {
  return switch (value.trim()) {
    'unsafe_stop_debounce_evidence' => 'unsafe_stop_debounce_evidence',
    'vehicle_movement_required_before_stop_review' =>
      'vehicle_movement_required_before_stop_review',
    'traffic_control_debounce_protected' =>
      'traffic_control_debounce_protected',
    'vehicle_only_dwell_manual_fallback' =>
      'vehicle_only_dwell_manual_fallback',
    'walking_burst_debounce_protected' => 'walking_burst_debounce_protected',
    'vehicle_speed_blocks_stop_review' => 'vehicle_speed_blocks_stop_review',
    'future_walking_evidence_rejected' => 'future_walking_evidence_rejected',
    'stale_walking_evidence_rejected' => 'stale_walking_evidence_rejected',
    'undated_walking_evidence_rejected' => 'undated_walking_evidence_rejected',
    'walking_stop_debounce_ready' => 'walking_stop_debounce_ready',
    'stop_debounce_waiting_for_confirmation' =>
      'stop_debounce_waiting_for_confirmation',
    'stop_debounce_keep_tracking' => 'stop_debounce_keep_tracking',
    _ => 'unsafe_stop_debounce_evidence',
  };
}
