import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_recovery_validation.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  final startedAt = DateTime.utc(2026, 7, 14, 12);
  final updatedAt = DateTime.utc(2026, 7, 14, 12, 5);

  TripTrackingSessionRecord activeSession({
    String id = 'trip_recoverable',
    String vehicleId = 'vehicle_1',
    TripTrackingEngineSnapshot engineSnapshot =
        const TripTrackingEngineSnapshot(
          totalAcceptedMeters: 1609.344,
          walkingReviewSuggested: false,
          vehicleMovementObserved: true,
        ),
    List<TripTrackingAdvisoryEvent> advisories = const [],
  }) => TripTrackingSessionRecord(
    id: id,
    vehicleId: vehicleId,
    startingOdometer: 1000,
    profile: TripTrackingProfile.deliveryVehicle,
    startedAt: startedAt,
    updatedAt: updatedAt,
    engineSnapshot: engineSnapshot,
    advisories: advisories,
  );

  TripTrackingReviewRecord review({
    String id = 'trip_review_recoverable',
    String vehicleId = 'vehicle_1',
    TripTrackingCloudSyncState cloudSyncState =
        TripTrackingCloudSyncState.pending,
    DateTime? cloudSyncedAt,
    String? cloudSyncError,
  }) => TripTrackingReviewRecord(
    id: id,
    vehicleId: vehicleId,
    startingOdometer: 1000,
    estimatedEndingOdometer: 1001,
    profile: TripTrackingProfile.deliveryVehicle,
    startedAt: startedAt,
    finishedAt: updatedAt,
    engineSnapshot: const TripTrackingEngineSnapshot(
      totalAcceptedMeters: 1609.344,
      walkingReviewSuggested: false,
      vehicleMovementObserved: true,
    ),
    cloudSyncState: cloudSyncState,
    cloudSyncedAt: cloudSyncedAt,
    cloudSyncError: cloudSyncError,
  );

  test('recoverable active session exposes a safe recovery summary', () {
    final validation = TripTrackingSessionRecoveryValidation.activeSession(
      activeSession(),
    );
    final safe = validation.toSafeSummary();

    expect(validation.isRecoverable, isTrue);
    expect(
      validation.status,
      TripTrackingSessionRecoveryStatus.recoverableActiveSession,
    );
    expect(validation.recordId, 'trip_recoverable');
    expect(validation.reasons, isEmpty);
    expect(safe['hiveRemainsOperationalSourceOfTruth'], isTrue);
    expect(safe['firestoreCanReviveQuarantinedSession'], isFalse);
    expect(safe['mapboxCanReviveQuarantinedSession'], isFalse);
    expect(safe['canCreateConfirmedMileage'], isFalse);
    expect(safe['officialMileageSource'], 'odometer');
    expect(safe['routeGeometryIncluded'], isFalse);
    expect(safe['tokensIncluded'], isFalse);
  });

  test('foreign advisory prevents active session recovery', () {
    final foreignAdvisory = TripTrackingAdvisoryEvent(
      id: 'advisory_1',
      type: TripTrackingAdvisoryType.probableStop,
      sessionId: 'other_trip',
      vehicleId: 'vehicle_1',
      profile: TripTrackingProfile.deliveryVehicle,
      detectedAt: startedAt.add(const Duration(minutes: 1)),
      evidenceStartedAt: startedAt,
      evidenceEndedAt: startedAt.add(const Duration(minutes: 1)),
      confidence: TripTrackingConfidence.high,
      suggestedAction: 'reviewStop',
    );
    final validation = TripTrackingSessionRecoveryValidation.activeSession(
      activeSession(advisories: [foreignAdvisory]),
    );

    expect(validation.isRecoverable, isFalse);
    expect(validation.status, TripTrackingSessionRecoveryStatus.quarantined);
    expect(validation.reasons, contains('foreign_advisory_in_session'));
  });

  test('walking review recovery requires vehicle movement and evidence', () {
    final validation = TripTrackingSessionRecoveryValidation.activeSession(
      activeSession(
        engineSnapshot: const TripTrackingEngineSnapshot(
          totalAcceptedMeters: 0,
          walkingReviewSuggested: true,
          vehicleMovementObserved: false,
          walkingEvidence: [],
        ),
      ),
    );

    expect(validation.isRecoverable, isFalse);
    expect(validation.reasons, contains('unsafe_engine_snapshot'));
  });

  test('active recovery quarantines future and stale checkpoints', () {
    final recoveredAt = DateTime.utc(2026, 7, 18, 12);
    final futureSession =
        activeSession(
          id: 'trip_future_checkpoint',
          advisories: const [],
        ).copyWithForTest(
          startedAt: recoveredAt.add(const Duration(minutes: 4)),
          updatedAt: recoveredAt.add(const Duration(minutes: 5)),
        );
    final staleSession = activeSession(id: 'trip_stale_checkpoint')
        .copyWithForTest(
          startedAt: recoveredAt.subtract(const Duration(days: 2)),
          updatedAt: recoveredAt.subtract(const Duration(hours: 20)),
        );

    final future = TripTrackingSessionRecoveryValidation.activeSession(
      futureSession,
      recoveredAt: recoveredAt,
    );
    final stale = TripTrackingSessionRecoveryValidation.activeSession(
      staleSession,
      recoveredAt: recoveredAt,
    );

    expect(future.isRecoverable, isFalse);
    expect(future.reasons, contains('session_started_in_future'));
    expect(future.reasons, contains('session_checkpoint_in_future'));
    expect(stale.isRecoverable, isFalse);
    expect(stale.reasons, contains('session_checkpoint_too_stale'));
    expect(
      stale.toSafeSummary()['firestoreCanReviveQuarantinedSession'],
      isFalse,
    );
  });

  test('recoverable review cannot create confirmed mileage by itself', () {
    final validation = TripTrackingSessionRecoveryValidation.review(review());
    final safe = validation.toSafeSummary();

    expect(validation.isRecoverable, isTrue);
    expect(
      validation.status,
      TripTrackingSessionRecoveryStatus.recoverableReview,
    );
    expect(validation.recordId, 'trip_review_recoverable');
    expect(safe['canCreateConfirmedMileage'], isFalse);
    expect(safe['officialMileageSource'], 'odometer');
    expect(safe['cloudFunctionCanReviveQuarantinedSession'], isFalse);
  });

  test('synced review recovery requires a trustworthy sync timestamp', () {
    final validation = TripTrackingSessionRecoveryValidation.review(
      review(cloudSyncState: TripTrackingCloudSyncState.synced),
    );

    expect(validation.isRecoverable, isFalse);
    expect(validation.reasons, contains('synced_without_timestamp'));
  });

  test('sensitive recovery text is quarantined before dashboard rendering', () {
    final validation = TripTrackingSessionRecoveryValidation.review(
      review(
        cloudSyncError:
            'Mapbox failed token=sk.secret at 35.12345,-80.98765 pk.public',
      ),
    );

    expect(validation.isRecoverable, isFalse);
    expect(validation.reasons, contains('sensitive_sync_error'));
    expect(validation.toSafeSummary()['tokensIncluded'], isFalse);
    expect(validation.toSafeSummary()['preciseLocationIncluded'], isFalse);
  });

  test('review recovery rejects impossible future sync timestamp', () {
    final validation = TripTrackingSessionRecoveryValidation.review(
      review(
        cloudSyncState: TripTrackingCloudSyncState.synced,
        cloudSyncedAt: DateTime.utc(2026, 7, 18, 12, 5),
      ),
      recoveredAt: DateTime.utc(2026, 7, 18, 12),
    );

    expect(validation.isRecoverable, isFalse);
    expect(validation.reasons, contains('sync_timestamp_in_future'));
    expect(
      validation.toSafeSummary()['cloudFunctionCanReviveQuarantinedSession'],
      isFalse,
    );
  });
}

extension on TripTrackingSessionRecord {
  TripTrackingSessionRecord copyWithForTest({
    required DateTime startedAt,
    required DateTime updatedAt,
  }) {
    return TripTrackingSessionRecord(
      id: id,
      vehicleId: vehicleId,
      startingOdometer: startingOdometer,
      profile: profile,
      startedAt: startedAt,
      updatedAt: updatedAt,
      engineSnapshot: engineSnapshot,
      advisories: advisories,
      lifecycleState: lifecycleState,
      healthState: healthState,
      hasValidTimeline: hasValidTimeline,
      schemaVersion: schemaVersion,
    );
  }
}
