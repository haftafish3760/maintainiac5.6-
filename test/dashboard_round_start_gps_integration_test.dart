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
      TripTrackingPlatformEvent.fromMap({
        'type': 'status',
        'status': 'tracking',
      }),
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

Future<void> _completeGuidedStartDay(WidgetTester tester) async {
  await tester.tap(find.text('Start day'));
  await tester.pumpAndSettle();
  expect(find.text('Start workday'), findsOneWidget);
  await tester.tap(find.text('Continue to odometer'));
  await tester.pumpAndSettle();
  expect(find.text('Enter Current Odometer'), findsOneWidget);
  await tester.tap(find.text('Start Day'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'command-center Start Day remains manual when GPS assistance is off',
    (tester) async {
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

      await _completeGuidedStartDay(tester);
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
      expect(find.byTooltip('Open contractor dashboard'), findsOneWidget);

      // Ending a manual day must return to the Dashboard's ready state. This
      // protects the root Dashboard path used after an app relaunch. In that
      // state ActiveWorkdayScreen is not a pushed route, so ending the day
      // must never pop the only app route to an empty surface.
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
      expect(find.text('Shift Timer'), findsOneWidget);
      await tester.tap(find.text('End Day'));
      await tester.pumpAndSettle();
      expect(find.text('Ending Odometer'), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, '11999');
      await tester.tap(find.text('End Day').last);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('cannot end below its starting odometer'),
        findsOneWidget,
      );
      expect(
        find.textContaining('reviewed odometer correction flow'),
        findsOneWidget,
      );
      expect(workday.activeSession, isNotNull);
      expect(find.text('Ending Odometer'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('End Day'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('End Day').last);
      await tester.pumpAndSettle();
      expect(workday.activeSession, isNull);
      expect(find.text('Delivery dashboard'), findsOneWidget);
    },
  );

  testWidgets(
    'command-center Start Day launches opted-in native GPS assistance',
    (tester) async {
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

      await _completeGuidedStartDay(tester);
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
    },
  );

  testWidgets(
    'ending a GPS-assisted root workday returns to the ready Dashboard',
    (tester) async {
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

      await _completeGuidedStartDay(tester);
      await _pumpUntil(
        tester,
        () => trip.nativeTracking,
        reason: 'GPS assistance did not start before End Day.',
      );
      await tester.tap(find.text('End Day'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      await _pumpUntil(
        tester,
        () => find.text('Review GPS Trip Odometer').evaluate().isNotEmpty,
        reason: 'GPS End Day did not open the odometer review.',
        diagnostic: () =>
            'tracking=${trip.isTracking}; '
            'lifecycle=${trip.lifecycleState}; '
            'status=${trip.platformStatus}; '
            'error=${trip.platformError}; '
            'review=${trip.latestUnconfirmedReview?.id}',
      );
      expect(find.text('Review GPS Trip Odometer'), findsWidgets);
      await tester.enterText(find.byType(TextField).first, '12001');
      await tester.pump();
      // A real keypad Done/Next action must open the mileage-classification
      // step, never an empty route, after the driver changes the reading.
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('You added 1 miles.'), findsOneWidget);
      expect(find.text('Business'), findsOneWidget);
      expect(workday.activeSession, isNotNull);
      expect(trip.activeSession, isNull);
      expect(odometer.confirmedReading, 12000);
      expect(tester.takeException(), isNull);
    },
  );

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

    await _completeGuidedStartDay(tester);
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
