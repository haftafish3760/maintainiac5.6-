import '../../../shared/data_export/csv_writer.dart';
import 'expense_ledger_models.dart';

part 'expense_export_snapshot.dart';
part 'expense_export_snapshot_ocr_summary.dart';
part 'expense_export_ocr_contract.dart';

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
    ExpenseExportCategoryFilter.business =>
      line.use == ExpenseLineUse.business || line.use == ExpenseLineUse.split,
    ExpenseExportCategoryFilter.personal =>
      line.use == ExpenseLineUse.personal || line.use == ExpenseLineUse.split,
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
