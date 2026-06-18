import '../../../shared/data_export/csv_writer.dart';
import 'expense_ledger_models.dart';

enum ExpenseExportRangePreset {
  week('Weekly'),
  month('Monthly'),
  sinceLast('Since Last Export'),
  custom('Custom Range');

  const ExpenseExportRangePreset(this.label);

  final String label;
}

enum ExpenseExportCategoryFilter {
  all('All Categories'),
  business('Business Only'),
  personal('Personal Only'),
  vehicle('Vehicle Expenses'),
  fuel('Fuel Only'),
  materials('Materials Only');

  const ExpenseExportCategoryFilter(this.label);

  final String label;
}

enum ExpenseExportDestination {
  share('Share / Save'),
  saveFiles('Save Files'),
  email('Email'),
  textMessage('Text Message'),
  print('Print');

  const ExpenseExportDestination(this.label);

  final String label;
}

enum ExpenseExportSource {
  localDevice('Local Device', false),
  cloudBackup('Backed-Up Data', true);

  const ExpenseExportSource(this.label, this.usesBackendReads);

  final String label;
  final bool usesBackendReads;
}

class ExpenseExportSnapshot {
  const ExpenseExportSnapshot({
    required this.exportedAt,
    required this.range,
    required this.categoryFilter,
    required this.receipts,
    this.source = ExpenseExportSource.localDevice,
    this.destination = ExpenseExportDestination.share,
  });

  final DateTime exportedAt;
  final ExpenseDateRange range;
  final ExpenseExportCategoryFilter categoryFilter;
  final ExpenseExportSource source;
  final ExpenseExportDestination destination;
  final List<ExpenseReceiptRecord> receipts;

  int get receiptCount => receipts.length;
  int get lineCount => receipts.fold(0, (sum, receipt) {
    return sum + _filteredLines(receipt).length;
  });

  double get total => receipts.fold(0, (sum, receipt) {
    return sum + _filteredReceiptTotal(receipt);
  });

  String toReceiptsCsv() {
    return buildCsv([
      [
        'receipt_id',
        'receipt_date',
        'receipt_time_minutes',
        'merchant_name',
        'phone',
        'street',
        'city',
        'state',
        'zip',
        'email',
        'website',
        'has_receipt_proof',
        'line_subtotal',
        'receipt_subtotal',
        'sales_tax',
        'effective_tax_rate',
        'receipt_total',
        'business_total',
        'personal_total',
        'vehicle_id',
        'source_screen',
        'notes',
        'created_at',
        'updated_at',
      ],
      for (final receipt in receipts)
        [
          receipt.id,
          _date(receipt.receiptDate),
          receipt.receiptTimeMinutes,
          receipt.merchantName,
          receipt.phone,
          receipt.street,
          receipt.city,
          receipt.state,
          receipt.zip,
          receipt.email,
          receipt.website,
          receipt.hasReceiptProof,
          _moneyValue(receipt.lineSubtotal),
          _moneyValue(receipt.receiptSubtotal),
          _moneyValue(receipt.receiptTax),
          _ratioValue(receipt.effectiveTaxRate),
          _moneyValue(_filteredReceiptTotal(receipt)),
          _moneyValue(_filteredBusinessTotal(receipt)),
          _moneyValue(_filteredPersonalTotal(receipt)),
          receipt.vehicleId,
          receipt.sourceScreen,
          receipt.notes,
          _date(receipt.createdAt),
          _date(receipt.updatedAt),
        ],
    ]);
  }

  String toLineItemsCsv() {
    return buildCsv([
      [
        'receipt_id',
        'line_id',
        'line_number',
        'receipt_date',
        'merchant_name',
        'description',
        'category',
        'use',
        'business_percent',
        'personal_percent',
        'quantity',
        'units_per_package',
        'unit',
        'line_subtotal',
        'tax_adjusted_line_total',
        'business_amount',
        'personal_amount',
        'odometer_reading',
        'fuel_type',
        'fill_type',
        'unit_price',
      ],
      for (final receipt in receipts)
        for (var index = 0; index < receipt.lines.length; index++)
          if (_includesLine(receipt.lines[index]))
            [
              receipt.id,
              receipt.lines[index].id,
              index + 1,
              _date(receipt.receiptDate),
              receipt.merchantName,
              receipt.lines[index].description,
              receipt.lines[index].category,
              receipt.lines[index].use.label,
              _ratioValue(receipt.lines[index].effectiveBusinessPercent),
              _ratioValue(receipt.lines[index].effectivePersonalPercent),
              _quantityValue(receipt.lines[index].quantity),
              _quantityValue(receipt.lines[index].unitsPerPackage),
              receipt.lines[index].unit,
              _moneyValue(receipt.lines[index].subtotal),
              _moneyValue(receipt.totalForLine(receipt.lines[index])),
              _moneyValue(receipt.businessTotalForLine(receipt.lines[index])),
              _moneyValue(receipt.personalTotalForLine(receipt.lines[index])),
              receipt.lines[index].odometerReading,
              receipt.lines[index].fuelType,
              receipt.lines[index].fillType,
              _moneyValue(receipt.lines[index].unitPrice),
            ],
    ]);
  }

  Map<String, Object?> toManifest() {
    return {
      'app': 'Maintaniac',
      'exportType': 'expenses',
      'exportedAt': exportedAt.toIso8601String(),
      'rangeStart': range.start.toIso8601String(),
      'rangeEnd': range.end.toIso8601String(),
      'categoryFilter': categoryFilter.name,
      'source': source.name,
      'destination': destination.name,
      'receiptCount': receiptCount,
      'lineCount': lineCount,
      'total': total,
      'files': fileNames,
    };
  }

  List<String> get fileNames => const [
    'expense_receipts.csv',
    'expense_line_items.csv',
    'expense_export_manifest.json',
  ];

  List<ExpenseReceiptLineRecord> _filteredLines(ExpenseReceiptRecord receipt) {
    return receipt.lines.where(_includesLine).toList(growable: false);
  }

  double _filteredReceiptTotal(ExpenseReceiptRecord receipt) {
    return _filteredLines(
      receipt,
    ).fold(0, (sum, line) => sum + receipt.totalForLine(line));
  }

  double _filteredBusinessTotal(ExpenseReceiptRecord receipt) {
    return _filteredLines(
      receipt,
    ).fold(0, (sum, line) => sum + receipt.businessTotalForLine(line));
  }

  double _filteredPersonalTotal(ExpenseReceiptRecord receipt) {
    return _filteredLines(
      receipt,
    ).fold(0, (sum, line) => sum + receipt.personalTotalForLine(line));
  }

  bool _includesLine(ExpenseReceiptLineRecord line) {
    return _lineMatchesFilter(line, categoryFilter);
  }
}

ExpenseExportSnapshot buildExpenseExportSnapshot({
  required List<ExpenseReceiptRecord> receipts,
  required ExpenseDateRange range,
  required ExpenseExportCategoryFilter categoryFilter,
  ExpenseExportSource source = ExpenseExportSource.localDevice,
  ExpenseExportDestination destination = ExpenseExportDestination.share,
  DateTime? exportedAt,
}) {
  final filtered =
      receipts
          .where((receipt) => range.contains(receipt.receiptDate))
          .where((receipt) {
            return receipt.lines.any(
              (line) => _lineMatchesFilter(line, categoryFilter),
            );
          })
          .toList(growable: false)
        ..sort((a, b) => a.sortDate.compareTo(b.sortDate));
  return ExpenseExportSnapshot(
    exportedAt: exportedAt ?? DateTime.now(),
    range: range,
    categoryFilter: categoryFilter,
    source: source,
    destination: destination,
    receipts: filtered,
  );
}

String _date(DateTime? value) => value?.toIso8601String() ?? '';

String _moneyValue(num? value) => value == null ? '' : value.toStringAsFixed(2);

String _ratioValue(num? value) => value == null ? '' : value.toStringAsFixed(4);

String _quantityValue(num value) {
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();
}

String _normalized(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
}

bool _lineMatchesFilter(
  ExpenseReceiptLineRecord line,
  ExpenseExportCategoryFilter filter,
) {
  final category = _normalized(line.category);
  return switch (filter) {
    ExpenseExportCategoryFilter.all => true,
    ExpenseExportCategoryFilter.business => line.use != ExpenseLineUse.personal,
    ExpenseExportCategoryFilter.personal => line.use != ExpenseLineUse.business,
    ExpenseExportCategoryFilter.vehicle => _vehicleCategories.contains(
      category,
    ),
    ExpenseExportCategoryFilter.fuel => category == 'fuel',
    ExpenseExportCategoryFilter.materials =>
      category == 'materials' || category == 'supplies',
  };
}

const _vehicleCategories = {
  'fuel',
  'fuel_additives',
  'charging_fees',
  'maintenance',
  'repairs',
  'repair',
  'insurance',
  'loan_lease',
  'registration',
  'parking',
  'tolls',
};
