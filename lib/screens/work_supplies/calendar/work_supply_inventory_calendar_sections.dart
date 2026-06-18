part of 'work_supply_inventory_calendar_screen.dart';

class _CalendarTitle extends StatelessWidget {
  const _CalendarTitle();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Inventory Calendar',
          style: TextStyle(
            color: Color(0xFFE8ECEE),
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Shows what happened in inventory on each day: receipt entries, manual adds, restocks, count changes, transfers, and job usage.',
          style: TextStyle(
            color: Color(0xFFC7D0D4),
            fontSize: 13,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

class _InventoryDayPanel extends StatelessWidget {
  const _InventoryDayPanel({
    required this.day,
    required this.records,
    required this.events,
  });

  final DateTime day;
  final List<WorkSupplyInventoryRecord> records;
  final List<WorkSupplyInventoryActivity> events;

  @override
  Widget build(BuildContext context) {
    final receiptCount = events.where((event) => event.hasReceipt).length;
    final dayRecap = buildWorkSupplyDayRecap(records: records, day: day);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF162229),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF53656D)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _dateLabel(day),
              style: const TextStyle(
                color: Color(0xFFE8ECEE),
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            if (events.isEmpty)
              const Text(
                'No inventory activity logged for this date.',
                style: TextStyle(
                  color: Color(0xFFC7D0D4),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              )
            else ...[
              _DaySummaryStrip(
                eventCount: events.length,
                receiptCount: receiptCount,
                totalSpent: dayRecap.totalSpent,
              ),
              const SizedBox(height: 9),
              for (final event in events) _InventoryCalendarRow(event: event),
            ],
          ],
        ),
      ),
    );
  }
}

class _InventoryMonthRecapPanel extends StatelessWidget {
  const _InventoryMonthRecapPanel({required this.recap});

  final WorkSupplyInventoryRecap recap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF14201A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3F7052)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Month Recap',
              style: TextStyle(
                color: Color(0xFFE8ECEE),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Expanded(
                  child: _SummaryPill(
                    label: 'Spent',
                    value: _money(recap.totalSpent),
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: _SummaryPill(
                    label: 'Lines',
                    value: '${recap.itemCount}',
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: _SummaryPill(
                    label: 'Receipts',
                    value: '${recap.receiptCount}',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DaySummaryStrip extends StatelessWidget {
  const _DaySummaryStrip({
    required this.eventCount,
    required this.receiptCount,
    required this.totalSpent,
  });

  final int eventCount;
  final int receiptCount;
  final double totalSpent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryPill(label: 'Spent', value: _money(totalSpent)),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _SummaryPill(
            label: 'Entries',
            value: '$eventCount ${eventCount == 1 ? 'entry' : 'entries'}',
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _SummaryPill(label: 'Receipts', value: '$receiptCount linked'),
        ),
      ],
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1519),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFF3F5058)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF8FD3FF),
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
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

class _InventoryCalendarRow extends StatelessWidget {
  const _InventoryCalendarRow({required this.event});

  final WorkSupplyInventoryActivity event;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1519),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFF3F5058)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: event.hasReceipt
                  ? const Color(0xFF153D29)
                  : const Color(0xFF273943),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: event.hasReceipt
                    ? const Color(0xFF58D67D)
                    : const Color(0xFF8FD3FF),
              ),
            ),
            child: Icon(
              event.hasReceipt
                  ? Icons.receipt_long_rounded
                  : Icons.edit_note_rounded,
              color: event.hasReceipt
                  ? const Color(0xFF58D67D)
                  : const Color(0xFF8FD3FF),
              size: 19,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFE8ECEE),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  event.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFC7D0D4),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 6,
                  runSpacing: 5,
                  children: [
                    _EventChip(event.typeLabel),
                    _EventChip(event.quantityLabel),
                    _EventChip(event.storageArea),
                    if (event.costLabel.isNotEmpty) _EventChip(event.costLabel),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EventChip extends StatelessWidget {
  const _EventChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF172126),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: const Color(0xFF4A5B63)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFC7D0D4),
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class WorkSupplyInventoryActivity {
  const WorkSupplyInventoryActivity({
    required this.title,
    required this.subtitle,
    required this.typeLabel,
    required this.quantity,
    required this.quantityLabel,
    required this.storageArea,
    required this.costLabel,
    required this.hasReceipt,
  });

  final String title;
  final String subtitle;
  final String typeLabel;
  final double quantity;
  final String quantityLabel;
  final String storageArea;
  final String costLabel;
  final bool hasReceipt;

  factory WorkSupplyInventoryActivity.fromRecord(
    WorkSupplyInventoryRecord record,
  ) {
    final receipt = record.receiptLinked;
    final quantity = record.onHand;
    final purchaseType = record.purchaseType.trim().isEmpty
        ? 'each'
        : record.purchaseType;
    final packageCount = _formatNumber(record.packagesPurchased);
    final unitsPerPackage = _formatNumber(record.unitsPerPackage);
    final quantityLabel = purchaseType == 'each'
        ? '${_formatNumber(quantity)} ${record.item.unit}'
        : '$packageCount $purchaseType x $unitsPerPackage';
    final costLabel = record.lineTotal > 0
        ? '\$${record.lineTotal.toStringAsFixed(2)} total'
        : '';
    final merchant = record.sourceMerchantName.trim();
    return WorkSupplyInventoryActivity(
      title: receipt && merchant.isNotEmpty
          ? '$merchant receipt'
          : record.item.name,
      subtitle: receipt && merchant.isNotEmpty
          ? '${record.item.name} | ${record.item.trade} / ${record.item.category}'
          : '${record.item.trade} / ${record.item.category} / ${record.item.system}',
      typeLabel: receipt ? 'Receipt entry' : 'Manual entry',
      quantity: quantity,
      quantityLabel: quantityLabel,
      storageArea: record.storageArea,
      costLabel: costLabel,
      hasReceipt: receipt,
    );
  }

  static String _formatNumber(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }
}

String _money(double value) => '\$${value.toStringAsFixed(2)}';

Map<DateTime, List<WorkSupplyCalendarMarker>> _inventoryMarkers(
  List<WorkSupplyInventoryRecord> records,
) {
  final counts = <DateTime, int>{};
  for (final record in records) {
    final loggedAt = record.loggedAt;
    if (loggedAt == null) continue;
    final key = _dayKey(loggedAt);
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
