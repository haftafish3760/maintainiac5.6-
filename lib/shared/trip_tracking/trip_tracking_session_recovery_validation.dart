import 'trip_tracking_models.dart';
import 'trip_tracking_session_store.dart';
import 'trip_tracking_state_machine.dart';

enum TripTrackingSessionRecoveryStatus {
  recoverableActiveSession,
  recoverableReview,
  quarantined,
}

class TripTrackingSessionRecoveryValidation {
  const TripTrackingSessionRecoveryValidation._({
    required this.status,
    required this.recordId,
    required this.vehicleId,
    required this.reasons,
  });

  factory TripTrackingSessionRecoveryValidation.activeSession(
    TripTrackingSessionRecord session, {
    DateTime? recoveredAt,
    Duration? maximumCheckpointAge = const Duration(hours: 18),
    Duration maximumFutureSkew = const Duration(minutes: 2),
  }) {
    final reasons = <String>[];
    if (!_safeIdentifier(session.id)) reasons.add('unsafe_session_id');
    if (!_safeIdentifier(session.vehicleId)) reasons.add('unsafe_vehicle_id');
    if (!session.hasValidTimeline) reasons.add('invalid_session_timeline');
    if (session.updatedAt.isBefore(session.startedAt)) {
      reasons.add('updated_before_started');
    }
    final recoveryClock = recoveredAt;
    if (recoveryClock != null) {
      final recovered = recoveryClock.toUtc();
      final started = session.startedAt.toUtc();
      final updated = session.updatedAt.toUtc();
      final futureSkew = _safeFutureSkew(maximumFutureSkew);
      if (started.isAfter(recovered.add(futureSkew))) {
        reasons.add('session_started_in_future');
      }
      if (updated.isAfter(recovered.add(futureSkew))) {
        reasons.add('session_checkpoint_in_future');
      }
      if (maximumCheckpointAge != null &&
          updated.isBefore(
            recovered.subtract(_safeCheckpointAge(maximumCheckpointAge)),
          )) {
        reasons.add('session_checkpoint_too_stale');
      }
    }
    if (session.startingOdometer < 0) {
      reasons.add('negative_starting_odometer');
    }
    if (!_supportedSessionSchema(session.schemaVersion)) {
      reasons.add('unsupported_session_schema');
    }
    if (!_safeEngineSnapshot(session.engineSnapshot)) {
      reasons.add('unsafe_engine_snapshot');
    }
    if (_hasForeignAdvisory(session)) {
      reasons.add('foreign_advisory_in_session');
    }
    if (_hasForeignTripEvent(session)) {
      reasons.add('foreign_trip_event_in_session');
    }
    if (_hasForeignTransitionAudit(
      session.transitionAudits,
      sessionId: session.id,
      vehicleId: session.vehicleId,
      profile: session.profile,
      profileId: session.effectiveProfileId,
      startedAt: session.startedAt,
      latestAt: session.updatedAt,
    )) {
      reasons.add('foreign_transition_audit_in_session');
    }
    if (_hasUnsafeRecoveryEvidence(
      permissionHistory: session.permissionHistory,
      batteryStateSummary: session.batteryStateSummary,
      latestAt: session.updatedAt,
    )) {
      reasons.add('invalid_recovery_evidence_in_session');
    }
    if (_hasSensitiveAdvisoryText(session.advisories)) {
      reasons.add('sensitive_advisory_text');
    }
    return TripTrackingSessionRecoveryValidation._(
      status: reasons.isEmpty
          ? TripTrackingSessionRecoveryStatus.recoverableActiveSession
          : TripTrackingSessionRecoveryStatus.quarantined,
      recordId: reasons.isEmpty ? session.id : null,
      vehicleId: reasons.isEmpty ? session.vehicleId : null,
      reasons: List.unmodifiable(reasons),
    );
  }

  factory TripTrackingSessionRecoveryValidation.review(
    TripTrackingReviewRecord review, {
    DateTime? recoveredAt,
    Duration maximumFutureSkew = const Duration(minutes: 2),
  }) {
    final reasons = <String>[];
    if (!_safeIdentifier(review.id)) reasons.add('unsafe_review_id');
    if (!_safeIdentifier(review.vehicleId)) reasons.add('unsafe_vehicle_id');
    if (!review.hasValidTimeline) reasons.add('invalid_review_timeline');
    if (review.finishedAt.isBefore(review.startedAt)) {
      reasons.add('finished_before_started');
    }
    if (review.startingOdometer < 0) reasons.add('negative_starting_odometer');
    if (review.estimatedEndingOdometer < review.startingOdometer) {
      reasons.add('ending_below_starting_odometer');
    }
    if (!_supportedReviewSchema(review.schemaVersion)) {
      reasons.add('unsupported_review_schema');
    }
    if (!_safeEngineSnapshot(review.engineSnapshot)) {
      reasons.add('unsafe_engine_snapshot');
    }
    if (_hasForeignReviewAdvisory(review)) {
      reasons.add('foreign_advisory_in_review');
    }
    if (_hasSensitiveAdvisoryText(review.advisories)) {
      reasons.add('sensitive_advisory_text');
    }
    if (review.cloudSyncState == TripTrackingCloudSyncState.synced &&
        review.cloudSyncedAt == null) {
      reasons.add('synced_without_timestamp');
    }
    final recoveryClock = recoveredAt;
    final syncedAt = review.cloudSyncedAt;
    if (recoveryClock != null && syncedAt != null) {
      final recovered = recoveryClock.toUtc();
      if (syncedAt.toUtc().isAfter(
        recovered.add(_safeFutureSkew(maximumFutureSkew)),
      )) {
        reasons.add('sync_timestamp_in_future');
      }
    }
    if (review.cloudBackupScope == TripTrackingCloudBackupScope.organization &&
        !_safeIdentifier(review.cloudOrganizationId)) {
      reasons.add('organization_scope_missing_safe_org_id');
    }
    if ((review.confirmedEndingOdometer != null ||
            review.odometerConfirmedAt != null) &&
        !review.isOdometerConfirmed) {
      reasons.add('invalid_confirmed_odometer');
    }
    if (_containsSensitiveText(review.cloudSyncError)) {
      reasons.add('sensitive_sync_error');
    }
    if (_hasForeignReviewTripEvent(review)) {
      reasons.add('foreign_trip_event_in_review');
    }
    if (_hasUnsafeManualAdjustment(
      review,
      recoveredAt: recoveryClock,
      maximumFutureSkew: maximumFutureSkew,
    )) {
      reasons.add('invalid_manual_adjustment_in_review');
    }
    if (_hasForeignTransitionAudit(
      review.transitionAudits,
      sessionId: review.id,
      vehicleId: review.vehicleId,
      profile: review.profile,
      profileId: review.effectiveProfileId,
      startedAt: review.startedAt,
      latestAt: review.finishedAt,
    )) {
      reasons.add('foreign_transition_audit_in_review');
    }
    if (_hasUnsafeRecoveryEvidence(
      permissionHistory: review.permissionHistory,
      batteryStateSummary: review.batteryStateSummary,
      latestAt: review.finishedAt,
    )) {
      reasons.add('invalid_recovery_evidence_in_review');
    }
    return TripTrackingSessionRecoveryValidation._(
      status: reasons.isEmpty
          ? TripTrackingSessionRecoveryStatus.recoverableReview
          : TripTrackingSessionRecoveryStatus.quarantined,
      recordId: reasons.isEmpty ? review.id : null,
      vehicleId: reasons.isEmpty ? review.vehicleId : null,
      reasons: List.unmodifiable(reasons),
    );
  }

  final TripTrackingSessionRecoveryStatus status;
  final String? recordId;
  final String? vehicleId;
  final List<String> reasons;

  bool get isRecoverable =>
      status == TripTrackingSessionRecoveryStatus.recoverableActiveSession ||
      status == TripTrackingSessionRecoveryStatus.recoverableReview;

  Map<String, Object?> toSafeSummary() => {
    'schemaVersion': 1,
    'status': status.name,
    'recordId': recordId,
    'vehicleId': vehicleId,
    'isRecoverable': isRecoverable,
    'reasons': reasons,
    'localRecordRequired': true,
    'hiveRemainsOperationalSourceOfTruth': true,
    'firestoreCanReviveQuarantinedSession': false,
    'mapboxCanReviveQuarantinedSession': false,
    'cloudFunctionCanReviveQuarantinedSession': false,
    'recoveryRequiresLocalCheckpointFreshness': true,
    'recoveryRequiresValidatedEngineSnapshot': true,
    'canCreateConfirmedMileage': false,
    'recoveryCanCreateOfficialStop': false,
    'recoveryCanEndTripAutomatically': false,
    'recoveryCanReplayPendingSampleWithoutValidation': false,
    'officialMileageSource': 'odometer',
    'odometerIsGlobalTruth': true,
    'recoveryCanCreateCalibration': false,
    'recoveryCanApplyCalibration': false,
    'calibrationRequiresTrustedGpsWindow': true,
    'poorGpsDaysExcludedFromCalibration': true,
    'rawGpsIncluded': false,
    'preciseLocationIncluded': false,
    'routeGeometryIncluded': false,
    'tokensIncluded': false,
  };
}

bool _safeEngineSnapshot(TripTrackingEngineSnapshot snapshot) =>
    snapshot.totalAcceptedMeters.isFinite &&
    snapshot.totalAcceptedMeters >= 0 &&
    snapshot.schemaVersion == 1 &&
    snapshot.algorithmVersion == 'gps-v1' &&
    (!snapshot.walkingReviewSuggested ||
        (snapshot.vehicleMovementObserved &&
            snapshot.walkingEvidence.isNotEmpty));

bool _hasForeignAdvisory(TripTrackingSessionRecord session) =>
    _hasDuplicateAdvisoryId(session.advisories) ||
    session.advisories.any(
      (event) =>
          !_safeIdentifier(event.id) ||
          event.sessionId != session.id ||
          event.vehicleId != session.vehicleId ||
          event.profile != session.profile ||
          event.detectedAt.isBefore(session.startedAt) ||
          event.detectedAt.isAfter(session.updatedAt) ||
          event.evidenceStartedAt.isBefore(session.startedAt) ||
          event.evidenceStartedAt.isAfter(session.updatedAt) ||
          event.evidenceEndedAt.isBefore(event.evidenceStartedAt) ||
          event.evidenceEndedAt.isAfter(session.updatedAt),
    );

bool _hasDuplicateAdvisoryId(Iterable<TripTrackingAdvisoryEvent> advisories) {
  final ids = <String>{};
  for (final advisory in advisories) {
    if (!ids.add(advisory.id)) return true;
  }
  return false;
}

bool _hasSensitiveAdvisoryText(
  Iterable<TripTrackingAdvisoryEvent> advisories,
) => advisories.any(
  (event) =>
      _containsSensitiveText(event.id) ||
      _containsSensitiveText(event.suggestedAction) ||
      _containsSensitiveText(event.tripLogReference),
);

bool _hasForeignReviewAdvisory(TripTrackingReviewRecord review) =>
    _hasDuplicateAdvisoryId(review.advisories) ||
    review.advisories.any(
      (event) =>
          !_safeIdentifier(event.id) ||
          event.sessionId != review.id ||
          event.vehicleId != review.vehicleId ||
          event.profile != review.profile ||
          event.detectedAt.isBefore(review.startedAt) ||
          event.detectedAt.isAfter(review.finishedAt) ||
          event.evidenceStartedAt.isBefore(review.startedAt) ||
          event.evidenceStartedAt.isAfter(review.finishedAt) ||
          event.evidenceEndedAt.isBefore(event.evidenceStartedAt) ||
          event.evidenceEndedAt.isAfter(review.finishedAt),
    );

bool _hasForeignTripEvent(TripTrackingSessionRecord session) =>
    _hasDuplicateTripEventId(session.tripEvents) ||
    session.tripEvents.any(
      (event) =>
          !event.belongsTo(
            expectedSessionId: session.id,
            expectedVehicleId: session.vehicleId,
            expectedProfileId: session.effectiveProfileId,
            tripStartedAt: session.startedAt,
            tripFinishedAt: session.updatedAt,
          ) ||
          event.recordedAt!.isAfter(session.updatedAt),
    );

bool _hasForeignReviewTripEvent(TripTrackingReviewRecord review) =>
    _hasDuplicateTripEventId(review.tripEvents) ||
    review.tripEvents.any(
      (event) =>
          !event.isValid ||
          event.occurredAt.isBefore(review.startedAt) ||
          event.occurredAt.isAfter(review.finishedAt) ||
          (event.hasAnyTripContext &&
              !event.belongsTo(
                expectedSessionId: review.id,
                expectedVehicleId: review.vehicleId,
                expectedProfileId: review.effectiveProfileId,
                tripStartedAt: review.startedAt,
                tripFinishedAt: review.finishedAt,
              )),
    );

bool _hasDuplicateTripEventId(Iterable<TripManualEvent> events) {
  final ids = <String>{};
  for (final event in events) {
    if (!ids.add(event.id)) return true;
  }
  return false;
}

bool _hasUnsafeManualAdjustment(
  TripTrackingReviewRecord review, {
  required DateTime? recoveredAt,
  required Duration maximumFutureSkew,
}) {
  final ids = <String>{};
  final latestAllowed = recoveredAt?.toUtc().add(
    _safeFutureSkew(maximumFutureSkew),
  );
  return review.manualAdjustments.any(
    (adjustment) =>
        !adjustment.isValid ||
        !ids.add(adjustment.id) ||
        (adjustment.note != null &&
            (adjustment.note!.length > 240 ||
                _containsSensitiveText(adjustment.note))) ||
        (review.odometerConfirmedAt != null &&
            adjustment.createdAt.isAfter(review.odometerConfirmedAt!)) ||
        (latestAllowed != null &&
            adjustment.createdAt.toUtc().isAfter(latestAllowed)),
  );
}

bool _hasForeignTransitionAudit(
  Iterable<TripTrackingSessionTransitionAudit> audits, {
  required String sessionId,
  required String vehicleId,
  required TripTrackingProfile profile,
  required String profileId,
  required DateTime startedAt,
  required DateTime latestAt,
}) {
  final auditList = audits.toList(growable: false);
  final ids = <String>{};
  final sequences = <int>{};
  TripTrackingSessionTransitionAudit? previous;
  for (final event in auditList) {
    if (event.schemaVersion != 1 ||
        !_safeIdentifier(event.id) ||
        !ids.add(event.id) ||
        !sequences.add(event.sequenceNumber) ||
        event.sessionId != sessionId ||
        event.vehicleId != vehicleId ||
        event.profile != profile ||
        event.profileId != profileId ||
        event.sequenceNumber < 1 ||
        event.revision < 1 ||
        event.eventTimestamp.isBefore(startedAt) ||
        event.eventTimestamp.isAfter(latestAt) ||
        !_transitionAcceptanceMatchesStateMachines(event)) {
      return true;
    }
    final prior = previous;
    if (prior != null &&
        (event.sequenceNumber <= prior.sequenceNumber ||
            event.revision <= prior.revision ||
            event.fromState !=
                (prior.accepted ? prior.toState : prior.fromState) ||
            event.effectiveFromContractState !=
                (prior.accepted
                    ? prior.effectiveToContractState
                    : prior.effectiveFromContractState))) {
      return true;
    }
    previous = event;
  }
  return false;
}

bool _transitionAcceptanceMatchesStateMachines(
  TripTrackingSessionTransitionAudit event,
) {
  final runtimeAllowed =
      event.fromState == event.toState ||
      TripTrackingSessionStateMachine.canTransition(
        event.fromState,
        event.toState,
      );
  final fromContract = event.effectiveFromContractState;
  final toContract = event.effectiveToContractState;
  final contractAllowed =
      fromContract == toContract ||
      TripTrackingSessionContractStateMachine.canTransition(
        fromContract,
        toContract,
      );
  return event.accepted == (runtimeAllowed && contractAllowed);
}

bool _hasUnsafeRecoveryEvidence({
  required Iterable<TripTrackingPermissionEvidence> permissionHistory,
  required TripTrackingBatteryStateSummary? batteryStateSummary,
  required DateTime latestAt,
}) {
  if (permissionHistory.any(
    (evidence) =>
        evidence.observedAt.isAfter(latestAt) ||
        evidence.state.isEmpty ||
        evidence.state.length > 32 ||
        evidence.source.isEmpty ||
        evidence.source.length > 48 ||
        _containsSensitiveText(evidence.state) ||
        _containsSensitiveText(evidence.source),
  )) {
    return true;
  }
  final battery = batteryStateSummary;
  return battery != null &&
      (battery.observedAt.isAfter(latestAt) ||
          (battery.batteryPercent != null &&
              (battery.batteryPercent! < 0 || battery.batteryPercent! > 100)) ||
          battery.reasonCode.isEmpty ||
          battery.reasonCode.length > 80 ||
          _containsSensitiveText(battery.reasonCode));
}

bool _supportedSessionSchema(int value) => value == 1;

bool _supportedReviewSchema(int value) => value == 1 || value == 2;

Duration _safeCheckpointAge(Duration value) {
  if (value <= Duration.zero) return const Duration(hours: 1);
  return value > const Duration(days: 30) ? const Duration(days: 30) : value;
}

Duration _safeFutureSkew(Duration value) {
  if (value <= Duration.zero) return Duration.zero;
  return value > const Duration(minutes: 10)
      ? const Duration(minutes: 10)
      : value;
}

bool _safeIdentifier(Object? value) {
  if (value is! String) return false;
  return value.trim() == value &&
      value.isNotEmpty &&
      value.length <= 160 &&
      RegExp(r'^[A-Za-z0-9._:-]+$').hasMatch(value);
}

bool _containsSensitiveText(String? value) {
  if (value == null) return false;
  final lower = value.toLowerCase();
  return lower.contains('token=') ||
      lower.contains('pk.') ||
      lower.contains('sk.') ||
      lower.contains('lat=') ||
      lower.contains('lng=') ||
      RegExp(r'-?\d{1,2}\.\d{4,}\s*,\s*-?\d{1,3}\.\d{4,}').hasMatch(value);
}
