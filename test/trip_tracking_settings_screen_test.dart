import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/settings/trip_tracking_settings_screen.dart';
import 'package:maintaniac/shared/state/app_state.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/profiles/user_profile_store.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';

void main() {
  testWidgets('calibration opt-in explains that evidence still needs review', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 2400);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final settings = TripTrackingSettingsController.memory();
    await settings.update(
      const TripTrackingSettings(
        gpsAssistedTrackingEnabled: true,
        odometerAnomalyAlertsEnabled: true,
        gpsOdometerCalibrationAssistEnabled: true,
      ),
    );
    final odometer = GlobalOdometerController();
    final tripTracking = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      odometer: odometer,
    );
    tripTracking.refreshGpsAssistanceCalibration(enabled: true);
    addTearDown(settings.dispose);
    addTearDown(odometer.dispose);
    addTearDown(tripTracking.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: AppStateScope(
          controller: AppStateController(),
          child: GlobalOdometerScope(
            controller: odometer,
            child: TripTrackingSettingsScope(
              controller: settings,
              child: TripTrackingScope(
                controller: tripTracking,
                child: const TripTrackingSettingsScreen(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Calibration review'));
    await tester.pump();

    expect(find.text('Calibration review'), findsOneWidget);
    expect(
      find.textContaining('More consistent, reviewed driving days'),
      findsOneWidget,
    );
    expect(find.text('Accept current calibration review'), findsNothing);
  });

  testWidgets('GPS settings are visible and remain opt-in', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 2400);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final settings = TripTrackingSettingsController.memory();
    final profiles = UserProfileController.memory();
    await tester.pumpWidget(
      MaterialApp(
        home: AppStateScope(
          controller: AppStateController(),
          child: GlobalOdometerScope(
            controller: GlobalOdometerController(),
            child: TripTrackingSettingsScope(
              controller: settings,
              child: UserProfileScope(
                controller: profiles,
                child: const TripTrackingSettingsScreen(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('GPS-Assisted Trip Tracking'), findsOneWidget);
    expect(find.text('CORE TRACKING'), findsOneWidget);
    expect(find.text('MAPS AND ROUTE HISTORY'), findsOneWidget);
    expect(find.text('BATTERY PROTECTION'), findsOneWidget);
    expect(find.text('TRACKING BEHAVIOR AND STOPS'), findsOneWidget);
    expect(find.text('ODOMETER REVIEW AND CALIBRATION'), findsOneWidget);
    expect(find.text('Enable GPS-assisted tracking'), findsOneWidget);
    expect(
      find.text('Share reviewed mileage summaries with organization'),
      findsNothing,
    );
    expect(
      find.textContaining('Enable GPS-assisted tracking before allowing'),
      findsOneWidget,
    );
    expect(find.text('Use motion activity for walking review'), findsOneWidget);
    expect(find.text('Show optional maps'), findsOneWidget);
    expect(find.text('Save optional map route history'), findsOneWidget);
    expect(find.text('Profile-specific stop detection'), findsOneWidget);
    expect(find.text('Odometer anomaly alerts'), findsOneWidget);
    expect(find.text('Odometer calibration assist'), findsOneWidget);
    expect(
      find.textContaining('review and accept current local evidence'),
      findsNothing,
    );
    expect(find.text('Protect GPS at or below 15% battery'), findsOneWidget);
    expect(find.text('Allow GPS at or below 15% battery'), findsOneWidget);
    expect(find.text('Remember low-battery GPS choice'), findsOneWidget);
    expect(
      find.textContaining('unless the phone is charging'),
      findsNWidgets(2),
    );
    expect(find.text('Mileage backup network'), findsNothing);
    expect(
      find.text('Recognize a linked vehicle by Bluetooth'),
      findsOneWidget,
    );
    expect(
      find.text('Linked vehicle suggestions need your approval'),
      findsOneWidget,
    );
    expect(find.text('Automatically switch the active vehicle'), findsNothing);
    expect(find.text('Paid feature'), findsOneWidget);
    expect(settings.settings.activityRecognitionEnabled, isFalse);
    expect(settings.settings.odometerAnomalyAlertsEnabled, isFalse);
    expect(settings.settings.gpsOdometerCalibrationAssistEnabled, isFalse);
    expect(settings.settings.gpsAssistedTrackingEnabled, isFalse);
    expect(settings.settings.mapPreviewEnabled, isFalse);
    expect(settings.settings.mapRouteHistorySavingEnabled, isFalse);
    await tester.ensureVisible(find.text('Show optional maps'));
    await tester.pump();
    final disabledMapRow = find
        .ancestor(
          of: find.text('Show optional maps'),
          matching: find.byType(Row),
        )
        .first;
    await tester.tap(
      find.descendant(of: disabledMapRow, matching: find.byType(Switch)),
    );
    await tester.pumpAndSettle();
    expect(settings.settings.mapPreviewEnabled, isFalse);
    await tester.ensureVisible(find.text('Odometer anomaly alerts'));
    await tester.pump();
    final disabledAnomalyRow = find
        .ancestor(
          of: find.text('Odometer anomaly alerts'),
          matching: find.byType(Row),
        )
        .first;
    await tester.tap(
      find.descendant(of: disabledAnomalyRow, matching: find.byType(Switch)),
    );
    await tester.pumpAndSettle();
    expect(settings.settings.odometerAnomalyAlertsEnabled, isFalse);

    await tester.ensureVisible(
      find.text('Use motion activity for walking review'),
    );
    await tester.pump();
    final motionRow = find
        .ancestor(
          of: find.text('Use motion activity for walking review'),
          matching: find.byType(Row),
        )
        .first;
    await tester.tap(
      find.descendant(of: motionRow, matching: find.byType(Switch)),
    );
    await tester.pumpAndSettle();
    expect(settings.settings.activityRecognitionEnabled, isFalse);
    expect(settings.settings.gpsAssistedTrackingEnabled, isFalse);

    await tester.ensureVisible(find.text('Enable GPS-assisted tracking'));
    await tester.pump();
    final gpsRow = find
        .ancestor(
          of: find.text('Enable GPS-assisted tracking'),
          matching: find.byType(Row),
        )
        .first;
    await tester.tap(
      find.descendant(of: gpsRow, matching: find.byType(Switch)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Check your tire setup'), findsOneWidget);
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(settings.settings.gpsAssistedTrackingEnabled, isTrue);
    expect(
      find.bySemanticsLabel('Enable GPS-assisted tracking'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Accuracy and battery use'));
    await tester.pump();
    expect(find.bySemanticsLabel('Accuracy and battery use'), findsOneWidget);
    await tester.tap(find.text('Enhanced (8 sec)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('High accuracy (2 sec)').last);
    await tester.pumpAndSettle();
    expect(
      settings.settings.samplingPreset,
      TripTrackingSamplingPreset.highAccuracy,
    );
    await tester.ensureVisible(
      find.text('Use motion activity for walking review'),
    );
    await tester.pump();
    final enabledMotionRow = find
        .ancestor(
          of: find.text('Use motion activity for walking review'),
          matching: find.byType(Row),
        )
        .first;
    await tester.tap(
      find.descendant(of: enabledMotionRow, matching: find.byType(Switch)),
    );
    await tester.pumpAndSettle();
    expect(settings.settings.activityRecognitionEnabled, isTrue);
    expect(settings.settings.gpsAssistedTrackingEnabled, isTrue);
    await tester.ensureVisible(find.text('Show optional maps'));
    await tester.pump();
    final enabledMapRow = find
        .ancestor(
          of: find.text('Show optional maps'),
          matching: find.byType(Row),
        )
        .first;
    await tester.tap(
      find.descendant(of: enabledMapRow, matching: find.byType(Switch)),
    );
    await tester.pumpAndSettle();
    expect(settings.settings.mapPreviewEnabled, isTrue);
    expect(settings.settings.mapRouteHistorySavingEnabled, isFalse);
    await tester.ensureVisible(find.text('Save optional map route history'));
    await tester.pump();
    final routeHistoryRow = find
        .ancestor(
          of: find.text('Save optional map route history'),
          matching: find.byType(Row),
        )
        .first;
    await tester.tap(
      find.descendant(of: routeHistoryRow, matching: find.byType(Switch)),
    );
    await tester.pumpAndSettle();
    expect(settings.settings.mapRouteHistorySavingEnabled, isTrue);
    expect(settings.settings.mapRouteHistoryDailyBudgetMb, 1);
    expect(settings.settings.mapRouteHistorySampleIntervalSeconds, 30);
    expect(find.text('Map route storage limits'), findsOneWidget);
    await tester.ensureVisible(find.text('Odometer anomaly alerts'));
    await tester.pump();
    final enabledAnomalyRow = find
        .ancestor(
          of: find.text('Odometer anomaly alerts'),
          matching: find.byType(Row),
        )
        .first;
    await tester.tap(
      find.descendant(of: enabledAnomalyRow, matching: find.byType(Switch)),
    );
    await tester.pumpAndSettle();
    expect(settings.settings.odometerAnomalyAlertsEnabled, isTrue);
    await tester.ensureVisible(find.text('Odometer calibration assist'));
    await tester.pump();
    final calibrationRow = find
        .ancestor(
          of: find.text('Odometer calibration assist'),
          matching: find.byType(Row),
        )
        .first;
    await tester.tap(
      find.descendant(of: calibrationRow, matching: find.byType(Switch)),
    );
    await tester.pumpAndSettle();
    expect(settings.settings.gpsOdometerCalibrationAssistEnabled, isTrue);
    expect(
      find.textContaining('review and accept current local evidence'),
      findsOneWidget,
    );
    expect(find.text('Back up reviewed mileage'), findsNothing);
    expect(find.text('Back up reviewed mileage to Firebase'), findsNothing);
    expect(find.text('Firebase backup account'), findsNothing);
    expect(profiles.activeProfile.cloudBackupEnabled, isFalse);
  });

  testWidgets('optional route storage failure is visible but non-blocking', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 2400);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final settings = TripTrackingSettingsController.memory(
      const TripTrackingSettings(
        tripTrackingSetupCompleted: true,
        gpsAssistedTrackingEnabled: true,
        mapPreviewEnabled: true,
        mapRouteHistorySavingEnabled: true,
        mapRouteHistoryDailyBudgetMb: 1,
      ),
    );
    final odometer = GlobalOdometerController();
    final tripTracking = _RouteStorageStatusController(
      odometer: odometer,
      status: 'local_route_storage_unavailable',
    );
    addTearDown(settings.dispose);
    addTearDown(odometer.dispose);
    addTearDown(tripTracking.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: AppStateScope(
          controller: AppStateController(),
          child: GlobalOdometerScope(
            controller: odometer,
            child: TripTrackingSettingsScope(
              controller: settings,
              child: TripTrackingScope(
                controller: tripTracking,
                child: const TripTrackingSettingsScreen(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('routeStorageNotice')));
    await tester.pump();

    expect(
      find.textContaining('Optional route history is not being saved'),
      findsOneWidget,
    );
    expect(
      find.textContaining('confirmed odometer mileage continue normally'),
      findsOneWidget,
    );
    expect(settings.settings.gpsAssistedTrackingEnabled, isTrue);
  });

  testWidgets('backup network policy stays outside GPS settings', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 2400);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final settings = TripTrackingSettingsController.memory();
    final profiles = UserProfileController.memory();
    await tester.pumpWidget(
      MaterialApp(
        home: AppStateScope(
          controller: AppStateController(),
          child: GlobalOdometerScope(
            controller: GlobalOdometerController(),
            child: TripTrackingSettingsScope(
              controller: settings,
              child: UserProfileScope(
                controller: profiles,
                child: const TripTrackingSettingsScreen(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mileage backup network'), findsNothing);
    expect(
      settings.settings.backupNetworkPolicy,
      TripTrackingBackupNetworkPolicy.wifiAndMobileData,
    );
  });

  testWidgets('driver profile guidance updates with the selected profile', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 2400);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final settings = TripTrackingSettingsController.memory(
      const TripTrackingSettings(gpsAssistedTrackingEnabled: true),
    );
    final profiles = UserProfileController.memory();
    await tester.pumpWidget(
      MaterialApp(
        home: AppStateScope(
          controller: AppStateController(),
          child: GlobalOdometerScope(
            controller: GlobalOdometerController(),
            child: TripTrackingSettingsScope(
              controller: settings,
              child: UserProfileScope(
                controller: profiles,
                child: const TripTrackingSettingsScreen(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Default tracking profile'));
    await tester.tap(find.byType(DropdownButton<TripTrackingProfile>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rideshare / passenger driving').last);
    await tester.pumpAndSettle();

    expect(
      settings.settings.defaultProfile,
      TripTrackingProfile.rideshareVehicle,
    );
    expect(find.textContaining('stay in the vehicle'), findsOneWidget);
  });

  testWidgets('low battery GPS settings are reversible', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 1500);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final settings = TripTrackingSettingsController.memory(
      const TripTrackingSettings(
        gpsAssistedTrackingEnabled: true,
        lowBatteryGpsOverrideEnabled: true,
        lowBatteryGpsWarningDismissed: true,
      ),
    );
    final profiles = UserProfileController.memory();
    await tester.pumpWidget(
      MaterialApp(
        home: AppStateScope(
          controller: AppStateController(),
          child: GlobalOdometerScope(
            controller: GlobalOdometerController(),
            child: TripTrackingSettingsScope(
              controller: settings,
              child: UserProfileScope(
                controller: profiles,
                child: const TripTrackingSettingsScreen(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Allow GPS at or below 15% battery'));
    await tester.pump();
    final allowRow = find
        .ancestor(
          of: find.text('Allow GPS at or below 15% battery'),
          matching: find.byType(Row),
        )
        .first;
    await tester.tap(
      find.descendant(of: allowRow, matching: find.byType(Switch)),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Remember low-battery GPS choice'));
    await tester.pump();
    final rememberRow = find
        .ancestor(
          of: find.text('Remember low-battery GPS choice'),
          matching: find.byType(Row),
        )
        .first;
    await tester.tap(
      find.descendant(of: rememberRow, matching: find.byType(Switch)),
    );
    await tester.pumpAndSettle();

    expect(settings.settings.lowBatteryGpsOverrideEnabled, isFalse);
    expect(settings.settings.lowBatteryGpsWarningDismissed, isFalse);
  });
}

class _RouteStorageStatusController extends TripTrackingController {
  // A dedicated fixture supplies the required in-memory store itself.
  // ignore: use_super_parameters
  _RouteStorageStatusController({
    required GlobalOdometerController odometer,
    required this.status,
  }) : super(
         sessionStore: TripTrackingSessionStore.memory(),
         odometer: odometer,
       );

  final String status;

  @override
  String? get routeStorageStatus => status;
}
