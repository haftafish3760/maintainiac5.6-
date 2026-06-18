enum ExpenseReceiptLineInputMode { amountOnly, measuredItem, fuel }

class ExpenseReceiptCategoryRule {
  const ExpenseReceiptCategoryRule({
    required this.mode,
    required this.defaultUnit,
    required this.guidance,
    required this.descriptionHint,
  });

  final ExpenseReceiptLineInputMode mode;
  final String defaultUnit;
  final String guidance;
  final String descriptionHint;

  bool get usesQuantityFields => mode != ExpenseReceiptLineInputMode.amountOnly;
  bool get isFuel => mode == ExpenseReceiptLineInputMode.fuel;
}

ExpenseReceiptCategoryRule expenseReceiptRuleForCategory(String category) {
  final key = _normalizedCategory(category);
  if (key == 'fuel') {
    return const ExpenseReceiptCategoryRule(
      mode: ExpenseReceiptLineInputMode.fuel,
      defaultUnit: 'gallon',
      guidance:
          'Fuel needs odometer and fill details so mileage allocation can work later.',
      descriptionHint: 'Example: diesel fuel, gasoline fuel, EV charge',
    );
  }
  if (_amountOnlyCategories.contains(key)) {
    return const ExpenseReceiptCategoryRule(
      mode: ExpenseReceiptLineInputMode.amountOnly,
      defaultUnit: 'each',
      guidance:
          'This category records the receipt amount only. Package and unit counts do not apply.',
      descriptionHint: 'Example: insurance premium, permit fee, phone bill',
    );
  }
  return ExpenseReceiptCategoryRule(
    mode: ExpenseReceiptLineInputMode.measuredItem,
    defaultUnit: _defaultUnitByCategory[key] ?? 'each',
    guidance:
        'This category can use quantity, package size, and unit cost when the receipt shows them.',
    descriptionHint:
        'Example: saw blade, T-shirt, oil filter, cleaning supplies',
  );
}

bool expenseCategoryUsesQuantityFields(String category) {
  return expenseReceiptRuleForCategory(category).usesQuantityFields;
}

String defaultExpenseReceiptUnit(String category) {
  return expenseReceiptRuleForCategory(category).defaultUnit;
}

String normalizedExpenseCategoryKey(String category) {
  return _normalizedCategory(category);
}

String _normalizedCategory(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
}

const _amountOnlyCategories = {
  'advertising',
  'background_checks',
  'business_license',
  'cell_phone',
  'charging_fees',
  'commissions',
  'contract_labor',
  'dispatch_fees',
  'equipment_rental',
  'home_office',
  'insurance',
  'internet',
  'licenses',
  'lodging',
  'loan_lease',
  'meals',
  'medical',
  'parking',
  'permits',
  'platform_fees',
  'postage',
  'registration',
  'rent',
  'roadside_help',
  'subscriptions',
  'tolls',
  'tool_rental',
  'training',
  'travel',
  'utilities',
  'vehicle_wash',
  'waste_disposal',
};

const _defaultUnitByCategory = {
  'cleaning_supplies': 'each',
  'delivery_bags': 'each',
  'equipment': 'each',
  'fuel_additives': 'bottle',
  'laundry': 'each',
  'maintenance': 'each',
  'materials': 'each',
  'office_supplies': 'each',
  'passenger_amenities': 'each',
  'printing': 'each',
  'repair': 'each',
  'safety_gear': 'each',
  'storage': 'each',
  'tools': 'each',
  'uniforms': 'each',
  'vehicle_parts': 'each',
  'vehicle_supplies': 'each',
};
