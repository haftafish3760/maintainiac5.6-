import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'work_supply_models.dart';

class WorkSupplyInventorySettingsController extends ChangeNotifier {
  WorkSupplyInventorySettingsController._(this._box);

  static const boxName = 'work_supply_inventory_settings';

  final Box<dynamic> _box;

  static Future<WorkSupplyInventorySettingsController> create() async {
    final box = await Hive.openBox<dynamic>(boxName);
    return WorkSupplyInventorySettingsController._(box);
  }

  bool get appAssistedReceipts => _readBool(_Keys.appAssistedReceipts, false);
  bool get localOnlyReceiptAssistance =>
      _readBool(_Keys.localOnlyReceiptAssistance, true);
  bool get hasSeenWorkSupplyIntro =>
      _readBool(_Keys.hasSeenWorkSupplyIntro, false);
  bool get showOnlyFollowedCatalog =>
      _readBool(_Keys.showOnlyFollowedCatalog, false);
  bool get showHiddenCatalogItems =>
      _readBool(_Keys.showHiddenCatalogItems, false);

  Set<String> get followedTrades => _readStringSet(_Keys.followedTrades);
  Set<String> get hiddenTrades => _readStringSet(_Keys.hiddenTrades);
  Set<String> get followedCategories =>
      _readStringSet(_Keys.followedCategories);
  Set<String> get hiddenCategories => _readStringSet(_Keys.hiddenCategories);
  Set<String> get followedItems => _readStringSet(_Keys.followedItems);
  Set<String> get hiddenItems => _readStringSet(_Keys.hiddenItems);

  Future<void> setAppAssistedReceipts(bool value) =>
      _writeBool(_Keys.appAssistedReceipts, value);
  Future<void> setLocalOnlyReceiptAssistance(bool value) =>
      _writeBool(_Keys.localOnlyReceiptAssistance, value);
  Future<void> setHasSeenWorkSupplyIntro(bool value) =>
      _writeBool(_Keys.hasSeenWorkSupplyIntro, value);
  Future<void> setShowOnlyFollowedCatalog(bool value) =>
      _writeBool(_Keys.showOnlyFollowedCatalog, value);
  Future<void> setShowHiddenCatalogItems(bool value) =>
      _writeBool(_Keys.showHiddenCatalogItems, value);

  bool followsTrade(String trade) => followedTrades.contains(trade.trim());
  bool hidesTrade(String trade) => hiddenTrades.contains(trade.trim());

  bool followsCategory(String trade, String category) {
    return followedCategories.contains(workSupplyCategoryKey(trade, category));
  }

  bool hidesCategory(String trade, String category) {
    return hiddenCategories.contains(workSupplyCategoryKey(trade, category));
  }

  bool followsItem(WorkSupplyItem item) => followedItems.contains(item.id);
  bool hidesItem(WorkSupplyItem item) => hiddenItems.contains(item.id);

  bool itemIsVisible(WorkSupplyItem item) {
    if (showHiddenCatalogItems) return true;
    if (hidesTrade(item.trade) ||
        hidesCategory(item.trade, item.category) ||
        hidesItem(item)) {
      return false;
    }
    if (!showOnlyFollowedCatalog) return true;
    return followsTrade(item.trade) ||
        followsCategory(item.trade, item.category) ||
        followsItem(item);
  }

  Future<void> setTradeFollowed(String trade, bool value) {
    return _toggleString(_Keys.followedTrades, trade.trim(), value);
  }

  Future<void> setTradeHidden(String trade, bool value) async {
    await _toggleString(_Keys.hiddenTrades, trade.trim(), value);
    if (value) await setTradeFollowed(trade, false);
  }

  Future<void> setCategoryFollowed(String trade, String category, bool value) {
    return _toggleString(
      _Keys.followedCategories,
      workSupplyCategoryKey(trade, category),
      value,
    );
  }

  Future<void> setCategoryHidden(
    String trade,
    String category,
    bool value,
  ) async {
    final key = workSupplyCategoryKey(trade, category);
    await _toggleString(_Keys.hiddenCategories, key, value);
    if (value) await _toggleString(_Keys.followedCategories, key, false);
  }

  Future<void> setItemFollowed(WorkSupplyItem item, bool value) {
    return _toggleString(_Keys.followedItems, item.id, value);
  }

  Future<void> setItemHidden(WorkSupplyItem item, bool value) async {
    await _toggleString(_Keys.hiddenItems, item.id, value);
    if (value) await setItemFollowed(item, false);
  }

  Future<void> resetCatalogPreferences() async {
    await _box.delete(_Keys.followedTrades);
    await _box.delete(_Keys.hiddenTrades);
    await _box.delete(_Keys.followedCategories);
    await _box.delete(_Keys.hiddenCategories);
    await _box.delete(_Keys.followedItems);
    await _box.delete(_Keys.hiddenItems);
    notifyListeners();
  }

  bool _readBool(String key, bool fallback) {
    final value = _box.get(key);
    return value is bool ? value : fallback;
  }

  Set<String> _readStringSet(String key) {
    final value = _box.get(key);
    if (value is List) {
      return value.whereType<String>().map((entry) => entry.trim()).toSet();
    }
    return <String>{};
  }

  Future<void> _writeBool(String key, bool value) async {
    await _box.put(key, value);
    notifyListeners();
  }

  Future<void> _toggleString(String key, String value, bool enabled) async {
    if (value.isEmpty) return;
    final values = _readStringSet(key);
    if (enabled) {
      values.add(value);
    } else {
      values.remove(value);
    }
    await _box.put(key, values.toList()..sort());
    notifyListeners();
  }
}

String workSupplyCategoryKey(String trade, String category) {
  return '${trade.trim()} > ${category.trim()}';
}

class _Keys {
  const _Keys._();

  static const appAssistedReceipts = 'app_assisted_receipts';
  static const localOnlyReceiptAssistance = 'local_only_receipt_assistance';
  static const hasSeenWorkSupplyIntro = 'has_seen_work_supply_intro';
  static const showOnlyFollowedCatalog = 'show_only_followed_catalog';
  static const showHiddenCatalogItems = 'show_hidden_catalog_items';
  static const followedTrades = 'followed_trades';
  static const hiddenTrades = 'hidden_trades';
  static const followedCategories = 'followed_categories';
  static const hiddenCategories = 'hidden_categories';
  static const followedItems = 'followed_items';
  static const hiddenItems = 'hidden_items';
}
