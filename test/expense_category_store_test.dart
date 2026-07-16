import 'package:flutter_test/flutter_test.dart';
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
}
