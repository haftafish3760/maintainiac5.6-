import '../data/fuel_economy_metrics.dart';
import '../data/expense_ledger_models.dart';
import '../data/expense_ledger_store.dart';

part 'expense_recap_tile_definitions.dart';
part 'expense_recap_fuel_summary.dart';

enum ExpenseRecapPeriod {
  day('Daily'),
  week('Weekly'),
  month('Monthly'),
  ninetyDays('90 Days'),
  yearToDate('Year-to-Date'),
  custom('Custom');

  const ExpenseRecapPeriod(this.label);

  final String label;

  ExpenseDateRange rangeFor(DateTime anchor, {ExpenseDateRange? customRange}) {
    final day = DateTime(anchor.year, anchor.month, anchor.day);
    return switch (this) {
      ExpenseRecapPeriod.day => ExpenseDateRange(start: day, end: day),
      ExpenseRecapPeriod.week => _weekRange(day),
      ExpenseRecapPeriod.month => ExpenseDateRange(
        start: DateTime(day.year, day.month),
        end: DateTime(day.year, day.month + 1, 0),
      ),
      ExpenseRecapPeriod.ninetyDays => ExpenseDateRange(
        start: day.subtract(const Duration(days: 89)),
        end: day,
      ),
      ExpenseRecapPeriod.yearToDate => ExpenseDateRange(
        start: DateTime(day.year),
        end: day,
      ),
      ExpenseRecapPeriod.custom =>
        customRange ?? ExpenseDateRange(start: day, end: day),
    };
  }

  DateTime shift(DateTime anchor, int direction) {
    return switch (this) {
      ExpenseRecapPeriod.day => anchor.add(Duration(days: direction)),
      ExpenseRecapPeriod.week => anchor.add(Duration(days: 7 * direction)),
      ExpenseRecapPeriod.month => DateTime(
        anchor.year,
        anchor.month + direction,
      ),
      ExpenseRecapPeriod.ninetyDays => anchor.add(
        Duration(days: 90 * direction),
      ),
      ExpenseRecapPeriod.yearToDate => DateTime(anchor.year + direction),
      ExpenseRecapPeriod.custom => anchor,
    };
  }

  String rangeLabel(DateTime anchor, {ExpenseDateRange? customRange}) {
    final range = rangeFor(anchor, customRange: customRange);
    return switch (this) {
      ExpenseRecapPeriod.day => _longDate(range.start),
      ExpenseRecapPeriod.week ||
      ExpenseRecapPeriod.ninetyDays ||
      ExpenseRecapPeriod.custom =>
        '${_shortDate(range.start)} - ${_shortDate(range.end)}',
      ExpenseRecapPeriod.month =>
        '${_monthName(range.start.month)} ${range.start.year}',
      ExpenseRecapPeriod.yearToDate => 'Jan 1 - ${_shortDate(range.end)}',
    };
  }
}

class ExpenseRecapReport {
  const ExpenseRecapReport({
    required this.range,
    required this.receiptCount,
    required this.lineCount,
    required this.totalExpenses,
    required this.businessExpenses,
    required this.personalExpenses,
    required this.categoryTotals,
    required this.vehicleExpense,
    required this.fuelExpense,
    required this.liquidFuelExpense,
    required this.electricFuelExpense,
    required this.hydrogenFuelExpense,
    required this.maintenanceExpense,
    required this.repairExpense,
    required this.materialsExpense,
    required this.toolsExpense,
    required this.parkingTollsExpense,
    required this.mealsExpense,
    required this.insuranceExpense,
    required this.loanLeaseExpense,
    required this.receiptsMissingProof,
    required this.splitReceiptCount,
    required this.uncategorizedExpense,
    required this.largestReceiptTitle,
    required this.largestReceiptTotal,
    required this.fuelUnits,
    required this.electricKwh,
    required this.hydrogenKg,
    required this.odometerMiles,
    required this.completedLiquidFillMiles,
    required this.completedLiquidFillGallons,
    required this.hasMixedLiquidFuelTypes,
    required this.hasUnmeasuredLiquidFuel,
    required this.businessVehicleMiles,
    required this.personalVehicleMiles,
  });

  factory ExpenseRecapReport.fromLedger(
    ExpenseLedgerController ledger,
    ExpenseDateRange range, {
    String? vehicleId,
    Map<String, ExpenseVehicleUsageSnapshot> vehicleUsage = const {},
  }) {
    final categoryTotals = <String, double>{};
    final includedReceipts = <ExpenseReceiptRecord>[];
    final usageTotals = _VehicleUsageTotals();
    var receiptCount = 0;
    var lineCount = 0;
    var totalExpenses = 0.0;
    var businessExpenses = 0.0;
    var personalExpenses = 0.0;
    var vehicleExpense = 0.0;
    var fuelExpense = 0.0;
    var maintenanceExpense = 0.0;
    var repairExpense = 0.0;
    var materialsExpense = 0.0;
    var toolsExpense = 0.0;
    var parkingTollsExpense = 0.0;
    var mealsExpense = 0.0;
    var insuranceExpense = 0.0;
    var loanLeaseExpense = 0.0;
    var uncategorizedExpense = 0.0;
    var receiptsMissingProof = 0;
    var splitReceiptCount = 0;
    var largestReceiptTitle = 'No receipts';
    var largestReceiptTotal = 0.0;

    for (final receipt in ledger.receipts) {
      if (!range.contains(receipt.receiptDate)) continue;
      if (vehicleId != null && receipt.vehicleId != vehicleId) continue;
      includedReceipts.add(receipt);
      receiptCount += 1;
      lineCount += receipt.lines.length;
      totalExpenses += receipt.total;
      final usage = _usageForReceipt(receipt, vehicleUsage);
      usageTotals.addOnce(receipt.vehicleId, usage);
      if (!receipt.hasReceiptAttachment) receiptsMissingProof += 1;
      if (receipt.lines.any((line) => line.use == ExpenseLineUse.split)) {
        splitReceiptCount += 1;
      }
      if (receipt.total > largestReceiptTotal) {
        largestReceiptTotal = receipt.total;
        largestReceiptTitle = receipt.title;
      }
      for (final line in receipt.lines) {
        final amount = receipt.totalForLine(line);
        final businessAmount = _businessAmountForLine(
          receipt: receipt,
          line: line,
          lineTotal: amount,
          usage: usage,
        );
        businessExpenses += businessAmount;
        personalExpenses += amount - businessAmount;
        final normalized = _normalizedCategory(line.category);
        categoryTotals.update(
          normalized,
          (value) => value + amount,
          ifAbsent: () => amount,
        );
        if (_vehicleCategories.contains(normalized)) vehicleExpense += amount;
        if (normalized == 'fuel' || normalized == 'charging fees') {
          fuelExpense += amount;
        }
        if (normalized == 'maintenance') maintenanceExpense += amount;
        if (normalized == 'repair') repairExpense += amount;
        if (normalized == 'materials') materialsExpense += amount;
        if (normalized == 'tools' || normalized == 'tool rental') {
          toolsExpense += amount;
        }
        if (normalized == 'parking' || normalized == 'tolls') {
          parkingTollsExpense += amount;
        }
        if (normalized == 'meals') mealsExpense += amount;
        if (normalized == 'insurance') insuranceExpense += amount;
        if (normalized == 'loan lease') loanLeaseExpense += amount;
        if (normalized == 'uncategorized') uncategorizedExpense += amount;
      }
    }

    final fuelEconomy = _ExpenseRecapFuelSummary.fromReceipts(includedReceipts);
    return ExpenseRecapReport(
      range: range,
      receiptCount: receiptCount,
      lineCount: lineCount,
      totalExpenses: totalExpenses,
      businessExpenses: businessExpenses,
      personalExpenses: personalExpenses,
      categoryTotals: Map.unmodifiable(categoryTotals),
      vehicleExpense: vehicleExpense,
      fuelExpense: fuelExpense,
      liquidFuelExpense: fuelEconomy.liquidFuelExpense,
      electricFuelExpense: fuelEconomy.electricFuelExpense,
      hydrogenFuelExpense: fuelEconomy.hydrogenFuelExpense,
      maintenanceExpense: maintenanceExpense,
      repairExpense: repairExpense,
      materialsExpense: materialsExpense,
      toolsExpense: toolsExpense,
      parkingTollsExpense: parkingTollsExpense,
      mealsExpense: mealsExpense,
      insuranceExpense: insuranceExpense,
      loanLeaseExpense: loanLeaseExpense,
      receiptsMissingProof: receiptsMissingProof,
      splitReceiptCount: splitReceiptCount,
      uncategorizedExpense: uncategorizedExpense,
      largestReceiptTitle: largestReceiptTitle,
      largestReceiptTotal: largestReceiptTotal,
      fuelUnits: fuelEconomy.liquidGallons,
      electricKwh: fuelEconomy.electricKwh,
      hydrogenKg: fuelEconomy.hydrogenKg,
      odometerMiles: fuelEconomy.odometerMiles,
      completedLiquidFillMiles: fuelEconomy.completedLiquidFillMiles,
      completedLiquidFillGallons: fuelEconomy.completedLiquidFillGallons,
      hasMixedLiquidFuelTypes: fuelEconomy.hasMixedLiquidFuelTypes,
      hasUnmeasuredLiquidFuel: fuelEconomy.hasUnmeasuredLiquidFuel,
      businessVehicleMiles: usageTotals.businessMiles,
      personalVehicleMiles: usageTotals.personalMiles,
    );
  }

  final ExpenseDateRange range;
  final int receiptCount;
  final int lineCount;
  final double totalExpenses;
  final double businessExpenses;
  final double personalExpenses;
  final Map<String, double> categoryTotals;
  final double vehicleExpense;
  final double fuelExpense;
  final double liquidFuelExpense;
  final double electricFuelExpense;
  final double hydrogenFuelExpense;
  final double maintenanceExpense;
  final double repairExpense;
  final double materialsExpense;
  final double toolsExpense;
  final double parkingTollsExpense;
  final double mealsExpense;
  final double insuranceExpense;
  final double loanLeaseExpense;
  final int receiptsMissingProof;
  final int splitReceiptCount;
  final double uncategorizedExpense;
  final String largestReceiptTitle;
  final double largestReceiptTotal;
  final double fuelUnits;
  final double electricKwh;
  final double hydrogenKg;
  final int? odometerMiles;
  final int? completedLiquidFillMiles;
  final double completedLiquidFillGallons;
  final bool hasMixedLiquidFuelTypes;
  final bool hasUnmeasuredLiquidFuel;
  final double businessVehicleMiles;
  final double personalVehicleMiles;

  double get contractorCoreExpense =>
      materialsExpense + toolsExpense + maintenanceExpense + repairExpense;
  double get totalVehicleUsageMiles =>
      businessVehicleMiles + personalVehicleMiles;
  double get propulsionFuelExpense =>
      liquidFuelExpense + electricFuelExpense + hydrogenFuelExpense;
  double? get vehicleBusinessUsePercent => totalVehicleUsageMiles <= 0
      ? null
      : businessVehicleMiles / totalVehicleUsageMiles;
  double? get vehiclePersonalUsePercent => totalVehicleUsageMiles <= 0
      ? null
      : personalVehicleMiles / totalVehicleUsageMiles;
  double? get vehicleCostPerMile => _perMile(vehicleExpense);
  double? get fuelCostPerMile => _perMile(propulsionFuelExpense);
  double? get liquidFuelCostPerMile => _perMile(liquidFuelExpense);
  double? get electricFuelCostPerMile => _perMile(electricFuelExpense);
  double? get hydrogenFuelCostPerMile => _perMile(hydrogenFuelExpense);
  double? get totalCostPerMile => _perMile(totalExpenses);
  double? get averageFuelPrice => hasUnmeasuredLiquidFuel || fuelUnits <= 0
      ? null
      : liquidFuelExpense / fuelUnits;
  double? get averageElectricKwhPrice =>
      electricKwh <= 0 ? null : electricFuelExpense / electricKwh;
  double? get averageHydrogenKgPrice =>
      hydrogenKg <= 0 ? null : hydrogenFuelExpense / hydrogenKg;
  double? get averageMpg {
    if (hasMixedLiquidFuelTypes || hasUnmeasuredLiquidFuel) return null;
    final miles = completedLiquidFillMiles ?? odometerMiles;
    final gallons = completedLiquidFillMiles == null
        ? fuelUnits
        : completedLiquidFillGallons;
    if (miles == null || miles <= 0 || gallons <= 0) return null;
    return miles / gallons;
  }

  double? get milesPerKwh {
    final miles = odometerMiles;
    if (miles == null || miles <= 0 || electricKwh <= 0) return null;
    return miles / electricKwh;
  }

  double? get milesPerHydrogenKg {
    final miles = odometerMiles;
    if (miles == null || miles <= 0 || hydrogenKg <= 0) return null;
    return miles / hydrogenKg;
  }

  double? _perMile(double amount) {
    final miles = odometerMiles;
    if (miles == null || miles <= 0) return null;
    return amount / miles;
  }
}

class ExpenseVehicleUsageSnapshot {
  const ExpenseVehicleUsageSnapshot({
    required this.vehicleId,
    required this.businessMiles,
    required this.personalMiles,
    this.source = 'manual',
  });

  final String vehicleId;
  final double businessMiles;
  final double personalMiles;
  final String source;

  double get totalMiles => businessMiles + personalMiles;
  double get businessPercent {
    if (businessMiles <= 0 && personalMiles > 0) return 0;
    if (totalMiles <= 0) return 1;
    return businessMiles / totalMiles;
  }

  double get personalPercent => 1 - businessPercent;
  bool get isMixedUse => businessMiles > 0 && personalMiles > 0;
}

class _VehicleUsageTotals {
  final _seenVehicleIds = <String>{};
  var businessMiles = 0.0;
  var personalMiles = 0.0;

  void addOnce(String? vehicleId, ExpenseVehicleUsageSnapshot? usage) {
    final id = vehicleId?.trim();
    if (id == null || id.isEmpty || usage == null || !_seenVehicleIds.add(id)) {
      return;
    }
    businessMiles += usage.businessMiles;
    personalMiles += usage.personalMiles;
  }
}

ExpenseVehicleUsageSnapshot? _usageForReceipt(
  ExpenseReceiptRecord receipt,
  Map<String, ExpenseVehicleUsageSnapshot> vehicleUsage,
) {
  final vehicleId = receipt.vehicleId?.trim();
  if (vehicleId == null || vehicleId.isEmpty) return null;
  return vehicleUsage[vehicleId];
}

double _businessAmountForLine({
  required ExpenseReceiptRecord receipt,
  required ExpenseReceiptLineRecord line,
  required double lineTotal,
  required ExpenseVehicleUsageSnapshot? usage,
}) {
  if (line.use == ExpenseLineUse.split) {
    return receipt.businessTotalForLine(line);
  }
  final normalized = _normalizedCategory(line.category);
  if (line.use == ExpenseLineUse.business &&
      usage != null &&
      _vehicleUsageAllocatedCategories.contains(normalized)) {
    return lineTotal * usage.businessPercent;
  }
  return receipt.businessTotalForLine(line);
}

const _vehicleUsageAllocatedCategories = {
  'fuel',
  'charging fees',
  'insurance',
  'loan lease',
  'repair',
  'maintenance',
  'registration',
};

String _normalizedCategory(String category) {
  return switch (category.trim().toLowerCase()) {
    'repairs' => 'repair',
    'material' || 'materials' || 'supplies' => 'materials',
    'cell phone' || 'phone' || 'phone bill' || 'mobile phone' => 'cell phone',
    'car payment' ||
    'vehicle payment' ||
    'loan' ||
    'lease' ||
    'loan/lease' => 'loan lease',
    'charging fee' || 'charging fees' || 'ev charging' => 'charging fees',
    '' => 'uncategorized',
    final value => value,
  };
}

const _vehicleCategories = {
  'fuel',
  'charging fees',
  'maintenance',
  'repair',
  'insurance',
  'registration',
  'loan lease',
  'parking',
  'tolls',
  'vehicle parts',
  'vehicle supplies',
  'vehicle wash',
  'roadside help',
};

ExpenseDateRange _weekRange(DateTime day) {
  final start = DateTime(
    day.year,
    day.month,
    day.day - (day.weekday - DateTime.monday),
  );
  return ExpenseDateRange(
    start: start,
    end: start.add(const Duration(days: 6)),
  );
}
