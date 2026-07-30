// Calendar regression: recap readouts use the available screen width without
// shrinking compact-phone content or forcing tablet/desktop layouts into pairs.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/calendar/calendar_flow_models.dart';
import 'package:maintaniac/shared/calendar/calendar_flow_widgets.dart';

void main() {
  testWidgets('recap tiles use responsive phone, tablet, and desktop columns', (
    tester,
  ) async {
    for (final expectation in [
      (width: 320.0, reviewSharesRow: false, cashSharesRow: false),
      (width: 720.0, reviewSharesRow: true, cashSharesRow: false),
      (width: 1080.0, reviewSharesRow: true, cashSharesRow: true),
    ]) {
      await tester.binding.setSurfaceSize(Size(expectation.width, 700));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: expectation.width,
              child: CalendarRecapStrip(items: _items),
            ),
          ),
        ),
      );

      final entries = tester.getTopLeft(find.text('Entries'));
      final review = tester.getTopLeft(find.text('Awaiting review'));
      final cash = tester.getTopLeft(find.text('Cash received'));

      expect(review.dy == entries.dy, expectation.reviewSharesRow);
      expect(cash.dy == entries.dy, expectation.cashSharesRow);
      expect(tester.takeException(), isNull);
    }

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('recap tiles remain readable at enlarged phone text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(body: CalendarRecapStrip(items: _items)),
        ),
      ),
    );

    expect(find.text('Awaiting review'), findsOneWidget);
    expect(find.text(r'$450.00'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.binding.setSurfaceSize(null);
  });
}

const _items = [
  CalendarRecapItem(label: 'Entries', value: '12'),
  CalendarRecapItem(label: 'Stops', value: '4'),
  CalendarRecapItem(label: 'Awaiting review', value: '2'),
  CalendarRecapItem(label: 'Cash received', value: r'$450.00'),
];
