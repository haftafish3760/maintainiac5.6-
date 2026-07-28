// Accessibility and navigation regression checks for GPS settings.
//
// Owns the explicit-back-control, readable sampling-guidance, and iOS
// permission-path contracts. It does not request device permissions or start
// a trip. The settings UI and native bridge are the systems under test.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/settings/trip_tracking_settings_screen.dart';
import 'package:maintaniac/shared/state/app_state.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/widgets/app_back_button.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';

void main() {
  testWidgets('GPS settings supplies an explicit accessible back control', (
    tester,
  ) async {
    final settings = TripTrackingSettingsController.memory();
    final odometer = GlobalOdometerController();
    addTearDown(settings.dispose);
    addTearDown(odometer.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: AppStateScope(
          controller: AppStateController(),
          child: GlobalOdometerScope(
            controller: odometer,
            child: TripTrackingSettingsScope(
              controller: settings,
              child: const TripTrackingSettingsScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppScreenHeader), findsOneWidget);
    expect(find.byType(AppBackButton), findsOneWidget);
    expect(find.text('GPS-Assisted Trip Tracking'), findsOneWidget);
  });

  test(
    'iOS location permission is requested at Start Day and supports background escalation',
    () {
      final native = File(
        'ios/Runner/TripTrackingNativeBridge.swift',
      ).readAsStringSync();
      final settings = File(
        'lib/screens/settings/trip_tracking_settings_screen.dart',
      ).readAsStringSync();

      expect(
        native,
        contains('locationManager.requestWhenInUseAuthorization()'),
      );
      expect(native, contains('locationManager.requestAlwaysAuthorization()'));
      expect(native, contains('allowsBackgroundLocationUpdates'));
      expect(settings, contains('Start Day, iPhone asks for location access'));
      final sampling = File(
        'lib/screens/settings/trip_tracking_sampling_explanation.dart',
      ).readAsStringSync();
      expect(sampling, contains('2-second updates'));
      expect(sampling, contains('60-second updates'));
      expect(sampling, contains('brief-stop accuracy'));
    },
  );
}
