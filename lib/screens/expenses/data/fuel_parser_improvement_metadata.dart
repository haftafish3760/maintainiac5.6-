import 'expense_receipt_parser.dart';

class FuelParserImprovementMetadata {
  const FuelParserImprovementMetadata({
    required this.schema,
    required this.receiptFamily,
    required this.localeBucket,
    required this.fuelLineCount,
    required this.nonFuelLineCount,
    required this.fuelTypeCounts,
    required this.unitCounts,
    required this.parserTaskCounts,
    required this.excludedPrivateLineCount,
    required this.redactionStatus,
  });

  factory FuelParserImprovementMetadata.fromParseResult(
    ExpenseReceiptParseResult parsed,
  ) {
    final fuelTypeCounts = <String, int>{};
    final unitCounts = <String, int>{};
    var fuelLineCount = 0;
    var nonFuelLineCount = 0;
    for (final line in parsed.lines) {
      if (_normalizeToken(line.category) == 'fuel') {
        fuelLineCount += 1;
        _increment(fuelTypeCounts, _safeToken(line.fuelType ?? 'unknown'));
        _increment(unitCounts, _safeToken(line.unit));
      } else {
        nonFuelLineCount += 1;
      }
    }

    final taskCounts = <String, int>{};
    for (final entry in parsed.diagnostics.parserTaskCounts.entries) {
      final key = _safeToken(entry.key);
      final value = entry.value;
      if (value > 0) taskCounts[key] = value;
    }

    final excludedPrivateLineCount =
        parsed.diagnostics.parserTaskCount('payment_line_excluded') +
        parsed.diagnostics.parserTaskCount('transaction_line_excluded') +
        parsed.diagnostics.parserTaskCount('auth_detail_line_excluded') +
        parsed.diagnostics.parserTaskCount('reference_detail_line_excluded') +
        parsed.diagnostics.parserTaskCount('identity_detail_line_excluded') +
        parsed.diagnostics.parserTaskCount('private_receipt_line_protected');

    return FuelParserImprovementMetadata(
      schema: 'fuel_parser_improvement_metadata_v1',
      receiptFamily: nonFuelLineCount > 0 ? 'mixed_fuel' : 'fuel_only',
      localeBucket: _localeBucketFor(parsed.sourceText),
      fuelLineCount: fuelLineCount,
      nonFuelLineCount: nonFuelLineCount,
      fuelTypeCounts: Map.unmodifiable(fuelTypeCounts),
      unitCounts: Map.unmodifiable(unitCounts),
      parserTaskCounts: Map.unmodifiable(taskCounts),
      excludedPrivateLineCount: excludedPrivateLineCount,
      redactionStatus: 'redacted_counts_only',
    );
  }

  final String schema;
  final String receiptFamily;
  final String localeBucket;
  final int fuelLineCount;
  final int nonFuelLineCount;
  final Map<String, int> fuelTypeCounts;
  final Map<String, int> unitCounts;
  final Map<String, int> parserTaskCounts;
  final int excludedPrivateLineCount;
  final String redactionStatus;

  Map<String, Object?> toMap() {
    return {
      'schema': schema,
      'receiptFamily': receiptFamily,
      'localeBucket': localeBucket,
      'fuelLineCount': fuelLineCount,
      'nonFuelLineCount': nonFuelLineCount,
      'fuelTypeCounts': fuelTypeCounts,
      'unitCounts': unitCounts,
      'parserTaskCounts': parserTaskCounts,
      'excludedPrivateLineCount': excludedPrivateLineCount,
      'redactionStatus': redactionStatus,
    };
  }
}

String _localeBucketFor(String text) {
  final lower = text.toLowerCase();
  if (RegExp(
    r'\b(gasolina|galones|gal[oó]n|precio|efectivo|cambio|tarjeta|'
    r'combustible|bomba|surtidor|od[oó]metro|diésel|energ[ií]a|'
    r'carga|el[eé]ctrica|el[eé]ctrico|tarifa|sesi[oó]n|inactividad)\b',
  ).hasMatch(lower)) {
    return RegExp(r'\b(fuel|gallons?|price|cash|card|pump)\b').hasMatch(lower)
        ? 'bilingual_en_es'
        : 'spanish_us';
  }
  return 'english_us';
}

String _safeToken(String value) {
  final token = _normalizeToken(value);
  return token.isEmpty ? 'unknown' : token;
}

String _normalizeToken(String value) {
  final normalized = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  return normalized.length > 48 ? normalized.substring(0, 48) : normalized;
}

void _increment(Map<String, int> counts, String key) {
  counts[key] = (counts[key] ?? 0) + 1;
}
