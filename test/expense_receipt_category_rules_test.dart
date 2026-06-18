import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_category_rules.dart';

void main() {
  test('fuel uses fuel-specific receipt fields', () {
    final rule = expenseReceiptRuleForCategory('Fuel');

    expect(rule.mode, ExpenseReceiptLineInputMode.fuel);
    expect(rule.defaultUnit, 'gallon');
    expect(rule.usesQuantityFields, isTrue);
    expect(rule.isFuel, isTrue);
  });

  test('amount-only categories hide package and quantity fields', () {
    for (final category in [
      'Insurance',
      'Cell Phone',
      'Loan/Lease',
      'Registration',
      'Meals',
      'Subscriptions',
      'Business License',
    ]) {
      final rule = expenseReceiptRuleForCategory(category);

      expect(rule.mode, ExpenseReceiptLineInputMode.amountOnly);
      expect(rule.usesQuantityFields, isFalse);
      expect(rule.defaultUnit, 'each');
    }
  });

  test('physical item categories keep measured item fields', () {
    for (final category in [
      'Materials',
      'Tools',
      'Vehicle Parts',
      'Cleaning Supplies',
      'Office Supplies',
    ]) {
      final rule = expenseReceiptRuleForCategory(category);

      expect(rule.mode, ExpenseReceiptLineInputMode.measuredItem);
      expect(rule.usesQuantityFields, isTrue);
      expect(rule.isFuel, isFalse);
    }
  });
}
