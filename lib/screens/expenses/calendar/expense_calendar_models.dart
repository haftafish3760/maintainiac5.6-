part of 'expense_calendar.dart';

class _ReceiptLineData {
  const _ReceiptLineData({
    required this.description,
    required this.scope,
    required this.category,
    required this.quantityLabel,
    required this.total,
  });

  factory _ReceiptLineData.fromLedger(ExpenseReceiptLineRecord line) {
    return _ReceiptLineData(
      description: line.description,
      scope: line.use == ExpenseLineUse.split
          ? 'Split ${_percent(line.effectiveBusinessPercent)} business'
          : line.use.label,
      category: line.category,
      quantityLabel: line.quantityLabel,
      total: line.subtotal,
    );
  }

  final String description;
  final String scope;
  final String category;
  final String quantityLabel;
  final double total;
}

String _timeLabel(TimeOfDay? time) {
  if (time == null) return 'No time';
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final minute = time.minute.toString().padLeft(2, '0');
  final period = time.period == DayPeriod.am ? 'AM' : 'PM';
  return '$hour:$minute $period';
}

String _dateLabel(DateTime day) => calendarFullDateLabel(day);

String _money(double value) => '\$${value.toStringAsFixed(2)}';
String _percent(double value) => '${(value * 100).toStringAsFixed(2)}%';

class _CalendarExpenseData {
  const _CalendarExpenseData({
    required this.receiptId,
    required this.title,
    required this.scope,
    required this.category,
    required this.amount,
    required this.color,
    required this.date,
    required this.lines,
    this.time,
  });

  factory _CalendarExpenseData.fromReceipt(ExpenseReceiptRecord receipt) {
    final firstLine = receipt.lines.isEmpty ? null : receipt.lines.first;
    final category = firstLine?.category ?? 'Uncategorized';
    final use = firstLine?.use.label ?? 'Business';
    final timeMinutes = receipt.receiptTimeMinutes;
    return _CalendarExpenseData(
      receiptId: receipt.id,
      title: receipt.title,
      scope: use,
      category: category,
      amount: receipt.total,
      color: _colorForCategory(category),
      date: receipt.receiptDate,
      time: timeMinutes == null
          ? null
          : TimeOfDay(hour: timeMinutes ~/ 60, minute: timeMinutes % 60),
      lines: [
        for (final line in receipt.lines) _ReceiptLineData.fromLedger(line),
      ],
    );
  }

  final String receiptId;
  final String title;
  final String scope;
  final String category;
  final double amount;
  final Color color;
  final DateTime date;
  final TimeOfDay? time;
  final List<_ReceiptLineData> lines;

  String get timeLabel => _timeLabel(time);
  String get dateLabel => _dateLabel(date);
}

class _VehicleExpenseMetrics {
  const _VehicleExpenseMetrics({
    required this.range,
    required this.totalExpense,
    required this.businessExpense,
    required this.personalExpense,
    required this.vehicleExpense,
    required this.fuelExpense,
    required this.fuelUnits,
    required this.odometerMiles,
  });

  factory _VehicleExpenseMetrics.fromLedger(
    ExpenseLedgerController ledger,
    ExpenseDateRange range,
  ) {
    final fuelReadings = <int>[];
    var totalExpense = 0.0;
    var businessExpense = 0.0;
    var personalExpense = 0.0;
    var vehicleExpense = 0.0;
    var fuelExpense = 0.0;
    var fuelUnits = 0.0;
    for (final receipt in ledger.receipts) {
      if (!range.contains(receipt.receiptDate)) continue;
      totalExpense += receipt.total;
      businessExpense += receipt.businessTotal;
      personalExpense += receipt.personalTotal;
      for (final line in receipt.lines) {
        final lineTotal = receipt.totalForLine(line);
        if (_isVehicleExpenseCategory(line.category)) {
          vehicleExpense += lineTotal;
        }
        if (_normalizedExpenseCategory(line.category) == 'fuel') {
          fuelExpense += lineTotal;
          fuelUnits += line.quantity;
          final odometer = line.odometerReading;
          if (odometer != null && odometer > 0) fuelReadings.add(odometer);
        }
      }
    }
    fuelReadings.sort();
    final odometerMiles = fuelReadings.length < 2
        ? null
        : fuelReadings.last - fuelReadings.first;
    return _VehicleExpenseMetrics(
      range: range,
      totalExpense: totalExpense,
      businessExpense: businessExpense,
      personalExpense: personalExpense,
      vehicleExpense: vehicleExpense,
      fuelExpense: fuelExpense,
      fuelUnits: fuelUnits,
      odometerMiles: odometerMiles,
    );
  }

  final ExpenseDateRange range;
  final double totalExpense;
  final double businessExpense;
  final double personalExpense;
  final double vehicleExpense;
  final double fuelExpense;
  final double fuelUnits;
  final int? odometerMiles;

  double? get averageMpg {
    final miles = odometerMiles;
    if (miles == null || miles <= 0 || fuelUnits <= 0) return null;
    return miles / fuelUnits;
  }

  double? get vehicleCostPerMile {
    final miles = odometerMiles;
    if (miles == null || miles <= 0) return null;
    return vehicleExpense / miles;
  }

  double? get fuelCostPerMile {
    final miles = odometerMiles;
    if (miles == null || miles <= 0) return null;
    return fuelExpense / miles;
  }

  double? get totalCostPerMile {
    final miles = odometerMiles;
    if (miles == null || miles <= 0) return null;
    return totalExpense / miles;
  }

  String get mpgLabel {
    final mpg = averageMpg;
    if (mpg == null) return '--';
    return mpg.toStringAsFixed(1);
  }

  String get vehicleCostPerMileLabel => _perMileLabel(vehicleCostPerMile);
  String get fuelCostPerMileLabel => _perMileLabel(fuelCostPerMile);
  String get totalCostPerMileLabel => _perMileLabel(totalCostPerMile);
}

const _blue = Color(0xFF34A9E8);
const _green = Color(0xFF58D67D);
const _gold = Color(0xFFFFD166);
const _red = Color(0xFFFF6B63);

Color _colorForCategory(String category) {
  return switch (category) {
    'Fuel' => _red,
    'Parking' || 'Tolls' => _green,
    'Materials' || 'Tools' || 'Supplies' || 'Office Supplies' => _blue,
    _ => _gold,
  };
}

String _perMileLabel(double? value) {
  if (value == null) return '--';
  return '\$${value.toStringAsFixed(2)}';
}

bool _isVehicleExpenseCategory(String category) {
  return const {
    'fuel',
    'fuel additives',
    'charging fees',
    'maintenance',
    'repair',
    'repairs',
    'insurance',
    'loan/lease',
    'loan lease',
    'registration',
    'parking',
    'tolls',
  }.contains(_normalizedExpenseCategory(category));
}

String _normalizedExpenseCategory(String category) {
  return category.trim().toLowerCase();
}

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
