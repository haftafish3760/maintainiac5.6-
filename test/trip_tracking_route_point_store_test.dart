import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_platform.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_route_point_store.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';
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

  test(
    'route deletion requires explicit confirmation and repairs budget',
    () async {
      final store = TripTrackingRoutePointStore.memory();
      await store.persist(
        payload: payload(1),
        expectedTripId: 'trip_1',
        localDayKey: '2026-07-21',
        nowUtc: now,
        settings: enabled,
      );

      expect(await store.deleteRoute('trip_1', userConfirmed: false), isFalse);
      expect(store.pointsForTrip('trip_1'), hasLength(1));
      expect(await store.deleteRoute('trip_1', userConfirmed: true), isTrue);
      expect(store.pointsForTrip('trip_1'), isEmpty);
      expect(store.nextSequenceForTrip('trip_1'), 0);

      final replacement = await store.persist(
        payload: payload(0),
        expectedTripId: 'trip_1',
        localDayKey: '2026-07-21',
        nowUtc: now,
        settings: enabled,
      );
      expect(replacement.saved, isTrue);
      expect(replacement.persistedPointsForDay, 1);
    },
  );

  test('concurrent route writes retain order and daily counts', () async {
    final store = TripTrackingRoutePointStore.memory();

    final results = await Future.wait([
      store.persist(
        payload: payload(0),
        expectedTripId: 'trip_1',
        localDayKey: '2026-07-21',
        nowUtc: now,
        settings: enabled,
      ),
      store.persist(
        payload: payload(1),
        expectedTripId: 'trip_1',
        localDayKey: '2026-07-21',
        nowUtc: now,
        settings: enabled,
      ),
    ]);

    expect(results.map((result) => result.saved), everyElement(isTrue));
    expect(results.last.persistedPointsForDay, 2);
    expect(store.pointsForTrip('trip_1').map((point) => point['sequence']), [
      0,
      1,
    ]);
  });

  test(
    'revoking maps mid-trip stops route capture without stopping GPS mileage',
    () async {
      final store = TripTrackingRoutePointStore.memory();
      final platform = _RoutePlatform();
      var activeSettings = enabled;
      var clock = now;
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
        platform: platform,
        routePointStore: store,
        routeSettings: () => activeSettings,
        localRouteDayKey: (_) => '2026-07-21',
        clockNow: () => clock,
      );
      addTearDown(controller.dispose);
      addTearDown(platform.close);
      await controller.start(
        tripId: 'trip_route_consent_revoked',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: now,
      );
      expect(
        await controller.startNativeTracking(allowBackground: false),
        isTrue,
      );

      for (final entry in [(0, -80.0), (30, -79.999)]) {
        clock = now.add(Duration(seconds: entry.$1));
        platform.addLocation(
          TripLocationSample(
            latitude: 35,
            longitude: entry.$2,
            recordedAt: clock,
            horizontalAccuracyMeters: 5,
          ),
        );
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);
      }
      final acceptedBeforeRevocation = controller.acceptedMeters;
      expect(store.pointsForTrip('trip_route_consent_revoked'), hasLength(2));

      activeSettings = activeSettings.copyWith(mapPreviewEnabled: false);
      clock = now.add(const Duration(seconds: 60));
      platform.addLocation(
        TripLocationSample(
          latitude: 35,
          longitude: -79.998,
          recordedAt: clock,
          horizontalAccuracyMeters: 5,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(activeSettings.gpsAssistedTrackingEnabled, isTrue);
      expect(activeSettings.mapPreviewEnabled, isFalse);
      expect(activeSettings.mapRouteHistorySavingEnabled, isFalse);
      expect(controller.acceptedMeters, greaterThan(acceptedBeforeRevocation));
      expect(controller.routeStorageStatus, 'maps_not_enabled');
      expect(store.pointsForTrip('trip_route_consent_revoked'), hasLength(2));
    },
  );
}

class _RoutePlatform implements TripTrackingNativeGateway {
  final _events = StreamController<TripTrackingPlatformEvent>.broadcast();

  @override
  Stream<TripTrackingPlatformEvent> get events => _events.stream;

  void addLocation(TripLocationSample sample) => _events.add(
    TripTrackingPlatformEvent.fromMap({
      ...sample.toMap(),
      'schemaVersion': 1,
      'type': TripTrackingPlatformEventType.location.name,
    }),
  );

  Future<void> close() => _events.close();

  @override
  Future<bool> get isTracking async => false;

  @override
  Future<TripTrackingPlatformCapabilities> readCapabilities() async =>
      const TripTrackingPlatformCapabilities(
        locationAvailable: true,
        backgroundTrackingAvailable: true,
        activityRecognitionAvailable: false,
      );

  @override
  Future<TripTrackingBatterySnapshot> readBatterySnapshot() async =>
      const TripTrackingBatterySnapshot(
        batteryPercent: 80,
        isCharging: false,
        lowPowerModeEnabled: false,
      );

  @override
  Future<TripTrackingAuthorization> requestAuthorization({
    required bool allowBackground,
    required bool activityRecognitionEnabled,
  }) async => TripTrackingAuthorization(
    state: allowBackground
        ? TripTrackingAuthorizationState.always
        : TripTrackingAuthorizationState.whileInUse,
    preciseLocation: true,
  );

  @override
  Future<bool> start(TripTrackingNativeRequest request) async => true;

  @override
  Future<void> stop() async {}

  @override
  Future<bool> update(TripTrackingNativeRequest request) async => true;
}
