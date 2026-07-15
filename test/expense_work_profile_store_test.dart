import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/expenses/data/expense_work_profile_store.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'expense_work_profile_store_test_',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  test(
    'keeps a durable default and archives only non-default profiles',
    () async {
      final profiles = await ExpenseWorkProfileController.create();
      expect(profiles.activeProfiles.single.id, 'main-work');

      final now = DateTime(2026, 7, 15);
      final delivery = await profiles.save(
        ExpenseWorkProfileRecord(
          id: '',
          name: 'Delivery work',
          createdAt: now,
          updatedAt: now,
        ),
      );
      expect(profiles.profileById(delivery.id)?.name, 'Delivery work');
      expect(await profiles.archive('main-work'), isNull);
      expect((await profiles.archive(delivery.id))?.archived, isTrue);
      expect(profiles.activeProfiles.map((profile) => profile.id), [
        'main-work',
      ]);
    },
  );
}
