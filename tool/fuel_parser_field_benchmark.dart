import 'dart:convert';
import 'dart:io';

import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';

const _benchmarkPath = 'test/fixtures/receipt_qa/fuel_field_benchmark.json';

void main(List<String> args) {
  final requireCommercial = args.contains('--require-commercial');
  final report = runFuelParserFieldBenchmark();
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(report));
  if (requireCommercial && report['commercialValidationReady'] != true) {
    exitCode = 1;
  }
}

/// Scores only provenance-tagged real-redacted or anonymized field cases.
/// This is kept separate from synthetic regression coverage so a passing
/// regression suite cannot be mistaken for validated field accuracy.
Map<String, Object?> runFuelParserFieldBenchmark() {
  final root =
      jsonDecode(File(_benchmarkPath).readAsStringSync())
          as Map<String, Object?>;
  if (root['schema'] != 'fuel_parser_field_benchmark_v1') {
    throw FormatException('Unexpected fuel benchmark schema.');
  }
  final cases = (root['cases']! as List<Object?>).cast<Map<String, Object?>>();
  final results = <Map<String, Object?>>[];
  var matchedFields = 0;
  var scoredFields = 0;
  var independentCaseCount = 0;
  final merchantFamilies = <String>{};

  for (final benchmarkCase in cases) {
    if (benchmarkCase['fixtureKind'] != 'real_redacted' &&
        benchmarkCase['fixtureKind'] != 'real_anonymized') {
      continue;
    }
    final expected = benchmarkCase['expected']! as Map<String, Object?>;
    final parsed = parseExpenseReceiptText(benchmarkCase['text']! as String);
    final fuelLines = parsed.lines
        .where((line) => line.category == 'Fuel')
        .toList(growable: false);
    final fuel = fuelLines.length == 1 ? fuelLines.single : null;
    final fields = <String, bool>{
      'merchant': _sameToken(parsed.merchantName, expected['merchantName']),
      'date': _sameDate(parsed.receiptDate, expected['dateIso']),
      'total': _sameMoney(parsed.enteredTotal, expected['total']),
      'fuel_line_count': fuelLines.length == expected['fuelLineCount'],
      'fuel_type': _sameToken(fuel?.fuelType, expected['fuelType']),
      'quantity': _sameNumber(fuel?.quantity, expected['quantity']),
      'unit': _sameToken(fuel?.unit, expected['unit']),
      'unit_price': _sameNumber(fuel?.unitPrice, expected['unitPrice']),
      'subtotal': _sameMoney(fuel?.subtotal, expected['subtotal']),
    };
    matchedFields += fields.values.where((matched) => matched).length;
    scoredFields += fields.length;
    final usedForRegression = benchmarkCase['usedForRegression'] == true;
    if (!usedForRegression) {
      independentCaseCount += 1;
      merchantFamilies.add(benchmarkCase['merchantFamily']! as String);
    }
    results.add({
      'id': benchmarkCase['id'],
      'fixtureKind': benchmarkCase['fixtureKind'],
      'merchantFamily': benchmarkCase['merchantFamily'],
      'usedForRegression': usedForRegression,
      'fieldMatches': fields,
      'matchedFieldCount': fields.values.where((matched) => matched).length,
      'fieldCount': fields.length,
    });
  }

  final minimumCases = root['minimumCommercialSampleCount']! as int;
  final minimumFamilies = root['minimumMerchantFamilies']! as int;
  final accuracy = scoredFields == 0 ? 0.0 : matchedFields / scoredFields;
  final blockers = <String>[
    if (independentCaseCount < minimumCases)
      'Need at least $minimumCases independent redacted real-world receipts; found $independentCaseCount.',
    if (merchantFamilies.length < minimumFamilies)
      'Need at least $minimumFamilies merchant families; found ${merchantFamilies.length}.',
    if (accuracy < .90)
      'Field accuracy ${(accuracy * 100).toStringAsFixed(1)}% is below the 90% floor.',
  ];
  return {
    'schema': 'fuel_parser_field_benchmark_report_v1',
    'sourcePolicy': root['sourcePolicy'],
    'realRedactedCaseCount': results.length,
    'independentCaseCount': independentCaseCount,
    'merchantFamilyCount': merchantFamilies.length,
    'matchedFieldCount': matchedFields,
    'scoredFieldCount': scoredFields,
    'fieldAccuracy': accuracy,
    'commercialValidationReady': blockers.isEmpty,
    'blockers': blockers,
    'cases': results,
  };
}

bool _sameToken(Object? actual, Object? expected) =>
    actual?.toString().trim().toLowerCase() ==
    expected?.toString().trim().toLowerCase();

bool _sameDate(DateTime? actual, Object? expected) =>
    actual != null &&
    '${actual.year.toString().padLeft(4, '0')}-${actual.month.toString().padLeft(2, '0')}-${actual.day.toString().padLeft(2, '0')}' ==
        expected;

bool _sameMoney(num? actual, Object? expected) =>
    actual != null && expected is num && (actual - expected).abs() <= .01;

bool _sameNumber(num? actual, Object? expected) =>
    actual != null && expected is num && (actual - expected).abs() <= .001;
