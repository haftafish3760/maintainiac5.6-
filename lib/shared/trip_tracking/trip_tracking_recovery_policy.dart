import 'trip_live_odometer_projection.dart';
import 'trip_tracking_models.dart';
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
    'schemaVersion': 1,
    'status': status.name,
    'safeReason': _safeRecoveryReason(safeReason),
    'canRestore': _safeCanRestore(
      status: status,
      reason: safeReason,
      canRestore: canRestore,
      estimatedOdometer: estimatedOdometer,
    ),
    'requiresUserAction': _safeRequiresUserAction(
      status: status,
      reason: safeReason,
      requiresUserAction: requiresUserAction,
      canRestore: canRestore,
      estimatedOdometer: estimatedOdometer,
    ),
    'pendingSampleQueued': _safePendingSampleQueued(
      status: status,
      reason: safeReason,
      pendingSampleQueued: pendingSampleQueued,
      canRestore: canRestore,
      estimatedOdometer: estimatedOdometer,
    ),
    if (_safeEstimatedOdometer(estimatedOdometer) != null)
      'estimatedOdometer': _safeEstimatedOdometer(estimatedOdometer),
    'localRecoveryAuthoritative': true,
    'firestoreCanOverrideLocalRecovery': false,
    'cloudMirrorCanDeleteLocalRecovery': false,
    'recoveryNeverDeletesTripData': true,
    'backgroundInterruptionCanDeleteCheckpoint': false,
    'permissionLossCanDeleteCheckpoint': false,
    'localCheckpointPreservedUntilReview': true,
    'odometerRemainsCanonical': true,
    'odometerIsGlobalTruth': true,
    'mapboxCanRestoreTrip': false,
    'mapboxCanModifyRecoveredOdometer': false,
    'manualReviewRequiredBeforeConfirmation': _safeRequiresUserAction(
      status: status,
      reason: safeReason,
      requiresUserAction: requiresUserAction,
      canRestore: canRestore,
      estimatedOdometer: estimatedOdometer,
    ),
    'requiresSameVehicle': true,
    'requiresSameConfirmedOdometer': true,
    'estimatedOdometerTrustedAfterValidationOnly': true,
    'invalidEstimatedOdometerCanRestore': false,
    'remotePendingSampleCanReplayWithoutValidation': false,
    'rawLocationIncluded': false,
    'routeGeometryIncluded': false,
    'pendingSampleIncluded': false,
    'rawSessionIncluded': false,
    'rawReviewIncluded': false,
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
    if (!session.hasValidTimeline ||
        !_isRecoverableLifecycleState(session.lifecycleState)) {
      return _decision(
        TripTrackingRecoveryStatus.invalidSession,
        'trip_recovery_invalid_session',
        userAction: true,
      );
    }
    final savedReview = review;
    if (savedReview != null) {
      if (!savedReview.hasValidTimeline ||
          savedReview.id != session.id ||
          !_sameSafeVehicleId(savedReview.vehicleId, session.vehicleId) ||
          savedReview.profile != session.profile ||
          savedReview.startedAt != session.startedAt) {
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
    if (!_sameSafeVehicleId(session.vehicleId, currentVehicleId)) {
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
    final hasPending = _hasRecoverablePendingSample(
      session: session,
      pendingSample: pendingSample,
    );
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

bool _isRecoverableLifecycleState(TripTrackingSessionLifecycleState state) =>
    switch (state) {
      TripTrackingSessionLifecycleState.ready ||
      TripTrackingSessionLifecycleState.starting ||
      TripTrackingSessionLifecycleState.active ||
      TripTrackingSessionLifecycleState.paused ||
      TripTrackingSessionLifecycleState.degraded ||
      TripTrackingSessionLifecycleState.interrupted ||
      TripTrackingSessionLifecycleState.recovering ||
      TripTrackingSessionLifecycleState.stopping ||
      TripTrackingSessionLifecycleState.failedRecoverable => true,
      TripTrackingSessionLifecycleState.disabled ||
      TripTrackingSessionLifecycleState.permissionRequired ||
      TripTrackingSessionLifecycleState.awaitingReview ||
      TripTrackingSessionLifecycleState.completed ||
      TripTrackingSessionLifecycleState.failedTerminal => false,
    };

bool _sameSafeVehicleId(String left, String right) {
  final safeLeft = _safeRecoveryVehicleId(left);
  final safeRight = _safeRecoveryVehicleId(right);
  return safeLeft != null && safeLeft == safeRight;
}

String? _safeRecoveryVehicleId(String value) {
  final clean = value.trim();
  if (clean.isEmpty || clean.length > 120) return null;
  return RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(clean) ? clean : null;
}

bool _hasRecoverablePendingSample({
  required TripTrackingSessionRecord session,
  required TripTrackingPendingSample? pendingSample,
}) {
  final pending = pendingSample;
  if (pending == null || pending.sessionId != session.id) return false;
  if (!pending.sample.hasValidCoordinate || !pending.sample.hasValidAccuracy) {
    return false;
  }
  if (pending.sample.mockedLocation == true) return false;
  if (pending.sample.recordedAt.isBefore(session.startedAt)) return false;
  final replayWindowEnd = session.updatedAt.add(const Duration(minutes: 5));
  if (pending.sample.recordedAt.isAfter(replayWindowEnd)) return false;
  final activity = pending.activity;
  if (activity != null) {
    if (activity.confidence < 0 || activity.confidence > 100) return false;
    if (pending.sample.recordedAt.isBefore(activity.recordedAt)) return false;
    if (pending.sample.recordedAt.difference(activity.recordedAt) >
        const Duration(seconds: 90)) {
      return false;
    }
  }
  return true;
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

String _safeRecoveryReason(String value) {
  return switch (value.trim()) {
    'trip_recovery_none' => 'trip_recovery_none',
    'trip_recovery_ready' => 'trip_recovery_ready',
    'trip_recovery_pending_replay_ready' =>
      'trip_recovery_pending_replay_ready',
    'trip_recovery_invalid_session' => 'trip_recovery_invalid_session',
    'trip_recovery_completed_review_present' =>
      'trip_recovery_completed_review_present',
    'trip_recovery_invalid_review_present' =>
      'trip_recovery_invalid_review_present',
    'trip_recovery_vehicle_mismatch' => 'trip_recovery_vehicle_mismatch',
    'trip_recovery_odometer_mismatch' => 'trip_recovery_odometer_mismatch',
    'trip_recovery_odometer_projection_invalid' =>
      'trip_recovery_odometer_projection_invalid',
    _ => 'trip_recovery_invalid_session',
  };
}

int? _safeEstimatedOdometer(int? value) {
  if (value == null || value < 0 || value > 9999999) return null;
  return value;
}

bool _safeCanRestore({
  required TripTrackingRecoveryStatus status,
  required String reason,
  required bool canRestore,
  required int? estimatedOdometer,
}) {
  if (!canRestore || _safeEstimatedOdometer(estimatedOdometer) == null) {
    return false;
  }
  return switch ((_safeRecoveryReason(reason), status)) {
    ('trip_recovery_ready', TripTrackingRecoveryStatus.ready) => true,
    (
      'trip_recovery_pending_replay_ready',
      TripTrackingRecoveryStatus.pendingReplayReady,
    ) =>
      true,
    _ => false,
  };
}

bool _safeRequiresUserAction({
  required TripTrackingRecoveryStatus status,
  required String reason,
  required bool requiresUserAction,
  required bool canRestore,
  required int? estimatedOdometer,
}) {
  if (_safeCanRestore(
    status: status,
    reason: reason,
    canRestore: canRestore,
    estimatedOdometer: estimatedOdometer,
  )) {
    return false;
  }
  return status != TripTrackingRecoveryStatus.noRecoverableTrip ||
      _safeRecoveryReason(reason) == 'trip_recovery_invalid_session' ||
      requiresUserAction;
}

bool _safePendingSampleQueued({
  required TripTrackingRecoveryStatus status,
  required String reason,
  required bool pendingSampleQueued,
  required bool canRestore,
  required int? estimatedOdometer,
}) {
  return pendingSampleQueued &&
      _safeCanRestore(
        status: status,
        reason: reason,
        canRestore: canRestore,
        estimatedOdometer: estimatedOdometer,
      ) &&
      _safeRecoveryReason(reason) == 'trip_recovery_pending_replay_ready';
}
