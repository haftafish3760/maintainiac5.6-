import 'dart:convert';
import 'dart:io';

const _allowedResultCategories = {
  'correct',
  'review_required',
  'unknown',
  'wrong',
};

const _allowedMerchantCategories = {
  'home_improvement_big_box',
  'hardware_store',
  'local_hardware',
  'regional_chain',
  'plumbing_supply_house',
  'electrical_supply_house',
  'hvac_supply_house',
  'industrial_supply',
  'farm_ranch_supply',
  'mass_retailer',
  'online_supplier',
  'unknown_merchant',
};

const _forbiddenArgumentNames = {
  'raw',
  'rawLine',
  'raw-line',
  'rawReceipt',
  'raw-receipt',
  'rawReceiptText',
  'raw-receipt-text',
  'receiptText',
  'receipt-text',
  'ocrText',
  'ocr-text',
  'photoPath',
  'photo-path',
  'imagePath',
  'image-path',
};

final _forbiddenPrivateValuePatterns = {
  'card_like_number': RegExp(r'\b\d{12,19}\b'),
  'email': RegExp(
    r'\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b',
    caseSensitive: false,
  ),
  'phone': RegExp(r'\b(?:\+?1[-.\s]?)?\(?\d{3}\)?[-.\s]\d{3}[-.\s]\d{4}\b'),
  'street_address': RegExp(
    r"\b\d{1,6}\s+[A-Z0-9 .'-]+\s+"
    r'(?:st|street|rd|road|ave|avenue|dr|drive|ln|lane|blvd|boulevard)\b',
    caseSensitive: false,
  ),
  'receipt_identifier': RegExp(
    r'\b(?:receipt|transaction|terminal|register|cashier|auth|approval|store)\s*#?\s*[A-Z0-9-]{3,}\b',
    caseSensitive: false,
  ),
};

void main(List<String> args) {
  final result = runRealReceiptValidationLog(args);
  if (result.exitCode != 0) {
    stderr.writeln(result.message);
    exitCode = result.exitCode;
    return;
  }
  stdout.writeln(result.message);
}

RealReceiptValidationLogResult runRealReceiptValidationLog(List<String> args) {
  final parsed = _parseArgs(args);
  if (parsed.error != null) {
    return RealReceiptValidationLogResult.failure(parsed.error!);
  }
  final values = parsed.values;
  final output = values['output'] ?? '';
  if (output.trim().isEmpty) {
    return const RealReceiptValidationLogResult.failure(
      'Missing --output. Write private receipt validation summaries under build/.',
    );
  }
  if (!_isBuildPath(output)) {
    return RealReceiptValidationLogResult.failure(
      'Refusing to write outside build/: $output',
    );
  }

  final summaryResult = buildRealReceiptValidationSummary(values);
  if (summaryResult.error != null) {
    return RealReceiptValidationLogResult.failure(summaryResult.error!);
  }

  final file = File(output);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(summaryResult.summary),
  );

  return RealReceiptValidationLogResult.success(
    'QA_REAL_RECEIPT_VALIDATION_LOG output=$output '
    'rawReceiptStored=false liveServicesAllowed=false',
  );
}

RealReceiptValidationSummaryResult buildRealReceiptValidationSummary(
  Map<String, String> values,
) {
  for (final key in values.keys) {
    if (_forbiddenArgumentNames.contains(key)) {
      return RealReceiptValidationSummaryResult.failure(
        'Forbidden private receipt field: --$key',
      );
    }
  }
  for (final entry in values.entries) {
    if (entry.key == 'output') continue;
    final blocked = _blockedPrivateValueKind(entry.value);
    if (blocked == null) continue;
    return RealReceiptValidationSummaryResult.failure(
      'Forbidden private receipt value in --${entry.key}: $blocked',
    );
  }

  final merchantCategory = _required(values, 'merchant-category');
  final expectedItemFamily = _required(values, 'expected-item-family');
  final resultCategory = _required(values, 'result-category');
  if (merchantCategory == null ||
      expectedItemFamily == null ||
      resultCategory == null) {
    return RealReceiptValidationSummaryResult.failure(
      'Missing required fields: --merchant-category, '
      '--expected-item-family, --result-category.',
    );
  }
  if (!_allowedMerchantCategories.contains(merchantCategory)) {
    return RealReceiptValidationSummaryResult.failure(
      'Unsupported merchant category: $merchantCategory. '
      'Use a safe category such as ${_allowedMerchantCategories.join(', ')}.',
    );
  }
  if (!_allowedResultCategories.contains(resultCategory)) {
    return RealReceiptValidationSummaryResult.failure(
      'Unsupported result category: $resultCategory. '
      'Use ${_allowedResultCategories.join(', ')}.',
    );
  }

  final failureReasonCategory = values['failure-reason-category']?.trim() ?? '';
  final syntheticFixtureRecommendation =
      values['synthetic-fixture-recommendation']?.trim() ?? '';

  return RealReceiptValidationSummaryResult.success({
    'schemaVersion': 1,
    'report': 'work_supply_parser_real_receipt_validation_log',
    'createdAtIso': DateTime.now().toUtc().toIso8601String(),
    'merchantCategory': merchantCategory,
    'expectedItemFamily': expectedItemFamily,
    'parserResultCategory': resultCategory,
    'failureReasonCategory': failureReasonCategory,
    'syntheticFixtureRecommendation': syntheticFixtureRecommendation,
    'rawReceiptStored': false,
    'rawReceiptTextStored': false,
    'receiptImageStored': false,
    'privateReceiptContentCommitted': false,
    'liveServicesAllowed': false,
    'firebaseWritesAllowed': false,
    'ocrCameraExpensesTouched': false,
    'notes':
        'This artifact is a privacy-safe summary only. Real receipt text must '
        'stay local/private; regressions must be rewritten as synthetic fixtures.',
  });
}

String? _blockedPrivateValueKind(String value) {
  for (final entry in _forbiddenPrivateValuePatterns.entries) {
    if (entry.value.hasMatch(value)) return entry.key;
  }
  return null;
}

String? _required(Map<String, String> values, String key) {
  final value = values[key]?.trim();
  if (value == null || value.isEmpty) return null;
  return value;
}

bool _isBuildPath(String path) {
  final normalized = path.replaceAll('\\', '/').toLowerCase();
  return normalized == 'build' || normalized.startsWith('build/');
}

_ParsedArgs _parseArgs(List<String> args) {
  final values = <String, String>{};
  for (var index = 0; index < args.length; index++) {
    final arg = args[index];
    if (!arg.startsWith('--')) {
      return _ParsedArgs.error('Unexpected positional argument: $arg');
    }
    final withoutPrefix = arg.substring(2);
    final equalsIndex = withoutPrefix.indexOf('=');
    if (equalsIndex >= 0) {
      final key = withoutPrefix.substring(0, equalsIndex);
      final value = withoutPrefix.substring(equalsIndex + 1);
      values[key] = value;
      continue;
    }
    if (index + 1 >= args.length || args[index + 1].startsWith('--')) {
      return _ParsedArgs.error('Missing value for $arg');
    }
    values[withoutPrefix] = args[++index];
  }
  return _ParsedArgs(values);
}

class RealReceiptValidationLogResult {
  const RealReceiptValidationLogResult._(this.exitCode, this.message);

  const RealReceiptValidationLogResult.success(String message)
    : this._(0, message);

  const RealReceiptValidationLogResult.failure(String message)
    : this._(2, message);

  final int exitCode;
  final String message;
}

class RealReceiptValidationSummaryResult {
  const RealReceiptValidationSummaryResult._({this.summary, this.error});

  const RealReceiptValidationSummaryResult.success(Map<String, Object?> summary)
    : this._(summary: summary);

  const RealReceiptValidationSummaryResult.failure(String error)
    : this._(error: error);

  final Map<String, Object?>? summary;
  final String? error;
}

class _ParsedArgs {
  const _ParsedArgs(this.values) : error = null;

  const _ParsedArgs.error(this.error) : values = const {};

  final Map<String, String> values;
  final String? error;
}
