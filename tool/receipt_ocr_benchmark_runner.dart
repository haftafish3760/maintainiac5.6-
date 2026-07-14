import 'dart:convert';
import 'dart:io';

import 'package:maintaniac/shared/widgets/receipt_capture/receipt_ocr_benchmark_metrics.dart';

const _requiredReceiptScenarios = <String>{
  'thermal',
  'faded',
  'glare',
  'shadow',
  'rotated',
  'perspective',
  'tiny_print',
  'low_light',
  'high_light',
  'fuel',
  'inventory',
  'mixed',
  'unsupported',
  'screenshot',
  'long_receipt_reconstructed',
};
const _minimumRealCasesPerScenario = 3;

void main(List<String> args) {
  final releaseGate = args.contains('--release-gate');
  final requireReal = releaseGate || args.contains('--require-real');
  final requireCompleteCoverage =
      releaseGate || args.contains('--require-complete-coverage');
  final inputPath = args
      .where((arg) => arg.startsWith('--input='))
      .map((arg) => arg.substring('--input='.length))
      .firstOrNull;
  final failUnder =
      args
          .where((arg) => arg.startsWith('--fail-under='))
          .map((arg) => double.tryParse(arg.substring('--fail-under='.length)))
          .firstOrNull ??
      .9;
  if (inputPath == null || inputPath.isEmpty) {
    stderr.writeln(
      'Usage: dart tool/receipt_ocr_benchmark_runner.dart --input=<labeled-results.json> [--fail-under=0.9]',
    );
    exitCode = 64;
    return;
  }
  final file = File(inputPath);
  if (!file.existsSync()) {
    stderr.writeln('Missing labeled OCR benchmark input: $inputPath');
    exitCode = 66;
    return;
  }
  final decoded = jsonDecode(file.readAsStringSync());
  final cases = _readCases(decoded);
  final hasRealEvidence = _hasRealEvidence(decoded);
  final report = scoreReceiptOcrBenchmark(cases);
  final below = report.below(failUnder);
  final missingCoverage = report.coverage.entries
      .where((entry) => entry.value == 0)
      .map((entry) => entry.key)
      .toList(growable: false);
  final scenarioCoverage = _scenarioCoverage(decoded);
  final realScenarioCoverage = _scenarioCoverage(decoded, realOnly: true);
  final missingScenarioCoverage = _requiredReceiptScenarios
      .where((scenario) => !scenarioCoverage.contains(scenario))
      .toList(growable: false);
  final missingRealScenarioCoverage = _requiredReceiptScenarios
      .where((scenario) => !realScenarioCoverage.contains(scenario))
      .toList(growable: false);
  final realScenarioCaseCounts = _scenarioCaseCounts(decoded, realOnly: true);
  final underSampledRealScenarios = _requiredReceiptScenarios
      .where(
        (scenario) =>
            (realScenarioCaseCounts[scenario] ?? 0) <
            _minimumRealCasesPerScenario,
      )
      .toList(growable: false);
  final scenarioBelowMinimum = _scenarioBelowMinimum(decoded, failUnder);
  stdout.writeln(
    const JsonEncoder.withIndent('  ').convert({
      'caseCount': report.caseCount,
      'minimumRequired': failUnder,
      'releaseGate': releaseGate,
      'requiresRealEvidence': requireReal,
      'requiresCompleteCoverage': requireCompleteCoverage,
      'hasRealEvidence': hasRealEvidence,
      'metrics': report.metrics,
      'metricCaseCounts': report.coverage,
      'missingCoverage': missingCoverage,
      'scenarioCoverage': scenarioCoverage.toList()..sort(),
      'missingScenarioCoverage': missingScenarioCoverage,
      'realScenarioCoverage': realScenarioCoverage.toList()..sort(),
      'missingRealScenarioCoverage': missingRealScenarioCoverage,
      'minimumRealCasesPerScenario': _minimumRealCasesPerScenario,
      'realScenarioCaseCounts': realScenarioCaseCounts,
      'underSampledRealScenarios': underSampledRealScenarios,
      'scenarioBelowMinimum': scenarioBelowMinimum,
      'belowMinimum': below,
    }),
  );
  if (report.caseCount == 0 ||
      below.isNotEmpty ||
      (requireReal && !hasRealEvidence) ||
      (requireCompleteCoverage &&
          (missingCoverage.isNotEmpty ||
              missingScenarioCoverage.isNotEmpty ||
              scenarioBelowMinimum.isNotEmpty)) ||
      (releaseGate &&
          (missingRealScenarioCoverage.isNotEmpty ||
              underSampledRealScenarios.isNotEmpty))) {
    exitCode = 1;
  }
}

bool _hasRealEvidence(Object? source) {
  if (source is! Map<String, Object?> || source['cases'] is! List) return false;
  return (source['cases']! as List).whereType<Map<String, Object?>>().any((
    entry,
  ) {
    final provenance = entry['provenance'];
    final kind = provenance is Map<String, Object?>
        ? provenance['sourceKind'] as String?
        : null;
    return kind == 'camera' ||
        kind == 'gallery_import' ||
        kind == 'file_import';
  });
}

Set<String> _scenarioCoverage(Object? source, {bool realOnly = false}) {
  if (source is! Map<String, Object?> || source['cases'] is! List) {
    return const {};
  }
  final covered = <String>{};
  for (final entry
      in (source['cases']! as List).whereType<Map<String, Object?>>()) {
    final provenance = entry['provenance'];
    if (provenance is! Map<String, Object?>) continue;
    final sourceKind = provenance['sourceKind'];
    if (realOnly &&
        sourceKind != 'camera' &&
        sourceKind != 'gallery_import' &&
        sourceKind != 'file_import') {
      continue;
    }
    final tags = provenance['scenarioTags'];
    if (tags is! List) continue;
    covered.addAll(
      tags
          .whereType<String>()
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty),
    );
  }
  return covered;
}

Map<String, int> _scenarioCaseCounts(Object? source, {bool realOnly = false}) {
  if (source is! Map<String, Object?> || source['cases'] is! List) {
    return const {};
  }
  final counts = <String, int>{};
  for (final entry
      in (source['cases']! as List).whereType<Map<String, Object?>>()) {
    final provenance = entry['provenance'];
    if (provenance is! Map<String, Object?>) continue;
    final sourceKind = provenance['sourceKind'];
    if (realOnly &&
        sourceKind != 'camera' &&
        sourceKind != 'gallery_import' &&
        sourceKind != 'file_import') {
      continue;
    }
    final tags = provenance['scenarioTags'];
    if (tags is! List) continue;
    for (final tag
        in tags.whereType<String>().map((tag) => tag.trim()).toSet()) {
      if (tag.isEmpty) continue;
      counts[tag] = (counts[tag] ?? 0) + 1;
    }
  }
  return Map.unmodifiable(counts);
}

Map<String, List<String>> _scenarioBelowMinimum(
  Object? source,
  double minimum,
) {
  if (source is! Map<String, Object?> || source['cases'] is! List) {
    return const {};
  }
  final casesByScenario = <String, List<ReceiptOcrBenchmarkCase>>{};
  for (final entry
      in (source['cases']! as List).whereType<Map<String, Object?>>()) {
    final provenance = entry['provenance'];
    if (provenance is! Map<String, Object?>) continue;
    final tags = provenance['scenarioTags'];
    if (tags is! List) continue;
    final benchmarkCase = _caseFromJson(entry);
    for (final tag in tags.whereType<String>().map((tag) => tag.trim())) {
      if (tag.isEmpty) continue;
      (casesByScenario[tag] ??= []).add(benchmarkCase);
    }
  }
  final below = <String, List<String>>{};
  for (final entry in casesByScenario.entries) {
    final failedMetrics = scoreReceiptOcrBenchmark(entry.value).below(minimum);
    if (failedMetrics.isNotEmpty) below[entry.key] = failedMetrics;
  }
  return Map.unmodifiable(below);
}

List<ReceiptOcrBenchmarkCase> _readCases(Object? source) {
  if (source is! Map<String, Object?> || source['cases'] is! List) {
    throw const FormatException('Benchmark input must contain a cases array.');
  }
  final cases = <ReceiptOcrBenchmarkCase>[];
  for (final entry in source['cases']! as List) {
    if (entry is! Map<String, Object?>) {
      throw const FormatException('Every benchmark case must be an object.');
    }
    cases.add(_caseFromJson(entry));
  }
  return cases;
}

ReceiptOcrBenchmarkCase _caseFromJson(Map<String, Object?> source) {
  Map<String, Object?> side(String key) {
    final value = source[key];
    if (value is Map<String, Object?>) return value;
    throw FormatException(
      'Benchmark case ${source['id'] ?? '<unknown>'} is missing $key evidence.',
    );
  }

  String? value(Map<String, Object?> map, String key) => map[key] as String?;
  List<String> lines(Map<String, Object?> map) =>
      (map['lines'] as List? ?? const []).whereType<String>().toList(
        growable: false,
      );
  final expected = side('expected');
  final actual = side('actual');
  _validateProvenance(source['provenance'], source['id']);
  final id = source['id'] as String?;
  if (id == null || id.trim().isEmpty) {
    throw const FormatException('Every benchmark case needs an id.');
  }
  return ReceiptOcrBenchmarkCase(
    id: id,
    expectedText: value(expected, 'text') ?? '',
    actualText: value(actual, 'text') ?? '',
    expectedMerchant: value(expected, 'merchant'),
    actualMerchant: value(actual, 'merchant'),
    expectedDate: value(expected, 'date'),
    actualDate: value(actual, 'date'),
    expectedSubtotal: value(expected, 'subtotal'),
    actualSubtotal: value(actual, 'subtotal'),
    expectedTax: value(expected, 'tax'),
    actualTax: value(actual, 'tax'),
    expectedTotal: value(expected, 'total'),
    actualTotal: value(actual, 'total'),
    expectedLines: lines(expected),
    actualLines: lines(actual),
    expectedRoute: value(expected, 'route'),
    actualRoute: value(actual, 'route'),
  );
}

void _validateProvenance(Object? value, Object? id) {
  if (value is! Map<String, Object?>) {
    throw FormatException(
      'Benchmark case ${id ?? '<unknown>'} is missing privacy-safe provenance.',
    );
  }
  for (final key in const [
    'sourceId',
    'sourceKind',
    'engine',
    'processingVersion',
  ]) {
    final field = value[key];
    if (field is! String || field.trim().isEmpty) {
      throw FormatException(
        'Benchmark case ${id ?? '<unknown>'} needs provenance.$key.',
      );
    }
  }
  if (value.keys.any(
    (key) =>
        key.toLowerCase().contains('path') ||
        key.toLowerCase().contains('text'),
  )) {
    throw FormatException(
      'Benchmark case ${id ?? '<unknown>'} provenance must not contain raw text or file paths.',
    );
  }
}

extension on Iterable<String?> {
  String? get firstOrNull {
    for (final value in this) {
      if (value != null) return value;
    }
    return null;
  }
}
