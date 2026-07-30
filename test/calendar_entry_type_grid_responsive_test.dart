// Calendar regression: add-entry labels never truncate on compact screens.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/calendar/calendar_entry_flow.dart';
import 'package:maintaniac/shared/calendar/calendar_flow_models.dart';

void main() {
  testWidgets('add-entry grid keeps long labels readable at enlarged text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: CalendarEntryTypeGrid(
              day: DateTime(2026, 7, 30),
              mode: CalendarDayMode.today,
              source: CalendarFlowSource.dashboard,
              types: const [
                CalendarEntryType.invoiceEstimate,
                CalendarEntryType.job,
              ],
              onSelected: (_) {},
            ),
          ),
        ),
      ),
    );

    final label = tester.widget<Text>(find.text('Invoice / Estimate'));
    expect(label.overflow, isNull);
    expect(label.maxLines, isNull);
    expect(tester.takeException(), isNull);

    await tester.binding.setSurfaceSize(null);
  });
}
