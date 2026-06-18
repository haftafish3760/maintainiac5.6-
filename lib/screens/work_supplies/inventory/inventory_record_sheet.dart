part of 'work_supply_inventory_screen.dart';

class _InventoryRecordSheet extends StatelessWidget {
  const _InventoryRecordSheet({
    required this.record,
    required this.relatedRecords,
    required this.recentTransactions,
    required this.activeVehicleName,
    required this.activeVehicleQuantity,
    required this.onAddMore,
    required this.onRemove,
  });

  final WorkSupplyInventoryRecord record;
  final List<WorkSupplyInventoryRecord> relatedRecords;
  final List<WorkSupplyInventoryTransaction> recentTransactions;
  final String activeVehicleName;
  final double activeVehicleQuantity;
  final VoidCallback onAddMore;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final companyTotal = _totalUnits(relatedRecords);
    final locationRows = _locationRows(relatedRecords);
    final purchaseRows = _purchaseRows(recentTransactions).take(10).toList();
    final currentVehicleOut = activeVehicleQuantity <= 0 && companyTotal > 0;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF879196),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              record.item.name,
              style: const TextStyle(
                color: Color(0xFF111820),
                fontSize: 19,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              record.item.path,
              style: const TextStyle(
                color: Color(0xFF40505A),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (currentVehicleOut) ...[
              const SizedBox(height: 10),
              _StockAlert(
                message:
                    '$activeVehicleName is out of this item. Stock exists at ${locationRows.first.location}.',
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                _LightStat(
                  '${_formatNumber(activeVehicleQuantity)} ${record.item.unit} on this vehicle',
                ),
                _LightStat('Low at ${_formatNumber(record.threshold)}'),
                _LightStat(
                  '${_formatNumber(companyTotal)} ${record.item.unit} company-wide',
                ),
                _LightStat(_money(record.unitCostWithTax)),
                _LightStat(
                  record.receiptLinked ? 'Receipt linked' : 'No receipt',
                ),
                if (record.storageDetail.trim().isNotEmpty)
                  _LightStat(record.storageDetail.trim()),
              ],
            ),
            const SizedBox(height: 14),
            _SheetSection(
              title: 'Where this item is stocked',
              children: [
                for (final row in locationRows)
                  _SheetDataRow(
                    title: row.location,
                    value: '${_formatNumber(row.quantity)} ${record.item.unit}',
                    detail: row.detail,
                  ),
              ],
            ),
            if (purchaseRows.isNotEmpty) ...[
              const SizedBox(height: 12),
              _SheetSection(
                title: 'Recent purchase records',
                children: [
                  for (final row in purchaseRows)
                    _SheetDataRow(
                      title: row.title,
                      value: _money(row.unitCost),
                      detail: row.detail,
                    ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            AppButton(
              label: 'Add More Of This Item',
              tone: AppButtonTone.commit,
              icon: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 18,
              ),
              onPressed: onAddMore,
            ),
            const SizedBox(height: 8),
            AppButton(
              label: 'Mark Out Of Stock',
              tone: AppButtonTone.destructive,
              icon: const Icon(
                Icons.inventory_2_outlined,
                color: Colors.white,
                size: 18,
              ),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetSection extends StatelessWidget {
  const _SheetSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF111820),
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF4F6F7),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: const Color(0xFFBAC3C8)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _StockAlert extends StatelessWidget {
  const _StockAlert({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3D6),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFFD39A42), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.swap_horiz_rounded,
            color: Color(0xFF7A4C10),
            size: 19,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF3B2A12),
                fontSize: 12,
                fontWeight: FontWeight.w900,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetDataRow extends StatelessWidget {
  const _SheetDataRow({
    required this.title,
    required this.value,
    required this.detail,
  });

  final String title;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF1E2B32),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (detail.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF52636C),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF111820),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _LightStat extends StatelessWidget {
  const _LightStat(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F7),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFBAC3C8)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF1E2B32),
            fontSize: 11.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFFDDE6EA),
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
      ),
    );
  }
}
