import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  for (final testCase
      in <({TripTrackingSessionLifecycleState state, String expectedStatus})>[
        (
          state: TripTrackingSessionLifecycleState.cancelled,
          expectedStatus: 'cancelled_review_invalid',
        ),
        (
          state: TripTrackingSessionLifecycleState.stopping,
          expectedStatus: 'completion_review_invalid',
        ),
      ]) {
    for (final mismatch in [
      'odometer',
      'engine snapshot',
      'GPS estimate',
      'finish time',
      'tracking profile',
      'recovery audit',
      'advisory detail',
      'manual event detail',
    ]) {
      test('${testCase.state.name} recovery preserves a mismatched $mismatch '
          'review and checkpoint for repair', () async {
        final store = TripTrackingSessionStore.memory();
        final startedAt = DateTime.utc(2026, 7, 23, 9);
        final finishedAt = startedAt.add(const Duration(minutes: 20));
        final tripId =
            'trip_${testCase.state.name}_${mismatch.replaceAll(' ', '_')}';
        final advisory = TripTrackingAdvisoryEvent(
          id: '$tripId:advisory',
          type: TripTrackingAdvisoryType.probableStop,
          sessionId: tripId,
          vehicleId: 'vehicle_1',
          profile: TripTrackingProfile.roadVehicle,
          detectedAt: startedAt.add(const Duration(minutes: 10)),
          evidenceStartedAt: startedAt.add(const Duration(minutes: 8)),
          evidenceEndedAt: startedAt.add(const Duration(minutes: 10)),
          confidence: TripTrackingConfidence.high,
          suggestedAction: 'review_stop',
        );
        final manualEvent = TripManualEvent(
          id: '$tripId:event',
          type: TripManualEventType.stop,
          occurredAt: startedAt.add(const Duration(minutes: 12)),
          userConfirmed: true,
          note: 'original_note',
          sessionId: tripId,
          vehicleId: 'vehicle_1',
          profileId: 'work_profile_1',
          recordedAt: startedAt.add(const Duration(minutes: 12)),
          initiatingSource: 'trip_screen',
        );
        final session = TripTrackingSessionRecord(
          id: tripId,
          vehicleId: 'vehicle_1',
          startingOdometer: 5000,
          profile: TripTrackingProfile.roadVehicle,
          profileId: 'work_profile_1',
          startedAt: startedAt,
          updatedAt: finishedAt,
          lifecycleState: testCase.state,
          engineSnapshot: const TripTrackingEngineSnapshot(
            totalAcceptedMeters: 3200,
            walkingReviewSuggested: false,
          ),
          advisories: mismatch == 'advisory detail' ? [advisory] : const [],
          tripEvents: mismatch == 'manual event detail'
              ? [manualEvent]
              : const [],
          revision: 2,
        );
        await store.save(session);
        final mismatchedReview = TripTrackingReviewRecord(
          id: session.id,
          vehicleId: session.vehicleId,
          startingOdometer: mismatch == 'odometer' ? 4999 : 5000,
          estimatedEndingOdometer: mismatch == 'GPS estimate' ? 5001 : 5002,
          profile: mismatch == 'tracking profile'
              ? TripTrackingProfile.deliveryVehicle
              : session.profile,
          profileId: session.effectiveProfileId,
          startedAt: startedAt,
          finishedAt: mismatch == 'finish time'
              ? finishedAt.add(const Duration(seconds: 1))
              : finishedAt,
          engineSnapshot: mismatch == 'engine snapshot'
              ? const TripTrackingEngineSnapshot(
                  totalAcceptedMeters: 3199,
                  walkingReviewSuggested: false,
                )
              : session.engineSnapshot,
          advisories: mismatch == 'advisory detail'
              ? [advisory.copyWith(confidence: TripTrackingConfidence.low)]
              : session.advisories,
          tripEvents: mismatch == 'manual event detail'
              ? [
                  TripManualEvent(
                    id: manualEvent.id,
                    type: manualEvent.type,
                    occurredAt: manualEvent.occurredAt,
                    userConfirmed: true,
                    note: 'changed_note',
                    sessionId: manualEvent.sessionId,
                    vehicleId: manualEvent.vehicleId,
                    profileId: manualEvent.profileId,
                    recordedAt: manualEvent.recordedAt,
                    initiatingSource: manualEvent.initiatingSource,
                  ),
                ]
              : session.tripEvents,
          transitionAudits: mismatch == 'recovery audit'
              ? [
                  TripTrackingSessionTransitionAudit(
                    id: '${session.id}:foreign_audit',
                    sessionId: session.id,
                    vehicleId: session.vehicleId,
                    profile: session.profile,
                    profileId: session.effectiveProfileId,
                    fromState: TripTrackingSessionLifecycleState.active,
                    toState: testCase.state,
                    eventTimestamp: finishedAt,
                    sequenceNumber: 1,
                    reasonCode: 'foreign_recovery_audit',
                    initiatingSource: 'recovery',
                    revision: session.revision,
                    permissionState: 'permission_granted',
                    confidenceState: 'healthy',
                    trackingQualityMode: 'high_quality',
                  ),
                ]
              : session.transitionAudits,
          revision: session.revision,
        );
        await store.saveReview(mismatchedReview);
        final odometer = GlobalOdometerController(
          vehicleId: session.vehicleId,
          initialReading: session.startingOdometer,
        );
        final controller = TripTrackingController(
          sessionStore: store,
          odometer: odometer,
        );
        addTearDown(controller.dispose);

        expect(await controller.restore(), isFalse);

        expect(controller.platformStatus, testCase.expectedStatus);
        expect(store.activeSession?.id, session.id);
        final preserved = store.recoveryReviewForTrip(session.id);
        expect(preserved?.startingOdometer, mismatchedReview.startingOdometer);
        expect(
          preserved?.engineSnapshot.totalAcceptedMeters,
          mismatchedReview.engineSnapshot.totalAcceptedMeters,
        );
        expect(odometer.confirmedReading, session.startingOdometer);
      });
    }
  }

  for (final testCase
      in <({TripTrackingSessionLifecycleState state, String failureStatus})>[
        (
          state: TripTrackingSessionLifecycleState.cancelled,
          failureStatus: 'cancelled_review_recovery_failed',
        ),
        (
          state: TripTrackingSessionLifecycleState.stopping,
          failureStatus: 'completion_review_recovery_failed',
        ),
      ]) {
    for (final failure in ['review write', 'checkpoint cleanup']) {
      test(
        '${testCase.state.name} $failure failure preserves terminal evidence',
        () async {
          final TripTrackingSessionStore store = failure == 'review write'
              ? _FailingTerminalReviewSaveStore()
              : _FailingTerminalCleanupStore();
          final startedAt = DateTime.utc(2026, 7, 23, 10);
          final session = TripTrackingSessionRecord(
            id: 'trip_${testCase.state.name}_${failure.replaceAll(' ', '_')}',
            vehicleId: 'vehicle_1',
            startingOdometer: 7000,
            profile: TripTrackingProfile.roadVehicle,
            startedAt: startedAt,
            updatedAt: startedAt.add(const Duration(minutes: 15)),
            lifecycleState: testCase.state,
            engineSnapshot: const TripTrackingEngineSnapshot(
              totalAcceptedMeters: 1609.344,
              walkingReviewSuggested: false,
            ),
          );
          await store.save(session);
          final controller = TripTrackingController(
            sessionStore: store,
            odometer: GlobalOdometerController(
              vehicleId: session.vehicleId,
              initialReading: session.startingOdometer,
            ),
          );
          addTearDown(controller.dispose);

          expect(await controller.restore(), isFalse);

          expect(controller.platformStatus, testCase.failureStatus);
          expect(store.activeSession?.id, session.id);
          expect(
            store.recoveryReviewForTrip(session.id),
            failure == 'review write' ? isNull : isNotNull,
          );
          if (failure == 'checkpoint cleanup') {
            final preservedRevision = store
                .recoveryReviewForTrip(session.id)!
                .revision;
            expect(await controller.restore(), isFalse);
            expect(controller.platformStatus, testCase.failureStatus);
            expect(store.activeSession?.id, session.id);
            expect(
              store.recoveryReviewForTrip(session.id)?.revision,
              preservedRevision,
            );
          }
        },
      );
    }
  }

  for (final testCase
      in <({TripTrackingSessionLifecycleState state, String invalidStatus})>[
        (
          state: TripTrackingSessionLifecycleState.cancelled,
          invalidStatus: 'cancelled_session_invalid',
        ),
        (
          state: TripTrackingSessionLifecycleState.stopping,
          invalidStatus: 'completion_session_invalid',
        ),
      ]) {
    test(
      '${testCase.state.name} malformed terminal evidence fails closed',
      () async {
        final startedAt = DateTime.utc(2026, 7, 23, 11);
        final malformed = TripTrackingSessionRecord(
          id: 'trip_${testCase.state.name}_malformed',
          vehicleId: 'vehicle_1',
          startingOdometer: 8000,
          profile: TripTrackingProfile.roadVehicle,
          startedAt: startedAt,
          updatedAt: startedAt,
          lifecycleState: testCase.state,
          engineSnapshot: const TripTrackingEngineSnapshot(
            totalAcceptedMeters: 100,
            walkingReviewSuggested: false,
          ),
          hasValidTimeline: false,
        );
        final store = _InjectedRecoverySessionStore(malformed);
        final controller = TripTrackingController(
          sessionStore: store,
          odometer: GlobalOdometerController(
            vehicleId: malformed.vehicleId,
            initialReading: malformed.startingOdometer,
          ),
        );
        addTearDown(controller.dispose);

        expect(await controller.restore(), isFalse);

        expect(controller.platformStatus, testCase.invalidStatus);
        expect(store.injectedSession, same(malformed));
        expect(store.recoveryReviewForTrip(malformed.id), isNull);
      },
    );
  }
}

class _FailingTerminalReviewSaveStore extends TripTrackingSessionStore {
  _FailingTerminalReviewSaveStore() : super.memory();

  @override
  Future<void> saveReview(TripTrackingReviewRecord review) async {
    throw StateError('terminal review write failed');
  }
}

class _FailingTerminalCleanupStore extends TripTrackingSessionStore {
  _FailingTerminalCleanupStore() : super.memory();

  @override
  Future<void> clear() async {
    throw StateError('terminal checkpoint cleanup failed');
  }
}

class _InjectedRecoverySessionStore extends TripTrackingSessionStore {
  _InjectedRecoverySessionStore(this.injectedSession) : super.memory();

  final TripTrackingSessionRecord injectedSession;

  @override
  Future<TripTrackingSessionRecord?> recoverActive({
    DateTime? recordedAtUtc,
  }) async => injectedSession;
}
