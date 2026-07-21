import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_upload_queue.dart';
import 'package:maintaniac/shared/odometer/odometer_mileage_review.dart';
import 'package:maintaniac/shared/odometer/odometer_validation.dart';
import 'package:maintaniac/shared/records/maintainiac_durable_record_store.dart';
import 'package:maintaniac/shared/storage/app_storage_guard.dart';
import 'package:maintaniac/shared/state/global_odometer.dart'
    as global_odometer;
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_durable_record_bridge.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_engine.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_firebase_bridge.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_platform.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';

/// Keeps controller tests aligned with production: GPS sessions are started
/// for the currently selected odometer vehicle unless a test explicitly
/// exercises a mismatch.
class GlobalOdometerController
    extends global_odometer.GlobalOdometerController {
  GlobalOdometerController({
    super.vehicleId = 'vehicle_1',
    super.initialReading = 298150,
    super.validationPolicy,
  });
}

void main() {
  final start = DateTime.utc(2026, 7, 12, 12);

  TripLocationSample sample(
    double longitude,
    int seconds, {
    double? speed,
    double? speedAccuracy,
    double accuracy = 5,
    int? monotonicElapsedNanos,
  }) => TripLocationSample(
    latitude: 35,
    longitude: longitude,
    recordedAt: start.add(Duration(seconds: seconds)),
    horizontalAccuracyMeters: accuracy,
    speedMetersPerSecond: speed,
    speedAccuracyMetersPerSecond: speedAccuracy,
    monotonicElapsedNanos: monotonicElapsedNanos,
  );

  Future<void> drainNativeTripEventsUntil(
    bool Function() condition, {
    int maxPumps = 12,
  }) async {
    for (var pump = 0; pump < maxPumps && !condition(); pump += 1) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  test(
    'controller accepts newer Android monotonic time at a duplicate wall clock',
    () async {
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(initialReading: 1000),
      );
      await controller.start(
        tripId: 'trip_duplicate_android_wall_clock',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );

      await controller.ingest(
        sample(-80, 0, monotonicElapsedNanos: 10000000000),
      );
      expect(
        (await controller.ingest(
          sample(-79.9998, 0, monotonicElapsedNanos: 30000000000),
        ))?.disposition,
        TripSampleDisposition.acceptedDistance,
      );
      expect(controller.acceptedMeters, greaterThan(0));
    },
  );

  test(
    'controller rejects invalid direct speed accuracy before persistence',
    () async {
      final store = TripTrackingSessionStore.memory();
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(initialReading: 1000),
      );
      await controller.start(
        tripId: 'trip_invalid_direct_speed_accuracy',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );

      final decision = await controller.ingest(
        TripLocationSample(
          latitude: 35,
          longitude: -80,
          recordedAt: start,
          horizontalAccuracyMeters: 5,
          speedAccuracyMetersPerSecond: -1,
        ),
      );

      expect(decision?.disposition, TripSampleDisposition.rejectedInvalid);
      expect(
        store.pendingSampleFor('trip_invalid_direct_speed_accuracy'),
        isNull,
      );
    },
  );

  test(
    'controller rejects regressing Android monotonic time before persistence',
    () async {
      final store = TripTrackingSessionStore.memory();
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(initialReading: 1000),
      );
      await controller.start(
        tripId: 'trip_regressing_android_monotonic_time',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );

      await controller.ingest(sample(0, 0, monotonicElapsedNanos: 30000000000));
      final rejected = await controller.ingest(
        sample(1, 1, monotonicElapsedNanos: 20000000000),
      );
      expect(rejected?.disposition, TripSampleDisposition.rejectedOutOfOrder);
      expect(controller.acceptedMeters, 0);
      expect(
        store.pendingSampleFor('trip_regressing_android_monotonic_time'),
        isNull,
      );
    },
  );

  test(
    'controller allows a recovered Android monotonic clock epoch reset',
    () async {
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(initialReading: 1000),
      );
      await controller.start(
        tripId: 'trip_recovered_android_monotonic_clock',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );

      await controller.ingest(
        sample(0, 0, monotonicElapsedNanos: 120000000000),
      );
      expect(
        (await controller.ingest(
          sample(0.0002, 20, monotonicElapsedNanos: 1000000000),
        ))?.disposition,
        TripSampleDisposition.acceptedDistance,
      );
    },
  );

  test(
    'a failed initial local checkpoint releases the live odometer lock',
    () async {
      final hiveDirectory = await Directory.systemTemp.createTemp(
        'trip_tracking_closed_store_',
      );
      Hive.init(hiveDirectory.path);
      final store = await TripTrackingSessionStore.create();
      await Hive.close();
      addTearDown(() async {
        if (hiveDirectory.existsSync()) {
          await hiveDirectory.delete(recursive: true);
        }
      });
      final odometer = GlobalOdometerController(initialReading: 1000);
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: odometer,
      );

      expect(
        await controller.start(
          tripId: 'trip_storage_failure',
          vehicleId: 'vehicle_1',
          profile: TripTrackingProfile.roadVehicle,
          startedAt: start,
        ),
        isFalse,
      );

      expect(controller.isTracking, isFalse);
      expect(odometer.hasLiveTripProjection, isFalse);
      expect(controller.platformStatus, 'storage_failed');
      expect(
        controller.platformError,
        contains('Could not save the trip locally'),
      );
    },
  );

  test('GPS tracking cannot start against another active vehicle', () async {
    final store = TripTrackingSessionStore.memory();
    final odometer = GlobalOdometerController(
      vehicleId: 'vehicle_b',
      initialReading: 2000,
    );
    final controller = TripTrackingController(
      sessionStore: store,
      odometer: odometer,
    );

    expect(
      await controller.start(
        tripId: 'trip_start_vehicle_mismatch',
        vehicleId: 'vehicle_a',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      ),
      isFalse,
    );
    expect(controller.platformStatus, 'vehicle_mismatch');
    expect(store.activeSession, isNull);

    expect(
      await odometer.switchVehicleById('vehicle_a', fallbackReading: 2000),
      isTrue,
    );
    expect(
      await controller.start(
        tripId: 'trip_start_after_vehicle_switch',
        vehicleId: 'vehicle_a',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      ),
      isTrue,
    );
    expect(controller.platformStatus, isNull);
    expect(controller.platformError, isNull);
  });

  test('GPS tracking cannot start with unsafe trip or vehicle ids', () async {
    final store = TripTrackingSessionStore.memory();
    final odometer = GlobalOdometerController(
      vehicleId: 'vehicle_1',
      initialReading: 1000,
    );
    final controller = TripTrackingController(
      sessionStore: store,
      odometer: odometer,
    );

    expect(
      await controller.start(
        tripId: ' trip_bad ',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      ),
      isFalse,
    );
    expect(
      await controller.start(
        tripId: 'trip_bad_vehicle',
        vehicleId: 'vehicle_\n1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      ),
      isFalse,
    );
    expect(store.activeSession, isNull);
    expect(odometer.hasLiveTripProjection, isFalse);
  });

  test('GPS tracking cannot start with a future start timestamp', () async {
    final store = TripTrackingSessionStore.memory();
    final odometer = GlobalOdometerController(
      vehicleId: 'vehicle_1',
      initialReading: 1000,
    );
    final controller = TripTrackingController(
      sessionStore: store,
      odometer: odometer,
    );

    expect(
      await controller.start(
        tripId: 'trip_future_start',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: DateTime.now().toUtc().add(const Duration(minutes: 10)),
      ),
      isFalse,
    );

    expect(controller.isTracking, isFalse);
    expect(store.activeSession, isNull);
    expect(odometer.hasLiveTripProjection, isFalse);
    expect(controller.platformStatus, 'trip_start_time_invalid');
  });

  test('restore fails safely when local trip storage is unavailable', () async {
    final hiveDirectory = await Directory.systemTemp.createTemp(
      'trip_tracking_restore_closed_store_',
    );
    Hive.init(hiveDirectory.path);
    final store = await TripTrackingSessionStore.create();
    await Hive.close();
    addTearDown(() async {
      if (hiveDirectory.existsSync()) {
        await hiveDirectory.delete(recursive: true);
      }
    });
    final controller = TripTrackingController(
      sessionStore: store,
      odometer: GlobalOdometerController(initialReading: 1000),
    );

    expect(await controller.restore(), isFalse);
    expect(controller.isTracking, isFalse);
    expect(controller.platformStatus, 'storage_failed');
    expect(controller.platformError, contains('Could not read local trip'));
  });

  test(
    'a failed review checkpoint keeps the trip recoverable for retry',
    () async {
      final hiveDirectory = await Directory.systemTemp.createTemp(
        'trip_tracking_review_store_',
      );
      Hive.init(hiveDirectory.path);
      final store = await TripTrackingSessionStore.create();
      final odometer = GlobalOdometerController(initialReading: 1000);
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: odometer,
      );
      expect(
        await controller.start(
          tripId: 'trip_review_storage_failure',
          vehicleId: 'vehicle_1',
          profile: TripTrackingProfile.roadVehicle,
          startedAt: start,
        ),
        isTrue,
      );
      await Hive.close();
      addTearDown(() async {
        if (hiveDirectory.existsSync()) {
          await hiveDirectory.delete(recursive: true);
        }
      });

      expect(await controller.finishForReview(), isNull);

      expect(controller.isTracking, isTrue);
      expect(odometer.hasLiveTripProjection, isTrue);
      expect(controller.platformStatus, 'review_save_failed');
      expect(
        controller.platformError,
        contains('Could not save the completed trip locally'),
      );
    },
  );

  test(
    'a failed empty-trip discard keeps the durable trip state intact',
    () async {
      final hiveDirectory = await Directory.systemTemp.createTemp(
        'trip_tracking_discard_store_',
      );
      Hive.init(hiveDirectory.path);
      final store = await TripTrackingSessionStore.create();
      final odometer = GlobalOdometerController(initialReading: 1000);
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: odometer,
      );
      expect(
        await controller.start(
          tripId: 'trip_discard_storage_failure',
          vehicleId: 'vehicle_1',
          profile: TripTrackingProfile.roadVehicle,
          startedAt: start,
        ),
        isTrue,
      );
      await Hive.close();
      addTearDown(() async {
        if (hiveDirectory.existsSync()) {
          await hiveDirectory.delete(recursive: true);
        }
      });

      expect(await controller.discardEmptyTrip(), isFalse);

      expect(controller.isTracking, isTrue);
      expect(odometer.hasLiveTripProjection, isTrue);
      expect(controller.platformStatus, 'discard_failed');
      expect(
        controller.platformError,
        contains('Could not discard the empty trip locally'),
      );
    },
  );

  test(
    'empty-trip discard reports transient pending cleanup failure',
    () async {
      final store = _FailingPendingCleanupStore();
      final odometer = GlobalOdometerController(initialReading: 1000);
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: odometer,
      );
      expect(
        await controller.start(
          tripId: 'trip_discard_pending_cleanup_fault',
          vehicleId: 'vehicle_1',
          profile: TripTrackingProfile.roadVehicle,
          startedAt: start,
        ),
        isTrue,
      );
      await store.savePending(
        TripTrackingPendingSample(
          sessionId: 'trip_discard_pending_cleanup_fault',
          sample: sample(-80, 0),
        ),
      );

      expect(await controller.discardEmptyTrip(), isTrue);

      expect(controller.isTracking, isFalse);
      expect(odometer.hasLiveTripProjection, isFalse);
      expect(store.activeSession, isNull);
      expect(
        store.pendingSampleFor('trip_discard_pending_cleanup_fault'),
        isNotNull,
      );
      expect(controller.platformStatus, 'pending_cleanup_failed');
      expect(
        controller.platformError,
        contains('Could not clear transient GPS recovery data'),
      );
    },
  );

  test(
    'native GPS cannot start without a durable lifecycle checkpoint',
    () async {
      final hiveDirectory = await Directory.systemTemp.createTemp(
        'trip_tracking_lifecycle_store_',
      );
      Hive.init(hiveDirectory.path);
      final store = await TripTrackingSessionStore.create();
      final native = _FakeTripTrackingPlatform();
      final odometer = GlobalOdometerController(initialReading: 1000);
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: odometer,
        platform: native,
      );
      expect(
        await controller.start(
          tripId: 'trip_lifecycle_storage_failure',
          vehicleId: 'vehicle_1',
          profile: TripTrackingProfile.roadVehicle,
          startedAt: start,
        ),
        isTrue,
      );
      await Hive.close();
      addTearDown(() async {
        if (hiveDirectory.existsSync()) {
          await hiveDirectory.delete(recursive: true);
        }
      });

      expect(
        await controller.startNativeTracking(allowBackground: false),
        isFalse,
      );

      expect(native.startCalls, 0);
      expect(controller.isTracking, isTrue);
      expect(odometer.hasLiveTripProjection, isTrue);
      expect(controller.platformStatus, 'storage_failed');
      expect(
        controller.platformError,
        contains('Could not save trip recovery state locally'),
      );
    },
  );

  test(
    'native GPS capability read failures fail closed before permission request',
    () async {
      final native = _FakeTripTrackingPlatform(throwOnReadCapabilities: true);
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
        platform: native,
      );
      expect(
        await controller.start(
          tripId: 'trip_capability_fault',
          vehicleId: 'vehicle_1',
          profile: TripTrackingProfile.roadVehicle,
          startedAt: start,
        ),
        isTrue,
      );

      expect(
        await controller.startNativeTracking(allowBackground: false),
        isFalse,
      );

      expect(native.requestAuthorizationCalls, 0);
      expect(native.startCalls, 0);
      expect(native.hasEventListener, isFalse);
      expect(controller.lastKnownCapabilities, isNull);
      expect(controller.isTracking, isTrue);
      expect(controller.platformStatus, isNull);
      expect(
        controller.platformError,
        contains('Could not read GPS capabilities'),
      );
      expect(
        controller.lifecycleState,
        TripTrackingSessionLifecycleState.failedRecoverable,
      );
      expect(controller.healthState, TripTrackingHealthState.unavailable);
    },
  );

  test(
    'low battery GPS protection asks before requesting permission',
    () async {
      final native = _FakeTripTrackingPlatform(
        batterySnapshot: const TripTrackingBatterySnapshot(
          batteryPercent: 15,
          isCharging: false,
          lowPowerModeEnabled: false,
        ),
      );
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
        platform: native,
      );
      await controller.start(
        tripId: 'trip_low_battery_prompt',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );

      expect(
        await controller.startNativeTracking(allowBackground: false),
        isFalse,
      );

      expect(native.requestAuthorizationCalls, 0);
      expect(native.startCalls, 0);
      expect(controller.platformStatus, 'low_battery_requires_user_choice');
      expect(controller.platformError, contains('below 15% battery'));
      expect(
        controller.lifecycleState,
        TripTrackingSessionLifecycleState.failedRecoverable,
      );
      expect(controller.healthState, TripTrackingHealthState.unavailable);
    },
  );

  test(
    'saved low battery cancellation blocks GPS before permission request',
    () async {
      final native = _FakeTripTrackingPlatform(
        batterySnapshot: const TripTrackingBatterySnapshot(
          batteryPercent: 15,
          isCharging: false,
          lowPowerModeEnabled: true,
        ),
      );
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
        platform: native,
      );
      await controller.start(
        tripId: 'trip_low_battery_saved_block',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );

      expect(
        await controller.startNativeTracking(
          allowBackground: false,
          lowBatteryWarningDismissed: true,
        ),
        isFalse,
      );

      expect(native.requestAuthorizationCalls, 0);
      expect(native.startCalls, 0);
      expect(
        controller.platformStatus,
        'low_battery_gps_blocked_by_saved_choice',
      );
      expect(controller.platformError, contains('below 15% battery'));
    },
  );

  test('low battery override allows GPS startup', () async {
    final native = _FakeTripTrackingPlatform(
      batterySnapshot: const TripTrackingBatterySnapshot(
        batteryPercent: 15,
        isCharging: false,
        lowPowerModeEnabled: true,
      ),
    );
    final controller = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      odometer: GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      ),
      platform: native,
    );
    await controller.start(
      tripId: 'trip_low_battery_override',
      vehicleId: 'vehicle_1',
      profile: TripTrackingProfile.roadVehicle,
      startedAt: start,
    );

    expect(
      await controller.startNativeTracking(
        allowBackground: false,
        lowBatteryOverrideEnabled: true,
      ),
      isTrue,
    );

    expect(native.requestAuthorizationCalls, 1);
    expect(native.startCalls, 1);
    expect(controller.platformError, isNull);
  });

  test('low battery override retry clears the previous GPS block', () async {
    final native = _FakeTripTrackingPlatform(
      batterySnapshot: const TripTrackingBatterySnapshot(
        batteryPercent: 15,
        isCharging: false,
        lowPowerModeEnabled: false,
      ),
    );
    final controller = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      odometer: GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      ),
      platform: native,
    );
    await controller.start(
      tripId: 'trip_low_battery_retry',
      vehicleId: 'vehicle_1',
      profile: TripTrackingProfile.roadVehicle,
      startedAt: start,
    );

    expect(
      await controller.startNativeTracking(allowBackground: false),
      isFalse,
    );
    expect(controller.platformStatus, 'low_battery_requires_user_choice');
    expect(controller.platformError, contains('below 15% battery'));

    expect(
      await controller.startNativeTracking(
        allowBackground: false,
        lowBatteryOverrideEnabled: true,
      ),
      isTrue,
    );

    expect(native.requestAuthorizationCalls, 1);
    expect(native.startCalls, 1);
    expect(controller.platformStatus, 'tracking');
    expect(controller.platformError, isNull);
  });

  test('low power mode asks before requesting GPS permission', () async {
    final native = _FakeTripTrackingPlatform(
      batterySnapshot: const TripTrackingBatterySnapshot(
        batteryPercent: 80,
        isCharging: false,
        lowPowerModeEnabled: true,
      ),
    );
    final controller = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      odometer: GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      ),
      platform: native,
    );
    await controller.start(
      tripId: 'trip_low_power_prompt',
      vehicleId: 'vehicle_1',
      profile: TripTrackingProfile.roadVehicle,
      startedAt: start,
    );

    expect(
      await controller.startNativeTracking(allowBackground: false),
      isFalse,
    );

    expect(native.requestAuthorizationCalls, 0);
    expect(native.startCalls, 0);
    expect(controller.platformStatus, 'low_power_mode_requires_user_choice');
    expect(controller.platformError, contains('Battery saver is active'));
    expect(
      controller.lifecycleState,
      TripTrackingSessionLifecycleState.failedRecoverable,
    );
  });

  test('unavailable low power capability cannot block GPS startup', () async {
    final native = _FakeTripTrackingPlatform(
      batteryStateAvailable: true,
      lowPowerModeAvailable: false,
      batterySnapshot: const TripTrackingBatterySnapshot(
        batteryPercent: 80,
        isCharging: false,
        lowPowerModeEnabled: true,
      ),
    );
    final controller = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      odometer: GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      ),
      platform: native,
    );
    await controller.start(
      tripId: 'trip_low_power_unavailable',
      vehicleId: 'vehicle_1',
      profile: TripTrackingProfile.roadVehicle,
      startedAt: start,
    );

    expect(
      await controller.startNativeTracking(allowBackground: false),
      isTrue,
    );

    expect(native.requestAuthorizationCalls, 1);
    expect(native.startCalls, 1);
    expect(controller.lastKnownCapabilities, isNotNull);
    expect(controller.lastKnownCapabilities!.lowPowerModeAvailable, isFalse);
    expect(controller.platformStatus, 'tracking');
    expect(controller.platformError, isNull);
  });

  test(
    'battery snapshot read failures do not fabricate low battery blocks',
    () async {
      final native = _FakeTripTrackingPlatform(
        throwOnReadBatterySnapshot: true,
      );
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
        platform: native,
      );
      await controller.start(
        tripId: 'trip_battery_snapshot_failure',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );

      expect(
        await controller.startNativeTracking(allowBackground: false),
        isTrue,
      );

      expect(native.requestAuthorizationCalls, 1);
      expect(native.startCalls, 1);
      expect(controller.platformError, isNull);
    },
  );

  test(
    'runtime critical battery stops GPS but preserves the local trip',
    () async {
      final native = _FakeTripTrackingPlatform();
      var now = DateTime.utc(2026, 7, 12, 12);
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
        platform: native,
        clockNow: () => now,
      );
      addTearDown(controller.dispose);

      await controller.start(
        tripId: 'trip_runtime_critical_battery',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      expect(
        await controller.startNativeTracking(allowBackground: false),
        isTrue,
      );

      native.batterySnapshot = const TripTrackingBatterySnapshot(
        batteryPercent: 9,
        isCharging: false,
        lowPowerModeEnabled: false,
      );
      now = now.add(const Duration(minutes: 6));
      native.addLocation(sample(-80, 0));
      await drainNativeTripEventsUntil(() => !controller.nativeTracking);

      expect(controller.isTracking, isTrue);
      expect(controller.nativeTracking, isFalse);
      expect(native.stopCalls, 1);
      expect(controller.platformStatus, 'battery_critical_gps_blocked');
      expect(controller.platformError, contains('critically low'));
    },
  );

  test(
    'runtime battery check allows a plugged-in device below twenty percent',
    () async {
      final native = _FakeTripTrackingPlatform();
      var now = DateTime.utc(2026, 7, 12, 12);
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
        platform: native,
        clockNow: () => now,
      );
      addTearDown(controller.dispose);

      await controller.start(
        tripId: 'trip_runtime_charging_battery',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      expect(
        await controller.startNativeTracking(allowBackground: false),
        isTrue,
      );

      native.batterySnapshot = const TripTrackingBatterySnapshot(
        batteryPercent: 19,
        isCharging: true,
        lowPowerModeEnabled: false,
      );
      now = now.add(const Duration(minutes: 6));
      native.addLocation(sample(-80, 0));
      await drainNativeTripEventsUntil(
        () => controller.platformStatus == 'tracking',
      );

      expect(controller.nativeTracking, isTrue);
      expect(native.stopCalls, 0);
      expect(controller.platformStatus, 'tracking');
    },
  );

  test(
    'runtime battery check warns below twenty percent before the fifteen percent prompt',
    () async {
      final native = _FakeTripTrackingPlatform();
      var now = DateTime.utc(2026, 7, 12, 12);
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
        platform: native,
        clockNow: () => now,
      );
      addTearDown(controller.dispose);

      await controller.start(
        tripId: 'trip_runtime_low_battery_warning',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      expect(
        await controller.startNativeTracking(allowBackground: false),
        isTrue,
      );

      native.batterySnapshot = const TripTrackingBatterySnapshot(
        batteryPercent: 19,
        isCharging: false,
        lowPowerModeEnabled: false,
      );
      now = now.add(const Duration(minutes: 6));
      native.addLocation(sample(-80, 0));
      await drainNativeTripEventsUntil(
        () => controller.platformStatus == 'battery_low_warning',
      );

      expect(controller.isTracking, isTrue);
      expect(controller.nativeTracking, isTrue);
      expect(native.stopCalls, 0);
      expect(controller.platformError, contains('below 20%'));
      expect(controller.platformError, contains('at or below 15%'));
    },
  );

  test(
    'native heartbeat without GPS fixes degrades until a credible fix arrives',
    () async {
      final native = _FakeTripTrackingPlatform();
      var now = start;
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
        platform: native,
        clockNow: () => now,
      );
      addTearDown(controller.dispose);

      await controller.start(
        tripId: 'trip_signal_stale_heartbeat',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      expect(
        await controller.startNativeTracking(allowBackground: true),
        isTrue,
      );

      now = now.add(const Duration(minutes: 3));
      native.addStatus('tracking');
      await drainNativeTripEventsUntil(
        () => controller.platformStatus == 'gps_signal_stale',
      );

      expect(
        controller.lifecycleState,
        TripTrackingSessionLifecycleState.degraded,
      );
      expect(controller.healthState, TripTrackingHealthState.reduced);
      expect(controller.platformError, contains('has not produced'));

      now = now.add(const Duration(seconds: 1));
      native.addLocation(sample(-80, 181));
      await drainNativeTripEventsUntil(
        () => controller.platformStatus == 'tracking',
      );

      expect(
        controller.lifecycleState,
        TripTrackingSessionLifecycleState.active,
      );
      expect(controller.healthState, TripTrackingHealthState.healthy);
      expect(controller.platformError, isNull);
    },
  );

  test('native heartbeat at the GPS freshness boundary stays usable', () async {
    final native = _FakeTripTrackingPlatform();
    var now = start;
    final controller = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      odometer: GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      ),
      platform: native,
      clockNow: () => now,
    );
    addTearDown(controller.dispose);

    await controller.start(
      tripId: 'trip_signal_freshness_boundary',
      vehicleId: 'vehicle_1',
      profile: TripTrackingProfile.roadVehicle,
      startedAt: start,
    );
    expect(await controller.startNativeTracking(allowBackground: true), isTrue);

    now = now.add(const Duration(minutes: 2));
    native.addStatus('tracking');
    await drainNativeTripEventsUntil(
      () => controller.platformStatus == 'tracking',
    );

    expect(controller.lifecycleState, TripTrackingSessionLifecycleState.active);
    expect(controller.healthState, TripTrackingHealthState.healthy);
    expect(controller.platformError, isNull);
  });

  test(
    'native critical battery stop keeps the actionable battery status',
    () async {
      final native = _FakeTripTrackingPlatform();
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
        platform: native,
      );
      addTearDown(controller.dispose);

      await controller.start(
        tripId: 'trip_native_critical_battery',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      expect(
        await controller.startNativeTracking(allowBackground: true),
        isTrue,
      );

      native.addPlatformError(
        code: 'trip_tracking_battery_critical',
        message: 'Battery is critically low.',
      );
      // Android emits a final stopped status from service teardown after the
      // critical-battery error. That ordinary lifecycle event must not erase the
      // actionable battery explanation the driver needs to see.
      native.addStatus('stopped');
      await drainNativeTripEventsUntil(() => !controller.nativeTracking);

      expect(controller.isTracking, isTrue);
      expect(controller.nativeTracking, isFalse);
      expect(native.stopCalls, 1);
      expect(controller.platformStatus, 'battery_critical_gps_blocked');
      expect(controller.platformError, contains('critically low'));
    },
  );

  test(
    'critical battery reported during native startup prevents a false active state',
    () async {
      final startGate = Completer<void>();
      final native = _FakeTripTrackingPlatform(startDelay: startGate.future);
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
        platform: native,
      );
      addTearDown(controller.dispose);

      await controller.start(
        tripId: 'trip_startup_critical_battery',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      final starting = controller.startNativeTracking(allowBackground: true);
      await Future<void>.delayed(Duration.zero);
      native.addPlatformError(
        code: 'trip_tracking_battery_critical',
        message: 'Battery is critically low.',
      );
      native.addStatus('stopped');
      await Future<void>.delayed(Duration.zero);
      startGate.complete();

      expect(await starting, isFalse);
      expect(controller.isTracking, isTrue);
      expect(controller.nativeTracking, isFalse);
      expect(
        controller.lifecycleState,
        TripTrackingSessionLifecycleState.failedRecoverable,
      );
      expect(controller.platformStatus, 'battery_critical_gps_blocked');
      expect(controller.platformError, contains('critically low'));
    },
  );

  test(
    'critical battery startup error survives a native false start result',
    () async {
      final startGate = Completer<void>();
      final native = _FakeTripTrackingPlatform(
        startDelay: startGate.future,
        startSucceeds: false,
      );
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
        platform: native,
      );
      addTearDown(controller.dispose);

      await controller.start(
        tripId: 'trip_startup_critical_false_result',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      final starting = controller.startNativeTracking(allowBackground: false);
      await Future<void>.delayed(Duration.zero);
      native.addPlatformError(
        code: 'trip_tracking_battery_critical',
        message: 'Battery is critically low.',
      );
      await Future<void>.delayed(Duration.zero);
      startGate.complete();

      expect(await starting, isFalse);
      expect(controller.nativeTracking, isFalse);
      expect(controller.platformStatus, 'battery_critical_gps_blocked');
      expect(controller.platformError, contains('critically low'));
    },
  );

  test(
    'runtime battery check pauses at the fifteen percent consent boundary',
    () async {
      final native = _FakeTripTrackingPlatform();
      var now = DateTime.utc(2026, 7, 12, 12);
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
        platform: native,
        clockNow: () => now,
      );
      addTearDown(controller.dispose);

      await controller.start(
        tripId: 'trip_runtime_low_battery_prompt',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      expect(
        await controller.startNativeTracking(allowBackground: false),
        isTrue,
      );

      native.batterySnapshot = const TripTrackingBatterySnapshot(
        batteryPercent: 15,
        isCharging: false,
        lowPowerModeEnabled: false,
      );
      now = now.add(const Duration(minutes: 6));
      native.addLocation(sample(-80, 0));
      await drainNativeTripEventsUntil(() => !controller.nativeTracking);

      expect(controller.isTracking, isTrue);
      expect(controller.nativeTracking, isFalse);
      expect(controller.platformStatus, 'low_battery_requires_user_choice');
      expect(controller.platformError, contains('Choose whether to continue'));
    },
  );

  test(
    'resume enforces critical battery before resuming background GPS',
    () async {
      final native = _FakeTripTrackingPlatform();
      var now = DateTime.utc(2026, 7, 12, 12);
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
        platform: native,
        clockNow: () => now,
      );
      addTearDown(controller.dispose);

      await controller.start(
        tripId: 'trip_resume_critical_battery',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      expect(
        await controller.startNativeTracking(allowBackground: true),
        isTrue,
      );

      native.batterySnapshot = const TripTrackingBatterySnapshot(
        batteryPercent: 9,
        isCharging: false,
        lowPowerModeEnabled: false,
      );
      now = now.add(const Duration(minutes: 6));
      await controller.handleAppLifecycleState(
        AppLifecycleState.resumed,
        backgroundTrackingAllowed: true,
      );

      expect(controller.isTracking, isTrue);
      expect(controller.nativeTracking, isFalse);
      expect(native.stopCalls, 1);
      expect(controller.platformStatus, 'battery_critical_gps_blocked');
    },
  );

  test(
    'background tracking requires explicit background authorization before native start',
    () async {
      final native = _FakeTripTrackingPlatform(
        authorization: const TripTrackingAuthorization(
          state: TripTrackingAuthorizationState.whileInUse,
          preciseLocation: true,
        ),
      );
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
        platform: native,
      );
      await controller.start(
        tripId: 'trip_background_permission_denied',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );

      expect(
        await controller.startNativeTracking(allowBackground: true),
        isFalse,
      );

      expect(native.requestAuthorizationCalls, 1);
      expect(native.startCalls, 0);
      expect(native.hasEventListener, isFalse);
      expect(
        controller.platformError,
        contains('Background location permission is required'),
      );
      expect(
        controller.lifecycleState,
        TripTrackingSessionLifecycleState.permissionRequired,
      );
      expect(controller.healthState, TripTrackingHealthState.permissionBlocked);
    },
  );

  test(
    'native start fails closed when background consent cannot persist',
    () async {
      var storageChecks = 0;
      final store = TripTrackingSessionStore.memory(
        storageCheck: () async {
          storageChecks += 1;
          final available = storageChecks == 3 ? 0 : 1024 * 1024;
          return AppStorageCheck(
            availableBytes: available,
            operationBytes: 1024,
            requiredBytes: 1024,
            purpose: AppStoragePurpose.mileageTracking,
          );
        },
      );
      final native = _FakeTripTrackingPlatform();
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
        platform: native,
      );
      await controller.start(
        tripId: 'trip_background_consent_storage_failure',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );

      expect(
        await controller.startNativeTracking(allowBackground: true),
        isFalse,
      );
      expect(native.requestAuthorizationCalls, 1);
      expect(native.startCalls, 0);
      expect(controller.nativeTracking, isFalse);
      expect(controller.platformStatus, 'storage_failed');
      expect(
        controller.platformError,
        contains('background tracking permission locally'),
      );
      expect(
        controller.lifecycleState,
        TripTrackingSessionLifecycleState.failedRecoverable,
      );
    },
  );

  test('native samples are serialized through the trip controller', () async {
    final native = _FakeTripTrackingPlatform();
    final odometer = GlobalOdometerController(initialReading: 1000);
    final nativeStart = DateTime.now().toUtc().subtract(
      const Duration(minutes: 4),
    );
    TripLocationSample nativeSample(double longitude, int seconds) =>
        TripLocationSample(
          latitude: 35,
          longitude: longitude,
          recordedAt: nativeStart.add(Duration(seconds: seconds)),
          horizontalAccuracyMeters: 5,
        );
    final controller = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      odometer: odometer,
      platform: native,
    );
    await controller.start(
      tripId: 'trip_native',
      vehicleId: 'vehicle_1',
      profile: TripTrackingProfile.roadVehicle,
      startedAt: nativeStart,
    );

    expect(
      await controller.startNativeTracking(allowBackground: false),
      isTrue,
    );
    native.addLocation(nativeSample(-80, 0));
    native.addLocation(nativeSample(-79.9998, 20));
    native.addLocation(nativeSample(-79.9996, 35));
    native.addLocation(nativeSample(-79.985, 150));
    await drainNativeTripEventsUntil(
      () => odometer.reading > 1000 && native.startedRequest != null,
    );

    expect(
      native.startedRequest?.sampling.interval,
      const Duration(seconds: 5),
    );
    expect(controller.acceptedMeters, greaterThan(0));
    expect(odometer.reading, greaterThan(1000));
    await controller.finishForReview();
    expect(native.stopCalls, 1);
  });

  test(
    'latest local review stays available after a trip is finished',
    () async {
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
      );
      await controller.start(
        tripId: 'trip_latest_review',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );

      final review = await controller.finishForReview(
        finishedAt: start.add(const Duration(minutes: 1)),
      );

      expect(review, isNotNull);
      expect(controller.latestReview?.id, 'trip_latest_review');
      expect(controller.latestUnconfirmedReview?.id, 'trip_latest_review');
      expect(
        await controller.confirmOdometerReview(
          reviewId: 'trip_latest_review',
          confirmedEndingOdometer: 1002,
          confirmedAt: start.add(const Duration(minutes: 2)),
        ),
        isTrue,
      );
      expect(controller.latestUnconfirmedReview, isNull);
      expect(controller.latestReview?.confirmedEndingOdometer, 1002);
      expect(
        await controller.confirmOdometerReview(
          reviewId: 'trip_latest_review',
          confirmedEndingOdometer: 1003,
          confirmedAt: start.add(const Duration(minutes: 3)),
        ),
        isFalse,
      );
      expect(controller.latestReview?.confirmedEndingOdometer, 1002);
      expect(
        await controller.start(
          tripId: 'trip_latest_review',
          vehicleId: 'vehicle_1',
          profile: TripTrackingProfile.roadVehicle,
        ),
        isFalse,
      );
      expect(controller.isTracking, isFalse);
    },
  );

  test('live odometer timestamps follow validated GPS sample time', () async {
    final odometer = GlobalOdometerController(
      vehicleId: 'vehicle_1',
      initialReading: 1000,
    );
    final controller = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      odometer: odometer,
    );

    expect(
      await controller.start(
        tripId: 'trip_live_odometer_sample_clock',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      ),
      isTrue,
    );
    expect(odometer.liveTripUpdatedAt, start);

    await controller.ingest(sample(-80, 0), referenceTime: start);
    await controller.ingest(
      sample(-79.985, 60),
      referenceTime: start.add(const Duration(seconds: 60)),
    );

    expect(odometer.reading, greaterThan(1000));
    expect(odometer.confirmedReading, 1000);
    expect(odometer.liveTripUpdatedAt, start.add(const Duration(seconds: 60)));
  });

  test(
    'finishing a trip drains queued native GPS events into the review',
    () async {
      final native = _FakeTripTrackingPlatform();
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(initialReading: 1000),
        platform: native,
      );
      await controller.start(
        tripId: 'trip_finish_drain',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      expect(
        await controller.startNativeTracking(allowBackground: false),
        isTrue,
      );

      native.addLocation(sample(-80, 0));
      native.addLocation(sample(-79.9998, 20));
      native.addLocation(sample(-79.985, 60));
      await Future<void>.delayed(Duration.zero);
      final review = await controller.finishForReview(
        finishedAt: start.add(const Duration(minutes: 2)),
      );

      expect(review, isNotNull);
      expect(review!.engineSnapshot.totalAcceptedMeters, greaterThan(0));
      expect(native.stopCalls, 1);
    },
  );

  test(
    'walking after driving creates review-only stop and resume advisories',
    () async {
      final store = TripTrackingSessionStore.memory();
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(initialReading: 1000),
      );
      await controller.start(
        tripId: 'trip_stop_assistance',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      TripActivityObservation activity(TripActivity type, int seconds) =>
          TripActivityObservation(
            activity: type,
            confidence: 90,
            recordedAt: start.add(Duration(seconds: seconds)),
          );

      await controller.ingest(
        sample(-80, 0),
        activity: activity(TripActivity.automotive, 0),
      );
      await controller.ingest(
        sample(-79.9997, 15),
        activity: activity(TripActivity.automotive, 15),
      );
      for (final seconds in [30, 45, 60]) {
        await controller.ingest(
          sample(-79.9997, seconds),
          activity: activity(TripActivity.walking, seconds),
        );
      }
      await controller.ingest(
        sample(-79.9994, 75),
        activity: activity(TripActivity.automotive, 75),
      );

      expect(controller.advisories.map((event) => event.type), [
        TripTrackingAdvisoryType.probableStop,
        TripTrackingAdvisoryType.resumedMovement,
      ]);
      expect(
        controller.advisories.every((event) => event.id.isNotEmpty),
        isTrue,
      );
      final probableStop = controller.advisories.first;
      expect(probableStop.sessionId, 'trip_stop_assistance');
      expect(probableStop.vehicleId, 'vehicle_1');
      expect(probableStop.profile, TripTrackingProfile.roadVehicle);
      expect(probableStop.confidence, TripTrackingConfidence.high);
      expect(probableStop.disposition, TripTrackingAdvisoryDisposition.pending);

      await controller.acknowledgeWalkingReview();
      expect(
        controller.advisories.first.disposition,
        TripTrackingAdvisoryDisposition.confirmed,
      );

      final restored = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
      );
      expect(await restored.restore(), isTrue);
      expect(restored.advisories.map((event) => event.type), [
        TripTrackingAdvisoryType.probableStop,
        TripTrackingAdvisoryType.resumedMovement,
      ]);
      expect(
        restored.advisories.first.disposition,
        TripTrackingAdvisoryDisposition.confirmed,
      );
    },
  );

  test(
    'traffic-like vehicle-only waiting does not create a stop advisory',
    () async {
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(initialReading: 1000),
      );
      await controller.start(
        tripId: 'trip_vehicle_only_stop_candidate',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.rideshareVehicle,
        startedAt: start,
      );
      TripActivityObservation automotive(int seconds) =>
          TripActivityObservation(
            activity: TripActivity.automotive,
            confidence: 90,
            recordedAt: start.add(Duration(seconds: seconds)),
          );

      await controller.ingest(sample(-80, 0), activity: automotive(0));
      await controller.ingest(sample(-79.9997, 15), activity: automotive(15));
      for (final seconds in [30, 60, 90, 135, 150]) {
        await controller.ingest(sample(-79.9997, seconds));
      }

      expect(controller.needsWalkingReview, isFalse);
      expect(controller.advisories, isEmpty);

      await controller.ingest(sample(-79.997, 170), activity: automotive(170));
      expect(controller.advisories, isEmpty);
    },
  );

  test(
    'traffic-like vehicle-only waiting stays advisory-free across recovery',
    () async {
      final store = TripTrackingSessionStore.memory();
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(initialReading: 1000),
      );
      await controller.start(
        tripId: 'trip_reviewed_vehicle_only_stop',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.rideshareVehicle,
        startedAt: start,
      );
      TripActivityObservation automotive(int seconds) =>
          TripActivityObservation(
            activity: TripActivity.automotive,
            confidence: 90,
            recordedAt: start.add(Duration(seconds: seconds)),
          );

      await controller.ingest(sample(-80, 0), activity: automotive(0));
      await controller.ingest(sample(-79.9997, 15), activity: automotive(15));
      for (final seconds in [30, 60, 90, 135]) {
        await controller.ingest(sample(-79.9997, seconds));
      }
      expect(controller.advisories, isEmpty);

      final restored = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
      );
      expect(await restored.restore(), isTrue);
      expect(restored.advisories, isEmpty);
      expect(restored.needsWalkingReview, isFalse);
    },
  );

  test(
    'walking confirmation creates a high-confidence stop after vehicle-only wait',
    () async {
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(initialReading: 1000),
      );
      await controller.start(
        tripId: 'trip_vehicle_stop_then_walk',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.rideshareVehicle,
        startedAt: start,
      );
      TripActivityObservation activity(TripActivity type, int seconds) =>
          TripActivityObservation(
            activity: type,
            confidence: 90,
            recordedAt: start.add(Duration(seconds: seconds)),
          );

      await controller.ingest(
        sample(-80, 0),
        activity: activity(TripActivity.automotive, 0),
      );
      await controller.ingest(
        sample(-79.9997, 15),
        activity: activity(TripActivity.automotive, 15),
      );
      for (final seconds in [30, 60, 90, 135]) {
        await controller.ingest(sample(-79.9997, seconds));
      }
      expect(controller.advisories, isEmpty);

      for (final seconds in [150, 165, 180, 195, 210]) {
        await controller.ingest(
          sample(-79.9997, seconds),
          activity: activity(TripActivity.walking, seconds),
        );
      }

      expect(controller.advisories, hasLength(1));
      expect(
        controller.advisories.single.confidence,
        TripTrackingConfidence.high,
      );
      expect(
        controller.advisories.single.evidenceStartedAt,
        start.add(const Duration(seconds: 30)),
      );
      expect(
        controller.advisories.single.evidenceEndedAt,
        start.add(const Duration(seconds: 210)),
      );
      expect(controller.needsWalkingReview, isTrue);
    },
  );

  test(
    'traffic-like vehicle-only waiting cannot create a rejected stop record',
    () async {
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(initialReading: 1000),
      );
      await controller.start(
        tripId: 'trip_rejected_vehicle_stop',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.rideshareVehicle,
        startedAt: start,
      );
      TripActivityObservation automotive(int seconds) =>
          TripActivityObservation(
            activity: TripActivity.automotive,
            confidence: 90,
            recordedAt: start.add(Duration(seconds: seconds)),
          );

      await controller.ingest(sample(-80, 0), activity: automotive(0));
      await controller.ingest(sample(-79.9997, 15), activity: automotive(15));
      for (final seconds in [30, 60, 90, 135]) {
        await controller.ingest(sample(-79.9997, seconds));
      }
      expect(controller.advisories, isEmpty);
      await controller.ingest(sample(-79.997, 170), activity: automotive(170));

      expect(controller.advisories, isEmpty);
    },
  );

  test(
    'dismissed walking stop review clears the walking review state',
    () async {
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(initialReading: 1000),
      );
      await controller.start(
        tripId: 'trip_dismissed_walking_stop',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.deliveryVehicle,
        startedAt: start,
      );
      TripActivityObservation activity(TripActivity type, int seconds) =>
          TripActivityObservation(
            activity: type,
            confidence: 90,
            recordedAt: start.add(Duration(seconds: seconds)),
          );

      await controller.ingest(
        sample(-80, 0),
        activity: activity(TripActivity.automotive, 0),
      );
      await controller.ingest(
        sample(-79.9997, 15),
        activity: activity(TripActivity.automotive, 15),
      );
      for (final seconds in [30, 45, 60]) {
        await controller.ingest(
          sample(-79.9997, seconds),
          activity: activity(TripActivity.walking, seconds),
        );
      }
      expect(controller.needsWalkingReview, isTrue);

      await controller.reviewLatestStopAdvisory(
        TripTrackingAdvisoryDisposition.dismissed,
      );

      expect(controller.needsWalkingReview, isFalse);
      expect(
        controller.advisories.single.disposition,
        TripTrackingAdvisoryDisposition.dismissed,
      );
    },
  );

  test('overlapping native start and stop requests are serialized', () async {
    final startGate = Completer<void>();
    final native = _FakeTripTrackingPlatform(startDelay: startGate.future);
    final controller = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      odometer: GlobalOdometerController(initialReading: 1000),
      platform: native,
    );
    await controller.start(
      tripId: 'trip_lifecycle_race',
      vehicleId: 'vehicle_1',
      profile: TripTrackingProfile.roadVehicle,
      startedAt: start,
    );

    final firstStart = controller.startNativeTracking(allowBackground: false);
    final duplicateStart = controller.startNativeTracking(
      allowBackground: false,
    );
    final stop = controller.stopNativeTracking();
    startGate.complete();

    expect(await firstStart, isTrue);
    expect(await duplicateStart, isFalse);
    await stop;
    expect(native.startCalls, 1);
    expect(native.stopCalls, 1);
    expect(controller.nativeTracking, isFalse);
  });

  test(
    'backgrounding foreground-only tracking stops the native collector',
    () async {
      final native = _FakeTripTrackingPlatform();
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(initialReading: 1000),
        platform: native,
      );
      await controller.start(
        tripId: 'trip_lifecycle',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: DateTime.utc(2025),
      );
      expect(
        await controller.startNativeTracking(allowBackground: false),
        isTrue,
      );

      await controller.handleAppLifecycleState(
        AppLifecycleState.paused,
        backgroundTrackingAllowed: false,
      );

      expect(native.stopCalls, 1);
      expect(controller.nativeTracking, isFalse);
      expect(
        controller.lifecycleState,
        TripTrackingSessionLifecycleState.paused,
      );
    },
  );

  test(
    'native subscription cancel failure still clears GPS tracking state',
    () async {
      final native = _FakeTripTrackingPlatform(throwOnCancel: true);
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(initialReading: 1000),
        platform: native,
      );
      await controller.start(
        tripId: 'trip_cancel_fault',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      await controller.startNativeTracking(allowBackground: false);

      await controller.stopNativeTracking();

      expect(native.stopCalls, 1);
      expect(controller.nativeTracking, isFalse);
      expect(
        controller.platformError,
        'Could not detach GPS event listener cleanly.',
      );
      expect(
        controller.lifecycleState,
        TripTrackingSessionLifecycleState.paused,
      );
    },
  );

  test(
    'a stale UI background preference cannot keep foreground GPS running',
    () async {
      final native = _FakeTripTrackingPlatform();
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(initialReading: 1000),
        platform: native,
      );
      await controller.start(
        tripId: 'trip_stale_background_preference',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      expect(
        await controller.startNativeTracking(allowBackground: false),
        isTrue,
      );

      await controller.handleAppLifecycleState(
        AppLifecycleState.paused,
        backgroundTrackingAllowed: true,
      );

      expect(native.stopCalls, 1);
      expect(controller.nativeTracking, isFalse);
      expect(
        controller.lifecycleState,
        TripTrackingSessionLifecycleState.paused,
      );
    },
  );

  test(
    'backgrounding during foreground-only startup stops GPS after it starts',
    () async {
      final startGate = Completer<void>();
      final native = _FakeTripTrackingPlatform(startDelay: startGate.future);
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(initialReading: 1000),
        platform: native,
      );
      await controller.start(
        tripId: 'trip_lifecycle_start_race',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );

      final nativeStart = controller.startNativeTracking(
        allowBackground: false,
      );
      final backgrounded = controller.handleAppLifecycleState(
        AppLifecycleState.paused,
        backgroundTrackingAllowed: false,
      );
      startGate.complete();

      expect(await nativeStart, isTrue);
      await backgrounded;
      expect(native.startCalls, 1);
      expect(native.stopCalls, 1);
      expect(controller.nativeTracking, isFalse);
    },
  );

  test(
    'background-enabled tracking is not stopped by app lifecycle changes',
    () async {
      final native = _FakeTripTrackingPlatform();
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(initialReading: 1000),
        platform: native,
      );
      await controller.start(
        tripId: 'trip_background_lifecycle',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: DateTime.utc(2025),
      );
      expect(
        await controller.startNativeTracking(allowBackground: true),
        isTrue,
      );

      await controller.handleAppLifecycleState(
        AppLifecycleState.paused,
        backgroundTrackingAllowed: true,
      );

      expect(native.stopCalls, isZero);
      expect(controller.nativeTracking, isTrue);
    },
  );

  test('foreground-only tracking stops when the app becomes hidden', () async {
    final native = _FakeTripTrackingPlatform();
    final controller = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      odometer: GlobalOdometerController(initialReading: 1000),
      platform: native,
    );
    await controller.start(
      tripId: 'trip_hidden_foreground_only',
      vehicleId: 'vehicle_1',
      profile: TripTrackingProfile.roadVehicle,
      startedAt: DateTime.utc(2025),
    );
    expect(
      await controller.startNativeTracking(allowBackground: false),
      isTrue,
    );

    await controller.handleAppLifecycleState(
      AppLifecycleState.hidden,
      backgroundTrackingAllowed: false,
    );

    expect(native.stopCalls, 1);
    expect(controller.nativeTracking, isFalse);
    expect(controller.lifecycleState, TripTrackingSessionLifecycleState.paused);
  });

  test(
    'a native GPS stream error stops tracking and leaves a retryable trip',
    () async {
      final native = _FakeTripTrackingPlatform();
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(initialReading: 1000),
        platform: native,
      );
      await controller.start(
        tripId: 'trip_stream_error',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      expect(
        await controller.startNativeTracking(allowBackground: false),
        isTrue,
      );

      native.addError(StateError('location provider disconnected'));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(controller.isTracking, isTrue);
      expect(controller.nativeTracking, isFalse);
      expect(
        controller.lifecycleState,
        TripTrackingSessionLifecycleState.interrupted,
      );
      expect(controller.healthState, TripTrackingHealthState.interrupted);
      expect(
        controller.platformError,
        contains('updates stopped unexpectedly'),
      );
      expect(native.stopCalls, 1);
      expect(
        await controller.startNativeTracking(allowBackground: false),
        isTrue,
      );
    },
  );

  test(
    'native GPS event processing failures do not expose raw errors',
    () async {
      var storageAvailable = true;
      final native = _FakeTripTrackingPlatform();
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(
          storageCheck: () async => AppStorageCheck(
            purpose: AppStoragePurpose.mileageTracking,
            availableBytes: storageAvailable ? 1024 * 1024 * 1024 : 1,
            operationBytes: 1024,
            requiredBytes: 1024,
          ),
        ),
        odometer: GlobalOdometerController(initialReading: 1000),
        platform: native,
      );
      await controller.start(
        tripId: 'trip_processing_error',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      expect(
        await controller.startNativeTracking(allowBackground: false),
        isTrue,
      );

      storageAvailable = false;
      native.addLocation(sample(-79.999, 70, speed: 8));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(
        controller.platformError,
        'GPS event could not be processed safely.',
      );
      expect(controller.platformError, isNot(contains('available')));
    },
  );

  test(
    'malformed native payload events are ignored without stopping GPS',
    () async {
      final native = _FakeTripTrackingPlatform();
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(initialReading: 1000),
        platform: native,
      );
      await controller.start(
        tripId: 'trip_malformed_native_payload',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      expect(
        await controller.startNativeTracking(allowBackground: false),
        isTrue,
      );

      native.addMalformedPayload();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(controller.isTracking, isTrue);
      expect(controller.nativeTracking, isTrue);
      expect(controller.platformStatus, 'tracking');
      expect(controller.platformError, isNull);
    },
  );

  test('a fatal native platform error interrupts and stops tracking', () async {
    final native = _FakeTripTrackingPlatform();
    final controller = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      odometer: GlobalOdometerController(initialReading: 1000),
      platform: native,
    );
    await controller.start(
      tripId: 'trip_platform_error',
      vehicleId: 'vehicle_1',
      profile: TripTrackingProfile.roadVehicle,
      startedAt: start,
    );
    expect(
      await controller.startNativeTracking(allowBackground: false),
      isTrue,
    );

    native.addPlatformError(
      code: 'trip_tracking_location_registration_failed',
      message: 'Android could not register GPS updates.',
    );
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(controller.nativeTracking, isFalse);
    expect(
      controller.lifecycleState,
      TripTrackingSessionLifecycleState.interrupted,
    );
    expect(controller.platformError, contains('could not be registered'));
    expect(native.stopCalls, 1);
  });

  test(
    'a terminal Core Location failure preserves a recoverable local trip',
    () async {
      final native = _FakeTripTrackingPlatform();
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(initialReading: 1000),
        platform: native,
      );
      await controller.start(
        tripId: 'trip_core_location_error',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      expect(
        await controller.startNativeTracking(allowBackground: false),
        isTrue,
      );

      native.addPlatformError(
        code: 'trip_tracking_location_error',
        message: 'Core Location could not continue trip tracking.',
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(controller.isTracking, isTrue);
      expect(controller.nativeTracking, isFalse);
      expect(
        controller.lifecycleState,
        TripTrackingSessionLifecycleState.interrupted,
      );
      expect(
        controller.platformError,
        'The device could not continue GPS trip tracking.',
      );
      expect(native.stopCalls, 1);
    },
  );

  test(
    'native platform errors do not surface raw tokens or coordinates',
    () async {
      final native = _FakeTripTrackingPlatform();
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(initialReading: 1000),
        platform: native,
      );
      await controller.start(
        tripId: 'trip_platform_error_redaction',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      expect(
        await controller.startNativeTracking(allowBackground: false),
        isTrue,
      );

      native.addPlatformError(
        code: 'upstream_raw_error',
        message: 'token=pk.secret lat=35.123 lon=-80.456',
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(controller.platformError, 'GPS reported a device error.');
      expect(controller.platformError, isNot(contains('pk.secret')));
      expect(controller.platformError, isNot(contains('35.123')));
      expect(controller.platformError, isNot(contains('-80.456')));
      expect(controller.isTracking, isTrue);
      expect(controller.nativeTracking, isTrue);
    },
  );

  test(
    'a native stopped event after a fatal error stays interrupted',
    () async {
      final native = _FakeTripTrackingPlatform();
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(initialReading: 1000),
        platform: native,
      );
      await controller.start(
        tripId: 'trip_fatal_then_stopped',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      expect(
        await controller.startNativeTracking(allowBackground: false),
        isTrue,
      );

      native.addPlatformError(
        code: 'trip_tracking_gps_disabled',
        message: 'GPS was turned off while tracking.',
      );
      native.addStatus('stopped');
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(
        controller.lifecycleState,
        TripTrackingSessionLifecycleState.interrupted,
      );
      expect(controller.healthState, TripTrackingHealthState.interrupted);
    },
  );

  test(
    'a late fatal platform error cannot interrupt a manually paused trip',
    () async {
      final native = _FakeTripTrackingPlatform();
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(initialReading: 1000),
        platform: native,
      );
      await controller.start(
        tripId: 'trip_late_platform_error',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      expect(
        await controller.startNativeTracking(allowBackground: false),
        isTrue,
      );
      await controller.stopNativeTracking();

      native.addPlatformError(
        code: 'trip_tracking_location_registration_failed',
        message: 'Late native error.',
      );
      await Future<void>.delayed(Duration.zero);

      expect(
        controller.lifecycleState,
        TripTrackingSessionLifecycleState.paused,
      );
      expect(native.stopCalls, 1);
    },
  );

  test(
    'motion-assistance loss keeps GPS active and clears persisted sensor consent',
    () async {
      final native = _FakeTripTrackingPlatform(
        activityRecognitionAvailable: true,
      );
      final store = TripTrackingSessionStore.memory();
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(initialReading: 1000),
        platform: native,
      );
      await controller.start(
        tripId: 'trip_activity_assistance_lost',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.deliveryVehicle,
        startedAt: start,
      );
      expect(
        await controller.startNativeTracking(
          allowBackground: false,
          activityRecognitionEnabled: true,
        ),
        isTrue,
      );
      expect(store.activeSession?.activityRecognitionEnabled, isTrue);

      native.addPlatformError(
        code: 'trip_tracking_activity_unavailable',
        message: 'Motion permission was removed.',
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(
        controller.lifecycleState,
        TripTrackingSessionLifecycleState.active,
      );
      expect(controller.nativeTracking, isTrue);
      expect(store.activeSession?.activityRecognitionEnabled, isFalse);
      expect(native.stopCalls, 0);
    },
  );

  test(
    'late motion-assistance loss cannot alter a stopped trip preference',
    () async {
      final native = _FakeTripTrackingPlatform(
        activityRecognitionAvailable: true,
      );
      final store = TripTrackingSessionStore.memory();
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(initialReading: 1000),
        platform: native,
      );
      await controller.start(
        tripId: 'trip_late_activity_assistance_loss',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.deliveryVehicle,
        startedAt: start,
      );
      expect(
        await controller.startNativeTracking(
          allowBackground: false,
          activityRecognitionEnabled: true,
        ),
        isTrue,
      );
      await controller.stopNativeTracking();

      native.addPlatformError(
        code: 'trip_tracking_activity_unavailable',
        message: 'Late motion provider error.',
      );
      await Future<void>.delayed(Duration.zero);

      expect(store.activeSession?.activityRecognitionEnabled, isTrue);
      expect(native.stopCalls, 1);
    },
  );

  test(
    'motion-assistance loss stops GPS when withdrawn sensor consent cannot persist',
    () async {
      final native = _FakeTripTrackingPlatform(
        activityRecognitionAvailable: true,
      );
      final store = _FailingNextSessionSaveStore();
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(initialReading: 1000),
        platform: native,
      );
      await controller.start(
        tripId: 'trip_activity_assistance_persist_failure',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.deliveryVehicle,
        startedAt: start,
      );
      expect(
        await controller.startNativeTracking(
          allowBackground: false,
          activityRecognitionEnabled: true,
        ),
        isTrue,
      );
      store.failNextSessionSave = true;

      native.addPlatformError(
        code: 'trip_tracking_activity_unavailable',
        message: 'Motion permission was removed.',
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(controller.nativeTracking, isFalse);
      expect(native.stopCalls, 1);
      expect(controller.platformError, contains('could not be saved locally'));
    },
  );

  test(
    'motion-assistance loss queued during a stop cannot alter trip preference',
    () async {
      final native = _FakeTripTrackingPlatform(
        activityRecognitionAvailable: true,
      );
      final store = TripTrackingSessionStore.memory();
      native.beforeStop = () => native.addPlatformError(
        code: 'trip_tracking_activity_unavailable',
        message: 'Motion provider ended with the collector.',
      );
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(initialReading: 1000),
        platform: native,
      );
      await controller.start(
        tripId: 'trip_stopping_activity_assistance_loss',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.deliveryVehicle,
        startedAt: start,
      );
      expect(
        await controller.startNativeTracking(
          allowBackground: false,
          activityRecognitionEnabled: true,
        ),
        isTrue,
      );

      await controller.stopNativeTracking();

      expect(store.activeSession?.activityRecognitionEnabled, isTrue);
      expect(native.stopCalls, 1);
    },
  );

  test(
    'motion-assistance loss during native startup keeps GPS and retires walking',
    () async {
      final native = _FakeTripTrackingPlatform(
        activityRecognitionAvailable: true,
        startDelay: Future<void>.delayed(Duration.zero),
      );
      native.beforeStart = () => native.addPlatformError(
        code: 'trip_tracking_activity_unavailable',
        message: 'Motion permission was unavailable at startup.',
      );
      final store = TripTrackingSessionStore.memory();
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(initialReading: 1000),
        platform: native,
      );
      await controller.start(
        tripId: 'trip_starting_activity_assistance_loss',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.deliveryVehicle,
        startedAt: start,
      );

      expect(
        await controller.startNativeTracking(
          allowBackground: false,
          activityRecognitionEnabled: true,
        ),
        isTrue,
      );

      expect(controller.nativeTracking, isTrue);
      expect(store.activeSession?.activityRecognitionEnabled, isFalse);
      expect(native.stopCalls, 0);
    },
  );

  test(
    'startup motion-assistance loss fails closed when withdrawal cannot persist',
    () async {
      final store = _FailingNextSessionSaveStore();
      final native = _FakeTripTrackingPlatform(
        activityRecognitionAvailable: true,
        startDelay: Future<void>.delayed(Duration.zero),
      );
      native.beforeStart = () {
        store.failNextSessionSave = true;
        native.addPlatformError(
          code: 'trip_tracking_activity_unavailable',
          message: 'Motion permission was unavailable at startup.',
        );
      };
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(initialReading: 1000),
        platform: native,
      );
      await controller.start(
        tripId: 'trip_starting_activity_assistance_persist_failure',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.deliveryVehicle,
        startedAt: start,
      );

      expect(
        await controller.startNativeTracking(
          allowBackground: false,
          activityRecognitionEnabled: true,
        ),
        isFalse,
      );

      expect(controller.nativeTracking, isFalse);
      expect(native.stopCalls, 1);
      expect(controller.platformError, contains('could not save'));
    },
  );

  test('native collector stop during startup fails closed', () async {
    final native = _FakeTripTrackingPlatform(
      startDelay: Future<void>.delayed(Duration.zero),
    );
    native.beforeStart = () => native.addStatus('stopped');
    final controller = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      odometer: GlobalOdometerController(initialReading: 1000),
      platform: native,
    );
    await controller.start(
      tripId: 'trip_native_start_stop',
      vehicleId: 'vehicle_1',
      profile: TripTrackingProfile.roadVehicle,
      startedAt: start,
    );

    expect(
      await controller.startNativeTracking(allowBackground: false),
      isFalse,
    );

    expect(controller.nativeTracking, isFalse);
    expect(native.stopCalls, 1);
    expect(controller.platformError, contains('stopped while trip tracking'));
  });

  test('location permission loss during native startup fails closed', () async {
    final native = _FakeTripTrackingPlatform(
      startDelay: Future<void>.delayed(Duration.zero),
    );
    native.beforeStart = () => native.addAuthorization(
      const TripTrackingAuthorization(
        state: TripTrackingAuthorizationState.denied,
        preciseLocation: false,
      ),
    );
    final controller = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      odometer: GlobalOdometerController(initialReading: 1000),
      platform: native,
    );
    await controller.start(
      tripId: 'trip_native_start_permission_loss',
      vehicleId: 'vehicle_1',
      profile: TripTrackingProfile.roadVehicle,
      startedAt: start,
    );

    expect(
      await controller.startNativeTracking(allowBackground: false),
      isFalse,
    );

    expect(controller.nativeTracking, isFalse);
    expect(native.stopCalls, 1);
    expect(
      controller.lifecycleState,
      TripTrackingSessionLifecycleState.failedRecoverable,
    );
    expect(controller.platformError, contains('permission was removed'));
  });

  test(
    'location permission revocation interrupts an active native trip',
    () async {
      final native = _FakeTripTrackingPlatform();
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(initialReading: 1000),
        platform: native,
      );
      await controller.start(
        tripId: 'trip_active_permission_loss',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      expect(
        await controller.startNativeTracking(allowBackground: true),
        isTrue,
      );

      native.addAuthorization(
        const TripTrackingAuthorization(
          state: TripTrackingAuthorizationState.denied,
          preciseLocation: false,
        ),
      );
      native.addAuthorization(
        const TripTrackingAuthorization(
          state: TripTrackingAuthorizationState.denied,
          preciseLocation: false,
        ),
      );
      await drainNativeTripEventsUntil(
        () => controller.nativeTracking == false,
        maxPumps: 48,
      );

      expect(controller.isTracking, isTrue);
      expect(
        controller.lifecycleState,
        TripTrackingSessionLifecycleState.interrupted,
      );
      expect(controller.healthState, TripTrackingHealthState.interrupted);
      expect(native.stopCalls, 1);
      expect(controller.platformError, contains('permission was removed'));
    },
  );

  test(
    'foreground tracking survives a background-only permission downgrade',
    () async {
      final native = _FakeTripTrackingPlatform();
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(initialReading: 1000),
        platform: native,
      );
      await controller.start(
        tripId: 'trip_foreground_permission_downgrade',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      expect(
        await controller.startNativeTracking(allowBackground: false),
        isTrue,
      );

      native.addAuthorization(
        const TripTrackingAuthorization(
          state: TripTrackingAuthorizationState.whileInUse,
          preciseLocation: true,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(controller.nativeTracking, isTrue);
      expect(
        controller.lifecycleState,
        TripTrackingSessionLifecycleState.active,
      );
      expect(native.stopCalls, isZero);
    },
  );

  test(
    'background permission downgrade interrupts an active background trip',
    () async {
      final native = _FakeTripTrackingPlatform();
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(initialReading: 1000),
        platform: native,
      );
      await controller.start(
        tripId: 'trip_active_background_permission_loss',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      expect(
        await controller.startNativeTracking(allowBackground: true),
        isTrue,
      );

      native.addAuthorization(
        const TripTrackingAuthorization(
          state: TripTrackingAuthorizationState.whileInUse,
          preciseLocation: true,
        ),
      );
      await drainNativeTripEventsUntil(
        () => controller.nativeTracking == false,
        maxPumps: 48,
      );

      expect(controller.isTracking, isTrue);
      expect(
        controller.lifecycleState,
        TripTrackingSessionLifecycleState.interrupted,
      );
      expect(controller.healthState, TripTrackingHealthState.interrupted);
      expect(native.stopCalls, 1);
      expect(
        controller.platformError,
        contains('Background location permission'),
      );
    },
  );

  test('duplicate fatal platform errors issue one native stop', () async {
    final native = _FakeTripTrackingPlatform();
    final controller = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      odometer: GlobalOdometerController(initialReading: 1000),
      platform: native,
    );
    await controller.start(
      tripId: 'trip_duplicate_platform_error',
      vehicleId: 'vehicle_1',
      profile: TripTrackingProfile.roadVehicle,
      startedAt: start,
    );
    expect(
      await controller.startNativeTracking(allowBackground: false),
      isTrue,
    );

    native.addPlatformError(
      code: 'trip_tracking_location_registration_failed',
      message: 'First fatal error.',
    );
    native.addPlatformError(
      code: 'trip_tracking_location_registration_failed',
      message: 'Duplicate fatal error.',
    );
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(
      controller.lifecycleState,
      TripTrackingSessionLifecycleState.interrupted,
    );
    expect(native.stopCalls, 1);
  });

  test('a fixed sampling preset is not silently overridden', () async {
    final native = _FakeTripTrackingPlatform();
    final controller = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      odometer: GlobalOdometerController(initialReading: 1000),
      platform: native,
    );
    await controller.start(
      tripId: 'trip_fixed_sampling',
      vehicleId: 'vehicle_1',
      profile: TripTrackingProfile.roadVehicle,
      startedAt: start,
    );
    await controller.startNativeTracking(
      allowBackground: false,
      adaptiveSamplingEnabled: false,
      samplingOverride: const TripSamplingRecommendation(
        mode: TripSamplingMode.economy,
        interval: Duration(seconds: 60),
        minimumDisplacementMeters: 30,
      ),
    );
    native.addLocation(sample(-80, 0, speed: 8));
    native.addLocation(sample(-79.999, 20, speed: 8));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(
      native.startedRequest?.sampling.interval,
      const Duration(seconds: 60),
    );
    expect(native.updateCalls, 0);
  });

  test(
    'recovery preserves a poor-accuracy timestamp against stale GPS fixes',
    () async {
      final store = TripTrackingSessionStore.memory();
      final original = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(initialReading: 1000),
      );
      await original.start(
        tripId: 'trip_accuracy_recovery',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      await original.ingest(sample(-80, 0));
      await original.ingest(sample(-79.99, 30, accuracy: 120));

      final recovered = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
      );
      expect(await recovered.restore(), isTrue);
      final stale = await recovered.ingest(sample(-79.9998, 20));

      expect(stale?.disposition, TripSampleDisposition.rejectedOutOfOrder);
      expect(recovered.acceptedMeters, 0);
    },
  );

  test('recovery replays one durable in-flight GPS sample', () async {
    final store = TripTrackingSessionStore.memory();
    final original = TripTrackingController(
      sessionStore: store,
      odometer: GlobalOdometerController(initialReading: 1000),
    );
    await original.start(
      tripId: 'trip_pending_replay',
      vehicleId: 'vehicle_1',
      profile: TripTrackingProfile.roadVehicle,
      startedAt: start,
    );
    await original.ingest(sample(-80, 0));
    await store.savePending(
      TripTrackingPendingSample(
        sessionId: 'trip_pending_replay',
        sample: sample(-79.98, 90),
      ),
    );

    final recoveredOdometer = GlobalOdometerController(
      vehicleId: 'vehicle_1',
      initialReading: 1000,
    );
    final recovered = TripTrackingController(
      sessionStore: store,
      odometer: recoveredOdometer,
    );
    expect(await recovered.restore(), isTrue);
    expect(recovered.acceptedMeters, greaterThan(10));
    expect(recoveredOdometer.reading, greaterThan(1000));
    expect(recoveredOdometer.confirmedReading, 1000);
    expect(store.pendingSampleFor('trip_pending_replay'), isNull);
  });

  test('recovery survives a failed pending GPS sample replay write', () async {
    var storageAvailable = true;
    final store = TripTrackingSessionStore.memory(
      storageCheck: () async => AppStorageCheck(
        availableBytes: storageAvailable
            ? AppStorageGuard.mileageTrackingWriteBytes
            : 0,
        operationBytes: AppStorageGuard.mileageTrackingWriteBytes,
        requiredBytes: AppStorageGuard.mileageTrackingWriteBytes,
        purpose: AppStoragePurpose.mileageTracking,
      ),
    );
    final original = TripTrackingController(
      sessionStore: store,
      odometer: GlobalOdometerController(initialReading: 1000),
    );
    await original.start(
      tripId: 'trip_pending_replay_storage_full',
      vehicleId: 'vehicle_1',
      profile: TripTrackingProfile.roadVehicle,
      startedAt: start,
    );
    await original.ingest(sample(-80, 0));
    await store.savePending(
      TripTrackingPendingSample(
        sessionId: 'trip_pending_replay_storage_full',
        sample: sample(-79.98, 90),
      ),
    );
    storageAvailable = false;
    final recovered = TripTrackingController(
      sessionStore: store,
      odometer: GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      ),
    );

    expect(await recovered.restore(), isTrue);
    expect(recovered.isTracking, isTrue);
    expect(recovered.platformStatus, 'pending_replay_failed');
    expect(
      store.pendingSampleFor('trip_pending_replay_storage_full'),
      isNotNull,
    );
  });

  test('recovery clears stale pending samples that cannot replay', () async {
    final store = TripTrackingSessionStore.memory();
    final original = TripTrackingController(
      sessionStore: store,
      odometer: GlobalOdometerController(initialReading: 1000),
    );
    await original.start(
      tripId: 'trip_stale_pending_replay',
      vehicleId: 'vehicle_1',
      profile: TripTrackingProfile.roadVehicle,
      startedAt: start,
    );
    await store.savePending(
      TripTrackingPendingSample(
        sessionId: 'trip_stale_pending_replay',
        sample: sample(-80, -10),
      ),
    );

    final recovered = TripTrackingController(
      sessionStore: store,
      odometer: GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      ),
    );

    expect(await recovered.restore(), isTrue);
    expect(store.pendingSampleFor('trip_stale_pending_replay'), isNull);
    expect(recovered.acceptedMeters, 0);
    expect(recovered.isTracking, isTrue);
  });

  test(
    'recovery ignores malformed pending samples without moving odometer',
    () async {
      final store = await _storeWithRawTripTrackingData(
        tempPrefix: 'trip_tracking_malformed_pending_',
        activeSession: {
          'id': 'trip_malformed_pending_replay',
          'vehicleId': 'vehicle_1',
          'startingOdometer': 1000,
          'profile': 'roadVehicle',
          'startedAt': start.toIso8601String(),
          'updatedAt': start.toIso8601String(),
          'engineSnapshot': const TripTrackingEngineSnapshot(
            totalAcceptedMeters: 0,
            walkingReviewSuggested: false,
          ).toMap(),
        },
        pending: {
          'sessionId': 'trip_malformed_pending_replay',
          'sample': {
            'latitude': 35,
            'longitude': -80,
            'recordedAt': start.add(const Duration(hours: 2)).toIso8601String(),
            'horizontalAccuracyMeters': 5,
          },
          'activity': {
            'activity': 'walking',
            'confidence': 95,
            'recordedAt': start.toIso8601String(),
          },
        },
      );

      final odometer = GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      );
      final recovered = TripTrackingController(
        sessionStore: store,
        odometer: odometer,
      );

      expect(await recovered.restore(), isTrue);
      expect(store.pendingSampleFor('trip_malformed_pending_replay'), isNull);
      expect(recovered.acceptedMeters, 0);
      expect(odometer.confirmedReading, 1000);
      expect(odometer.reading, 1000);
    },
  );

  test(
    'GPS health degrades on poor fixes and recovers only on credible data',
    () async {
      final native = _FakeTripTrackingPlatform();
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(initialReading: 1000),
        platform: native,
      );
      await controller.start(
        tripId: 'trip_health',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      expect(
        await controller.startNativeTracking(allowBackground: false),
        isTrue,
      );

      await controller.ingest(sample(-80, 0));
      await controller.ingest(sample(-79.999, 15, accuracy: 120));
      expect(
        controller.lifecycleState,
        TripTrackingSessionLifecycleState.degraded,
      );
      expect(controller.healthState, TripTrackingHealthState.poor);

      await controller.ingest(sample(-79.9998, 30));
      expect(
        controller.lifecycleState,
        TripTrackingSessionLifecycleState.active,
      );
      expect(controller.healthState, TripTrackingHealthState.healthy);
    },
  );

  test(
    'recovery preserves an implausible-jump reanchor against stale fixes',
    () async {
      final store = TripTrackingSessionStore.memory();
      final original = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(initialReading: 1000),
      );
      await original.start(
        tripId: 'trip_jump_recovery',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      await original.ingest(sample(-80, 0));
      await original.ingest(sample(-79.99, 2));

      final recovered = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
      );
      expect(await recovered.restore(), isTrue);
      final stale = await recovered.ingest(sample(-79.9998, 1));

      expect(stale?.disposition, TripSampleDisposition.rejectedOutOfOrder);
      expect(recovered.acceptedMeters, 0);
    },
  );

  test(
    'recovery preserves a drift timestamp against stale GPS fixes',
    () async {
      final store = TripTrackingSessionStore.memory();
      final original = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(initialReading: 1000),
      );
      await original.start(
        tripId: 'trip_drift_recovery',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      await original.ingest(sample(-80, 0));
      await original.ingest(sample(-79.99996, 30));

      final recovered = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
      );
      expect(await recovered.restore(), isTrue);
      final stale = await recovered.ingest(sample(-79.9998, 20));

      expect(stale?.disposition, TripSampleDisposition.rejectedOutOfOrder);
      expect(recovered.acceptedMeters, 0);
    },
  );

  test('controller rejects replayed samples before pending storage', () async {
    final store = TripTrackingSessionStore.memory();
    final controller = TripTrackingController(
      sessionStore: store,
      odometer: GlobalOdometerController(initialReading: 1000),
    );
    await controller.start(
      tripId: 'trip_replay_pre_save',
      vehicleId: 'vehicle_1',
      profile: TripTrackingProfile.roadVehicle,
      startedAt: start,
    );

    final first = await controller.ingest(sample(-80, 0));
    final second = await controller.ingest(sample(-79.999, 30));
    final replay = await controller.ingest(sample(-79.9995, 20));

    expect(first?.accepted, isTrue);
    expect(second?.accepted, isTrue);
    expect(replay?.disposition, TripSampleDisposition.rejectedOutOfOrder);
    expect(store.pendingSampleFor('trip_replay_pre_save'), isNull);
    expect(
      store.activeSession?.updatedAt,
      start.add(const Duration(seconds: 30)),
    );
    expect(
      store.activeSession?.engineSnapshot.lastObservedAt,
      start.add(const Duration(seconds: 30)),
    );
    expect(controller.acceptedMeters, greaterThan(0));
  });

  test(
    'duplicate native timestamps cannot overwrite pending recovery sample',
    () async {
      final store = TripTrackingSessionStore.memory();
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(initialReading: 1000),
      );
      await controller.start(
        tripId: 'trip_duplicate_pre_save',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );

      final first = await controller.ingest(sample(-80, 0));
      final duplicate = await controller.ingest(sample(-79.9999, 0));

      expect(first?.accepted, isTrue);
      expect(duplicate?.disposition, TripSampleDisposition.rejectedOutOfOrder);
      expect(store.pendingSampleFor('trip_duplicate_pre_save'), isNull);
      expect(store.activeSession?.updatedAt, start);
      expect(store.activeSession?.engineSnapshot.lastAccepted?.longitude, -80);
    },
  );

  test(
    'a closed native GPS stream stops tracking instead of leaving it stuck',
    () async {
      final native = _FakeTripTrackingPlatform();
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(initialReading: 1000),
        platform: native,
      );
      await controller.start(
        tripId: 'trip_stream_closed',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      expect(
        await controller.startNativeTracking(allowBackground: false),
        isTrue,
      );

      await native.closeEvents();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(controller.isTracking, isTrue);
      expect(controller.nativeTracking, isFalse);
      expect(controller.platformError, 'GPS updates ended unexpectedly.');
      expect(native.stopCalls, 1);
    },
  );

  test(
    'an externally stopped native collector detaches before a retry',
    () async {
      final native = _FakeTripTrackingPlatform();
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(initialReading: 1000),
        platform: native,
      );
      await controller.start(
        tripId: 'trip_external_stop',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      await controller.startNativeTracking(allowBackground: false);

      native.addStatus('stopped');
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(controller.nativeTracking, isFalse);
      expect(native.hasEventListener, isFalse);
      expect(
        controller.lifecycleState,
        TripTrackingSessionLifecycleState.interrupted,
      );
      expect(controller.healthState, TripTrackingHealthState.interrupted);
      expect(controller.platformStatus, 'interrupted');
      expect(
        controller.platformError,
        'GPS updates stopped unexpectedly. Your local trip is preserved for review.',
      );
      expect(
        await controller.startNativeTracking(allowBackground: false),
        isTrue,
      );
      expect(native.startCalls, 2);
    },
  );

  test(
    'an externally stopped native collector tolerates listener cancel failure',
    () async {
      final native = _FakeTripTrackingPlatform(throwOnCancel: true);
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(initialReading: 1000),
        platform: native,
      );
      await controller.start(
        tripId: 'trip_external_stop_cancel_fault',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      await controller.startNativeTracking(allowBackground: false);

      native.addStatus('stopped');
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(controller.nativeTracking, isFalse);
      expect(native.stopCalls, 0);
      expect(controller.platformStatus, 'interrupted');
      expect(
        controller.platformError,
        'GPS updates stopped unexpectedly. Your local trip is preserved for review.',
      );

      native.addLocation(sample(-80, 0, speed: 8));
      native.addLocation(sample(-79.99, 60, speed: 8));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(controller.acceptedMeters, 0);
      expect(controller.nativeTracking, isFalse);
    },
  );

  test(
    'an explicit native pause preserves the trip without an interruption',
    () async {
      final native = _FakeTripTrackingPlatform();
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(initialReading: 1000),
        platform: native,
      );
      await controller.start(
        tripId: 'trip_explicit_native_pause',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      await controller.startNativeTracking(allowBackground: false);

      native.addStatus('paused');
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(controller.isTracking, isTrue);
      expect(controller.nativeTracking, isFalse);
      expect(
        controller.lifecycleState,
        TripTrackingSessionLifecycleState.paused,
      );
      expect(
        controller.healthState,
        isNot(TripTrackingHealthState.interrupted),
      );
      expect(controller.platformStatus, 'paused');
      expect(controller.platformError, isNull);
    },
  );

  test(
    'malformed native status payload is ignored without stopping a valid trip',
    () async {
      final native = _FakeTripTrackingPlatform();
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(initialReading: 1000),
        platform: native,
      );
      await controller.start(
        tripId: 'trip_malformed_native_status',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      await controller.startNativeTracking(allowBackground: false);

      native.addRawEvent({'type': 'status', 'status': '../stopped'});
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(controller.isTracking, isTrue);
      expect(controller.nativeTracking, isTrue);
      expect(controller.platformError, isNull);
      expect(native.hasEventListener, isTrue);
      expect(native.stopCalls, 0);
    },
  );

  test(
    'native idle status is ignored while GPS is actively tracking',
    () async {
      final native = _FakeTripTrackingPlatform();
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(initialReading: 1000),
        platform: native,
      );
      await controller.start(
        tripId: 'trip_active_status_guard',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      await controller.startNativeTracking(allowBackground: false);
      expect(controller.platformStatus, 'tracking');

      native.addStatus('idle');
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(controller.platformStatus, 'tracking');
      expect(controller.isTracking, isTrue);
      expect(controller.nativeTracking, isTrue);
      expect(native.hasEventListener, isTrue);
      expect(native.stopCalls, 0);
    },
  );

  test(
    'disposing the controller stops collection without a durable Dart consumer',
    () async {
      final native = _FakeTripTrackingPlatform();
      final store = TripTrackingSessionStore.memory();
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(initialReading: 1000),
        platform: native,
      );
      await controller.start(
        tripId: 'trip_dispose',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      await controller.startNativeTracking(allowBackground: false);
      expect(native.hasEventListener, isTrue);

      controller.dispose();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(native.hasEventListener, isFalse);
      expect(native.stopCalls, 1);
      expect(await native.isTracking, isFalse);
      expect(
        store.activeSession?.lifecycleState,
        TripTrackingSessionLifecycleState.paused,
      );
    },
  );

  test(
    'a disposed controller rejects late GPS samples without notifying',
    () async {
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(initialReading: 1000),
      );
      await controller.start(
        tripId: 'trip_disposed_sample',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      controller.dispose();

      expect(await controller.ingest(sample(-80, 0)), isNull);
    },
  );

  test('a disposed controller cannot restart native GPS collection', () async {
    final native = _FakeTripTrackingPlatform();
    final controller = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      odometer: GlobalOdometerController(initialReading: 1000),
      platform: native,
    );
    await controller.start(
      tripId: 'trip_disposed_start',
      vehicleId: 'vehicle_1',
      profile: TripTrackingProfile.roadVehicle,
      startedAt: start,
    );
    controller.dispose();

    expect(
      await controller.startNativeTracking(allowBackground: false),
      isFalse,
    );
    expect(native.startCalls, 0);
  });

  test(
    'restoring a trip reattaches to a surviving native GPS collector',
    () async {
      final store = TripTrackingSessionStore.memory();
      final initial = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(initialReading: 1000),
      );
      await initial.start(
        tripId: 'trip_native_restore',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      await initial.ingest(sample(-80, 0, speed: 8));
      await store.save(
        store.activeSession!.copyWith(
          backgroundTrackingAllowed: true,
          activityRecognitionEnabled: true,
          nativeSampling: const TripSamplingRecommendation(
            mode: TripSamplingMode.balanced,
            interval: Duration(seconds: 5),
            minimumDisplacementMeters: 5,
          ),
        ),
      );

      final native = _FakeTripTrackingPlatform();
      await native.start(
        const TripTrackingNativeRequest(
          profile: TripTrackingProfile.roadVehicle,
          sampling: TripSamplingRecommendation(
            mode: TripSamplingMode.balanced,
            interval: Duration(seconds: 5),
            minimumDisplacementMeters: 5,
          ),
        ),
      );
      final restored = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
        platform: native,
      );

      expect(await restored.restore(), isTrue);
      expect(restored.nativeTracking, isTrue);
      for (final seconds in [20, 35, 50]) {
        native.addActivity(
          TripActivityObservation(
            activity: TripActivity.walking,
            confidence: 95,
            recordedAt: start.add(Duration(seconds: seconds)),
          ),
        );
        native.addLocation(sample(-80 + (seconds / 100000), seconds, speed: 1));
      }
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(restored.needsWalkingReview, isTrue);
      native.addActivity(
        TripActivityObservation(
          activity: TripActivity.automotive,
          confidence: 95,
          recordedAt: start.add(const Duration(seconds: 70)),
        ),
      );
      native.addLocation(sample(-79.999, 70, speed: 8));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(restored.acceptedMeters, greaterThan(0));
    },
  );

  test(
    'restore stops a surviving collector without durable background consent',
    () async {
      final store = TripTrackingSessionStore.memory();
      final initial = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(initialReading: 1000),
      );
      await initial.start(
        tripId: 'trip_restore_without_background_consent',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      final native = _FakeTripTrackingPlatform();
      await native.start(
        const TripTrackingNativeRequest(
          profile: TripTrackingProfile.roadVehicle,
          sampling: TripSamplingRecommendation(
            mode: TripSamplingMode.balanced,
            interval: Duration(seconds: 5),
            minimumDisplacementMeters: 5,
          ),
        ),
      );
      final restored = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
        platform: native,
      );

      expect(await restored.restore(), isTrue);
      expect(restored.nativeTracking, isFalse);
      expect(native.stopCalls, 1);
      expect(restored.platformStatus, 'background_consent_required');
      expect(restored.platformError, contains('not previously authorized'));
    },
  );

  test(
    'recovery preserves the driver-selected battery-saving sampling ceiling',
    () async {
      final store = TripTrackingSessionStore.memory();
      final native = _FakeTripTrackingPlatform();
      final initial = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(initialReading: 1000),
        platform: native,
      );
      await initial.start(
        tripId: 'trip_restore_sampling_ceiling',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      expect(
        await initial.startNativeTracking(
          allowBackground: true,
          samplingPreset: TripTrackingSamplingPreset.batterySaver,
          adaptiveSamplingEnabled: true,
          lowBatteryProtectionEnabled: false,
          lowBatteryOverrideEnabled: true,
          lowBatteryWarningDismissed: true,
        ),
        isTrue,
      );
      final restored = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
        platform: native,
      );

      expect(await restored.restore(), isTrue);
      native.addLocation(sample(-80, 20, speed: 8));
      native.addLocation(sample(-79.999, 40, speed: 8));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(restored.nativeTracking, isTrue);
      expect(native.updateCalls, 1);
      expect(
        store.activeSession?.nativeSampling?.interval,
        const Duration(seconds: 30),
      );
      expect(
        store.activeSession?.samplingCeiling?.interval,
        const Duration(seconds: 30),
      );
      expect(store.activeSession?.adaptiveSamplingEnabled, isTrue);
      expect(store.activeSession?.lowBatteryProtectionEnabled, isFalse);
    },
  );

  test(
    'native status recovery failure preserves the local recoverable trip',
    () async {
      final store = TripTrackingSessionStore.memory();
      final initial = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(initialReading: 1000),
      );
      await initial.start(
        tripId: 'trip_restore_status_fault',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      await initial.ingest(sample(-80, 0, speed: 8));

      final restored = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
        platform: _FakeTripTrackingPlatform(throwOnIsTracking: true),
      );

      expect(await restored.restore(), isTrue);
      expect(restored.isTracking, isTrue);
      expect(restored.nativeTracking, isFalse);
      expect(restored.platformError, contains('Could not restore the GPS'));
    },
  );

  test(
    'recovery applies the persisted battery safeguard before accepting GPS',
    () async {
      final store = TripTrackingSessionStore.memory();
      final initial = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(initialReading: 1000),
      );
      await initial.start(
        tripId: 'trip_restore_battery_guard',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      await store.save(
        store.activeSession!.copyWith(
          backgroundTrackingAllowed: true,
          nativeSampling: const TripSamplingRecommendation(
            mode: TripSamplingMode.balanced,
            interval: Duration(seconds: 15),
            minimumDisplacementMeters: 8,
          ),
          lowBatteryProtectionEnabled: true,
          lowBatteryWarningDismissed: true,
        ),
      );
      final native = _FakeTripTrackingPlatform(
        batterySnapshot: const TripTrackingBatterySnapshot(
          batteryPercent: 15,
          isCharging: false,
          lowPowerModeEnabled: false,
        ),
      );
      await native.start(
        const TripTrackingNativeRequest(
          profile: TripTrackingProfile.roadVehicle,
          sampling: TripSamplingRecommendation(
            mode: TripSamplingMode.balanced,
            interval: Duration(seconds: 15),
            minimumDisplacementMeters: 8,
          ),
          allowBackground: true,
        ),
      );
      final restored = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
        platform: native,
      );

      expect(await restored.restore(), isTrue);
      expect(restored.nativeTracking, isFalse);
      expect(native.stopCalls, 1);
      expect(
        restored.platformStatus,
        'low_battery_gps_blocked_by_saved_choice',
      );
      expect(restored.isTracking, isTrue);
    },
  );

  test(
    'recovery stops GPS when saved native settings cannot be reapplied',
    () async {
      final store = TripTrackingSessionStore.memory();
      final initial = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(initialReading: 1000),
      );
      await initial.start(
        tripId: 'trip_restore_native_reconfiguration',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      const sampling = TripSamplingRecommendation(
        mode: TripSamplingMode.balanced,
        interval: Duration(seconds: 15),
        minimumDisplacementMeters: 8,
      );
      await store.save(
        store.activeSession!.copyWith(
          backgroundTrackingAllowed: true,
          nativeSampling: sampling,
        ),
      );
      final native = _FakeTripTrackingPlatform(updateSucceeds: false);
      await native.start(
        const TripTrackingNativeRequest(
          profile: TripTrackingProfile.roadVehicle,
          sampling: sampling,
          allowBackground: true,
        ),
      );
      final restored = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
        platform: native,
      );

      expect(await restored.restore(), isTrue);
      expect(native.updateCalls, 1);
      expect(native.stopCalls, 1);
      expect(restored.nativeTracking, isFalse);
      expect(restored.platformStatus, 'native_reconfiguration_failed');
      expect(restored.platformError, contains('could not reapply'));
      expect(restored.isTracking, isTrue);
    },
  );

  test(
    'stopping native GPS preserves the recoverable trip for a later resume',
    () async {
      final native = _FakeTripTrackingPlatform();
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(initialReading: 1000),
        platform: native,
      );
      await controller.start(
        tripId: 'trip_pause_resume',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      expect(
        await controller.startNativeTracking(allowBackground: false),
        isTrue,
      );

      await controller.stopNativeTracking();

      expect(controller.isTracking, isTrue);
      expect(controller.nativeTracking, isFalse);
      expect(native.stopCalls, 1);
      expect(
        await controller.startNativeTracking(allowBackground: false),
        isTrue,
      );
      expect(native.startCalls, 2);
      expect(native.startedRequest?.profile, TripTrackingProfile.roadVehicle);
    },
  );

  test(
    'late location callbacks after native stop cannot change GPS mileage',
    () async {
      final native = _FakeTripTrackingPlatform();
      final odometer = GlobalOdometerController(initialReading: 1000);
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: odometer,
        platform: native,
      );
      await controller.start(
        tripId: 'trip_late_location_after_stop',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      expect(
        await controller.startNativeTracking(allowBackground: false),
        isTrue,
      );
      native.addLocation(sample(-80, 0, speed: 8));
      native.addLocation(sample(-79.999, 30, speed: 8));
      await drainNativeTripEventsUntil(
        () => controller.acceptedMeters > 0,
        maxPumps: 48,
      );
      final acceptedBeforeStop = controller.acceptedMeters;
      final projectedBeforeStop = odometer.reading;

      await controller.stopNativeTracking();
      native.addLocation(sample(-79.95, 60, speed: 20));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(controller.nativeTracking, isFalse);
      expect(controller.acceptedMeters, acceptedBeforeStop);
      expect(odometer.reading, projectedBeforeStop);
    },
  );

  test(
    'stale walking activity is cleared across native stop and restart',
    () async {
      final native = _FakeTripTrackingPlatform();
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(initialReading: 1000),
        platform: native,
      );
      await controller.start(
        tripId: 'trip_restart_clears_activity',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      await controller.startNativeTracking(
        allowBackground: false,
        activityRecognitionEnabled: true,
      );
      native.addActivity(
        TripActivityObservation(
          activity: TripActivity.walking,
          confidence: 95,
          recordedAt: start,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      await controller.stopNativeTracking();
      await controller.startNativeTracking(
        allowBackground: false,
        activityRecognitionEnabled: true,
      );
      native.addLocation(sample(-80, 30, speed: 8));
      native.addLocation(sample(-79.999, 50, speed: 8));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(controller.acceptedMeters, greaterThan(0));
      expect(controller.needsWalkingReview, isFalse);
    },
  );

  test(
    'native walking evidence suggests a real stop without ending the trip',
    () async {
      final native = _FakeTripTrackingPlatform(
        activityRecognitionAvailable: true,
      );
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(initialReading: 1000),
        platform: native,
      );
      await controller.start(
        tripId: 'trip_native_walking_stop_assistance',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      expect(
        await controller.startNativeTracking(
          allowBackground: false,
          activityRecognitionEnabled: true,
        ),
        isTrue,
      );

      native.addLocation(sample(-80, 0, speed: 8));
      native.addLocation(sample(-79.9997, 15, speed: 8));
      await drainNativeTripEventsUntil(
        () => controller.motionState == TripMotionState.moving,
        maxPumps: 48,
      );

      for (final seconds in [30, 45, 60]) {
        native.addActivity(
          TripActivityObservation(
            activity: TripActivity.walking,
            confidence: 95,
            recordedAt: start.add(Duration(seconds: seconds)),
          ),
        );
        native.addLocation(sample(-79.9997, seconds));
      }
      await drainNativeTripEventsUntil(
        () => controller.needsWalkingReview,
        maxPumps: 48,
      );

      expect(controller.motionState, TripMotionState.stopped);
      expect(controller.isTracking, isTrue);
      expect(controller.nativeTracking, isTrue);

      native.addActivity(
        TripActivityObservation(
          activity: TripActivity.automotive,
          confidence: 95,
          recordedAt: start.add(const Duration(seconds: 75)),
        ),
      );
      native.addLocation(sample(-79.9994, 75, speed: 8));
      await drainNativeTripEventsUntil(
        () => controller.motionState == TripMotionState.moving,
        maxPumps: 48,
      );

      expect(controller.motionState, TripMotionState.moving);
      expect(controller.isTracking, isTrue);
    },
  );

  test(
    'failed activity evidence checkpoint cannot influence a later GPS sample',
    () async {
      final native = _FakeTripTrackingPlatform(
        activityRecognitionAvailable: true,
      );
      final store = _FailingNextSessionSaveStore();
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(initialReading: 1000),
        platform: native,
      );
      await controller.start(
        tripId: 'trip_failed_activity_checkpoint',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      expect(
        await controller.startNativeTracking(
          allowBackground: false,
          activityRecognitionEnabled: true,
        ),
        isTrue,
      );

      native.addLocation(sample(-80, 0, speed: 8));
      native.addLocation(sample(-79.9997, 15, speed: 8));
      await drainNativeTripEventsUntil(
        () => controller.motionState == TripMotionState.moving,
        maxPumps: 48,
      );

      store.failNextSessionSave = true;
      native.addActivity(
        TripActivityObservation(
          activity: TripActivity.walking,
          confidence: 95,
          recordedAt: start.add(const Duration(seconds: 30)),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(controller.platformStatus, 'storage_failed');
      expect(controller.platformError, contains('activity evidence locally'));

      native.addLocation(sample(-79.9997, 45));
      await drainNativeTripEventsUntil(
        () =>
            store.activeSession?.updatedAt ==
            start.add(const Duration(seconds: 45)),
        maxPumps: 48,
      );

      expect(store.activeSession?.engineSnapshot.walkingEvidence, isEmpty);
      expect(controller.needsWalkingReview, isFalse);
    },
  );

  test(
    'native walking evidence persists across sparse location callbacks',
    () async {
      final native = _FakeTripTrackingPlatform(
        activityRecognitionAvailable: true,
      );
      final store = TripTrackingSessionStore.memory();
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(initialReading: 1000),
        platform: native,
      );
      await controller.start(
        tripId: 'trip_sparse_native_walking_stop',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      expect(
        await controller.startNativeTracking(
          allowBackground: false,
          activityRecognitionEnabled: true,
        ),
        isTrue,
      );

      native.addLocation(sample(-80, 0, speed: 8));
      native.addLocation(sample(-79.9997, 15, speed: 8));
      await drainNativeTripEventsUntil(
        () => controller.motionState == TripMotionState.moving,
        maxPumps: 48,
      );
      for (final seconds in [30, 45, 60]) {
        native.addActivity(
          TripActivityObservation(
            activity: TripActivity.walking,
            confidence: 95,
            recordedAt: start.add(Duration(seconds: seconds)),
          ),
        );
      }
      await drainNativeTripEventsUntil(
        () =>
            (store.activeSession?.engineSnapshot.walkingEvidence.length ?? 0) ==
            3,
        maxPumps: 48,
      );

      native.addLocation(sample(-79.9997, 60));
      await drainNativeTripEventsUntil(
        () => controller.motionState == TripMotionState.stopped,
        maxPumps: 48,
      );

      expect(controller.motionState, TripMotionState.stopped);
      expect(controller.isTracking, isTrue);
      expect(controller.nativeTracking, isTrue);
    },
  );

  test(
    'native traffic delay without walking evidence is not a completed stop',
    () async {
      final native = _FakeTripTrackingPlatform(
        activityRecognitionAvailable: true,
      );
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(initialReading: 1000),
        platform: native,
      );
      await controller.start(
        tripId: 'trip_native_traffic_delay',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      expect(
        await controller.startNativeTracking(
          allowBackground: false,
          activityRecognitionEnabled: true,
        ),
        isTrue,
      );

      native.addLocation(sample(-80, 0, speed: 8));
      native.addLocation(sample(-79.9997, 15, speed: 8));
      await drainNativeTripEventsUntil(
        () => controller.motionState == TripMotionState.moving,
        maxPumps: 48,
      );
      for (final seconds in [30, 45, 60, 75]) {
        native.addLocation(sample(-79.9997, seconds));
      }
      await drainNativeTripEventsUntil(
        () => controller.motionState == TripMotionState.moving,
        maxPumps: 48,
      );

      expect(controller.motionState, TripMotionState.moving);
      expect(controller.needsWalkingReview, isFalse);
      expect(controller.isTracking, isTrue);
    },
  );

  test(
    'disabling motion assistance updates the active native collector',
    () async {
      final native = _FakeTripTrackingPlatform(
        activityRecognitionAvailable: true,
      );
      final store = TripTrackingSessionStore.memory();
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(initialReading: 1000),
        platform: native,
      );
      await controller.start(
        tripId: 'trip_disable_motion_assistance',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      expect(
        await controller.startNativeTracking(
          allowBackground: true,
          activityRecognitionEnabled: true,
        ),
        isTrue,
      );

      await controller.disableActivityRecognition();

      expect(native.updateCalls, 1);
      expect(native.updatedRequest?.activityRecognitionEnabled, isFalse);
      expect(native.updatedRequest?.allowBackground, isTrue);
      expect(controller.nativeTracking, isTrue);
      expect(store.activeSession?.activityRecognitionEnabled, isFalse);
    },
  );

  test(
    'a failed motion-assistance withdrawal stops GPS rather than retaining sensor access',
    () async {
      final native = _FakeTripTrackingPlatform(
        activityRecognitionAvailable: true,
        updateSucceeds: false,
      );
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(initialReading: 1000),
        platform: native,
      );
      await controller.start(
        tripId: 'trip_failed_motion_withdrawal',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      await controller.startNativeTracking(
        allowBackground: false,
        activityRecognitionEnabled: true,
      );

      await controller.disableActivityRecognition();

      expect(native.updateCalls, 1);
      expect(native.stopCalls, 1);
      expect(controller.nativeTracking, isFalse);
      expect(
        controller.platformError,
        contains('Motion activity was disabled'),
      );
    },
  );

  test(
    'motion events arriving after consent withdrawal cannot influence stop review',
    () async {
      final native = _FakeTripTrackingPlatform(
        activityRecognitionAvailable: true,
      );
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(initialReading: 1000),
        platform: native,
      );
      await controller.start(
        tripId: 'trip_ignore_withdrawn_motion_events',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.deliveryVehicle,
        startedAt: start,
      );
      await controller.startNativeTracking(
        allowBackground: false,
        activityRecognitionEnabled: true,
      );
      await controller.disableActivityRecognition();

      for (final seconds in [20, 35, 50]) {
        native.addActivity(
          TripActivityObservation(
            activity: TripActivity.walking,
            confidence: 95,
            recordedAt: start.add(Duration(seconds: seconds)),
          ),
        );
        native.addLocation(sample(-80 + (seconds / 100000), seconds, speed: 8));
      }
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(controller.needsWalkingReview, isFalse);
      expect(controller.acceptedMeters, greaterThan(0));
    },
  );

  test(
    'legacy recovery stops GPS when saved native sampling is unavailable',
    () async {
      final store = TripTrackingSessionStore.memory();
      final initial = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(initialReading: 1000),
      );
      await initial.start(
        tripId: 'trip_legacy_motion_withdrawal',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      await store.save(
        store.activeSession!.copyWith(
          backgroundTrackingAllowed: true,
          activityRecognitionEnabled: true,
          clearNativeSampling: true,
        ),
      );
      final native = _FakeTripTrackingPlatform(
        activityRecognitionAvailable: true,
      );
      await native.start(
        const TripTrackingNativeRequest(
          profile: TripTrackingProfile.roadVehicle,
          sampling: TripSamplingRecommendation(
            mode: TripSamplingMode.balanced,
            interval: Duration(seconds: 15),
            minimumDisplacementMeters: 8,
          ),
          allowBackground: true,
          activityRecognitionEnabled: true,
        ),
      );
      final restored = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
        platform: native,
      );

      expect(await restored.restore(), isTrue);

      expect(native.updateCalls, 0);
      expect(native.stopCalls, 1);
      expect(restored.nativeTracking, isFalse);
      expect(
        restored.platformError,
        contains('saved sampling state is unavailable'),
      );
    },
  );

  test(
    'withdrawing an already-disabled sensor does not disturb GPS tracking',
    () async {
      final native = _FakeTripTrackingPlatform();
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(initialReading: 1000),
        platform: native,
      );
      await controller.start(
        tripId: 'trip_no_motion_sensor_to_withdraw',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      await controller.startNativeTracking(allowBackground: false);

      await controller.disableActivityRecognition();

      expect(native.updateCalls, 0);
      expect(native.stopCalls, 0);
      expect(controller.nativeTracking, isTrue);
    },
  );

  test(
    'a long paused GPS gap is not converted into live odometer miles',
    () async {
      final native = _FakeTripTrackingPlatform();
      final odometer = GlobalOdometerController(initialReading: 1000);
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: odometer,
        platform: native,
      );
      await controller.start(
        tripId: 'trip_pause_gap',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      await controller.startNativeTracking(allowBackground: false);
      native.addLocation(sample(-80, 0, speed: 8));
      native.addLocation(sample(-79.999, 20, speed: 8));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      final acceptedBeforePause = controller.acceptedMeters;
      final odometerBeforePause = odometer.reading;

      await controller.stopNativeTracking();
      await controller.startNativeTracking(allowBackground: false);
      native.addLocation(sample(-79.98, 1800, speed: 8));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(controller.acceptedMeters, acceptedBeforePause);
      expect(odometer.reading, odometerBeforePause);
    },
  );

  test(
    'a native stop fault still leaves the GPS trip safely recoverable',
    () async {
      final native = _FakeTripTrackingPlatform(throwOnStop: true);
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(initialReading: 1000),
        platform: native,
      );
      await controller.start(
        tripId: 'trip_stop_fault',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      await controller.startNativeTracking(allowBackground: false);

      await controller.stopNativeTracking();

      expect(controller.isTracking, isTrue);
      expect(controller.nativeTracking, isFalse);
      expect(controller.platformError, contains('could not cleanly stop GPS'));
      expect(native.stopCalls, 1);

      expect(
        await controller.startNativeTracking(allowBackground: false),
        isTrue,
      );
      expect(controller.platformError, isNull);
      expect(controller.nativeTracking, isTrue);
    },
  );

  test(
    'reviewing a walking-based stop cue persists across local recovery',
    () async {
      final store = TripTrackingSessionStore.memory();
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(initialReading: 1000),
      );
      await controller.start(
        tripId: 'trip_reviewed_stop',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      for (var index = 1; index <= 5; index++) {
        final seconds = index * 15;
        await controller.ingest(
          sample(-80 + (index * .00012), seconds),
          activity: TripActivityObservation(
            activity: TripActivity.walking,
            confidence: 90,
            recordedAt: start.add(Duration(seconds: seconds)),
          ),
        );
      }
      expect(controller.needsWalkingReview, isTrue);

      await controller.acknowledgeWalkingReview();

      expect(controller.needsWalkingReview, isFalse);
      final restored = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
      );
      expect(await restored.restore(), isTrue);
      expect(restored.needsWalkingReview, isFalse);
    },
  );

  test(
    'a native stop fault during finish still saves review and releases odometer',
    () async {
      final native = _FakeTripTrackingPlatform(throwOnStop: true);
      final store = TripTrackingSessionStore.memory();
      final odometer = GlobalOdometerController(initialReading: 1000);
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: odometer,
        platform: native,
      );
      await controller.start(
        tripId: 'trip_finish_stop_fault',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      await controller.startNativeTracking(allowBackground: false);
      native.addLocation(sample(-80, 0, speed: 8));
      native.addLocation(sample(-79.965, 90, speed: 8));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final review = await controller.finishForReview(
        finishedAt: start.add(const Duration(minutes: 2)),
      );

      expect(review, isNotNull);
      expect(store.reviewForTrip('trip_finish_stop_fault'), isNotNull);
      expect(store.activeSession, isNull);
      expect(controller.isTracking, isFalse);
      expect(controller.nativeTracking, isFalse);
      expect(odometer.hasLiveTripProjection, isFalse);
      expect(odometer.confirmedReading, 1000);
      expect(native.stopCalls, 1);
      expect(controller.platformError, contains('could not cleanly stop GPS'));
    },
  );

  test(
    'permission startup failure can discard an empty trip without locking odometer',
    () async {
      final odometer = GlobalOdometerController(initialReading: 1000);
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: odometer,
        platform: _FakeTripTrackingPlatform(
          authorization: const TripTrackingAuthorization(
            state: TripTrackingAuthorizationState.denied,
            preciseLocation: false,
          ),
        ),
      );
      await controller.start(
        tripId: 'trip_denied',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );

      expect(
        await controller.startNativeTracking(allowBackground: false),
        isFalse,
      );
      expect(await controller.discardEmptyTrip(), isTrue);
      expect(controller.isTracking, isFalse);
      expect(odometer.hasLiveTripProjection, isFalse);
    },
  );

  test('approximate-only location cannot start a precise GPS trip', () async {
    final native = _FakeTripTrackingPlatform(
      authorization: const TripTrackingAuthorization(
        state: TripTrackingAuthorizationState.always,
        preciseLocation: false,
      ),
    );
    final controller = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      odometer: GlobalOdometerController(initialReading: 1000),
      platform: native,
    );
    await controller.start(
      tripId: 'trip_approximate_location',
      vehicleId: 'vehicle_1',
      profile: TripTrackingProfile.roadVehicle,
      startedAt: start,
    );

    expect(
      await controller.startNativeTracking(allowBackground: false),
      isFalse,
    );
    expect(controller.platformError, contains('Precise location permission'));
    expect(
      controller.lifecycleState,
      TripTrackingSessionLifecycleState.permissionRequired,
    );
  });

  test(
    'native startup exceptions fail safely without leaving a subscription',
    () async {
      final native = _FakeTripTrackingPlatform(
        throwOnStart: true,
        startFailureMessage: 'token=pk.secret lat=35.123 lon=-80.456',
      );
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(initialReading: 1000),
        platform: native,
      );
      await controller.start(
        tripId: 'trip_start_exception',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );

      expect(
        await controller.startNativeTracking(allowBackground: false),
        isFalse,
      );
      expect(controller.nativeTracking, isFalse);
      expect(controller.platformError, contains('could not start GPS'));
      expect(controller.platformError, isNot(contains('pk.secret')));
      expect(controller.platformError, isNot(contains('35.123')));
      expect(await controller.discardEmptyTrip(), isTrue);
    },
  );

  test('native permission errors use a safe actionable message', () async {
    final native = _FakeTripTrackingPlatform(
      authorizationException: PlatformException(
        code: 'trip_tracking_permission_busy',
        message: 'raw permission provider detail',
      ),
    );
    final controller = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      odometer: GlobalOdometerController(initialReading: 1000),
      platform: native,
    );
    await controller.start(
      tripId: 'trip_permission_command_failure',
      vehicleId: 'vehicle_1',
      profile: TripTrackingProfile.roadVehicle,
      startedAt: start,
    );

    expect(
      await controller.startNativeTracking(allowBackground: false),
      isFalse,
    );
    expect(
      controller.platformError,
      'Another GPS permission request is already in progress.',
    );
    expect(
      controller.platformError,
      isNot(contains('raw permission provider')),
    );
  });

  test(
    'native startup platform errors use a safe actionable message',
    () async {
      final native = _FakeTripTrackingPlatform(
        startException: PlatformException(
          code: 'trip_tracking_location_accuracy_reduced',
          message: 'raw native provider failure',
        ),
      );
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(initialReading: 1000),
        platform: native,
      );
      await controller.start(
        tripId: 'trip_safe_native_start_failure',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );

      expect(
        await controller.startNativeTracking(allowBackground: false),
        isFalse,
      );
      expect(
        controller.platformError,
        'Precise GPS access was reduced while tracking.',
      );
      expect(
        controller.platformError,
        isNot(contains('raw native provider failure')),
      );
    },
  );

  test(
    'future-dated walking evidence is not applied to an earlier location',
    () async {
      final native = _FakeTripTrackingPlatform();
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(initialReading: 1000),
        platform: native,
      );
      await controller.start(
        tripId: 'trip_future_activity',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      await controller.startNativeTracking(allowBackground: false);
      native.addActivity(
        TripActivityObservation(
          activity: TripActivity.walking,
          confidence: 90,
          recordedAt: start.add(const Duration(minutes: 5)),
        ),
      );
      native.addLocation(sample(-80, 0));
      native.addLocation(sample(-79.9998, 20));
      native.addLocation(sample(-79.9996, 35));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(controller.needsWalkingReview, isFalse);
    },
  );

  test(
    'direct ingest drops future activity before pending recovery save',
    () async {
      final store = TripTrackingSessionStore.memory();
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(initialReading: 1000),
      );

      expect(
        await controller.start(
          tripId: 'trip_future_activity_direct',
          vehicleId: 'vehicle_1',
          profile: TripTrackingProfile.deliveryVehicle,
          startedAt: start,
        ),
        isTrue,
      );
      final first = await controller.ingest(
        sample(-80, 0),
        activity: TripActivityObservation(
          activity: TripActivity.walking,
          confidence: 95,
          recordedAt: start.add(const Duration(minutes: 5)),
        ),
      );
      final second = await controller.ingest(sample(-79.999, 20));

      expect(first?.disposition, TripSampleDisposition.acceptedAnchor);
      expect(second?.accepted, isTrue);
      expect(controller.needsWalkingReview, isFalse);
      expect(store.pendingSampleFor('trip_future_activity_direct'), isNull);
    },
  );

  test('invalid activity confidence cannot break GPS ingestion', () async {
    final store = TripTrackingSessionStore.memory();
    final controller = TripTrackingController(
      sessionStore: store,
      odometer: GlobalOdometerController(initialReading: 1000),
    );

    expect(
      await controller.start(
        tripId: 'trip_invalid_activity_confidence',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.deliveryVehicle,
        startedAt: start,
      ),
      isTrue,
    );
    final first = await controller.ingest(
      sample(-80, 0),
      activity: TripActivityObservation(
        activity: TripActivity.walking,
        confidence: 101,
        recordedAt: start,
      ),
    );
    final second = await controller.ingest(sample(-79.999, 20));

    expect(first?.disposition, TripSampleDisposition.acceptedAnchor);
    expect(second?.accepted, isTrue);
    expect(controller.needsWalkingReview, isFalse);
    expect(controller.platformStatus, isNull);
    expect(store.pendingSampleFor('trip_invalid_activity_confidence'), isNull);
  });

  test('accepted GPS distance updates the global live odometer only', () async {
    final odometer = GlobalOdometerController(initialReading: 1000);
    var odometerNotifications = 0;
    odometer.addListener(() => odometerNotifications++);
    final controller = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      odometer: odometer,
    );

    expect(
      await controller.start(
        tripId: 'trip_1',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      ),
      isTrue,
    );
    await controller.ingest(sample(-80, 0));
    await controller.ingest(sample(-79.985, 60));

    expect(odometer.reading, greaterThan(1000));
    expect(odometer.confirmedReading, 1000);
    expect(odometerNotifications, greaterThan(0));
    expect(controller.acceptedMeters, greaterThan(0));
  });

  test('accepted GPS distance can use bounded advisory calibration', () async {
    final odometer = GlobalOdometerController(initialReading: 1000);
    final controller = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      odometer: odometer,
      gpsAssistanceCalibrationMultiplier: .8,
    );

    expect(
      await controller.start(
        tripId: 'trip_calibrated_projection',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      ),
      isTrue,
    );
    await controller.ingest(sample(-80, 0));
    await controller.ingest(sample(-79.985, 60));

    expect(controller.acceptedMeters, greaterThan(0));
    expect(odometer.reading, greaterThan(1000));
    expect(odometer.confirmedReading, 1000);
  });

  test(
    'failed local GPS checkpoints do not advance the live filter or odometer',
    () async {
      final store = _FailingNextSessionSaveStore();
      final odometer = GlobalOdometerController(initialReading: 1000);
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: odometer,
      );

      expect(
        await controller.start(
          tripId: 'trip_live_save_order',
          vehicleId: 'vehicle_1',
          profile: TripTrackingProfile.roadVehicle,
          startedAt: start,
        ),
        isTrue,
      );
      expect(await controller.ingest(sample(-80, 0)), isNotNull);
      store.failNextSessionSave = true;

      await expectLater(
        controller.ingest(sample(-79.985, 60)),
        throwsStateError,
      );

      expect(odometer.reading, 1000);
      expect(odometer.confirmedReading, 1000);
      expect(controller.acceptedMeters, 0);

      final expected = TripTrackingEngine();
      expected.ingest(sample(-80, 0));
      expected.ingest(sample(-79.97, 120));
      expect(await controller.ingest(sample(-79.97, 120)), isNotNull);
      expect(
        controller.acceptedMeters,
        closeTo(expected.totalAcceptedMeters, .001),
      );
    },
  );

  test(
    'overrange accepted GPS distance cannot silently skip live odometer UI',
    () async {
      final odometer = GlobalOdometerController(
        initialReading: 1000,
        validationPolicy: const OdometerValidationPolicy(
          maxSupportedReading: 1001,
        ),
      );
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: odometer,
        policy: const TripTrackingPolicy(
          maximumPlausibleSpeedMetersPerSecond: 1000,
        ),
      );

      expect(
        await controller.start(
          tripId: 'trip_projection_live_limit',
          vehicleId: 'vehicle_1',
          profile: TripTrackingProfile.roadVehicle,
          startedAt: start,
        ),
        isTrue,
      );
      await controller.ingest(sample(-80, 0));
      await controller.ingest(sample(-79.95, 60));

      expect(controller.acceptedMeters, greaterThan(0));
      expect(odometer.reading, 1000);
      expect(controller.platformStatus, 'odometer_projection_invalid');
      expect(controller.platformError, contains('Review the trip'));
    },
  );

  test(
    'live GPS projection fails closed at active validation ceiling',
    () async {
      final odometer = GlobalOdometerController(
        initialReading: 1000,
        validationPolicy: const OdometerValidationPolicy(
          maxSupportedReading: 1002,
        ),
      );
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: odometer,
        policy: const TripTrackingPolicy(
          maximumPlausibleSpeedMetersPerSecond: 1000,
        ),
      );

      expect(
        await controller.start(
          tripId: 'trip_projection_uses_validation_limit',
          vehicleId: 'vehicle_1',
          profile: TripTrackingProfile.roadVehicle,
          startedAt: start,
        ),
        isTrue,
      );
      await controller.ingest(sample(-80, 0));
      await controller.ingest(sample(-79.96, 60));

      expect(odometer.reading, 1000);
      expect(controller.platformStatus, 'odometer_projection_invalid');
      expect(controller.acceptedMeters, greaterThan(0));
    },
  );

  test(
    'stale live odometer projection updates are not mislabeled as distance range failures',
    () async {
      final odometer = GlobalOdometerController(initialReading: 1000);
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: odometer,
      );
      await controller.start(
        tripId: 'trip_projection_timestamp_conflict',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      await controller.ingest(sample(-80, 0), referenceTime: start);
      expect(
        odometer.updateLiveTripProjection(
          tripId: 'trip_projection_timestamp_conflict',
          estimatedOdometer: 1000,
          observedAtUtc: start.add(const Duration(minutes: 1)),
          receivedAtUtc: start.add(const Duration(minutes: 1)),
        ),
        isTrue,
      );

      await controller.ingest(
        sample(-79.999, 20),
        referenceTime: start.add(const Duration(seconds: 20)),
      );

      expect(controller.platformStatus, 'odometer_projection_invalid');
      expect(controller.platformError, contains('could not be updated safely'));
      expect(controller.platformError, isNot(contains('distance exceeded')));
      expect(odometer.confirmedReading, 1000);
    },
  );

  test(
    'native future timestamps are rejected without changing GPS distance',
    () async {
      final store = TripTrackingSessionStore.memory();
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(initialReading: 1000),
      );
      final now = start.add(const Duration(minutes: 10));
      await controller.start(
        tripId: 'trip_future_native_timestamp',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );

      final decision = await controller.ingest(
        sample(-80, 0),
        referenceTime: now,
      );

      expect(decision?.disposition, TripSampleDisposition.acceptedAnchor);
      final future = await controller.ingest(
        sample(-79.99, 800),
        referenceTime: now,
      );
      expect(
        future?.disposition,
        TripSampleDisposition.rejectedFutureTimestamp,
      );
      expect(controller.acceptedMeters, 0);
      expect(store.pendingSampleFor('trip_future_native_timestamp'), isNull);
      expect(
        store.activeSession?.updatedAt,
        start.add(const Duration(seconds: 0)),
      );
    },
  );

  test(
    'direct ingest rejects future timestamps using the controller clock',
    () async {
      final store = TripTrackingSessionStore.memory();
      final now = start.add(const Duration(minutes: 10));
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(initialReading: 1000),
        clockNow: () => now,
      );
      addTearDown(controller.dispose);

      expect(
        await controller.start(
          tripId: 'trip_future_direct_timestamp',
          vehicleId: 'vehicle_1',
          profile: TripTrackingProfile.roadVehicle,
          startedAt: start,
        ),
        isTrue,
      );
      expect(
        (await controller.ingest(sample(-80, 0)))?.disposition,
        TripSampleDisposition.acceptedAnchor,
      );

      final future = await controller.ingest(sample(-79.99, 800));

      expect(
        future?.disposition,
        TripSampleDisposition.rejectedFutureTimestamp,
      );
      expect(controller.acceptedMeters, 0);
      expect(store.pendingSampleFor('trip_future_direct_timestamp'), isNull);
      expect(store.activeSession?.updatedAt, start);
    },
  );

  test(
    'recovery cannot replay a future pending sample without native events',
    () async {
      final store = TripTrackingSessionStore.memory();
      final now = start.add(const Duration(minutes: 10));
      final original = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(initialReading: 1000),
        clockNow: () => now,
      );
      addTearDown(original.dispose);
      expect(
        await original.start(
          tripId: 'trip_future_pending_recovery',
          vehicleId: 'vehicle_1',
          profile: TripTrackingProfile.roadVehicle,
          startedAt: start,
        ),
        isTrue,
      );
      await original.ingest(sample(-80, 0));
      await store.savePending(
        TripTrackingPendingSample(
          sessionId: 'trip_future_pending_recovery',
          sample: sample(-79.98, 800),
        ),
      );

      final odometer = GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      );
      final recovered = TripTrackingController(
        sessionStore: store,
        odometer: odometer,
        clockNow: () => now,
      );
      addTearDown(recovered.dispose);
      addTearDown(odometer.dispose);

      expect(await recovered.restore(), isTrue);
      expect(recovered.acceptedMeters, 0);
      expect(odometer.reading, 1000);
      expect(store.pendingSampleFor('trip_future_pending_recovery'), isNull);
    },
  );

  test(
    'mocked GPS fixes are rejected without durable pending recovery',
    () async {
      final store = TripTrackingSessionStore.memory();
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(initialReading: 1000),
      );
      await controller.start(
        tripId: 'trip_mocked_pending',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );

      final decision = await controller.ingest(
        TripLocationSample(
          latitude: 35,
          longitude: -80,
          recordedAt: start,
          horizontalAccuracyMeters: 5,
          mockedLocation: true,
        ),
      );

      expect(decision?.disposition, TripSampleDisposition.rejectedMockLocation);
      expect(controller.acceptedMeters, 0);
      expect(store.pendingSampleFor('trip_mocked_pending'), isNull);
      expect(
        store.activeSession?.engineSnapshot.diagnostics.receivedSamples,
        1,
      );
    },
  );

  test(
    'invalid GPS fixes are rejected before durable pending recovery',
    () async {
      final store = TripTrackingSessionStore.memory();
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(initialReading: 1000),
      );
      await controller.start(
        tripId: 'trip_invalid_pending',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );

      final decision = await controller.ingest(
        TripLocationSample(
          latitude: 91,
          longitude: -80,
          recordedAt: start,
          horizontalAccuracyMeters: 5,
        ),
      );

      expect(decision?.disposition, TripSampleDisposition.rejectedInvalid);
      expect(controller.acceptedMeters, 0);
      expect(store.pendingSampleFor('trip_invalid_pending'), isNull);
      expect(store.activeSession?.updatedAt, start);
    },
  );

  test(
    'malformed reported speeds are rejected before durable pending recovery',
    () async {
      final store = TripTrackingSessionStore.memory();
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(initialReading: 1000),
      );
      await controller.start(
        tripId: 'trip_invalid_speed_pending',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );

      final decision = await controller.ingest(
        TripLocationSample(
          latitude: 35,
          longitude: -80,
          recordedAt: start,
          horizontalAccuracyMeters: 5,
          speedMetersPerSecond: double.infinity,
        ),
      );

      expect(decision?.disposition, TripSampleDisposition.rejectedInvalid);
      expect(controller.acceptedMeters, 0);
      expect(store.pendingSampleFor('trip_invalid_speed_pending'), isNull);
      expect(store.activeSession?.updatedAt, start);
    },
  );

  test(
    'near-future native timestamps stay within clock-skew tolerance',
    () async {
      final store = TripTrackingSessionStore.memory();
      final odometer = GlobalOdometerController(initialReading: 1000);
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: odometer,
      );
      addTearDown(controller.dispose);
      addTearDown(odometer.dispose);
      final now = start.add(const Duration(minutes: 10));
      await controller.start(
        tripId: 'trip_near_future_native_timestamp',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );

      expect(
        (await controller.ingest(
          sample(-80, 9 * 60 + 30),
          referenceTime: now,
        ))?.disposition,
        TripSampleDisposition.acceptedAnchor,
      );
      final accepted = await controller.ingest(
        sample(-79.999, 11 * 60),
        referenceTime: now,
      );

      expect(accepted?.disposition, TripSampleDisposition.acceptedDistance);
      expect(controller.acceptedMeters, greaterThan(0));
      expect(odometer.confirmedReading, 1000);
      expect(
        store.pendingSampleFor('trip_near_future_native_timestamp'),
        isNull,
      );
    },
  );

  test(
    'cached native fixes before trip start cannot anchor live mileage',
    () async {
      final store = TripTrackingSessionStore.memory();
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(initialReading: 1000),
      );
      await controller.start(
        tripId: 'trip_cached_native_fix',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );

      final stale = await controller.ingest(
        sample(-80, -5),
        referenceTime: start,
      );

      expect(stale?.disposition, TripSampleDisposition.rejectedOutOfOrder);
      expect(controller.acceptedMeters, 0);
      expect(store.pendingSampleFor('trip_cached_native_fix'), isNull);
      expect(store.activeSession?.updatedAt, start);
    },
  );

  test(
    'native sampling escalates only after an accepted high-speed sample',
    () async {
      final native = _FakeTripTrackingPlatform();
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(initialReading: 1000),
        platform: native,
      );
      await controller.start(
        tripId: 'trip_sampling',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      await controller.startNativeTracking(allowBackground: false);
      native.addLocation(sample(-80, 0, speed: 8));
      native.addLocation(sample(-79.999, 20, speed: 8));
      native.addLocation(sample(-79.998, 40, speed: 6));
      await drainNativeTripEventsUntil(
        () =>
            native.updatedRequest?.sampling.mode == TripSamplingMode.precision,
      );

      expect(native.updatedRequest?.sampling.mode, TripSamplingMode.precision);
      expect(
        native.updatedRequest?.sampling.interval,
        const Duration(seconds: 2),
      );
      expect(native.updateCalls, 1);
    },
  );

  test('uncertain native speed cannot escalate GPS sampling', () async {
    final native = _FakeTripTrackingPlatform();
    final controller = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      odometer: GlobalOdometerController(initialReading: 1000),
      platform: native,
    );
    await controller.start(
      tripId: 'trip_sampling_uncertain_speed',
      vehicleId: 'vehicle_1',
      profile: TripTrackingProfile.roadVehicle,
      startedAt: start,
    );
    await controller.startNativeTracking(allowBackground: false);
    native.addLocation(sample(-80, 0, speed: 20, speedAccuracy: 50));
    native.addLocation(sample(-79.999, 20, speed: 20, speedAccuracy: 50));
    await drainNativeTripEventsUntil(
      () => controller.acceptedMeters > 0,
      maxPumps: 48,
    );

    expect(controller.acceptedMeters, greaterThan(0));
    expect(native.updateCalls, 0);
  });

  test(
    'stationary GPS drift deescalates precision sampling to save battery',
    () async {
      final native = _FakeTripTrackingPlatform();
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(initialReading: 1000),
        platform: native,
      );
      await controller.start(
        tripId: 'trip_sampling_deescalation',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      await controller.startNativeTracking(allowBackground: false);
      native.addLocation(sample(-80, 0, speed: 8));
      native.addLocation(sample(-79.999, 20, speed: 8));
      await drainNativeTripEventsUntil(
        () =>
            native.updatedRequest?.sampling.mode == TripSamplingMode.precision,
      );
      expect(native.updatedRequest?.sampling.mode, TripSamplingMode.precision);

      native.addLocation(sample(-79.999, 22, speed: 0));
      await drainNativeTripEventsUntil(
        () => native.updatedRequest?.sampling.mode == TripSamplingMode.balanced,
      );

      expect(native.updatedRequest?.sampling.mode, TripSamplingMode.balanced);
      expect(
        native.updatedRequest?.sampling.interval,
        const Duration(seconds: 5),
      );
      expect(native.updateCalls, 2);
    },
  );

  test(
    'stationary GPS speed conflicts deescalate precision sampling',
    () async {
      final native = _FakeTripTrackingPlatform();
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(initialReading: 1000),
        platform: native,
      );
      await controller.start(
        tripId: 'trip_sampling_stationary_conflict',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.rideshareVehicle,
        startedAt: start,
      );
      await controller.startNativeTracking(allowBackground: false);
      native.addLocation(sample(-80, 0, speed: 8));
      native.addLocation(sample(-79.999, 20, speed: 8));
      await drainNativeTripEventsUntil(
        () =>
            native.updatedRequest?.sampling.mode == TripSamplingMode.precision,
      );
      expect(native.updatedRequest?.sampling.mode, TripSamplingMode.precision);

      native.addLocation(sample(-79.998, 22, speed: 0.2));
      await drainNativeTripEventsUntil(
        () => native.updatedRequest?.sampling.mode == TripSamplingMode.balanced,
      );

      expect(native.updatedRequest?.sampling.mode, TripSamplingMode.balanced);
      expect(controller.acceptedMeters, lessThan(200));
      expect(native.updateCalls, 2);
    },
  );

  test('a credible slowdown deescalates precision GPS sampling', () async {
    final native = _FakeTripTrackingPlatform();
    final controller = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      odometer: GlobalOdometerController(initialReading: 1000),
      platform: native,
    );
    await controller.start(
      tripId: 'trip_sampling_slowdown',
      vehicleId: 'vehicle_1',
      profile: TripTrackingProfile.roadVehicle,
      startedAt: start,
    );
    await controller.startNativeTracking(allowBackground: false);
    native.addLocation(sample(-80, 0, speed: 8));
    native.addLocation(sample(-79.999, 20, speed: 8));
    native.addLocation(sample(-79.9985, 40, speed: 4));
    await drainNativeTripEventsUntil(
      () => native.updatedRequest?.sampling.mode == TripSamplingMode.balanced,
    );

    expect(native.updatedRequest?.sampling.mode, TripSamplingMode.balanced);
    expect(
      native.updatedRequest?.sampling.interval,
      const Duration(seconds: 5),
    );
    expect(native.updateCalls, 2);
  });

  test(
    'a restored trip resumes its live projection from local session state',
    () async {
      final store = TripTrackingSessionStore.memory();
      final firstOdometer = GlobalOdometerController(initialReading: 1000);
      final first = TripTrackingController(
        sessionStore: store,
        odometer: firstOdometer,
      );
      await first.start(
        tripId: 'trip_1',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      await first.ingest(sample(-80, 0));
      await first.ingest(sample(-79.985, 60));

      final restoredOdometer = GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      );
      final restored = TripTrackingController(
        sessionStore: store,
        odometer: restoredOdometer,
      );

      expect(await restored.restore(), isTrue);
      expect(restoredOdometer.reading, greaterThan(1000));
      expect(restoredOdometer.confirmedReading, 1000);
    },
  );

  test(
    'finish keeps a review local until physical odometer confirmation',
    () async {
      final store = TripTrackingSessionStore.memory();
      final odometer = GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      );
      final mirror = _FakeTripTrackingCloudMirror();
      final durableBridge = TripTrackingDurableRecordBridge(
        MaintainiacDurableRecordStore.memory(),
      );
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: odometer,
        cloudMirror: mirror,
        durableRecordBridge: durableBridge,
      );
      expect(controller.odometerIsGlobalTruth, isTrue);
      expect(controller.calibrationRequiresTrustedGpsWindow, isTrue);
      expect(controller.poorGpsDaysExcludedFromCalibration, isTrue);
      expect(controller.controllerCanCreateCalibrationWithoutReview, isFalse);
      expect(controller.controllerCanApplyCalibrationWithoutOptIn, isFalse);
      await controller.start(
        tripId: 'trip_review',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      await controller.ingest(sample(-80, 0));
      await controller.ingest(sample(-79.985, 60));

      final review = await controller.finishForReview(
        finishedAt: start.add(const Duration(minutes: 2)),
      );

      expect(review, isNotNull);
      expect(review!.estimatedEndingOdometer, greaterThan(1000));
      expect(store.activeSession, isNull);
      expect(store.reviewForTrip('trip_review')?.id, 'trip_review');
      expect(controller.isTracking, isFalse);
      expect(odometer.hasLiveTripProjection, isFalse);
      expect(odometer.confirmedReading, 1000);
      await Future<void>.delayed(Duration.zero);
      expect(mirror.reviews, isEmpty);
      expect(mirror.flushCalls, 0);
      expect(
        await controller.confirmOdometerReview(
          reviewId: 'trip_review',
          confirmedEndingOdometer: 1002,
        ),
        isTrue,
      );
      await Future<void>.delayed(Duration.zero);
      expect(odometer.confirmedReading, 1002);
      expect(odometer.history.last.sourceType, 'gps_trip_review');
      expect(odometer.history.last.sourceId, 'trip_review');
      expect(
        odometer.history.last.mileageReview?.use,
        OdometerMileageUse.unresolved,
      );
      expect(mirror.reviews.single.id, 'trip_review');
      expect(mirror.reviews.single.isOdometerConfirmed, isTrue);
      expect(mirror.flushCalls, 1);
      final durableReview = durableBridge.reviewForTrip('trip_review');
      expect(durableReview?.confirmedEndingOdometer, 1002);
      expect(durableReview?.isOdometerConfirmed, isTrue);
      expect(controller.durableRecordError, isNull);
    },
  );

  test(
    'concurrent finish requests cannot create duplicate trip reviews',
    () async {
      final store = _DelayedReviewSaveStore();
      final odometer = GlobalOdometerController(initialReading: 1000);
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: odometer,
      );
      addTearDown(controller.dispose);
      addTearDown(odometer.dispose);
      expect(
        await controller.start(
          tripId: 'trip_concurrent_finish',
          vehicleId: 'vehicle_1',
          profile: TripTrackingProfile.roadVehicle,
          startedAt: start,
        ),
        isTrue,
      );
      await controller.ingest(sample(-80, 0));

      final first = controller.finishForReview(
        finishedAt: start.add(const Duration(minutes: 10)),
      );
      await store.reviewSaveStarted.future;
      final second = await controller.finishForReview(
        finishedAt: start.add(const Duration(minutes: 10)),
      );
      store.allowReviewSave.complete();
      final firstReview = await first;

      expect(firstReview, isNotNull);
      expect(second, isNull);
      expect(store.reviewSaveCalls, 1);
      expect(store.pendingReviews, hasLength(1));
      expect(controller.isTracking, isFalse);
      expect(odometer.hasLiveTripProjection, isFalse);
    },
  );

  test(
    'durable review backup failure is retryable without changing odometer truth',
    () async {
      var durableStorageAvailable = false;
      final durableStore = MaintainiacDurableRecordStore.memory(
        storageCheck: () async => AppStorageCheck(
          availableBytes: durableStorageAvailable ? 4096 : 0,
          operationBytes: 1,
          requiredBytes: 2,
          purpose: AppStoragePurpose.smallRecordWrite,
        ),
      );
      final durableBridge = TripTrackingDurableRecordBridge(durableStore);
      final store = TripTrackingSessionStore.memory();
      final odometer = GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      );
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: odometer,
        durableRecordBridge: durableBridge,
      );
      await controller.start(
        tripId: 'trip_durable_retry',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.deliveryVehicle,
        startedAt: start,
      );
      await controller.ingest(sample(-80, 0));
      await controller.ingest(sample(-79.985, 60));

      final review = await controller.finishForReview(
        finishedAt: start.add(const Duration(minutes: 2)),
      );
      expect(review, isNotNull);
      expect(
        await controller.confirmOdometerReview(
          reviewId: 'trip_durable_retry',
          confirmedEndingOdometer: 1002,
          confirmedAt: start.add(const Duration(minutes: 3)),
        ),
        isTrue,
      );

      expect(odometer.confirmedReading, 1002);
      expect(
        store.reviewForTrip('trip_durable_retry')?.isOdometerConfirmed,
        isTrue,
      );
      expect(durableBridge.reviewForTrip('trip_durable_retry'), isNull);
      expect(controller.durableRecordError, contains('pending retry'));

      durableStorageAvailable = true;
      await controller.retryCloudBackup();

      expect(odometer.confirmedReading, 1002);
      expect(durableBridge.reviewForTrip('trip_durable_retry'), isNotNull);
      expect(controller.durableRecordError, isNull);
    },
  );

  test(
    'finish refuses inverted timelines without dropping the active trip',
    () async {
      final store = TripTrackingSessionStore.memory();
      final odometer = GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      );
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: odometer,
      );
      await controller.start(
        tripId: 'trip_inverted_finish',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      await controller.ingest(sample(-80, 0));

      final review = await controller.finishForReview(
        finishedAt: start.subtract(const Duration(seconds: 1)),
      );

      expect(review, isNull);
      expect(controller.isTracking, isTrue);
      expect(store.activeSession?.id, 'trip_inverted_finish');
      expect(store.reviewForTrip('trip_inverted_finish'), isNull);
      expect(odometer.hasLiveTripProjection, isTrue);
      expect(controller.platformStatus, 'review_timeline_invalid');
    },
  );

  test(
    'finish refuses far future timelines without dropping the active trip',
    () async {
      final start = DateTime.now().toUtc().subtract(const Duration(minutes: 5));
      final store = TripTrackingSessionStore.memory();
      final odometer = GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      );
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: odometer,
      );
      await controller.start(
        tripId: 'trip_future_finish',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      await controller.ingest(sample(-80, 0));

      final review = await controller.finishForReview(
        finishedAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
      );

      expect(review, isNull);
      expect(controller.isTracking, isTrue);
      expect(store.activeSession?.id, 'trip_future_finish');
      expect(store.reviewForTrip('trip_future_finish'), isNull);
      expect(odometer.hasLiveTripProjection, isTrue);
      expect(controller.platformStatus, 'review_finish_time_invalid');
    },
  );

  test(
    'a failed review confirmation save can retry without duplicating odometer history',
    () async {
      var storageChecks = 0;
      final store = TripTrackingSessionStore.memory(
        storageCheck: () async {
          storageChecks += 1;
          if (storageChecks == 2) {
            return const AppStorageCheck(
              availableBytes: 0,
              operationBytes: AppStorageGuard.mileageTrackingWriteBytes,
              requiredBytes: AppStorageGuard.mileageTrackingWriteBytes,
              purpose: AppStoragePurpose.mileageTracking,
            );
          }
          return const AppStorageCheck(
            availableBytes: AppStorageGuard.mileageTrackingWriteBytes,
            operationBytes: AppStorageGuard.mileageTrackingWriteBytes,
            requiredBytes: AppStorageGuard.mileageTrackingWriteBytes,
            purpose: AppStoragePurpose.mileageTracking,
          );
        },
      );
      final odometer = GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      );
      final mirror = _FakeTripTrackingCloudMirror();
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: odometer,
        cloudMirror: mirror,
      );
      final review = TripTrackingReviewRecord(
        id: 'trip_retry_confirmation_save',
        vehicleId: 'vehicle_1',
        startingOdometer: 1000,
        estimatedEndingOdometer: 1001,
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
        finishedAt: start.add(const Duration(minutes: 1)),
        engineSnapshot: const TripTrackingEngineSnapshot(
          totalAcceptedMeters: 1609.344,
          walkingReviewSuggested: false,
        ),
      );
      await store.saveReview(review);

      expect(
        await controller.confirmOdometerReview(
          reviewId: review.id,
          confirmedEndingOdometer: 1001,
          confirmedAt: start.add(const Duration(minutes: 2)),
        ),
        isFalse,
      );
      expect(store.reviewForTrip(review.id)?.isOdometerConfirmed, isFalse);
      expect(odometer.confirmedReading, 1001);
      expect(controller.platformStatus, 'review_confirmation_save_failed');
      expect(controller.platformError, contains('Retry review confirmation'));
      expect(
        odometer.history.where((event) => event.sourceId == review.id),
        hasLength(1),
      );
      expect(mirror.reviews, isEmpty);

      expect(
        await controller.confirmOdometerReview(
          reviewId: review.id,
          confirmedEndingOdometer: 1001,
          confirmedAt: start.add(const Duration(minutes: 2)),
        ),
        isTrue,
      );
      expect(store.reviewForTrip(review.id)?.isOdometerConfirmed, isTrue);
      expect(
        odometer.history.where((event) => event.sourceId == review.id),
        hasLength(1),
      );
      expect(controller.platformStatus, isNull);
      expect(controller.platformError, isNull);
      expect(mirror.reviews.single.id, review.id);
    },
  );

  test('finishing a trip clears its transient pending GPS sample', () async {
    final store = TripTrackingSessionStore.memory();
    final controller = TripTrackingController(
      sessionStore: store,
      odometer: GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      ),
    );
    await controller.start(
      tripId: 'trip_pending_cleanup',
      vehicleId: 'vehicle_1',
      profile: TripTrackingProfile.roadVehicle,
      startedAt: start,
    );
    await store.savePending(
      TripTrackingPendingSample(
        sessionId: 'trip_pending_cleanup',
        sample: sample(-80, 0),
      ),
    );

    expect(await controller.finishForReview(), isNotNull);
    expect(store.pendingSampleFor('trip_pending_cleanup'), isNull);
  });

  test('recovery does not resume a trip already queued for review', () async {
    final store = TripTrackingSessionStore.memory();
    final first = TripTrackingController(
      sessionStore: store,
      odometer: GlobalOdometerController(initialReading: 1000),
    );
    await first.start(
      tripId: 'trip_ended_before_crash',
      vehicleId: 'vehicle_1',
      profile: TripTrackingProfile.roadVehicle,
      startedAt: start,
    );
    final active = store.activeSession!;
    await store.savePending(
      TripTrackingPendingSample(sessionId: active.id, sample: sample(-80, 0)),
    );
    await store.saveReview(
      TripTrackingReviewRecord(
        id: active.id,
        vehicleId: active.vehicleId,
        startingOdometer: active.startingOdometer,
        estimatedEndingOdometer: active.startingOdometer,
        profile: active.profile,
        startedAt: active.startedAt,
        finishedAt: start.add(const Duration(minutes: 1)),
        engineSnapshot: active.engineSnapshot,
      ),
    );

    final recoveredOdometer = GlobalOdometerController(initialReading: 1000);
    final recovered = TripTrackingController(
      sessionStore: store,
      odometer: recoveredOdometer,
    );

    expect(await recovered.restore(), isFalse);
    expect(store.activeSession, isNull);
    expect(store.pendingSampleFor(active.id), isNull);
    expect(recovered.isTracking, isFalse);
    expect(recoveredOdometer.hasLiveTripProjection, isFalse);
  });

  test(
    'recovery refuses to resume a reviewed trip when stale cleanup fails',
    () async {
      final store = _FailingReviewCleanupStore();
      final first = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(initialReading: 1000),
      );
      await first.start(
        tripId: 'trip_review_cleanup_fault',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      final active = store.activeSession!;
      await store.savePending(
        TripTrackingPendingSample(sessionId: active.id, sample: sample(-80, 0)),
      );
      await store.saveReview(
        TripTrackingReviewRecord(
          id: active.id,
          vehicleId: active.vehicleId,
          startingOdometer: active.startingOdometer,
          estimatedEndingOdometer: active.startingOdometer,
          profile: active.profile,
          startedAt: active.startedAt,
          finishedAt: start.add(const Duration(minutes: 1)),
          engineSnapshot: active.engineSnapshot,
        ),
      );

      final recoveredOdometer = GlobalOdometerController(initialReading: 1000);
      final recovered = TripTrackingController(
        sessionStore: store,
        odometer: recoveredOdometer,
      );

      expect(await recovered.restore(), isFalse);
      expect(recovered.isTracking, isFalse);
      expect(recoveredOdometer.hasLiveTripProjection, isFalse);
      expect(store.activeSession?.id, active.id);
      expect(store.pendingSampleFor(active.id), isNotNull);
      expect(store.reviewForTrip(active.id), isNotNull);
      expect(recovered.platformStatus, 'review_cleanup_failed');
      expect(
        recovered.platformError,
        contains('Could not clear stale trip recovery data'),
      );
    },
  );

  test('corrupt local trip identity is cleared instead of restored', () async {
    final hiveDirectory = await Directory.systemTemp.createTemp(
      'trip_tracking_corrupt_identity_',
    );
    Hive.init(hiveDirectory.path);
    final box = await Hive.openBox<dynamic>(TripTrackingSessionStore.boxName);
    await box.put('activeSession', {
      'id': 'trip_\ncorrupt',
      'vehicleId': 'vehicle_1',
      'startingOdometer': 1000,
      'profile': TripTrackingProfile.roadVehicle.name,
      'startedAt': start.toIso8601String(),
      'updatedAt': start.toIso8601String(),
      'engineSnapshot': const TripTrackingEngineSnapshot(
        totalAcceptedMeters: 0,
        walkingReviewSuggested: false,
      ).toMap(),
    });
    final store = await TripTrackingSessionStore.create();
    addTearDown(() async {
      await Hive.close();
      if (hiveDirectory.existsSync()) {
        await hiveDirectory.delete(recursive: true);
      }
    });
    final odometer = GlobalOdometerController(initialReading: 1000);
    final controller = TripTrackingController(
      sessionStore: store,
      odometer: odometer,
    );

    expect(await controller.restore(), isFalse);
    expect(store.activeSession, isNull);
    expect(controller.isTracking, isFalse);
    expect(odometer.hasLiveTripProjection, isFalse);
  });

  test('future-schema local trip is cleared instead of restored', () async {
    final hiveDirectory = await Directory.systemTemp.createTemp(
      'trip_tracking_future_schema_',
    );
    Hive.init(hiveDirectory.path);
    final box = await Hive.openBox<dynamic>(TripTrackingSessionStore.boxName);
    await box.put('activeSession', {
      'id': 'trip_future_schema_restore',
      'vehicleId': 'vehicle_1',
      'startingOdometer': 1000,
      'profile': TripTrackingProfile.roadVehicle.name,
      'startedAt': start.toIso8601String(),
      'updatedAt': start.toIso8601String(),
      'engineSnapshot': const TripTrackingEngineSnapshot(
        totalAcceptedMeters: 0,
        walkingReviewSuggested: false,
      ).toMap(),
      'schemaVersion': 99,
    });
    final store = await TripTrackingSessionStore.create();
    addTearDown(() async {
      await Hive.close();
      if (hiveDirectory.existsSync()) {
        await hiveDirectory.delete(recursive: true);
      }
    });
    final odometer = GlobalOdometerController(initialReading: 1000);
    final controller = TripTrackingController(
      sessionStore: store,
      odometer: odometer,
    );

    expect(await controller.restore(), isFalse);
    expect(store.activeSession, isNull);
    expect(controller.isTracking, isFalse);
    expect(odometer.hasLiveTripProjection, isFalse);
  });

  test('restore rejects over-range live odometer projections safely', () async {
    final store = TripTrackingSessionStore.memory();
    await store.save(
      TripTrackingSessionRecord(
        id: 'trip_projection_too_high',
        vehicleId: 'vehicle_1',
        startingOdometer: 1000,
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
        updatedAt: start,
        engineSnapshot: const TripTrackingEngineSnapshot(
          totalAcceptedMeters: 3218688,
          walkingReviewSuggested: false,
        ),
      ),
    );
    final odometer = GlobalOdometerController(
      vehicleId: 'vehicle_1',
      initialReading: 1000,
      validationPolicy: const OdometerValidationPolicy(
        maxSupportedReading: 1200,
      ),
    );
    final controller = TripTrackingController(
      sessionStore: store,
      odometer: odometer,
    );

    expect(await controller.restore(), isFalse);
    expect(store.activeSession?.id, 'trip_projection_too_high');
    expect(controller.isTracking, isFalse);
    expect(odometer.hasLiveTripProjection, isFalse);
    expect(controller.platformStatus, 'odometer_projection_invalid');
  });

  test('restore rejects terminal lifecycle checkpoints safely', () async {
    final store = TripTrackingSessionStore.memory();
    await store.save(
      TripTrackingSessionRecord(
        id: 'trip_terminal_restore',
        vehicleId: 'vehicle_1',
        startingOdometer: 1000,
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
        updatedAt: start.add(const Duration(minutes: 1)),
        lifecycleState: TripTrackingSessionLifecycleState.completed,
        engineSnapshot: const TripTrackingEngineSnapshot(
          totalAcceptedMeters: 1609.344,
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
    );

    expect(await controller.restore(), isFalse);
    expect(store.activeSession, isNull);
    expect(controller.isTracking, isFalse);
  });

  test(
    'cloud flush failures remain visible without losing the local review',
    () async {
      final store = TripTrackingSessionStore.memory();
      final mirror = _FakeTripTrackingCloudMirror()..throwOnFlush = true;
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
        cloudMirror: mirror,
      );
      await controller.start(
        tripId: 'trip_cloud_retry',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );

      await controller.finishForReview(
        finishedAt: start.add(const Duration(minutes: 2)),
      );
      await controller.confirmOdometerReview(
        reviewId: 'trip_cloud_retry',
        confirmedEndingOdometer: 1001,
      );
      await Future<void>.delayed(Duration.zero);

      expect(store.reviewForTrip('trip_cloud_retry'), isNotNull);
      expect(controller.cloudMirrorError, contains('pending'));
    },
  );

  test(
    'a successful manual cloud retry clears a stale dashboard backup error',
    () async {
      final store = TripTrackingSessionStore.memory();
      final mirror = _FakeTripTrackingCloudMirror()..throwOnFlush = true;
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
        cloudMirror: mirror,
      );
      await controller.start(
        tripId: 'trip_manual_retry',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );

      await controller.finishForReview(
        finishedAt: start.add(const Duration(minutes: 2)),
      );
      await controller.confirmOdometerReview(
        reviewId: 'trip_manual_retry',
        confirmedEndingOdometer: 1001,
      );
      await Future<void>.delayed(Duration.zero);
      expect(controller.cloudMirrorError, contains('pending'));

      mirror.throwOnFlush = false;
      await controller.retryCloudBackup();

      expect(controller.cloudMirrorError, isNull);
      expect(mirror.flushCalls, 2);
    },
  );

  test(
    'confirmation cloud queue failure durably marks the review pending',
    () async {
      final hiveDirectory = await Directory.systemTemp.createTemp(
        'trip_tracking_confirm_pending_cloud_',
      );
      Hive.init(hiveDirectory.path);
      addTearDown(() async {
        await Hive.close();
        if (hiveDirectory.existsSync()) {
          await hiveDirectory.delete(recursive: true);
        }
      });
      final store = TripTrackingSessionStore.memory();
      final queue = await MaintainiacFirestoreUploadQueueStore.create();
      final mirror = TripTrackingFirebaseMirror(
        localStore: store,
        queueStore: queue,
        uploadCoordinator: MaintainiacFirestoreUploadCoordinator(
          queue: queue,
          sink: _NoopFirestoreSink(),
          uploadEnabled: true,
        ),
        createdByUid: 'firebaseUid-1',
        authenticatedUid: () => null,
      );
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
        cloudMirror: mirror,
      );
      await controller.start(
        tripId: 'trip_confirm_pending_cloud',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      await controller.finishForReview(
        finishedAt: start.add(const Duration(minutes: 2)),
      );

      expect(
        await controller.confirmOdometerReview(
          reviewId: 'trip_confirm_pending_cloud',
          confirmedEndingOdometer: 1001,
          confirmedAt: start.add(const Duration(minutes: 3)),
        ),
        isTrue,
      );
      final stored = store.reviewForTrip('trip_confirm_pending_cloud');
      expect(stored?.isOdometerConfirmed, isTrue);
      expect(stored?.cloudSyncState, TripTrackingCloudSyncState.pending);
      expect(stored?.cloudSyncError, contains('Backup sign-in'));
      expect(queue.pendingRecords, isEmpty);
      expect(controller.cloudMirrorError, contains('pending'));
    },
  );

  test(
    'confirmation with backup disabled remains local only without dashboard error',
    () async {
      final hiveDirectory = await Directory.systemTemp.createTemp(
        'trip_tracking_confirm_backup_disabled_',
      );
      Hive.init(hiveDirectory.path);
      addTearDown(() async {
        await Hive.close();
        if (hiveDirectory.existsSync()) {
          await hiveDirectory.delete(recursive: true);
        }
      });
      final store = TripTrackingSessionStore.memory();
      final queue = await MaintainiacFirestoreUploadQueueStore.create();
      final mirror = TripTrackingFirebaseMirror(
        localStore: store,
        queueStore: queue,
        uploadCoordinator: MaintainiacFirestoreUploadCoordinator(
          queue: queue,
          sink: _NoopFirestoreSink(),
          uploadEnabled: true,
        ),
        personal: true,
        createdByUid: 'firebaseUid-1',
        backupEnabled: () => false,
      );
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
        cloudMirror: mirror,
      );
      await controller.start(
        tripId: 'trip_confirm_backup_disabled',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
      );
      await controller.finishForReview(
        finishedAt: start.add(const Duration(minutes: 2)),
      );

      expect(
        await controller.confirmOdometerReview(
          reviewId: 'trip_confirm_backup_disabled',
          confirmedEndingOdometer: 1001,
          confirmedAt: start.add(const Duration(minutes: 3)),
        ),
        isTrue,
      );

      final stored = store.reviewForTrip('trip_confirm_backup_disabled');
      expect(stored?.isOdometerConfirmed, isTrue);
      expect(stored?.cloudSyncState, TripTrackingCloudSyncState.localOnly);
      expect(stored?.cloudSyncError, isNull);
      expect(queue.pendingRecords, isEmpty);
      expect(controller.cloudMirrorError, isNull);
    },
  );

  test('a missing persisted timeline is cleared instead of restored', () async {
    final store = await _storeWithRawTripTrackingData(
      tempPrefix: 'trip_tracking_missing_timeline_',
      activeSession: {
        'id': 'trip_missing_timeline',
        'vehicleId': 'vehicle_1',
        'startingOdometer': 1000,
        'profile': 'roadVehicle',
        'engineSnapshot': {
          'totalAcceptedMeters': 0,
          'walkingReviewSuggested': false,
        },
      },
    );
    final controller = TripTrackingController(
      sessionStore: store,
      odometer: GlobalOdometerController(initialReading: 1000),
    );

    expect(await controller.restore(), isFalse);
    expect(store.activeSession, isNull);
    expect(controller.isTracking, isFalse);
  });

  test('an unknown persisted profile is cleared instead of restored', () async {
    final store = await _storeWithRawTripTrackingData(
      tempPrefix: 'trip_tracking_unknown_profile_',
      activeSession: {
        'id': 'trip_unknown_profile',
        'vehicleId': 'vehicle_1',
        'startingOdometer': 1000,
        'profile': 'silentTracker',
        'startedAt': start.toIso8601String(),
        'updatedAt': start.toIso8601String(),
        'engineSnapshot': const TripTrackingEngineSnapshot(
          totalAcceptedMeters: 0,
          walkingReviewSuggested: false,
        ).toMap(),
      },
    );
    final odometer = GlobalOdometerController(initialReading: 1000);
    final controller = TripTrackingController(
      sessionStore: store,
      odometer: odometer,
    );

    expect(await controller.restore(), isFalse);
    expect(store.activeSession, isNull);
    expect(controller.isTracking, isFalse);
    expect(odometer.hasLiveTripProjection, isFalse);
  });

  test('recovery never projects a GPS trip onto another vehicle', () async {
    final store = TripTrackingSessionStore.memory();
    await store.save(
      TripTrackingSessionRecord(
        id: 'trip_vehicle_mismatch',
        vehicleId: 'vehicle_a',
        startingOdometer: 1000,
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
        updatedAt: start,
        engineSnapshot: const TripTrackingEngineSnapshot(
          totalAcceptedMeters: 0,
          walkingReviewSuggested: false,
        ),
      ),
    );
    final odometer = GlobalOdometerController(
      vehicleId: 'vehicle_b',
      initialReading: 2000,
    );
    final controller = TripTrackingController(
      sessionStore: store,
      odometer: odometer,
    );

    expect(await controller.restore(), isFalse);
    expect(controller.platformStatus, 'vehicle_mismatch');
    expect(odometer.hasLiveTripProjection, isFalse);
    expect(store.activeSession?.id, 'trip_vehicle_mismatch');
  });

  test('an invalid local review cannot erase a recoverable GPS trip', () async {
    final store = await _storeWithRawTripTrackingData(
      tempPrefix: 'trip_tracking_invalid_review_',
      activeSession: {
        'id': 'trip_invalid_review',
        'vehicleId': 'vehicle_1',
        'startingOdometer': 1000,
        'profile': 'roadVehicle',
        'startedAt': start.toIso8601String(),
        'updatedAt': start.toIso8601String(),
        'engineSnapshot': const TripTrackingEngineSnapshot(
          totalAcceptedMeters: 0,
          walkingReviewSuggested: false,
        ).toMap(),
      },
      review: {
        'id': 'trip_invalid_review',
        'vehicleId': 'vehicle_1',
        'startingOdometer': 1000,
        'estimatedEndingOdometer': 1001,
        'profile': 'roadVehicle',
        'engineSnapshot': {
          'totalAcceptedMeters': 0,
          'walkingReviewSuggested': false,
        },
      },
    );
    final odometer = GlobalOdometerController(
      vehicleId: 'vehicle_1',
      initialReading: 1000,
    );
    final controller = TripTrackingController(
      sessionStore: store,
      odometer: odometer,
    );

    expect(await controller.restore(), isFalse);
    expect(controller.platformStatus, 'review_invalid');
    expect(odometer.hasLiveTripProjection, isFalse);
    expect(store.activeSession?.id, 'trip_invalid_review');
  });

  test(
    'a mismatched review timeline cannot erase a recoverable GPS trip',
    () async {
      final store = TripTrackingSessionStore.memory();
      await store.save(
        TripTrackingSessionRecord(
          id: 'trip_mismatched_review_timeline',
          vehicleId: 'vehicle_1',
          startingOdometer: 1000,
          profile: TripTrackingProfile.roadVehicle,
          startedAt: start,
          updatedAt: start,
          engineSnapshot: const TripTrackingEngineSnapshot(
            totalAcceptedMeters: 0,
            walkingReviewSuggested: false,
          ),
        ),
      );
      await store.saveReview(
        TripTrackingReviewRecord(
          id: 'trip_mismatched_review_timeline',
          vehicleId: 'vehicle_1',
          startingOdometer: 1000,
          estimatedEndingOdometer: 1001,
          profile: TripTrackingProfile.roadVehicle,
          startedAt: start.add(const Duration(seconds: 1)),
          finishedAt: start.add(const Duration(minutes: 1)),
          engineSnapshot: const TripTrackingEngineSnapshot(
            totalAcceptedMeters: 0,
            walkingReviewSuggested: false,
          ),
        ),
      );
      final odometer = GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      );
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: odometer,
      );

      expect(await controller.restore(), isFalse);
      expect(controller.platformStatus, 'review_invalid');
      expect(odometer.hasLiveTripProjection, isFalse);
      expect(store.activeSession?.id, 'trip_mismatched_review_timeline');
    },
  );

  test('a trip review cannot confirm an odometer on another vehicle', () async {
    final store = TripTrackingSessionStore.memory();
    final review = TripTrackingReviewRecord(
      id: 'trip_confirmation_vehicle_mismatch',
      vehicleId: 'vehicle_a',
      startingOdometer: 1000,
      estimatedEndingOdometer: 1001,
      profile: TripTrackingProfile.roadVehicle,
      startedAt: start,
      finishedAt: start.add(const Duration(minutes: 1)),
      engineSnapshot: const TripTrackingEngineSnapshot(
        totalAcceptedMeters: 100,
        walkingReviewSuggested: false,
      ),
    );
    await store.saveReview(review);
    final mirror = _FakeTripTrackingCloudMirror();
    final controller = TripTrackingController(
      sessionStore: store,
      odometer: GlobalOdometerController(
        vehicleId: 'vehicle_b',
        initialReading: 2000,
      ),
      cloudMirror: mirror,
    );

    expect(
      await controller.confirmOdometerReview(
        reviewId: review.id,
        confirmedEndingOdometer: 2001,
      ),
      isFalse,
    );
    expect(store.reviewForTrip(review.id)?.isOdometerConfirmed, isFalse);
    expect(mirror.reviews, isEmpty);
  });

  test('concurrent odometer confirmations commit one durable review', () async {
    final store = _DelayedConfirmationSaveStore();
    final review = TripTrackingReviewRecord(
      id: 'trip_concurrent_confirmation',
      vehicleId: 'vehicle_1',
      startingOdometer: 1000,
      estimatedEndingOdometer: 1001,
      profile: TripTrackingProfile.roadVehicle,
      startedAt: start,
      finishedAt: start.add(const Duration(minutes: 1)),
      engineSnapshot: const TripTrackingEngineSnapshot(
        totalAcceptedMeters: 100,
        walkingReviewSuggested: false,
      ),
    );
    await store.saveReview(review);
    final odometer = GlobalOdometerController(
      vehicleId: 'vehicle_1',
      initialReading: 1000,
    );
    final controller = TripTrackingController(
      sessionStore: store,
      odometer: odometer,
      clockNow: () => start.add(const Duration(minutes: 3)),
    );
    addTearDown(controller.dispose);
    addTearDown(odometer.dispose);
    store.delayWrites = true;

    final first = controller.confirmOdometerReview(
      reviewId: review.id,
      confirmedEndingOdometer: 1001,
      confirmedAt: start.add(const Duration(minutes: 2)),
    );
    await store.confirmationSaveStarted.future;
    final second = await controller.confirmOdometerReview(
      reviewId: review.id,
      confirmedEndingOdometer: 1001,
      confirmedAt: start.add(const Duration(minutes: 2)),
    );
    store.allowConfirmationSave.complete();

    expect(await first, isTrue);
    expect(second, isFalse);
    expect(store.delayedSaveCalls, 1);
    expect(store.reviewForTrip(review.id)?.isOdometerConfirmed, isTrue);
    expect(odometer.confirmedReading, 1001);
    expect(
      odometer.history.where((entry) => entry.sourceId == review.id),
      hasLength(1),
    );
  });

  test('a trip review cannot confirm before the trip has finished', () async {
    final store = TripTrackingSessionStore.memory();
    final review = TripTrackingReviewRecord(
      id: 'trip_confirmation_before_finish',
      vehicleId: 'vehicle_1',
      startingOdometer: 1000,
      estimatedEndingOdometer: 1001,
      profile: TripTrackingProfile.roadVehicle,
      startedAt: start,
      finishedAt: start.add(const Duration(minutes: 5)),
      engineSnapshot: const TripTrackingEngineSnapshot(
        totalAcceptedMeters: 1609.344,
        walkingReviewSuggested: false,
      ),
    );
    await store.saveReview(review);
    final odometer = GlobalOdometerController(
      vehicleId: 'vehicle_1',
      initialReading: 1000,
    );
    final mirror = _FakeTripTrackingCloudMirror();
    final controller = TripTrackingController(
      sessionStore: store,
      odometer: odometer,
      cloudMirror: mirror,
    );

    expect(
      await controller.confirmOdometerReview(
        reviewId: review.id,
        confirmedEndingOdometer: 1001,
        confirmedAt: start.add(const Duration(minutes: 4)),
      ),
      isFalse,
    );
    expect(store.reviewForTrip(review.id)?.isOdometerConfirmed, isFalse);
    expect(odometer.confirmedReading, 1000);
    expect(mirror.reviews, isEmpty);
  });

  test('a trip review cannot confirm with a future timestamp', () async {
    final store = TripTrackingSessionStore.memory();
    final review = TripTrackingReviewRecord(
      id: 'trip_confirmation_future_time',
      vehicleId: 'vehicle_1',
      startingOdometer: 1000,
      estimatedEndingOdometer: 1001,
      profile: TripTrackingProfile.roadVehicle,
      startedAt: start,
      finishedAt: start.add(const Duration(minutes: 1)),
      engineSnapshot: const TripTrackingEngineSnapshot(
        totalAcceptedMeters: 1609.344,
        walkingReviewSuggested: false,
      ),
    );
    await store.saveReview(review);
    final odometer = GlobalOdometerController(
      vehicleId: 'vehicle_1',
      initialReading: 1000,
    );
    final mirror = _FakeTripTrackingCloudMirror();
    final controller = TripTrackingController(
      sessionStore: store,
      odometer: odometer,
      cloudMirror: mirror,
    );

    expect(
      await controller.confirmOdometerReview(
        reviewId: review.id,
        confirmedEndingOdometer: 1001,
        confirmedAt: DateTime.now().add(const Duration(days: 1)),
      ),
      isFalse,
    );
    expect(controller.platformStatus, 'odometer_confirmation_time_invalid');
    expect(store.reviewForTrip(review.id)?.isOdometerConfirmed, isFalse);
    expect(odometer.confirmedReading, 1000);
    expect(mirror.reviews, isEmpty);
  });

  test('a trip review can confirm below the GPS estimated odometer', () async {
    final store = TripTrackingSessionStore.memory();
    final review = TripTrackingReviewRecord(
      id: 'trip_confirmation_below_estimate',
      vehicleId: 'vehicle_1',
      startingOdometer: 1000,
      estimatedEndingOdometer: 1005,
      profile: TripTrackingProfile.roadVehicle,
      startedAt: start,
      finishedAt: start.add(const Duration(minutes: 1)),
      engineSnapshot: const TripTrackingEngineSnapshot(
        totalAcceptedMeters: 8046.72,
        walkingReviewSuggested: false,
      ),
    );
    await store.saveReview(review);
    final odometer = GlobalOdometerController(
      vehicleId: 'vehicle_1',
      initialReading: 1000,
    );
    final mirror = _FakeTripTrackingCloudMirror();
    final controller = TripTrackingController(
      sessionStore: store,
      odometer: odometer,
      cloudMirror: mirror,
    );

    expect(
      await controller.confirmOdometerReview(
        reviewId: review.id,
        confirmedEndingOdometer: 1004,
        confirmedAt: start.add(const Duration(minutes: 2)),
      ),
      isTrue,
    );
    final confirmed = store.reviewForTrip(review.id);
    expect(confirmed?.isOdometerConfirmed, isTrue);
    expect(confirmed?.confirmedEndingOdometer, 1004);
    expect(odometer.confirmedReading, 1004);
    expect(mirror.reviews.single.confirmedEndingOdometer, 1004);
  });

  test(
    'a trip review cannot confirm without an odometer audit commit',
    () async {
      final store = TripTrackingSessionStore.memory();
      final review = TripTrackingReviewRecord(
        id: 'trip_odometer_commit_required',
        vehicleId: 'vehicle_1',
        startingOdometer: 1000,
        estimatedEndingOdometer: 1001,
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
        finishedAt: start.add(const Duration(minutes: 1)),
        engineSnapshot: const TripTrackingEngineSnapshot(
          totalAcceptedMeters: 1609.344,
          walkingReviewSuggested: false,
        ),
      );
      await store.saveReview(review);
      final mirror = _FakeTripTrackingCloudMirror();
      final odometer = GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 2000,
      );
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: odometer,
        cloudMirror: mirror,
      );

      expect(
        await controller.confirmOdometerReview(
          reviewId: review.id,
          confirmedEndingOdometer: 1001,
        ),
        isFalse,
      );
      expect(store.reviewForTrip(review.id)?.isOdometerConfirmed, isFalse);
      expect(odometer.confirmedReading, 2000);
      expect(mirror.reviews, isEmpty);
    },
  );

  test(
    'material GPS odometer discrepancy confirms with advisory only',
    () async {
      final store = TripTrackingSessionStore.memory();
      final review = TripTrackingReviewRecord(
        id: 'trip_reconciliation_advisory',
        vehicleId: 'vehicle_1',
        startingOdometer: 1000,
        estimatedEndingOdometer: 1012,
        profile: TripTrackingProfile.roadVehicle,
        startedAt: start,
        finishedAt: start.add(const Duration(minutes: 10)),
        engineSnapshot: const TripTrackingEngineSnapshot(
          totalAcceptedMeters: 19312.128,
          walkingReviewSuggested: false,
        ),
      );
      await store.saveReview(review);
      final odometer = GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      );
      final mirror = _FakeTripTrackingCloudMirror();
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: odometer,
        cloudMirror: mirror,
      );

      expect(
        await controller.confirmOdometerReview(
          reviewId: review.id,
          confirmedEndingOdometer: 1005,
          confirmedAt: start.add(const Duration(minutes: 11)),
        ),
        isTrue,
      );
      expect(store.reviewForTrip(review.id)?.confirmedEndingOdometer, 1005);
      expect(odometer.confirmedReading, 1005);
      expect(mirror.reviews.single.confirmedEndingOdometer, 1005);
      expect(controller.platformStatus, 'odometer_reconciliation_review');
      expect(controller.platformError, contains('physical odometer'));
    },
  );

  test('a malformed local review cannot become confirmed mileage', () async {
    final store = TripTrackingSessionStore.memory();
    final review = TripTrackingReviewRecord.fromMap({
      'id': 'trip_invalid_confirmation',
      'vehicleId': 'vehicle_1',
      'startingOdometer': 1000,
      'estimatedEndingOdometer': 1001,
      'profile': 'roadVehicle',
      'engineSnapshot': {
        'totalAcceptedMeters': 100,
        'walkingReviewSuggested': false,
      },
    });
    await expectLater(store.saveReview(review), throwsArgumentError);
    expect(store.reviewForTrip(review.id), isNull);
  });

  test(
    'confirmation blocks a trip starting below the previous confirmed ending',
    () async {
      final store = TripTrackingSessionStore.memory();
      final previous =
          TripTrackingReviewRecord(
            id: 'trip_previous_confirmed',
            vehicleId: 'vehicle_1',
            startingOdometer: 1000,
            estimatedEndingOdometer: 1200,
            profile: TripTrackingProfile.roadVehicle,
            startedAt: DateTime.utc(2026, 7, 13, 8),
            finishedAt: DateTime.utc(2026, 7, 13, 10),
            engineSnapshot: const TripTrackingEngineSnapshot(
              totalAcceptedMeters: 32186.88,
              walkingReviewSuggested: false,
            ),
          ).copyWith(
            confirmedEndingOdometer: 1200,
            odometerConfirmedAt: DateTime.utc(2026, 7, 13, 10, 5),
          );
      final current = TripTrackingReviewRecord(
        id: 'trip_overlap_confirmation',
        vehicleId: 'vehicle_1',
        startingOdometer: 1199,
        estimatedEndingOdometer: 1210,
        profile: TripTrackingProfile.roadVehicle,
        startedAt: DateTime.utc(2026, 7, 14, 8),
        finishedAt: DateTime.utc(2026, 7, 14, 10),
        engineSnapshot: const TripTrackingEngineSnapshot(
          totalAcceptedMeters: 16093.44,
          walkingReviewSuggested: false,
        ),
      );
      await store.saveReview(previous);
      await store.saveReview(current);
      final odometer = GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1199,
      );
      final mirror = _FakeTripTrackingCloudMirror();
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: odometer,
        cloudMirror: mirror,
      );

      expect(
        await controller.confirmOdometerReview(
          reviewId: current.id,
          confirmedEndingOdometer: 1210,
          confirmedAt: DateTime.utc(2026, 7, 14, 10, 5),
        ),
        isFalse,
      );

      expect(controller.platformStatus, 'odometer_continuity_invalid');
      expect(controller.platformError, contains('previous confirmed odometer'));
      expect(store.reviewForTrip(current.id)?.isOdometerConfirmed, isFalse);
      expect(odometer.confirmedReading, 1199);
      expect(mirror.reviews, isEmpty);
    },
  );

  test(
    'confirmation surfaces large untracked odometer gap without blocking',
    () async {
      final store = TripTrackingSessionStore.memory();
      final previous =
          TripTrackingReviewRecord(
            id: 'trip_previous_gap_confirmed',
            vehicleId: 'vehicle_1',
            startingOdometer: 1000,
            estimatedEndingOdometer: 1020,
            profile: TripTrackingProfile.roadVehicle,
            startedAt: DateTime.utc(2026, 7, 13, 8),
            finishedAt: DateTime.utc(2026, 7, 13, 10),
            engineSnapshot: const TripTrackingEngineSnapshot(
              totalAcceptedMeters: 20 * 1609.344,
              walkingReviewSuggested: false,
            ),
          ).copyWith(
            confirmedEndingOdometer: 1020,
            odometerConfirmedAt: DateTime.utc(2026, 7, 13, 10, 5),
          );
      final current = TripTrackingReviewRecord(
        id: 'trip_large_gap_confirmation',
        vehicleId: 'vehicle_1',
        startingOdometer: 1100,
        estimatedEndingOdometer: 1110,
        profile: TripTrackingProfile.roadVehicle,
        startedAt: DateTime.utc(2026, 7, 14, 8),
        finishedAt: DateTime.utc(2026, 7, 14, 10),
        engineSnapshot: const TripTrackingEngineSnapshot(
          totalAcceptedMeters: 10 * 1609.344,
          walkingReviewSuggested: false,
        ),
      );
      await store.saveReview(previous);
      await store.saveReview(current);
      final odometer = GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1100,
      );
      final mirror = _FakeTripTrackingCloudMirror();
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: odometer,
        cloudMirror: mirror,
      );

      expect(
        await controller.confirmOdometerReview(
          reviewId: current.id,
          confirmedEndingOdometer: 1110,
          confirmedAt: DateTime.utc(2026, 7, 14, 10, 5),
        ),
        isTrue,
      );

      expect(controller.platformStatus, 'odometer_entry_review');
      expect(controller.platformError, contains('physical odometer'));
      expect(store.reviewForTrip(current.id)?.confirmedEndingOdometer, 1110);
      expect(odometer.confirmedReading, 1110);
      expect(mirror.reviews.single.confirmedEndingOdometer, 1110);
    },
  );
}

class _FakeTripTrackingPlatform implements TripTrackingNativeGateway {
  _FakeTripTrackingPlatform({
    this.authorization = const TripTrackingAuthorization(
      state: TripTrackingAuthorizationState.always,
      preciseLocation: true,
    ),
    this.throwOnStart = false,
    this.authorizationException,
    this.startException,
    this.throwOnStop = false,
    this.throwOnCancel = false,
    this.throwOnIsTracking = false,
    this.throwOnReadCapabilities = false,
    this.throwOnReadBatterySnapshot = false,
    this.batteryStateAvailable = true,
    this.lowPowerModeAvailable = true,
    this.activityRecognitionAvailable = false,
    this.updateSucceeds = true,
    this.startSucceeds = true,
    this.startFailureMessage = 'native start fault',
    this.batterySnapshot = const TripTrackingBatterySnapshot(
      batteryPercent: 100,
      isCharging: false,
      lowPowerModeEnabled: false,
    ),
    this.startDelay,
  }) : _events = throwOnCancel
           ? StreamController<TripTrackingPlatformEvent>(
               onCancel: () async {
                 throw StateError('native subscription cancel fault');
               },
             )
           : StreamController<TripTrackingPlatformEvent>.broadcast();

  final StreamController<TripTrackingPlatformEvent> _events;
  final TripTrackingAuthorization authorization;
  final bool throwOnStart;
  final Object? authorizationException;
  final Object? startException;
  final bool throwOnStop;
  final bool throwOnCancel;
  final bool throwOnIsTracking;
  final bool throwOnReadCapabilities;
  final bool throwOnReadBatterySnapshot;
  final bool batteryStateAvailable;
  final bool lowPowerModeAvailable;
  final bool activityRecognitionAvailable;
  final bool updateSucceeds;
  final bool startSucceeds;
  final String startFailureMessage;
  TripTrackingBatterySnapshot batterySnapshot;
  final Future<void>? startDelay;
  void Function()? beforeStart;
  void Function()? beforeStop;
  var _running = false;
  TripTrackingNativeRequest? startedRequest;
  TripTrackingNativeRequest? updatedRequest;
  var requestAuthorizationCalls = 0;
  var startCalls = 0;
  var updateCalls = 0;
  var stopCalls = 0;

  @override
  Stream<TripTrackingPlatformEvent> get events => _events.stream;
  bool get hasEventListener => _events.hasListener;

  void addLocation(TripLocationSample sample) {
    _events.add(
      TripTrackingPlatformEvent.fromMap({
        'type': 'location',
        ...sample.toMap(),
      }),
    );
  }

  void addActivity(TripActivityObservation observation) {
    _events.add(
      TripTrackingPlatformEvent.fromMap({
        'type': 'activity',
        ...observation.toMap(),
      }),
    );
  }

  void addAuthorization(TripTrackingAuthorization authorization) {
    _events.add(
      TripTrackingPlatformEvent.fromMap({
        'type': 'authorization',
        'state': authorization.state.name,
        'preciseLocation': authorization.preciseLocation,
      }),
    );
  }

  void addError(Object error) => _events.addError(error);

  void addPlatformError({required String code, required String message}) {
    _events.add(
      TripTrackingPlatformEvent.fromMap({
        'type': 'error',
        'errorCode': code,
        'errorMessage': message,
      }),
    );
  }

  void addMalformedPayload() {
    _events.add(TripTrackingPlatformEvent.fromNativePayload('not-a-map'));
  }

  void addStatus(String status) {
    _events.add(
      TripTrackingPlatformEvent.fromMap({'type': 'status', 'status': status}),
    );
  }

  void addRawEvent(Map<String, Object?> event) {
    _events.add(TripTrackingPlatformEvent.fromMap(event));
  }

  Future<void> closeEvents() => _events.close();

  @override
  Future<TripTrackingPlatformCapabilities> readCapabilities() async {
    if (throwOnReadCapabilities) {
      throw StateError('capability probe failed');
    }
    return TripTrackingPlatformCapabilities(
      locationAvailable: true,
      backgroundTrackingAvailable: true,
      activityRecognitionAvailable: activityRecognitionAvailable,
      batteryStateAvailable: batteryStateAvailable,
      lowPowerModeAvailable: lowPowerModeAvailable,
    );
  }

  @override
  Future<TripTrackingBatterySnapshot> readBatterySnapshot() async =>
      throwOnReadBatterySnapshot
      ? throw StateError('battery snapshot failed')
      : batterySnapshot;

  @override
  Future<TripTrackingAuthorization> requestAuthorization({
    required bool allowBackground,
    required bool activityRecognitionEnabled,
  }) async {
    final exception = authorizationException;
    if (exception != null) throw exception;
    requestAuthorizationCalls += 1;
    return authorization;
  }

  @override
  Future<bool> start(TripTrackingNativeRequest request) async {
    final exception = startException;
    if (exception != null) throw exception;
    if (throwOnStart) throw StateError(startFailureMessage);
    beforeStart?.call();
    await startDelay;
    startCalls += 1;
    startedRequest = request;
    _running = true;
    return startSucceeds;
  }

  @override
  Future<bool> update(TripTrackingNativeRequest request) async {
    updateCalls += 1;
    updatedRequest = request;
    return updateSucceeds;
  }

  @override
  Future<void> stop() async {
    beforeStop?.call();
    stopCalls += 1;
    if (throwOnStop) throw StateError('native stop fault');
    _running = false;
  }

  @override
  Future<bool> get isTracking async {
    if (throwOnIsTracking) throw StateError('native status unavailable');
    return _running;
  }
}

class _FakeTripTrackingCloudMirror implements TripTrackingCloudMirror {
  final reviews = <TripTrackingReviewRecord>[];
  var flushCalls = 0;
  var throwOnFlush = false;

  @override
  Future<void> queueReview(TripTrackingReviewRecord review) async {
    reviews.add(review);
  }

  @override
  Future<void> flushPending() async {
    flushCalls += 1;
    if (throwOnFlush) throw StateError('temporary cloud outage');
  }

  @override
  Future<void> withdrawBackupConsent() async {}

  @override
  Future<void> withdrawOrganizationSharingConsent() async {}

  @override
  void dispose() {}
}

Future<TripTrackingSessionStore> _storeWithRawTripTrackingData({
  required String tempPrefix,
  required Map<String, Object?> activeSession,
  Map<String, Object?>? review,
  Map<String, Object?>? pending,
}) async {
  final hiveDirectory = await Directory.systemTemp.createTemp(tempPrefix);
  Hive.init(hiveDirectory.path);
  final box = await Hive.openBox<dynamic>(TripTrackingSessionStore.boxName);
  await box.put('activeSession', activeSession);
  final reviewId = review?['id'];
  if (reviewId is String) {
    await box.put('review:$reviewId', review);
  }
  final pendingSessionId = pending?['sessionId'];
  if (pendingSessionId is String) {
    await box.put('pending:$pendingSessionId', pending);
  }
  final store = await TripTrackingSessionStore.create();
  addTearDown(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      await hiveDirectory.delete(recursive: true);
    }
  });
  return store;
}

class _DelayedReviewSaveStore extends TripTrackingSessionStore {
  _DelayedReviewSaveStore() : super.memory();

  final reviewSaveStarted = Completer<void>();
  final allowReviewSave = Completer<void>();
  var reviewSaveCalls = 0;

  @override
  Future<void> saveReview(TripTrackingReviewRecord review) async {
    reviewSaveCalls += 1;
    reviewSaveStarted.complete();
    await allowReviewSave.future;
    await super.saveReview(review);
  }
}

class _DelayedConfirmationSaveStore extends TripTrackingSessionStore {
  _DelayedConfirmationSaveStore() : super.memory();

  final confirmationSaveStarted = Completer<void>();
  final allowConfirmationSave = Completer<void>();
  var delayWrites = false;
  var delayedSaveCalls = 0;

  @override
  Future<void> saveReview(TripTrackingReviewRecord review) async {
    if (!delayWrites) return super.saveReview(review);
    delayedSaveCalls += 1;
    confirmationSaveStarted.complete();
    await allowConfirmationSave.future;
    await super.saveReview(review);
  }
}

class _FailingNextSessionSaveStore extends TripTrackingSessionStore {
  _FailingNextSessionSaveStore() : super.memory();

  var failNextSessionSave = false;

  @override
  Future<void> save(TripTrackingSessionRecord session) async {
    if (failNextSessionSave) {
      failNextSessionSave = false;
      throw StateError('local session checkpoint failed');
    }
    return super.save(session);
  }
}

class _FailingReviewCleanupStore extends TripTrackingSessionStore {
  _FailingReviewCleanupStore() : super.memory();

  @override
  Future<void> clear() async {
    throw StateError('stale recovery cleanup failed');
  }
}

class _FailingPendingCleanupStore extends TripTrackingSessionStore {
  _FailingPendingCleanupStore() : super.memory();

  @override
  Future<void> clearPending(String sessionId) async {
    throw StateError('pending cleanup failed');
  }
}

class _NoopFirestoreSink implements MaintainiacFirestoreDocumentSink {
  @override
  Future<void> writeDocument({
    required String path,
    required Map<String, Object?> data,
  }) async {}
}
