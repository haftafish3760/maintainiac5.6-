import 'trip_tracking_models.dart';
import 'trip_tracking_session_store.dart';

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
    Duration maximumCheckpointAge = const Duration(hours: 18),
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
      if (updated.isBefore(
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
    session.advisories.any(
      (event) =>
          event.sessionId != session.id ||
          event.vehicleId != session.vehicleId ||
          event.profile != session.profile ||
          event.detectedAt.isBefore(session.startedAt) ||
          event.detectedAt.isAfter(
            session.startedAt.add(const Duration(days: 30)),
          ),
    );

bool _hasSensitiveAdvisoryText(
  Iterable<TripTrackingAdvisoryEvent> advisories,
) => advisories.any(
  (event) =>
      _containsSensitiveText(event.id) ||
      _containsSensitiveText(event.suggestedAction) ||
      _containsSensitiveText(event.tripLogReference),
);

bool _hasForeignTripEvent(TripTrackingSessionRecord session) =>
    _hasDuplicateTripEventId(session.tripEvents) ||
    session.tripEvents.any(
      (event) => !event.belongsTo(
        expectedSessionId: session.id,
        expectedVehicleId: session.vehicleId,
        expectedProfileId: session.effectiveProfileId,
        tripStartedAt: session.startedAt,
      ),
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
