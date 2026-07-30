part of 'work_supply_home_screen.dart';

class _InventoryCalendarHomePanel extends StatelessWidget {
  const _InventoryCalendarHomePanel({
    required this.records,
    required this.selectedDay,
    required this.onDaySelected,
  });

  final List<WorkSupplyInventoryRecord> records;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) {
    final dayRecords = _recordsForDay(records, selectedDay);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF172126),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF53656D)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Inventory Activity',
                    style: TextStyle(
                      color: Color(0xFFE8ECEE),
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Tap a date to see that day’s inventory entries right here.',
              style: TextStyle(
                color: Color(0xFFC7D0D4),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            WorkSupplyCalendarPanel(
              markersByDay: _homeInventoryMarkers(records),
              onDaySelected: (day) => onDaySelected(_dayKey(day)),
              calendarSource: CalendarFlowSource.materials,
            ),
            const SizedBox(height: 10),
            _CalendarDayEntries(day: selectedDay, records: dayRecords),
          ],
        ),
      ),
    );
  }
}

class _CalendarDayEntries extends StatelessWidget {
  const _CalendarDayEntries({required this.day, required this.records});

  final DateTime day;
  final List<WorkSupplyInventoryRecord> records;

  @override
  Widget build(BuildContext context) {
    final recap = buildWorkSupplyDayRecap(records: records, day: day);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF10181C),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFF405159)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _dateLabel(day),
              style: const TextStyle(
                color: Color(0xFFE8ECEE),
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            _CalendarDaySpendRow(recap: recap),
            const SizedBox(height: 8),
            if (records.isEmpty)
              const Text(
                'No inventory entries for this date.',
                style: TextStyle(
                  color: Color(0xFFC7D0D4),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              )
            else
              for (final record in records) _CalendarEntryRow(record: record),
          ],
        ),
      ),
    );
  }
}

class _CalendarDaySpendRow extends StatelessWidget {
  const _CalendarDaySpendRow({required this.recap});

  final WorkSupplyInventoryRecap recap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SmallRecapPill(
            label: 'Spent',
            value: _money(recap.totalSpent),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _SmallRecapPill(label: 'Entries', value: '${recap.itemCount}'),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _SmallRecapPill(
            label: 'Receipts',
            value: '${recap.receiptCount}',
          ),
        ),
      ],
    );
  }
}

class _SmallRecapPill extends StatelessWidget {
  const _SmallRecapPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF172126),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFF405159)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8FD3FF),
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFE8ECEE),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarEntryRow extends StatelessWidget {
  const _CalendarEntryRow({required this.record});

  final WorkSupplyInventoryRecord record;

  @override
  Widget build(BuildContext context) {
    final source = record.receiptLinked
        ? _receiptSourceLabel(record)
        : 'Manual entry';
    final quantity = _formatNumber(record.onHand);
    final unitCost = record.lastUnitCost <= 0
        ? 'cost unknown'
        : '\$${record.lastUnitCost.toStringAsFixed(2)} each';
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            record.receiptLinked
                ? Icons.receipt_long_rounded
                : Icons.edit_note_rounded,
            color: record.receiptLinked
                ? const Color(0xFF8FD3FF)
                : const Color(0xFFFFCF5A),
            size: 19,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFE8ECEE),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '$source | $quantity on hand | $unitCost',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFC7D0D4),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
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

Map<DateTime, List<WorkSupplyCalendarMarker>> _homeInventoryMarkers(
  List<WorkSupplyInventoryRecord> records,
) {
  final counts = <DateTime, int>{};
  for (final record in records) {
    final loggedAt = record.loggedAt;
    if (loggedAt == null) continue;
    final key = DateTime.utc(loggedAt.year, loggedAt.month, loggedAt.day);
    counts[key] = (counts[key] ?? 0) + 1;
  }
  return {
    for (final entry in counts.entries)
      entry.key: [
        WorkSupplyCalendarMarker(
          label: 'I',
          color: const Color(0xFF64C98A),
          count: entry.value,
        ),
      ],
  };
}

List<WorkSupplyInventoryRecord> _recordsForDay(
  List<WorkSupplyInventoryRecord> records,
  DateTime day,
) {
  final selected = _dayKey(day);
  return records.where((record) {
    final loggedAt = record.loggedAt;
    if (loggedAt == null) return false;
    return _dayKey(loggedAt) == selected;
  }).toList();
}

DateTime _dayKey(DateTime day) => DateTime.utc(day.year, day.month, day.day);

String _dateLabel(DateTime day) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[day.month - 1]} ${day.day}, ${day.year}';
}

String _receiptSourceLabel(WorkSupplyInventoryRecord record) {
  final merchant = record.sourceMerchantName.trim();
  if (merchant.isEmpty) return 'Receipt entry';
  return '$merchant receipt';
}

String _money(double value) => '\$${value.toStringAsFixed(2)}';

String _formatNumber(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(2);
}
