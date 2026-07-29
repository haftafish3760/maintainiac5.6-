import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_store.dart';
import 'package:maintaniac/screens/expenses/data/expense_work_profile_store.dart';

void main() {
  test('work-profile timestamps never move backward', () async {
    final profiles = ExpenseWorkProfileController.memory();
    final future = DateTime.utc(2099, 1, 1);
    final saved = await profiles.save(
      ExpenseWorkProfile(
        id: 'future-profile',
        name: 'Future profile',
        createdAt: future,
        updatedAt: future,
      ),
    );
    await profiles.delete(saved.id);
    final archived = profiles.profileById(saved.id)!;

    expect(saved.updatedAt, future);
    expect(archived.updatedAt, future.add(const Duration(microseconds: 1)));
    expect(archived.archivedAt, archived.updatedAt);
  });

  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'expense_work_profile_persistence_test_',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) await hiveDirectory.delete(recursive: true);
  });

  test('an archived work profile survives a local app restart', () async {
    final first = await ExpenseWorkProfileController.create();
    final profile = await first.save(
      ExpenseWorkProfile(
        id: 'seasonal-contract',
        name: 'Seasonal contract',
        createdAt: DateTime.utc(2026, 7, 15),
        updatedAt: DateTime.utc(2026, 7, 15),
      ),
    );
    await first.delete(profile.id);

    await Hive.close();
    Hive.init(hiveDirectory.path);
    final restored = await ExpenseWorkProfileController.create();

    expect(restored.profiles.any((item) => item.id == profile.id), isFalse);
    expect(restored.profileById(profile.id)?.name, 'Seasonal contract');
    expect(restored.profileById(profile.id)?.isArchived, isTrue);
  });

  test(
    'archiving the active profile durably returns to the default profile',
    () async {
      final first = await ExpenseWorkProfileController.create();
      final profile = await first.save(
        ExpenseWorkProfile(
          id: 'seasonal-contract',
          name: 'Seasonal contract',
          createdAt: DateTime.utc(2026, 7, 15),
          updatedAt: DateTime.utc(2026, 7, 15),
        ),
      );
      await first.select(profile.id);
      await first.delete(profile.id);

      await Hive.close();
      Hive.init(hiveDirectory.path);
      final restored = await ExpenseWorkProfileController.create();

      expect(
        restored.activeWorkProfile.id,
        ExpenseWorkProfileController.defaultProfileId,
      );
    },
  );

  test(
    'a corrupt work profile is ignored instead of being reconstructed',
    () async {
      await ExpenseWorkProfileController.create();
      final box = await Hive.openBox<dynamic>(
        ExpenseWorkProfileController.boxName,
      );
      await box.put('corrupt-profile', <String, Object?>{
        'id': 'corrupt-profile',
        'name': 'Corrupt profile',
        'createdAt': 'not-a-date',
        'updatedAt': 'not-a-date',
      });

      await Hive.close();
      Hive.init(hiveDirectory.path);
      final restored = await ExpenseWorkProfileController.create();

      expect(restored.profileById('corrupt-profile'), isNull);
      expect(
        restored.activeWorkProfile.id,
        ExpenseWorkProfileController.defaultProfileId,
      );
    },
  );

  test(
    'a historical receipt retains its archived work-profile identity',
    () async {
      final profiles = await ExpenseWorkProfileController.create();
      final profile = await profiles.save(
        ExpenseWorkProfile(
          id: 'seasonal-contract',
          name: 'Seasonal contract',
          createdAt: DateTime.utc(2026, 7, 15),
          updatedAt: DateTime.utc(2026, 7, 15),
        ),
      );
      final ledger = await ExpenseLedgerController.create();
      await ledger.saveReceipt(
        ExpenseReceiptRecord(
          id: 'seasonal-receipt',
          receiptDate: DateTime.utc(2026, 7, 15),
          workProfileId: profile.id,
          lines: const [
            ExpenseReceiptLineRecord(
              id: 'seasonal-line',
              description: 'Parking',
              category: 'Parking',
              use: ExpenseLineUse.business,
              quantity: 1,
              unitsPerPackage: 1,
              unit: 'each',
              subtotal: 12,
            ),
          ],
        ),
      );
      await profiles.delete(profile.id);

      await Hive.close();
      Hive.init(hiveDirectory.path);
      final restoredProfiles = await ExpenseWorkProfileController.create();
      final restoredLedger = await ExpenseLedgerController.create();

      expect(
        restoredLedger.receiptById('seasonal-receipt')?.workProfileId,
        profile.id,
      );
      expect(restoredProfiles.profileById(profile.id)?.isArchived, isTrue);
    },
  );
}
