part of 'work_supply_inventory_screen.dart';

class _EmptyInventory extends StatelessWidget {
  const _EmptyInventory({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111B20),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFF40515A)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFFC7D0D4),
          fontSize: 13,
          fontWeight: FontWeight.w800,
          height: 1.3,
        ),
      ),
    );
  }
}

class _FilterChoice {
  const _FilterChoice({
    required this.label,
    required this.count,
    required this.units,
    this.color,
    this.imageAsset,
  });

  final String label;
  final int count;
  final double units;
  final Color? color;
  final String? imageAsset;
}

class _LocationStockRow {
  const _LocationStockRow({
    required this.location,
    required this.quantity,
    required this.detail,
  });

  final String location;
  final double quantity;
  final String detail;
}

class _PurchaseRecordRow {
  const _PurchaseRecordRow({
    required this.title,
    required this.detail,
    required this.unitCost,
  });

  final String title;
  final String detail;
  final double unitCost;
}

class _PreviouslyPurchasedItem {
  const _PreviouslyPurchasedItem({
    required this.item,
    required this.transactions,
  });

  final WorkSupplyItem item;
  final List<WorkSupplyInventoryTransaction> transactions;

  WorkSupplyInventoryTransaction get latest => transactions.first;
  DateTime get lastPurchasedAt => latest.occurredAt;
  String get lastMerchant => latest.sourceMerchantName;
  double get lastUnitCost => latest.unitCostWithTax;
}

class _InventoryStockSummary {
  const _InventoryStockSummary({
    required this.activeQuantity,
    required this.companyQuantity,
    required this.firstOtherLocation,
  });

  final double activeQuantity;
  final double companyQuantity;
  final String firstOtherLocation;
}

const _inventoryTradeOrder = [
  'Plumbing',
  'Electrical',
  'HVAC',
  'Carpentry',
  'Drywall',
  'Painting',
  'Roofing',
  'Tile',
  'Insulation',
  'Fencing',
  'Masonry and Concrete',
  'Landscaping',
  'Low Voltage and Data',
  'Tools and Safety',
];

List<_FilterChoice> _filterChoices({
  required List<WorkSupplyInventoryRecord> records,
  required String Function(WorkSupplyInventoryRecord record) valueFor,
  Color Function(String value)? colorFor,
  String? Function(String value)? imageFor,
  List<String> order = const [],
}) {
  final grouped = <String, List<WorkSupplyInventoryRecord>>{};
  for (final record in records) {
    final value = valueFor(record).trim();
    if (value.isEmpty) continue;
    grouped.putIfAbsent(value, () => []).add(record);
  }
  return _sortFilterChoices([
    for (final entry in grouped.entries)
      _FilterChoice(
        label: entry.key,
        count: _uniqueInventoryRecords(entry.value).length,
        units: _totalUnits(entry.value),
        color: colorFor?.call(entry.key),
        imageAsset: imageFor?.call(entry.key),
      ),
  ], order);
}

List<_FilterChoice> _previousFilterChoices({
  required List<_PreviouslyPurchasedItem> items,
  required String Function(_PreviouslyPurchasedItem entry) valueFor,
  Color Function(String value)? colorFor,
  List<String> order = const [],
}) {
  final grouped = <String, List<_PreviouslyPurchasedItem>>{};
  for (final entry in items) {
    final value = valueFor(entry).trim();
    if (value.isEmpty) continue;
    grouped.putIfAbsent(value, () => []).add(entry);
  }
  return _sortFilterChoices([
    for (final entry in grouped.entries)
      _FilterChoice(
        label: entry.key,
        count: entry.value.length,
        units: 0,
        color: colorFor?.call(entry.key),
      ),
  ], order);
}

List<_FilterChoice> _sortFilterChoices(
  List<_FilterChoice> choices,
  List<String> order,
) {
  final position = {
    for (var index = 0; index < order.length; index++) order[index]: index,
  };
  return choices..sort((a, b) {
    final aIndex = position[a.label] ?? 9999;
    final bIndex = position[b.label] ?? 9999;
    if (aIndex != bIndex) return aIndex.compareTo(bIndex);
    return a.label.compareTo(b.label);
  });
}

List<WorkSupplyInventoryRecord> _recordsForPath(
  List<WorkSupplyInventoryRecord> source, {
  String? trade,
  String? category,
  String? system,
}) {
  return source.where((record) {
    if (trade != null && record.item.trade != trade) return false;
    if (category != null && record.item.category != category) return false;
    if (system != null && record.item.system != system) return false;
    return true;
  }).toList();
}

List<WorkSupplyInventoryRecord> _uniqueInventoryRecords(
  List<WorkSupplyInventoryRecord> records,
) {
  final byItem = <String, WorkSupplyInventoryRecord>{};
  for (final record in records) {
    byItem.putIfAbsent(_inventoryItemKey(record), () => record);
  }
  return byItem.values.toList();
}

_InventoryStockSummary _stockSummaryFor({
  required WorkSupplyInventoryRecord record,
  required List<WorkSupplyInventoryRecord> companyRecords,
  required List<WorkSupplyInventoryRecord> activeRecords,
}) {
  final companyMatches = companyRecords
      .where((candidate) => _sameInventoryItem(candidate, record))
      .toList();
  final activeMatches = activeRecords
      .where((candidate) => _sameInventoryItem(candidate, record))
      .toList();
  final otherLocations =
      companyMatches
          .where((candidate) => !activeMatches.contains(candidate))
          .map((candidate) => candidate.storageArea)
          .where((location) => location.trim().isNotEmpty)
          .toSet()
          .toList()
        ..sort();
  return _InventoryStockSummary(
    activeQuantity: _totalUnits(activeMatches),
    companyQuantity: _totalUnits(companyMatches),
    firstOtherLocation: otherLocations.isEmpty
        ? 'another location'
        : otherLocations.first,
  );
}

bool _sameInventoryItem(
  WorkSupplyInventoryRecord? a,
  WorkSupplyInventoryRecord? b,
) {
  if (a == null || b == null) return false;
  return _inventoryItemKey(a) == _inventoryItemKey(b);
}

String _inventoryItemKey(WorkSupplyInventoryRecord record) {
  return _itemKey(record.item);
}

bool _sameItemValues(WorkSupplyItem a, WorkSupplyItem b) {
  return _itemKey(a) == _itemKey(b);
}

String _itemKey(WorkSupplyItem item) {
  if (item.id.trim().isNotEmpty) return item.id;
  return '${item.name}|${item.path}';
}

Color _tradeColor(String? trade) {
  return switch (trade) {
    'Plumbing' => const Color(0xFF2D7EA7),
    'Electrical' => const Color(0xFFF6B73C),
    'HVAC' => const Color(0xFF4EB7C4),
    'Carpentry' => const Color(0xFFB57742),
    'Insulation' => const Color(0xFFDF9A3A),
    'Drywall' => const Color(0xFF9AA3A8),
    'Painting' => const Color(0xFF66A6D8),
    'Roofing' => const Color(0xFF6D7A84),
    'Tile' => const Color(0xFF5FA58E),
    'Fencing' => const Color(0xFF8A704D),
    'Masonry and Concrete' => const Color(0xFFA77E55),
    'Landscaping' => const Color(0xFF4F9B59),
    'Low Voltage and Data' => const Color(0xFF8E72D8),
    'Tools and Safety' => const Color(0xFFD05D4B),
    _ => const Color(0xFF64C98A),
  };
}

String? _generatedTradeIconAsset(String trade) {
  return switch (trade) {
    'Plumbing' => 'assets/generated_trade_icons/plumbing.png',
    'Electrical' => 'assets/generated_trade_icons/electrical.png',
    'HVAC' => 'assets/generated_trade_icons/hvac.png',
    'Carpentry' => 'assets/generated_trade_icons/carpentry.png',
    'Drywall' => 'assets/generated_trade_icons/drywall.png',
    'Painting' => 'assets/generated_trade_icons/painting.png',
    'Roofing' => 'assets/generated_trade_icons/roofing.png',
    'Tile' => 'assets/generated_trade_icons/tile.png',
    'Insulation' => 'assets/generated_trade_icons/insulation.png',
    'Fencing' => 'assets/generated_trade_icons/fencing.png',
    'Masonry and Concrete' =>
      'assets/generated_trade_icons/masonry_concrete.png',
    'Landscaping' => 'assets/generated_trade_icons/landscaping.png',
    'Low Voltage and Data' =>
      'assets/generated_trade_icons/low_voltage_data.png',
    'Tools and Safety' => 'assets/generated_trade_icons/tools_safety.png',
    _ => null,
  };
}

String _plainItemLabel(WorkSupplyInventoryRecord record) {
  final variant = record.item.variant.trim();
  final type = record.item.itemType.trim();
  if (variant.isEmpty) return record.item.name;
  if (type.isEmpty || record.item.name.contains(variant)) {
    return record.item.name;
  }
  return '$variant $type';
}

double _totalUnits(Iterable<WorkSupplyInventoryRecord> records) {
  return records.fold(0, (total, record) => total + record.onHand);
}

double _sizeValue(String value) {
  final match = RegExp(r'(\d+)(?:/(\d+))?').firstMatch(value);
  if (match == null) return double.maxFinite;
  final whole = double.tryParse(match.group(1) ?? '') ?? 0;
  final denominator = double.tryParse(match.group(2) ?? '');
  if (denominator == null || denominator == 0) return whole;
  return whole / denominator;
}

String _formatNumber(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(2);
}

String _filterChoiceDetail(_FilterChoice choice) {
  final itemLabel = choice.count == 1 ? 'item' : 'items';
  if (choice.units <= 0) return '${choice.count} $itemLabel';
  final unitLabel = choice.units == 1 ? 'unit' : 'units';
  return '${choice.count} $itemLabel | ${_formatNumber(choice.units)} $unitLabel';
}

String _money(double value) => '\$${value.toStringAsFixed(2)} each';

List<_LocationStockRow> _locationRows(List<WorkSupplyInventoryRecord> records) {
  final grouped = <String, List<WorkSupplyInventoryRecord>>{};
  for (final record in records) {
    grouped.putIfAbsent(record.storageArea, () => []).add(record);
  }
  final rows = [
    for (final entry in grouped.entries)
      _LocationStockRow(
        location: entry.key,
        quantity: _totalUnits(entry.value),
        detail: entry.value
            .map((record) => record.storageDetail.trim())
            .where((detail) => detail.isNotEmpty)
            .toSet()
            .join(', '),
      ),
  ];
  rows.sort((a, b) => a.location.compareTo(b.location));
  return rows;
}

List<_PurchaseRecordRow> _purchaseRows(
  List<WorkSupplyInventoryTransaction> transactions,
) {
  final rows = [
    for (final transaction in transactions)
      _PurchaseRecordRow(
        title: _dateLabel(transaction.occurredAt),
        detail: [
          if (transaction.sourceMerchantName.trim().isNotEmpty)
            transaction.sourceMerchantName.trim(),
          '${_formatNumber(transaction.packagesPurchased)} ${transaction.purchaseType}',
          '${_formatNumber(transaction.totalUnitsPurchased)} ${transaction.item.unit}',
        ].join(' | '),
        unitCost: transaction.unitCostWithTax,
      ),
  ];
  rows.sort((a, b) => b.title.compareTo(a.title));
  return rows;
}

String _dateLabel(DateTime? date) {
  if (date == null) return 'Unknown date';
  return '${date.month}/${date.day}/${date.year}';
}
