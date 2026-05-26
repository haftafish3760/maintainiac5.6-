import 'package:flutter/material.dart';

import '../../shared/navigation/app_page_routes.dart';
import '../../shared/widgets/app_back_button.dart';
import 'calendar_dummy_data.dart';
import 'calendar_entry_flow.dart';
import 'calendar_flow_models.dart';
import 'calendar_flow_widgets.dart';

class CalendarDayFlowScreen extends StatelessWidget {
  const CalendarDayFlowScreen({
    super.key,
    required this.day,
    this.source = CalendarFlowSource.dashboard,
  });

  final DateTime day;
  final CalendarFlowSource source;

  @override
  Widget build(BuildContext context) {
    final selectedDay = DateUtils.dateOnly(day);
    final mode = calendarModeFor(selectedDay);
    final profile = calendarModeProfileFor(mode);
    final data = calendarDummyDataFor(selectedDay, mode, source: source);

    return Scaffold(
      backgroundColor: const Color(0xFF1F2528),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: profile.fabColor,
        foregroundColor: profile.fabForeground,
        icon: Icon(profile.fabIcon),
        label: Text(profile.fabLabel),
        onPressed: () => _openEntrySelector(context, selectedDay, mode),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 92),
          children: [
            AppScreenHeader(title: _screenTitle(selectedDay)),
            const SizedBox(height: 12),
            CalendarModeHeader(day: selectedDay, profile: profile),
            const SizedBox(height: 12),
            ..._sectionsForMode(context, selectedDay, mode, data),
          ],
        ),
      ),
    );
  }

  List<Widget> _sectionsForMode(
    BuildContext context,
    DateTime day,
    CalendarDayMode mode,
    CalendarDayData data,
  ) {
    return switch (mode) {
      CalendarDayMode.past => _pastDaySections(context, day, mode, data),
      CalendarDayMode.today => _todaySections(context, day, mode, data),
      CalendarDayMode.future => _futureSections(context, day, mode, data),
    };
  }

  List<Widget> _pastDaySections(
    BuildContext context,
    DateTime day,
    CalendarDayMode mode,
    CalendarDayData data,
  ) {
    return [
      const CalendarSectionTitle('COMPLETED DAY RECAP'),
      const SizedBox(height: 8),
      CalendarRecapStrip(items: data.recapItems),
      const SizedBox(height: 14),
      CalendarSectionTitle.withAction(
        label: source == CalendarFlowSource.expenses
            ? 'EXPENSE ENTRIES'
            : 'CHRONOLOGICAL ENTRIES',
        actionLabel: 'Add missed entry',
        onPressed: () => _openEntrySelector(context, day, mode),
      ),
      const SizedBox(height: 8),
      ..._timelineRows(context, day, mode, data.entries),
      const SizedBox(height: 14),
      const CalendarStatusPanel(
        icon: Icons.edit_calendar_rounded,
        title: 'Past day record',
        subtitle:
            'Use this screen to correct entries or add something that happened on this date.',
      ),
    ];
  }

  List<Widget> _todaySections(
    BuildContext context,
    DateTime day,
    CalendarDayMode mode,
    CalendarDayData data,
  ) {
    final planned = data.entriesForStatus(CalendarEntryStatus.planned);
    final logged =
        data.entries
            .where((entry) => entry.status != CalendarEntryStatus.planned)
            .toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return [
      const CalendarSectionTitle('ACTIVE DAY STATE'),
      const SizedBox(height: 8),
      const CalendarStatusPanel(
        icon: Icons.timer_rounded,
        title: 'Work day in progress',
        subtitle:
            'Today can show scheduled work and completed records together.',
      ),
      const SizedBox(height: 14),
      CalendarSectionTitle.withAction(
        label: 'PLANNED TODAY',
        actionLabel: 'Add plan',
        onPressed: () => _openEntryDraft(
          context,
          day,
          mode,
          CalendarEntryType.reminderSchedule,
        ),
      ),
      const SizedBox(height: 8),
      ..._timelineRows(context, day, mode, planned),
      const SizedBox(height: 14),
      CalendarSectionTitle.withAction(
        label: 'LOGGED TODAY',
        actionLabel: 'Quick add',
        onPressed: () => _openEntrySelector(context, day, mode),
      ),
      const SizedBox(height: 8),
      ..._timelineRows(context, day, mode, logged),
    ];
  }

  List<Widget> _futureSections(
    BuildContext context,
    DateTime day,
    CalendarDayMode mode,
    CalendarDayData data,
  ) {
    return [
      CalendarSectionTitle.withAction(
        label: 'PLANNED ITEMS',
        actionLabel: 'Plan item',
        onPressed: () => _openEntrySelector(context, day, mode),
      ),
      const SizedBox(height: 8),
      ..._timelineRows(context, day, mode, data.entries),
      const SizedBox(height: 14),
      const CalendarStatusPanel(
        icon: Icons.info_outline_rounded,
        title: 'Planning only',
        subtitle:
            'Future dates do not show completed recap. They are for jobs, reminders, notes, vehicles, helpers, and linked work.',
      ),
    ];
  }

  List<Widget> _timelineRows(
    BuildContext context,
    DateTime day,
    CalendarDayMode mode,
    List<CalendarTimelineEntry> entries,
  ) {
    if (entries.isEmpty) {
      return const [
        CalendarStatusPanel(
          icon: Icons.inbox_rounded,
          title: 'No entries yet',
          subtitle: 'Use the action button to add something for this date.',
        ),
      ];
    }

    final sortedEntries = [...entries]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return [
      for (final entry in sortedEntries)
        CalendarTimelineItem(
          entry: entry,
          onTap: () => _openEntryDetail(context, day, mode, entry),
        ),
    ];
  }

  void _openEntrySelector(
    BuildContext context,
    DateTime day,
    CalendarDayMode mode,
  ) {
    Navigator.of(context).push(
      appNativeRoute<void>(
        context,
        CalendarEntryTypeSelectorScreen(day: day, mode: mode, source: source),
      ),
    );
  }

  void _openEntryDraft(
    BuildContext context,
    DateTime day,
    CalendarDayMode mode,
    CalendarEntryType type,
  ) {
    Navigator.of(context).push(
      appNativeRoute<void>(
        context,
        CalendarEntryDraftScreen(
          day: day,
          mode: mode,
          type: type,
          source: source,
        ),
      ),
    );
  }

  void _openEntryDetail(
    BuildContext context,
    DateTime day,
    CalendarDayMode mode,
    CalendarTimelineEntry entry,
  ) {
    Navigator.of(context).push(
      appNativeRoute<void>(
        context,
        CalendarEntryDetailScreen(
          day: day,
          mode: mode,
          entry: entry,
          source: source,
        ),
      ),
    );
  }

  String _screenTitle(DateTime selectedDay) {
    final prefix = source == CalendarFlowSource.expenses ? 'Expenses ' : '';
    return '$prefix${calendarDateTitle(selectedDay)}';
  }
}
