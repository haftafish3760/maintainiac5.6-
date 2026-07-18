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
    'backgroundRecoveryCanRunWithoutMaps': true,
    'mapsRequiredForRecoveryResume': false,
    'vehicleBoundaryValidated':
        reason != TripRecoveryResumeReason.unsafeVehicleBoundary,
    'odometerBoundaryValidated':
        reason != TripRecoveryResumeReason.invalidOdometerBoundary,
    'hiveRemainsOperationalSourceOfTruth': true,
    'firestoreMirrorOnly': true,
    'firestoreCanReviveQuarantinedSession': false,
    'mapboxCanReviveQuarantinedSession': false,
    'cloudFunctionCanReviveQuarantinedSession': false,
    'firestoreCanForceResume': false,
    'mapboxCanForceResume': false,
    'cloudFunctionCanForceResume': false,
    'remoteCheckpointCanOverrideLocalRecovery': false,
    'recoveryCanDeleteLocalData': false,
    'recoveryCanPurgeLocalDeviceData': false,
    'recoveryCanConfirmMileage': false,
    'recoveryCanSetGlobalTruth': false,
    'recoveryCanChangeOfficialMileage': false,
    'recoveryCanCreateOfficialStop': false,
    'recoveryCanEndTripAutomatically': false,
    'recoveryCanReplayPendingSampleWithoutValidation': false,
    'odometerRemainsOfficialMileageTruth': true,
    'odometerIsGlobalTruth': true,
    'rawGpsIncluded': false,
    'preciseLocationIncluded': false,
    'routeGeometryIncluded': false,
    'tokensIncluded': false,
  };
}

class TripRecoveryResumeSummaryValidation {
  const TripRecoveryResumeSummaryValidation._({
    required this.isRenderable,
    required this.reasons,
  });

  factory TripRecoveryResumeSummaryValidation.fromSummary(
    Map<String, Object?> summary,
  ) {
    final reasons = <String>[];
    if (summary['schemaVersion'] != 1) {
      reasons.add('unsupported_schema_version');
    }
    if (_safeStatus(summary['status']) == null) {
      reasons.add('invalid_resume_status');
    }
    if (_safeReason(summary['reason']) == null) {
      reasons.add('invalid_resume_reason');
    }
    if (_safeLifecycle(summary['targetLifecycle']) == null) {
      reasons.add('invalid_target_lifecycle');
    }
    for (final key in const [
      'canResumeNativeTracking',
      'canOpenReview',
      'requiresUserReview',
      'localRecoveryValidationRequired',
      'localLifecycleAuthoritative',
      'backgroundRecoveryCanRunWithoutMaps',
      'mapsRequiredForRecoveryResume',
      'vehicleBoundaryValidated',
      'odometerBoundaryValidated',
      'hiveRemainsOperationalSourceOfTruth',
      'firestoreMirrorOnly',
      'firestoreCanReviveQuarantinedSession',
      'mapboxCanReviveQuarantinedSession',
      'cloudFunctionCanReviveQuarantinedSession',
      'firestoreCanForceResume',
      'mapboxCanForceResume',
      'cloudFunctionCanForceResume',
      'remoteCheckpointCanOverrideLocalRecovery',
      'recoveryCanDeleteLocalData',
      'recoveryCanPurgeLocalDeviceData',
      'recoveryCanConfirmMileage',
      'recoveryCanSetGlobalTruth',
      'recoveryCanChangeOfficialMileage',
      'recoveryCanCreateOfficialStop',
      'recoveryCanEndTripAutomatically',
      'recoveryCanReplayPendingSampleWithoutValidation',
      'odometerRemainsOfficialMileageTruth',
      'odometerIsGlobalTruth',
      'rawGpsIncluded',
      'preciseLocationIncluded',
      'routeGeometryIncluded',
      'tokensIncluded',
    ]) {
      if (summary[key] is! bool) reasons.add('${key}_not_bool');
    }
    if (summary['localRecoveryValidationRequired'] != true ||
        summary['localLifecycleAuthoritative'] != true ||
        summary['backgroundRecoveryCanRunWithoutMaps'] != true ||
        summary['mapsRequiredForRecoveryResume'] != false) {
      reasons.add('recovery_resume_boundary_missing');
    }
    if (summary['hiveRemainsOperationalSourceOfTruth'] != true ||
        summary['firestoreMirrorOnly'] != true ||
        summary['odometerRemainsOfficialMileageTruth'] != true ||
        summary['odometerIsGlobalTruth'] != true) {
      reasons.add('recovery_source_of_truth_boundary_missing');
    }
    if (summary['firestoreCanReviveQuarantinedSession'] != false ||
        summary['mapboxCanReviveQuarantinedSession'] != false ||
        summary['cloudFunctionCanReviveQuarantinedSession'] != false ||
        summary['firestoreCanForceResume'] != false ||
        summary['mapboxCanForceResume'] != false ||
        summary['cloudFunctionCanForceResume'] != false ||
        summary['remoteCheckpointCanOverrideLocalRecovery'] != false) {
      reasons.add('remote_or_map_can_force_resume');
    }
    if (summary['recoveryCanDeleteLocalData'] != false ||
        summary['recoveryCanPurgeLocalDeviceData'] != false ||
        summary['recoveryCanConfirmMileage'] != false ||
        summary['recoveryCanSetGlobalTruth'] != false ||
        summary['recoveryCanChangeOfficialMileage'] != false ||
        summary['recoveryCanCreateOfficialStop'] != false ||
        summary['recoveryCanEndTripAutomatically'] != false ||
        summary['recoveryCanReplayPendingSampleWithoutValidation'] != false) {
      reasons.add('recovery_can_mutate_trip_truth');
    }
    if (summary['rawGpsIncluded'] != false ||
        summary['preciseLocationIncluded'] != false ||
        summary['routeGeometryIncluded'] != false ||
        summary['tokensIncluded'] != false ||
        summary.values.any(_looksSensitive)) {
      reasons.add('summary_contains_sensitive_recovery_material');
    }

    return TripRecoveryResumeSummaryValidation._(
      isRenderable: reasons.isEmpty,
      reasons: List.unmodifiable(reasons),
    );
  }

  final bool isRenderable;
  final List<String> reasons;
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

TripRecoveryResumeStatus? _safeStatus(Object? value) {
  if (value is! String) return null;
  for (final status in TripRecoveryResumeStatus.values) {
    if (status.name == value) return status;
  }
  return null;
}

TripRecoveryResumeReason? _safeReason(Object? value) {
  if (value is! String) return null;
  for (final reason in TripRecoveryResumeReason.values) {
    if (reason.name == value) return reason;
  }
  return null;
}

TripTrackingSessionLifecycleState? _safeLifecycle(Object? value) {
  if (value is! String) return null;
  for (final lifecycle in TripTrackingSessionLifecycleState.values) {
    if (lifecycle.name == value) return lifecycle;
  }
  return null;
}

bool _looksSensitive(Object? value) {
  if (value is! String) return false;
  final clean = value.trim();
  return clean.startsWith('pk.') ||
      clean.startsWith('sk.') ||
      clean.contains(RegExp(r'-?\d{1,3}\.\d{5,}'));
}
