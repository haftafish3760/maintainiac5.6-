import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserFileSizeSuite extends QaSuite {
  const WorkSupplyParserFileSizeSuite() : super('inventory.file_size_contract');

  static const _softLimit = 500;
  static const _hardLimit = 1000;
  static const _protectedAppFileBaselines = {
    'lib/screens/work_supplies/data/catalog/plumbing/generated_plumbing_service_truck_catalog.dart':
        549,
    'lib/screens/work_supplies/data/work_supply_receipt_parser.dart': 4954,
    'lib/screens/work_supplies/data/work_supply_receipt_parser_trade_scores_core.dart':
        2333,
    'lib/screens/work_supplies/data/work_supply_receipt_parser_trade_scores_finishes.dart':
        1796,
    'lib/screens/work_supplies/data/work_supply_receipt_parser_trade_scores_exterior.dart':
        1130,
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final directories = [
      Directory('test/support/work_supply_parser_qa'),
      Directory('tool'),
    ];
    var checked = 0;
    final largestFiles = <Map<String, Object?>>[];
    final softOverages = <Map<String, Object?>>[];

    for (final directory in directories) {
      if (!directory.existsSync()) continue;
      for (final entity in directory.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        checked++;
        final lineCount = entity.readAsLinesSync().length;
        largestFiles.add({'path': entity.path, 'lines': lineCount});
        if (lineCount > _softLimit) {
          softOverages.add({'path': entity.path, 'lines': lineCount});
        }
        if (lineCount <= _hardLimit) continue;
        failures.add(
          QaFailure(
            suite: name,
            id: 'qa_file_over_hard_limit:${entity.path}',
            message: 'Parser QA file is over the hard file-size limit.',
            severity: QaSeverity.error,
            expected: '<= $_softLimit lines preferred, <= $_hardLimit hard',
            actual: '$lineCount lines',
            suggestedFix:
                'Split this QA/tool file by responsibility or document the functional reason that requires the larger file.',
            metadata: const {'triageCategory': QaFailureTriage.governance},
          ),
        );
      }
    }
    for (final entry in _protectedAppFileBaselines.entries) {
      final file = File(entry.key);
      if (!file.existsSync()) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'protected_app_file_missing:${entry.key}',
            message: 'Protected app file size baseline target is missing.',
            severity: QaSeverity.warning,
            expected: entry.key,
            actual: 'not found',
            suggestedFix:
                'Update the protected app file baseline when catalog files are intentionally moved or split.',
            metadata: const {'triageCategory': QaFailureTriage.governance},
          ),
        );
        continue;
      }
      checked++;
      final lineCount = file.readAsLinesSync().length;
      largestFiles.add({'path': file.path, 'lines': lineCount});
      if (lineCount <= entry.value) continue;
      failures.add(
        QaFailure(
          suite: name,
          id: 'protected_app_file_grew:${entry.key}',
          message:
              'Known over-target app catalog file grew instead of being split.',
          severity: QaSeverity.error,
          expected: '<= ${entry.value} lines until this file is split',
          actual: '$lineCount lines',
          suggestedFix:
              'Move new catalog rows into a focused sibling file or split this generated catalog instead of adding to it.',
          metadata: const {'triageCategory': QaFailureTriage.governance},
        ),
      );
    }
    largestFiles.sort(
      (left, right) =>
          (right['lines']! as int).compareTo(left['lines']! as int),
    );

    return timer.finish(
      suite: name,
      checked: checked,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'softLimitLines': _softLimit,
        'hardLimitLines': _hardLimit,
        'softOverageCount': softOverages.length,
        'softOverages': softOverages.take(12).toList(),
        'largestFiles': largestFiles.take(12).toList(),
        'protectedAppFileBaselines': _protectedAppFileBaselines,
      },
    );
  }
}
