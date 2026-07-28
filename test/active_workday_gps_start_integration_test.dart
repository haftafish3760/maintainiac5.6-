import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/dashboard/active_workday_screen.dart';
import 'package:maintaniac/screens/dashboard/data/active_workday_store.dart';
import 'package:maintaniac/screens/dashboard/vehicle_profile_widgets.dart';
import 'package:maintaniac/shared/state/app_state.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_platform.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';

class _DashboardGpsGateway implements TripTrackingNativeGateway {
  final _events = StreamController<TripTrackingPlatformEvent>.broadcast();
  bool running = false;
  int startCalls = 0;
  TripTrackingNativeRequest? request;

  void addLocation(TripLocationSample sample) => _events.add(
    TripTrackingPlatformEvent.fromMap({
      ...sample.toMap(),
      'schemaVersion': 1,
      'type': TripTrackingPlatformEventType.location.name,
    }),
  );

  void addStatus(String status) => _events.add(
    TripTrackingPlatformEvent.fromMap({'type': 'status', 'status': status}),
  );

  @override
  Stream<TripTrackingPlatformEvent> get events => _events.stream;

  @override
  Future<bool> get isTracking async => running;

  @override
  Future<TripTrackingPlatformCapabilities> readCapabilities() async =>
      const TripTrackingPlatformCapabilities(
        locationAvailable: true,
        backgroundTrackingAvailable: true,
        activityRecognitionAvailable: true,
        batteryStateAvailable: true,
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
  }) async => const TripTrackingAuthorization(
    state: TripTrackingAuthorizationState.always,
    preciseLocation: true,
  );

  @override
  Future<bool> start(TripTrackingNativeRequest request) async {
    startCalls += 1;
    this.request = request;
    running = true;
    addStatus('tracking');
    return true;
  }

  @override
  Future<bool> update(TripTrackingNativeRequest request) async => true;

  @override
  Future<void> stop() async => running = false;

  Future<void> dispose() => _events.close();
}

void main() {
  testWidgets('dashboard start binds one native trip to active work context', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 1500);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final appState = AppStateController();
    final workday = ActiveWorkdayController.memory();
    final odometer = GlobalOdometerController(
      vehicleId: 'vehicle_1',
      initialReading: 12000,
    );
    final gateway = _DashboardGpsGateway();
    var clock = DateTime.utc(2026, 7, 22, 12);
    final trip = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      odometer: odometer,
      platform: gateway,
      clockNow: () => clock,
    );
    final settings = TripTrackingSettingsController.memory(
      const TripTrackingSettings(
        tripTrackingSetupCompleted: true,
        gpsAssistedTrackingEnabled: true,
        samplingPreset: TripTrackingSamplingPreset.highAccuracy,
        activityRecognitionEnabled: true,
      ),
    );
    addTearDown(appState.dispose);
    addTearDown(workday.dispose);
    addTearDown(odometer.dispose);
    addTearDown(trip.dispose);
    addTearDown(settings.dispose);
    addTearDown(gateway.dispose);
    await workday.startDay(
      vehicleId: 'vehicle_1',
      vehicleLabel: 'Work Truck',
      workProfileId: 'profile_delivery',
      startOdometer: 12000,
    );

    await tester.pumpWidget(
      AppStateScope(
        controller: appState,
        child: ActiveWorkdayScope(
          controller: workday,
          child: GlobalOdometerScope(
            controller: odometer,
            child: TripTrackingSettingsScope(
              controller: settings,
              child: TripTrackingScope(
                controller: trip,
                child: MaterialApp(
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: const TextScaler.linear(2)),
                    child: child!,
                  ),
                  home: const ActiveWorkdayScreen(
                    activeVehicle: VehicleProfilePreview(
                      id: 'vehicle_1',
                      nickname: 'Work Truck',
                      year: '2026',
                      make: 'Ford',
                      model: 'Transit',
                      odometer: '0012000',
                      status: 'ACTIVE',
                    ),
                    workProfileName: 'Delivery',
                    startGpsWhenOpened: true,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(gateway.startCalls, 1);
    expect(gateway.running, isTrue);
    expect(trip.nativeTracking, isTrue);
    expect(trip.activeSession?.vehicleId, 'vehicle_1');
    expect(trip.activeSession?.effectiveProfileId, 'profile_delivery');
    expect(gateway.request?.activityRecognitionEnabled, isTrue);
    expect(gateway.request?.sampling.interval, const Duration(seconds: 2));
    expect(gateway.request?.sampling.minimumDisplacementMeters, 1);
    expect(odometer.confirmedReading, 12000);
    expect(find.textContaining('• GPS live'), findsOneWidget);

    final sessionId = trip.activeSession?.id;
    gateway.running = false;
    gateway.addStatus('paused');
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    expect(trip.nativeTracking, isFalse);
    expect(trip.activeSession?.pauseKind, TripTrackingPauseKind.user);
    expect(
      trip.signalGaps.single.reason,
      TripTrackingSignalGapReason.userPause,
    );
    expect(find.textContaining('• Location paused'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'RESUME'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'RESUME'));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    expect(gateway.startCalls, 2);
    expect(gateway.running, isTrue);
    expect(trip.activeSession?.id, sessionId);
    expect(odometer.confirmedReading, 12000);

    gateway.addLocation(
      TripLocationSample(
        latitude: 35,
        longitude: -80,
        recordedAt: clock,
        horizontalAccuracyMeters: 5,
        speedMetersPerSecond: 10,
      ),
    );
    await tester.pump();
    clock = clock.add(const Duration(seconds: 15));
    gateway.addLocation(
      TripLocationSample(
        latitude: 35,
        longitude: -79.9985,
        recordedAt: clock,
        horizontalAccuracyMeters: 5,
        speedMetersPerSecond: 10,
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(trip.acceptedMeters, greaterThan(100));
    expect(trip.signalGaps, hasLength(1));
    expect(trip.signalGaps.single.isOpen, isFalse);

    await tester.tap(find.widgetWithText(FilledButton, 'STOP'));
    await tester.pump();
    expect(find.text('Stop Location Tracking?'), findsOneWidget);
    await tester.tap(
      find.widgetWithText(FilledButton, 'Stop Location Tracking'),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    for (
      var attempt = 0;
      attempt < 40 &&
          (trip.isTracking ||
              find.text('Review GPS Trip Odometer').evaluate().isEmpty);
      attempt += 1
    ) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(gateway.running, isFalse);
    expect(
      trip.isTracking,
      isFalse,
      reason:
          'state=${trip.activeSession?.lifecycleState}; '
          'status=${trip.platformStatus}; error=${trip.platformError}; '
          'review=${trip.latestUnconfirmedReview?.id}',
    );
    // GPS review remains available as a configurable Active Day quick action;
    // the compact status line must not recreate the removed GPS panel.
    expect(trip.latestUnconfirmedReview, isNotNull);
    expect(odometer.confirmedReading, 12000);

    await tester.binding.handlePopRoute();
    await tester.pump();

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
