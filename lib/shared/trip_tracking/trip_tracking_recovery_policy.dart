import 'trip_live_odometer_projection.dart';
import 'trip_tracking_session_store.dart';

enum TripTrackingRecoveryStatus {
  noRecoverableTrip,
  ready,
  pendingReplayReady,
  invalidSession,
  completedReviewPresent,
  invalidReviewPresent,
  vehicleMismatch,
  odometerMismatch,
  odometerProjectionInvalid,
}

class TripTrackingRecoveryDecision {
  const TripTrackingRecoveryDecision({
    required this.status,
    required this.safeReason,
    required this.canRestore,
    required this.requiresUserAction,
    required this.estimatedOdometer,
    required this.pendingSampleQueued,
  });

  final TripTrackingRecoveryStatus status;
  final String safeReason;
  final bool canRestore;
  final bool requiresUserAction;
  final int? estimatedOdometer;
  final bool pendingSampleQueued;

  Map<String, Object?> toSafeSummary() => {
    'status': status.name,
    'safeReason': safeReason,
    'canRestore': canRestore,
    'requiresUserAction': requiresUserAction,
    'pendingSampleQueued': pendingSampleQueued,
    if (estimatedOdometer != null) 'estimatedOdometer': estimatedOdometer,
    'rawLocationIncluded': false,
    'routeGeometryIncluded': false,
    'pendingSampleIncluded': false,
  };
}

class TripTrackingRecoveryPolicy {
  const TripTrackingRecoveryPolicy._();

  static TripTrackingRecoveryDecision evaluate({
    required TripTrackingSessionRecord? session,
    required String currentVehicleId,
    required int currentConfirmedOdometer,
    TripTrackingReviewRecord? review,
    TripTrackingPendingSample? pendingSample,
  }) {
    if (session == null) {
      return _decision(
        TripTrackingRecoveryStatus.noRecoverableTrip,
        'trip_recovery_none',
      );
    }
    if (!session.hasValidTimeline) {
      return _decision(
        TripTrackingRecoveryStatus.invalidSession,
        'trip_recovery_invalid_session',
        userAction: true,
      );
    }
    final savedReview = review;
    if (savedReview != null) {
      if (!savedReview.hasValidTimeline || savedReview.id != session.id) {
        return _decision(
          TripTrackingRecoveryStatus.invalidReviewPresent,
          'trip_recovery_invalid_review_present',
          userAction: true,
        );
      }
      return _decision(
        TripTrackingRecoveryStatus.completedReviewPresent,
        'trip_recovery_completed_review_present',
      );
    }
    if (session.vehicleId != currentVehicleId) {
      return _decision(
        TripTrackingRecoveryStatus.vehicleMismatch,
        'trip_recovery_vehicle_mismatch',
        userAction: true,
      );
    }
    if (session.startingOdometer != currentConfirmedOdometer) {
      return _decision(
        TripTrackingRecoveryStatus.odometerMismatch,
        'trip_recovery_odometer_mismatch',
        userAction: true,
      );
    }
    final projection = TripLiveOdometerProjection(
      startingOdometer: session.startingOdometer,
    );
    final estimated = projection.updateAcceptedMeters(
      session.engineSnapshot.totalAcceptedMeters,
    );
    if (estimated < session.startingOdometer) {
      return _decision(
        TripTrackingRecoveryStatus.odometerProjectionInvalid,
        'trip_recovery_odometer_projection_invalid',
        userAction: true,
      );
    }
    final hasPending = pendingSample?.sessionId == session.id;
    return TripTrackingRecoveryDecision(
      status: hasPending
          ? TripTrackingRecoveryStatus.pendingReplayReady
          : TripTrackingRecoveryStatus.ready,
      safeReason: hasPending
          ? 'trip_recovery_pending_replay_ready'
          : 'trip_recovery_ready',
      canRestore: true,
      requiresUserAction: false,
      estimatedOdometer: estimated,
      pendingSampleQueued: hasPending,
    );
  }
}

TripTrackingRecoveryDecision _decision(
  TripTrackingRecoveryStatus status,
  String reason, {
  bool userAction = false,
}) {
  return TripTrackingRecoveryDecision(
    status: status,
    safeReason: reason,
    canRestore: false,
    requiresUserAction: userAction,
    estimatedOdometer: null,
    pendingSampleQueued: false,
  );
}
