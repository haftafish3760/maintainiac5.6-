import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_recovery_validation.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  final start = DateTime.utc(2026, 7, 20, 12);

  TripManualEvent boundEvent({
    String id = 'user:pickup_1',
    String sessionId = 'trip_1',
    DateTime? occurredAt,
    DateTime? recordedAt,
  }) => TripManualEvent(
    id: id,
    type: TripManualEventType.pickup,
    occurredAt: occurredAt ?? start,
    userConfirmed: true,
    sessionId: sessionId,
    vehicleId: 'vehicle_1',
    profileId: 'profile_1',
    recordedAt: recordedAt ?? occurredAt ?? start,
    initiatingSource: 'trip_screen',
  );

  TripTrackingSessionRecord activeSession({
    List<TripManualEvent> events = const [],
  }) => TripTrackingSessionRecord(
    id: 'trip_1',
    vehicleId: 'vehicle_1',
    profileId: 'profile_1',
    startingOdometer: 1000,
    profile: TripTrackingProfile.deliveryVehicle,
    startedAt: start,
    updatedAt: start,
    engineSnapshot: const TripTrackingEngineSnapshot(
      totalAcceptedMeters: 0,
      walkingReviewSuggested: false,
    ),
    tripEvents: events,
  );

  test('driver event is durable and duplicate command is idempotent', () async {
    final store = TripTrackingSessionStore.memory();
    var now = start;
    final controller = TripTrackingController(
      sessionStore: store,
      odometer: GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      ),
      clockNow: () => now,
    );
    addTearDown(controller.dispose);
    expect(
      await controller.start(
        tripId: 'trip_events',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.deliveryVehicle,
        profileId: 'profile_1',
        startedAt: start,
      ),
      isTrue,
    );
    now = start.add(const Duration(minutes: 10));

    for (var attempt = 0; attempt < 2; attempt += 1) {
      expect(
        await controller.recordUserTripEvent(
          commandId: 'pickup_command_1',
          type: TripManualEventType.pickup,
          initiatingSource: 'trip_screen',
          occurredAt: now,
          note: 'Order 42',
        ),
        isTrue,
      );
    }

    final restored = TripTrackingSessionRecord.fromMap(
      store.activeSession!.toMap(),
    );
    expect(restored.tripEvents, hasLength(1));
    expect(restored.tripEvents.single.type, TripManualEventType.pickup);
    expect(restored.tripEvents.single.note, 'Order 42');
    expect(restored.tripEvents.single.sessionId, 'trip_events');
    expect(restored.tripEvents.single.profileId, 'profile_1');

    now = start.add(const Duration(hours: 1));
    final review = await controller.finishForReview(finishedAt: now);
    expect(review?.tripEvents, hasLength(1));
    expect(store.pendingReviews.single.tripEvents, hasLength(1));
  });

  test(
    'GPS and remote sources cannot create driver-confirmed events',
    () async {
      final store = TripTrackingSessionStore.memory();
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
        clockNow: () => start,
      );
      addTearDown(controller.dispose);
      await controller.start(
        tripId: 'trip_event_sources',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.deliveryVehicle,
        profileId: 'profile_1',
        startedAt: start,
      );

      for (final source in const ['gps', 'mapbox', 'firebase', 'remote']) {
        expect(
          await controller.recordUserTripEvent(
            commandId: 'blocked_$source',
            type: TripManualEventType.stop,
            initiatingSource: source,
          ),
          isFalse,
        );
      }
      expect(store.activeSession!.tripEvents, isEmpty);
    },
  );

  test('tampered event authority is rejected during recovery', () {
    final event = boundEvent().toMap()..['remoteCreated'] = true;
    final session = activeSession().toMap()..['tripEvents'] = [event];
    final restored = TripTrackingSessionRecord.fromMap(session);

    expect(restored.tripEvents, isEmpty);
    expect(restored.hasValidTimeline, isTrue);
  });

  test('foreign direct event quarantines active-session recovery', () {
    final validation = TripTrackingSessionRecoveryValidation.activeSession(
      activeSession(events: [boundEvent(sessionId: 'different_trip')]),
    );

    expect(validation.isRecoverable, isFalse);
    expect(validation.reasons, contains('foreign_trip_event_in_session'));
  });

  test(
    'future event cannot be committed beyond the active checkpoint',
    () async {
      final store = TripTrackingSessionStore.memory();
      final futureEvent = boundEvent(
        occurredAt: start.add(const Duration(minutes: 1)),
      );
      final futureRecording = boundEvent(
        id: 'future_recording',
        recordedAt: start.add(const Duration(minutes: 1)),
      );

      await expectLater(
        store.save(activeSession(events: [futureEvent])),
        throwsArgumentError,
      );
      await expectLater(
        store.save(activeSession(events: [futureRecording])),
        throwsArgumentError,
      );
      expect(store.activeSession, isNull);
    },
  );

  test(
    'duplicate event identities are rejected instead of duplicated',
    () async {
      final duplicate = boundEvent();
      final session = activeSession(events: [duplicate, duplicate]);
      final store = TripTrackingSessionStore.memory();

      await expectLater(store.save(session), throwsArgumentError);
      final validation = TripTrackingSessionRecoveryValidation.activeSession(
        session,
      );
      expect(validation.isRecoverable, isFalse);
      expect(validation.reasons, contains('foreign_trip_event_in_session'));
    },
  );

  test(
    'event limit refuses a write without dropping existing events',
    () async {
      final events = List.generate(
        TripManualEvent.maximumPerTrip + 1,
        (index) => boundEvent(id: 'user:event_$index'),
        growable: false,
      );
      final store = TripTrackingSessionStore.memory();

      await expectLater(
        store.save(activeSession(events: events)),
        throwsArgumentError,
      );
      expect(store.activeSession, isNull);
    },
  );

  test(
    'completion draft binds legacy manual event to review provenance',
    () async {
      final store = TripTrackingSessionStore.memory();
      final finish = start.add(const Duration(hours: 1));
      await store.saveReview(
        TripTrackingReviewRecord(
          id: 'review_event',
          vehicleId: 'vehicle_1',
          profileId: 'profile_1',
          startingOdometer: 1000,
          estimatedEndingOdometer: 1005,
          profile: TripTrackingProfile.deliveryVehicle,
          startedAt: start,
          finishedAt: finish,
          engineSnapshot: const TripTrackingEngineSnapshot(
            totalAcceptedMeters: 8046.72,
            walkingReviewSuggested: false,
          ),
        ),
      );
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
        clockNow: () => finish.add(const Duration(minutes: 5)),
      );
      addTearDown(controller.dispose);

      expect(
        await controller.saveCompletionDraft(
          tripId: 'review_event',
          tripEvents: [
            TripManualEvent(
              id: 'manual_job_site',
              type: TripManualEventType.jobSite,
              occurredAt: start.add(const Duration(minutes: 20)),
              userConfirmed: true,
            ),
          ],
        ),
        isTrue,
      );

      final saved = store.reviewForTrip('review_event')!.tripEvents.single;
      expect(saved.hasBoundTripContext, isTrue);
      expect(saved.sessionId, 'review_event');
      expect(saved.initiatingSource, 'recovery_review');
    },
  );

  test('canonical event taxonomy preserves both branch capabilities', () {
    expect(
      TripManualEventType.values,
      containsAll([
        TripManualEventType.stop,
        TripManualEventType.workStop,
        TripManualEventType.fuelStop,
        TripManualEventType.customerWait,
        TripManualEventType.jobSite,
        TripManualEventType.breakTime,
        TripManualEventType.personalInterruption,
        TripManualEventType.note,
        TripManualEventType.other,
      ]),
    );
  });
}
