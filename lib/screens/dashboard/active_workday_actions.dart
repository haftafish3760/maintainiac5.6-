import 'package:flutter/material.dart';

import '../../shared/theme/app_action_colors.dart';

class WorkdayQuickActionSpec {
  const WorkdayQuickActionSpec({
    required this.icon,
    required this.emoji,
    required this.label,
    required this.color,
    required this.flowTitle,
    required this.flowSummary,
    this.requiresOdometer = false,
  });

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
    icon: Icons.receipt_long_rounded,
    emoji: '🧾',
    label: 'Expense',
    color: Color(0xFFFF6F3D),
    flowTitle: 'Add Expense',
    flowSummary:
        'Record an expense, category, amount, vendor, vehicle, and receipt attachments.',
  ),
  WorkdayQuickActionSpec(
    icon: Icons.payments_rounded,
    emoji: '💵',
    label: 'Payment',
    color: AppActionColors.positive,
    flowTitle: 'Record Payment',
    flowSummary:
        'Record a payment received and connect it to an invoice, estimate, customer, or workday.',
  ),
  WorkdayQuickActionSpec(
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
    icon: Icons.inventory_2_rounded,
    emoji: '📦',
    label: 'Materials',
    color: Color(0xFF8F6CEB),
    flowTitle: 'Add Materials',
    flowSummary:
        'Record materials used, quantities, cost, job link, and invoice link.',
  ),
  WorkdayQuickActionSpec(
    icon: Icons.camera_alt_rounded,
    emoji: '📷',
    label: 'Receipt',
    color: Color(0xFFFFD166),
    flowTitle: 'Attach Receipt',
    flowSummary:
        'Capture or import receipt images or PDFs and link them to a record.',
  ),
  WorkdayQuickActionSpec(
    icon: Icons.event_available_rounded,
    emoji: '📅',
    label: 'Reminder',
    color: Color(0xFF4FE8FF),
    flowTitle: 'Add Reminder',
    flowSummary:
        'Create a dated reminder or scheduled item for a future workday.',
  ),
  WorkdayQuickActionSpec(
    icon: Icons.request_quote_rounded,
    emoji: '📋',
    label: 'Estimate',
    color: Color(0xFF78909C),
    flowTitle: 'Create Estimate',
    flowSummary:
        'Create a job estimate that can later become an invoice or scheduled work.',
  ),
  WorkdayQuickActionSpec(
    icon: Icons.note_alt_rounded,
    emoji: '📝',
    label: 'Note',
    color: Color(0xFFB9C3C7),
    flowTitle: 'Add Note',
    flowSummary:
        'Add a dated note and optionally link it to a day, trip, customer, or record.',
  ),
];
