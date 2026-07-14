import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/settings/trip_tracking_settings_screen.dart';
import 'package:maintaniac/shared/state/app_state.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';

void main() {
  testWidgets('GPS settings are visible and remain opt-in', (tester) async {
    final settings = TripTrackingSettingsController.memory();
    await tester.pumpWidget(
      MaterialApp(
        home: AppStateScope(
          controller: AppStateController(),
          child: GlobalOdometerScope(
            controller: GlobalOdometerController(),
            child: TripTrackingSettingsScope(
              controller: settings,
              child: const TripTrackingSettingsScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('GPS-Assisted Trip Tracking'), findsOneWidget);
    expect(find.text('Enable GPS-assisted tracking'), findsOneWidget);
    expect(settings.settings.gpsAssistedTrackingEnabled, isFalse);

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    expect(settings.settings.gpsAssistedTrackingEnabled, isTrue);
  });
}
