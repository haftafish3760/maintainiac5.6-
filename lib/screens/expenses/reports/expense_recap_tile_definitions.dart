part of 'expense_recap_models.dart';

class ExpenseRecapTileDefinition {
  const ExpenseRecapTileDefinition({
    required this.id,
    required this.title,
    required this.group,
    required this.valueFor,
    required this.detailFor,
  });

  final String id;
  final String title;
  final String group;
  final String Function(ExpenseRecapReport report) valueFor;
  final String Function(ExpenseRecapReport report) detailFor;
}

final expenseRecapTileDefinitions = <ExpenseRecapTileDefinition>[
  _moneyTile('totalExpenses', 'Total Expenses', 'Core', (r) => r.totalExpenses),
  _moneyTile(
    'businessExpenses',
    'Business Expenses',
    'Core',
    (r) => r.businessExpenses,
  ),
  _moneyTile(
    'personalExpenses',
    'Personal Expenses',
    'Core',
    (r) => r.personalExpenses,
  ),
  _countTile('receiptCount', 'Receipt Count', 'Core', (r) => r.receiptCount),
  _moneyTile('fuelSpend', 'Fuel Spend', 'Vehicle', (r) => r.fuelExpense),
  _moneyTile(
    'maintenanceSpend',
    'Maintenance',
    'Vehicle',
    (r) => r.maintenanceExpense,
  ),
  _moneyTile('repairSpend', 'Repairs', 'Vehicle', (r) => r.repairExpense),
  _moneyTile(
    'vehicleSpend',
    'Vehicle Expenses',
    'Vehicle',
    (r) => r.vehicleExpense,
  ),
  _nullableTile(
    'vehicleCostPerMile',
    'Vehicle Cost Per Mile',
    'Vehicle',
    (r) => r.vehicleCostPerMile,
    prefix: r'$',
    empty: 'Needs odometer data',
  ),
  _nullableTile(
    'fuelCostPerMile',
    'Fuel Cost Per Mile',
    'Vehicle',
    (r) => r.fuelCostPerMile,
    prefix: r'$',
    empty: 'Needs odometer data',
  ),
  _nullableTile(
    'totalCostPerMile',
    'Total Cost Per Mile',
    'Vehicle',
    (r) => r.totalCostPerMile,
    prefix: r'$',
    empty: 'Needs odometer data',
  ),
  _nullableTile(
    'averageFuelPrice',
    'Average Fuel Price',
    'Vehicle',
    (r) => r.averageFuelPrice,
    prefix: r'$',
    empty: 'Needs fuel quantity',
  ),
  _nullableTile(
    'averageMpg',
    'Average MPG',
    'Vehicle',
    (r) => r.averageMpg,
    suffix: ' MPG',
    empty: 'Needs fuel/odometer data',
  ),
  _nullableTile(
    'averageElectricKwhPrice',
    'Average EV kWh Price',
    'Vehicle',
    (r) => r.averageElectricKwhPrice,
    prefix: r'$',
    empty: 'Needs EV energy data',
  ),
  _nullableTile(
    'milesPerKwh',
    'EV Miles per kWh',
    'Vehicle',
    (r) => r.milesPerKwh,
    suffix: ' mi/kWh',
    empty: 'Needs EV energy and odometer data',
  ),
  _nullableTile(
    'electricFuelCostPerMile',
    'EV Cost Per Mile',
    'Vehicle',
    (r) => r.electricFuelCostPerMile,
    prefix: r'$',
    empty: 'Needs EV and odometer data',
  ),
  _nullableTile(
    'averageHydrogenKgPrice',
    'Average Hydrogen kg Price',
    'Vehicle',
    (r) => r.averageHydrogenKgPrice,
    prefix: r'$',
    empty: 'Needs hydrogen quantity data',
  ),
  _nullableTile(
    'milesPerHydrogenKg',
    'Hydrogen Miles per kg',
    'Vehicle',
    (r) => r.milesPerHydrogenKg,
    suffix: ' mi/kg',
    empty: 'Needs hydrogen and odometer data',
  ),
  _nullableTile(
    'hydrogenFuelCostPerMile',
    'Hydrogen Cost Per Mile',
    'Vehicle',
    (r) => r.hydrogenFuelCostPerMile,
    prefix: r'$',
    empty: 'Needs hydrogen and odometer data',
  ),
  _percentTile(
    'vehicleBusinessUse',
    'Business Mile Share',
    'Vehicle',
    (r) => r.vehicleBusinessUsePercent,
    empty: 'Needs business and personal mileage',
  ),
  _percentTile(
    'vehiclePersonalUse',
    'Personal Mile Share',
    'Vehicle',
    (r) => r.vehiclePersonalUsePercent,
    empty: 'Needs business and personal mileage',
  ),
  _moneyTile(
    'materialsSpend',
    'Materials',
    'Contractor',
    (r) => r.materialsExpense,
  ),
  _moneyTile('toolsSpend', 'Tools', 'Contractor', (r) => r.toolsExpense),
  _moneyTile(
    'contractorCore',
    'Contractor Core Cost',
    'Contractor',
    (r) => r.contractorCoreExpense,
  ),
  _moneyTile(
    'parkingTolls',
    'Parking & Tolls',
    'Gig / Travel',
    (r) => r.parkingTollsExpense,
  ),
  _moneyTile('mealsSpend', 'Meals', 'Gig / Travel', (r) => r.mealsExpense),
  _moneyTile(
    'insuranceSpend',
    'Insurance',
    'Fixed Costs',
    (r) => r.insuranceExpense,
  ),
  _moneyTile(
    'loanLeaseSpend',
    'Loan / Lease',
    'Fixed Costs',
    (r) => r.loanLeaseExpense,
  ),
  _countTile(
    'missingProof',
    'Receipts Missing Proof',
    'Review',
    (r) => r.receiptsMissingProof,
  ),
  _countTile(
    'splitReceipts',
    'Split Receipts',
    'Review',
    (r) => r.splitReceiptCount,
  ),
  _moneyTile(
    'uncategorizedSpend',
    'Uncategorized',
    'Review',
    (r) => r.uncategorizedExpense,
  ),
  ExpenseRecapTileDefinition(
    id: 'largestReceipt',
    title: 'Largest Receipt',
    group: 'Review',
    valueFor: (report) => _money(report.largestReceiptTotal),
    detailFor: (report) => report.largestReceiptTitle,
  ),
  const ExpenseRecapTileDefinition(
    id: 'profitBeforeExpenses',
    title: 'Profit Before Expenses',
    group: 'Income',
    valueFor: _notAvailable,
    detailFor: _incomeNeeded,
  ),
  const ExpenseRecapTileDefinition(
    id: 'profitAfterExpenses',
    title: 'Profit After Expenses',
    group: 'Income',
    valueFor: _notAvailable,
    detailFor: _incomeNeeded,
  ),
  const ExpenseRecapTileDefinition(
    id: 'expensePerHour',
    title: 'Expense Per Hour',
    group: 'Work Time',
    valueFor: _notAvailable,
    detailFor: _hoursNeeded,
  ),
];

ExpenseRecapTileDefinition _moneyTile(
  String id,
  String title,
  String group,
  double Function(ExpenseRecapReport report) value,
) {
  return ExpenseRecapTileDefinition(
    id: id,
    title: title,
    group: group,
    valueFor: (report) => _money(value(report)),
    detailFor: (report) => '${report.receiptCount} receipts in range',
  );
}

ExpenseRecapTileDefinition _countTile(
  String id,
  String title,
  String group,
  int Function(ExpenseRecapReport report) value,
) {
  return ExpenseRecapTileDefinition(
    id: id,
    title: title,
    group: group,
    valueFor: (report) => value(report).toString(),
    detailFor: (report) => '${report.lineCount} receipt lines in range',
  );
}

ExpenseRecapTileDefinition _nullableTile(
  String id,
  String title,
  String group,
  double? Function(ExpenseRecapReport report) value, {
  String prefix = '',
  String suffix = '',
  required String empty,
}) {
  return ExpenseRecapTileDefinition(
    id: id,
    title: title,
    group: group,
    valueFor: (report) {
      final number = value(report);
      return number == null
          ? '--'
          : '$prefix${number.toStringAsFixed(2)}$suffix';
    },
    detailFor: (report) =>
        value(report) == null ? empty : 'Calculated from this range',
  );
}

ExpenseRecapTileDefinition _percentTile(
  String id,
  String title,
  String group,
  double? Function(ExpenseRecapReport report) value, {
  required String empty,
}) {
  return ExpenseRecapTileDefinition(
    id: id,
    title: title,
    group: group,
    valueFor: (report) {
      final number = value(report);
      return number == null ? '--' : '${(number * 100).toStringAsFixed(1)}%';
    },
    detailFor: (report) =>
        value(report) == null ? empty : 'Calculated from mileage in this range',
  );
}

String _notAvailable(ExpenseRecapReport report) => '--';
String _incomeNeeded(ExpenseRecapReport report) => 'Needs income records';
String _hoursNeeded(ExpenseRecapReport report) => 'Needs work-hour records';
String _money(double value) => '\$${value.toStringAsFixed(2)}';
String _shortDate(DateTime date) => '${date.month}/${date.day}/${date.year}';
String _longDate(DateTime date) =>
    '${_monthName(date.month)} ${date.day}, ${date.year}';
String _monthName(int month) {
  return const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][month - 1];
}
