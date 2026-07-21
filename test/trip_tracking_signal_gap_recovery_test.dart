import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_platform.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_route_point_store.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';

class _GapPlatform implements TripTrackingNativeGateway {
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

TripLocationSample _sample(DateTime at, double longitude) => TripLocationSample(
  latitude: 35,
  longitude: longitude,
  recordedAt: at,
  horizontalAccuracyMeters: 5,
  speedMetersPerSecond: 8,
);

void main() {
  test(
    'missing native collector recovers active trip as system-paused',
    () async {
      final startedAt = DateTime.utc(2026, 7, 21, 12);
      final now = startedAt.add(const Duration(minutes: 10));
      final store = TripTrackingSessionStore.memory();
      await store.save(
        TripTrackingSessionRecord(
          id: 'reboot_recovery_trip',
          vehicleId: 'vehicle_1',
          startingOdometer: 1000,
          profile: TripTrackingProfile.roadVehicle,
          startedAt: startedAt,
          updatedAt: startedAt.add(const Duration(minutes: 5)),
          engineSnapshot: const TripTrackingEngineSnapshot(
            totalAcceptedMeters: 1000,
            walkingReviewSuggested: false,
          ),
          lifecycleState: TripTrackingSessionLifecycleState.active,
        ),
      );
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
        platform: _GapPlatform(),
        clockNow: () => now,
      );

      expect(await controller.restore(), isTrue);
      expect(
        controller.lifecycleState,
        TripTrackingSessionLifecycleState.paused,
      );
      expect(controller.platformStatus, 'recovery_paused_native_missing');
      expect(controller.acceptedMeters, 1000);
      expect(controller.signalGaps, hasLength(1));
      expect(controller.signalGaps.single.isOpen, isTrue);
      expect(
        controller.signalGaps.single.reason,
        TripTrackingSignalGapReason.systemPause,
      );
    },
  );

  test('pause gap is durable and cannot create teleport mileage', () async {
    final startedAt = DateTime.utc(2026, 7, 21, 12);
    var now = startedAt;
    final platform = _GapPlatform();
    final routeStore = TripTrackingRoutePointStore.memory();
    final controller = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      odometer: GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      ),
      platform: platform,
      clockNow: () => now,
      routePointStore: routeStore,
      routeSettings: () => const TripTrackingSettings(
        gpsAssistedTrackingEnabled: true,
        mapPreviewEnabled: true,
        mapRouteHistorySavingEnabled: true,
        mapRouteHistoryDailyBudgetMb: 1,
        mapRouteHistorySampleIntervalSeconds: 30,
      ),
      localRouteDayKey: (_) => '2026-07-21',
    );

    expect(
      await controller.start(
        tripId: 'trip_signal_gap',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: startedAt,
      ),
      isTrue,
    );
    expect(
      await controller.startNativeTracking(allowBackground: false),
      isTrue,
    );
    platform.addLocation(_sample(startedAt, -80));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    final acceptedBeforePause = controller.acceptedMeters;
    expect(
      controller.initialFixAssessment?.quality,
      TripInitialFixQuality.freshPrecise,
    );
    expect(controller.initialFixAssessment?.canConfirmMileage, isFalse);
    expect(routeStore.pointsForTrip('trip_signal_gap'), hasLength(1));
    expect(controller.routeStorageStatus, 'route_point_saved_locally');
    expect(
      controller.activeSession!.engineSnapshot.initialFixAssessment?.quality,
      TripInitialFixQuality.freshPrecise,
    );

    now = startedAt.add(const Duration(minutes: 2));
    await controller.stopNativeTracking();
    expect(controller.signalGaps, hasLength(1));
    expect(controller.signalGaps.single.isOpen, isTrue);
    expect(controller.activeSession!.engineSnapshot.signalGaps, hasLength(1));

    now = startedAt.add(const Duration(minutes: 12));
    expect(
      await controller.startNativeTracking(allowBackground: false),
      isTrue,
    );
    platform.addLocation(_sample(now, -79.98));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(controller.signalGaps.single.isOpen, isFalse);
    expect(controller.signalGaps.single.estimatedDistanceMeters, 0);
    expect(controller.signalGaps.single.requiresUserReview, isTrue);
    expect(controller.signalGaps.single.canChangeOdometer, isFalse);
    expect(controller.acceptedMeters, acceptedBeforePause);

    final restored = TripTrackingEngineSnapshot.fromMap(
      controller.activeSession!.engineSnapshot.toMap(),
    );
    expect(restored.signalGaps, hasLength(1));
    expect(restored.signalGaps.single.isOpen, isFalse);
    await platform._events.close();
  });
}
