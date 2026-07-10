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
  final cases = <_FuelSyntheticReceipt>[];
  for (var seedOffset = 0; seedOffset < config.seedCount; seedOffset += 1) {
    cases.addAll(
      _generateSyntheticFuelReceipts(
        count: config.count,
        seed: config.seed + seedOffset,
      ),
    );
  }
  final report = _scoreFuelReceipts(cases);
  final blocker = report.accuracy < config.failUnder;

  if (config.summaryJson || config.json) {
    stdout.writeln(
      const JsonEncoder.withIndent('  ').convert(
        config.summaryJson
            ? report.toSummaryJson(failUnder: config.failUnder)
            : report.toJson(failUnder: config.failUnder),
      ),
    );
  } else {
    stdout.writeln(
      'Fuel synthetic parser runner: '
      '${report.passedCaseCount}/${report.caseCount} cases passed '
      '(${(report.accuracy * 100).toStringAsFixed(1)}%).',
    );
    if (report.failures.isNotEmpty) {
      stdout.writeln('Failures:');
      for (final failure in report.failures.take(10)) {
        stdout.writeln('  - ${failure.caseName}: ${failure.issues.join('; ')}');
      }
    }
  }

  if (blocker) exitCode = 1;
}
