import 'trip_tracking_session_recovery_validation.dart';
import 'trip_tracking_models.dart';
import 'trip_tracking_state_machine.dart';

enum TripRecoveryResumeStatus { ready, blocked }

enum TripRecoveryResumeReason {
  activeSessionCanResume,
  reviewCanOpen,
  quarantinedRecord,
  illegalLifecycleTransition,
  vehicleMismatch,
  unsafeVehicleBoundary,
  odometerRollbackRisk,
  invalidOdometerBoundary,
}

class TripRecoveryResumeDecision {
  const TripRecoveryResumeDecision({
    required this.status,
    required this.reason,
    required this.targetLifecycle,
    required this.canResumeNativeTracking,
    required this.canOpenReview,
    required this.requiresUserReview,
  });

  final TripRecoveryResumeStatus status;
  final TripRecoveryResumeReason reason;
  final TripTrackingSessionLifecycleState targetLifecycle;
  final bool canResumeNativeTracking;
  final bool canOpenReview;
  final bool requiresUserReview;

  bool get isReady => status == TripRecoveryResumeStatus.ready;

  Map<String, Object?> toSafeSummary() => {
    'schemaVersion': 1,
    'status': status.name,
    'reason': reason.name,
    'targetLifecycle': targetLifecycle.name,
    'canResumeNativeTracking': isReady && canResumeNativeTracking,
    'canOpenReview': isReady && canOpenReview,
    'requiresUserReview': requiresUserReview,
    'localRecoveryValidationRequired': true,
    'localLifecycleAuthoritative': true,
    'vehicleBoundaryValidated':
        reason != TripRecoveryResumeReason.unsafeVehicleBoundary,
    'odometerBoundaryValidated':
        reason != TripRecoveryResumeReason.invalidOdometerBoundary,
    'hiveRemainsOperationalSourceOfTruth': true,
    'firestoreCanReviveQuarantinedSession': false,
    'mapboxCanReviveQuarantinedSession': false,
    'cloudFunctionCanReviveQuarantinedSession': false,
    'remoteCheckpointCanOverrideLocalRecovery': false,
    'recoveryCanDeleteLocalData': false,
    'recoveryCanConfirmMileage': false,
    'recoveryCanCreateOfficialStop': false,
    'odometerRemainsOfficialMileageTruth': true,
    'rawGpsIncluded': false,
    'preciseLocationIncluded': false,
    'routeGeometryIncluded': false,
    'tokensIncluded': false,
  };
}

class TripRecoveryResumePolicy {
  const TripRecoveryResumePolicy._();

  static TripRecoveryResumeDecision evaluate({
    required TripTrackingSessionRecoveryValidation validation,
    required TripTrackingSessionLifecycleState currentLifecycle,
    required String currentVehicleId,
    required String expectedVehicleId,
    required int currentConfirmedOdometer,
    required int startingOdometer,
  }) {
    if (!validation.isRecoverable) {
      return _blocked(
        TripRecoveryResumeReason.quarantinedRecord,
        currentLifecycle,
      );
    }
    if (!_safeIdentifier(currentVehicleId) ||
        !_safeIdentifier(expectedVehicleId)) {
      return _blocked(
        TripRecoveryResumeReason.unsafeVehicleBoundary,
        currentLifecycle,
      );
    }
    if (currentConfirmedOdometer < 0 || startingOdometer < 0) {
      return _blocked(
        TripRecoveryResumeReason.invalidOdometerBoundary,
        currentLifecycle,
      );
    }
    if (currentVehicleId.trim() != expectedVehicleId.trim() ||
        validation.vehicleId != expectedVehicleId.trim()) {
      return _blocked(
        TripRecoveryResumeReason.vehicleMismatch,
        currentLifecycle,
      );
    }
    if (startingOdometer < currentConfirmedOdometer) {
      return _blocked(
        TripRecoveryResumeReason.odometerRollbackRisk,
        currentLifecycle,
      );
    }
    if (validation.status ==
        TripTrackingSessionRecoveryStatus.recoverableReview) {
      return TripRecoveryResumeDecision(
        status: TripRecoveryResumeStatus.ready,
        reason: TripRecoveryResumeReason.reviewCanOpen,
        targetLifecycle: TripTrackingSessionLifecycleState.awaitingReview,
        canResumeNativeTracking: false,
        canOpenReview: true,
        requiresUserReview: true,
      );
    }
    const target = TripTrackingSessionLifecycleState.recovering;
    if (!TripTrackingSessionStateMachine.canTransition(
      currentLifecycle,
      target,
    )) {
      return _blocked(
        TripRecoveryResumeReason.illegalLifecycleTransition,
        currentLifecycle,
      );
    }
    return const TripRecoveryResumeDecision(
      status: TripRecoveryResumeStatus.ready,
      reason: TripRecoveryResumeReason.activeSessionCanResume,
      targetLifecycle: target,
      canResumeNativeTracking: true,
      canOpenReview: false,
      requiresUserReview: false,
    );
  }
}

bool _safeIdentifier(String value) {
  return value.trim() == value &&
      value.isNotEmpty &&
      value.length <= 160 &&
      RegExp(r'^[A-Za-z0-9._:-]+$').hasMatch(value);
}

TripRecoveryResumeDecision _blocked(
  TripRecoveryResumeReason reason,
  TripTrackingSessionLifecycleState currentLifecycle,
) {
  return TripRecoveryResumeDecision(
    status: TripRecoveryResumeStatus.blocked,
    reason: reason,
    targetLifecycle: currentLifecycle,
    canResumeNativeTracking: false,
    canOpenReview: false,
    requiresUserReview: true,
  );
}
