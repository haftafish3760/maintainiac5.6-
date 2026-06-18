import 'package:flutter/material.dart';

enum CalendarDayMode { past, today, future }

enum CalendarFlowSource {
  dashboard,
  contractor,
  expenses,
  invoices,
  maintenance,
}

enum CalendarEntryType {
  tripEntry,
  stop,
  pickup,
  delivery,
  expense,
  payment,
  invoiceEstimate,
  maintenance,
  materials,
  receiptPhoto,
  note,
  reminderSchedule,
}

enum CalendarEntryStatus { planned, completed, needsAttention }

class CalendarModeProfile {
  const CalendarModeProfile({
    required this.title,
    required this.subtitle,
    required this.fabLabel,
    required this.fabIcon,
    required this.fabColor,
    required this.fabForeground,
  });

  final String title;
  final String subtitle;
  final String fabLabel;
  final IconData fabIcon;
  final Color fabColor;
  final Color fabForeground;
}

class CalendarRecapItem {
  const CalendarRecapItem({required this.label, required this.value});

  final String label;
  final String value;
}

class CalendarDayData {
  const CalendarDayData({required this.recapItems, required this.entries});

  final List<CalendarRecapItem> recapItems;
  final List<CalendarTimelineEntry> entries;

  List<CalendarTimelineEntry> entriesForStatus(CalendarEntryStatus status) {
    return entries.where((entry) => entry.status == status).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }
}

class CalendarTimelineEntry {
  const CalendarTimelineEntry({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.status,
    required this.title,
    required this.source,
    required this.summary,
    required this.details,
  });

  final String id;
  final DateTime timestamp;
  final CalendarEntryType type;
  final CalendarEntryStatus status;
  final String title;
  final String source;
  final String summary;
  final List<String> details;
}

class CalendarEntryMeta {
  const CalendarEntryMeta({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}

CalendarDayMode calendarModeFor(DateTime day) {
  final today = DateUtils.dateOnly(DateTime.now());
  final normalizedDay = DateUtils.dateOnly(day);
  if (normalizedDay.isBefore(today)) {
    return CalendarDayMode.past;
  }
  if (DateUtils.isSameDay(normalizedDay, today)) {
    return CalendarDayMode.today;
  }
  return CalendarDayMode.future;
}

CalendarModeProfile calendarModeProfileFor(CalendarDayMode mode) {
  return switch (mode) {
    CalendarDayMode.past => const CalendarModeProfile(
      title: 'History / Edit Mode',
      subtitle: 'Review the day, correct records, or add anything missed.',
      fabLabel: 'Add Entry',
      fabIcon: Icons.edit_note_rounded,
      fabColor: Color(0xFFFFD166),
      fabForeground: Color(0xFF17120A),
    ),
    CalendarDayMode.today => const CalendarModeProfile(
      title: 'Today / Active Timeline',
      subtitle: 'See planned work, completed work, and active-day status.',
      fabLabel: 'Quick Add',
      fabIcon: Icons.add_task_rounded,
      fabColor: Color(0xFF20F060),
      fabForeground: Color(0xFF07100A),
    ),
    CalendarDayMode.future => const CalendarModeProfile(
      title: 'Planning Mode',
      subtitle: 'Schedule work, reminders, notes, vehicles, and helpers.',
      fabLabel: 'Plan',
      fabIcon: Icons.event_available_rounded,
      fabColor: Color(0xFF4FE8FF),
      fabForeground: Color(0xFF061013),
    ),
  };
}

String calendarDateTitle(DateTime day) {
  return '${day.month}/${day.day}/${day.year}';
}

String calendarSelectorTitle(CalendarDayMode mode) {
  return switch (mode) {
    CalendarDayMode.past => 'Add Missed Entry',
    CalendarDayMode.today => 'Quick Add',
    CalendarDayMode.future => 'Plan Day',
  };
}

String calendarSelectorTitleFor(
  CalendarDayMode mode,
  CalendarFlowSource source,
) {
  if (source == CalendarFlowSource.expenses) {
    return switch (mode) {
      CalendarDayMode.past => 'Add Missed Expense',
      CalendarDayMode.today => 'Add Expense',
      CalendarDayMode.future => 'Plan Expense',
    };
  }
  return calendarSelectorTitle(mode);
}

String calendarDraftSubtitle(CalendarDayMode mode) {
  return switch (mode) {
    CalendarDayMode.past =>
      'Past-day entry: preserve this date and allow correction.',
    CalendarDayMode.today =>
      'Today entry: can become logged work or scheduled work.',
    CalendarDayMode.future =>
      'Future entry: plan only, do not create completed recap.',
  };
}

List<CalendarEntryType> calendarTypesForMode(CalendarDayMode mode) {
  return switch (mode) {
    CalendarDayMode.past => const [
      CalendarEntryType.tripEntry,
      CalendarEntryType.stop,
      CalendarEntryType.pickup,
      CalendarEntryType.delivery,
      CalendarEntryType.expense,
      CalendarEntryType.payment,
      CalendarEntryType.invoiceEstimate,
      CalendarEntryType.maintenance,
      CalendarEntryType.materials,
      CalendarEntryType.receiptPhoto,
      CalendarEntryType.note,
    ],
    CalendarDayMode.today => const [
      CalendarEntryType.tripEntry,
      CalendarEntryType.stop,
      CalendarEntryType.pickup,
      CalendarEntryType.delivery,
      CalendarEntryType.expense,
      CalendarEntryType.payment,
      CalendarEntryType.invoiceEstimate,
      CalendarEntryType.maintenance,
      CalendarEntryType.materials,
      CalendarEntryType.receiptPhoto,
      CalendarEntryType.note,
      CalendarEntryType.reminderSchedule,
    ],
    CalendarDayMode.future => const [
      CalendarEntryType.reminderSchedule,
      CalendarEntryType.note,
      CalendarEntryType.invoiceEstimate,
      CalendarEntryType.maintenance,
      CalendarEntryType.materials,
    ],
  };
}

List<CalendarEntryType> calendarTypesForSource(
  CalendarDayMode mode,
  CalendarFlowSource source,
) {
  if (source == CalendarFlowSource.expenses) {
    return switch (mode) {
      CalendarDayMode.past || CalendarDayMode.today => const [
        CalendarEntryType.expense,
        CalendarEntryType.receiptPhoto,
        CalendarEntryType.payment,
        CalendarEntryType.materials,
        CalendarEntryType.note,
        CalendarEntryType.reminderSchedule,
      ],
      CalendarDayMode.future => const [
        CalendarEntryType.reminderSchedule,
        CalendarEntryType.expense,
        CalendarEntryType.payment,
        CalendarEntryType.note,
      ],
    };
  }
  if (source == CalendarFlowSource.contractor) {
    return switch (mode) {
      CalendarDayMode.past || CalendarDayMode.today => const [
        CalendarEntryType.invoiceEstimate,
        CalendarEntryType.payment,
        CalendarEntryType.expense,
        CalendarEntryType.materials,
        CalendarEntryType.maintenance,
        CalendarEntryType.tripEntry,
        CalendarEntryType.note,
        CalendarEntryType.reminderSchedule,
      ],
      CalendarDayMode.future => const [
        CalendarEntryType.reminderSchedule,
        CalendarEntryType.invoiceEstimate,
        CalendarEntryType.materials,
        CalendarEntryType.maintenance,
        CalendarEntryType.note,
      ],
    };
  }
  return calendarTypesForMode(mode);
}

CalendarEntryMeta calendarEntryMeta(CalendarEntryType type) {
  return switch (type) {
    CalendarEntryType.tripEntry => const CalendarEntryMeta(
      label: 'Trip Entry',
      icon: Icons.route_rounded,
      color: Color(0xFF4FE8FF),
    ),
    CalendarEntryType.stop => const CalendarEntryMeta(
      label: 'Stop',
      icon: Icons.location_on_rounded,
      color: Color(0xFF4FE8FF),
    ),
    CalendarEntryType.pickup => const CalendarEntryMeta(
      label: 'Pickup',
      icon: Icons.move_to_inbox_rounded,
      color: Color(0xFF20F060),
    ),
    CalendarEntryType.delivery => const CalendarEntryMeta(
      label: 'Delivery',
      icon: Icons.outbox_rounded,
      color: Color(0xFFB66DFF),
    ),
    CalendarEntryType.expense => const CalendarEntryMeta(
      label: 'Expense',
      icon: Icons.receipt_long_rounded,
      color: Color(0xFFFF5A4D),
    ),
    CalendarEntryType.payment => const CalendarEntryMeta(
      label: 'Payment',
      icon: Icons.payments_rounded,
      color: Color(0xFF20F060),
    ),
    CalendarEntryType.invoiceEstimate => const CalendarEntryMeta(
      label: 'Invoice / Estimate',
      icon: Icons.description_rounded,
      color: Color(0xFFFFD166),
    ),
    CalendarEntryType.maintenance => const CalendarEntryMeta(
      label: 'Maintenance',
      icon: Icons.build_rounded,
      color: Color(0xFFFF9F1C),
    ),
    CalendarEntryType.materials => const CalendarEntryMeta(
      label: 'Materials',
      icon: Icons.inventory_2_rounded,
      color: Color(0xFFB66DFF),
    ),
    CalendarEntryType.receiptPhoto => const CalendarEntryMeta(
      label: 'Receipt Photo',
      icon: Icons.camera_alt_rounded,
      color: Color(0xFFFFD166),
    ),
    CalendarEntryType.note => const CalendarEntryMeta(
      label: 'Note',
      icon: Icons.note_alt_rounded,
      color: Color(0xFFE2E8EA),
    ),
    CalendarEntryType.reminderSchedule => const CalendarEntryMeta(
      label: 'Reminder / Schedule',
      icon: Icons.event_available_rounded,
      color: Color(0xFF4FE8FF),
    ),
  };
}
