import 'work_supply_models.dart';
import 'work_supply_receipt_parser.dart';
import 'work_supply_trade_pack_runtime_loader.dart';

/// Stable inventory-parser entry point for receipt text already handed off by
/// OCR, PDFs, or manual entry. Camera/OCR owns recognition; this class only
/// classifies the supplied line against the active local catalog.
class InventoryParser {
  const InventoryParser({this.catalogItems});

  factory InventoryParser.fromLoadedTradePack(
    WorkSupplyTradePackRuntimeLoadResult pack,
  ) {
    if (!pack.isReady) {
      throw ArgumentError.value(
        pack.status,
        'pack',
        'A validated local trade pack is required for offline inventory parsing.',
      );
    }
    return InventoryParser(catalogItems: pack.items);
  }

  factory InventoryParser.fromLoadedTradePacks(
    Iterable<WorkSupplyTradePackRuntimeLoadResult> packs,
  ) {
    final itemsById = <String, WorkSupplyItem>{};
    for (final pack in packs) {
      if (!pack.isReady) {
        throw ArgumentError.value(
          pack.status,
          'packs',
          'Every local trade pack must be validated before offline parsing.',
        );
      }
      for (final item in pack.items) {
        final existing = itemsById[item.id];
        if (existing == null) {
          itemsById[item.id] = item;
          continue;
        }
        if (!_sameCatalogItem(existing, item)) {
          throw ArgumentError.value(
            item.id,
            'packs',
            'Installed trade packs contain conflicting item IDs.',
          );
        }
      }
    }
    return InventoryParser(
      catalogItems: List<WorkSupplyItem>.unmodifiable(itemsById.values),
    );
  }

  /// Null preserves the legacy/default compiled-catalog behavior. A non-null
  /// list restricts matching to the bundled or user-downloaded pack only.
  final List<WorkSupplyItem>? catalogItems;

  ReceiptLineMatch? matchReceiptLine(
    String rawText, {
    String? tradeScope,
    String localePackId = '',
    int maxCandidates = 80,
    ReceiptParserLearningMemory? memory,
    Map<String, String> trustedItemIdentityIds = const {},
  }) {
    return matchReceiptLineToCatalog(
      rawText,
      tradeScope: tradeScope,
      localePackId: localePackId,
      maxCandidates: maxCandidates,
      memory: memory,
      trustedItemIdentityIds: trustedItemIdentityIds,
      catalogItems: catalogItems,
    );
  }
}

bool _sameCatalogItem(WorkSupplyItem left, WorkSupplyItem right) {
  return left.id == right.id &&
      left.name == right.name &&
      left.trade == right.trade &&
      left.category == right.category &&
      left.system == right.system &&
      left.itemType == right.itemType &&
      left.variant == right.variant &&
      left.unit == right.unit;
}
