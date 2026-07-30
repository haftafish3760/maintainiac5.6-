import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/calendar/calendar_filtered_timeline.dart';
import 'package:maintaniac/shared/calendar/calendar_flow_models.dart';
import 'package:maintaniac/shared/calendar/calendar_projection_contract.dart';

void main() {
  testWidgets('empty unfiltered timeline never presents demo activity', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarFilteredTimeline(entries: const [], onOpen: (_) {}),
        ),
      ),
    );

    expect(find.text('No entries for this day'), findsOneWidget);
    expect(
      find.textContaining('Add a record in its own screen'),
      findsOneWidget,
    );
  });

  testWidgets('dashboard timeline filters by entry type and review state', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarFilteredTimeline(
            entries: _entries(),
            enableFiltering: true,
            onOpen: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Fuel'), findsOneWidget);
    expect(find.text('Client visit'), findsOneWidget);
    await tester.tap(
      find.byType(DropdownButtonFormField<CalendarProjectionSource?>).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Expense').last);
    await tester.pumpAndSettle();

    expect(find.text('Fuel'), findsOneWidget);
    expect(find.text('Client visit'), findsNothing);

    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byType(DropdownButtonFormField<CalendarEntryStatus?>).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Planned').last);
    await tester.pumpAndSettle();

    expect(find.text('Fuel'), findsNothing);
    expect(find.text('Client visit'), findsOneWidget);
  });

  testWidgets('timeline filters source-owned business use when available', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarFilteredTimeline(
            entries: _entries(),
            enableFiltering: true,
            onOpen: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(
      find.byType(DropdownButtonFormField<CalendarBusinessClassification?>),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Business').last);
    await tester.pumpAndSettle();

    expect(find.text('Fuel'), findsOneWidget);
    expect(find.text('Client visit'), findsNothing);

    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byType(DropdownButtonFormField<CalendarBusinessClassification?>),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Personal').last);
    await tester.pumpAndSettle();

    expect(find.text('No matching entries'), findsOneWidget);
    expect(find.text('No entries for this day'), findsNothing);
  });

  testWidgets('timeline filters by projected vehicle and work profile', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarFilteredTimeline(
            entries: _entries(),
            enableFiltering: true,
            onOpen: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('All vehicles'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('vehicle-2').last);
    await tester.pumpAndSettle();

    expect(find.text('Client visit'), findsOneWidget);
    expect(find.text('Fuel'), findsNothing);

    await tester.tap(find.text('All profiles'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('delivery').last);
    await tester.pumpAndSettle();

    expect(find.text('No matching entries'), findsOneWidget);
  });

  testWidgets('Dashboard filters fit phone, tablet, and desktop widths', (
    tester,
  ) async {
    for (final width in [320.0, 412.0, 768.0, 1280.0]) {
      await tester.pumpWidget(_filterTimelineForWidth(width));

      expect(
        tester.takeException(),
        isNull,
        reason: 'Dashboard filters overflowed at $width logical pixels.',
      );
      expect(find.text('FILTER ENTRIES'), findsOneWidget);
      expect(find.text('Vehicle'), findsOneWidget);
      expect(find.text('Work profile'), findsOneWidget);
    }
  });

  testWidgets('source calendars do not render Dashboard filter controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarFilteredTimeline(entries: _entries(), onOpen: (_) {}),
        ),
      ),
    );

    expect(find.text('FILTER ENTRIES'), findsNothing);
    expect(find.text('Fuel'), findsOneWidget);
    expect(find.text('Client visit'), findsOneWidget);
  });
}

Widget _filterTimelineForWidth(double width) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: width,
        child: CalendarFilteredTimeline(
          entries: _entries(),
          enableFiltering: true,
          onOpen: (_) {},
        ),
      ),
    ),
  ),
);

List<CalendarTimelineEntry> _entries() => [
  _entry(
    id: 'expense',
    title: 'Fuel',
    source: CalendarProjectionSource.expense,
    status: CalendarEntryStatus.needsAttention,
    businessClassification: CalendarBusinessClassification.business,
    vehicleId: 'vehicle-1',
    workProfileId: 'delivery',
  ),
  _entry(
    id: 'job',
    title: 'Client visit',
    source: CalendarProjectionSource.job,
    status: CalendarEntryStatus.planned,
    vehicleId: 'vehicle-2',
    workProfileId: 'service',
  ),
];

CalendarTimelineEntry _entry({
  required String id,
  required String title,
  required CalendarProjectionSource source,
  required CalendarEntryStatus status,
  CalendarBusinessClassification? businessClassification,
  String? vehicleId,
  String? workProfileId,
}) => CalendarTimelineEntry(
  id: id,
  timestamp: DateTime(2026, 7, 29, 9),
  type: CalendarEntryType.note,
  status: status,
  title: title,
  source: source.name,
  summary: 'Test entry',
  details: const [],
  projection: CalendarProjectionEvent(
    eventId: id,
    source: source,
    sourceRecordId: id,
    timing: CalendarProjectionTiming(
      eventDate: DateTime(2026, 7, 29),
      recordedAt: DateTime(2026, 7, 29, 9),
      timeSource: CalendarTimeSource.recorded,
    ),
    title: title,
    conciseDetail: 'Test entry',
    state: CalendarProjectionState.needsReview,
    sourceRecordStatus: 'test',
    revision: 1,
    businessClassification: businessClassification,
    vehicleIds: vehicleId == null ? const [] : [vehicleId],
    workProfileId: workProfileId,
    deepLink: CalendarProjectionDeepLink(
      target: CalendarDeepLinkTarget.expenseDetail,
      sourceRecordId: id,
    ),
  ),
);
