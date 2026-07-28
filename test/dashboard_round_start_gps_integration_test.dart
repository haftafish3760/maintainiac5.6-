import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/dashboard/dashboard.dart';
import 'package:maintaniac/screens/dashboard/data/active_workday_store.dart';
import 'package:maintaniac/screens/expenses/data/expense_work_profile_store.dart';
import 'package:maintaniac/shared/state/app_state.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_platform.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';

class _RoundStartGpsGateway implements TripTrackingNativeGateway {
  _RoundStartGpsGateway({this.locationAvailable = true});

  final _events = StreamController<TripTrackingPlatformEvent>.broadcast();
  final bool locationAvailable;
  bool running = false;
  int capabilityReadCalls = 0;
  int startCalls = 0;

  @override
  Stream<TripTrackingPlatformEvent> get events => _events.stream;

  @override
  Future<bool> get isTracking async => running;

  @override
  Future<TripTrackingPlatformCapabilities> readCapabilities() async {
    capabilityReadCalls += 1;
    return TripTrackingPlatformCapabilities(
      locationAvailable: locationAvailable,
      backgroundTrackingAvailable: true,
      activityRecognitionAvailable: true,
      batteryStateAvailable: true,
    );
  }

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
    running = true;
    _events.add(
      TripTrackingPlatformEvent.fromMap({'type': 'status', 'status': 'tracking'}),
    );
    return true;
  }

  @override
  Future<bool> update(TripTrackingNativeRequest request) async => true;

  @override
  Future<void> stop() async => running = false;

  Future<void> close() => _events.close();
}

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  String? reason,
  String Function()? diagnostic,
}) async {
  for (var attempt = 0; attempt < 40; attempt += 1) {
    if (condition()) {
      await tester.pump();
      return;
    }
    await tester.pump(const Duration(milliseconds: 25));
  }
  expect(
    condition(),
    isTrue,
    reason: diagnostic == null ? reason : '${reason ?? ''} ${diagnostic()}',
  );
}

void main() {
  testWidgets('round Start Day remains manual when GPS assistance is off', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 1800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final appState = AppStateController();
    final workProfiles = ExpenseWorkProfileController.memory();
    final workday = ActiveWorkdayController.memory();
    final odometer = GlobalOdometerController(initialReading: 12000);
    final gateway = _RoundStartGpsGateway();
    final trip = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      odometer: odometer,
      platform: gateway,
    );
    final settings = TripTrackingSettingsController.memory(
      const TripTrackingSettings(
        tripTrackingSetupCompleted: true,
        gpsAssistedTrackingEnabled: false,
      ),
    );
    addTearDown(appState.dispose);
    addTearDown(workProfiles.dispose);
    addTearDown(workday.dispose);
    addTearDown(odometer.dispose);
    addTearDown(settings.dispose);
    addTearDown(() async {
      trip.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await gateway.close();
    });

    await tester.pumpWidget(
      AppStateScope(
        controller: appState,
        child: ExpenseWorkProfileScope(
          controller: workProfiles,
          child: ActiveWorkdayScope(
            controller: workday,
            child: GlobalOdometerScope(
              controller: odometer,
              child: TripTrackingSettingsScope(
                controller: settings,
                child: TripTrackingScope(
                  controller: trip,
                  child: const MaterialApp(home: DashboardScreen()),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('START'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review Start Day'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start Workday'));
    await _pumpUntil(
      tester,
      () => workday.activeSession != null,
      reason: 'The manual workday did not become active.',
    );

    expect(workday.activeSession, isNotNull);
    expect(gateway.startCalls, 0);
    expect(trip.activeSession, isNull);
    expect(trip.nativeTracking, isFalse);
    expect(odometer.confirmedReading, 12000);
  });

  testWidgets('round Start Day launches opted-in native GPS assistance', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 1800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final appState = AppStateController();
    final workProfiles = ExpenseWorkProfileController.memory();
    final workday = ActiveWorkdayController.memory();
    final odometer = GlobalOdometerController(initialReading: 12000);
    final gateway = _RoundStartGpsGateway();
    final trip = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      odometer: odometer,
      platform: gateway,
    );
    final settings = TripTrackingSettingsController.memory(
      const TripTrackingSettings(
        tripTrackingSetupCompleted: true,
        gpsAssistedTrackingEnabled: true,
        activityRecognitionEnabled: true,
      ),
    );
    addTearDown(appState.dispose);
    addTearDown(workProfiles.dispose);
    addTearDown(workday.dispose);
    addTearDown(odometer.dispose);
    addTearDown(settings.dispose);
    addTearDown(() async {
      trip.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await gateway.close();
    });

    await tester.pumpWidget(
      AppStateScope(
        controller: appState,
        child: ExpenseWorkProfileScope(
          controller: workProfiles,
          child: ActiveWorkdayScope(
            controller: workday,
            child: GlobalOdometerScope(
              controller: odometer,
              child: TripTrackingSettingsScope(
                controller: settings,
                child: TripTrackingScope(
                  controller: trip,
                  child: const MaterialApp(home: DashboardScreen()),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('START'));
    await tester.pumpAndSettle();
    expect(find.text('Starting Odometer'), findsOneWidget);
    await tester.tap(find.text('Review Start Day'));
    await tester.pumpAndSettle();
    expect(find.text('Ready to Start Day'), findsOneWidget);
    await tester.tap(find.text('Start Workday'));
    await _pumpUntil(
      tester,
      () =>
          gateway.startCalls == 1 &&
          trip.nativeTracking &&
          trip.lifecycleState == TripTrackingSessionLifecycleState.active,
      reason: 'The opted-in native GPS start did not finish.',
    );

    expect(workday.activeSession, isNotNull);
    expect(gateway.startCalls, 1);
    expect(trip.nativeTracking, isTrue);
    expect(odometer.confirmedReading, 12000);
  });

  testWidgets('unavailable GPS never blocks the manual workday', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 1800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final appState = AppStateController();
    final workProfiles = ExpenseWorkProfileController.memory();
    final workday = ActiveWorkdayController.memory();
    final odometer = GlobalOdometerController(initialReading: 12000);
    final gateway = _RoundStartGpsGateway(locationAvailable: false);
    final trip = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      odometer: odometer,
      platform: gateway,
    );
    final settings = TripTrackingSettingsController.memory(
      const TripTrackingSettings(
        tripTrackingSetupCompleted: true,
        gpsAssistedTrackingEnabled: true,
      ),
    );
    addTearDown(appState.dispose);
    addTearDown(workProfiles.dispose);
    addTearDown(workday.dispose);
    addTearDown(odometer.dispose);
    addTearDown(settings.dispose);
    addTearDown(() async {
      trip.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await gateway.close();
    });

    await tester.pumpWidget(
      AppStateScope(
        controller: appState,
        child: ExpenseWorkProfileScope(
          controller: workProfiles,
          child: ActiveWorkdayScope(
            controller: workday,
            child: GlobalOdometerScope(
              controller: odometer,
              child: TripTrackingSettingsScope(
                controller: settings,
                child: TripTrackingScope(
                  controller: trip,
                  child: const MaterialApp(home: DashboardScreen()),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('START'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review Start Day'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start Workday'));
    await _pumpUntil(
      tester,
      () =>
          workday.activeSession != null &&
          gateway.capabilityReadCalls == 1 &&
          !trip.isTracking &&
          trip.activeSession == null,
      reason: 'The GPS-unavailable fallback did not finish.',
      diagnostic: () =>
          'workday=${workday.activeSession != null}; reads=${gateway.capabilityReadCalls}; tracking=${trip.isTracking}; session=${trip.activeSession?.lifecycleState}; native=${trip.nativeTracking}; error=${trip.platformError}',
    );

    expect(workday.activeSession, isNotNull);
    expect(gateway.startCalls, 0);
    expect(
      trip.isTracking,
      isFalse,
      reason:
          'status=${trip.platformStatus}; error=${trip.platformError}; native=${trip.nativeTracking}; location=${trip.lastKnownCapabilities?.locationAvailable}',
    );
    expect(trip.activeSession, isNull);
    expect(trip.nativeTracking, isFalse);
    expect(
      find.text(
        'Device location is unavailable. Your workday is active and manual mileage is still available.',
      ),
      findsWidgets,
    );
    expect(odometer.confirmedReading, 12000);
  });
}
