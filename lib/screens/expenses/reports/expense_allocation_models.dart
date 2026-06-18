part of 'expense_allocation_screen.dart';

enum _ReportPeriod {
  day('Daily', 'Daily'),
  week('Weekly', 'Weekly'),
  month('Monthly', 'Monthly'),
  yearToDate('YTD', 'YTD');

  const _ReportPeriod(this.buttonLabel, this.label);

  final String buttonLabel;
  final String label;

  static _ReportPeriod fromRange(ExpenseDateRange range) {
    final days = range.end.difference(range.start).inDays + 1;
    if (range.start.month == 1 && range.start.day == 1 && days > 31) {
      return _ReportPeriod.yearToDate;
    }
    if (range.start.day == 1 &&
        range.end.day ==
            DateTime(range.start.year, range.start.month + 1, 0).day) {
      return _ReportPeriod.month;
    }
    if (days == 7) return _ReportPeriod.week;
    return _ReportPeriod.day;
  }

  ExpenseDateRange rangeFor(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return switch (this) {
      _ReportPeriod.day => ExpenseDateRange(start: day, end: day),
      _ReportPeriod.week => _weekRange(day),
      _ReportPeriod.month => ExpenseDateRange(
        start: DateTime(day.year, day.month),
        end: DateTime(day.year, day.month + 1, 0),
      ),
      _ReportPeriod.yearToDate => ExpenseDateRange(
        start: DateTime(day.year),
        end: day.year == DateTime.now().year
            ? DateTime(
                DateTime.now().year,
                DateTime.now().month,
                DateTime.now().day,
              )
            : DateTime(day.year, 12, 31),
      ),
    };
  }

  DateTime shift(DateTime date, int direction) {
    return switch (this) {
      _ReportPeriod.day => date.add(Duration(days: direction)),
      _ReportPeriod.week => date.add(Duration(days: 7 * direction)),
      _ReportPeriod.month => DateTime(date.year, date.month + direction, 1),
      _ReportPeriod.yearToDate => DateTime(date.year + direction, 1, 1),
    };
  }

  String rangeLabel(DateTime date) {
    final range = rangeFor(date);
    return switch (this) {
      _ReportPeriod.day => _longDate(range.start),
      _ReportPeriod.week =>
        '${_shortDate(range.start)} - ${_shortDate(range.end)}',
      _ReportPeriod.month =>
        '${_monthName(range.start.month)} ${range.start.year}',
      _ReportPeriod.yearToDate => range.start.year.toString(),
    };
  }
}

class _AllocationReport {
  const _AllocationReport({required this.rows});

  factory _AllocationReport.fromLedger(
    ExpenseLedgerController ledger,
    ExpenseDateRange range,
  ) {
    final map = <String, _AllocationAccumulator>{};
    for (final receipt in ledger.receipts) {
      if (!range.contains(receipt.receiptDate)) continue;
      for (final line in receipt.lines) {
        final key = _normalizedCategory(line.category);
        map.putIfAbsent(key, () => _AllocationAccumulator(line.category));
        map[key]!.add(receipt, line);
      }
    }
    final rows =
        map.values
            .map((item) => item.toRow())
            .where(
              (row) =>
                  _isSharedUseCategory(row.normalizedCategory) ||
                  row.wasExplicitlySplit ||
                  row.hasBusinessAndPersonal,
            )
            .toList()
          ..sort((left, right) => right.total.compareTo(left.total));
    return _AllocationReport(rows: rows);
  }

  final List<_AllocationRow> rows;

  double get total => rows.fold(0, (sum, row) => sum + row.total);
  double get business => rows.fold(0, (sum, row) => sum + row.business);
  double get personal => rows.fold(0, (sum, row) => sum + row.personal);
  double get businessPercent => total <= 0 ? 0 : business / total;
  double get personalPercent => total <= 0 ? 0 : personal / total;

  List<_AllocationRow> visibleRows(ExpenseAllocationLimit limit) {
    return switch (limit) {
      ExpenseAllocationLimit.top10 => rows.take(10).toList(),
      ExpenseAllocationLimit.top25 => rows.take(25).toList(),
      ExpenseAllocationLimit.all => rows,
    };
  }
}

class _AllocationAccumulator {
  _AllocationAccumulator(this.label)
    : normalizedCategory = _normalizedCategory(label);

  final String label;
  final String normalizedCategory;
  var business = 0.0;
  var personal = 0.0;
  var wasExplicitlySplit = false;

  void add(ExpenseReceiptRecord receipt, ExpenseReceiptLineRecord line) {
    business += receipt.businessTotalForLine(line);
    personal += receipt.personalTotalForLine(line);
    wasExplicitlySplit = wasExplicitlySplit || line.use == ExpenseLineUse.split;
  }

  _AllocationRow toRow() {
    return _AllocationRow(
      label: _labelForCategory(label),
      normalizedCategory: normalizedCategory,
      business: business,
      personal: personal,
      wasExplicitlySplit: wasExplicitlySplit,
    );
  }
}

class _AllocationRow {
  const _AllocationRow({
    required this.label,
    required this.normalizedCategory,
    required this.business,
    required this.personal,
    required this.wasExplicitlySplit,
  });

  final String label;
  final String normalizedCategory;
  final double business;
  final double personal;
  final bool wasExplicitlySplit;

  double get total => business + personal;
  double get businessPercent => total <= 0 ? 0 : business / total;
  double get personalPercent => total <= 0 ? 0 : personal / total;
  bool get hasBusinessAndPersonal => business > 0 && personal > 0;
}

String _labelForCategory(String category) {
  for (final definition in [
    ...defaultExpenseCategories,
    ...otherExpenseCategories,
  ]) {
    if (_normalizedCategory(definition.category) ==
        _normalizedCategory(category)) {
      return definition.label;
    }
  }
  return category;
}

String _normalizedCategory(String category) {
  return switch (category.trim().toLowerCase()) {
    'cell phone' || 'phone' || 'phone bill' || 'mobile phone' => 'cell phone',
    'car payment' ||
    'vehicle payment' ||
    'loan' ||
    'lease' ||
    'loan/lease' => 'loan lease',
    'maintenance' || 'vehicle maintenance' => 'maintenance',
    'repairs' => 'repair',
    'material' || 'materials' || 'supplies' => 'materials',
    final value => value,
  };
}

bool _isSharedUseCategory(String normalizedCategory) {
  return const {
    'fuel',
    'charging fees',
    'insurance',
    'loan lease',
    'cell phone',
    'internet',
    'repair',
    'maintenance',
    'registration',
  }.contains(normalizedCategory);
}

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

String _longDate(DateTime date) {
  return '${_monthName(date.month)} ${date.day}, ${date.year}';
}

String _shortDate(DateTime date) {
  return '${date.month}/${date.day}/${date.year}';
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

String _money(double value) => '\$${value.toStringAsFixed(2)}';
