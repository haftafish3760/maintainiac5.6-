// Calendar regression: the day recap remains a clear, full-width action.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/calendar/calendar_flow_widgets.dart';

void main() {
  testWidgets('full recap action is visible and opens on tap', (tester) async {
    var opened = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarRecapActionButton(onPressed: () => opened++),
        ),
      ),
    );

    expect(find.text('Open full recap'), findsOneWidget);
    await tester.tap(find.text('Open full recap'));
    expect(opened, 1);
  });
}
