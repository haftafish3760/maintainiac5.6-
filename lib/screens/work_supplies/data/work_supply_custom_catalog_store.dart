import 'package:hive_flutter/hive_flutter.dart';

import 'work_supply_catalog.dart';
import 'work_supply_models.dart';

class WorkSupplyCustomCatalogStore {
  WorkSupplyCustomCatalogStore._(this._box);

  static const boxName = 'work_supply_custom_catalog_items';

  final Box<dynamic> _box;

  static Future<WorkSupplyCustomCatalogStore> create() async {
    final box = await Hive.openBox<dynamic>(boxName);
    return WorkSupplyCustomCatalogStore._(box);
  }

  List<WorkSupplyItem> loadItems() {
    final items = <WorkSupplyItem>[];
    for (final value in _box.values) {
      final item = _itemFromStoredValue(value);
      if (item != null) items.add(item);
    }
    items.sort((a, b) {
      final path = a.path.compareTo(b.path);
      if (path != 0) return path;
      return a.name.compareTo(b.name);
    });
    return items;
  }

  List<WorkSupplyItem> searchItems(String query, {int limit = 50}) {
    final tokens = _searchTokens(query);
    if (tokens.isEmpty) return loadItems().take(limit).toList();
    final scored = <({WorkSupplyItem item, int score})>[];
    for (final item in loadItems()) {
      final haystack = item.searchableText;
      var score = 0;
      for (final token in tokens) {
        if (haystack.contains(token)) score++;
      }
      if (score == tokens.length) scored.add((item: item, score: score));
    }
    scored.sort((a, b) {
      final score = b.score.compareTo(a.score);
      if (score != 0) return score;
      return a.item.name.compareTo(b.item.name);
    });
    return scored.map((entry) => entry.item).take(limit).toList();
  }

  Future<void> saveItem(WorkSupplyItem item) async {
    final id = item.id.trim().isEmpty
        ? 'USER-${DateTime.now().microsecondsSinceEpoch}'
        : item.id;
    final saved = WorkSupplyItem(
      id: id,
      name: item.name.trim(),
      trade: item.trade.trim(),
      category: item.category.trim(),
      system: item.system.trim(),
      itemType: item.itemType.trim(),
      variant: item.variant.trim(),
      unit: item.unit.trim().isEmpty ? 'each' : item.unit.trim(),
      aliases: item.aliases
          .map((alias) => alias.trim())
          .where((alias) => alias.isNotEmpty)
          .toSet()
          .toList(),
    );
    await _box.put(saved.id, _itemToMap(saved));
  }

  Future<void> clear() async {
    await _box.clear();
  }
}

List<WorkSupplyItem> mergeWorkSupplySearchResults({
  required String query,
  required List<WorkSupplyItem> customItems,
}) {
  final starterResults = searchWorkSupplies(query);
  final customResults = _searchCustomItems(customItems, query);
  final merged = <String, WorkSupplyItem>{};
  for (final item in [...customResults, ...starterResults]) {
    merged[item.id] = item;
  }
  return merged.values.take(50).toList();
}

List<WorkSupplyItem> _searchCustomItems(
  List<WorkSupplyItem> items,
  String query,
) {
  final tokens = _searchTokens(query);
  if (tokens.isEmpty) return items.take(25).toList();
  final scored = <({WorkSupplyItem item, int score})>[];
  for (final item in items) {
    final haystack = item.searchableText;
    var score = 0;
    for (final token in tokens) {
      if (haystack.contains(token)) score++;
    }
    if (score == tokens.length) scored.add((item: item, score: score));
  }
  scored.sort((a, b) {
    final score = b.score.compareTo(a.score);
    if (score != 0) return score;
    return a.item.name.compareTo(b.item.name);
  });
  return scored.map((entry) => entry.item).toList();
}

List<String> _searchTokens(String query) {
  return query
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9/.-]+'), ' ')
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .toList();
}

Map<String, Object?> _itemToMap(WorkSupplyItem item) {
  return {
    'id': item.id,
    'name': item.name,
    'trade': item.trade,
    'category': item.category,
    'system': item.system,
    'itemType': item.itemType,
    'variant': item.variant,
    'unit': item.unit,
    'aliases': item.aliases,
  };
}

WorkSupplyItem? _itemFromStoredValue(Object? value) {
  if (value is! Map) return null;
  return WorkSupplyItem(
    id: _string(value['id']),
    name: _string(value['name'], fallback: 'Custom Inventory Item'),
    trade: _string(value['trade'], fallback: 'Custom'),
    category: _string(value['category'], fallback: 'Custom'),
    system: _string(value['system'], fallback: 'User Added'),
    itemType: _string(value['itemType'], fallback: 'Manual Item'),
    variant: _string(value['variant'], fallback: 'manual'),
    unit: _string(value['unit'], fallback: 'each'),
    aliases: _stringList(value['aliases']),
  );
}

String _string(Object? value, {String fallback = ''}) {
  if (value == null) return fallback;
  return value.toString();
}

List<String> _stringList(Object? value) {
  if (value is List) return value.map((item) => item.toString()).toList();
  return const [];
}
