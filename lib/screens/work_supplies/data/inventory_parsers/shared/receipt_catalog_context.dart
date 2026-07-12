part of '../../work_supply_receipt_parser.dart';

List<WorkSupplyItem>? _activeReceiptCatalogItems;
_ReceiptCatalogIndexes? _activeReceiptCatalogIndexes;

final _receiptCatalogContextByItems = Expando<_ReceiptCatalogContext>(
  'receiptCatalogContext',
);

final _baseReceiptCatalogIndexes = _ReceiptCatalogIndexes.build(
  catalog.workSupplyCatalogItems,
);

List<WorkSupplyItem> get _activeWorkSupplyCatalogItems =>
    _activeReceiptCatalogItems ?? catalog.workSupplyCatalogItems;

Map<String, _ReceiptCatalogEntry> get _receiptCatalogEntryById =>
    _activeReceiptCatalogIndexes?.entriesById ??
    _baseReceiptCatalogIndexes.entriesById;

List<WorkSupplyItem> get _plumbingPvcDwvSanitaryTeeItems =>
    _activeReceiptCatalogIndexes?.plumbingPvcDwvSanitaryTeeItems ??
    _baseReceiptCatalogIndexes.plumbingPvcDwvSanitaryTeeItems;

List<_ReceiptVendorMappingEntry> get _receiptVendorMappingIndex =>
    _activeReceiptCatalogIndexes?.vendorMappings ??
    _baseReceiptCatalogIndexes.vendorMappings;

Map<String, List<_ReceiptCatalogEntry>> get _receiptCatalogTokenIndex =>
    _activeReceiptCatalogIndexes?.tokenIndex ??
    _baseReceiptCatalogIndexes.tokenIndex;

T _runWithReceiptCatalogItems<T>(
  List<WorkSupplyItem>? catalogItems,
  T Function() action,
) {
  if (catalogItems == null) return action();
  final previousItems = _activeReceiptCatalogItems;
  final previousIndexes = _activeReceiptCatalogIndexes;
  final context = _receiptCatalogContextByItems[catalogItems] ??=
      _ReceiptCatalogContext.fromItems(catalogItems);
  _activeReceiptCatalogItems = context.items;
  _activeReceiptCatalogIndexes = context.indexes;
  try {
    return action();
  } finally {
    _activeReceiptCatalogItems = previousItems;
    _activeReceiptCatalogIndexes = previousIndexes;
  }
}

class _ReceiptCatalogContext {
  const _ReceiptCatalogContext._({required this.items, required this.indexes});

  factory _ReceiptCatalogContext.fromItems(List<WorkSupplyItem> source) {
    final items = List<WorkSupplyItem>.unmodifiable(source);
    return _ReceiptCatalogContext._(
      items: items,
      indexes: _ReceiptCatalogIndexes.build(items),
    );
  }

  final List<WorkSupplyItem> items;
  final _ReceiptCatalogIndexes indexes;
}

List<WorkSupplyItem> _searchActiveReceiptCatalogItems(String query) {
  final tokens = _normalize(
    query,
  ).split(' ').where((token) => token.length >= 2).toList();
  if (tokens.isEmpty) return _activeWorkSupplyCatalogItems.take(25).toList();
  return [
    for (final item in _activeWorkSupplyCatalogItems)
      if (tokens.every(item.searchableText.contains)) item,
  ];
}

class _ReceiptCatalogIndexes {
  const _ReceiptCatalogIndexes({
    required this.entries,
    required this.entriesById,
    required this.plumbingPvcDwvSanitaryTeeItems,
    required this.vendorMappings,
    required this.tokenIndex,
  });

  final List<_ReceiptCatalogEntry> entries;
  final Map<String, _ReceiptCatalogEntry> entriesById;
  final List<WorkSupplyItem> plumbingPvcDwvSanitaryTeeItems;
  final List<_ReceiptVendorMappingEntry> vendorMappings;
  final Map<String, List<_ReceiptCatalogEntry>> tokenIndex;

  factory _ReceiptCatalogIndexes.build(List<WorkSupplyItem> items) {
    final entries = [
      for (final item in items)
        (
          item: item,
          searchableText: item.searchableText.toLowerCase(),
          normalizedText: _normalize(
            '${item.searchableText} ${item.aliases.join(' ')}',
          ),
          variantText: _normalize(item.variant),
        ),
    ];
    return _ReceiptCatalogIndexes(
      entries: List.unmodifiable(entries),
      entriesById: Map.unmodifiable({
        for (final entry in entries) entry.item.id: entry,
      }),
      plumbingPvcDwvSanitaryTeeItems: List.unmodifiable([
        for (final item in items)
          if (item.trade == 'Plumbing' &&
              item.name.toLowerCase().contains('pvc dwv sanitary tee'))
            item,
      ]),
      vendorMappings: List.unmodifiable([
        for (final entry in entries)
          for (final mapping in entry.item.intelligence.vendorMappings)
            if (_compactVendorCode(mapping.code).length >= 4 ||
                _normalize(mapping.label).length >= 4)
              (
                item: entry.item,
                code: _compactVendorCode(mapping.code),
                label: _normalize(mapping.label),
              ),
      ]),
      tokenIndex: Map.unmodifiable(_buildReceiptCatalogTokenIndex(entries)),
    );
  }
}
