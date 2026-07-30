import 'package:flutter/material.dart';

import 'calendar_projection_contract.dart';

/// Read-only source-owner detail handoff for a projected Calendar event.
typedef CalendarSourceEventDetailBuilder =
    Widget? Function(CalendarProjectionEvent event);

enum CalendarDayMode { past, today, future }

enum CalendarFlowSource {
  dashboard,
  contractor,
  jobs,
  materials,
  expenses,
  invoices,
  maintenance,
  employee,
}

enum CalendarEntryType {
  tripEntry,
  job,
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
    this.timeLabel,
    this.projection,
  });

  factory CalendarTimelineEntry.fromProjection(CalendarProjectionEvent event) {
    final timing = event.timing;
    final stateLabel = _projectionStateLabel(event.state);
    return CalendarTimelineEntry(
      id: event.eventId,
      timestamp: timing.chronologicalTime,
      timeLabel: switch (timing.timeSource) {
        CalendarTimeSource.actual || CalendarTimeSource.scheduled => null,
        CalendarTimeSource.recorded => 'Recorded',
        CalendarTimeSource.unknown => 'Time?',
      },
      type: _entryTypeForProjectionSource(event.source),
      status: _entryStatusForProjectionState(event.state),
      title: event.title,
      source: _projectionSourceLabel(event.source),
      summary:
          '$stateLabel · ${timing.displayTimeLabel} · ${event.conciseDetail}',
      details: [
        'State: $stateLabel',
        '${timing.displayTimeLabel}: ${_projectionDateTimeLabel(timing.displayChronologicalTime)}',
        if (timing.scheduledEndAt != null)
          'Planned end: ${_projectionDateTimeLabel(timing.displayScheduledAt(timing.scheduledEndAt!))}',
        'Recorded: ${_projectionDateTimeLabel(timing.displayRecordedAt(timing.recordedAt))}',
        if (timing.timezoneId != null) 'Source time zone: ${timing.timezoneId}',
        if (event.vehicleIds.isNotEmpty)
          'Vehicle: ${event.vehicleIds.join(', ')}',
        if (event.workProfileId != null) 'Work profile: ${event.workProfileId}',
        if (event.businessClassification != null)
          'Use: ${_businessClassificationLabel(event.businessClassification!)}',
        if (event.participantIds.isNotEmpty)
          'People: ${event.participantIds.join(', ')}',
        if (event.evidence.evidenceId != null)
          'Evidence ID: ${event.evidence.evidenceId}',
        if (event.evidence.proposalId != null)
          'Proposal ID: ${event.evidence.proposalId}',
        if (event.evidence.summary != null)
          'Evidence: ${event.evidence.summary}',
        if (event.evidence.strength != null)
          'Evidence strength: ${event.evidence.strength}',
        if (event.evidence.recommendationConfidence != null)
          'Recommendation confidence: ${_confidenceLabel(event.evidence.recommendationConfidence!)}',
        if (event.evidence.explanation != null)
          'Review detail: ${event.evidence.explanation}',
        if (event.evidence.acceptanceImpact != null)
          'If accepted: ${event.evidence.acceptanceImpact}',
        if (event.evidence.ignoreImpact != null)
          'If ignored: ${event.evidence.ignoreImpact}',
        if (event.auditReference != null) 'Audit: ${event.auditReference}',
      ],
      projection: event,
    );
  }

  final String id;
  final DateTime timestamp;
  final CalendarEntryType type;
  final CalendarEntryStatus status;
  final String title;
  final String source;
  final String summary;
  final List<String> details;
  final String? timeLabel;
  final CalendarProjectionEvent? projection;
}

String _confidenceLabel(double confidence) =>
    '${(confidence.clamp(0, 1) * 100).toStringAsFixed(0)}%';

CalendarEntryType _entryTypeForProjectionSource(
  CalendarProjectionSource source,
) => switch (source) {
  CalendarProjectionSource.activeWorkday => CalendarEntryType.tripEntry,
  CalendarProjectionSource.trip => CalendarEntryType.tripEntry,
  CalendarProjectionSource.stop => CalendarEntryType.stop,
  CalendarProjectionSource.job => CalendarEntryType.job,
  CalendarProjectionSource.expense => CalendarEntryType.expense,
  CalendarProjectionSource.receipt => CalendarEntryType.receiptPhoto,
  CalendarProjectionSource.invoice ||
  CalendarProjectionSource.estimate => CalendarEntryType.invoiceEstimate,
  CalendarProjectionSource.payment => CalendarEntryType.payment,
  CalendarProjectionSource.maintenance => CalendarEntryType.maintenance,
  CalendarProjectionSource.inventory => CalendarEntryType.materials,
  CalendarProjectionSource.reminder => CalendarEntryType.reminderSchedule,
  CalendarProjectionSource.calendarSchedule =>
    CalendarEntryType.reminderSchedule,
  CalendarProjectionSource.workTime => CalendarEntryType.note,
  CalendarProjectionSource.odometer => CalendarEntryType.tripEntry,
  CalendarProjectionSource.vehicleProfile => CalendarEntryType.note,
};

CalendarEntryStatus _entryStatusForProjectionState(
  CalendarProjectionState state,
) => switch (state) {
  CalendarProjectionState.proposed => CalendarEntryStatus.planned,
  CalendarProjectionState.confirmed ||
  CalendarProjectionState.historical => CalendarEntryStatus.completed,
  _ => CalendarEntryStatus.needsAttention,
};

String _projectionStateLabel(CalendarProjectionState state) => switch (state) {
  CalendarProjectionState.confirmed => 'Confirmed',
  CalendarProjectionState.proposed => 'Proposed',
  CalendarProjectionState.needsReview => 'Needs review',
  CalendarProjectionState.rejected => 'Rejected',
  CalendarProjectionState.voided => 'Voided',
  CalendarProjectionState.historical => 'Historical',
  CalendarProjectionState.incomplete => 'Incomplete',
  CalendarProjectionState.blocked => 'Blocked',
};

String _businessClassificationLabel(CalendarBusinessClassification value) =>
    switch (value) {
      CalendarBusinessClassification.business => 'Business',
      CalendarBusinessClassification.personal => 'Personal',
      CalendarBusinessClassification.mixed => 'Business and personal',
      CalendarBusinessClassification.unclassified => 'Needs classification',
    };

String _projectionSourceLabel(CalendarProjectionSource source) =>
    switch (source) {
      CalendarProjectionSource.activeWorkday => 'Active workday',
      CalendarProjectionSource.trip => 'Trip tracking',
      CalendarProjectionSource.stop => 'Stop review',
      CalendarProjectionSource.job => 'Jobs',
      CalendarProjectionSource.expense => 'Expenses',
      CalendarProjectionSource.receipt => 'Receipts',
      CalendarProjectionSource.invoice => 'Invoices',
      CalendarProjectionSource.estimate => 'Estimates',
      CalendarProjectionSource.payment => 'Payments',
      CalendarProjectionSource.maintenance => 'Maintenance',
      CalendarProjectionSource.inventory => 'Inventory',
      CalendarProjectionSource.reminder => 'Reminders',
      CalendarProjectionSource.calendarSchedule => 'Calendar schedule',
      CalendarProjectionSource.workTime => 'Work time',
      CalendarProjectionSource.odometer => 'Odometer',
      CalendarProjectionSource.vehicleProfile => 'Vehicle profile',
    };

String _projectionDateTimeLabel(DateTime time) {
  final hour = time.hour == 0
      ? 12
      : time.hour > 12
      ? time.hour - 12
      : time.hour;
  final minute = time.minute.toString().padLeft(2, '0');
  return '${time.month}/${time.day}/${time.year} $hour:$minute ${time.hour >= 12 ? 'PM' : 'AM'}${time.isUtc ? ' UTC' : ''}';
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
      fabLabel: 'Schedule',
      fabIcon: Icons.edit_note_rounded,
      fabColor: Color(0xFFFFD166),
      fabForeground: Color(0xFF17120A),
    ),
    CalendarDayMode.today => const CalendarModeProfile(
      title: 'Today / Active Timeline',
      subtitle: 'See planned work, completed work, and active-day status.',
      fabLabel: 'Schedule',
      fabIcon: Icons.add_task_rounded,
      fabColor: Color(0xFF20F060),
      fabForeground: Color(0xFF07100A),
    ),
    CalendarDayMode.future => const CalendarModeProfile(
      title: 'Planning Mode',
      subtitle: 'Schedule work, reminders, notes, vehicles, and helpers.',
      fabLabel: 'Schedule',
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
      CalendarEntryType.job,
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
      CalendarEntryType.job,
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
      CalendarEntryType.job,
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
  // Keep the Dashboard Quick Add contract stable. Jobs own scheduling in their
  // own screen; this source-specific grid must remain the established set of
  // quick entries rather than gaining a competing Job tile.
  if (source == CalendarFlowSource.dashboard) {
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
        CalendarEntryType.job,
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
        CalendarEntryType.job,
        CalendarEntryType.invoiceEstimate,
        CalendarEntryType.materials,
        CalendarEntryType.maintenance,
        CalendarEntryType.note,
      ],
    };
  }
  if (source == CalendarFlowSource.jobs) {
    return switch (mode) {
      CalendarDayMode.past || CalendarDayMode.today => const [
        CalendarEntryType.job,
        CalendarEntryType.note,
        CalendarEntryType.reminderSchedule,
      ],
      CalendarDayMode.future => const [
        CalendarEntryType.job,
        CalendarEntryType.reminderSchedule,
        CalendarEntryType.note,
      ],
    };
  }
  if (source == CalendarFlowSource.employee) {
    return switch (mode) {
      CalendarDayMode.past || CalendarDayMode.today => const [
        CalendarEntryType.tripEntry,
        CalendarEntryType.job,
        CalendarEntryType.invoiceEstimate,
        CalendarEntryType.expense,
        CalendarEntryType.materials,
        CalendarEntryType.maintenance,
        CalendarEntryType.note,
        CalendarEntryType.reminderSchedule,
      ],
      CalendarDayMode.future => const [
        CalendarEntryType.reminderSchedule,
        CalendarEntryType.job,
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
    CalendarEntryType.job => const CalendarEntryMeta(
      label: 'Job / Appointment',
      icon: Icons.event_available_rounded,
      color: Color(0xFF20F060),
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
