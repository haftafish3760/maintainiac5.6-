import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_route_point_store.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';

void main() {
  const enabled = TripTrackingSettings(
    gpsAssistedTrackingEnabled: true,
    mapPreviewEnabled: true,
    mapRouteHistorySavingEnabled: true,
    mapRouteHistoryDailyBudgetMb: 1,
    mapRouteHistorySampleIntervalSeconds: 30,
  );
  final now = DateTime.utc(2026, 7, 21, 12);
  Map<String, Object?> payload(int sequence) => {
    'schemaVersion': 1,
    'tripId': 'trip_1',
    'source': 'gps',
    'sequence': sequence,
    'recordedAt': now.add(Duration(seconds: sequence)).toIso8601String(),
    'latitude': 35.0,
    'longitude': -80.0,
    'horizontalAccuracyMeters': 5.0,
  };

  test(
    'local route store enforces opt-in, budget, and replay safety',
    () async {
      final store = TripTrackingRoutePointStore.memory();
      final first = await store.persist(
        payload: payload(1),
        expectedTripId: 'trip_1',
        localDayKey: '2026-07-21',
        nowUtc: now,
        settings: enabled,
      );
      final duplicate = await store.persist(
        payload: payload(1),
        expectedTripId: 'trip_1',
        localDayKey: '2026-07-21',
        nowUtc: now,
        settings: enabled,
      );
      final disabled = await store.persist(
        payload: payload(2),
        expectedTripId: 'trip_1',
        localDayKey: '2026-07-21',
        nowUtc: now,
        settings: const TripTrackingSettings(),
      );

      expect(first.saved, isTrue);
      expect(first.gpsTrackingMayContinue, isTrue);
      expect(first.canChangeOdometer, isFalse);
      expect(first.canUploadRawPointToFirestore, isFalse);
      expect(duplicate.saved, isFalse);
      expect(duplicate.reasonCode, 'route_point_replay_or_duplicate');
      expect(disabled.saved, isFalse);
      expect(store.pointsForTrip('trip_1'), hasLength(1));
      final restored = store.pointsForTrip('trip_1').single;
      expect(restored['latitude'], 35.0);
      expect(restored['longitude'], -80.0);
      expect(restored['horizontalAccuracyMeters'], 5.0);
      expect(TripTrackingRoutePointStore.compactEncodingVersion, 2);
    },
  );
}
