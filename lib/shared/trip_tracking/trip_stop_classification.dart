import 'trip_tracking_models.dart';
import 'trip_tracking_profile_strategy.dart';

enum TripStopSignal {
  noStop,
  stopCandidate,
  reviewOnlyStop,
  likelyTrafficControl,
  equipmentIgnored,
  unsafeEvidence,
}

enum TripStopReviewConfidence { none, low, medium, high }

class TripStopClassification {
  const TripStopClassification({
    required this.signal,
    required this.reviewConfidence,
    required this.reasonCode,
    required this.requiresUserReview,
    required this.canSuggestStop,
    required this.shouldSurfaceManualStopFallback,
    required this.actionToken,
    required this.dashboardMessage,
  });

  final TripStopSignal signal;
  final TripStopReviewConfidence reviewConfidence;
  final String reasonCode;
  final bool requiresUserReview;
  final bool canSuggestStop;
  final bool shouldSurfaceManualStopFallback;
  final String actionToken;
  final String dashboardMessage;

  bool get isStopLike =>
      signal == TripStopSignal.stopCandidate ||
      signal == TripStopSignal.reviewOnlyStop;

  Map<String, Object?> toSafeSummary() {
    final safeReasonCode = _safeStopReason(reasonCode);
    final safeReviewAllowed = _safeRequiresStopReview(
      signal: signal,
      reasonCode: safeReasonCode,
      requiresUserReview: requiresUserReview,
      canSuggestStop: canSuggestStop,
    );
    final safeSuggestionAllowed = _safeCanSuggestStop(
      signal: signal,
      reasonCode: safeReasonCode,
      canSuggestStop: canSuggestStop,
    );
    final safeManualFallbackAllowed = _safeShouldSurfaceManualStopFallback(
      signal: signal,
      reasonCode: safeReasonCode,
      shouldSurfaceManualStopFallback: shouldSurfaceManualStopFallback,
    );
    return {
      'schemaVersion': 1,
      'signal': signal.name,
      'reviewConfidence': _safeReviewConfidence(
        reviewConfidence,
        signal: signal,
        reasonCode: safeReasonCode,
        canSuggestStop: safeSuggestionAllowed,
      ).name,
      'reasonCode': safeReasonCode,
      'requiresUserReview': safeReviewAllowed,
      'canSuggestStop': safeSuggestionAllowed,
      'reviewOnly': true,
      'advisoryOnly': true,
      'gpsAssistedOnly': true,
      'manualStopFallbackAvailable': true,
      'shouldSurfaceManualStopFallback': safeManualFallbackAllowed,
      'vehicleOnlyStopFallbackAvailable': true,
      'longTrafficLightProtected': true,
      'walkingEvidenceCanOnlySuggestReview': true,
      'activityRecognitionCanCreateOfficialStop': false,
      'externalMotionDataValidatedBeforeUse': true,
      'stopEvidenceTrustedAfterValidationOnly': true,
      'unsafeEvidenceCanCreateStop': false,
      'unsafeEvidenceSuppressesStopReview':
          signal == TripStopSignal.unsafeEvidence,
      'remoteStopSummaryCanOverrideLocalTrip': false,
      'remoteDashboardCanOpenStopReview': false,
      'importedStopSummaryCanOpenStopReview': false,
      'localTripLogRequiredForReview': true,
      'authenticatedUserStillNeedsAuthorization': true,
      'fleetObserverCanCreateStop': false,
      'firestoreCanCreateOfficialStop': false,
      'cloudFunctionCanCreateOfficialStop': false,
      'malformedStopSummaryFailsSafe': true,
      'reviewConfidenceCanCreateOfficialStop': false,
      'reviewConfidenceCanEndTripAutomatically': false,
      'reviewConfidenceCanReplaceOdometer': false,
      'officialStopSource': 'user_review',
      'officialMileageSource': 'odometer',
      'odometerIsGlobalTruth': true,
      'physicalOdometerRequiredForOfficialMileage': true,
      'confirmedOdometerOverridesExternalMileage': true,
      'externalMileageCannotBecomeGlobalTruth': true,
      'gpsDistanceCanOnlyAdviseMileageReview': true,
      'mapMatchingCanOnlyAdviseMileageReview': true,
      'optimizationCannotChangeOfficialMileage': true,
      'canCreateOfficialStop': false,
      'canReplaceOdometer': false,
      'canEndTripAutomatically': false,
      'stopRequiresAcceptedVehicleMovement': true,
      'actionToken': _safeStopAction(actionToken),
      'dashboardMessage': _safeStopMessage(dashboardMessage),
      'mapsRequiredForStopReview': false,
      'mapboxCanCreateStop': false,
      'mapboxCanEndTrip': false,
      'mapboxDirectionsCanCreateStop': false,
      'mapboxMatrixCanCreateStop': false,
      'mapboxMapMatchingCanReplaceMileage': false,
      'mapboxOptimizationCanReorderOfficialStops': false,
      'rawSamplesIncluded': false,
      'rawMotionPayloadIncluded': false,
      'coordinatesIncluded': false,
      'routeGeometryIncluded': false,
      'mapboxGeometryIncluded': false,
      'tokensIncluded': false,
    };
  }
}

TripStopReviewConfidence _safeReviewConfidence(
  TripStopReviewConfidence value, {
  required TripStopSignal signal,
  required String reasonCode,
  required bool canSuggestStop,
}) {
  if (signal == TripStopSignal.unsafeEvidence ||
      signal == TripStopSignal.equipmentIgnored ||
      signal == TripStopSignal.noStop) {
    return TripStopReviewConfidence.none;
  }
  if (signal == TripStopSignal.likelyTrafficControl) {
    return TripStopReviewConfidence.low;
  }
  if (signal == TripStopSignal.stopCandidate) {
    return value == TripStopReviewConfidence.none
        ? TripStopReviewConfidence.low
        : value;
  }
  if (!canSuggestStop) return TripStopReviewConfidence.none;
  return switch (reasonCode) {
    'delivery_stop_walk_review' || 'contractor_stop_walk_review' =>
      value == TripStopReviewConfidence.high
          ? value
          : TripStopReviewConfidence.medium,
    'rideshare_stop_requires_extra_evidence' =>
      value == TripStopReviewConfidence.high
          ? TripStopReviewConfidence.medium
          : value,
    'road_vehicle_stop_walk_review' =>
      value == TripStopReviewConfidence.none
          ? TripStopReviewConfidence.low
          : value,
    _ => TripStopReviewConfidence.none,
  };
}

bool _safeShouldSurfaceManualStopFallback({
  required TripStopSignal signal,
  required String reasonCode,
  required bool shouldSurfaceManualStopFallback,
}) {
  if (!shouldSurfaceManualStopFallback) return false;
  return switch (signal) {
    TripStopSignal.reviewOnlyStop => _safeCanSuggestStop(
      signal: signal,
      reasonCode: reasonCode,
      canSuggestStop: true,
    ),
    TripStopSignal.stopCandidate =>
      reasonCode == 'stop_candidate_waiting_for_stronger_evidence' ||
          reasonCode == 'stop_candidate_waiting_for_confirmation',
    TripStopSignal.likelyTrafficControl =>
      reasonCode == 'traffic_control_or_stationary_jitter',
    _ => false,
  };
}

bool _safeRequiresStopReview({
  required TripStopSignal signal,
  required String reasonCode,
  required bool requiresUserReview,
  required bool canSuggestStop,
}) {
  return requiresUserReview &&
      _safeCanSuggestStop(
        signal: signal,
        reasonCode: reasonCode,
        canSuggestStop: canSuggestStop,
      );
}

bool _safeCanSuggestStop({
  required TripStopSignal signal,
  required String reasonCode,
  required bool canSuggestStop,
}) {
  if (!canSuggestStop || signal != TripStopSignal.reviewOnlyStop) return false;
  return switch (reasonCode) {
    'delivery_stop_walk_review' ||
    'contractor_stop_walk_review' ||
    'rideshare_stop_requires_extra_evidence' ||
    'road_vehicle_stop_walk_review' => true,
    _ => false,
  };
}

String _safeStopReason(String value) {
  final clean = value.trim();
  return switch (clean) {
    'unsafe_stop_evidence_rejected' => clean,
    'equipment_walking_evidence_ignored' => clean,
    'walking_stop_without_vehicle_movement' => clean,
    'delivery_stop_walk_review' => clean,
    'contractor_stop_walk_review' => clean,
    'rideshare_stop_requires_extra_evidence' => clean,
    'road_vehicle_stop_walk_review' => clean,
    'stop_candidate_waiting_for_stronger_evidence' => clean,
    'stop_candidate_waiting_for_confirmation' => clean,
    'traffic_control_or_stationary_jitter' => clean,
    'no_stop_review_needed' => clean,
    _ => 'unsafe_stop_evidence_rejected',
  };
}

String _safeStopAction(String value) {
  final clean = value.trim();
  return switch (clean) {
    'keep_tracking' => clean,
    'continue_monitoring' => clean,
    'review_delivery_stop' => clean,
    'review_jobsite_stop' => clean,
    'review_shift_stop' => clean,
    'review_trip_stop' => clean,
    _ => 'keep_tracking',
  };
}

String _safeStopMessage(String value) {
  final clean = value.trim();
  return switch (clean) {
    'Stop evidence was ignored because the GPS provider data was not safe enough to trust.' =>
      clean,
    'Walking-style evidence is ignored for this equipment profile.' => clean,
    'Walking evidence was ignored because no vehicle movement was accepted first.' =>
      clean,
    'The trip may be stopped, but this profile needs stronger evidence before showing a stop review.' =>
      clean,
    'The trip may be stopped; Maintainiac is waiting for confirmation before suggesting a review.' =>
      clean,
    'Stationary GPS jitter was treated like a traffic light or road delay, not a customer stop.' =>
      clean,
    'No stop review is needed right now.' => clean,
    'Walking evidence suggests a pickup or dropoff stop. Review it before it becomes official.' =>
      clean,
    'Walking evidence suggests a job-site stop. Review it before it becomes official.' =>
      clean,
    'Sustained walking evidence suggests the driver may have ended or paused the shift.' =>
      clean,
    'Walking evidence suggests a stop. Review it before it becomes official.' =>
      clean,
    'No stop review is needed for this equipment profile.' => clean,
    _ =>
      'Stop evidence is unavailable. Keep tracking and review mileage later.',
  };
}

class TripStopClassifier {
  const TripStopClassifier._();

  static TripStopClassification classify({
    required TripTrackingProfile profile,
    required TripMotionState motionState,
    required bool needsWalkingReview,
    required int excludedWalkingCount,
    required int rejectedDriftCount,
    required int rejectedUnsafeCount,
    int acceptedDistanceCount = 0,
  }) {
    final strategy = TripTrackingProfileStrategy.forProfile(profile);
    final safeExcludedWalkingCount = _safeEvidenceCount(excludedWalkingCount);
    final safeRejectedDriftCount = _safeEvidenceCount(rejectedDriftCount);
    final safeRejectedUnsafeCount = _safeEvidenceCount(rejectedUnsafeCount);
    final safeAcceptedDistanceCount = _safeEvidenceCount(acceptedDistanceCount);

    if (safeRejectedUnsafeCount >= 3 &&
        safeRejectedUnsafeCount >= safeExcludedWalkingCount) {
      return TripStopClassification(
        signal: TripStopSignal.unsafeEvidence,
        reviewConfidence: TripStopReviewConfidence.none,
        reasonCode: 'unsafe_stop_evidence_rejected',
        requiresUserReview: false,
        canSuggestStop: false,
        shouldSurfaceManualStopFallback: false,
        actionToken: 'keep_tracking',
        dashboardMessage:
            'Stop evidence was ignored because the GPS provider data was not safe enough to trust.',
      );
    }
    if (!strategy.usesWalkingStopEvidence && safeExcludedWalkingCount > 0) {
      return TripStopClassification(
        signal: TripStopSignal.equipmentIgnored,
        reviewConfidence: TripStopReviewConfidence.none,
        reasonCode: 'equipment_walking_evidence_ignored',
        requiresUserReview: false,
        canSuggestStop: false,
        shouldSurfaceManualStopFallback: false,
        actionToken: 'keep_tracking',
        dashboardMessage:
            'Walking-style evidence is ignored for this equipment profile.',
      );
    }
    if (needsWalkingReview &&
        safeExcludedWalkingCount > 0 &&
        safeAcceptedDistanceCount == 0) {
      return const TripStopClassification(
        signal: TripStopSignal.unsafeEvidence,
        reviewConfidence: TripStopReviewConfidence.none,
        reasonCode: 'walking_stop_without_vehicle_movement',
        requiresUserReview: false,
        canSuggestStop: false,
        shouldSurfaceManualStopFallback: false,
        actionToken: 'keep_tracking',
        dashboardMessage:
            'Walking evidence was ignored because no vehicle movement was accepted first.',
      );
    }
    if (needsWalkingReview && safeExcludedWalkingCount > 0) {
      return TripStopClassification(
        signal: TripStopSignal.reviewOnlyStop,
        reviewConfidence: _reviewConfidenceFor(strategy.workStyle),
        reasonCode: strategy.stopReviewReasonCode,
        requiresUserReview: true,
        canSuggestStop: true,
        shouldSurfaceManualStopFallback: true,
        actionToken: _reviewActionFor(strategy.workStyle),
        dashboardMessage: _reviewMessageFor(strategy.workStyle),
      );
    }
    if (safeRejectedDriftCount >= 6 &&
        safeExcludedWalkingCount == 0 &&
        safeAcceptedDistanceCount > 0 &&
        motionState != TripMotionState.stopped) {
      return TripStopClassification(
        signal: TripStopSignal.likelyTrafficControl,
        reviewConfidence: TripStopReviewConfidence.low,
        reasonCode: 'traffic_control_or_stationary_jitter',
        requiresUserReview: false,
        canSuggestStop: false,
        shouldSurfaceManualStopFallback:
            strategy.vehicleOnlyStopsNeedManualFallback,
        actionToken: 'keep_tracking',
        dashboardMessage:
            'Stationary GPS jitter was treated like a traffic light or road delay, not a customer stop.',
      );
    }
    if (motionState == TripMotionState.stopCandidate) {
      return TripStopClassification(
        signal: TripStopSignal.stopCandidate,
        reviewConfidence: strategy.vehicleOnlyStopsNeedManualFallback
            ? TripStopReviewConfidence.low
            : TripStopReviewConfidence.none,
        reasonCode: strategy.requiresStrongerStopDebounce
            ? 'stop_candidate_waiting_for_stronger_evidence'
            : 'stop_candidate_waiting_for_confirmation',
        requiresUserReview: false,
        canSuggestStop: false,
        shouldSurfaceManualStopFallback:
            safeAcceptedDistanceCount > 0 &&
            strategy.vehicleOnlyStopsNeedManualFallback,
        actionToken: 'continue_monitoring',
        dashboardMessage: strategy.requiresStrongerStopDebounce
            ? 'The trip may be stopped, but this profile needs stronger evidence before showing a stop review.'
            : 'The trip may be stopped; Maintainiac is waiting for confirmation before suggesting a review.',
      );
    }
    return const TripStopClassification(
      signal: TripStopSignal.noStop,
      reviewConfidence: TripStopReviewConfidence.none,
      reasonCode: 'no_stop_review_needed',
      requiresUserReview: false,
      canSuggestStop: false,
      shouldSurfaceManualStopFallback: false,
      actionToken: 'keep_tracking',
      dashboardMessage: 'No stop review is needed right now.',
    );
  }
}

String _reviewActionFor(TripTrackingWorkStyle workStyle) {
  return switch (workStyle) {
    TripTrackingWorkStyle.delivery => 'review_delivery_stop',
    TripTrackingWorkStyle.contractor => 'review_jobsite_stop',
    TripTrackingWorkStyle.rideshare => 'review_shift_stop',
    TripTrackingWorkStyle.generalRoad => 'review_trip_stop',
    TripTrackingWorkStyle.equipment => 'keep_tracking',
  };
}

TripStopReviewConfidence _reviewConfidenceFor(TripTrackingWorkStyle workStyle) {
  return switch (workStyle) {
    TripTrackingWorkStyle.delivery => TripStopReviewConfidence.high,
    TripTrackingWorkStyle.contractor => TripStopReviewConfidence.high,
    TripTrackingWorkStyle.rideshare => TripStopReviewConfidence.medium,
    TripTrackingWorkStyle.generalRoad => TripStopReviewConfidence.low,
    TripTrackingWorkStyle.equipment => TripStopReviewConfidence.none,
  };
}

int _safeEvidenceCount(int value) {
  if (value <= 0) return 0;
  return value > 100000 ? 100000 : value;
}

String _reviewMessageFor(TripTrackingWorkStyle workStyle) {
  return switch (workStyle) {
    TripTrackingWorkStyle.delivery =>
      'Walking evidence suggests a pickup or dropoff stop. Review it before it becomes official.',
    TripTrackingWorkStyle.contractor =>
      'Walking evidence suggests a job-site stop. Review it before it becomes official.',
    TripTrackingWorkStyle.rideshare =>
      'Sustained walking evidence suggests the driver may have ended or paused the shift.',
    TripTrackingWorkStyle.generalRoad =>
      'Walking evidence suggests a stop. Review it before it becomes official.',
    TripTrackingWorkStyle.equipment =>
      'No stop review is needed for this equipment profile.',
  };
}
