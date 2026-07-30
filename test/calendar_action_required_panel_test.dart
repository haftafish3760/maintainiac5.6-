// Calendar regression: action-required records are surfaced without changing
// the complete chronological timeline or creating a Calendar editor.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/calendar/calendar_action_required_panel.dart';
import 'package:maintaniac/shared/calendar/calendar_flow_models.dart';

void main() {
  test('action queue selects only actionable entries in time order', () {
    final entries = calendarActionRequiredEntries([
      _entry('confirmed', 10, CalendarEntryStatus.completed),
      _entry('later review', 11, CalendarEntryStatus.needsAttention),
      _entry('first review', 9, CalendarEntryStatus.needsAttention),
    ]);

    expect(entries.map((entry) => entry.id), ['first review', 'later review']);
  });

  testWidgets('action queue opens its source-owned entry shortcut', (
    tester,
  ) async {
    CalendarTimelineEntry? opened;
    final entry = _entry('review', 9, CalendarEntryStatus.needsAttention);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarActionRequiredPanel(
            entries: [entry],
            onOpen: (value) => opened = value,
          ),
        ),
      ),
    );

    expect(find.text('1 item needs review'), findsOneWidget);
    expect(find.text('review'), findsOneWidget);
    await tester.tap(find.text('review'));
    expect(opened?.id, 'review');
  });
}

CalendarTimelineEntry _entry(String id, int hour, CalendarEntryStatus status) =>
    CalendarTimelineEntry(
      id: id,
      timestamp: DateTime(2026, 7, 30, hour),
      type: CalendarEntryType.job,
      status: status,
      title: id,
      source: 'Jobs',
      summary: 'Calendar test entry',
      details: const [],
    );
