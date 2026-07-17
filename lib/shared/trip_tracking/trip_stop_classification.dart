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
    'signal': signal.name,
    'reasonCode': reasonCode,
    'requiresUserReview': requiresUserReview,
    'canSuggestStop': canSuggestStop,
    'actionToken': actionToken,
    'dashboardMessage': dashboardMessage,
    'rawSamplesIncluded': false,
    'coordinatesIncluded': false,
    'routeGeometryIncluded': false,
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
