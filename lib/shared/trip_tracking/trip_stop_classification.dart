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

class TripStopClassification {
  const TripStopClassification({
    required this.signal,
    required this.reasonCode,
    required this.requiresUserReview,
    required this.canSuggestStop,
    required this.actionToken,
    required this.dashboardMessage,
  });

  final TripStopSignal signal;
  final String reasonCode;
  final bool requiresUserReview;
  final bool canSuggestStop;
  final String actionToken;
  final String dashboardMessage;

  bool get isStopLike =>
      signal == TripStopSignal.stopCandidate ||
      signal == TripStopSignal.reviewOnlyStop;

  Map<String, Object?> toSafeSummary() => {
    'schemaVersion': 1,
    'signal': signal.name,
    'reasonCode': _safeStopReason(reasonCode),
    'requiresUserReview': requiresUserReview,
    'canSuggestStop': canSuggestStop,
    'reviewOnly': true,
    'advisoryOnly': true,
    'gpsAssistedOnly': true,
    'manualStopFallbackAvailable': true,
    'vehicleOnlyStopFallbackAvailable': true,
    'longTrafficLightProtected': true,
    'walkingEvidenceCanOnlySuggestReview': true,
    'activityRecognitionCanCreateOfficialStop': false,
    'officialStopSource': 'user_review',
    'officialMileageSource': 'odometer',
    'canCreateOfficialStop': false,
    'canReplaceOdometer': false,
    'canEndTripAutomatically': false,
    'stopRequiresAcceptedVehicleMovement': true,
    'actionToken': _safeStopAction(actionToken),
    'dashboardMessage': _safeStopMessage(dashboardMessage),
    'mapsRequiredForStopReview': false,
    'mapboxCanCreateStop': false,
    'mapboxCanEndTrip': false,
    'rawSamplesIncluded': false,
    'rawMotionPayloadIncluded': false,
    'coordinatesIncluded': false,
    'routeGeometryIncluded': false,
    'mapboxGeometryIncluded': false,
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
    if (rejectedUnsafeCount >= 3 && acceptedDistanceCount == 0) {
      return const TripStopClassification(
        signal: TripStopSignal.unsafeEvidence,
        reasonCode: 'unsafe_stop_evidence_rejected',
        requiresUserReview: false,
        canSuggestStop: false,
        actionToken: 'keep_tracking',
        dashboardMessage:
            'Stop evidence was ignored because the GPS provider data was not safe enough to trust.',
      );
    }
    if (!strategy.usesWalkingStopEvidence && excludedWalkingCount > 0) {
      return const TripStopClassification(
        signal: TripStopSignal.equipmentIgnored,
        reasonCode: 'equipment_walking_evidence_ignored',
        requiresUserReview: false,
        canSuggestStop: false,
        actionToken: 'keep_tracking',
        dashboardMessage:
            'Walking-style evidence is ignored for this equipment profile.',
      );
    }
    if (needsWalkingReview &&
        excludedWalkingCount > 0 &&
        acceptedDistanceCount == 0) {
      return const TripStopClassification(
        signal: TripStopSignal.unsafeEvidence,
        reasonCode: 'walking_stop_without_vehicle_movement',
        requiresUserReview: false,
        canSuggestStop: false,
        actionToken: 'keep_tracking',
        dashboardMessage:
            'Walking evidence was ignored because no vehicle movement was accepted first.',
      );
    }
    if (needsWalkingReview && excludedWalkingCount > 0) {
      return TripStopClassification(
        signal: TripStopSignal.reviewOnlyStop,
        reasonCode: strategy.stopReviewReasonCode,
        requiresUserReview: true,
        canSuggestStop: true,
        actionToken: _reviewActionFor(strategy.workStyle),
        dashboardMessage: _reviewMessageFor(strategy.workStyle),
      );
    }
    if (motionState == TripMotionState.stopCandidate) {
      return TripStopClassification(
        signal: TripStopSignal.stopCandidate,
        reasonCode: strategy.requiresStrongerStopDebounce
            ? 'stop_candidate_waiting_for_stronger_evidence'
            : 'stop_candidate_waiting_for_confirmation',
        requiresUserReview: false,
        canSuggestStop: false,
        actionToken: 'continue_monitoring',
        dashboardMessage: strategy.requiresStrongerStopDebounce
            ? 'The trip may be stopped, but this profile needs stronger evidence before showing a stop review.'
            : 'The trip may be stopped; Maintainiac is waiting for confirmation before suggesting a review.',
      );
    }
    if (rejectedDriftCount >= 6 &&
        excludedWalkingCount == 0 &&
        motionState == TripMotionState.moving) {
      return const TripStopClassification(
        signal: TripStopSignal.likelyTrafficControl,
        reasonCode: 'traffic_control_or_stationary_jitter',
        requiresUserReview: false,
        canSuggestStop: false,
        actionToken: 'keep_tracking',
        dashboardMessage:
            'Stationary GPS jitter was treated like a traffic light or road delay, not a customer stop.',
      );
    }
    return const TripStopClassification(
      signal: TripStopSignal.noStop,
      reasonCode: 'no_stop_review_needed',
      requiresUserReview: false,
      canSuggestStop: false,
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
