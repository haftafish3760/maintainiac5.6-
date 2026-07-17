import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_upload_queue.dart';
import 'package:maintaniac/shared/odometer/odometer_mileage_review.dart';
import 'package:maintaniac/shared/odometer/odometer_validation.dart';
import 'package:maintaniac/shared/storage/app_storage_guard.dart';
import 'package:maintaniac/shared/state/global_odometer.dart'
    as global_odometer;
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_firebase_bridge.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_platform.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

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
    double accuracy = 5,
  }) => TripLocationSample(
    latitude: 35,
    longitude: longitude,
    recordedAt: start.add(Duration(seconds: seconds)),
    horizontalAccuracyMeters: accuracy,
    speedMetersPerSecond: speed,
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
          batteryPercent: 19,
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
      expect(controller.platformError, contains('below 20% battery'));
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
          batteryPercent: 5,
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
      expect(controller.platformError, contains('blocked below 20% battery'));
    },
  );

  test('low battery override allows GPS startup', () async {
    final native = _FakeTripTrackingPlatform(
      batterySnapshot: const TripTrackingBatterySnapshot(
        batteryPercent: 5,
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

  test('native samples are serialized through the trip controller', () async {
    final native = _FakeTripTrackingPlatform();
    final odometer = GlobalOdometerController(initialReading: 1000);
    final controller = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      odometer: odometer,
      platform: native,
    );
    await controller.start(
      tripId: 'trip_native',
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
    native.addLocation(sample(-79.9996, 35));
    native.addLocation(sample(-79.985, 60));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

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
      native.addLocation(sample(-79.999, 20, speed: 8));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(
        controller.platformError,
        'GPS event could not be processed safely.',
      );
      expect(controller.platformError, isNot(contains('available')));
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
    expect(controller.platformError, contains('could not register'));
    expect(native.stopCalls, 1);
  });

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
        await controller.startNativeTracking(allowBackground: false),
        isTrue,
      );
      expect(native.startCalls, 2);
    },
  );

  test(
    'disposing the controller detaches its native GPS event listener',
    () async {
      final native = _FakeTripTrackingPlatform();
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
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

      expect(native.hasEventListener, isFalse);
      expect(native.stopCalls, 0);
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
      native.addLocation(sample(-79.999, 20, speed: 8));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(restored.acceptedMeters, greaterThan(0));
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

  test('accepted GPS distance updates the global live odometer only', () async {
    final odometer = GlobalOdometerController(initialReading: 1000);
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
    expect(controller.acceptedMeters, greaterThan(0));
  });

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
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(native.updatedRequest?.sampling.mode, TripSamplingMode.precision);
      expect(
        native.updatedRequest?.sampling.interval,
        const Duration(seconds: 2),
      );
      expect(native.updateCalls, 1);
    },
  );

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
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(native.updatedRequest?.sampling.mode, TripSamplingMode.precision);

      native.addLocation(sample(-79.999, 22, speed: 0));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(native.updatedRequest?.sampling.mode, TripSamplingMode.balanced);
      expect(
        native.updatedRequest?.sampling.interval,
        const Duration(seconds: 5),
      );
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
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

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
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: odometer,
        cloudMirror: mirror,
      );
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

  test('corrupt local trip identity is cleared instead of restored', () async {
    final store = TripTrackingSessionStore.memory();
    await store.save(
      TripTrackingSessionRecord(
        id: 'trip_\ncorrupt',
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
    final store = TripTrackingSessionStore.memory();
    await store.save(
      TripTrackingSessionRecord.fromMap({
        'id': 'trip_missing_timeline',
        'vehicleId': 'vehicle_1',
        'startingOdometer': 1000,
        'profile': 'roadVehicle',
        'engineSnapshot': {
          'totalAcceptedMeters': 0,
          'walkingReviewSuggested': false,
        },
      }),
    );
    final controller = TripTrackingController(
      sessionStore: store,
      odometer: GlobalOdometerController(initialReading: 1000),
    );

    expect(await controller.restore(), isFalse);
    expect(store.activeSession, isNull);
    expect(controller.isTracking, isFalse);
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
    final store = TripTrackingSessionStore.memory();
    await store.save(
      TripTrackingSessionRecord(
        id: 'trip_invalid_review',
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
      TripTrackingReviewRecord.fromMap({
        'id': 'trip_invalid_review',
        'vehicleId': 'vehicle_1',
        'startingOdometer': 1000,
        'estimatedEndingOdometer': 1001,
        'profile': 'roadVehicle',
        'engineSnapshot': {
          'totalAcceptedMeters': 0,
          'walkingReviewSuggested': false,
        },
      }),
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
    await store.saveReview(review);
    final mirror = _FakeTripTrackingCloudMirror();
    final controller = TripTrackingController(
      sessionStore: store,
      odometer: GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      ),
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
    expect(mirror.reviews, isEmpty);
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
}

class _FakeTripTrackingPlatform implements TripTrackingNativeGateway {
  _FakeTripTrackingPlatform({
    this.authorization = const TripTrackingAuthorization(
      state: TripTrackingAuthorizationState.always,
      preciseLocation: true,
    ),
    this.throwOnStart = false,
    this.throwOnStop = false,
    this.throwOnIsTracking = false,
    this.throwOnReadCapabilities = false,
    this.throwOnReadBatterySnapshot = false,
    this.startFailureMessage = 'native start fault',
    this.batterySnapshot = const TripTrackingBatterySnapshot(
      batteryPercent: 100,
      isCharging: false,
      lowPowerModeEnabled: false,
    ),
    this.startDelay,
  });

  final _events = StreamController<TripTrackingPlatformEvent>.broadcast();
  final TripTrackingAuthorization authorization;
  final bool throwOnStart;
  final bool throwOnStop;
  final bool throwOnIsTracking;
  final bool throwOnReadCapabilities;
  final bool throwOnReadBatterySnapshot;
  final String startFailureMessage;
  final TripTrackingBatterySnapshot batterySnapshot;
  final Future<void>? startDelay;
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

  void addStatus(String status) {
    _events.add(
      TripTrackingPlatformEvent.fromMap({'type': 'status', 'status': status}),
    );
  }

  Future<void> closeEvents() => _events.close();

  @override
  Future<TripTrackingPlatformCapabilities> readCapabilities() async {
    if (throwOnReadCapabilities) {
      throw StateError('capability probe failed');
    }
    return const TripTrackingPlatformCapabilities(
      locationAvailable: true,
      backgroundTrackingAvailable: true,
      activityRecognitionAvailable: false,
      batteryStateAvailable: true,
      lowPowerModeAvailable: true,
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
    requestAuthorizationCalls += 1;
    return authorization;
  }

  @override
  Future<bool> start(TripTrackingNativeRequest request) async {
    if (throwOnStart) throw StateError(startFailureMessage);
    await startDelay;
    startCalls += 1;
    startedRequest = request;
    _running = true;
    return true;
  }

  @override
  Future<bool> update(TripTrackingNativeRequest request) async {
    updateCalls += 1;
    updatedRequest = request;
    return true;
  }

  @override
  Future<void> stop() async {
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

class _NoopFirestoreSink implements MaintainiacFirestoreDocumentSink {
  @override
  Future<void> writeDocument({
    required String path,
    required Map<String, Object?> data,
  }) async {}
}
