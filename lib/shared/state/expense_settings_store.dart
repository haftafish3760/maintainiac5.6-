import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'expense_backup_schedule.dart';
import 'expense_settings_write_queue.dart';

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
      ExpenseReceiptReviewStyle.fullItemDetails => 'Detailed receipt review',
    };
  }

  String get description {
    return switch (this) {
      ExpenseReceiptReviewStyle.basicReceipt =>
        'Price-only review. Keep the receipt proof and review the store, date, sales tax, and final total without item descriptions.',
      ExpenseReceiptReviewStyle.simpleAmounts =>
        'Single-total review. Keep the receipt proof and record the final total after sales tax as all Business or all Personal.',
      ExpenseReceiptReviewStyle.fullItemDetails =>
        'Detailed review. Preserve and review each meaningful receipt line exactly as printed, including quantities, prices, discounts, and totals.',
    };
  }
}

/// Determines whether a user-approved Expense backup may leave the device.
/// Manual is the safe default; records always save locally regardless.
enum ExpenseBackupSyncMode {
  manual,
  scheduled,
  immediate;

  static ExpenseBackupSyncMode fromName(String? value) {
    return switch (value?.trim().toLowerCase()) {
      'scheduled' => ExpenseBackupSyncMode.scheduled,
      'immediate' => ExpenseBackupSyncMode.immediate,
      _ => ExpenseBackupSyncMode.manual,
    };
  }
}

class ExpenseSettingsController extends ChangeNotifier {
  ExpenseSettingsController._(
    this._box, {
    ExpenseSettingsStorageCheck? storageCheck,
  }) : _writes = ExpenseSettingsWriteQueue(storageCheck);

  static const boxName = 'expense_settings';

  static Future<ExpenseSettingsController> create({
    ExpenseSettingsStorageCheck? storageCheck,
  }) async {
    final box = await Hive.openBox<dynamic>(boxName);
    return ExpenseSettingsController._(box, storageCheck: storageCheck);
  }

  final Box<dynamic> _box;
  final ExpenseSettingsWriteQueue _writes;

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

  ExpenseBackupSyncMode get backupSyncMode {
    final value = _box.get(_Keys.backupSyncMode);
    return ExpenseBackupSyncMode.fromName(value is String ? value : null);
  }

  ExpenseBackupSchedule get backupSchedule => ExpenseBackupSchedule.normalized(
    timesMinutesAfterMidnight: _readIntList(_Keys.backupScheduleTimes),
    transport: ExpenseBackupTransport.fromName(
      _box.get(_Keys.backupTransport) as String?,
    ),
  );

  /// Local-only timestamp for the current scheduled-backup authorization.
  /// It is intentionally not restored on another device, where the user must
  /// make a fresh choice before any automatic transfer can occur.
  DateTime? get backupScheduleAuthorizedAt {
    return _readUtcDateTime(_Keys.backupScheduleAuthorizedAt);
  }

  /// Device-local backup activity status. It is never restored onto another
  /// device, because restore must not masquerade as a successful new-device
  /// backup or authorize a future automatic transfer.
  DateTime? get lastBackupAttemptAt =>
      _readUtcDateTime(_Keys.lastBackupAttemptAt);
  DateTime? get lastSuccessfulBackupAt =>
      _readUtcDateTime(_Keys.lastSuccessfulBackupAt);
  String? get lastBackupFailureReason {
    final value = _box.get(_Keys.lastBackupFailureReason);
    if (value is! String || value.trim().isEmpty) return null;
    return value.trim();
  }

  bool get backupRetryPending => lastBackupFailureReason != null;

  bool isScheduledBackupDueAt(DateTime now, {DateTime? lastAttemptAt}) {
    if (backupSyncMode != ExpenseBackupSyncMode.scheduled) return false;
    return backupSchedule.isDueAt(
      now.toLocal(),
      lastAttemptAt: lastAttemptAt?.toLocal(),
      authorizationBeganAt: backupScheduleAuthorizedAt?.toLocal(),
    );
  }

  List<String> get quickCategoryOrder =>
      _readStringList(_Keys.quickCategoryOrder);
  List<String> get topThreeCategories => _readStringList(
    _Keys.topThreeCategories,
    fallback: const ['Fuel', 'Meals', 'Materials'],
  );
  List<String> get hiddenRecapTiles => _readStringList(_Keys.hiddenRecapTiles);
  List<String> get customCategoryNames =>
      _uniqueCategories(_readStringList(_Keys.customCategoryNames));
  bool get odometerPromptEnabled =>
      _readBool(_Keys.odometerPromptEnabled, true);
  List<String> get odometerPromptSuppressedCategories =>
      _readStringList(_Keys.odometerPromptSuppressedCategories);

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
      'backupSyncMode': backupSyncMode.name,
      'backupScheduleTimesMinutes': backupSchedule.timesMinutesAfterMidnight,
      'backupTransport': backupSchedule.transport.name,
      'quickCategoryOrder': quickCategoryOrder,
      'topThreeCategories': topThreeCategories,
      'hiddenRecapTiles': hiddenRecapTiles,
      'customCategoryNames': customCategoryNames,
      'odometerPromptEnabled': odometerPromptEnabled,
      'odometerPromptSuppressedCategories': odometerPromptSuppressedCategories,
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
  Future<void> setReceiptReviewStyle(ExpenseReceiptReviewStyle value) =>
      _writes.enqueue(() async {
        await _box.put(_Keys.receiptReviewStyle, value.name);
        notifyListeners();
      });

  Future<void> setBackupSyncMode(
    ExpenseBackupSyncMode value, {
    DateTime? nowUtc,
  }) => _writes.enqueue(() async {
    final wasScheduled = backupSyncMode == ExpenseBackupSyncMode.scheduled;
    await _box.put(_Keys.backupSyncMode, value.name);
    if (value == ExpenseBackupSyncMode.scheduled && !wasScheduled) {
      await _box.put(
        _Keys.backupScheduleAuthorizedAt,
        (nowUtc ?? DateTime.now().toUtc()).toUtc().toIso8601String(),
      );
    } else if (value != ExpenseBackupSyncMode.scheduled) {
      await _box.delete(_Keys.backupScheduleAuthorizedAt);
    }
    notifyListeners();
  });

  Future<void> setBackupSchedule(ExpenseBackupSchedule value) =>
      _writes.enqueue(() async {
        final normalized = ExpenseBackupSchedule.normalized(
          timesMinutesAfterMidnight: value.timesMinutesAfterMidnight,
          transport: value.transport,
        );
        await _box.put(
          _Keys.backupScheduleTimes,
          normalized.timesMinutesAfterMidnight,
        );
        await _box.put(_Keys.backupTransport, normalized.transport.name);
        notifyListeners();
      });

  Future<void> recordBackupAttempt(DateTime atUtc) =>
      _writeUtcDateTime(_Keys.lastBackupAttemptAt, atUtc);

  Future<void> recordSuccessfulBackup(DateTime atUtc) =>
      _recordSuccessfulBackup(atUtc);

  Future<void> recordBackupFailure(String? reason) => _writes.enqueue(() async {
    final normalized = reason?.trim() ?? '';
    if (normalized.isEmpty) return;
    await _box.put(
      _Keys.lastBackupFailureReason,
      normalized.length <= 240 ? normalized : normalized.substring(0, 240),
    );
    notifyListeners();
  });

  Future<void> setOdometerPromptEnabled(bool value) =>
      _writeBool(_Keys.odometerPromptEnabled, value);

  bool shouldPromptForOdometer(String category) {
    return odometerPromptEnabled &&
        !_containsCategory(odometerPromptSuppressedCategories, category);
  }

  Future<void> setOdometerPromptSuppressed(String category, bool suppressed) =>
      _writes.enqueue(() async {
        final normalized = category.trim();
        if (normalized.isEmpty) return;
        final current = [...odometerPromptSuppressedCategories];
        current.removeWhere((item) => _sameCategory(item, normalized));
        if (suppressed) current.add(normalized);
        await _box.put(
          _Keys.odometerPromptSuppressedCategories,
          _uniqueCategories(current),
        );
        notifyListeners();
      });

  Future<void> setQuickCategoryOrder(List<String> categories) =>
      _writes.enqueue(() => _setQuickCategoryOrder(categories));

  Future<void> _setQuickCategoryOrder(List<String> categories) async {
    final normalized = _uniqueCategories(categories);
    await _box.put(_Keys.quickCategoryOrder, normalized);
    notifyListeners();
  }

  Future<void> addQuickCategory(String category, {int maxCategories = 9}) =>
      _writes.enqueue(() async {
        final current = [...quickCategoryOrder];
        if (_containsCategory(current, category) ||
            current.length >= maxCategories) {
          return;
        }
        current.add(category);
        await _setQuickCategoryOrder(current);
      });

  Future<void> removeQuickCategory(String category) =>
      _writes.enqueue(() async {
        final current = quickCategoryOrder
            .where((item) => !_sameCategory(item, category))
            .toList(growable: false);
        await _setQuickCategoryOrder(current);
      });

  /// Adds a user-owned category without changing historical receipt text.
  /// Categories remain strings on saved receipt lines so recaps preserve them.
  Future<bool> addCustomCategory(String category) => _writes.enqueue(() async {
    final normalized = _normalizedCategoryName(category);
    if (normalized == null ||
        _containsCategory(customCategoryNames, normalized)) {
      return false;
    }
    await _box.put(_Keys.customCategoryNames, [
      ...customCategoryNames,
      normalized,
    ]);
    notifyListeners();
    return true;
  });

  Future<void> removeCustomCategory(String category) =>
      _writes.enqueue(() async {
        final remaining = customCategoryNames
            .where((item) => !_sameCategory(item, category))
            .toList(growable: false);
        await _box.put(_Keys.customCategoryNames, remaining);
        notifyListeners();
      });

  Future<void> setTopThreeCategories(List<String> categories) =>
      _writes.enqueue(() => _setTopThreeCategories(categories));

  Future<void> _setTopThreeCategories(List<String> categories) async {
    final normalized = _uniqueCategories(categories).take(3).toList();
    await _box.put(_Keys.topThreeCategories, normalized);
    notifyListeners();
  }

  Future<void> setRecapTileVisible(String tileId, bool visible) =>
      _writes.enqueue(() async {
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
      });

  Future<void> resetRecapTiles() => _writes.enqueue(() async {
    await _box.delete(_Keys.hiddenRecapTiles);
    notifyListeners();
  });

  Future<void> useCategoryInTopThree(String category) =>
      _writes.enqueue(() async {
        final current = [
          category,
          ...topThreeCategories.where((item) => !_sameCategory(item, category)),
        ].take(3).toList();
        await _setTopThreeCategories(current);
      });

  Future<void> resetCategoryLayout() => _writes.enqueue(() async {
    await _box.delete(_Keys.quickCategoryOrder);
    await _box.put(_Keys.topThreeCategories, ['Fuel', 'Meals', 'Materials']);
    notifyListeners();
  });

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

  String? _normalizedCategoryName(String value) {
    final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty || normalized.length > 60) return null;
    return normalized;
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

  List<int> _readIntList(String key) {
    final value = _box.get(key);
    if (value is! List) return const [];
    return value
        .whereType<num>()
        .map((item) => item.toInt())
        .toList(growable: false);
  }

  DateTime? _readUtcDateTime(String key) {
    final value = _box.get(key);
    if (value is! String) return null;
    return DateTime.tryParse(value)?.toUtc();
  }

  Future<void> _writeUtcDateTime(String key, DateTime value) async {
    await _writes.enqueue(() async {
      await _box.put(key, value.toUtc().toIso8601String());
      notifyListeners();
    });
  }

  Future<void> _recordSuccessfulBackup(DateTime atUtc) async {
    await _writes.enqueue(() async {
      await _box.put(
        _Keys.lastSuccessfulBackupAt,
        atUtc.toUtc().toIso8601String(),
      );
      await _box.delete(_Keys.lastBackupFailureReason);
      notifyListeners();
    });
  }

  Future<void> _writeBool(String key, bool value) async {
    await _writes.enqueue(() async {
      await _box.put(key, value);
      notifyListeners();
    });
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
  static const backupSyncMode = 'expense_backup_sync_mode';
  static const backupScheduleTimes = 'expense_backup_schedule_times';
  static const backupTransport = 'expense_backup_transport';
  static const backupScheduleAuthorizedAt =
      'expense_backup_schedule_authorized_at';
  static const lastBackupAttemptAt = 'expense_last_backup_attempt_at';
  static const lastSuccessfulBackupAt = 'expense_last_successful_backup_at';
  static const lastBackupFailureReason = 'expense_last_backup_failure_reason';
  static const odometerPromptEnabled = 'expense_odometer_prompt_enabled';
  static const odometerPromptSuppressedCategories =
      'expense_odometer_prompt_suppressed_categories';
  static const quickCategoryOrder = 'quick_category_order';
  static const topThreeCategories = 'top_three_categories';
  static const hiddenRecapTiles = 'hidden_recap_tiles';
  static const customCategoryNames = 'custom_category_names';
}
