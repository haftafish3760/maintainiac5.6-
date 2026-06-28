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

int _attachmentBytes(ExpenseReceiptRecord receipt) {
  return receipt.attachments.fold(0, (sum, attachment) {
    return sum + (attachment.byteSize ?? 0);
  });
}

String _proofTypes(ExpenseReceiptRecord receipt) {
  final types = receipt.attachments.map((attachment) => attachment.kind.name);
  return types.toSet().join('|');
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
