import 'package:flutter/material.dart';

import '../navigation/app_page_routes.dart';
import '../widgets/app_back_button.dart';
import 'calendar_flow_models.dart';
import 'calendar_flow_widgets.dart';
import 'calendar_owner_entry_router.dart';

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
              onSelected: (type) => CalendarOwnerEntryRouter.open(
                context: context,
                day: day,
                type: type,
              ),
            ),
          ],
        ),
      ),
    );
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
              onEdit: () => CalendarOwnerEntryRouter.open(
                context: context,
                day: day,
                type: entry.type,
              ),
            ),
            const SizedBox(height: 14),
            const CalendarSectionTitle('ACTIONS FOR THIS ENTRY'),
            const SizedBox(height: 8),
            _DetailActionButton(
              icon: Icons.edit_rounded,
              label: 'Edit / Correct',
              onPressed: () => CalendarOwnerEntryRouter.open(
                context: context,
                day: day,
                type: entry.type,
              ),
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
    required this.onSelected,
  });

  final DateTime day;
  final CalendarDayMode mode;
  final CalendarFlowSource source;
  final List<CalendarEntryType> types;
  final ValueChanged<CalendarEntryType> onSelected;

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
                  onSelected: onSelected,
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
    required this.onSelected,
  });

  final DateTime day;
  final CalendarDayMode mode;
  final CalendarFlowSource source;
  final CalendarEntryType type;
  final ValueChanged<CalendarEntryType> onSelected;

  @override
  Widget build(BuildContext context) {
    final meta = calendarEntryMeta(type);

    return Semantics(
      button: true,
      label: 'Add ${meta.label} for ${calendarDateTitle(day)}',
      hint: 'Opens the ${meta.label} owner flow',
      onTap: () => onSelected(type),
      excludeSemantics: true,
      child: Material(
        color: const Color(0xFF2A3135),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
          side: const BorderSide(color: Color(0xFF59636A)),
        ),
        child: InkWell(
          onTap: () => onSelected(type),
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
      ),
    );
  }
}
