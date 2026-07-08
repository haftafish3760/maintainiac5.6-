import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'focused stitch gate delegates to the reusable camera QA gate',
    () async {
      final stitchGate = await File(
        'tool/receipt_camera_stitch_gate.sh',
      ).readAsString();

      expect(stitchGate, contains('receipt_camera_qa_gate.sh stitch'));
      expect(stitchGate, isNot(contains('flutter test')));
      expect(stitchGate, isNot(contains('dart analyze')));
    },
  );

  test('camera changed gate mode selection is executable', () async {
    Future<String> selectedModeFor(String changedFiles) async {
      final result = await Process.run(
        'bash',
        ['tool/receipt_camera_changed_gate.sh', '--print-mode'],
        environment: {'RECEIPT_CAMERA_CHANGED_FILES_FOR_TEST': changedFiles},
      );
      expect(result.exitCode, 0, reason: result.stderr.toString());
      final output = result.stdout.toString();
      expect(output, isNot(contains('Receipt camera scope gate')));
      return output;
    }

    expect(
      await selectedModeFor('test/receipt_camera_coverage_decision_test.dart'),
      contains('selected quick'),
    );
    expect(
      await selectedModeFor('test/receipt_stitching_test.dart'),
      contains('selected stitch'),
    );
    expect(
      await selectedModeFor(
        'lib/shared/widgets/receipt_capture/receipt_capture_stitch_models.dart',
      ),
      contains('selected phase6'),
    );
    expect(
      await selectedModeFor(
        'lib/shared/widgets/receipt_capture/receipt_ocr_source_handoff.dart',
      ),
      contains('selected core_remaining'),
    );
    expect(
      await selectedModeFor(
        'lib/shared/widgets/receipt_capture/receipt_attachment_publish_helpers.dart',
      ),
      contains('selected core_remaining'),
    );
    expect(
      await selectedModeFor(
        'lib/shared/widgets/receipt_capture/receipt_capture_review_result.dart',
      ),
      contains('selected milestone'),
    );
    expect(
      await selectedModeFor('ios/Runner/ReceiptCameraViewController.swift'),
      contains('selected phase3'),
    );
    expect(
      await selectedModeFor(
        'ios/Runner/ReceiptCameraViewControllerLabels.swift',
      ),
      contains('selected phase3'),
    );
    expect(
      await selectedModeFor(
        'android/app/src/main/kotlin/com/maintainiac/ReceiptCameraUiChrome.kt',
      ),
      contains('selected phase3'),
    );
    expect(
      await selectedModeFor('tool/receipt_camera_qa_gate.sh'),
      contains('selected milestone'),
    );
    expect(
      await selectedModeFor('tool/receipt_quiet_batch_status.sh'),
      contains('selected milestone'),
    );
    expect(
      await selectedModeFor('tool/receipt_quiet_batch_final_summary.sh'),
      contains('selected milestone'),
    );
    expect(
      await selectedModeFor('tool/receipt_external_fixture_schema_gate.dart'),
      contains('selected milestone'),
    );
    expect(
      await selectedModeFor('tool/receipt_external_dataset_local_audit.dart'),
      contains('selected milestone'),
    );
    expect(
      await selectedModeFor('tool/receipt_external_dataset_gate.dart'),
      contains('selected milestone'),
    );
    expect(
      await selectedModeFor(
        'test/receipt_camera_dataset_qa_gate_contract_test.dart',
      ),
      contains('selected milestone'),
    );
    expect(
      await selectedModeFor(
        'test/receipt_external_dataset_local_audit_test.dart',
      ),
      contains('selected milestone'),
    );
    expect(
      await selectedModeFor('test/receipt_external_dataset_gate_test.dart'),
      contains('selected milestone'),
    );
    expect(
      await selectedModeFor(
        'test/receipt_external_fixture_schema_gate_test.dart',
      ),
      contains('selected milestone'),
    );
    expect(
      await selectedModeFor(
        'test/receipt_camera_qa_gate_execution_runtime_test.dart',
      ),
      contains('selected milestone'),
    );
  });

  test('camera failure wrapper executable creates stitch task', () async {
    final root = Directory(
      '/tmp/maintainiac_receipt_ocr_pipeline/receipt_camera_qa_failure',
    );
    if (root.existsSync()) root.deleteSync(recursive: true);
    addTearDown(() {
      if (root.existsSync()) root.deleteSync(recursive: true);
    });

    final log = File('/tmp/receipt_camera_failure_wrapper_contract.log')
      ..writeAsStringSync('long receipt overlap regression failed\n');
    addTearDown(() {
      if (log.existsSync()) log.deleteSync();
    });

    final result = await Process.run('bash', [
      'tool/receipt_camera_failure_to_regression.sh',
      'camera_stitch_gate',
      log.path,
    ]);
    expect(result.exitCode, 0, reason: result.stderr.toString());

    final task = File(
      '${root.path}/regression_tasks/camera_stitch_gate_regression_task.md',
    );
    expect(task.existsSync(), isTrue);
    final text = task.readAsStringSync();
    expect(
      text,
      contains('Failure family: `long_receipt_stitch_ocr_source_contracts`'),
    );
    expect(
      text,
      contains('Suggested ledger category: `ghost_overlap_stitching`'),
    );
    expect(text, contains('Add a `BUG-RECEIPT-####` ledger row'));
  });

  test('detached camera QA summary reports passed and failed batches', () async {
    final passName =
        'receipt_camera_summary_pass_${DateTime.now().microsecondsSinceEpoch}';
    final failName =
        'receipt_camera_summary_fail_${DateTime.now().microsecondsSinceEpoch}';
    final passRoot = Directory('/tmp/maintainiac_receipt_quiet_batch/$passName')
      ..createSync(recursive: true);
    final failRoot = Directory('/tmp/maintainiac_receipt_quiet_batch/$failName')
      ..createSync(recursive: true);
    addTearDown(() {
      if (passRoot.existsSync()) passRoot.deleteSync(recursive: true);
      if (failRoot.existsSync()) failRoot.deleteSync(recursive: true);
    });

    File('${passRoot.path}/status.txt').writeAsStringSync('passed');
    File('${passRoot.path}/exit_code').writeAsStringSync('0');
    File('${passRoot.path}/run.log').writeAsStringSync('All tests passed\n');

    File('${failRoot.path}/status.txt').writeAsStringSync('failed');
    File('${failRoot.path}/exit_code').writeAsStringSync('1');
    File('${failRoot.path}/run.log').writeAsStringSync(
      'Expected: receipt camera stitch ready\n'
      'Actual: missing OCR source handoff\n',
    );

    final passed = await Process.run('bash', [
      'tool/receipt_camera_qa_summary.sh',
      passName,
    ]);
    expect(passed.exitCode, 0, reason: passed.stderr.toString());
    expect(
      passed.stdout.toString(),
      contains('summary=passed_no_actionable_failures'),
    );

    final failed = await Process.run('bash', [
      'tool/receipt_camera_qa_summary.sh',
      failName,
    ]);
    expect(failed.exitCode, 0, reason: failed.stderr.toString());
    final output = failed.stdout.toString();
    expect(output, contains('summary=failed_actionable_lines'));
    expect(output, contains('regression_task_command='));
    expect(output, contains('Expected: receipt camera stitch ready'));
    expect(output, contains('Actual: missing OCR source handoff'));
  });

  test(
    'detached camera QA summary reports stale batches without log tailing',
    () async {
      final staleName =
          'receipt_camera_summary_stale_${DateTime.now().microsecondsSinceEpoch}';
      final staleRoot = Directory(
        '/tmp/maintainiac_receipt_quiet_batch/$staleName',
      )..createSync(recursive: true);
      addTearDown(() {
        if (staleRoot.existsSync()) staleRoot.deleteSync(recursive: true);
      });

      File('${staleRoot.path}/status.txt').writeAsStringSync('running');
      File('${staleRoot.path}/pid').writeAsStringSync('999999');
      File(
        '${staleRoot.path}/run.log',
      ).writeAsStringSync('This stale log should not be tailed.\n');

      final result = await Process.run('bash', [
        'tool/receipt_camera_qa_summary.sh',
        staleName,
      ]);

      expect(result.exitCode, 70, reason: result.stderr.toString());
      final output = result.stdout.toString();
      expect(output, contains('status=stale'));
      expect(output, contains('summary=batch_stale_requires_restart'));
      expect(output, contains('restart_command='));
      expect(output, isNot(contains('This stale log should not be tailed')));
    },
  );

  test(
    'detached camera QA summary avoids noisy tails without patterns',
    () async {
      final quietName =
          'receipt_camera_summary_quiet_${DateTime.now().microsecondsSinceEpoch}';
      final quietRoot = Directory(
        '/tmp/maintainiac_receipt_quiet_batch/$quietName',
      )..createSync(recursive: true);
      addTearDown(() {
        if (quietRoot.existsSync()) quietRoot.deleteSync(recursive: true);
      });

      File('${quietRoot.path}/status.txt').writeAsStringSync('failed');
      File('${quietRoot.path}/exit_code').writeAsStringSync('1');
      File('${quietRoot.path}/run.log').writeAsStringSync(
        'long neutral diagnostic line that should stay in the file only\n',
      );

      final result = await Process.run('bash', [
        'tool/receipt_camera_qa_summary.sh',
        quietName,
      ]);

      expect(result.exitCode, 0, reason: result.stderr.toString());
      final output = result.stdout.toString();
      expect(output, contains('summary=failed_actionable_lines'));
      expect(
        output,
        contains('summary_detail=no_actionable_patterns_found_check_log_path'),
      );
      expect(output, contains('log_path=${quietRoot.path}/run.log'));
      expect(output, isNot(contains('long neutral diagnostic line')));
    },
  );
}
