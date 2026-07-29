import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/calendar/calendar_flow_models.dart';
import 'package:maintaniac/shared/calendar/calendar_flow_widgets.dart';

void main() {
  testWidgets('timeline items expose time source and review state to readers', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final entry = _entry();
    var opened = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarTimelineItem(entry: entry, onTap: () => opened = true),
        ),
      ),
    );

    final label = calendarTimelineAccessibilityLabel(entry);
    expect(label, contains('Recorded'));
    expect(label, contains('Needs review'));
    expect(
      tester.getSemantics(find.byType(CalendarTimelineItem)),
      matchesSemantics(
        label: label,
        hint: 'Open Expense details',
        isButton: true,
        hasTapAction: true,
      ),
    );

    await tester.tap(find.byType(CalendarTimelineItem));
    expect(opened, isTrue);
    handle.dispose();
  });
}

CalendarTimelineEntry _entry() => CalendarTimelineEntry(
  id: 'expense-1',
  timestamp: DateTime(2026, 7, 29, 9, 30),
  type: CalendarEntryType.expense,
  status: CalendarEntryStatus.needsAttention,
  title: 'Fuel receipt needs review',
  source: 'Expense',
  summary: 'Needs review · Recorded time · OCR total needs confirmation',
  details: const [],
  timeLabel: 'Recorded',
);
