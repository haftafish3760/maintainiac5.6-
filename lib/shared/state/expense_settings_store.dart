import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';

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

  List<String> get quickCategoryOrder =>
      _readStringList(_Keys.quickCategoryOrder);
  List<String> get topThreeCategories => _readStringList(
    _Keys.topThreeCategories,
    fallback: const ['Fuel', 'Food & Drinks', 'Materials'],
  );

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

  Future<void> resetCategoryLayout() async {
    await _box.delete(_Keys.quickCategoryOrder);
    await _box.put(_Keys.topThreeCategories, [
      'Fuel',
      'Food & Drinks',
      'Materials',
    ]);
    notifyListeners();
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
  static const quickCategoryOrder = 'quick_category_order';
  static const topThreeCategories = 'top_three_categories';
}
