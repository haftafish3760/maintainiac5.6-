import 'work_supply_catalog.dart';
import 'work_supply_catalog_audit.dart';
import 'work_supply_item_identity_resolver.dart';
import 'work_supply_models.dart';

const workSupplyFullTradesCatalogName = 'Full Trades Catalog';

enum WorkSupplyTradePackTier {
  core(
    'core',
    'Core',
    'Top daily-use items for receipt help, inventory entry, and estimates',
    .30,
    'Top 25-30% by service-truck usefulness',
  ),
  expanded(
    'standard',
    'Standard',
    'Common plus regular job stock for stronger receipt and estimate help',
    .60,
    'Top 50-60% by residential and light-industrial use',
  ),
  professional(
    'professional',
    'Professional',
    'Deep service inventory for busy contractors and stocked trucks',
    .90,
    'Top 80-90% before specialty edge cases',
  ),
  full(
    'complete',
    'Complete',
    'Every cataloged item for the trade, including specialty and rare stock',
    1,
    'Complete trade catalog',
  );

  const WorkSupplyTradePackTier(
    this.id,
    this.label,
    this.description,
    this.catalogShare,
    this.popularityBand,
  );

  final String id;
  final String label;
  final String description;
  final double catalogShare;
  final String popularityBand;
}

class WorkSupplyTradePackOption {
  const WorkSupplyTradePackOption({
    required this.tradeName,
    required this.tier,
    required this.itemCount,
    required this.estimatedRawBytes,
    required this.estimatedCompressedBytes,
    required this.storagePath,
  });

  final String tradeName;
  final WorkSupplyTradePackTier tier;
  final int itemCount;
  final int estimatedRawBytes;
  final int estimatedCompressedBytes;
  final String storagePath;

  String get displayName {
    if (tradeName == workSupplyFullTradesCatalogName) {
      return workSupplyFullTradesCatalogName;
    }
    return '${tier.label} $tradeName Pack';
  }

  String get estimatedSizeLabel => _byteSizeLabel(estimatedCompressedBytes);

  Map<String, Object?> toManifestMap() {
    return {
      'tradeName': tradeName,
      'tier': tier.id,
      'displayName': displayName,
      'description': tier.description,
      'popularityBand': tier.popularityBand,
      'catalogSharePercent': (tier.catalogShare * 100).round(),
      'itemCount': itemCount,
      'estimatedCompressedBytes': estimatedCompressedBytes,
      'estimatedSizeLabel': estimatedSizeLabel,
      'storagePath': storagePath,
      'deliveryMode': 'storage_gzip_chunk',
      'receiptAssistance':
          'Helps match receipt lines, package quantities, aliases, and vendor wording.',
      'estimateAssistance':
          'Can stage matched materials for estimate line items after receipt review.',
    };
  }
}

class WorkSupplyTradePackTradeSummary {
  const WorkSupplyTradePackTradeSummary({
    required this.tradeName,
    required this.optionCount,
    required this.itemCount,
    required this.estimatedCompressedBytes,
  });

  final String tradeName;
  final int optionCount;
  final int itemCount;
  final int estimatedCompressedBytes;

  String get estimatedSizeLabel => _byteSizeLabel(estimatedCompressedBytes);
}

List<WorkSupplyTradePackOption> buildWorkSupplyTradePackOptions(
  String tradeName,
) {
  final core = buildWorkSupplyTradePackItems(
    tradeName,
    WorkSupplyTradePackTier.core,
  );
  final expanded = buildWorkSupplyTradePackItems(
    tradeName,
    WorkSupplyTradePackTier.expanded,
  );
  final professional = buildWorkSupplyTradePackItems(
    tradeName,
    WorkSupplyTradePackTier.professional,
  );
  final full = buildWorkSupplyTradePackItems(
    tradeName,
    WorkSupplyTradePackTier.full,
  );
  return [
    _optionFor(tradeName, WorkSupplyTradePackTier.core, core),
    if (expanded.isNotEmpty)
      _optionFor(tradeName, WorkSupplyTradePackTier.expanded, expanded),
    if (professional.isNotEmpty)
      _optionFor(tradeName, WorkSupplyTradePackTier.professional, professional),
    _optionFor(tradeName, WorkSupplyTradePackTier.full, full),
  ];
}

List<WorkSupplyTradePackOption> buildAllWorkSupplyTradePackOptions() {
  return [
    for (final trade in workSupplyTrades)
      ...buildWorkSupplyTradePackOptions(trade.name),
  ];
}

List<WorkSupplyTradePackOption> buildAllWorkSupplyDownloadOptions() {
  return [
    buildFullWorkSupplyTradePackOption(),
    ...buildAllWorkSupplyTradePackOptions(),
  ];
}

WorkSupplyTradePackOption buildFullWorkSupplyTradePackOption() {
  final items = buildWorkSupplyTradePackItems(
    workSupplyFullTradesCatalogName,
    WorkSupplyTradePackTier.full,
  );
  return _optionFor(
    workSupplyFullTradesCatalogName,
    WorkSupplyTradePackTier.full,
    items,
  );
}

List<WorkSupplyTradePackTradeSummary> buildWorkSupplyTradePackSummaries() {
  return [for (final trade in workSupplyTrades) _summaryForTrade(trade.name)];
}

String workSupplyTradePackOptionKey(WorkSupplyTradePackOption option) {
  return '${workSupplyTradePackTradeKey(option.tradeName)}:${option.tier.id}';
}

String workSupplyTradePackTradeKey(String tradeName) {
  return _packSlug(tradeName);
}

List<WorkSupplyItem> buildWorkSupplyTradePackItems(
  String tradeName,
  WorkSupplyTradePackTier tier,
) {
  if (tradeName == workSupplyFullTradesCatalogName) {
    return _rankedItemsForTier(workSupplyCatalogItems, tier);
  }
  return _rankedItemsForTier(_itemsForTrade(tradeName), tier);
}

WorkSupplyTradePackTradeSummary _summaryForTrade(String tradeName) {
  final items = _itemsForTrade(tradeName);
  final rawBytes = _estimatedPackBytes(
    tradeName,
    WorkSupplyTradePackTier.full,
    items,
  );
  return WorkSupplyTradePackTradeSummary(
    tradeName: tradeName,
    optionCount: WorkSupplyTradePackTier.values.length,
    itemCount: items.length,
    estimatedCompressedBytes: _estimatedCompressedBytes(rawBytes),
  );
}

List<WorkSupplyItem> _rankedItemsForTier(
  List<WorkSupplyItem> items,
  WorkSupplyTradePackTier tier,
) {
  if (items.isEmpty) return const [];
  if (tier == WorkSupplyTradePackTier.full) return List.unmodifiable(items);
  final ranked = [...items]..sort(_compareByServicePopularity);
  final takeCount = (ranked.length * tier.catalogShare).ceil().clamp(
    1,
    ranked.length,
  );
  return List.unmodifiable(ranked.take(takeCount));
}

int _compareByServicePopularity(WorkSupplyItem a, WorkSupplyItem b) {
  final score = _servicePopularityScore(
    b,
  ).compareTo(_servicePopularityScore(a));
  if (score != 0) return score;
  return canonicalWorkSupplyItemKey(a).compareTo(canonicalWorkSupplyItemKey(b));
}

int _servicePopularityScore(WorkSupplyItem item) {
  final text = [
    item.trade,
    item.category,
    item.system,
    item.itemType,
    item.name,
    item.variant,
    item.unit,
    ...item.aliases,
  ].join(' ').toLowerCase();
  var score = 0;
  const highUseTerms = {
    'pex': 30,
    'pvc': 30,
    'dwv': 26,
    'schedule 40': 26,
    'copper': 24,
    'cpvc': 20,
    'sharkbite': 20,
    'push': 18,
    'supply': 18,
    'valve': 18,
    'ball valve': 22,
    'toilet': 18,
    'faucet': 16,
    'sink': 16,
    'water heater': 16,
    'drain': 16,
    'trap': 16,
    'coupling': 15,
    'elbow': 15,
    'tee': 15,
    'adapter': 14,
    'cap': 12,
    'nipple': 12,
    'washer': 10,
    'o-ring': 10,
    'screw': 8,
    'strap': 8,
    'hanger': 8,
  };
  const lowerPriorityTerms = {
    'expanded': -8,
    'galvanized': -12,
    'black iron': -8,
    'cast iron': -8,
    'specialty': -14,
    'commercial': -12,
  };
  for (final entry in highUseTerms.entries) {
    if (text.contains(entry.key)) score += entry.value;
  }
  for (final entry in lowerPriorityTerms.entries) {
    if (text.contains(entry.key)) score += entry.value;
  }
  if (item.aliases.length >= 3) score += 6;
  if (item.variant.contains('1/2') || item.variant.contains('3/4')) score += 8;
  if (item.variant.contains('1 in') || item.variant.contains('1"')) score += 4;
  return score;
}

WorkSupplyTradePackOption _optionFor(
  String tradeName,
  WorkSupplyTradePackTier tier,
  List<WorkSupplyItem> items,
) {
  final rawBytes = _estimatedPackBytes(tradeName, tier, items);
  return WorkSupplyTradePackOption(
    tradeName: tradeName,
    tier: tier,
    itemCount: items.length,
    estimatedRawBytes: rawBytes,
    estimatedCompressedBytes: _estimatedCompressedBytes(rawBytes),
    storagePath:
        '$workSupplyCatalogStoragePrefix/${_packSlug(tradeName)}/${tier.id}.json.gz',
  );
}

List<WorkSupplyItem> _itemsForTrade(String tradeName) {
  return [
    for (final item in workSupplyCatalogItems)
      if (item.trade == tradeName) item,
  ];
}

int _estimatedPackBytes(
  String tradeName,
  WorkSupplyTradePackTier tier,
  List<WorkSupplyItem> items,
) {
  var total = 220 + tradeName.length + tier.id.length;
  for (final item in items) {
    total += 180;
    total += canonicalWorkSupplyItemKey(item).length;
    total += item.id.length;
    total += item.name.length;
    total += item.category.length;
    total += item.system.length;
    total += item.itemType.length;
    total += item.variant.length;
    total += item.unit.length;
    for (final alias in item.aliases) {
      total += 16 + alias.length;
    }
  }
  return total;
}

int _estimatedCompressedBytes(int rawBytes) {
  if (rawBytes <= 0) return 0;
  return (rawBytes * .08).ceil();
}

String _byteSizeLabel(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kib = bytes / 1024;
  if (kib < 1024) return '${kib.toStringAsFixed(1)} KB';
  return '${(kib / 1024).toStringAsFixed(1)} MB';
}

String _packSlug(String value) {
  return value
      .toLowerCase()
      .replaceAll('&', 'and')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}
