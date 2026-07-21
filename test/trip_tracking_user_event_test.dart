import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/odometer/odometer_validation.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_user_event.dart';

void main() {
  final start = DateTime.utc(2026, 7, 20, 12);

  test(
    'driver pickup event is durable and duplicate command is idempotent',
    () async {
      final store = TripTrackingSessionStore.memory();
      var now = start;
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
          validationPolicy: const OdometerValidationPolicy(),
        ),
        activeProfileId: () => 'profile_1',
        clockNow: () => now,
      );
      addTearDown(controller.dispose);
      expect(
        await controller.start(
          tripId: 'trip_events',
          vehicleId: 'vehicle_1',
          profile: TripTrackingProfile.deliveryVehicle,
          startedAt: start,
        ),
        isTrue,
      );
      await controller.ingest(
        TripLocationSample(
          latitude: 35,
          longitude: -80,
          recordedAt: start,
          horizontalAccuracyMeters: 5,
        ),
      );
      now = start.add(const Duration(minutes: 10));

      for (var attempt = 0; attempt < 2; attempt += 1) {
        expect(
          await controller.recordUserTripEvent(
            commandId: 'pickup_command_1',
            kind: TripTrackingUserEventKind.pickup,
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
      expect(restored.userEvents, hasLength(1));
      expect(restored.userEvents.single.kind, TripTrackingUserEventKind.pickup);
      expect(restored.userEvents.single.note, 'Order 42');
      expect(restored.schemaVersion, 5);
    },
  );

  test(
    'GPS and remote sources cannot create driver-confirmed events',
    () async {
      final store = TripTrackingSessionStore.memory();
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
          validationPolicy: const OdometerValidationPolicy(),
        ),
        activeProfileId: () => 'profile_1',
        clockNow: () => start,
      );
      addTearDown(controller.dispose);
      await controller.start(
        tripId: 'trip_event_sources',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.deliveryVehicle,
        startedAt: start,
      );
      await controller.ingest(
        TripLocationSample(
          latitude: 35,
          longitude: -80,
          recordedAt: start,
          horizontalAccuracyMeters: 5,
        ),
      );

      for (final source in const ['gps', 'mapbox', 'firebase', 'remote']) {
        expect(
          await controller.recordUserTripEvent(
            commandId: 'blocked_$source',
            kind: TripTrackingUserEventKind.stop,
            initiatingSource: source,
          ),
          isFalse,
        );
      }
      expect(store.activeSession!.userEvents, isEmpty);
    },
  );

  test('tampered persisted event authority is rejected during recovery', () {
    final event = TripTrackingUserEvent(
      id: 'trip_1:user:pickup_1',
      sessionId: 'trip_1',
      vehicleId: 'vehicle_1',
      profileId: 'profile_1',
      kind: TripTrackingUserEventKind.pickup,
      occurredAt: start,
      recordedAt: start,
      initiatingSource: 'trip_screen',
    ).toMap()..['remoteCreated'] = true;
    final restored = TripTrackingSessionRecord.fromMap({
      'id': 'trip_1',
      'vehicleId': 'vehicle_1',
      'profileId': 'profile_1',
      'vehicleConfigurationRevision': 0,
      'startingOdometer': 1000,
      'profile': TripTrackingProfile.deliveryVehicle.name,
      'startedAt': start.toIso8601String(),
      'updatedAt': start.toIso8601String(),
      'startedTimeZoneOffsetMinutes': 0,
      'startedTimeZoneName': 'UTC',
      'engineSnapshot': const TripTrackingEngineSnapshot(
        totalAcceptedMeters: 0,
        walkingReviewSuggested: false,
      ).toMap(),
      'advisories': const <Object?>[],
      'userEvents': [event],
      'schemaVersion': 5,
    });

    expect(restored.userEvents, isEmpty);
    expect(restored.hasValidTimeline, isTrue);
  });

  test(
    'completed review preserves user events and legacy review invents none',
    () {
      final event = TripTrackingUserEvent(
        id: 'user:dropoff_1',
        sessionId: 'trip_review_events',
        vehicleId: 'vehicle_1',
        profileId: 'profile_1',
        kind: TripTrackingUserEventKind.dropoff,
        occurredAt: start.add(const Duration(minutes: 15)),
        recordedAt: start.add(const Duration(minutes: 15)),
        initiatingSource: 'dashboard',
      );
      final source = TripTrackingReviewRecord(
        id: 'trip_review_events',
        vehicleId: 'vehicle_1',
        profileId: 'profile_1',
        startingOdometer: 1000,
        estimatedEndingOdometer: 1005,
        profile: TripTrackingProfile.deliveryVehicle,
        startedAt: start,
        finishedAt: start.add(const Duration(hours: 1)),
        engineSnapshot: const TripTrackingEngineSnapshot(
          totalAcceptedMeters: 8046.72,
          walkingReviewSuggested: false,
        ),
        userEvents: [event],
      );

      final restored = TripTrackingReviewRecord.fromMap(source.toMap());
      final legacyMap = source.toMap()
        ..['schemaVersion'] = 4
        ..remove('userEvents');
      final legacy = TripTrackingReviewRecord.fromMap(legacyMap);

      expect(
        restored.userEvents.single.kind,
        TripTrackingUserEventKind.dropoff,
      );
      expect(restored.schemaVersion, 5);
      expect(legacy.userEvents, isEmpty);
      expect(legacy.schemaVersion, 5);
      expect(legacy.hasValidTimeline, isTrue);
    },
  );
}
