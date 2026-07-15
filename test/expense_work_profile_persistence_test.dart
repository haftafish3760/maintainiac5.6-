import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/expenses/data/expense_work_profile_store.dart';

void main() {
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
}
