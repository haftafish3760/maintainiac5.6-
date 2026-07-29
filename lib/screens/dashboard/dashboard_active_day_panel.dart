import 'package:flutter/material.dart';

import 'data/active_workday_store.dart';

class DashboardActiveDayPanel extends StatelessWidget {
  const DashboardActiveDayPanel({super.key, required this.session});

  final ActiveWorkdaySessionRecord session;

  @override
  Widget build(BuildContext context) {
    final entries = session.events
        .where((event) => event.type != ActiveWorkdayEventType.started)
        .toList(growable: false);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
        decoration: BoxDecoration(
          color: const Color(0xFF142126),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF52656D)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.route_rounded,
                  color: Color(0xFF7CC7FF),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Today: ${session.currentContextSegment.vehicleLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFE8ECEE),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  '${entries.length}',
                  style: const TextStyle(
                    color: Color(0xFF50F77A),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (entries.isEmpty)
              const _DashboardDayEntryRow(
                icon: Icons.play_arrow_rounded,
                time: 'Now',
                text: 'Day started. Stops and expenses will show here.',
              )
            else
              for (final event in entries.reversed.take(4))
                _DashboardDayEntryRow(
                  icon: _iconForEvent(event.type),
                  time: event.timeLabel,
                  text: event.displayText,
                ),
          ],
        ),
      ),
    );
  }
}

class _DashboardDayEntryRow extends StatelessWidget {
  const _DashboardDayEntryRow({
    required this.icon,
    required this.time,
    required this.text,
  });

  final IconData icon;
  final String time;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 42),
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF101719),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF3E4A50)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFFD166), size: 18),
          const SizedBox(width: 7),
          SizedBox(
            width: 56,
            child: Text(
              time,
              style: const TextStyle(
                color: Color(0xFF50F77A),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFE2E8EA),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

IconData _iconForEvent(ActiveWorkdayEventType type) {
  return switch (type) {
    ActiveWorkdayEventType.fuel => Icons.local_gas_station_rounded,
    ActiveWorkdayEventType.expense => Icons.receipt_long_rounded,
    ActiveWorkdayEventType.stop => Icons.place_rounded,
    ActiveWorkdayEventType.pickup => Icons.archive_rounded,
    ActiveWorkdayEventType.dropOff => Icons.outbox_rounded,
    ActiveWorkdayEventType.paused => Icons.pause_rounded,
    ActiveWorkdayEventType.resumed => Icons.play_arrow_rounded,
    ActiveWorkdayEventType.ended => Icons.stop_rounded,
    ActiveWorkdayEventType.note => Icons.note_alt_rounded,
    ActiveWorkdayEventType.started => Icons.flag_rounded,
    ActiveWorkdayEventType.contextChanged => Icons.swap_horiz_rounded,
  };
}
