import 'package:flutter/material.dart';

import '../../shared/navigation/app_page_routes.dart';
import '../../shared/theme/app_action_colors.dart';
import '../../shared/widgets/app_back_button.dart';
import 'calendar_flow_models.dart';
import 'calendar_flow_widgets.dart';

class CalendarEntryTypeSelectorScreen extends StatelessWidget {
  const CalendarEntryTypeSelectorScreen({
    super.key,
    required this.day,
    required this.mode,
    this.source = CalendarFlowSource.dashboard,
  });

  final DateTime day;
  final CalendarDayMode mode;
  final CalendarFlowSource source;

  @override
  Widget build(BuildContext context) {
    final types = calendarTypesForSource(mode, source);

    return Scaffold(
      backgroundColor: const Color(0xFF1F2528),

      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            AppScreenHeader(title: calendarSelectorTitleFor(mode, source)),
            const SizedBox(height: 12),
            CalendarStatusPanel(
              icon: Icons.calendar_month_rounded,
              title: calendarDateTitle(day),
              subtitle: source == CalendarFlowSource.expenses
                  ? 'Add receipts, payments, reminders, and expense corrections for this date.'
                  : 'Anything added here stays attached to this selected date.',
            ),
            const SizedBox(height: 12),
            CalendarEntryTypeGrid(
              day: day,
              mode: mode,
              source: source,
              types: types,
            ),
          ],
        ),
      ),
    );
  }
}

class CalendarEntryDraftScreen extends StatelessWidget {
  const CalendarEntryDraftScreen({
    super.key,
    required this.day,
    required this.mode,
    required this.type,
    this.source = CalendarFlowSource.dashboard,
  });

  final DateTime day;
  final CalendarDayMode mode;
  final CalendarEntryType type;
  final CalendarFlowSource source;

  @override
  Widget build(BuildContext context) {
    final meta = calendarEntryMeta(type);

    return Scaffold(
      backgroundColor: const Color(0xFF1F2528),

      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            AppScreenHeader(title: meta.label),
            const SizedBox(height: 12),
            CalendarStatusPanel(
              icon: meta.icon,
              title: '${meta.label} for ${calendarDateTitle(day)}',
              subtitle: source == CalendarFlowSource.expenses
                  ? 'Expense calendar entry: keep this date, category, receipt, and reminder history together.'
                  : calendarDraftSubtitle(mode),
            ),
            const SizedBox(height: 14),
            CalendarSectionTitle(_draftSectionTitle(mode)),
            const SizedBox(height: 8),
            for (final field in _draftFieldsFor(mode, type)) ...[
              CalendarDraftField(label: field),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.check_rounded),
              label: const Text('Save'),
              style: FilledButton.styleFrom(
                backgroundColor: AppActionColors.positive,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _draftSectionTitle(CalendarDayMode mode) {
    return switch (mode) {
      CalendarDayMode.past => 'ADD OR CORRECT PAST RECORD',
      CalendarDayMode.today => 'ADD TO TODAY',
      CalendarDayMode.future => 'PLAN FUTURE WORK',
    };
  }

  static List<String> _draftFieldsFor(
    CalendarDayMode mode,
    CalendarEntryType type,
  ) {
    if (mode == CalendarDayMode.future) {
      return const [
        'What is planned?',
        'Customer name',
        'Address',
        'Phone number',
        'Vehicle or helper assignment',
        'Linked invoice / estimate / materials',
        'Notes',
      ];
    }

    return switch (type) {
      CalendarEntryType.tripEntry => const [
        'Trip description',
        'Start / end odometer',
        'Miles',
        'Linked customer, invoice, or note',
      ],
      CalendarEntryType.stop ||
      CalendarEntryType.pickup ||
      CalendarEntryType.delivery => const [
        'Location name',
        'Address',
        'Arrival / completion time',
        'Linked trip, invoice, or customer',
      ],
      CalendarEntryType.expense => const [
        'Expense category',
        'Amount',
        'Vendor',
        'Receipt photos, PDF, or no attachment',
        'Preview and compression choice',
      ],
      CalendarEntryType.payment => const [
        'Payment amount',
        'Payment source',
        'Linked invoice / estimate',
        'Notes',
      ],
      CalendarEntryType.invoiceEstimate => const [
        'Customer name',
        'Invoice or estimate number',
        'Amount',
        'Linked work or materials',
      ],
      CalendarEntryType.maintenance => const [
        'Maintenance item',
        'Odometer',
        'Cost',
        'Receipt photos, PDF, or no attachment',
        'Notes',
      ],
      CalendarEntryType.materials => const [
        'Material name',
        'Quantity',
        'Cost',
        'Linked invoice / job',
      ],
      CalendarEntryType.receiptPhoto => const [
        'Receipt source',
        'Amount',
        'Take photo / choose image / upload PDF',
        'Attach multiple images if needed',
        'Preview and compression choice',
        'Link to expense or maintenance',
      ],
      CalendarEntryType.note || CalendarEntryType.reminderSchedule => const [
        'Title',
        'Details',
        'Linked item',
      ],
    };
  }
}

class CalendarEntryDetailScreen extends StatelessWidget {
  const CalendarEntryDetailScreen({
    super.key,
    required this.day,
    required this.mode,
    required this.entry,
    this.source = CalendarFlowSource.dashboard,
  });

  final DateTime day;
  final CalendarDayMode mode;
  final CalendarTimelineEntry entry;
  final CalendarFlowSource source;

  @override
  Widget build(BuildContext context) {
    final meta = calendarEntryMeta(entry.type);

    return Scaffold(
      backgroundColor: const Color(0xFF1F2528),

      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            AppScreenHeader(title: meta.label),
            const SizedBox(height: 12),
            CalendarEntryDetailPanel(
              entry: entry,
              onEdit: () {
                Navigator.of(context).push(
                  appNativeRoute<void>(
                    context,
                    CalendarEntryDraftScreen(
                      day: day,
                      mode: mode,
                      type: entry.type,
                      source: source,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            const CalendarSectionTitle('ACTIONS FOR THIS ENTRY'),
            const SizedBox(height: 8),
            _DetailActionButton(
              icon: Icons.edit_rounded,
              label: 'Edit / Correct',
              onPressed: () {
                Navigator.of(context).push(
                  appNativeRoute<void>(
                    context,
                    CalendarEntryDraftScreen(
                      day: day,
                      mode: mode,
                      type: entry.type,
                      source: source,
                    ),
                  ),
                );
              },
            ),
            _DetailActionButton(
              icon: Icons.add_link_rounded,
              label: 'Attach related entry',
              onPressed: () {
                Navigator.of(context).push(
                  appNativeRoute<void>(
                    context,
                    CalendarEntryTypeSelectorScreen(
                      day: day,
                      mode: mode,
                      source: source,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailActionButton extends StatelessWidget {
  const _DetailActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFE2E8EA),
          side: const BorderSide(color: Color(0xFF59636A)),
          minimumSize: const Size.fromHeight(48),
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }
}

class CalendarEntryTypeGrid extends StatelessWidget {
  const CalendarEntryTypeGrid({
    super.key,
    required this.day,
    required this.mode,
    required this.source,
    required this.types,
  });

  final DateTime day;
  final CalendarDayMode mode;
  final CalendarFlowSource source;
  final List<CalendarEntryType> types;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 560 ? 3 : 2;
        const spacing = 8.0;
        final itemWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final type in types)
              SizedBox(
                width: itemWidth,
                height: 82,
                child: _CalendarEntryTypeButton(
                  day: day,
                  mode: mode,
                  source: source,
                  type: type,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CalendarEntryTypeButton extends StatelessWidget {
  const _CalendarEntryTypeButton({
    required this.day,
    required this.mode,
    required this.source,
    required this.type,
  });

  final DateTime day;
  final CalendarDayMode mode;
  final CalendarFlowSource source;
  final CalendarEntryType type;

  @override
  Widget build(BuildContext context) {
    final meta = calendarEntryMeta(type);

    return Material(
      color: const Color(0xFF2A3135),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
        side: const BorderSide(color: Color(0xFF59636A)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            appNativeRoute<void>(
              context,
              CalendarEntryDraftScreen(
                day: day,
                mode: mode,
                source: source,
                type: type,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(5),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(meta.icon, color: meta.color, size: 24),
              const SizedBox(height: 6),
              Text(
                meta.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFE2E8EA),
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
