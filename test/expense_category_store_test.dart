import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/expenses/data/expense_category_store.dart';

void main() {
  test('renames a category without changing its durable identity', () async {
    final store = ExpenseCategoryStore.memory();
    await store.rename(id: 'fuel', name: 'Vehicle fuel');
    expect(store.displayNameFor('fuel', fallback: 'Fuel'), 'Vehicle fuel');
    expect(store.displayNameFor('repair', fallback: 'Repair'), 'Repair');
    expect(store.backupPayloadFor('fuel', fallback: 'Fuel'), {
      'schema': 'expense_category_backup_v1',
      'categoryId': 'fuel',
      'displayName': 'Vehicle fuel',
    });
  });

  test('category rename survives a local restart', () async {
    final directory = await Directory.systemTemp.createTemp('category_store_');
    addTearDown(() async {
      await Hive.close();
      await directory.delete(recursive: true);
    });
    Hive.init(directory.path);
    final first = await ExpenseCategoryStore.create();
    await first.rename(id: 'fuel', name: 'Vehicle fuel');
    await Hive.close();
    Hive.init(directory.path);
    final reopened = await ExpenseCategoryStore.create();
    expect(reopened.displayNameFor('fuel', fallback: 'Fuel'), 'Vehicle fuel');
  });
}
