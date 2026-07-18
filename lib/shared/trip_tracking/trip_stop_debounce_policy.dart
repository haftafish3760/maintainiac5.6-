import 'trip_gps_dependability_policy.dart';
import 'trip_stop_classification.dart';
import 'trip_stop_debounce_evidence_digest.dart';
import 'trip_stop_false_positive_guard.dart';
import 'trip_tracking_models.dart';
import 'trip_tracking_profile_strategy.dart';
import 'trip_tracking_signal_quality.dart';
import 'trip_vehicle_only_dwell_policy.dart';
import 'trip_walking_evidence_recency_guard.dart';

part 'trip_stop_debounce_dashboard_summary.dart';
part 'trip_stop_debounce_policy_helpers.dart';

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
    this.signalQuality = TripTrackingSignalQuality.healthy,
    this.gpsDependability,
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
  final TripTrackingSignalQuality signalQuality;
  final TripGpsDependabilityDecision? gpsDependability;
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
      signalQuality: observation.signalQuality,
    );
    final gpsDependability = observation.gpsDependability;

    if (gpsDependability?.status == TripGpsDependabilityStatus.unsafeBlocked) {
      return _decision(
        status: TripStopDebounceStatus.unsafeEvidence,
        reasonCode: 'gps_dependability_blocks_stop_review',
        profile: profile,
        motionState: observation.motionState,
        evidenceDigest: evidenceDigest,
        needsWalkingReview: false,
        vehicleOnlyDwell: vehicleOnlyDwell,
        excludedWalkingCount: walkingCount,
        rejectedDriftCount: rejectedDriftCount,
        rejectedUnsafeCount: rejectedUnsafeCount + 3,
        acceptedDistanceCount: acceptedDistanceCount,
      );
    }

    if (gpsDependability?.status ==
        TripGpsDependabilityStatus.projectionPaused) {
      return _decision(
        status: TripStopDebounceStatus.waitingForEvidence,
        reasonCode: 'gps_dependability_waiting_for_projection_grade_signal',
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

    if (gpsDependability != null && !gpsDependability.canOpenStopReview) {
      return _decision(
        status: TripStopDebounceStatus.waitingForEvidence,
        reasonCode: 'gps_dependability_blocks_stop_review_authority',
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

    if (unsafe ||
        rejectedUnsafeCount >= 3 ||
        _signalQualityUnsafe(observation.signalQuality)) {
      return _decision(
        status: TripStopDebounceStatus.unsafeEvidence,
        reasonCode: _signalQualityUnsafe(observation.signalQuality)
            ? 'unsafe_gps_blocks_stop_review'
            : 'unsafe_stop_debounce_evidence',
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

    if (_signalQualityBlocksStopReview(observation.signalQuality)) {
      return _decision(
        status: TripStopDebounceStatus.waitingForEvidence,
        reasonCode: 'gps_signal_quality_blocks_stop_review',
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
