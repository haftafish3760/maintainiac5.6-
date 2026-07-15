import 'dart:convert';
import 'dart:io';

import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';

part 'fuel_synthetic_parser_scoring.dart';
part 'fuel_synthetic_parser_generation.dart';
part 'fuel_synthetic_parser_validation.dart';
part 'fuel_synthetic_parser_liquid_layouts.dart';
part 'fuel_synthetic_parser_ev_layouts.dart';
part 'fuel_synthetic_parser_report_models.dart';
part 'fuel_synthetic_parser_receipt_models.dart';

const _defaultCount = 24;
const _defaultFailUnder = 1.0;
const _presetCounts = {'smoke': 24, 'milestone': 500};

void main(List<String> args) {
  final config = _FuelSyntheticRunnerConfig.fromArgs(args);
  final report = runFuelSyntheticParser(
    count: config.count,
    seed: config.seed,
    seedCount: config.seedCount,
    failUnder: config.failUnder,
  );
  final blocker = (report['blockers'] as List<Object?>).isNotEmpty;

  if (config.summaryJson || config.json) {
    stdout.writeln(
      const JsonEncoder.withIndent(
        '  ',
      ).convert(config.summaryJson ? _withoutFailureEvidence(report) : report),
    );
  } else {
    stdout.writeln(
      'Fuel synthetic parser runner: '
      '${report['passedCaseCount']}/${report['caseCount']} cases passed '
      '(${((report['accuracy'] as double) * 100).toStringAsFixed(1)}%).',
    );
  }

  if (blocker) exitCode = 1;
}

/// Runs the deterministic fuel parser matrix inside a Flutter-capable process.
///
/// The parser's record model depends on Flutter storage types, so focused
/// regression tests call this directly instead of shelling out to a standalone
/// Dart VM, which cannot load `dart:ui`.
Map<String, Object?> runFuelSyntheticParser({
  required int count,
  required int seed,
  int seedCount = 1,
  double failUnder = _defaultFailUnder,
}) {
  final cases = <_FuelSyntheticReceipt>[];
  for (var seedOffset = 0; seedOffset < seedCount; seedOffset += 1) {
    cases.addAll(
      _generateSyntheticFuelReceipts(count: count, seed: seed + seedOffset),
    );
  }
  final report = _scoreFuelReceipts(cases);
  return report.toJson(failUnder: failUnder);
}

Map<String, Object?> _withoutFailureEvidence(Map<String, Object?> report) {
  final summary = Map<String, Object?>.from(report);
  summary.remove('failures');
  return summary;
}
