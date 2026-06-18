import 'work_supply_catalog.dart';
import 'work_supply_item_identity_resolver.dart';
import 'work_supply_models.dart';

Map<String, Object?> buildWorkSupplyTradePackPayload(
  String tradeName, {
  int version = 1,
}) {
  final trade = workSupplyTrades.firstWhere(
    (candidate) => candidate.name == tradeName,
  );
  final items = _itemsForTrade(tradeName);
  final categoryPaths = <String>{};
  final systems = <String>{};
  final itemTypes = <String>{};
  final aliases = <String>{};
  for (final item in items) {
    categoryPaths.add('${item.category} / ${item.system} / ${item.itemType}');
    systems.add('${item.category} / ${item.system}');
    itemTypes.add('${item.category} / ${item.system} / ${item.itemType}');
    aliases.addAll(item.aliases.where((alias) => alias.trim().isNotEmpty));
  }
  return {
    'schemaVersion': 1,
    'packId': _packIdForTrade(tradeName),
    'displayName': '$tradeName Trade Pack',
    'trade': tradeName,
    'version': version,
    'stats': {
      'categoryCount': trade.categories.length,
      'systemCount': systems.length,
      'itemTypeCount': itemTypes.length,
      'categoryPathCount': categoryPaths.length,
      'itemCount': items.length,
      'aliasCount': aliases.length,
    },
    'categories': [
      for (final category in trade.categories)
        {
          'name': category.name,
          'systems': [
            for (final system in category.systems)
              {
                'name': system.name,
                'itemTypes': [
                  for (final type in system.itemTypes)
                    {'name': type.name, 'itemCount': type.items.length},
                ],
              },
          ],
        },
    ],
    'items': [
      for (final item in items)
        {
          'canonicalKey': canonicalWorkSupplyItemKey(item),
          'displayName': item.name,
          'trade': item.trade,
          'category': item.category,
          'system': item.system,
          'itemType': item.itemType,
          'variant': item.variant,
          'unit': item.unit,
          'aliases': item.aliases,
        },
    ],
  };
}

List<WorkSupplyItem> _itemsForTrade(String tradeName) {
  return [
    for (final item in workSupplyCatalogItems)
      if (item.trade == tradeName) item,
  ];
}

String _packIdForTrade(String tradeName) {
  return tradeName
      .toLowerCase()
      .replaceAll('&', 'and')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}
