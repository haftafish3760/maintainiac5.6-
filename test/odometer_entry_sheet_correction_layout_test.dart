import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/odometer/odometer_entry_sheet.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';

void main() {
  for (final textScale in <double>[1, 2]) {
    testWidgets(
      'lower-reading review wraps fully without overflow at ${textScale}x text',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 640);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        final odometer = GlobalOdometerController(
          vehicleId: 'vehicle-1',
          initialReading: 1000,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: const Size(320, 640),
                textScaler: TextScaler.linear(textScale),
              ),
              child: GlobalOdometerScope(
                controller: odometer,
                child: const Scaffold(
                  body: OdometerEntrySheet(
                    title: 'Starting Odometer',
                    saveLabel: 'Save Reading',
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.enterText(find.byType(TextField), '900');
        await tester.ensureVisible(find.text('Save Reading'));
        await tester.tap(find.text('Save Reading'));
        await tester.pumpAndSettle();

        expect(
          find.text('Please review this odometer reading'),
          findsOneWidget,
        );
        expect(
          find.text(
            'This reading is 100 miles below your previous entry of '
            '1,000 miles.',
          ),
          findsOneWidget,
        );
        expect(
          find.text('Select the option that best explains the difference.'),
          findsOneWidget,
        );
        expect(find.text('Correct the entered reading'), findsOneWidget);
        expect(find.textContaining('What happened?'), findsNothing);
        expect(find.text('Typed the wrong number'), findsNothing);
        final field = tester.widget<TextField>(find.byType(TextField));
        expect(field.decoration?.errorText, isNull);
        expect(field.decoration?.errorMaxLines, 3);
        expect(tester.takeException(), isNull);

        await tester.scrollUntilVisible(
          find.text('Save Review'),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(find.text('Save Review'), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(odometer.confirmedReading, 1000);
      },
    );
  }
}
