import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/settings/trip_tracking_gps_opt_in_flow.dart';
import 'package:maintaniac/shared/state/app_state.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';

void main() {
  testWidgets('first GPS opt-in asks for optional vehicle tire context', (
    tester,
  ) async {
    final appState = AppStateController();
    var settings = const TripTrackingSettings();

    await tester.pumpWidget(
      MaterialApp(
        home: AppStateScope(
          controller: appState,
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => updateGpsAssistedTrackingOptIn(
                context: context,
                settings: settings,
                onChanged: (value) => settings = value,
                enabled: true,
              ),
              child: const Text('Enable GPS'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Enable GPS'));
    await tester.pumpAndSettle();

    expect(find.text('Check your tire setup'), findsOneWidget);
    expect(settings.gpsAssistedTrackingEnabled, isFalse);

    await tester.tap(find.text('Save and continue'));
    await tester.pumpAndSettle();

    expect(settings.gpsAssistedTrackingEnabled, isTrue);
    expect(appState.activeVehicle?.tireConfigurationRevision, 1);
    expect(appState.activeVehicle?.tireConfigurationUpdatedAt, isNotNull);
  });

  testWidgets('declining tire setup does not block explicit GPS opt-in', (
    tester,
  ) async {
    final appState = AppStateController();
    var settings = const TripTrackingSettings();

    await tester.pumpWidget(
      MaterialApp(
        home: AppStateScope(
          controller: appState,
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => updateGpsAssistedTrackingOptIn(
                context: context,
                settings: settings,
                onChanged: (value) => settings = value,
                enabled: true,
              ),
              child: const Text('Enable GPS'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Enable GPS'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    expect(settings.gpsAssistedTrackingEnabled, isTrue);
    expect(appState.activeVehicle?.tireConfigurationUpdatedAt, isNull);
  });
}
