import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'pipeline failure task requires categorized bug ledger regression',
    () async {
      final runName =
          'receipt_pipeline_failure_to_regression_test_${DateTime.now().microsecondsSinceEpoch}';
      final root = Directory('/tmp/maintainiac_receipt_ocr_pipeline/$runName');
      final phaseDir = Directory('${root.path}/phases')
        ..createSync(recursive: true);
      final failureReport = File('${root.path}/failure_report.txt')
        ..writeAsStringSync(
          'FAILED_PHASE camera_pipeline_contracts\n'
          'LOG ${phaseDir.path}/camera_pipeline_contracts.log\n',
        );
      final phaseLog = File('${phaseDir.path}/camera_pipeline_contracts.log')
        ..writeAsStringSync('camera quality contract failed\n');

      addTearDown(() {
        if (root.existsSync()) root.deleteSync(recursive: true);
      });

      final result = await Process.run('dart', [
        'run',
        'tool/receipt_pipeline_failure_to_regression.dart',
        runName,
      ]);
      final task = File(
        '${root.path}/regression_tasks/camera_pipeline_contracts_regression_task.md',
      );

      expect(failureReport.existsSync(), isTrue);
      expect(phaseLog.existsSync(), isTrue);
      expect(result.exitCode, 0, reason: result.stderr.toString());
      expect(task.existsSync(), isTrue);

      final text = task.readAsStringSync();
      expect(
        text,
        contains('Failure family: `camera_capture_ocr_stitch_contracts`'),
      );
      expect(
        text,
        contains('Suggested ledger category: `camera_capture_quality`'),
      );
      expect(
        text,
        contains('Bug ledger: `docs/receipt_bug_regression_ledger.md`'),
      );
      expect(text, contains('Add a `BUG-RECEIPT-####` ledger row'));
      expect(text, contains('Do not close the task as an uncategorized bug.'));
    },
  );
}
