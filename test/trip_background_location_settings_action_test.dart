import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/settings/trip_background_location_settings_action.dart';

void main() {
  testWidgets('Android preflight opens settings only after confirmation', (
    tester,
  ) async {
    var openCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TripBackgroundLocationSettingsAction(
            platform: TargetPlatform.android,
            onOpenSettings: () async {
              openCalls += 1;
              return true;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Review Android background permission'));
    await tester.pumpAndSettle();
    expect(openCalls, 0);
    await tester.tap(find.text('Open Android settings'));
    await tester.pumpAndSettle();
    expect(openCalls, 1);
  });

  testWidgets('background permission preflight is hidden off Android', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TripBackgroundLocationSettingsAction(
          platform: TargetPlatform.iOS,
          onOpenSettings: () async => true,
        ),
      ),
    );

    expect(find.text('Review Android background permission'), findsNothing);
  });
}
