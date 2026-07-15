import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/categories/expense_categories.dart';

void main() {
  test('contractor and gig-worker expense categories stay available', () {
    final categories = [...defaultExpenseCategories, ...otherExpenseCategories];
    final names = categories.map((category) => category.category).toSet();

    expect(names.length, categories.length);
    expect(
      names,
      containsAll({
        'Fuel',
        'Repair',
        'Maintenance',
        'Insurance',
        'Parking',
        'Tolls',
        'Meals',
        'Tools',
        'Materials',
        'Cell Phone',
        'Registration',
        'Loan/Lease',
        'Advertising',
        'Background Checks',
        'Contract Labor',
        'Platform Fees',
        'Safety Gear',
        'Training',
        'Vehicle Parts',
        'Waste Disposal',
      }),
    );
  });
}
