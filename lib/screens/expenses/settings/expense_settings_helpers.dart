part of 'expense_settings_screen.dart';

bool _sameCategory(String left, String right) {
  return _categoryKey(left) == _categoryKey(right);
}

String _categoryKey(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
}

final _allExpenseCategories = [
  ...defaultExpenseCategories,
  ...otherExpenseCategories,
];
