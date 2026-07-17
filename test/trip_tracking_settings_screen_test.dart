import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/settings/trip_tracking_settings_screen.dart';
import 'package:maintaniac/shared/state/app_state.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/profiles/user_profile_store.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';

void main() {
  testWidgets('GPS settings are visible and remain opt-in', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 1500);
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
    expect(find.text('Enable GPS-assisted tracking'), findsOneWidget);
    expect(
      find.text('Share reviewed mileage summaries with organization'),
      findsOneWidget,
    );
    expect(
      find.textContaining('GPS stops when the app is backgrounded'),
      findsOneWidget,
    );
    expect(find.text('Use motion activity for walking review'), findsOneWidget);
    expect(find.text('Protect GPS below 20% battery'), findsOneWidget);
    expect(find.text('Allow GPS below 20% battery'), findsOneWidget);
    expect(find.text('Remember low-battery GPS choice'), findsOneWidget);
    expect(settings.settings.activityRecognitionEnabled, isFalse);
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
    expect(settings.settings.activityRecognitionEnabled, isTrue);
    expect(settings.settings.gpsAssistedTrackingEnabled, isFalse);
    expect(find.text('Back up reviewed mileage'), findsOneWidget);
    expect(find.text('Back up reviewed mileage to Firebase'), findsNothing);
    expect(profiles.activeProfile.cloudBackupEnabled, isFalse);
  });

  testWidgets('low battery GPS settings are reversible', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 1500);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final settings = TripTrackingSettingsController.memory(
      const TripTrackingSettings(
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

    await tester.ensureVisible(find.text('Allow GPS below 20% battery'));
    await tester.pump();
    final allowRow = find
        .ancestor(
          of: find.text('Allow GPS below 20% battery'),
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
