import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserMaintainabilitySuite extends QaSuite {
  const WorkSupplyParserMaintainabilitySuite()
    : super('inventory.harness_maintainability_contract');

  static const preferredLineLimit = 500;
  static const hardLineLimit = 1000;
  static const _planPath = 'docs/inventory_parser_qa_harness_plan.md';
  static const _scanRoots = [
    'test/support/work_supply_parser_qa',
    'test/support/qa_harness',
    'tool',
  ];

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final files = _dartFiles(failures);
    final preferredOverages = <Map<String, Object?>>[];
    final hardOverages = <Map<String, Object?>>[];

    for (final file in files) {
      final lineCount = file.readAsLinesSync().length;
      final record = {
        'path': _relative(file.path),
        'lines': lineCount,
        'preferredLimit': preferredLineLimit,
        'hardLimit': hardLineLimit,
      };
      if (lineCount > preferredLineLimit) preferredOverages.add(record);
      if (lineCount <= hardLineLimit) continue;
      hardOverages.add(record);
      failures.add(
        QaFailure(
          suite: name,
          id: 'harness_file_over_hard_limit:${_relative(file.path)}',
          message: 'Harness Dart file exceeds the 1000-line hard ceiling.',
          severity: QaSeverity.error,
          expected: '<= $hardLineLimit lines',
          actual: '$lineCount lines',
          suggestedFix:
              'Split the file by suite, model, or helper responsibility before adding more harness work.',
          metadata: const {'triageCategory': QaFailureTriage.governance},
        ),
      );
    }

    final plan = File(_planPath);
    if (!plan.existsSync()) {
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_maintainability_plan',
          message: 'Harness maintainability plan documentation is missing.',
          expected: _planPath,
          actual: 'not found',
          suggestedFix:
              'Document the 500-line preferred and 1000-line hard harness file limits.',
          metadata: const {'triageCategory': QaFailureTriage.schema},
        ),
      );
    } else {
      final source = plan.readAsStringSync();
      for (final token in [
        '500-line preferred',
        '1000-line hard ceiling',
        'inventory.harness_maintainability_contract',
      ]) {
        if (source.contains(token)) continue;
        failures.add(
          QaFailure(
            suite: name,
            id: 'missing_maintainability_doc_token:$token',
            message: 'Harness maintainability rule is not documented.',
            expected: token,
            actual: 'not found',
            suggestedFix:
                'Keep file-size governance visible so future passes do not create monster harness files.',
            metadata: const {'triageCategory': QaFailureTriage.governance},
          ),
        );
      }
    }

    preferredOverages.sort(
      (left, right) =>
          (right['lines']! as int).compareTo(left['lines']! as int),
    );

    return timer.finish(
      suite: name,
      checked: files.length + 4,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'preferredLineLimit': preferredLineLimit,
        'hardLineLimit': hardLineLimit,
        'filesScanned': files.map((file) => _relative(file.path)).toList(),
        'preferredOverages': preferredOverages,
        'hardOverages': hardOverages,
      },
    );
  }

  List<File> _dartFiles(List<QaFailure> failures) {
    final files = <File>[];
    for (final root in _scanRoots) {
      final directory = Directory(root);
      if (!directory.existsSync()) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'missing_maintainability_scan_root:$root',
            message: 'Harness maintainability scan root is missing.',
            expected: root,
            actual: 'not found',
            suggestedFix: 'Update scan roots if harness files move.',
            metadata: const {'triageCategory': QaFailureTriage.schema},
          ),
        );
        continue;
      }
      files.addAll(
        directory
            .listSync(recursive: false)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart')),
      );
    }
    files.sort((left, right) => left.path.compareTo(right.path));
    return files;
  }

  String _relative(String path) {
    final current = Directory.current.path;
    if (!path.startsWith(current)) return path;
    return path.substring(current.length + 1).replaceAll(r'\', '/');
  }
}
