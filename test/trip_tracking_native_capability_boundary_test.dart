import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_platform.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  final startedAt = DateTime.utc(2026, 7, 17, 12);

  test('background GPS cannot start when native capability is unavailable', () async {
    final native = _NativeCapabilityProbeFake(
      capabilities: const TripTrackingPlatformCapabilities(
        locationAvailable: true,
        backgroundTrackingAvailable: false,
        activityRecognitionAvailable: true,
      ),
    );
    final controller = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      odometer: GlobalOdometerController(vehicleId: "vehicle_1", initialReading: 1000),
      platform: native,
    );
    addTearDown(controller.dispose);

    await controller.start(
      tripId: 'trip_background_unavailable',
      vehicleId: 'vehicle_1',
      profile: TripTrackingProfile.roadVehicle,
      startedAt: startedAt,
    );

    expect(await controller.startNativeTracking(allowBackground: true), isFalse);
    expect(native.requestAuthorizationCalls, 0);
    expect(native.startCalls, 0);
    expect(controller.platformError, contains('Background GPS tracking is unavailable'));
  });

  test('unavailable activity recognition is stripped before native start', () async {
    final native = _NativeCapabilityProbeFake(
      capabilities: const TripTrackingPlatformCapabilities(
        locationAvailable: true,
        backgroundTrackingAvailable: true,
        activityRecognitionAvailable: false,
      ),
    );
    final controller = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      odometer: GlobalOdometerController(vehicleId: "vehicle_1", initialReading: 1000),
      platform: native,
    );
    addTearDown(controller.dispose);

    await controller.start(
      tripId: 'trip_motion_unavailable',
      vehicleId: 'vehicle_1',
      profile: TripTrackingProfile.roadVehicle,
      startedAt: startedAt,
    );

    expect(
      await controller.startNativeTracking(
        allowBackground: false,
        activityRecognitionEnabled: true,
      ),
      isTrue,
    );
    expect(native.authorizationActivityRecognitionEnabled, isFalse);
    expect(native.startedRequest?.activityRecognitionEnabled, isFalse);
  });

  test('unavailable activity recognition stays stripped during sampling updates', () async {
    final native = _NativeCapabilityProbeFake(
      capabilities: const TripTrackingPlatformCapabilities(
        locationAvailable: true,
        backgroundTrackingAvailable: true,
        activityRecognitionAvailable: false,
      ),
    );
    final controller = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      odometer: GlobalOdometerController(vehicleId: "vehicle_1", initialReading: 1000),
      platform: native,
    );
    addTearDown(controller.dispose);

    await controller.start(
      tripId: 'trip_motion_unavailable_update',
      vehicleId: 'vehicle_1',
      profile: TripTrackingProfile.roadVehicle,
      startedAt: startedAt,
    );
    await controller.startNativeTracking(
      allowBackground: false,
      activityRecognitionEnabled: true,
    );

    native.addLocation(_sample(-80, startedAt, 0, speed: 8));
    native.addLocation(_sample(-79.999, startedAt, 20, speed: 8));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(native.updatedRequest?.activityRecognitionEnabled, isFalse);
  });
}

TripLocationSample _sample(
  double longitude,
  DateTime start,
  int seconds, {
  double? speed,
}) => TripLocationSample(
  latitude: 35,
  longitude: longitude,
  recordedAt: start.add(Duration(seconds: seconds)),
  horizontalAccuracyMeters: 5,
  speedMetersPerSecond: speed,
);

class _NativeCapabilityProbeFake implements TripTrackingNativeGateway {
  _NativeCapabilityProbeFake({required this.capabilities});

  final TripTrackingPlatformCapabilities capabilities;
  final _events = StreamController<TripTrackingPlatformEvent>.broadcast();
  var requestAuthorizationCalls = 0;
  var startCalls = 0;
  bool? authorizationActivityRecognitionEnabled;
  TripTrackingNativeRequest? startedRequest;
  TripTrackingNativeRequest? updatedRequest;

  @override
  Stream<TripTrackingPlatformEvent> get events => _events.stream;

  @override
  Future<TripTrackingPlatformCapabilities> readCapabilities() async => capabilities;

  @override
  Future<TripTrackingBatterySnapshot> readBatterySnapshot() async =>
      const TripTrackingBatterySnapshot(
        batteryPercent: 100,
        isCharging: false,
        lowPowerModeEnabled: false,
      );

  @override
  Future<TripTrackingAuthorization> requestAuthorization({
    required bool allowBackground,
    required bool activityRecognitionEnabled,
  }) async {
    requestAuthorizationCalls += 1;
    authorizationActivityRecognitionEnabled = activityRecognitionEnabled;
    return const TripTrackingAuthorization(
      state: TripTrackingAuthorizationState.always,
      preciseLocation: true,
    );
  }

  @override
  Future<bool> start(TripTrackingNativeRequest request) async {
    startCalls += 1;
    startedRequest = request;
    return true;
  }

  @override
  Future<bool> update(TripTrackingNativeRequest request) async {
    updatedRequest = request;
    return true;
  }

  @override
  Future<void> stop() async {}

  @override
  Future<bool> get isTracking async => startCalls > 0;

  void addLocation(TripLocationSample sample) {
    _events.add(
      TripTrackingPlatformEvent.fromMap({
        'type': 'location',
        ...sample.toMap(),
      }),
    );
  }
}
