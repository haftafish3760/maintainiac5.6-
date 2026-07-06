import '../../../shared/data_export/csv_writer.dart';
import '../../../shared/document_engine/document_engine_core.dart';
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

  List<String> get privacyIssueCodes {
    return AppPdfPrivacyPolicy.issueCodesForExport(
      bytes: const [],
      metadata: exportPrivacyMetadata,
    );
  }

  bool get canExport => privacyIssueCodes.isEmpty;

  void ensureCanExport() {
    final issues = privacyIssueCodes;
    if (issues.isEmpty) return;
    throw ExpenseExportPrivacyException(issues);
  }

  Iterable<String> get exportPrivacyMetadata sync* {
    yield range.start.toIso8601String();
    yield range.end.toIso8601String();
    yield categoryFilter.name;
    yield source.name;
    yield destination.name;
    yield ocrReadStatus;
    yield ocrReadSummary;
    yield ocrTopCheck;
    yield ocrTopSource;
    yield ocrTopPrimaryIssue;
    yield ocrTopPrimaryAction;
    yield ocrTopRecoveryAction;
    yield ocrTopRecoveryTarget;
    yield* _mapPrivacyMetadata('ocrSourceCounts', ocrSourceCounts);
    yield* _mapPrivacyMetadata(
      'ocrPrimaryWarningKindCounts',
      ocrPrimaryWarningKindCounts,
    );
    yield* _mapPrivacyMetadata(
      'ocrRecoveryActionCounts',
      ocrRecoveryActionCounts,
    );
    yield* _mapPrivacyMetadata(
      'ocrRecoveryTargetCounts',
      ocrRecoveryTargetCounts,
    );
    for (var receiptIndex = 0; receiptIndex < receipts.length; receiptIndex++) {
      final receipt = receipts[receiptIndex];
      yield _receiptExportRef(receiptIndex);
      yield receipt.merchantName;
      yield receipt.phone;
      yield receipt.street;
      yield receipt.city;
      yield receipt.state;
      yield receipt.zip;
      yield receipt.email;
      yield receipt.website;
      yield receipt.vehicleId ?? '';
      yield '${receipt.odometerReading ?? ''}';
      yield receipt.sourceScreen;
      yield receipt.notes;
      yield receipt.ocrReview.severity;
      yield receipt.ocrReview.source;
      yield receipt.ocrReview.primaryWarningKind;
      yield receipt.ocrReview.commandCenterPrimaryIssue;
      yield receipt.ocrReview.commandCenterPrimaryAction;
      for (final entry in receipt.ocrReview.commandCenterSummary.entries) {
        yield 'ocrSummary.${entry.key}=${entry.value}';
      }
      for (final line in _filteredLines(receipt)) {
        yield _lineExportRef(receiptIndex, receipt.lines.indexOf(line));
        yield line.description;
        yield line.category;
        yield line.unit;
        yield line.fuelType ?? '';
        yield line.fillType ?? '';
        yield '${line.odometerReading ?? ''}';
      }
    }
  }

  String toReceiptsCsv() {
    return buildCsv([
      [
        'receipt_export_ref',
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
      for (var receiptIndex = 0; receiptIndex < receipts.length; receiptIndex++)
        [
          _receiptExportRef(receiptIndex),
          _date(receipts[receiptIndex].receiptDate),
          receipts[receiptIndex].receiptTimeMinutes,
          receipts[receiptIndex].merchantName,
          receipts[receiptIndex].phone,
          receipts[receiptIndex].street,
          receipts[receiptIndex].city,
          receipts[receiptIndex].state,
          receipts[receiptIndex].zip,
          receipts[receiptIndex].email,
          receipts[receiptIndex].website,
          receipts[receiptIndex].hasReceiptAttachment,
          receipts[receiptIndex].attachments.length,
          _proofTypes(receipts[receiptIndex]),
          _attachmentBytes(receipts[receiptIndex]),
          receipts[receiptIndex].ocrReview.hasData
              ? receipts[receiptIndex].ocrReview.severity
              : '',
          receipts[receiptIndex].ocrReview.warningCount,
          receipts[receiptIndex].ocrReview.primaryWarningKind,
          receipts[receiptIndex]
                  .ocrReview
                  .commandCenterSummary['recoveryAction'] ??
              '',
          receipts[receiptIndex]
                  .ocrReview
                  .commandCenterSummary['recoveryTarget'] ??
              '',
          receipts[receiptIndex].ocrReview.commandCenterPrimaryIssue,
          receipts[receiptIndex].ocrReview.commandCenterPrimaryAction,
          receipts[receiptIndex].ocrReview.parserLineCount,
          receipts[receiptIndex].ocrReview.pdfPagesRequested,
          _moneyValue(receipts[receiptIndex].lineSubtotal),
          _moneyValue(receipts[receiptIndex].receiptSubtotal),
          _moneyValue(receipts[receiptIndex].receiptTax),
          _ratioValue(receipts[receiptIndex].effectiveTaxRate),
          _moneyValue(_filteredReceiptTotal(receipts[receiptIndex])),
          _moneyValue(_filteredBusinessTotal(receipts[receiptIndex])),
          _moneyValue(_filteredPersonalTotal(receipts[receiptIndex])),
          receipts[receiptIndex].vehicleId,
          receipts[receiptIndex].odometerReading,
          receipts[receiptIndex].sourceScreen,
          receipts[receiptIndex].notes,
          _date(receipts[receiptIndex].createdAt),
          _date(receipts[receiptIndex].updatedAt),
        ],
    ]);
  }

  String toLineItemsCsv() {
    return buildCsv([
      [
        'receipt_export_ref',
        'line_export_ref',
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
      for (var receiptIndex = 0; receiptIndex < receipts.length; receiptIndex++)
        for (
          var lineIndex = 0;
          lineIndex < receipts[receiptIndex].lines.length;
          lineIndex++
        )
          if (_includesLine(receipts[receiptIndex].lines[lineIndex]))
            [
              _receiptExportRef(receiptIndex),
              _lineExportRef(receiptIndex, lineIndex),
              lineIndex + 1,
              _date(receipts[receiptIndex].receiptDate),
              receipts[receiptIndex].merchantName,
              receipts[receiptIndex].lines[lineIndex].description,
              receipts[receiptIndex].lines[lineIndex].category,
              receipts[receiptIndex].lines[lineIndex].use.label,
              _ratioValue(
                receipts[receiptIndex]
                    .lines[lineIndex]
                    .effectiveBusinessPercent,
              ),
              _ratioValue(
                receipts[receiptIndex]
                    .lines[lineIndex]
                    .effectivePersonalPercent,
              ),
              _quantityValue(receipts[receiptIndex].lines[lineIndex].quantity),
              _quantityValue(
                receipts[receiptIndex].lines[lineIndex].unitsPerPackage,
              ),
              receipts[receiptIndex].lines[lineIndex].unit,
              _moneyValue(receipts[receiptIndex].lines[lineIndex].subtotal),
              _moneyValue(
                taxAdjustedTotalForLine(
                  receipts[receiptIndex],
                  receipts[receiptIndex].lines[lineIndex],
                ),
              ),
              _moneyValue(
                businessTotalForLine(
                  receipts[receiptIndex],
                  receipts[receiptIndex].lines[lineIndex],
                ),
              ),
              _moneyValue(
                personalTotalForLine(
                  receipts[receiptIndex],
                  receipts[receiptIndex].lines[lineIndex],
                ),
              ),
              receipts[receiptIndex].lines[lineIndex].odometerReading,
              receipts[receiptIndex].lines[lineIndex].fuelType,
              receipts[receiptIndex].lines[lineIndex].fillType,
              _moneyValue(receipts[receiptIndex].lines[lineIndex].unitPrice),
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
    final contract = {
      'schema': commandCenterOcrContractSchema,
      'privacyScope': commandCenterOcrPrivacyScope,
      'contentPolicy': commandCenterOcrContentPolicy,
      'rangeStart': range.start.toIso8601String(),
      'rangeEnd': range.end.toIso8601String(),
      'categoryFilter': categoryFilter.name,
      'source': source.name,
      'destination': destination.name,
      'receiptCount': receiptCount,
      'receiptsWithOcrReview': receiptsWithOcrReview,
      'receiptsNeedingOcrReview': receiptsNeedingOcrReview,
      'ocrReadsSaved': ocrReadsSaved,
      'ocrCleanReadCount': ocrCleanReadCount,
      'ocrReadStatus': ocrReadStatus,
      'ocrReadSummary': ocrReadSummary,
      'ocrWarningCount': totalOcrWarningCount,
      'ocrBlockingWarningCount': totalOcrBlockingWarningCount,
      'ocrPartialWarningCount': totalOcrPartialWarningCount,
      'ocrReviewWarningCount': totalOcrReviewWarningCount,
      'ocrSourceCounts': ocrSourceCounts,
      'ocrTopSource': ocrTopSource,
      'ocrPrimaryWarningKindCounts': ocrPrimaryWarningKindCounts,
      'ocrRecoveryActionCounts': ocrRecoveryActionCounts,
      'ocrRecoveryTargetCounts': ocrRecoveryTargetCounts,
      'ocrTopCheck': ocrTopCheck,
      'ocrTopPrimaryIssue': ocrTopPrimaryIssue,
      'ocrTopPrimaryAction': ocrTopPrimaryAction,
      'ocrTopRecoveryAction': ocrTopRecoveryAction,
      'ocrTopRecoveryTarget': ocrTopRecoveryTarget,
    };
    assert(_isCommandCenterOcrContractSafe(contract));
    return contract;
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

  int get receiptsWithOcrReview {
    return receipts.where((receipt) => receipt.ocrReview.hasData).length;
  }

  int get receiptsNeedingOcrReview {
    return receipts.where((receipt) => receipt.ocrReview.needsReview).length;
  }

  int get ocrReadsSaved {
    return receipts.where((receipt) => receipt.ocrReview.hasData).length;
  }

  int get ocrCleanReadCount {
    return receipts.where((receipt) {
      final review = receipt.ocrReview;
      return review.hasData && !review.needsReview;
    }).length;
  }

  String get ocrReadStatus {
    if (receiptCount == 0) return 'No receipts exported';
    if (ocrReadsSaved == 0) return 'No receipt reads exported';
    if (receiptsNeedingOcrReview > 0) {
      return '$receiptsNeedingOcrReview need review';
    }
    return 'All reads saved';
  }

  String get ocrReadSummary {
    if (receiptCount == 0) return 'No receipts in this export.';
    if (ocrReadsSaved == 0) {
      return '$receiptCount ${receiptCount == 1 ? 'receipt' : 'receipts'} exported without receipt reading.';
    }
    final parts = [
      '$ocrReadsSaved ${ocrReadsSaved == 1 ? 'read' : 'reads'} saved',
      if (receiptsNeedingOcrReview > 0) '$receiptsNeedingOcrReview need review',
      if (ocrCleanReadCount > 0) '$ocrCleanReadCount saved clean',
      if (ocrTopCheck.isNotEmpty) 'Top check: $ocrTopCheck',
    ];
    return parts.join(' | ');
  }

  String get ocrTopCheck {
    final topKind = _topCountKey(ocrPrimaryWarningKindCounts);
    if (topKind.isEmpty) return '';
    for (final receipt in receipts) {
      if (receipt.ocrReview.primaryWarningKind == topKind) {
        return receipt.ocrReview.commandCenterPrimaryIssue;
      }
    }
    return '';
  }

  int get totalOcrWarningCount {
    return receipts.fold(
      0,
      (sum, receipt) => sum + receipt.ocrReview.warningCount,
    );
  }

  int get totalOcrBlockingWarningCount {
    return receipts.fold(
      0,
      (sum, receipt) => sum + receipt.ocrReview.blockingWarningCount,
    );
  }

  int get totalOcrPartialWarningCount {
    return receipts.fold(
      0,
      (sum, receipt) => sum + receipt.ocrReview.partialWarningCount,
    );
  }

  int get totalOcrReviewWarningCount {
    return receipts.fold(
      0,
      (sum, receipt) => sum + receipt.ocrReview.reviewWarningCount,
    );
  }

  Map<String, int> get ocrPrimaryWarningKindCounts {
    final counts = <String, int>{};
    for (final receipt in receipts) {
      final kind = receipt.ocrReview.primaryWarningKind.trim();
      if (kind.isEmpty) continue;
      counts.update(kind, (count) => count + 1, ifAbsent: () => 1);
    }
    return Map.unmodifiable(counts);
  }

  Map<String, int> get ocrSourceCounts {
    final counts = <String, int>{};
    for (final receipt in receipts) {
      final source = receipt.ocrReview.source.trim();
      if (source.isEmpty) continue;
      counts.update(source, (count) => count + 1, ifAbsent: () => 1);
    }
    return Map.unmodifiable(counts);
  }

  String get ocrTopSource {
    return _topCountKey(ocrSourceCounts);
  }

  Map<String, int> get ocrRecoveryActionCounts {
    final counts = <String, int>{};
    for (final receipt in receipts) {
      final action =
          '${receipt.ocrReview.commandCenterSummary['recoveryAction']}'.trim();
      if (action.isEmpty) continue;
      counts.update(action, (count) => count + 1, ifAbsent: () => 1);
    }
    return Map.unmodifiable(counts);
  }

  Map<String, int> get ocrRecoveryTargetCounts {
    final counts = <String, int>{};
    for (final receipt in receipts) {
      final target =
          '${receipt.ocrReview.commandCenterSummary['recoveryTarget']}'.trim();
      if (target.isEmpty) continue;
      counts.update(target, (count) => count + 1, ifAbsent: () => 1);
    }
    return Map.unmodifiable(counts);
  }

  String get ocrTopRecoveryAction {
    return _topCountKey(ocrRecoveryActionCounts);
  }

  String get ocrTopRecoveryTarget {
    return _topCountKey(ocrRecoveryTargetCounts);
  }

  String get ocrTopPrimaryIssue {
    final topKind = _topCountKey(ocrPrimaryWarningKindCounts);
    if (topKind.isEmpty) return '';
    for (final receipt in receipts) {
      if (receipt.ocrReview.primaryWarningKind == topKind) {
        return receipt.ocrReview.commandCenterPrimaryIssue;
      }
    }
    return topKind;
  }

  String get ocrTopPrimaryAction {
    final topKind = _topCountKey(ocrPrimaryWarningKindCounts);
    if (topKind.isEmpty) return '';
    for (final receipt in receipts) {
      if (receipt.ocrReview.primaryWarningKind == topKind) {
        return receipt.ocrReview.commandCenterPrimaryAction;
      }
    }
    return '';
  }

  List<String> get fileNames => const [
    'expense_receipts.csv',
    'expense_line_items.csv',
    'expense_export_manifest.json',
  ];

  List<ExpenseReceiptLineRecord> filteredLinesFor(
    ExpenseReceiptRecord receipt,
  ) {
    return _filteredLines(receipt);
  }

  double taxAdjustedTotalForLine(
    ExpenseReceiptRecord receipt,
    ExpenseReceiptLineRecord line,
  ) {
    return _allocatedMoneyForFilteredLine(receipt, line, receipt.totalForLine);
  }

  double businessTotalForLine(
    ExpenseReceiptRecord receipt,
    ExpenseReceiptLineRecord line,
  ) {
    return _allocatedMoneyForFilteredLine(
      receipt,
      line,
      receipt.businessTotalForLine,
    );
  }

  double personalTotalForLine(
    ExpenseReceiptRecord receipt,
    ExpenseReceiptLineRecord line,
  ) {
    return _allocatedMoneyForFilteredLine(
      receipt,
      line,
      receipt.personalTotalForLine,
    );
  }

  List<ExpenseReceiptLineRecord> _filteredLines(ExpenseReceiptRecord receipt) {
    return receipt.lines.where(_includesLine).toList(growable: false);
  }

  double _filteredReceiptTotal(ExpenseReceiptRecord receipt) {
    return _allocatedMoneyTotal(receipt, receipt.totalForLine);
  }

  double _filteredBusinessTotal(ExpenseReceiptRecord receipt) {
    return _allocatedMoneyTotal(receipt, receipt.businessTotalForLine);
  }

  double _filteredPersonalTotal(ExpenseReceiptRecord receipt) {
    return _allocatedMoneyTotal(receipt, receipt.personalTotalForLine);
  }

  bool _includesLine(ExpenseReceiptLineRecord line) {
    return _lineMatchesFilter(line, categoryFilter);
  }

  double _allocatedMoneyForFilteredLine(
    ExpenseReceiptRecord receipt,
    ExpenseReceiptLineRecord line,
    double Function(ExpenseReceiptLineRecord line) rawAmountForLine,
  ) {
    final lines = _filteredLines(receipt);
    final lineIndex = lines.indexOf(line);
    if (lineIndex < 0) return 0;
    return _allocatedMoneyCents(lines, rawAmountForLine)[lineIndex] / 100;
  }

  double _allocatedMoneyTotal(
    ExpenseReceiptRecord receipt,
    double Function(ExpenseReceiptLineRecord line) rawAmountForLine,
  ) {
    return _allocatedMoneyCents(
          _filteredLines(receipt),
          rawAmountForLine,
        ).fold<int>(0, (sum, cents) => sum + cents) /
        100;
  }
}

class ExpenseExportPrivacyException implements Exception {
  const ExpenseExportPrivacyException(this.issues);

  final List<String> issues;

  @override
  String toString() {
    return 'Expense export blocked for private fields: ${issues.join(', ')}';
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

List<int> _allocatedMoneyCents(
  List<ExpenseReceiptLineRecord> lines,
  double Function(ExpenseReceiptLineRecord line) rawAmountForLine,
) {
  if (lines.isEmpty) return const [];
  final rawAmounts = [for (final line in lines) rawAmountForLine(line)];
  final targetCents = _moneyCents(
    rawAmounts.fold<double>(0, (sum, amount) => sum + amount),
  );
  final floors = [
    for (final amount in rawAmounts) _floorTowardNegativeInfinity(amount * 100),
  ];
  var remainder =
      targetCents - floors.fold<int>(0, (sum, cents) => sum + cents);
  final order = List<int>.generate(lines.length, (index) => index)
    ..sort((left, right) {
      final remainderCompare = _centRemainder(
        rawAmounts[right],
      ).compareTo(_centRemainder(rawAmounts[left]));
      if (remainderCompare != 0) return remainderCompare;
      return left.compareTo(right);
    });
  final cents = floors.toList(growable: false);
  var orderIndex = 0;
  while (remainder > 0 && order.isNotEmpty) {
    cents[order[orderIndex % order.length]] += 1;
    remainder -= 1;
    orderIndex += 1;
  }
  while (remainder < 0 && order.isNotEmpty) {
    cents[order.reversed.elementAt(orderIndex % order.length)] -= 1;
    remainder += 1;
    orderIndex += 1;
  }
  return cents;
}

int _moneyCents(num value) => (value * 100).round();

int _floorTowardNegativeInfinity(num value) => value.floor();

double _centRemainder(num value) {
  final cents = value * 100;
  return (cents - cents.floor()).toDouble();
}

String _receiptExportRef(int receiptIndex) {
  return 'receipt_${(receiptIndex + 1).toString().padLeft(4, '0')}';
}

String _lineExportRef(int receiptIndex, int lineIndex) {
  return '${_receiptExportRef(receiptIndex)}_line_${(lineIndex + 1).toString().padLeft(4, '0')}';
}

int _attachmentBytes(ExpenseReceiptRecord receipt) {
  return receipt.attachments.fold(0, (sum, attachment) {
    return sum + (attachment.byteSize ?? 0);
  });
}

String _proofTypes(ExpenseReceiptRecord receipt) {
  final types = receipt.attachments.map((attachment) => attachment.kind.name);
  return types.toSet().join('|');
}

Iterable<String> _mapPrivacyMetadata(
  String name,
  Map<String, int> values,
) sync* {
  for (final entry in values.entries) {
    yield '$name.${entry.key}=${entry.value}';
  }
}

String _topCountKey(Map<String, int> counts) {
  if (counts.isEmpty) return '';
  final entries = counts.entries.toList(growable: false)
    ..sort((left, right) {
      final count = right.value.compareTo(left.value);
      if (count != 0) return count;
      return left.key.compareTo(right.key);
    });
  return entries.first.key;
}

bool _isCommandCenterOcrContractSafe(Map<String, Object?> contract) {
  return _commandCenterOcrContractPrivacyFindings(contract).isEmpty;
}

List<String> _commandCenterOcrContractPrivacyFindings(
  Map<String, Object?> contract,
) {
  final findings = <String>[];
  final allowedKeys = ExpenseExportSnapshot.commandCenterOcrAllowedKeys;
  for (final key in contract.keys) {
    if (!allowedKeys.contains(key)) {
      findings.add('unexpected_key:$key');
    }
  }
  for (final key in allowedKeys) {
    if (!contract.containsKey(key)) {
      findings.add('missing_key:$key');
    }
  }
  for (final entry in contract.entries) {
    _inspectCommandCenterOcrValue(
      findings: findings,
      path: entry.key,
      key: entry.key,
      value: entry.value,
    );
  }
  return List.unmodifiable(findings);
}

void _inspectCommandCenterOcrValue({
  required List<String> findings,
  required String path,
  required String key,
  required Object? value,
}) {
  switch (value) {
    case null:
      return;
    case bool():
      return;
    case num():
      if (value.isNaN || value.isInfinite || value < 0) {
        findings.add('invalid_number:$path');
      }
      return;
    case String():
      if (_commandCenterOcrStringLooksPrivate(key, value)) {
        findings.add('private_text:$path');
      }
      return;
    case Map():
      for (final entry in value.entries) {
        final nestedKey = '${entry.key}';
        if (_commandCenterOcrMapKeyLooksPrivate(path, nestedKey)) {
          findings.add('private_map_key:$path.$nestedKey');
        }
        final nestedValue = entry.value;
        if (nestedValue is! num || nestedValue < 0) {
          findings.add('invalid_map_value:$path.$nestedKey');
        }
      }
      return;
    case Iterable():
      findings.add('unexpected_list:$path');
      return;
    default:
      findings.add('unsupported_value:$path');
  }
}

bool _commandCenterOcrMapKeyLooksPrivate(String path, String key) {
  final token = key.trim();
  if (token.isEmpty || token.length > 80) return true;
  if (!RegExp(r'^[A-Za-z][A-Za-z0-9_]*$').hasMatch(token)) return true;
  return _commandCenterOcrSensitiveTextPatterns.any(
    (pattern) => pattern.hasMatch(token.toLowerCase()),
  );
}

bool _commandCenterOcrStringLooksPrivate(String key, String value) {
  final text = value.trim();
  if (text.isEmpty) return false;
  if (_commandCenterOcrIsoOrTokenKeys.contains(key)) return false;
  if (_commandCenterOcrSensitiveKeyPatterns.any((pattern) {
    return pattern.hasMatch(key.toLowerCase());
  })) {
    return true;
  }
  if (text.length > 260) return true;
  return _commandCenterOcrSensitiveTextPatterns.any(
    (pattern) => pattern.hasMatch(text.toLowerCase()),
  );
}

const _commandCenterOcrIsoOrTokenKeys = <String>{
  'schema',
  'privacyScope',
  'contentPolicy',
  'rangeStart',
  'rangeEnd',
  'categoryFilter',
  'source',
  'destination',
  'ocrTopSource',
  'ocrTopRecoveryAction',
  'ocrTopRecoveryTarget',
};

final _commandCenterOcrSensitiveTextPatterns = <RegExp>[
  RegExp(r'[/\\][a-z0-9_. -]+[/\\]', caseSensitive: false),
  RegExp(r'\b[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}\b'),
  RegExp(r'\(?\b\d{3}\)?[-.\s]\d{3}[-.\s]\d{4}\b'),
  RegExp(r'\$?\b\d{1,5}[.,]\d{2}\b'),
  RegExp(r'(?:^|[^a-z0-9])private[_\s]?store(?:$|[^a-z0-9])'),
  RegExp(r'(?:^|[^a-z0-9])shop[_\s]?towels(?:$|[^a-z0-9])'),
  RegExp(r'(?:^|[^a-z0-9])personal[_\s]?item(?:$|[^a-z0-9])'),
  RegExp(
    r'\b(?:invoice|auth|transaction|terminal|address|street|st\.?|avenue|ave\.?|lane|ln\.?|road|rd\.?|drive|dr\.?|boulevard|blvd\.?|suite|unit|zip)\b',
  ),
  RegExp(
    r'\b(?:lowe|lowes|lowe'
    's|walmart|target|amazon|shell|exxon|mobil|chevron|marathon|sheetz|private store|customer|shop towels|personal item)\b',
  ),
  RegExp(r'\.(?:jpg|jpeg|png|heic|pdf)\b'),
];

final _commandCenterOcrSensitiveKeyPatterns = <RegExp>[
  RegExp(r'merchant'),
  RegExp(r'customer'),
  RegExp(r'address'),
  RegExp(r'phone'),
  RegExp(r'email'),
  RegExp(r'note'),
  RegExp(r'description'),
  RegExp(r'raw'),
  RegExp(r'image'),
  RegExp(r'path'),
  RegExp(r'proof'),
];

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
