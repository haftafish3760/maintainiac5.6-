import 'inventory_parser.dart';
import 'work_supply_models.dart';
import 'work_supply_receipt_parser.dart';
import 'work_supply_trade_pack_delivery_policy.dart';

class InventoryRemoteCatalogQuery {
  const InventoryRemoteCatalogQuery({
    required this.rawText,
    required this.tradeScope,
    required this.localePackId,
    required this.limit,
  });

  final String rawText;
  final String tradeScope;
  final String localePackId;
  final int limit;
}

abstract interface class InventoryRemoteCatalogSource {
  Future<List<WorkSupplyItem>> queryCandidates(
    InventoryRemoteCatalogQuery query,
  );
}

/// Parser entry point for the subscription-backed cloud catalog mode.
///
/// The remote adapter performs the indexed Firebase query. This class keeps
/// the parser independent of Firebase SDKs and validates the returned catalog
/// slice before the normal compiled matcher is allowed to use it.
class InventoryOnlineParser {
  const InventoryOnlineParser({required InventoryRemoteCatalogSource source})
    : _source = source;

  final InventoryRemoteCatalogSource _source;

  Future<ReceiptLineMatch?> matchReceiptLine(
    String rawText, {
    required String tradeScope,
    String localePackId = '',
    int maxCandidates = 80,
    ReceiptParserLearningMemory? memory,
    Map<String, String> trustedItemIdentityIds = const {},
  }) async {
    final normalizedTrade = tradeScope.trim();
    if (normalizedTrade.isEmpty) {
      throw ArgumentError.value(
        tradeScope,
        'tradeScope',
        'Online inventory parsing requires an explicit trade scope.',
      );
    }
    if (maxCandidates <= 0) return null;
    final limit = maxCandidates.clamp(
      1,
      workSupplyTradePackDeliveryPolicy.cloudReadBudgetPerReceipt,
    );
    final items = await _source.queryCandidates(
      InventoryRemoteCatalogQuery(
        rawText: rawText,
        tradeScope: normalizedTrade,
        localePackId: localePackId,
        limit: limit,
      ),
    );
    _validateRemoteItems(items, tradeScope: normalizedTrade, limit: limit);
    return InventoryParser(
      catalogItems: List<WorkSupplyItem>.unmodifiable(items),
    ).matchReceiptLine(
      rawText,
      tradeScope: normalizedTrade,
      localePackId: localePackId,
      maxCandidates: limit,
      memory: memory,
      trustedItemIdentityIds: trustedItemIdentityIds,
    );
  }
}

void _validateRemoteItems(
  List<WorkSupplyItem> items, {
  required String tradeScope,
  required int limit,
}) {
  if (items.length > limit) {
    throw StateError(
      'Remote catalog returned ${items.length} candidates; limit is $limit.',
    );
  }
  final expectedTrade = tradeScope.toLowerCase();
  final ids = <String>{};
  for (final item in items) {
    if (item.trade.trim().toLowerCase() != expectedTrade) {
      throw StateError(
        'Remote catalog returned ${item.trade} for $tradeScope parsing.',
      );
    }
    if (!ids.add(item.id)) {
      throw StateError('Remote catalog returned duplicate item ID ${item.id}.');
    }
  }
}
