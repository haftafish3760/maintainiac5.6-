import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/records/maintainiac_durable_record_store.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_daily_bundle_bridge.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_user_event.dart';

void main() {
  test('reviewed trips merge idempotently into one local-day bundle', () async {
    final store = MaintainiacDurableRecordStore.memory();
    final bridge = TripTrackingDailyBundleBridge(store);
    final first = review('trip_1', DateTime.utc(2026, 7, 21, 2), -240, 10);
    final second = review('trip_2', DateTime.utc(2026, 7, 21, 3), -240, 15);

    await bridge.upsertReviewedTrip(first);
    await bridge.upsertReviewedTrip(second);
    await bridge.upsertReviewedTrip(first);

    final bundle = bridge.bundleForDay('2026-07-20')!;
    expect(
      store.recordsFor(TripTrackingDailyBundleBridge.module),
      hasLength(1),
    );
    expect(bundle.payload['tripCount'], 2);
    expect(bundle.payload['confirmedMileage'], 25);
    expect(bundle.payload['singleDocumentPerLocalDay'], isTrue);
    expect(bundle.payload['rawGpsIncluded'], isFalse);
    expect(bundle.payload['coordinatesIncluded'], isFalse);
    final trips = bundle.payload['trips'] as List;
    expect((trips.first as Map)['userEvents'], hasLength(1));
  });

  test('cross-midnight trip remains assigned to its start day', () async {
    final store = MaintainiacDurableRecordStore.memory();
    final bridge = TripTrackingDailyBundleBridge(store);
    final trip = review(
      'overnight',
      DateTime.utc(2026, 7, 21, 3, 30),
      -240,
      50,
    ).copyWith();

    await bridge.upsertReviewedTrip(trip);

    expect(bridge.bundleForDay('2026-07-20'), isNotNull);
    expect(bridge.bundleForDay('2026-07-21'), isNull);
  });

  test(
    'malformed existing bundle is preserved instead of overwritten',
    () async {
      final store = MaintainiacDurableRecordStore.memory();
      await store.save(
        module: TripTrackingDailyBundleBridge.module,
        id: '2026-07-20',
        payload: {'schemaVersion': 99, 'trips': <Object?>[]},
      );
      final bridge = TripTrackingDailyBundleBridge(store);

      await expectLater(
        () => bridge.upsertReviewedTrip(
          review('trip_1', DateTime.utc(2026, 7, 21, 2), -240, 10),
        ),
        throwsStateError,
      );
      expect(
        store
            .recordFor(TripTrackingDailyBundleBridge.module, '2026-07-20')
            ?.payload['schemaVersion'],
        99,
      );
    },
  );
}

TripTrackingReviewRecord review(
  String id,
  DateTime startedAt,
  int offsetMinutes,
  int miles,
) => TripTrackingReviewRecord(
  id: id,
  vehicleId: 'vehicle_1',
  profileId: 'profile_1',
  startingOdometer: 1000,
  estimatedEndingOdometer: 1000 + miles,
  confirmedEndingOdometer: 1000 + miles,
  odometerConfirmedAt: startedAt.add(const Duration(hours: 2)),
  profile: TripTrackingProfile.roadVehicle,
  startedAt: startedAt,
  finishedAt: startedAt.add(const Duration(hours: 1)),
  startedTimeZoneOffsetMinutes: offsetMinutes,
  startedTimeZoneName: 'EDT',
  finishedTimeZoneOffsetMinutes: offsetMinutes,
  finishedTimeZoneName: 'EDT',
  engineSnapshot: TripTrackingEngineSnapshot(
    totalAcceptedMeters: miles * 1609.344,
    walkingReviewSuggested: false,
  ),
  userEvents: [
    TripTrackingUserEvent(
      id: '$id:user:pickup_1',
      sessionId: id,
      vehicleId: 'vehicle_1',
      profileId: 'profile_1',
      kind: TripTrackingUserEventKind.pickup,
      occurredAt: startedAt.add(const Duration(minutes: 20)),
      recordedAt: startedAt.add(const Duration(minutes: 20)),
      initiatingSource: 'trip_screen',
    ),
  ],
);
