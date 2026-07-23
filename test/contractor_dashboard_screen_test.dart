import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/dashboard/active_workday_screen.dart';
import 'package:maintaniac/screens/dashboard/dashboard.dart';
import 'package:maintaniac/screens/dashboard/data/active_workday_store.dart';
import 'package:maintaniac/screens/dashboard/vehicle_profile_widgets.dart';
import 'package:maintaniac/screens/expenses/data/expense_work_profile_store.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_documents.dart';
import 'package:maintaniac/shared/state/app_state.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_firebase_bridge.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_platform.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';

void main() {
  late AppStateController appState;
  late GlobalOdometerController odometer;
  late ExpenseWorkProfileController workProfiles;

  setUp(() {
    appState = AppStateController();
    odometer = GlobalOdometerController();
    workProfiles = ExpenseWorkProfileController.memory();
  });

  tearDown(() {
    appState.dispose();
    odometer.dispose();
  });

  testWidgets('dashboard opens contractor command center', (tester) async {
    await _pumpDashboard(tester, appState, odometer, workProfiles);

    expect(find.text('Contractor Dashboard'), findsOneWidget);

    await tester.tap(find.text('Contractor Dashboard'));
    await tester.pumpAndSettle();

    expect(find.text('Contractor Command Center'), findsOneWidget);
    expect(find.text('Mode'), findsOneWidget);
    expect(find.text('Contractor'), findsOneWidget);
    expect(find.text('Operations Pulse'), findsOneWidget);
    expect(find.text('Vehicles Active'), findsOneWidget);
    expect(find.text('Employees Active'), findsOneWidget);
    expect(find.text('Needs Attention'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Money In'),
      360,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Money In'), findsOneWidget);
    expect(find.text('Money Out'), findsOneWidget);
  });

  testWidgets('contractor dashboard exposes active day tools', (tester) async {
    final activeWorkday = ActiveWorkdayController.memory();
    await _pumpDashboard(
      tester,
      appState,
      odometer,
      workProfiles,
      activeWorkday: activeWorkday,
    );

    await tester.tap(find.text('Contractor Dashboard'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Start Day'),
      220,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Start Day'));
    await tester.pumpAndSettle();

    expect(find.text('Active Contractor Day'), findsOneWidget);
    expect(activeWorkday.activeSession, isNotNull);
    expect(activeWorkday.activeSession?.vehicleId, odometer.vehicleId);
    expect(find.text('Shift Time'), findsOneWidget);
    expect(find.text('Miles Today'), findsOneWidget);
    expect(find.text('14.2'), findsNothing);
    expect(find.text('Add Stop'), findsOneWidget);
    expect(find.text('Job Note'), findsOneWidget);
    expect(find.text('Use Materials'), findsOneWidget);
    expect(find.text('Add Expense'), findsOneWidget);
    expect(find.text('Create Invoice'), findsOneWidget);
    expect(find.text('Record Payment'), findsOneWidget);
    expect(find.text('Proof Photo'), findsNothing);

    await tester.tap(find.text('Add Stop'));
    await tester.pumpAndSettle();
    expect(
      activeWorkday.activeSession?.events.last.type,
      ActiveWorkdayEventType.stop,
    );

    await tester.tap(find.text('Job Note'));
    await tester.pumpAndSettle();
    expect(
      activeWorkday.activeSession?.events.last.type,
      ActiveWorkdayEventType.note,
    );
  });

  testWidgets('contractor day controls persist pause resume and end events', (
    tester,
  ) async {
    final activeWorkday = ActiveWorkdayController.memory();
    await _pumpDashboard(
      tester,
      appState,
      odometer,
      workProfiles,
      activeWorkday: activeWorkday,
    );

    await tester.tap(find.text('Contractor Dashboard'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Start Day'),
      220,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Start Day'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pause Day'));
    await tester.pumpAndSettle();
    expect(activeWorkday.activeSession?.status, ActiveWorkdayStatus.paused);
    expect(find.text('Resume Day'), findsOneWidget);

    await tester.tap(find.text('Resume Day'));
    await tester.pumpAndSettle();
    expect(activeWorkday.activeSession?.status, ActiveWorkdayStatus.active);

    await tester.tap(find.text('End Day'));
    await tester.pumpAndSettle();
    expect(activeWorkday.activeSession, isNull);
    expect(find.text('Start Contractor Day'), findsOneWidget);
  });

  testWidgets('contractor record payment opens the payment workflow', (
    tester,
  ) async {
    final activeWorkday = ActiveWorkdayController.memory();
    await _pumpDashboard(
      tester,
      appState,
      odometer,
      workProfiles,
      activeWorkday: activeWorkday,
    );

    await tester.tap(find.text('Contractor Dashboard'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Start Day'),
      220,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Start Day'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Record Payment'));
    await tester.pumpAndSettle();

    expect(find.text('Payments'), findsWidgets);
    expect(find.text('Payment Amount'), findsOneWidget);
  });

  testWidgets('contractor quick stop requires a persisted active day', (
    tester,
  ) async {
    await _pumpDashboard(tester, appState, odometer, workProfiles);

    await tester.tap(find.text('Contractor Dashboard'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Start Day'),
      220,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Start Day'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Stop'));
    await tester.pumpAndSettle();

    expect(
      find.text('Start your contractor day before using Add Stop.'),
      findsOneWidget,
    );
  });

  testWidgets('active workday miles redraw from live GPS odometer projection', (
    tester,
  ) async {
    odometer.dispose();
    odometer = GlobalOdometerController(initialReading: 1000);
    final activeWorkday = ActiveWorkdayController.memory();
    await activeWorkday.startDay(
      vehicleId: odometer.vehicleId,
      vehicleLabel: 'Work Truck',
      workProfileId: 'business',
      startOdometer: 1000,
      startedAt: DateTime(2026, 7, 16, 8),
    );

    await tester.pumpWidget(
      AppStateScope(
        controller: appState,
        child: ActiveWorkdayScope(
          controller: activeWorkday,
          child: GlobalOdometerScope(
            controller: odometer,
            child: const MaterialApp(
              home: ActiveWorkdayScreen(
                activeVehicle: VehicleProfilePreview(
                  id: 'vehicle_1',
                  nickname: 'Work Truck',
                  year: '2026',
                  make: 'Ford',
                  model: 'Transit',
                  odometer: '0001000',
                  status: 'ACTIVE',
                ),
                workProfileName: 'Business',
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Miles Today'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);

    expect(
      odometer.beginLiveTripProjection(
        tripId: 'gps-trip-active-day',
        startingOdometer: 1000,
      ),
      isTrue,
    );
    expect(
      odometer.updateLiveTripProjection(
        tripId: 'gps-trip-active-day',
        estimatedOdometer: 1005,
      ),
      isTrue,
    );
    await tester.pump();

    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('active workday odometer redraws from accepted GPS samples', (
    tester,
  ) async {
    odometer.dispose();
    odometer = GlobalOdometerController(initialReading: 1000);
    final activeWorkday = ActiveWorkdayController.memory();
    await activeWorkday.startDay(
      vehicleId: odometer.vehicleId,
      vehicleLabel: 'Work Truck',
      workProfileId: 'business',
      startOdometer: 1000,
      startedAt: DateTime(2026, 7, 16, 8),
    );
    final tripController = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      odometer: odometer,
    );
    addTearDown(tripController.dispose);

    await tester.pumpWidget(
      AppStateScope(
        controller: appState,
        child: ActiveWorkdayScope(
          controller: activeWorkday,
          child: GlobalOdometerScope(
            controller: odometer,
            child: TripTrackingScope(
              controller: tripController,
              child: const MaterialApp(
                home: ActiveWorkdayScreen(
                  activeVehicle: VehicleProfilePreview(
                    id: 'vehicle_1',
                    nickname: 'Work Truck',
                    year: '2026',
                    make: 'Ford',
                    model: 'Transit',
                    odometer: '0001000',
                    status: 'ACTIVE',
                  ),
                  workProfileName: 'Business',
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('0001000'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);

    expect(
      await tripController.start(
        tripId: 'gps-trip-dashboard-live-odometer',
        vehicleId: odometer.vehicleId,
        profile: TripTrackingProfile.roadVehicle,
        startedAt: DateTime.utc(2026, 7, 16, 12),
      ),
      isTrue,
    );
    await tripController.ingest(
      TripLocationSample(
        latitude: 35,
        longitude: -80,
        recordedAt: DateTime.utc(2026, 7, 16, 12),
        horizontalAccuracyMeters: 5,
      ),
    );
    await tripController.ingest(
      TripLocationSample(
        latitude: 35,
        longitude: -79.965,
        recordedAt: DateTime.utc(2026, 7, 16, 12, 1, 30),
        horizontalAccuracyMeters: 5,
      ),
    );
    await tester.pump();

    expect(find.text('0001000'), findsNothing);
    expect(find.text(odometer.displayValue), findsOneWidget);
    expect(odometer.reading, greaterThan(1000));
    expect(odometer.confirmedReading, 1000);
    expect(find.text((odometer.reading - 1000).toString()), findsOneWidget);
    expect(
      find.textContaining('GPS estimate: ${odometer.displayValue}'),
      findsOneWidget,
    );

    final priorLiveDisplay = odometer.displayValue;
    final liveReading = odometer.reading;
    expect(
      odometer.updateLiveTripProjection(
        tripId: 'gps-trip-dashboard-live-odometer',
        estimatedOdometer: liveReading + 2,
      ),
      isTrue,
    );
    await tester.pump();

    expect(
      find.textContaining('GPS estimate: $priorLiveDisplay'),
      findsNothing,
    );
    expect(
      find.textContaining('GPS estimate: ${odometer.displayValue}'),
      findsOneWidget,
    );
  });

  testWidgets('active day shows profile-aware GPS guidance before tracking', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 1500);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    odometer.dispose();
    odometer = GlobalOdometerController(initialReading: 1000);
    final activeWorkday = ActiveWorkdayController.memory();
    await activeWorkday.startDay(
      vehicleId: odometer.vehicleId,
      vehicleLabel: 'Work Truck',
      workProfileId: 'delivery',
      startOdometer: 1000,
      startedAt: DateTime(2026, 7, 16, 8),
    );
    final tripController = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      odometer: odometer,
      platform: _DashboardTripNativeGateway(
        batterySnapshot: const TripTrackingBatterySnapshot(
          batteryPercent: 90,
          isCharging: false,
          lowPowerModeEnabled: false,
        ),
      ),
    );
    final settingsController = TripTrackingSettingsController.memory(
      const TripTrackingSettings(
        gpsAssistedTrackingEnabled: true,
        defaultProfile: TripTrackingProfile.deliveryVehicle,
        backupNetworkPolicy: TripTrackingBackupNetworkPolicy.wifiOnly,
      ),
    );
    addTearDown(tripController.dispose);
    addTearDown(settingsController.dispose);

    await tester.pumpWidget(
      AppStateScope(
        controller: appState,
        child: ActiveWorkdayScope(
          controller: activeWorkday,
          child: GlobalOdometerScope(
            controller: odometer,
            child: TripTrackingSettingsScope(
              controller: settingsController,
              child: TripTrackingScope(
                controller: tripController,
                child: const MaterialApp(
                  home: ActiveWorkdayScreen(
                    activeVehicle: VehicleProfilePreview(
                      id: 'vehicle_1',
                      nickname: 'Work Truck',
                      year: '2026',
                      make: 'Ford',
                      model: 'Transit',
                      odometer: '0001000',
                      status: 'ACTIVE',
                    ),
                    workProfileName: 'Delivery',
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.ensureVisible(find.text('GPS-ASSISTED TRIP'));
    expect(find.text('GPS assist is ready for delivery work.'), findsOneWidget);
    expect(find.textContaining('walking evidence'), findsOneWidget);
    expect(find.text('Delivery'), findsWidgets);
    expect(find.textContaining('Sync: Wi-Fi only'), findsOneWidget);
    expect(find.text('Battery guard on'), findsOneWidget);
    expect(find.textContaining('Motion assist is recommended'), findsOneWidget);
    expect(find.textContaining('Odometer remains'), findsOneWidget);
  });

  testWidgets('active day asks before starting GPS below 20 percent battery', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 1500);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    odometer.dispose();
    odometer = GlobalOdometerController(initialReading: 1000);
    final activeWorkday = ActiveWorkdayController.memory();
    await activeWorkday.startDay(
      vehicleId: odometer.vehicleId,
      vehicleLabel: 'Work Truck',
      workProfileId: 'business',
      startOdometer: 1000,
      startedAt: DateTime(2026, 7, 16, 8),
    );
    final native = _DashboardTripNativeGateway(
      batterySnapshot: const TripTrackingBatterySnapshot(
        batteryPercent: 10,
        isCharging: false,
        lowPowerModeEnabled: true,
      ),
    );
    final tripController = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      odometer: odometer,
      platform: native,
    );
    final settingsController = TripTrackingSettingsController.memory(
      const TripTrackingSettings(gpsAssistedTrackingEnabled: true),
    );
    addTearDown(tripController.dispose);
    addTearDown(settingsController.dispose);

    await tester.pumpWidget(
      AppStateScope(
        controller: appState,
        child: ActiveWorkdayScope(
          controller: activeWorkday,
          child: GlobalOdometerScope(
            controller: odometer,
            child: TripTrackingSettingsScope(
              controller: settingsController,
              child: TripTrackingScope(
                controller: tripController,
                child: const MaterialApp(
                  home: ActiveWorkdayScreen(
                    activeVehicle: VehicleProfilePreview(
                      id: 'vehicle_1',
                      nickname: 'Work Truck',
                      year: '2026',
                      make: 'Ford',
                      model: 'Transit',
                      odometer: '0001000',
                      status: 'ACTIVE',
                    ),
                    workProfileName: 'Business',
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'START'));
    await tester.tap(find.widgetWithText(FilledButton, 'START'));
    await tester.pumpAndSettle();

    expect(find.text('Battery below 20%'), findsOneWidget);
    expect(
      find.text('You can reverse this later in Dashboard GPS settings.'),
      findsOneWidget,
    );
    expect(native.requestAuthorizationCalls, 0);
    expect(native.startCalls, 0);

    await tester.tap(find.widgetWithText(FilledButton, 'Continue with GPS'));
    await tester.pumpAndSettle();

    expect(native.requestAuthorizationCalls, 1);
    expect(native.startCalls, 1);
    expect(find.text('GPS-assisted trip tracking started.'), findsOneWidget);
    expect(find.text('Foreground GPS'), findsOneWidget);
    expect(find.text('Foreground GPS assist is available.'), findsOneWidget);
  });

  testWidgets('active day can remember low battery GPS cancellation', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 1500);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    odometer.dispose();
    odometer = GlobalOdometerController(initialReading: 1000);
    final activeWorkday = ActiveWorkdayController.memory();
    await activeWorkday.startDay(
      vehicleId: odometer.vehicleId,
      vehicleLabel: 'Work Truck',
      workProfileId: 'business',
      startOdometer: 1000,
      startedAt: DateTime(2026, 7, 16, 8),
    );
    final native = _DashboardTripNativeGateway(
      batterySnapshot: const TripTrackingBatterySnapshot(
        batteryPercent: 10,
        isCharging: false,
        lowPowerModeEnabled: false,
      ),
    );
    final tripController = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      odometer: odometer,
      platform: native,
    );
    final settingsController = TripTrackingSettingsController.memory(
      const TripTrackingSettings(gpsAssistedTrackingEnabled: true),
    );
    addTearDown(tripController.dispose);
    addTearDown(settingsController.dispose);

    await tester.pumpWidget(
      AppStateScope(
        controller: appState,
        child: ActiveWorkdayScope(
          controller: activeWorkday,
          child: GlobalOdometerScope(
            controller: odometer,
            child: TripTrackingSettingsScope(
              controller: settingsController,
              child: TripTrackingScope(
                controller: tripController,
                child: const MaterialApp(
                  home: ActiveWorkdayScreen(
                    activeVehicle: VehicleProfilePreview(
                      id: 'vehicle_1',
                      nickname: 'Work Truck',
                      year: '2026',
                      make: 'Ford',
                      model: 'Transit',
                      odometer: '0001000',
                      status: 'ACTIVE',
                    ),
                    workProfileName: 'Business',
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'START'));
    await tester.tap(find.widgetWithText(FilledButton, 'START'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Do not show again'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Cancel GPS'));
    await tester.pumpAndSettle();

    expect(native.requestAuthorizationCalls, 0);
    expect(native.startCalls, 0);
    expect(tripController.isTracking, isFalse);
    expect(settingsController.settings.lowBatteryGpsOverrideEnabled, isFalse);
    expect(settingsController.settings.lowBatteryGpsWarningDismissed, isTrue);
  });

  testWidgets('active day GPS start requires an active workday', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 1500);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    odometer.dispose();
    odometer = GlobalOdometerController(initialReading: 1000);
    final activeWorkday = ActiveWorkdayController.memory();
    final native = _DashboardTripNativeGateway(
      batterySnapshot: const TripTrackingBatterySnapshot(
        batteryPercent: 90,
        isCharging: false,
        lowPowerModeEnabled: false,
      ),
    );
    final tripController = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      odometer: odometer,
      platform: native,
    );
    final settingsController = TripTrackingSettingsController.memory(
      const TripTrackingSettings(gpsAssistedTrackingEnabled: true),
    );
    addTearDown(tripController.dispose);
    addTearDown(settingsController.dispose);

    await tester.pumpWidget(
      AppStateScope(
        controller: appState,
        child: ActiveWorkdayScope(
          controller: activeWorkday,
          child: GlobalOdometerScope(
            controller: odometer,
            child: TripTrackingSettingsScope(
              controller: settingsController,
              child: TripTrackingScope(
                controller: tripController,
                child: const MaterialApp(
                  home: ActiveWorkdayScreen(
                    activeVehicle: VehicleProfilePreview(
                      id: 'vehicle_1',
                      nickname: 'Work Truck',
                      year: '2026',
                      make: 'Ford',
                      model: 'Transit',
                      odometer: '0001000',
                      status: 'ACTIVE',
                    ),
                    workProfileName: 'Business',
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'START'));
    await tester.tap(find.widgetWithText(FilledButton, 'START'));
    await tester.pumpAndSettle();

    expect(
      find.text('Start Day before starting GPS-assisted tracking.'),
      findsOneWidget,
    );
    expect(tripController.isTracking, isFalse);
    expect(native.requestAuthorizationCalls, 0);
    expect(native.startCalls, 0);
  });

  testWidgets('active day GPS start requires the active workday vehicle', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 1500);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    odometer.dispose();
    odometer = GlobalOdometerController(
      vehicleId: 'vehicle_1',
      initialReading: 1000,
    );
    final activeWorkday = ActiveWorkdayController.memory();
    await activeWorkday.startDay(
      vehicleId: 'vehicle_2',
      vehicleLabel: 'Other Truck',
      workProfileId: 'business',
      startOdometer: 1000,
      startedAt: DateTime(2026, 7, 16, 8),
    );
    final native = _DashboardTripNativeGateway(
      batterySnapshot: const TripTrackingBatterySnapshot(
        batteryPercent: 90,
        isCharging: false,
        lowPowerModeEnabled: false,
      ),
    );
    final tripController = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      odometer: odometer,
      platform: native,
    );
    final settingsController = TripTrackingSettingsController.memory(
      const TripTrackingSettings(gpsAssistedTrackingEnabled: true),
    );
    addTearDown(tripController.dispose);
    addTearDown(settingsController.dispose);

    await tester.pumpWidget(
      AppStateScope(
        controller: appState,
        child: ActiveWorkdayScope(
          controller: activeWorkday,
          child: GlobalOdometerScope(
            controller: odometer,
            child: TripTrackingSettingsScope(
              controller: settingsController,
              child: TripTrackingScope(
                controller: tripController,
                child: const MaterialApp(
                  home: ActiveWorkdayScreen(
                    activeVehicle: VehicleProfilePreview(
                      id: 'vehicle_1',
                      nickname: 'Work Truck',
                      year: '2026',
                      make: 'Ford',
                      model: 'Transit',
                      odometer: '0001000',
                      status: 'ACTIVE',
                    ),
                    workProfileName: 'Business',
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'START'));
    await tester.tap(find.widgetWithText(FilledButton, 'START'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Switch to the active workday vehicle before starting GPS-assisted tracking.',
      ),
      findsOneWidget,
    );
    expect(tripController.isTracking, isFalse);
    expect(native.requestAuthorizationCalls, 0);
    expect(native.startCalls, 0);
  });

  testWidgets('active day asks before starting GPS in low power mode', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 1500);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    odometer.dispose();
    odometer = GlobalOdometerController(initialReading: 1000);
    final activeWorkday = ActiveWorkdayController.memory();
    await activeWorkday.startDay(
      vehicleId: odometer.vehicleId,
      vehicleLabel: 'Work Truck',
      workProfileId: 'business',
      startOdometer: 1000,
      startedAt: DateTime(2026, 7, 16, 8),
    );
    final native = _DashboardTripNativeGateway(
      batterySnapshot: const TripTrackingBatterySnapshot(
        batteryPercent: 80,
        isCharging: false,
        lowPowerModeEnabled: true,
      ),
    );
    final tripController = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      odometer: odometer,
      platform: native,
    );
    final settingsController = TripTrackingSettingsController.memory(
      const TripTrackingSettings(gpsAssistedTrackingEnabled: true),
    );
    addTearDown(tripController.dispose);
    addTearDown(settingsController.dispose);

    await tester.pumpWidget(
      AppStateScope(
        controller: appState,
        child: ActiveWorkdayScope(
          controller: activeWorkday,
          child: GlobalOdometerScope(
            controller: odometer,
            child: TripTrackingSettingsScope(
              controller: settingsController,
              child: TripTrackingScope(
                controller: tripController,
                child: const MaterialApp(
                  home: ActiveWorkdayScreen(
                    activeVehicle: VehicleProfilePreview(
                      id: 'vehicle_1',
                      nickname: 'Work Truck',
                      year: '2026',
                      make: 'Ford',
                      model: 'Transit',
                      odometer: '0001000',
                      status: 'ACTIVE',
                    ),
                    workProfileName: 'Business',
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'START'));
    await tester.tap(find.widgetWithText(FilledButton, 'START'));
    await tester.pumpAndSettle();

    expect(find.text('Battery saver is active'), findsOneWidget);
    expect(native.requestAuthorizationCalls, 0);
    expect(native.startCalls, 0);

    await tester.tap(find.widgetWithText(FilledButton, 'Continue with GPS'));
    await tester.pumpAndSettle();

    expect(native.requestAuthorizationCalls, 1);
    expect(native.startCalls, 1);
    expect(find.text('GPS-assisted trip tracking started.'), findsOneWidget);
  });

  testWidgets('active day prevents duplicate GPS starts while starting', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 1500);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    odometer.dispose();
    odometer = GlobalOdometerController(initialReading: 1000);
    final activeWorkday = ActiveWorkdayController.memory();
    await activeWorkday.startDay(
      vehicleId: odometer.vehicleId,
      vehicleLabel: 'Work Truck',
      workProfileId: 'business',
      startOdometer: 1000,
      startedAt: DateTime(2026, 7, 16, 8),
    );
    final startCompleter = Completer<void>();
    final native = _DashboardTripNativeGateway(
      batterySnapshot: const TripTrackingBatterySnapshot(
        batteryPercent: 90,
        isCharging: false,
        lowPowerModeEnabled: false,
      ),
      startDelay: startCompleter.future,
    );
    final tripController = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      odometer: odometer,
      platform: native,
    );
    final settingsController = TripTrackingSettingsController.memory(
      const TripTrackingSettings(gpsAssistedTrackingEnabled: true),
    );
    addTearDown(tripController.dispose);
    addTearDown(settingsController.dispose);

    await tester.pumpWidget(
      AppStateScope(
        controller: appState,
        child: ActiveWorkdayScope(
          controller: activeWorkday,
          child: GlobalOdometerScope(
            controller: odometer,
            child: TripTrackingSettingsScope(
              controller: settingsController,
              child: TripTrackingScope(
                controller: tripController,
                child: const MaterialApp(
                  home: ActiveWorkdayScreen(
                    activeVehicle: VehicleProfilePreview(
                      id: 'vehicle_1',
                      nickname: 'Work Truck',
                      year: '2026',
                      make: 'Ford',
                      model: 'Transit',
                      odometer: '0001000',
                      status: 'ACTIVE',
                    ),
                    workProfileName: 'Business',
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'START'));
    await tester.tap(find.widgetWithText(FilledButton, 'START'));
    await tester.pump();

    expect(find.widgetWithText(FilledButton, 'STARTING'), findsOneWidget);
    expect(native.startCalls, 0);

    await tester.tap(find.widgetWithText(FilledButton, 'STARTING'));
    await tester.pump();
    startCompleter.complete();
    await tester.pumpAndSettle();

    expect(native.requestAuthorizationCalls, 1);
    expect(native.startCalls, 1);
    expect(find.text('GPS-assisted trip tracking started.'), findsOneWidget);
  });

  testWidgets('active day prevents duplicate GPS stops while finishing', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 1500);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    odometer.dispose();
    odometer = GlobalOdometerController(initialReading: 1000);
    final activeWorkday = ActiveWorkdayController.memory();
    await activeWorkday.startDay(
      vehicleId: odometer.vehicleId,
      vehicleLabel: 'Work Truck',
      workProfileId: 'business',
      startOdometer: 1000,
      startedAt: DateTime(2026, 7, 16, 8),
    );
    final stopCompleter = Completer<void>();
    final native = _DashboardTripNativeGateway(
      batterySnapshot: const TripTrackingBatterySnapshot(
        batteryPercent: 90,
        isCharging: false,
        lowPowerModeEnabled: false,
      ),
      stopDelay: stopCompleter.future,
    );
    final tripController = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      odometer: odometer,
      platform: native,
    );
    final settingsController = TripTrackingSettingsController.memory(
      const TripTrackingSettings(gpsAssistedTrackingEnabled: true),
    );
    addTearDown(tripController.dispose);
    addTearDown(settingsController.dispose);

    await tester.pumpWidget(
      AppStateScope(
        controller: appState,
        child: ActiveWorkdayScope(
          controller: activeWorkday,
          child: GlobalOdometerScope(
            controller: odometer,
            child: TripTrackingSettingsScope(
              controller: settingsController,
              child: TripTrackingScope(
                controller: tripController,
                child: const MaterialApp(
                  home: ActiveWorkdayScreen(
                    activeVehicle: VehicleProfilePreview(
                      id: 'vehicle_1',
                      nickname: 'Work Truck',
                      year: '2026',
                      make: 'Ford',
                      model: 'Transit',
                      odometer: '0001000',
                      status: 'ACTIVE',
                    ),
                    workProfileName: 'Business',
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'START'));
    await tester.tap(find.widgetWithText(FilledButton, 'START'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'STOP'), findsOneWidget);
    await tripController.ingest(
      TripLocationSample(
        latitude: 35,
        longitude: -80,
        recordedAt: DateTime.utc(2026, 7, 16, 12),
        horizontalAccuracyMeters: 5,
      ),
    );
    await tripController.ingest(
      TripLocationSample(
        latitude: 35,
        longitude: -79.985,
        recordedAt: DateTime.utc(2026, 7, 16, 12, 1),
        horizontalAccuracyMeters: 5,
      ),
    );
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, 'STOP'));
    await tester.pump();
    expect(find.widgetWithText(FilledButton, 'STOPPING'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'STOPPING'));
    await tester.pump();
    stopCompleter.complete();
    await tester.pumpAndSettle();
    await tester.pump();

    expect(native.stopCalls, 1);
  });

  testWidgets(
    'active workday stop dialog redraws live GPS odometer projection',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1500);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      odometer.dispose();
      odometer = GlobalOdometerController(initialReading: 1000);
      final activeWorkday = ActiveWorkdayController.memory();
      await activeWorkday.startDay(
        vehicleId: odometer.vehicleId,
        vehicleLabel: 'Work Truck',
        workProfileId: 'business',
        startOdometer: 1000,
        startedAt: DateTime(2026, 7, 16, 8),
      );

      await tester.pumpWidget(
        AppStateScope(
          controller: appState,
          child: ActiveWorkdayScope(
            controller: activeWorkday,
            child: GlobalOdometerScope(
              controller: odometer,
              child: const MaterialApp(
                home: ActiveWorkdayScreen(
                  activeVehicle: VehicleProfilePreview(
                    id: 'vehicle_1',
                    nickname: 'Work Truck',
                    year: '2026',
                    make: 'Ford',
                    model: 'Transit',
                    odometer: '0001000',
                    status: 'ACTIVE',
                  ),
                  workProfileName: 'Business',
                ),
              ),
            ),
          ),
        ),
      );

      await tester.ensureVisible(find.text('Add Stop'));
      await tester.pump();
      await tester.tap(
        find
            .ancestor(of: find.text('Add Stop'), matching: find.byType(InkWell))
            .first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Odometer: 0001000'), findsOneWidget);
      expect(
        odometer.beginLiveTripProjection(
          tripId: 'gps-trip-stop-dialog',
          startingOdometer: 1000,
        ),
        isTrue,
      );
      expect(
        odometer.updateLiveTripProjection(
          tripId: 'gps-trip-stop-dialog',
          estimatedOdometer: 1004,
        ),
        isTrue,
      );
      await tester.pump();

      expect(find.text('Live GPS odometer: 0001004'), findsOneWidget);
      expect(find.text('+4 mi live • confirmed 0001000'), findsOneWidget);
      expect(find.text('Odometer: 0001000'), findsNothing);
    },
  );

  testWidgets(
    'active workday trip review confirms the exact sheet odometer value',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1500);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      odometer.dispose();
      odometer = GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      );
      final activeWorkday = ActiveWorkdayController.memory();
      await activeWorkday.startDay(
        vehicleId: odometer.vehicleId,
        vehicleLabel: 'Work Truck',
        workProfileId: 'business',
        startOdometer: 1000,
        startedAt: DateTime(2026, 7, 16, 8),
      );
      final tripStore = TripTrackingSessionStore.memory();
      final cloudMirror = _RecordingTripCloudMirror();
      final tripController = TripTrackingController(
        sessionStore: tripStore,
        odometer: odometer,
        cloudMirror: cloudMirror,
      );
      await tripStore.saveReview(
        TripTrackingReviewRecord(
          id: 'dashboard_review_exact_saved_reading',
          vehicleId: 'vehicle_1',
          startingOdometer: 1000,
          estimatedEndingOdometer: 1001,
          profile: TripTrackingProfile.roadVehicle,
          startedAt: DateTime.utc(2026, 7, 16, 12),
          finishedAt: DateTime.utc(2026, 7, 16, 12, 10),
          engineSnapshot: const TripTrackingEngineSnapshot(
            totalAcceptedMeters: 1609.344,
            walkingReviewSuggested: false,
          ),
        ),
      );

      await tester.pumpWidget(
        AppStateScope(
          controller: appState,
          child: ActiveWorkdayScope(
            controller: activeWorkday,
            child: GlobalOdometerScope(
              controller: odometer,
              child: TripTrackingScope(
                controller: tripController,
                child: const MaterialApp(
                  home: ActiveWorkdayScreen(
                    activeVehicle: VehicleProfilePreview(
                      id: 'vehicle_1',
                      nickname: 'Work Truck',
                      year: '2026',
                      make: 'Ford',
                      model: 'Transit',
                      odometer: '0001000',
                      status: 'ACTIVE',
                    ),
                    workProfileName: 'Business',
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.ensureVisible(find.text('REVIEW LATEST GPS TRIP'));
      await tester.pump();
      await tester.tap(
        find
            .ancestor(
              of: find.text('REVIEW LATEST GPS TRIP'),
              matching: find.byType(InkWell),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '1001');
      await tester.tap(find.widgetWithText(FilledButton, 'Confirm Odometer'));
      await tester.pump();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Business'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Save Miles'));
      await tester.pumpAndSettle();

      final stored = tripStore.reviewForTrip(
        'dashboard_review_exact_saved_reading',
      );
      expect(stored?.confirmedEndingOdometer, 1001);
      expect(stored?.isOdometerConfirmed, isTrue);
      expect(odometer.confirmedReading, 1001);
      expect(cloudMirror.documents, hasLength(1));
      expect(cloudMirror.documents.single['locationDataIncluded'], isFalse);
      expect(cloudMirror.documents.single['visibilityScope'], 'mileage_only');
      expect(
        cloudMirror.documents.single.keys,
        isNot(contains(anyOf('latitude', 'longitude', 'samples', 'timeline'))),
      );
      expect(
        find.text('GPS trip reviewed and odometer confirmed.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'active workday trip review reports confirmed local backup retry',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1500);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      odometer.dispose();
      odometer = GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      );
      final activeWorkday = ActiveWorkdayController.memory();
      await activeWorkday.startDay(
        vehicleId: odometer.vehicleId,
        vehicleLabel: 'Work Truck',
        workProfileId: 'business',
        startOdometer: 1000,
        startedAt: DateTime(2026, 7, 16, 8),
      );
      final tripStore = TripTrackingSessionStore.memory();
      final cloudMirror = _RecordingTripCloudMirror(throwOnQueue: true);
      final tripController = TripTrackingController(
        sessionStore: tripStore,
        odometer: odometer,
        cloudMirror: cloudMirror,
      );
      await tripStore.saveReview(
        TripTrackingReviewRecord(
          id: 'dashboard_review_cloud_retry',
          vehicleId: 'vehicle_1',
          startingOdometer: 1000,
          estimatedEndingOdometer: 1001,
          profile: TripTrackingProfile.roadVehicle,
          startedAt: DateTime.utc(2026, 7, 16, 12),
          finishedAt: DateTime.utc(2026, 7, 16, 12, 10),
          engineSnapshot: const TripTrackingEngineSnapshot(
            totalAcceptedMeters: 1609.344,
            walkingReviewSuggested: false,
          ),
        ),
      );

      await tester.pumpWidget(
        AppStateScope(
          controller: appState,
          child: ActiveWorkdayScope(
            controller: activeWorkday,
            child: GlobalOdometerScope(
              controller: odometer,
              child: TripTrackingScope(
                controller: tripController,
                child: const MaterialApp(
                  home: ActiveWorkdayScreen(
                    activeVehicle: VehicleProfilePreview(
                      id: 'vehicle_1',
                      nickname: 'Work Truck',
                      year: '2026',
                      make: 'Ford',
                      model: 'Transit',
                      odometer: '0001000',
                      status: 'ACTIVE',
                    ),
                    workProfileName: 'Business',
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.ensureVisible(find.text('REVIEW LATEST GPS TRIP'));
      await tester.pump();
      await tester.tap(
        find
            .ancestor(
              of: find.text('REVIEW LATEST GPS TRIP'),
              matching: find.byType(InkWell),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '1001');
      await tester.tap(find.widgetWithText(FilledButton, 'Confirm Odometer'));
      await tester.pump();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Business'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Save Miles'));
      await tester.pumpAndSettle();

      final stored = tripStore.reviewForTrip('dashboard_review_cloud_retry');
      expect(stored?.isOdometerConfirmed, isTrue);
      expect(odometer.confirmedReading, 1001);
      expect(cloudMirror.documents, isEmpty);
      expect(tripController.cloudMirrorError, contains('pending'));
      expect(
        find.text(
          'GPS trip reviewed and saved locally; cloud backup will retry.',
        ),
        findsOneWidget,
      );
    },
  );
}

class _RecordingTripCloudMirror implements TripTrackingCloudMirror {
  _RecordingTripCloudMirror({this.throwOnQueue = false});

  final bool throwOnQueue;
  final documents = <Map<String, Object?>>[];

  @override
  Future<void> queueReview(TripTrackingReviewRecord review) async {
    if (throwOnQueue) {
      throw StateError('queue unavailable');
    }
    documents.add(
      MaintainiacFirestoreDocumentBuilder.personalTripTrackingReviewDocument(
        uid: 'firebaseUid-1',
        review: review,
      ).data,
    );
  }

  @override
  Future<void> flushPending() async {}

  @override
  Future<void> withdrawBackupConsent() async {}

  @override
  Future<void> withdrawOrganizationSharingConsent() async {}

  @override
  void dispose() {}
}

class _DashboardTripNativeGateway implements TripTrackingNativeGateway {
  _DashboardTripNativeGateway({
    required this.batterySnapshot,
    this.startDelay,
    this.stopDelay,
  });

  final TripTrackingBatterySnapshot batterySnapshot;
  final Future<void>? startDelay;
  final Future<void>? stopDelay;
  final _events = StreamController<TripTrackingPlatformEvent>.broadcast();
  var requestAuthorizationCalls = 0;
  var startCalls = 0;
  var stopCalls = 0;
  var _tracking = false;

  @override
  Stream<TripTrackingPlatformEvent> get events => _events.stream;

  @override
  Future<TripTrackingPlatformCapabilities> readCapabilities() async =>
      const TripTrackingPlatformCapabilities(
        locationAvailable: true,
        backgroundTrackingAvailable: true,
        activityRecognitionAvailable: false,
        batteryStateAvailable: true,
        lowPowerModeAvailable: true,
      );

  @override
  Future<TripTrackingBatterySnapshot> readBatterySnapshot() async =>
      batterySnapshot;

  @override
  Future<TripTrackingAuthorization> requestAuthorization({
    required bool allowBackground,
    required bool activityRecognitionEnabled,
  }) async {
    requestAuthorizationCalls += 1;
    return const TripTrackingAuthorization(
      state: TripTrackingAuthorizationState.always,
      preciseLocation: true,
    );
  }

  @override
  Future<bool> start(TripTrackingNativeRequest request) async {
    await startDelay;
    startCalls += 1;
    _tracking = true;
    return true;
  }

  @override
  Future<bool> update(TripTrackingNativeRequest request) async => _tracking;

  @override
  Future<void> stop() async {
    await stopDelay;
    stopCalls += 1;
    _tracking = false;
  }

  @override
  Future<bool> get isTracking async => _tracking;
}

Future<void> _pumpDashboard(
  WidgetTester tester,
  AppStateController appState,
  GlobalOdometerController odometer,
  ExpenseWorkProfileController workProfiles, {
  ActiveWorkdayController? activeWorkday,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(900, 1500);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final dashboard = AppStateScope(
    controller: appState,
    child: ExpenseWorkProfileScope(
      controller: workProfiles,
      child: GlobalOdometerScope(
        controller: odometer,
        child: const MaterialApp(home: DashboardScreen()),
      ),
    ),
  );

  await tester.pumpWidget(
    activeWorkday == null
        ? dashboard
        : ActiveWorkdayScope(controller: activeWorkday, child: dashboard),
  );
}
