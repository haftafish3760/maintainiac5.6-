import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';

enum ExpenseReceiptReviewStyle {
  basicReceipt,
  simpleAmounts,
  fullItemDetails;

  static ExpenseReceiptReviewStyle fromName(String? value) {
    final normalized = value?.trim().toLowerCase();
    return switch (normalized) {
      'basicreceipt' => ExpenseReceiptReviewStyle.basicReceipt,
      'fullitemdetails' => ExpenseReceiptReviewStyle.fullItemDetails,
      _ => ExpenseReceiptReviewStyle.simpleAmounts,
    };
  }

  String get label {
    return switch (this) {
      ExpenseReceiptReviewStyle.basicReceipt => 'Basic receipt review',
      ExpenseReceiptReviewStyle.simpleAmounts => 'Simple receipt review',
      ExpenseReceiptReviewStyle.fullItemDetails => 'Full item detail review',
    };
  }

  String get description {
    return switch (this) {
      ExpenseReceiptReviewStyle.basicReceipt =>
        'Fastest. Keep the receipt proof and review the store, date, category, and total without item lines.',
      ExpenseReceiptReviewStyle.simpleAmounts =>
        'Fastest. Keep the receipt photo as proof, review each detected amount, and mark it Business, Personal, or Split.',
      ExpenseReceiptReviewStyle.fullItemDetails =>
        'Best when you need item names, quantities, fuel details, materials, packages, or inventory tracking.',
    };
  }
}

class ExpenseSettingsController extends ChangeNotifier {
  ExpenseSettingsController._(this._box);

  static const boxName = 'expense_settings';

  static Future<ExpenseSettingsController> create() async {
    final box = await Hive.openBox<dynamic>(boxName);
    return ExpenseSettingsController._(box);
  }

  final Box<dynamic> _box;

  bool get autoTrackTopThree => _readBool(_Keys.autoTrackTopThree, false);
  bool get autoTrackQuickCategories =>
      _readBool(_Keys.autoTrackQuickCategories, false);
  bool get confirmOcrTotals => _readBool(_Keys.confirmOcrTotals, true);
  bool get allowMultipleReceiptPhotos =>
      _readBool(_Keys.allowMultipleReceiptPhotos, true);
  bool get saveOptimizedReceiptCopy =>
      _readBool(_Keys.saveOptimizedReceiptCopy, true);
  bool get inAppNotifications => _readBool(_Keys.inAppNotifications, true);
  bool get pushNotifications => _readBool(_Keys.pushNotifications, false);
  bool get audibleNotifications => _readBool(_Keys.audibleNotifications, false);
  bool get draftReminder => _readBool(_Keys.draftReminder, true);
  ExpenseReceiptReviewStyle get receiptReviewStyle {
    final value = _box.get(_Keys.receiptReviewStyle);
    return ExpenseReceiptReviewStyle.fromName(value is String ? value : null);
  }

  List<String> get quickCategoryOrder =>
      _readStringList(_Keys.quickCategoryOrder);
  List<String> get topThreeCategories => _readStringList(
    _Keys.topThreeCategories,
    fallback: const ['Fuel', 'Meals', 'Materials'],
  );
  List<String> get hiddenRecapTiles => _readStringList(_Keys.hiddenRecapTiles);

  Map<String, Object?> toBackupMap({
    required String ownerUid,
    required DateTime exportedAtUtc,
  }) {
    return {
      'schema': 'expense_settings_v1',
      'ownerUid': ownerUid,
      'exportedAtUtc': exportedAtUtc.toUtc().toIso8601String(),
      'autoTrackTopThree': autoTrackTopThree,
      'autoTrackQuickCategories': autoTrackQuickCategories,
      'confirmOcrTotals': confirmOcrTotals,
      'allowMultipleReceiptPhotos': allowMultipleReceiptPhotos,
      'saveOptimizedReceiptCopy': saveOptimizedReceiptCopy,
      'inAppNotifications': inAppNotifications,
      'pushNotifications': pushNotifications,
      'audibleNotifications': audibleNotifications,
      'draftReminder': draftReminder,
      'receiptReviewStyle': receiptReviewStyle.name,
      'quickCategoryOrder': quickCategoryOrder,
      'topThreeCategories': topThreeCategories,
      'hiddenRecapTiles': hiddenRecapTiles,
    };
  }

  bool recapTileVisible(String tileId) {
    return !hiddenRecapTiles.contains(tileId);
  }

  Future<void> setAutoTrackTopThree(bool value) =>
      _writeBool(_Keys.autoTrackTopThree, value);
  Future<void> setAutoTrackQuickCategories(bool value) =>
      _writeBool(_Keys.autoTrackQuickCategories, value);
  Future<void> setConfirmOcrTotals(bool value) =>
      _writeBool(_Keys.confirmOcrTotals, value);
  Future<void> setAllowMultipleReceiptPhotos(bool value) =>
      _writeBool(_Keys.allowMultipleReceiptPhotos, value);
  Future<void> setSaveOptimizedReceiptCopy(bool value) =>
      _writeBool(_Keys.saveOptimizedReceiptCopy, value);
  Future<void> setInAppNotifications(bool value) =>
      _writeBool(_Keys.inAppNotifications, value);
  Future<void> setPushNotifications(bool value) =>
      _writeBool(_Keys.pushNotifications, value);
  Future<void> setAudibleNotifications(bool value) =>
      _writeBool(_Keys.audibleNotifications, value);
  Future<void> setDraftReminder(bool value) =>
      _writeBool(_Keys.draftReminder, value);
  Future<void> setReceiptReviewStyle(ExpenseReceiptReviewStyle value) async {
    await _box.put(_Keys.receiptReviewStyle, value.name);
    notifyListeners();
  }

  Future<void> setQuickCategoryOrder(List<String> categories) async {
    final normalized = _uniqueCategories(categories);
    await _box.put(_Keys.quickCategoryOrder, normalized);
    notifyListeners();
  }

  Future<void> addQuickCategory(
    String category, {
    int maxCategories = 9,
  }) async {
    final current = [...quickCategoryOrder];
    if (_containsCategory(current, category) ||
        current.length >= maxCategories) {
      return;
    }
    current.add(category);
    await setQuickCategoryOrder(current);
  }

  Future<void> removeQuickCategory(String category) async {
    final current = quickCategoryOrder
        .where((item) => !_sameCategory(item, category))
        .toList(growable: false);
    await setQuickCategoryOrder(current);
  }

  Future<void> setTopThreeCategories(List<String> categories) async {
    final normalized = _uniqueCategories(categories).take(3).toList();
    await _box.put(_Keys.topThreeCategories, normalized);
    notifyListeners();
  }

  Future<void> setRecapTileVisible(String tileId, bool visible) async {
    final clean = tileId.trim();
    if (clean.isEmpty) return;
    final hidden = [...hiddenRecapTiles];
    if (visible) {
      hidden.removeWhere((item) => item == clean);
    } else if (!hidden.contains(clean)) {
      hidden.add(clean);
    }
    await _box.put(_Keys.hiddenRecapTiles, List.unmodifiable(hidden));
    notifyListeners();
  }

  Future<void> resetRecapTiles() async {
    await _box.delete(_Keys.hiddenRecapTiles);
    notifyListeners();
  }

  Future<void> useCategoryInTopThree(String category) async {
    final current = [
      category,
      ...topThreeCategories.where((item) => !_sameCategory(item, category)),
    ].take(3).toList();
    await setTopThreeCategories(current);
  }

  Future<void> resetCategoryLayout() async {
    await _box.delete(_Keys.quickCategoryOrder);
    await _box.put(_Keys.topThreeCategories, ['Fuel', 'Meals', 'Materials']);
    notifyListeners();
  }

  List<String> _uniqueCategories(List<String> categories) {
    final output = <String>[];
    for (final category in categories) {
      final trimmed = category.trim();
      if (trimmed.isEmpty || _containsCategory(output, trimmed)) continue;
      output.add(trimmed);
    }
    return List.unmodifiable(output);
  }

  bool _containsCategory(List<String> categories, String category) {
    return categories.any((item) => _sameCategory(item, category));
  }

  bool _sameCategory(String left, String right) {
    return _categoryKey(left) == _categoryKey(right);
  }

  String _categoryKey(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  }

  bool _readBool(String key, bool fallback) {
    final value = _box.get(key);
    return value is bool ? value : fallback;
  }

  List<String> _readStringList(String key, {List<String> fallback = const []}) {
    final value = _box.get(key);
    if (value is List) {
      return value.whereType<String>().toList(growable: false);
    }
    return List.unmodifiable(fallback);
  }

  Future<void> _writeBool(String key, bool value) async {
    await _box.put(key, value);
    notifyListeners();
  }
}

class ExpenseSettingsScope
    extends InheritedNotifier<ExpenseSettingsController> {
  const ExpenseSettingsScope({
    super.key,
    required ExpenseSettingsController controller,
    required super.child,
  }) : super(notifier: controller);

  static ExpenseSettingsController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<ExpenseSettingsScope>();
    assert(
      scope != null,
      'ExpenseSettingsScope is missing above this context.',
    );
    return scope!.notifier!;
  }

  static ExpenseSettingsController? maybeOf(BuildContext context) {
    try {
      final widget = context
          .getElementForInheritedWidgetOfExactType<ExpenseSettingsScope>()
          ?.widget;
      return widget is ExpenseSettingsScope ? widget.notifier : null;
    } on FlutterError {
      return null;
    }
  }
}

class _Keys {
  const _Keys._();

  static const autoTrackTopThree = 'auto_track_top_three';
  static const autoTrackQuickCategories = 'auto_track_quick_categories';
  static const confirmOcrTotals = 'confirm_ocr_totals';
  static const allowMultipleReceiptPhotos = 'allow_multiple_receipt_photos';
  static const saveOptimizedReceiptCopy = 'save_optimized_receipt_copy';
  static const inAppNotifications = 'in_app_notifications';
  static const pushNotifications = 'push_notifications';
  static const audibleNotifications = 'audible_notifications';
  static const draftReminder = 'draft_reminder';
  static const receiptReviewStyle = 'receipt_review_style';
  static const quickCategoryOrder = 'quick_category_order';
  static const topThreeCategories = 'top_three_categories';
  static const hiddenRecapTiles = 'hidden_recap_tiles';
}
