import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_category_rules.dart';

void main() {
  test('fuel uses fuel-specific receipt fields', () {
    final rule = expenseReceiptRuleForCategory('Fuel');

    expect(rule.mode, ExpenseReceiptLineInputMode.fuel);
    expect(rule.defaultUnit, 'gallon');
    expect(rule.quantityLabel, 'Fuel volume');
    expect(rule.unitChoices, containsAll(['gallon', 'kWh']));
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
      'Receipt Adjustment',
      'Subscriptions',
      'Business License',
    ]) {
      final rule = expenseReceiptRuleForCategory(category);

      expect(rule.mode, ExpenseReceiptLineInputMode.amountOnly);
      expect(rule.usesQuantityFields, isFalse);
      expect(rule.defaultUnit, 'each');
      expect(rule.unitChoices, ['each']);
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
      expect(rule.unitChoices, isNotEmpty);
    }
  });

  test('maintenance and materials expose their real-world units', () {
    expect(
      expenseReceiptRuleForCategory('Maintenance').unitChoices,
      containsAll(['quart', 'gallon', 'case', 'service']),
    );
    expect(
      expenseReceiptRuleForCategory('Materials').unitChoices,
      containsAll(['foot', 'inch', 'box', 'bag', 'roll']),
    );
  });
}
