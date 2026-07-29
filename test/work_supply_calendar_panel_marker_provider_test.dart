import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/calendar/work_supply_calendar_panel.dart';

void main() {
  testWidgets('dynamic marker provider overrides legacy date markers', (
    tester,
  ) async {
    final today = DateTime.now();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorkSupplyCalendarPanel(
            markersByDay: {
              DateTime.utc(today.year, today.month, today.day): const [
                WorkSupplyCalendarMarker(
                  label: 'L',
                  color: Colors.red,
                  count: 9,
                ),
              ],
            },
            markersForDay: (day) => DateUtils.isSameDay(day, today)
                ? const [
                    WorkSupplyCalendarMarker(
                      label: 'J',
                      color: Colors.blue,
                      count: 2,
                    ),
                  ]
                : const [],
            onDaySelected: (_) {},
          ),
        ),
      ),
    );

    final markerCount = find.byWidgetPredicate(
      (widget) =>
          widget is Text && widget.data == '2' && widget.style?.fontSize == 9,
      description: 'dynamic calendar marker count',
    );

    expect(markerCount, findsOneWidget);
    expect(find.text('L'), findsNothing);
  });
}
