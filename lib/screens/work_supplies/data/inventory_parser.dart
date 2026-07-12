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
