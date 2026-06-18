part of 'expenses_home_screen.dart';

String _quickActionTotalFor(
  BuildContext context,
  String category, {
  ExpenseDateRange? range,
  String? periodLabel,
}) {
  final ledger = ExpenseLedgerScope.of(context);
  final selectedRange = range ?? _weekRange(DateTime.now());
  var total = 0.0;
  for (final receipt in ledger.receipts) {
    if (!selectedRange.contains(receipt.receiptDate)) {
      continue;
    }
    for (final line in receipt.lines) {
      if (_sameExpenseCategory(line.category, category)) {
        total += receipt.totalForLine(line);
      }
    }
  }
  if (total <= 0) {
    return 'No entries';
  }
  return '${periodLabel ?? 'Period'} ${_money(total)}';
}

String _expenseScopeLabel(BuildContext context) {
  final vehicle = AppStateScope.of(context).activeVehicle;
  final label = vehicle?.nickname.trim();
  if (label == null || label.isEmpty) {
    return 'Active vehicle expenses';
  }
  return '$label expenses';
}

List<ExpenseCategoryDefinition> _topExpenseCategories(
  ExpenseLedgerController ledger,
  ExpenseDateRange range,
) {
  final allCategories = [
    ...defaultExpenseCategories,
    ...otherExpenseCategories,
  ];
  final totals = <String, double>{};
  for (final receipt in ledger.receipts) {
    if (!range.contains(receipt.receiptDate)) {
      continue;
    }
    for (final line in receipt.lines) {
      final lineTotal = receipt.totalForLine(line);
      totals.update(
        _normalizedExpenseCategory(line.category),
        (value) => value + lineTotal,
        ifAbsent: () => lineTotal,
      );
    }
  }
  final usedCategories = allCategories.where((category) {
    return (totals[_normalizedExpenseCategory(category.category)] ?? 0) > 0;
  }).toList();
  usedCategories.sort((left, right) {
    final leftTotal = totals[_normalizedExpenseCategory(left.category)] ?? 0;
    final rightTotal = totals[_normalizedExpenseCategory(right.category)] ?? 0;
    return rightTotal.compareTo(leftTotal);
  });
  final topTen = <ExpenseCategoryDefinition>[...usedCategories.take(10)];
  for (final category in allCategories) {
    if (topTen.length >= 10) {
      break;
    }
    final alreadyIncluded = topTen.any(
      (current) => _sameExpenseCategory(current.category, category.category),
    );
    if (!alreadyIncluded) {
      topTen.add(category);
    }
  }
  return topTen;
}

List<ExpenseCategoryDefinition> _quickCategoriesFromSettings(
  ExpenseSettingsController settings,
) {
  final allCategories = [
    ...defaultExpenseCategories,
    ...otherExpenseCategories,
  ];
  final saved = settings.quickCategoryOrder;
  if (saved.isEmpty) {
    return defaultExpenseCategories.take(10).toList(growable: false);
  }
  final output = <ExpenseCategoryDefinition>[];
  for (final categoryName in saved) {
    final match = allCategories.where(
      (category) => _sameExpenseCategory(category.category, categoryName),
    );
    if (match.isNotEmpty &&
        !output.any(
          (category) => _sameExpenseCategory(category.category, categoryName),
        )) {
      output.add(match.first);
    }
  }
  for (final category in allCategories) {
    if (output.length >= 10) break;
    final alreadyIncluded = output.any(
      (current) => _sameExpenseCategory(current.category, category.category),
    );
    if (!alreadyIncluded) output.add(category);
  }
  return output.take(10).toList(growable: false);
}

IconData _iconFor(ExpenseActionIcon icon) {
  return switch (icon) {
    ExpenseActionIcon.fuel => Icons.local_gas_station_rounded,
    ExpenseActionIcon.repair => Icons.build_rounded,
    ExpenseActionIcon.insurance => Icons.verified_user_rounded,
    ExpenseActionIcon.parking => Icons.local_parking_rounded,
    ExpenseActionIcon.tolls => Icons.toll_rounded,
    ExpenseActionIcon.meals => Icons.restaurant_rounded,
    ExpenseActionIcon.tools => Icons.handyman_rounded,
    ExpenseActionIcon.supplies => Icons.inventory_2_rounded,
    ExpenseActionIcon.registration => Icons.badge_rounded,
    ExpenseActionIcon.reminder => Icons.notifications_rounded,
    ExpenseActionIcon.rentLease => Icons.payments_rounded,
    ExpenseActionIcon.utilities => Icons.power_rounded,
  };
}
