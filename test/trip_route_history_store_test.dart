import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_route_history_store.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';

void main() {
  final started = DateTime.utc(2026, 7, 20, 12);
  const settings = TripTrackingSettings(
    gpsAssistedTrackingEnabled: true,
    mapPreviewEnabled: true,
    mapRouteHistorySavingEnabled: true,
    mapRouteHistoryDailyBudgetMb: 0.25,
    mapRouteHistorySampleIntervalSeconds: 30,
  );

  test('compact route store enforces cadence and explicit deletion', () async {
    final store = TripRouteHistoryStore.memory();
    Future<bool> append(int seconds, double longitude) async =>
        (await store.appendGpsPoint(
          tripId: 'trip_route',
          latitude: 35,
          longitude: longitude,
          recordedAtUtc: started.add(Duration(seconds: seconds)),
          horizontalAccuracyMeters: 5,
          localDayKey: '2026-07-20',
          settings: settings,
          nowUtc: started.add(Duration(seconds: seconds)),
        )).persisted;

    expect(await append(0, -80), isTrue);
    expect(await append(10, -79.9999), isFalse);
    expect(await append(30, -79.999), isTrue);
    final replay = store.replay('trip_route');
    expect(replay.points, hasLength(2));
    expect(replay.points.last.sequence, 1);
    expect(
      store.summary('trip_route').toBundleSafeMap(),
      isNot(contains('latitude')),
    );
    expect(
      await store.deleteRoute('trip_route', userConfirmed: false),
      isFalse,
    );
    expect(store.replay('trip_route').points, hasLength(2));
    expect(await store.deleteRoute('trip_route', userConfirmed: true), isTrue);
    expect(store.replay('trip_route').points, isEmpty);
  });

  test('corrupt route segment is isolated from replay', () async {
    final directory = await Directory.systemTemp.createTemp('trip_route_');
    Hive.init(directory.path);
    final store = await TripRouteHistoryStore.create();
    addTearDown(() async {
      await Hive.close();
      if (directory.existsSync()) await directory.delete(recursive: true);
    });
    await store.appendGpsPoint(
      tripId: 'trip_corrupt_route',
      latitude: 35,
      longitude: -80,
      recordedAtUtc: started,
      horizontalAccuracyMeters: 5,
      localDayKey: '2026-07-20',
      settings: settings,
      nowUtc: started,
    );
    final box = Hive.box<dynamic>(TripRouteHistoryStore.boxName);
    final key = box.keys.whereType<String>().firstWhere(
      (value) => value.startsWith('route:trip_corrupt_route:'),
    );
    final corrupt = Map<String, Object?>.from(box.get(key) as Map);
    corrupt['checksum'] = 'corrupt';
    await box.put(key, corrupt);

    final replay = store.replay('trip_corrupt_route');
    expect(replay.points, isEmpty);
    expect(replay.corruptSegmentCount, 1);
  });

  test('controller route capture never changes confirmed odometer', () async {
    final routeStore = TripRouteHistoryStore.memory();
    final odometer = GlobalOdometerController(
      vehicleId: 'vehicle_1',
      initialReading: 1000,
    );
    final controller = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      odometer: odometer,
      routeHistoryStore: routeStore,
      trackingSettings: () => settings,
    );
    await controller.start(
      tripId: 'trip_route_controller',
      vehicleId: 'vehicle_1',
      profile: TripTrackingProfile.roadVehicle,
      startedAt: started,
    );
    for (final entry in [(0, -80.0), (30, -79.999)]) {
      await controller.ingest(
        TripLocationSample(
          latitude: 35,
          longitude: entry.$2,
          recordedAt: started.add(Duration(seconds: entry.$1)),
          horizontalAccuracyMeters: 5,
        ),
        referenceTime: started.add(Duration(seconds: entry.$1)),
      );
    }

    expect(routeStore.replay('trip_route_controller').points, hasLength(2));
    expect(controller.routeStorageStatus, 'route_point_persisted');
    expect(odometer.confirmedReading, 1000);
  });
}
