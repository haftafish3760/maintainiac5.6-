part of 'expense_receipt_entry_screen.dart';

const Object _noBusinessPercentChange = Object();

enum _ExpenseLineUse {
  business('Business'),
  personal('Personal'),
  split('Split');

  const _ExpenseLineUse(this.label);

  final String label;
}

extension on _ExpenseLineUse {
  ExpenseLineUse get ledgerUse {
    return switch (this) {
      _ExpenseLineUse.business => ExpenseLineUse.business,
      _ExpenseLineUse.personal => ExpenseLineUse.personal,
      _ExpenseLineUse.split => ExpenseLineUse.split,
    };
  }
}

String _formatNumber(double value) =>
    value == value.roundToDouble() ? value.toInt().toString() : '$value';

String _money(double value) => '\$${value.toStringAsFixed(2)}';
String _percent(double value) => '${(value * 100).toStringAsFixed(2)}%';

String _expenseReceiptTokenLabel(String value) {
  final cleaned = value
      .trim()
      .replaceAll(RegExp(r'[_\-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ');
  if (cleaned.isEmpty) return '';
  return cleaned
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map(
        (part) => part.length == 1
            ? part.toUpperCase()
            : '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
      )
      .join(' ');
}

String _expenseReceiptSafeToken(String value, {String fallback = 'unknown'}) {
  final token = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  return token.isEmpty ? fallback : token;
}

double? _parseMoneyInput(String value) {
  final cleaned = value.replaceAll(RegExp(r'[^0-9.\-]'), '');
  if (cleaned.isEmpty || cleaned == '-' || cleaned == '.') return null;
  return double.tryParse(cleaned);
}

String _moneyInputText(double? value) {
  if (value == null) return '';
  return value.toStringAsFixed(2);
}

final _expenseCategoryNames = [
  'Uncategorized',
  ...{
    for (final category in [
      ...defaultExpenseCategories,
      ...otherExpenseCategories,
    ])
      category.category,
  },
];

const _stockUnits = [
  'each',
  'bottle',
  'package',
  'pack',
  'box',
  'case',
  'roll',
  'tube',
  'bag',
  'gallon',
  'quart',
  'ounce',
  'pound',
  'foot',
  'linear foot',
  'sheet',
  'set',
];
