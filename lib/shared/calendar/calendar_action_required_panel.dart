// Calendar ownership: concise shortcuts to source-owned review records.
// The chronological timeline remains the complete, non-duplicated record view.

import 'package:flutter/material.dart';

import 'calendar_flow_models.dart';

List<CalendarTimelineEntry> calendarActionRequiredEntries(
  Iterable<CalendarTimelineEntry> entries,
) =>
    entries
        .where(
          (entry) =>
              entry.projection?.isActionable ??
              entry.status == CalendarEntryStatus.needsAttention,
        )
        .toList(growable: false)
      ..sort((left, right) => left.timestamp.compareTo(right.timestamp));

class CalendarActionRequiredPanel extends StatelessWidget {
  const CalendarActionRequiredPanel({
    super.key,
    required this.entries,
    required this.onOpen,
  });

  final List<CalendarTimelineEntry> entries;
  final ValueChanged<CalendarTimelineEntry> onOpen;

  @override
  Widget build(BuildContext context) {
    final actionable = calendarActionRequiredEntries(entries);
    if (actionable.isEmpty) return const SizedBox.shrink();
    final visible = actionable.take(3).toList(growable: false);
    final remaining = actionable.length - visible.length;

    return Semantics(
      container: true,
      label: '${actionable.length} Calendar entries require review',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF302916),
          border: Border.all(color: const Color(0xFFFFD166)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFFFD166),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    actionable.length == 1
                        ? '1 item needs review'
                        : '${actionable.length} items need review',
                    style: const TextStyle(
                      color: Color(0xFFFFF1C7),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Review stays in the record’s owning screen.',
              style: TextStyle(
                color: Color(0xFFE7D9AE),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            for (final entry in visible)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: OutlinedButton.icon(
                  onPressed: () => onOpen(entry),
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(entry.title, softWrap: true),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(42),
                    foregroundColor: const Color(0xFFFFF1C7),
                    side: const BorderSide(color: Color(0xFFD9B657)),
                    alignment: Alignment.centerLeft,
                  ),
                ),
              ),
            if (remaining > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '$remaining more item${remaining == 1 ? '' : 's'} remain in the chronological timeline.',
                  style: const TextStyle(
                    color: Color(0xFFE7D9AE),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
