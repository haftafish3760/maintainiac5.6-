import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserFileSizeSuite extends QaSuite {
  const WorkSupplyParserFileSizeSuite() : super('inventory.file_size_contract');

  static const _softLimit = 500;
  static const _hardLimit = 1000;

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
      },
    );
  }
}
