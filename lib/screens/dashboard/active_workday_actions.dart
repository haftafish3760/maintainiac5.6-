import 'package:flutter/material.dart';

import '../../shared/theme/app_action_colors.dart';

enum WorkdayQuickActionKind {
  pauseDay,
  resumeDay,
  endDay,
  addFuel,
  addStop,
  addPickup,
  addDropOff,
  expense,
  payment,
  invoice,
  maintenance,
  materials,
  receipt,
  reminder,
  estimate,
  note,
}

class WorkdayQuickActionSpec {
  const WorkdayQuickActionSpec({
    required this.kind,
    required this.icon,
    required this.emoji,
    required this.label,
    required this.color,
    required this.flowTitle,
    required this.flowSummary,
    this.requiresOdometer = false,
  });

  final WorkdayQuickActionKind kind;
  final IconData icon;
  final String emoji;
  final String label;
  final Color color;
  final String flowTitle;
  final String flowSummary;
  final bool requiresOdometer;
}

const workdayQuickActions = [
  WorkdayQuickActionSpec(
    kind: WorkdayQuickActionKind.pauseDay,
    icon: Icons.pause_rounded,
    emoji: '⏸️',
    label: 'Pause Day',
    color: Color(0xFFFFB02E),
    flowTitle: 'Pause Workday',
    flowSummary:
        'Pause the active timer without ending the day. Later this will preserve the current shift and switch the button to Resume Day.',
    requiresOdometer: true,
  ),
  WorkdayQuickActionSpec(
    kind: WorkdayQuickActionKind.endDay,
    icon: Icons.stop_rounded,
    emoji: '⏹️',
    label: 'End Day',
    color: AppActionColors.danger,
    flowTitle: 'End Workday',
    flowSummary:
        'Review the active day, confirm required records, then end the workday.',
    requiresOdometer: true,
  ),
  WorkdayQuickActionSpec(
    kind: WorkdayQuickActionKind.addFuel,
    icon: Icons.local_gas_station_rounded,
    emoji: '⛽',
    label: 'Add Fuel',
    color: Color(0xFF1CA7E8),
    flowTitle: 'Add Fuel',
    flowSummary:
        'Record a fuel purchase with odometer, fuel details, payment details, and receipt attachments.',
    requiresOdometer: true,
  ),
  WorkdayQuickActionSpec(
    kind: WorkdayQuickActionKind.addStop,
    icon: Icons.place_rounded,
    emoji: '📍',
    label: 'Add Stop',
    color: Color(0xFF1CA7E8),
    flowTitle: 'Add Stop',
    flowSummary:
        'Log a stop for the active day with time, location, notes, and optional mileage.',
    requiresOdometer: true,
  ),
  WorkdayQuickActionSpec(
    kind: WorkdayQuickActionKind.addPickup,
    icon: Icons.archive_rounded,
    emoji: '📥',
    label: 'Add Pickup',
    color: AppActionColors.positive,
    flowTitle: 'Add Pickup',
    flowSummary:
        'Log a pickup and optionally connect it to a customer, job, invoice, or delivery.',
    requiresOdometer: true,
  ),
  WorkdayQuickActionSpec(
    kind: WorkdayQuickActionKind.addDropOff,
    icon: Icons.outbox_rounded,
    emoji: '📤',
    label: 'Add Drop-Off',
    color: Color(0xFF9E3DDF),
    flowTitle: 'Add Drop-Off',
    flowSummary:
        'Log a drop-off and optionally close out linked pickup or delivery work.',
    requiresOdometer: true,
  ),
  WorkdayQuickActionSpec(
    kind: WorkdayQuickActionKind.expense,
    icon: Icons.receipt_long_rounded,
    emoji: '🧾',
    label: 'Expense',
    color: Color(0xFFFF6F3D),
    flowTitle: 'Add Expense',
    flowSummary:
        'Record an expense, category, amount, vendor, vehicle, and receipt attachments.',
  ),
  WorkdayQuickActionSpec(
    kind: WorkdayQuickActionKind.payment,
    icon: Icons.payments_rounded,
    emoji: '💵',
    label: 'Payment',
    color: AppActionColors.positive,
    flowTitle: 'Record Payment',
    flowSummary:
        'Record a payment received and connect it to an invoice, estimate, customer, or workday.',
  ),
  WorkdayQuickActionSpec(
    kind: WorkdayQuickActionKind.invoice,
    icon: Icons.description_rounded,
    emoji: '📄',
    label: 'Invoice',
    color: Color(0xFF607D8B),
    flowTitle: 'Create Invoice',
    flowSummary:
        'Create or update an invoice from the active day, selected work, payments, and materials.',
  ),
];

const availableWorkdayQuickActions = [
  ...workdayQuickActions,
  WorkdayQuickActionSpec(
    kind: WorkdayQuickActionKind.maintenance,
    icon: Icons.build_rounded,
    emoji: '🛠️',
    label: 'Maintenance',
    color: Color(0xFFFF9F1C),
    flowTitle: 'Add Maintenance',
    flowSummary:
        'Record service, inspection, repair, interval reset, cost, odometer, and attachments.',
    requiresOdometer: true,
  ),
  WorkdayQuickActionSpec(
    kind: WorkdayQuickActionKind.materials,
    icon: Icons.inventory_2_rounded,
    emoji: '📦',
    label: 'Materials',
    color: Color(0xFF8F6CEB),
    flowTitle: 'Add Materials',
    flowSummary:
        'Record materials used, quantities, cost, job link, and invoice link.',
  ),
  WorkdayQuickActionSpec(
    kind: WorkdayQuickActionKind.receipt,
    icon: Icons.camera_alt_rounded,
    emoji: '📷',
    label: 'Receipt',
    color: Color(0xFFFFD166),
    flowTitle: 'Attach Receipt',
    flowSummary:
        'Capture or import receipt images or PDFs and link them to a record.',
  ),
  WorkdayQuickActionSpec(
    kind: WorkdayQuickActionKind.reminder,
    icon: Icons.event_available_rounded,
    emoji: '📅',
    label: 'Reminder',
    color: Color(0xFF4FE8FF),
    flowTitle: 'Add Reminder',
    flowSummary:
        'Create a dated reminder or scheduled item for a future workday.',
  ),
  WorkdayQuickActionSpec(
    kind: WorkdayQuickActionKind.estimate,
    icon: Icons.request_quote_rounded,
    emoji: '📋',
    label: 'Estimate',
    color: Color(0xFF78909C),
    flowTitle: 'Create Estimate',
    flowSummary:
        'Create a job estimate that can later become an invoice or scheduled work.',
  ),
  WorkdayQuickActionSpec(
    kind: WorkdayQuickActionKind.note,
    icon: Icons.note_alt_rounded,
    emoji: '📝',
    label: 'Note',
    color: Color(0xFFB9C3C7),
    flowTitle: 'Add Note',
    flowSummary:
        'Add a dated note and optionally link it to a day, trip, customer, or record.',
  ),
];

const defaultWorkdayQuickActionKinds = [
  WorkdayQuickActionKind.pauseDay,
  WorkdayQuickActionKind.endDay,
  WorkdayQuickActionKind.addFuel,
  WorkdayQuickActionKind.addStop,
  WorkdayQuickActionKind.addPickup,
  WorkdayQuickActionKind.addDropOff,
  WorkdayQuickActionKind.expense,
  WorkdayQuickActionKind.payment,
  WorkdayQuickActionKind.invoice,
];

class WorkdayQuickActionLayout {
  const WorkdayQuickActionLayout({required this.activeKinds});

  factory WorkdayQuickActionLayout.defaults() => const WorkdayQuickActionLayout(
    activeKinds: defaultWorkdayQuickActionKinds,
  );

  factory WorkdayQuickActionLayout.fromMap(Map<dynamic, dynamic> map) {
    final rawKinds = map['activeKinds'];
    if (rawKinds is! Iterable) return WorkdayQuickActionLayout.defaults();
    return WorkdayQuickActionLayout(
      activeKinds: _sanitizeActionKinds(
        rawKinds.map((value) => value?.toString() ?? ''),
      ),
    );
  }

  final List<WorkdayQuickActionKind> activeKinds;

  List<WorkdayQuickActionSpec> get activeActions => [
    for (final kind in activeKinds)
      if (_actionByKind[kind] != null) _actionByKind[kind]!,
  ];

  Map<String, Object?> toMap() => {
    'activeKinds': activeKinds.map((kind) => kind.name).toList(),
  };
}

List<WorkdayQuickActionKind> _sanitizeActionKinds(Iterable<String> rawKinds) {
  final selected = <WorkdayQuickActionKind>[];
  for (final rawKind in rawKinds.take(availableWorkdayQuickActions.length)) {
    final kind = _actionKindFromName(rawKind);
    if (kind == null || selected.contains(kind)) continue;
    selected.add(kind);
  }
  return selected.isEmpty
      ? List.unmodifiable(defaultWorkdayQuickActionKinds)
      : List.unmodifiable(selected);
}

WorkdayQuickActionKind? _actionKindFromName(String rawKind) {
  final clean = rawKind.trim();
  for (final kind in WorkdayQuickActionKind.values) {
    if (kind.name == clean) return kind;
  }
  return null;
}

final Map<WorkdayQuickActionKind, WorkdayQuickActionSpec> _actionByKind = {
  for (final action in availableWorkdayQuickActions) action.kind: action,
};
