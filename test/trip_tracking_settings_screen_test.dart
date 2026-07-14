import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/settings/trip_tracking_settings_screen.dart';
import 'package:maintaniac/shared/state/app_state.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/profiles/user_profile_store.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';

void main() {
  testWidgets('GPS settings are visible and remain opt-in', (tester) async {
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
    expect(settings.settings.gpsAssistedTrackingEnabled, isFalse);
    expect(find.text('Back up reviewed mileage to Firebase'), findsOneWidget);
    expect(profiles.activeProfile.cloudBackupEnabled, isFalse);
  });
}
