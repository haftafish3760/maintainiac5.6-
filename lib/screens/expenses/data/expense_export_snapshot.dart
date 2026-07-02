part of 'expense_export_models.dart';

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

  static const commandCenterOcrContractSchema =
      'expense_ocr_recovery_summary_v1';
  static const commandCenterOcrPrivacyScope = 'summary_only_no_receipt_content';
  static const commandCenterOcrContentPolicy =
      'no_receipt_images_no_raw_ocr_text_no_item_descriptions';
  static const commandCenterOcrAllowedKeys = <String>{
    'schema',
    'privacyScope',
    'contentPolicy',
    'rangeStart',
    'rangeEnd',
    'categoryFilter',
    'source',
    'destination',
    'receiptCount',
    'receiptsWithOcrReview',
    'receiptsNeedingOcrReview',
    'ocrReadsSaved',
    'ocrCleanReadCount',
    'ocrReadStatus',
    'ocrReadSummary',
    'ocrWarningCount',
    'ocrBlockingWarningCount',
    'ocrPartialWarningCount',
    'ocrReviewWarningCount',
    'ocrSourceCounts',
    'ocrTopSource',
    'ocrPrimaryWarningKindCounts',
    'ocrRecoveryActionCounts',
    'ocrRecoveryTargetCounts',
    'ocrTopCheck',
    'ocrTopPrimaryIssue',
    'ocrTopPrimaryAction',
    'ocrTopRecoveryAction',
    'ocrTopRecoveryTarget',
  };

  static List<String> commandCenterOcrContractFindingsFor(
    Map<String, Object?> contract,
  ) {
    return _commandCenterOcrContractPrivacyFindings(contract);
  }

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
        'receipt_proof_count',
        'receipt_proof_types',
        'saved_proof_bytes',
        'ocr_review_status',
        'ocr_warning_count',
        'ocr_primary_warning_kind',
        'ocr_recovery_action',
        'ocr_recovery_target',
        'ocr_primary_issue',
        'ocr_primary_action',
        'ocr_parser_line_count',
        'ocr_pdf_pages_requested',
        'line_subtotal',
        'receipt_subtotal',
        'sales_tax',
        'effective_tax_rate',
        'receipt_total',
        'business_total',
        'personal_total',
        'vehicle_id',
        'odometer_reading',
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
          receipt.hasReceiptAttachment,
          receipt.attachments.length,
          _proofTypes(receipt),
          _attachmentBytes(receipt),
          receipt.ocrReview.hasData ? receipt.ocrReview.severity : '',
          receipt.ocrReview.warningCount,
          receipt.ocrReview.primaryWarningKind,
          receipt.ocrReview.commandCenterSummary['recoveryAction'] ?? '',
          receipt.ocrReview.commandCenterSummary['recoveryTarget'] ?? '',
          receipt.ocrReview.commandCenterPrimaryIssue,
          receipt.ocrReview.commandCenterPrimaryAction,
          receipt.ocrReview.parserLineCount,
          receipt.ocrReview.pdfPagesRequested,
          _moneyValue(receipt.lineSubtotal),
          _moneyValue(receipt.receiptSubtotal),
          _moneyValue(receipt.receiptTax),
          _ratioValue(receipt.effectiveTaxRate),
          _moneyValue(_filteredReceiptTotal(receipt)),
          _moneyValue(_filteredBusinessTotal(receipt)),
          _moneyValue(_filteredPersonalTotal(receipt)),
          receipt.vehicleId,
          receipt.odometerReading,
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
      'app': 'Maintainiac',
      'exportType': 'expenses',
      'exportedAt': exportedAt.toIso8601String(),
      'rangeStart': range.start.toIso8601String(),
      'rangeEnd': range.end.toIso8601String(),
      'categoryFilter': categoryFilter.name,
      'source': source.name,
      'destination': destination.name,
      'receiptCount': receiptCount,
      'lineCount': lineCount,
      'receiptProofCount': receiptProofCount,
      'receiptProofBytes': receiptProofBytes,
      'receiptsMissingProof': receiptsMissingProof,
      'receiptsWithOcrReview': receiptsWithOcrReview,
      'receiptsNeedingOcrReview': receiptsNeedingOcrReview,
      'ocrReadStatus': ocrReadStatus,
      'ocrReadSummary': ocrReadSummary,
      'ocrReadsSaved': ocrReadsSaved,
      'ocrCleanReadCount': ocrCleanReadCount,
      'ocrTopCheck': ocrTopCheck,
      'ocrWarningCount': totalOcrWarningCount,
      'ocrBlockingWarningCount': totalOcrBlockingWarningCount,
      'ocrPartialWarningCount': totalOcrPartialWarningCount,
      'ocrReviewWarningCount': totalOcrReviewWarningCount,
      'ocrSourceCounts': ocrSourceCounts,
      'ocrTopSource': ocrTopSource,
      'ocrPrimaryWarningKindCounts': ocrPrimaryWarningKindCounts,
      'ocrRecoveryActionCounts': ocrRecoveryActionCounts,
      'ocrRecoveryTargetCounts': ocrRecoveryTargetCounts,
      'ocrTopPrimaryIssue': ocrTopPrimaryIssue,
      'ocrTopPrimaryAction': ocrTopPrimaryAction,
      'ocrTopRecoveryAction': ocrTopRecoveryAction,
      'ocrTopRecoveryTarget': ocrTopRecoveryTarget,
      'commandCenterOcrContract': commandCenterOcrContract,
      'total': total,
      'files': fileNames,
      'privacyNote':
          'Receipt exports include proof metadata and totals only. Raw OCR text and receipt images are not embedded by default.',
    };
  }

  Map<String, Object?> get commandCenterOcrContract {
    return _expenseExportCommandCenterOcrContract(this);
  }

  List<String> get commandCenterOcrContractPrivacyFindings {
    return commandCenterOcrContractFindingsFor(commandCenterOcrContract);
  }

  int get receiptProofCount {
    return receipts.fold(0, (sum, receipt) => sum + receipt.attachments.length);
  }

  int get receiptProofBytes {
    return receipts.fold(0, (sum, receipt) => sum + _attachmentBytes(receipt));
  }

  int get receiptsMissingProof {
    return receipts.where((receipt) => !receipt.hasReceiptAttachment).length;
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
