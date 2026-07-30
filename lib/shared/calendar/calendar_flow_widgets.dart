import 'package:flutter/material.dart';

import 'calendar_flow_models.dart';

class CalendarModeHeader extends StatelessWidget {
  const CalendarModeHeader({
    super.key,
    required this.day,
    required this.profile,
  });

  final DateTime day;
  final CalendarModeProfile profile;

  @override
  Widget build(BuildContext context) {
    return CalendarStatusPanel(
      icon: profile.fabIcon,
      title: profile.title,
      subtitle: profile.subtitle,
    );
  }
}

class CalendarTimelineItem extends StatelessWidget {
  const CalendarTimelineItem({
    super.key,
    required this.entry,
    required this.onTap,
  });

  final CalendarTimelineEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final meta = calendarEntryMeta(entry.type);

    return Semantics(
      button: true,
      label: calendarTimelineAccessibilityLabel(entry),
      hint: 'Open ${entry.source} details',
      onTap: onTap,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Material(
          color: const Color(0xFF2A3135),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
            side: BorderSide(color: _statusBorderColor(entry.status)),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(5),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 42,
                    child: Text(
                      entry.timeLabel ?? calendarTimeLabel(entry.timestamp),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFE2E8EA),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(meta.icon, color: meta.color, size: 21),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.title,
                          softWrap: true,
                          style: const TextStyle(
                            color: Color(0xFFE2E8EA),
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            height: 1.05,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          entry.summary,
                          softWrap: true,
                          style: const TextStyle(
                            color: Color(0xFFB7C4CA),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            height: 1.05,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _statusIcon(entry.status),
                    color: _statusColor(entry.status),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Color _statusBorderColor(CalendarEntryStatus status) {
    return switch (status) {
      CalendarEntryStatus.planned => const Color(0xFF4FE8FF),
      CalendarEntryStatus.completed => const Color(0xFF20F060),
      CalendarEntryStatus.needsAttention => const Color(0xFFFFD166),
    };
  }

  static Color _statusColor(CalendarEntryStatus status) {
    return switch (status) {
      CalendarEntryStatus.planned => const Color(0xFF4FE8FF),
      CalendarEntryStatus.completed => const Color(0xFF20F060),
      CalendarEntryStatus.needsAttention => const Color(0xFFFFD166),
    };
  }

  static IconData _statusIcon(CalendarEntryStatus status) {
    return switch (status) {
      CalendarEntryStatus.planned => Icons.event_available_rounded,
      CalendarEntryStatus.completed => Icons.check_circle_rounded,
      CalendarEntryStatus.needsAttention => Icons.warning_amber_rounded,
    };
  }
}

String calendarTimelineAccessibilityLabel(CalendarTimelineEntry entry) {
  final time = entry.timeLabel ?? calendarTimeLabel(entry.timestamp);
  return '$time. ${entry.title}. ${entry.summary}. '
      'Status: ${_calendarEntryStatusLabel(entry.status)}.';
}

String _calendarEntryStatusLabel(CalendarEntryStatus status) =>
    switch (status) {
      CalendarEntryStatus.planned => 'Planned',
      CalendarEntryStatus.completed => 'Confirmed',
      CalendarEntryStatus.needsAttention => 'Needs review',
    };

class CalendarEntryDetailPanel extends StatelessWidget {
  const CalendarEntryDetailPanel({
    super.key,
    required this.entry,
    required this.onEdit,
  });

  final CalendarTimelineEntry entry;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final meta = calendarEntryMeta(entry.type);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A3135),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF59636A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(meta.icon, color: meta.color, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.title,
                  style: const TextStyle(
                    color: Color(0xFFE2E8EA),
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                entry.timeLabel ?? calendarTimeLabel(entry.timestamp),
                style: const TextStyle(
                  color: Color(0xFF4FE8FF),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${meta.label} from ${entry.source}',
            style: const TextStyle(
              color: Color(0xFFB7C4CA),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          for (final detail in entry.details)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(
                detail,
                style: const TextStyle(
                  color: Color(0xFFE2E8EA),
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded),
            label: const Text('Edit / Correct This Entry'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFE2E8EA),
              side: const BorderSide(color: Color(0xFF59636A)),
              minimumSize: const Size.fromHeight(46),
            ),
          ),
        ],
      ),
    );
  }
}

String calendarTimeLabel(DateTime time) {
  final hour = time.hour == 0
      ? 12
      : time.hour > 12
      ? time.hour - 12
      : time.hour;
  final minute = time.minute.toString().padLeft(2, '0');
  final suffix = time.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}

String calendarDateTimeLabel(DateTime time) =>
    '${time.month}/${time.day}/${time.year} ${calendarTimeLabel(time)}';

class CalendarRecapStrip extends StatelessWidget {
  const CalendarRecapStrip({super.key, required this.items});

  final List<CalendarRecapItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 7.0;
        final itemWidth = (constraints.maxWidth - spacing) / 2;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in items)
              SizedBox(
                width: itemWidth,
                child: _CalendarRecapReadout(item: item),
              ),
          ],
        );
      },
    );
  }
}

/// Calendar ownership: a shared, obvious route to the read-only full recap.
class CalendarRecapActionButton extends StatelessWidget {
  const CalendarRecapActionButton({
    super.key,
    required this.onPressed,
    this.label = 'Open full recap',
  });

  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.insights_rounded),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF65B8FF),
          foregroundColor: const Color(0xFF071116),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    ),
  );
}

class CalendarStatusPanel extends StatelessWidget {
  const CalendarStatusPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A3135),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF59636A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF20F060), size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFE2E8EA),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFFB7C4CA),
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CalendarSectionTitle extends StatelessWidget {
  const CalendarSectionTitle(this.label, {super.key})
    : actionLabel = null,
      onPressed = null;

  const CalendarSectionTitle.withAction({
    super.key,
    required this.label,
    required this.actionLabel,
    required this.onPressed,
  });

  final String label;
  final String? actionLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final actionLabel = this.actionLabel;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFFE2E8EA),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (actionLabel != null && onPressed != null)
          TextButton(onPressed: onPressed, child: Text(actionLabel)),
      ],
    );
  }
}

class CalendarDraftField extends StatelessWidget {
  const CalendarDraftField({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFAAB4B9),
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _CalendarRecapReadout extends StatelessWidget {
  const _CalendarRecapReadout({required this.item});

  final CalendarRecapItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF101416),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF59636A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.label,
            style: const TextStyle(
              color: Color(0xFFB7C4CA),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.value,
            style: const TextStyle(
              color: Color(0xFF20F060),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
