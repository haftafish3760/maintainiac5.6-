import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/shared/state/expense_backup_schedule.dart';
import 'package:maintaniac/shared/state/expense_settings_store.dart';
import 'package:maintaniac/shared/storage/app_storage_guard.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'expense_settings_store_test_',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  test('quick category order saves without duplicates', () async {
    final settings = await ExpenseSettingsController.create();

    await settings.setQuickCategoryOrder([
      'Fuel',
      'fuel',
      'Materials',
      ' Materials ',
      'Parking',
    ]);

    expect(settings.quickCategoryOrder, ['Fuel', 'Materials', 'Parking']);
  });

  test(
    'scheduled backup choices persist without enabling automatic upload',
    () async {
      final settings = await ExpenseSettingsController.create();
      await settings.setBackupSchedule(
        ExpenseBackupSchedule.normalized(
          timesMinutesAfterMidnight: [17 * 60 + 30, -1, 8 * 60, 8 * 60],
          transport: ExpenseBackupTransport.wifiAndCellular,
        ),
      );

      expect(settings.backupSyncMode, ExpenseBackupSyncMode.manual);
      expect(settings.backupSchedule.timesMinutesAfterMidnight, [480, 1050]);
      expect(
        settings.backupSchedule.transport,
        ExpenseBackupTransport.wifiAndCellular,
      );
      expect(
        settings.toBackupMap(
          ownerUid: 'owner',
          exportedAtUtc: DateTime.utc(2026),
        )['backupScheduleTimesMinutes'],
        [480, 1050],
      );
    },
  );

  test('quick category add and remove update saved home buttons', () async {
    final settings = await ExpenseSettingsController.create();

    await settings.addQuickCategory('Fuel');
    await settings.addQuickCategory('Meals');
    await settings.addQuickCategory('fuel');
    await settings.removeQuickCategory('FUEL');

    expect(settings.quickCategoryOrder, ['Meals']);
  });

  test('queued category choices retain every user action', () async {
    final settings = await ExpenseSettingsController.create();

    await Future.wait([
      settings.addQuickCategory('Fuel'),
      settings.addQuickCategory('Meals'),
      settings.addQuickCategory('Parking'),
    ]);

    expect(settings.quickCategoryOrder, ['Fuel', 'Meals', 'Parking']);
  });

  test('settings do not claim a durable write when storage is full', () async {
    final settings = await ExpenseSettingsController.create(
      storageCheck: () async => const AppStorageCheck(
        availableBytes: 0,
        operationBytes: AppStorageGuard.smallRecordWriteBytes,
        requiredBytes: AppStorageGuard.smallRecordWriteBytes + 1,
        purpose: AppStoragePurpose.smallRecordWrite,
      ),
    );

    await expectLater(
      () => settings.addCustomCategory('Professional dues'),
      throwsA(isA<StateError>()),
    );
    expect(settings.customCategoryNames, isEmpty);
  });

  test(
    'custom categories persist and are included in backup settings',
    () async {
      final settings = await ExpenseSettingsController.create();

      expect(await settings.addCustomCategory('Professional dues'), isTrue);
      expect(
        await settings.addCustomCategory(' professional   dues '),
        isFalse,
      );
      expect(await settings.addCustomCategory(''), isFalse);
      expect(settings.customCategoryNames, ['Professional dues']);

      final restored = await ExpenseSettingsController.create();
      expect(restored.customCategoryNames, ['Professional dues']);
      expect(
        restored.toBackupMap(
          ownerUid: 'owner',
          exportedAtUtc: DateTime.utc(2026),
        ),
        containsPair('customCategoryNames', ['Professional dues']),
      );
    },
  );

  test(
    'legacy custom-category duplicates do not duplicate recaps or backup',
    () async {
      final box = await Hive.openBox<dynamic>(
        ExpenseSettingsController.boxName,
      );
      await box.put('custom_category_names', [
        'Professional dues',
        ' professional   dues ',
        'Vehicle wash',
        'VEHICLE-WASH',
      ]);
      final settings = await ExpenseSettingsController.create();

      expect(settings.customCategoryNames, [
        'Professional dues',
        'Vehicle wash',
      ]);
      expect(
        settings.toBackupMap(
          ownerUid: 'owner',
          exportedAtUtc: DateTime.utc(2026),
        )['customCategoryNames'],
        ['Professional dues', 'Vehicle wash'],
      );
    },
  );

  test('top three selection keeps the newest category first', () async {
    final settings = await ExpenseSettingsController.create();

    await settings.useCategoryInTopThree('Parking');

    expect(settings.topThreeCategories, ['Parking', 'Fuel', 'Meals']);
  });

  test('reset restores release defaults', () async {
    final settings = await ExpenseSettingsController.create();

    await settings.setQuickCategoryOrder(['Parking', 'Tolls']);
    await settings.useCategoryInTopThree('Parking');
    await settings.resetCategoryLayout();

    expect(settings.quickCategoryOrder, isEmpty);
    expect(settings.topThreeCategories, ['Fuel', 'Meals', 'Materials']);
  });

  test('recap tiles are visible by default and can be hidden', () async {
    final settings = await ExpenseSettingsController.create();

    expect(settings.recapTileVisible('fuelSpend'), isTrue);
    expect(settings.hiddenRecapTiles, isEmpty);

    await settings.setRecapTileVisible('fuelSpend', false);

    expect(settings.recapTileVisible('fuelSpend'), isFalse);
    expect(settings.hiddenRecapTiles, ['fuelSpend']);

    await settings.setRecapTileVisible('fuelSpend', true);

    expect(settings.recapTileVisible('fuelSpend'), isTrue);
    expect(settings.hiddenRecapTiles, isEmpty);
  });

  test('recap tile reset shows everything again', () async {
    final settings = await ExpenseSettingsController.create();

    await settings.setRecapTileVisible('fuelSpend', false);
    await settings.setRecapTileVisible('materialsSpend', false);
    await settings.resetRecapTiles();

    expect(settings.hiddenRecapTiles, isEmpty);
    expect(settings.recapTileVisible('fuelSpend'), isTrue);
    expect(settings.recapTileVisible('materialsSpend'), isTrue);
  });

  test('receipt review style saves the expense receipt default', () async {
    final settings = await ExpenseSettingsController.create();

    expect(
      settings.receiptReviewStyle,
      ExpenseReceiptReviewStyle.simpleAmounts,
    );
    expect(ExpenseReceiptReviewStyle.basicReceipt.label, 'Quick total');
    expect(ExpenseReceiptReviewStyle.simpleAmounts.label, 'Category summary');
    expect(ExpenseReceiptReviewStyle.fullItemDetails.label, 'Detailed receipt');

    await settings.setReceiptReviewStyle(
      ExpenseReceiptReviewStyle.fullItemDetails,
    );

    expect(
      settings.receiptReviewStyle,
      ExpenseReceiptReviewStyle.fullItemDetails,
    );
    expect(
      settings.toBackupMap(
        ownerUid: 'owner',
        exportedAtUtc: DateTime.utc(2026),
      ),
      containsPair('receiptReviewStyle', 'fullItemDetails'),
    );
  });

  test('receipt review style restores padded and case-varied values', () {
    expect(
      ExpenseReceiptReviewStyle.fromName(' basicReceipt '),
      ExpenseReceiptReviewStyle.basicReceipt,
    );
    expect(
      ExpenseReceiptReviewStyle.fromName(' fullItemDetails '),
      ExpenseReceiptReviewStyle.fullItemDetails,
    );
    expect(
      ExpenseReceiptReviewStyle.fromName('FULLITEMDETAILS'),
      ExpenseReceiptReviewStyle.fullItemDetails,
    );
    expect(
      ExpenseReceiptReviewStyle.fromName('simpleAmounts'),
      ExpenseReceiptReviewStyle.simpleAmounts,
    );
    expect(
      ExpenseReceiptReviewStyle.fromName('unknown'),
      ExpenseReceiptReviewStyle.simpleAmounts,
    );
  });

  test('backup sync is manual until the user chooses another mode', () async {
    final settings = await ExpenseSettingsController.create();

    expect(settings.backupSyncMode, ExpenseBackupSyncMode.manual);
    await settings.setBackupSchedule(
      ExpenseBackupSchedule.normalized(
        timesMinutesAfterMidnight: [8 * 60],
        transport: ExpenseBackupTransport.wifiOnly,
      ),
    );
    await settings.setBackupSyncMode(
      ExpenseBackupSyncMode.scheduled,
      nowUtc: DateTime.utc(2026, 7, 15, 11),
    );

    expect(settings.backupSyncMode, ExpenseBackupSyncMode.scheduled);
    expect(settings.backupScheduleAuthorizedAt, DateTime.utc(2026, 7, 15, 11));
    expect(
      settings.isScheduledBackupDueAt(DateTime.utc(2026, 7, 15, 13)),
      isTrue,
    );
    expect(
      settings.toBackupMap(
        ownerUid: 'owner',
        exportedAtUtc: DateTime.utc(2026),
      ),
      containsPair('backupSyncMode', 'scheduled'),
    );
    await settings.setBackupSyncMode(ExpenseBackupSyncMode.manual);
    expect(settings.backupScheduleAuthorizedAt, isNull);
    expect(
      settings.isScheduledBackupDueAt(DateTime.utc(2026, 7, 16, 9)),
      isFalse,
    );
  });

  test(
    'backup activity status stays local while persisting across restart',
    () async {
      final settings = await ExpenseSettingsController.create();
      final attemptedAt = DateTime.utc(2026, 7, 15, 12);
      final successfulAt = DateTime.utc(2026, 7, 15, 12, 5);

      await settings.recordBackupAttempt(attemptedAt);
      await settings.recordSuccessfulBackup(successfulAt);
      final reopened = await ExpenseSettingsController.create();

      expect(reopened.lastBackupAttemptAt, attemptedAt);
      expect(reopened.lastSuccessfulBackupAt, successfulAt);
      await reopened.recordBackupFailure('Temporary network issue');
      expect(reopened.backupRetryPending, isTrue);
      expect(reopened.lastBackupFailureReason, 'Temporary network issue');
      await reopened.recordSuccessfulBackup(
        successfulAt.add(const Duration(minutes: 1)),
      );
      expect(reopened.backupRetryPending, isFalse);
      expect(reopened.lastBackupFailureReason, isNull);
      expect(
        reopened
            .toBackupMap(ownerUid: 'owner', exportedAtUtc: DateTime.utc(2026))
            .keys,
        isNot(contains('lastBackupAttemptAt')),
      );
    },
  );

  test('backup activity timestamps never move backward', () async {
    final settings = await ExpenseSettingsController.create();
    final latest = DateTime.utc(2026, 7, 15, 12, 5);
    final earlier = latest.subtract(const Duration(minutes: 1));

    await settings.recordBackupAttempt(latest);
    await settings.recordBackupAttempt(earlier);
    await settings.recordSuccessfulBackup(latest);
    await settings.recordSuccessfulBackup(earlier);

    expect(settings.lastBackupAttemptAt, latest);
    expect(settings.lastSuccessfulBackupAt, latest);
  });

  test(
    'receipt review style ignores corrupted non-string storage values',
    () async {
      final settings = await ExpenseSettingsController.create();
      final box = Hive.box<dynamic>(ExpenseSettingsController.boxName);

      await box.put('receiptReviewStyle', 17);

      expect(
        settings.receiptReviewStyle,
        ExpenseReceiptReviewStyle.simpleAmounts,
      );
    },
  );

  test(
    'expense settings scope can be optional for shared receipt widgets',
    () async {
      final source = await File(
        'lib/shared/state/expense_settings_scope.dart',
      ).readAsString();

      expect(source, contains('static ExpenseSettingsController? maybeOf'));
      expect(
        source,
        contains(
          'getElementForInheritedWidgetOfExactType<ExpenseSettingsScope>',
        ),
      );
    },
  );
}
