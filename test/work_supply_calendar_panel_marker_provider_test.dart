import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/calendar/calendar_flow_models.dart';
import 'package:maintaniac/shared/state/app_state.dart';
import 'package:maintaniac/screens/work_supplies/calendar/work_supply_calendar_panel.dart';

void main() {
  testWidgets('Work Supplies uses the shared calendar source and markers', (
    tester,
  ) async {
    final today = DateTime.now();
    await tester.pumpWidget(
      AppStateScope(
        controller: AppStateController(),
        child: MaterialApp(
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
              onDaySelected: (_) {},
              calendarSource: CalendarFlowSource.materials,
            ),
          ),
        ),
      ),
    );

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text && widget.data == '9' && widget.style?.fontSize == 9,
        description: 'aggregated Work Supplies calendar badge count',
      ),
      findsOneWidget,
    );
  });
}
