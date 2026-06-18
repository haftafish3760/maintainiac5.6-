part of 'work_supply_inventory_screen.dart';

class _CompactInventoryGrid extends StatelessWidget {
  const _CompactInventoryGrid({
    required this.records,
    required this.activeRecords,
    required this.selected,
    required this.emptyMessage,
    required this.onSelected,
  });

  final List<WorkSupplyInventoryRecord> records;
  final List<WorkSupplyInventoryRecord> activeRecords;
  final WorkSupplyInventoryRecord? selected;
  final String emptyMessage;
  final ValueChanged<WorkSupplyInventoryRecord> onSelected;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) return _EmptyInventory(message: emptyMessage);
    final sorted = _uniqueInventoryRecords(records)
      ..sort((a, b) {
        final type = a.item.itemType.compareTo(b.item.itemType);
        if (type != 0) return type;
        final size = _sizeValue(
          a.item.variant,
        ).compareTo(_sizeValue(b.item.variant));
        if (size != 0) return size;
        return a.item.name.compareTo(b.item.name);
      });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Stocked items'),
        const SizedBox(height: 6),
        for (final record in sorted) ...[
          _InventoryStockRow(
            record: record,
            summary: _stockSummaryFor(
              record: record,
              companyRecords: records,
              activeRecords: activeRecords,
            ),
            selected: _sameInventoryItem(selected, record),
            onTap: () => onSelected(record),
          ),
          const SizedBox(height: 7),
        ],
      ],
    );
  }
}

class _InventoryStockRow extends StatelessWidget {
  const _InventoryStockRow({
    required this.record,
    required this.summary,
    required this.selected,
    required this.onTap,
  });

  final WorkSupplyInventoryRecord record;
  final _InventoryStockSummary summary;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _tradeColor(record.item.trade);
    final availableElsewhere =
        summary.activeQuantity <= 0 && summary.companyQuantity > 0;
    final borderColor = selected
        ? const Color(0xFFE8ECEE)
        : availableElsewhere
        ? const Color(0xFFFFC46B)
        : record.isRunningLow
        ? const Color(0xFFE0B24D)
        : color.withValues(alpha: .8);
    final surfaceColor = selected
        ? color.withValues(alpha: .42)
        : availableElsewhere
        ? const Color(0xFF342713)
        : const Color(0xFF111B20);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(9, 7, 8, 7),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: borderColor, width: selected ? 2 : 1.15),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _plainItemLabel(record),
                      softWrap: true,
                      style: const TextStyle(
                        color: Color(0xFFE8ECEE),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        height: 1.08,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      availableElsewhere
                          ? 'Out on this vehicle | At ${summary.firstOtherLocation}'
                          : record.storageDetail.trim().isEmpty
                          ? record.item.path
                          : '${record.storageDetail.trim()} | ${record.item.path}',
                      softWrap: true,
                      style: TextStyle(
                        color: availableElsewhere
                            ? const Color(0xFFFFD58A)
                            : const Color(0xFFC7D0D4),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 78, maxWidth: 96),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (selected)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFFE8ECEE),
                        size: 16,
                      ),
                    Text(
                      availableElsewhere
                          ? '0 here'
                          : '${_formatNumber(summary.activeQuantity)} here',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_formatNumber(summary.companyQuantity)} total',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Color(0xFFC7D0D4),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
