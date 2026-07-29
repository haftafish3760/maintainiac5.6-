import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/calendar/calendar_day_flow_support.dart';

void main() {
  testWidgets('day navigation exposes direct date selection and arrows', (
    tester,
  ) async {
    var previous = 0;
    var next = 0;
    var picked = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarDayNavigation(
            day: DateTime(2026, 7, 29),
            onPreviousDay: () => previous++,
            onNextDay: () => next++,
            onPickDate: () => picked++,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Previous day'));
    await tester.tap(find.text('July 29, 2026'));
    await tester.tap(find.byTooltip('Next day'));

    expect(previous, 1);
    expect(picked, 1);
    expect(next, 1);
  });
}
