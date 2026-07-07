import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('camera changed gate selects safe QA depth from tracked edits', () {
    final script = File(
      'tool/receipt_camera_changed_gate.sh',
    ).readAsStringSync();

    expect(script, contains('tool/receipt_camera_scope_gate.sh'));
    expect(script, contains('RECEIPT_CAMERA_CHANGED_FILES_FOR_TEST'));
    expect(script, contains('--print-mode'));
    expect(script, contains('--print-tests'));
    expect(
      script,
      contains('git diff --name-only --diff-filter=ACMRTUXB HEAD'),
    );
    expect(script, contains('no tracked camera changes; skipping QA rerun'));
    expect(script, contains('mode="quick"'));
    expect(script, contains('mode="stitch"'));
    expect(script, contains('mode="milestone"'));
    expect(script, contains('mode="full"'));
    expect(script, contains('tool/receipt_start_camera_qa_gate.sh'));
    expect(
      script,
      contains('tool/receipt_camera_changed_route_coverage_gate.dart'),
    );
    expect(script, contains('tool/receipt_camera_qa_summary.sh'));
    expect(script, contains('tool/receipt_external_dataset_local_audit.dart'));
    expect(script, contains('tool/receipt_external_dataset_gate.dart'));
    expect(script, contains('tool/receipt_external_fixture_schema_gate.dart'));
    expect(script, contains('tool/receipt_quiet_batch.sh'));
    expect(script, contains('tool/receipt_quiet_batch_status.sh'));
    expect(script, contains('tool/receipt_camera_qa_gate.sh'));
    expect(script, contains('tool/receipt_camera_qa_gate.sh --print-plan'));
    expect(script, contains('targeted_tests+=('));
    expect(
      script,
      contains('lib/shared/widgets/receipt_capture/receipt_import_source_sheet.dart'),
    );
    expect(
      script,
      contains('lib/shared/widgets/receipt_capture/receipt_attachment_camera_actions.dart'),
    );
    expect(
      script,
      contains('lib/shared/widgets/receipt_capture/receipt_camera_first_use_intro_sheet.dart'),
    );
    expect(
      script,
      contains('android/app/src/main/kotlin/com/maintainiac/ReceiptCameraSettingsDialog.kt'),
    );
    expect(
      script,
      contains('ios/Runner/ReceiptCameraViewControllerSessionSettings.swift'),
    );
    expect(script, contains('test/receipt_import_source_sheet_test.dart'));
    expect(
      script,
      contains('test/receipt_capture_flow_assist_opt_in_contract_test.dart'),
    );
    expect(
      script,
      contains('test/receipt_native_android_bridge_settings_quality_test.dart'),
    );
    expect(
      script,
      contains('test/receipt_native_ios_bridge_settings_close_test.dart'),
    );
    expect(script, contains('awk \'!seen[\$0]++'));
    expect(script, contains('test/receipt_camera_qa_gate_contract_test.dart'));
    expect(
      script,
      contains('test/receipt_camera_changed_route_coverage_gate_test.dart'),
    );
    expect(script, contains('test/receipt_camera_qa_gate_execution_test.dart'));
    expect(
      script,
      contains('test/receipt_external_dataset_local_audit_test.dart'),
    );
    expect(script, contains('test/receipt_external_dataset_gate_test.dart'));
    expect(
      script,
      contains('android/app/src/main/kotlin/com/maintainiac/ReceiptCamera*.kt'),
    );
    expect(script, contains('ios/Runner/ReceiptCamera*.swift'));
    expect(script, contains('test/receipt_stitching_*'));
    expect(script, contains('test/receipt_ocr_source_*'));
    expect(script, isNot(contains('git ls-files --others')));
  });

  test('camera changed gate can print exact targeted tests for known native files', () async {
    final result = await Process.run('bash', [
      'tool/receipt_camera_changed_gate.sh',
      '--print-tests',
    ], environment: {
      'RECEIPT_CAMERA_CHANGED_FILES_FOR_TEST': [
        'android/app/src/main/kotlin/com/maintainiac/ReceiptCameraSettingsDialog.kt',
        'ios/Runner/ReceiptCameraViewControllerSessionSettings.swift',
      ].join('\n'),
    });

    expect(result.exitCode, 0);
    final stdout = result.stdout.toString();
    expect(stdout, contains('mode=milestone'));
    expect(
      stdout,
      contains(
        'targeted test/receipt_native_android_bridge_settings_quality_test.dart',
      ),
    );
    expect(
      stdout,
      contains('targeted test/receipt_native_ios_bridge_settings_close_test.dart'),
    );
    expect(stdout, isNot(contains('quick test/receipt_camera_coverage_decision_test.dart')));
  });

  test('camera changed gate can print exact targeted tests for phase2 entry flow files', () async {
    final result = await Process.run('bash', [
      'tool/receipt_camera_changed_gate.sh',
      '--print-tests',
    ], environment: {
      'RECEIPT_CAMERA_CHANGED_FILES_FOR_TEST': [
        'lib/shared/widgets/receipt_capture/receipt_import_source_sheet.dart',
        'lib/shared/widgets/receipt_capture/receipt_attachment_camera_actions.dart',
        'lib/shared/widgets/receipt_capture/receipt_camera_first_use_intro_sheet.dart',
      ].join('\n'),
    });

    expect(result.exitCode, 0);
    final stdout = result.stdout.toString();
    expect(stdout, contains('mode=quick'));
    expect(
      stdout,
      contains('targeted test/receipt_import_source_sheet_test.dart'),
    );
    expect(
      stdout,
      contains('targeted test/receipt_capture_flow_assist_opt_in_contract_test.dart'),
    );
    expect(
      stdout,
      isNot(contains('milestone test/receipt_camera_phase3_viewer_contract_test.dart')),
    );
  });
}
