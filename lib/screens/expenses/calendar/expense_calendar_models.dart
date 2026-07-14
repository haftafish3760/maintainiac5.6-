part of 'expense_calendar.dart';

class _ReceiptLineData {
  const _ReceiptLineData({
    required this.description,
    required this.scope,
    required this.category,
    required this.quantityLabel,
    required this.total,
  });

  factory _ReceiptLineData.fromReceiptLine(
    ExpenseReceiptRecord receipt,
    ExpenseReceiptLineRecord line,
  ) {
    return _ReceiptLineData(
      description: line.description,
      scope: line.use == ExpenseLineUse.split
          ? 'Split ${_percent(line.effectiveBusinessPercent)} business'
          : line.use.label,
      category: line.category,
      quantityLabel: line.quantityLabel,
      total: receipt.totalForLine(line),
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
    required this.sourceReceipt,
    required this.receiptId,
    required this.title,
    required this.scope,
    required this.category,
    required this.amount,
    required this.color,
    required this.date,
    required this.lines,
    this.ocrStatusLabel = '',
    this.ocrRecoveryHintLabel = '',
    this.time,
  });

  factory _CalendarExpenseData.fromReceipt(ExpenseReceiptRecord receipt) {
    final firstLine = receipt.lines.isEmpty ? null : receipt.lines.first;
    final category = firstLine?.category ?? 'Uncategorized';
    final use = firstLine?.use.label ?? 'Business';
    final timeMinutes = receipt.receiptTimeMinutes;
    final ocrReview = receipt.ocrReview;
    return _CalendarExpenseData(
      sourceReceipt: receipt,
      receiptId: receipt.id,
      title: receipt.title,
      scope: use,
      category: category,
      amount: receipt.total,
      color: _colorForCategory(category),
      date: receipt.receiptDate,
      ocrStatusLabel: _calendarOcrStatusLabel(ocrReview),
      ocrRecoveryHintLabel: _calendarOcrRecoveryHintLabel(ocrReview),
      time: timeMinutes == null
          ? null
          : TimeOfDay(hour: timeMinutes ~/ 60, minute: timeMinutes % 60),
      lines: [
        for (final line in receipt.lines)
          _ReceiptLineData.fromReceiptLine(receipt, line),
      ],
    );
  }

  final String receiptId;
  final ExpenseReceiptRecord sourceReceipt;
  final String title;
  final String scope;
  final String category;
  final double amount;
  final Color color;
  final DateTime date;
  final TimeOfDay? time;
  final List<_ReceiptLineData> lines;
  final String ocrStatusLabel;
  final String ocrRecoveryHintLabel;

  String get timeLabel => _timeLabel(time);
  String get dateLabel => _dateLabel(date);
  bool get hasOcrSummary => ocrStatusLabel.trim().isNotEmpty;
  String get ocrSummaryLabel {
    final status = ocrStatusLabel.trim();
    if (status.isEmpty) return '';
    final hint = ocrRecoveryHintLabel.trim();
    return hint.isEmpty ? status : '$status: $hint';
  }
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

class _CalendarOcrDayRecap {
  const _CalendarOcrDayRecap({
    required this.receiptCount,
    required this.readCount,
    required this.reviewCount,
    required this.savedReadCount,
    required this.topRecoveryHint,
  });

  factory _CalendarOcrDayRecap.fromEntries(List<_CalendarExpenseData> entries) {
    return _CalendarOcrDayRecap.fromReceipts([
      for (final entry in entries) entry.sourceReceipt,
    ]);
  }

  factory _CalendarOcrDayRecap.fromLedgerRange(
    ExpenseLedgerController ledger,
    ExpenseDateRange range,
  ) {
    return _CalendarOcrDayRecap.fromReceipts(
      ledger.receipts.where((receipt) => range.contains(receipt.receiptDate)),
    );
  }

  factory _CalendarOcrDayRecap.fromReceipts(
    Iterable<ExpenseReceiptRecord> receipts,
  ) {
    final hintCounts = <String, int>{};
    var receiptCount = 0;
    var readCount = 0;
    var reviewCount = 0;
    var savedReadCount = 0;
    for (final receipt in receipts) {
      receiptCount++;
      final review = receipt.ocrReview;
      final status = _calendarOcrStatusLabel(review);
      if (status.isEmpty) continue;
      readCount++;
      if (status == 'Read needs review') {
        reviewCount++;
        final hint = _calendarOcrRecoveryHintLabel(review);
        if (hint.isNotEmpty) {
          hintCounts[hint] = (hintCounts[hint] ?? 0) + 1;
        }
      } else if (status == 'Read saved') {
        savedReadCount++;
      }
    }
    return _CalendarOcrDayRecap(
      receiptCount: receiptCount,
      readCount: readCount,
      reviewCount: reviewCount,
      savedReadCount: savedReadCount,
      topRecoveryHint: _topCalendarOcrHint(hintCounts),
    );
  }

  final int receiptCount;
  final int readCount;
  final int reviewCount;
  final int savedReadCount;
  final String topRecoveryHint;

  bool get hasReceipts => receiptCount > 0;
  bool get hasOcrReads => readCount > 0;
  bool get needsReview => reviewCount > 0;
  String get statusLabel {
    if (!hasReceipts) return 'No receipts yet';
    if (!hasOcrReads) return 'No receipt reads saved';
    if (needsReview) return '$reviewCount need review';
    return 'All reads saved';
  }

  String get detailLabel {
    if (!hasReceipts) return 'Add a receipt to start tracking read health.';
    if (!hasOcrReads) {
      return '$receiptCount ${receiptCount == 1 ? 'receipt' : 'receipts'} saved without receipt assistance.';
    }
    final readText = '$readCount ${readCount == 1 ? 'read' : 'reads'} saved';
    final reviewText = '$reviewCount need review';
    final savedText = '$savedReadCount saved clean';
    final parts = [
      readText,
      if (reviewCount > 0) reviewText,
      if (savedReadCount > 0) savedText,
      if (topRecoveryHint.isNotEmpty) 'Top check: $topRecoveryHint',
    ];
    return parts.join(' | ');
  }
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

String _calendarOcrStatusLabel(ExpenseReceiptOcrReview review) {
  if (!review.hasData) return '';
  return review.needsReview ? 'Read needs review' : 'Read saved';
}

String _calendarOcrRecoveryHintLabel(ExpenseReceiptOcrReview review) {
  if (!review.hasData || !review.needsReview) return '';
  final issue = review.commandCenterPrimaryIssue.trim();
  if (issue.isEmpty ||
      issue == 'No receipt-read review data' ||
      issue == 'Receipt read looks good') {
    return '';
  }
  return issue;
}

String _topCalendarOcrHint(Map<String, int> counts) {
  if (counts.isEmpty) return '';
  final entries = counts.entries.toList()
    ..sort((left, right) {
      final byCount = right.value.compareTo(left.value);
      if (byCount != 0) return byCount;
      return left.key.compareTo(right.key);
    });
  return entries.first.key;
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
