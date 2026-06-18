import 'work_supply_item_identity_resolver.dart';
import 'work_supply_models.dart';

class WorkSupplyTradeContext {
  const WorkSupplyTradeContext({
    required this.trade,
    required this.category,
    required this.system,
    required this.itemType,
    this.reason = '',
  });

  final String trade;
  final String category;
  final String system;
  final String itemType;
  final String reason;

  String get path => '$trade / $category / $system / $itemType';
}

List<WorkSupplyTradeContext> workSupplyTradeContextsForItem(
  WorkSupplyItem item, {
  Iterable<String> enabledTrades = const [],
}) {
  final enabled = enabledTrades.map((trade) => trade.toLowerCase()).toSet();
  final contexts = <WorkSupplyTradeContext>[
    WorkSupplyTradeContext(
      trade: item.trade,
      category: item.category,
      system: item.system,
      itemType: item.itemType,
      reason: 'Primary catalog context.',
    ),
  ];

  if (_isCopperRefrigerantCompatible(item) &&
      (enabled.isEmpty || enabled.contains('hvac'))) {
    contexts.add(
      WorkSupplyTradeContext(
        trade: 'HVAC',
        category: 'Refrigerant Lines',
        system: 'Copper Fittings',
        itemType: item.itemType,
        reason: 'Copper fittings can also be used for refrigerant line work.',
      ),
    );
  }

  return _dedupeContexts(contexts);
}

List<WorkSupplyInventoryRecord> workSupplyRecordsForPhysicalItem(
  Iterable<WorkSupplyInventoryRecord> records,
  WorkSupplyItem item,
) {
  final key = canonicalWorkSupplyItemKey(item);
  return [
    for (final record in records)
      if (canonicalWorkSupplyItemKey(record.item) == key) record,
  ];
}

double workSupplyOnHandForPhysicalItem(
  Iterable<WorkSupplyInventoryRecord> records,
  WorkSupplyItem item,
) {
  return workSupplyRecordsForPhysicalItem(
    records,
    item,
  ).fold(0, (sum, record) => sum + record.onHand);
}

bool workSupplyItemHasSharedTradeContext(WorkSupplyItem item) {
  return workSupplyTradeContextsForItem(item).length > 1;
}

bool _isCopperRefrigerantCompatible(WorkSupplyItem item) {
  final itemType = item.itemType.toLowerCase();
  return item.trade == 'Plumbing' &&
      item.category == 'Fittings' &&
      item.system == 'Copper' &&
      (itemType.contains('elbow') ||
          itemType.contains('tee') ||
          itemType.contains('coupling') ||
          itemType.contains('cap') ||
          itemType.contains('union') ||
          itemType.contains('adapter'));
}

List<WorkSupplyTradeContext> _dedupeContexts(
  List<WorkSupplyTradeContext> contexts,
) {
  final byPath = <String, WorkSupplyTradeContext>{};
  for (final context in contexts) {
    byPath[context.path] = context;
  }
  return byPath.values.toList();
}
