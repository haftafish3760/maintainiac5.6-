// Odometer-entry modal surface regression coverage.
//
// Owns the readable container contract for the shared odometer entry sheet.
// Does not own validation, persistence, or individual Dashboard workflows.
// Consumed by Dashboard and trip-review UI regression gates.
// The sheet must retain a light base surface because it uses dark text.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/odometer/open_odometer_entry.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';

void main() {
  testWidgets(
    'shared odometer entry keeps dark text on a light sheet surface',
    (tester) async {
      final odometer = GlobalOdometerController(initialReading: 1000);
      addTearDown(odometer.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: GlobalOdometerScope(
            controller: odometer,
            child: Builder(
              builder: (context) => Scaffold(
                body: FilledButton(
                  onPressed: () => openOdometerEntry(context),
                  child: const Text('Open odometer'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open odometer'));
      await tester.pumpAndSettle();

      final sheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
      expect(sheet.backgroundColor, const Color(0xFFF4F7F8));
      expect(find.text('Update Odometer'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
