import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/dashboard/trip_background_location_settings_prompt.dart';

void main() {
  testWidgets('background location handoff stays explicit and dismissible', (
    tester,
  ) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showTripBackgroundLocationSettingsPrompt(context);
            },
            child: const Text('Start'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(find.text('Allow background GPS'), findsOneWidget);
    expect(find.textContaining('Allow all the time'), findsOneWidget);
    expect(
      find.textContaining('Manual mileage remains available'),
      findsOneWidget,
    );

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });

  testWidgets('settings action returns only after user confirmation', (
    tester,
  ) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showTripBackgroundLocationSettingsPrompt(context);
            },
            child: const Text('Start'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open Android settings'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });
}
