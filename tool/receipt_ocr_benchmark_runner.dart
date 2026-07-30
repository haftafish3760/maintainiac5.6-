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
const _realSourceKinds = {'camera', 'gallery_import', 'file_import'};

void main(List<String> args) {
  final releaseGate = args.contains('--release-gate');
  final requireReal = releaseGate || args.contains('--require-real');
  final requireCompleteCoverage =
      releaseGate || args.contains('--require-complete-coverage');
  final inputPath = _option(args, '--input=');
  final failUnder = double.tryParse(_option(args, '--fail-under=') ?? '') ?? .9;
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

  try {
    final source = jsonDecode(file.readAsStringSync());
    final entries = _caseEntries(source);
    _validateBenchmarkIdentities(entries);
    final cases = entries.map(_caseFromJson).toList(growable: false);
    final report = scoreReceiptOcrBenchmark(cases);
    final scenarioCounts = _scenarioCounts(entries);
    final realScenarioCounts = _scenarioCounts(entries, realOnly: true);
    final scenarioCoverage = scenarioCounts.keys.toSet();
    final realScenarioCoverage = realScenarioCounts.keys.toSet();
    final missingCoverage = report.coverage.entries
        .where((entry) => entry.value == 0)
        .map((entry) => entry.key)
        .toList(growable: false);
    final missingScenarios = _requiredReceiptScenarios
        .difference(scenarioCoverage)
        .toList(growable: false);
    final missingRealScenarios = _requiredReceiptScenarios
        .difference(realScenarioCoverage)
        .toList(growable: false);
    final underSampledRealScenarios = _requiredReceiptScenarios
        .where(
          (scenario) =>
              (realScenarioCounts[scenario] ?? 0) <
              _minimumRealCasesPerScenario,
        )
        .toList(growable: false);
    final scenarioBelowMinimum = <String, List<String>>{
      for (final scenario in scenarioCoverage)
        if (scoreReceiptOcrBenchmark(
          entries
              .where((entry) => _scenarioTags(entry).contains(scenario))
              .map(_caseFromJson),
        ).below(failUnder).isNotEmpty)
          scenario: scoreReceiptOcrBenchmark(
            entries
                .where((entry) => _scenarioTags(entry).contains(scenario))
                .map(_caseFromJson),
          ).below(failUnder),
    };
    final realScenarioBelowMinimum = <String, List<String>>{
      for (final scenario in realScenarioCoverage)
        if (scoreReceiptOcrBenchmark(
          entries
              .where(
                (entry) =>
                    _realSourceKinds.contains(
                      _provenance(entry)['sourceKind'],
                    ) &&
                    _scenarioTags(entry).contains(scenario),
              )
              .map(_caseFromJson),
        ).below(failUnder).isNotEmpty)
          scenario: scoreReceiptOcrBenchmark(
            entries
                .where(
                  (entry) =>
                      _realSourceKinds.contains(
                        _provenance(entry)['sourceKind'],
                      ) &&
                      _scenarioTags(entry).contains(scenario),
                )
                .map(_caseFromJson),
          ).below(failUnder),
    };
    final belowMinimum = report.below(failUnder);
    final hasRealEvidence = entries.any(
      (entry) => _realSourceKinds.contains(_provenance(entry)['sourceKind']),
    );
    final realRunIdentities = _realRunIdentities(entries);
    final mixedRealRunIdentities = realRunIdentities.length > 1;

    stdout.writeln(
      const JsonEncoder.withIndent('  ').convert({
        'caseCount': report.caseCount,
        'minimumRequired': failUnder,
        'releaseGate': releaseGate,
        'requiresRealEvidence': requireReal,
        'requiresCompleteCoverage': requireCompleteCoverage,
        'hasRealEvidence': hasRealEvidence,
        'realRunIdentities': realRunIdentities.toList()..sort(),
        'mixedRealRunIdentities': mixedRealRunIdentities,
        'metrics': report.metrics,
        'metricCaseCounts': report.coverage,
        'missingCoverage': missingCoverage,
        'scenarioCoverage': scenarioCoverage.toList()..sort(),
        'missingScenarioCoverage': missingScenarios,
        'realScenarioCoverage': realScenarioCoverage.toList()..sort(),
        'missingRealScenarioCoverage': missingRealScenarios,
        'minimumRealCasesPerScenario': _minimumRealCasesPerScenario,
        'realScenarioCaseCounts': realScenarioCounts,
        'underSampledRealScenarios': underSampledRealScenarios,
        'scenarioBelowMinimum': scenarioBelowMinimum,
        'realScenarioBelowMinimum': realScenarioBelowMinimum,
        'belowMinimum': belowMinimum,
      }),
    );
    if (report.caseCount == 0 ||
        belowMinimum.isNotEmpty ||
        (requireReal && !hasRealEvidence) ||
        (requireCompleteCoverage &&
            (missingCoverage.isNotEmpty ||
                missingScenarios.isNotEmpty ||
                scenarioBelowMinimum.isNotEmpty)) ||
        (releaseGate &&
            (missingRealScenarios.isNotEmpty ||
                underSampledRealScenarios.isNotEmpty ||
                realScenarioBelowMinimum.isNotEmpty ||
                mixedRealRunIdentities))) {
      exitCode = 1;
    }
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    exitCode = 65;
  }
}

String? _option(List<String> args, String prefix) {
  for (final arg in args) {
    if (arg.startsWith(prefix)) return arg.substring(prefix.length);
  }
  return null;
}

List<Map<String, Object?>> _caseEntries(Object? source) {
  if (source is! Map<String, Object?> || source['cases'] is! List) {
    throw const FormatException('Benchmark input must contain a cases array.');
  }
  return (source['cases']! as List)
      .map((entry) {
        if (entry is! Map<String, Object?>) {
          throw const FormatException(
            'Every benchmark case must be an object.',
          );
        }
        return entry;
      })
      .toList(growable: false);
}

void _validateBenchmarkIdentities(List<Map<String, Object?>> entries) {
  final caseIds = <String>{};
  final realSourceIds = <String>{};
  for (final entry in entries) {
    final id = entry['id'];
    if (id is! String || id.trim().isEmpty) {
      throw const FormatException('Every benchmark case needs an id.');
    }
    if (!caseIds.add(id.trim())) {
      throw FormatException('Benchmark case id ${id.trim()} is repeated.');
    }
    final provenance = _provenance(entry);
    final tags = _scenarioTags(entry);
    if (tags.isEmpty) {
      throw FormatException(
        'Benchmark case ${id.trim()} needs at least one scenario tag.',
      );
    }
    if (!_realSourceKinds.contains(provenance['sourceKind'])) continue;
    final sourceId = (provenance['sourceId']! as String).trim();
    if (!realSourceIds.add(sourceId)) {
      throw FormatException(
        'Real receipt source $sourceId is repeated. Each physical receipt or long-receipt photo set can be counted once.',
      );
    }
  }
}

Set<String> _realRunIdentities(List<Map<String, Object?>> entries) {
  return {
    for (final entry in entries)
      if (_realSourceKinds.contains(_provenance(entry)['sourceKind']))
        '${(_provenance(entry)['engine']! as String).trim()}@${(_provenance(entry)['processingVersion']! as String).trim()}',
  };
}

Map<String, Object?> _provenance(Map<String, Object?> source) {
  final value = source['provenance'];
  if (value is! Map<String, Object?>) {
    throw FormatException(
      'Benchmark case ${source['id'] ?? '<unknown>'} is missing privacy-safe provenance.',
    );
  }
  for (final key in const [
    'sourceId',
    'sourceKind',
    'engine',
    'processingVersion',
  ]) {
    if (value[key] is! String || (value[key]! as String).trim().isEmpty) {
      throw FormatException(
        'Benchmark case ${source['id'] ?? '<unknown>'} needs provenance.$key.',
      );
    }
  }
  if (value.keys.any(
    (key) =>
        key.toLowerCase().contains('path') ||
        key.toLowerCase().contains('text'),
  )) {
    throw FormatException(
      'Benchmark case ${source['id'] ?? '<unknown>'} provenance must not contain raw text or file paths.',
    );
  }
  return value;
}

Set<String> _scenarioTags(Map<String, Object?> source) {
  final tags = _provenance(source)['scenarioTags'];
  return tags is List
      ? tags
            .whereType<String>()
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toSet()
      : const {};
}

Map<String, int> _scenarioCounts(
  List<Map<String, Object?>> entries, {
  bool realOnly = false,
}) {
  final counts = <String, int>{};
  for (final entry in entries) {
    final provenance = _provenance(entry);
    if (realOnly && !_realSourceKinds.contains(provenance['sourceKind'])) {
      continue;
    }
    for (final tag in _scenarioTags(entry)) {
      counts[tag] = (counts[tag] ?? 0) + 1;
    }
  }
  return Map.unmodifiable(counts);
}

ReceiptOcrBenchmarkCase _caseFromJson(Map<String, Object?> source) {
  Map<String, Object?> side(String key) {
    final value = source[key];
    if (value is Map<String, Object?>) return value;
    throw FormatException(
      'Benchmark case ${source['id'] ?? '<unknown>'} is missing $key evidence.',
    );
  }

  final id = source['id'];
  if (id is! String || id.trim().isEmpty) {
    throw const FormatException('Every benchmark case needs an id.');
  }
  _provenance(source);
  final expected = side('expected');
  final actual = side('actual');
  String? field(Map<String, Object?> value, String key) =>
      value[key] is String ? value[key] as String : null;
  List<String> lines(Map<String, Object?> value) =>
      (value['lines'] as List? ?? const []).whereType<String>().toList(
        growable: false,
      );
  return ReceiptOcrBenchmarkCase(
    id: id,
    expectedText: field(expected, 'text') ?? '',
    actualText: field(actual, 'text') ?? '',
    expectedMerchant: field(expected, 'merchant'),
    actualMerchant: field(actual, 'merchant'),
    expectedDate: field(expected, 'date'),
    actualDate: field(actual, 'date'),
    expectedSubtotal: field(expected, 'subtotal'),
    actualSubtotal: field(actual, 'subtotal'),
    expectedTax: field(expected, 'tax'),
    actualTax: field(actual, 'tax'),
    expectedTotal: field(expected, 'total'),
    actualTotal: field(actual, 'total'),
    expectedLines: lines(expected),
    actualLines: lines(actual),
    expectedRoute: field(expected, 'route'),
    actualRoute: field(actual, 'route'),
  );
}
