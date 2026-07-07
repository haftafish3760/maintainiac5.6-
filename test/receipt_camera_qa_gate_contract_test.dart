import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'camera detached QA starter rejects unknown modes before launching',
    () async {
      final result = await Process.run('bash', [
        'tool/receipt_start_camera_qa_gate.sh',
        'definitely-not-a-camera-mode',
      ]);

      expect(result.exitCode, 64);
      expect(
        result.stderr.toString(),
        contains(
          'Usage: tool/receipt_start_camera_qa_gate.sh [phase2|phase3|phase4|phase5|phase6|phase7|quick|stitch|milestone|full]',
        ),
      );
    },
  );

  test('camera QA gate exposes phase2 phase3 phase4 phase5 phase6 phase7 quick stitch milestone and full modes', () {
    final script = File('tool/receipt_camera_qa_gate.sh').readAsStringSync();

    expect(script, contains('--print-plan'));
    expect(script, contains(r'mode="${1:-milestone}"'));
    expect(script, contains('phase2 | phase3 | phase4 | phase5 | phase6 | phase7 | quick | stitch | milestone | full'));
    expect(script, contains('run_phase2'));
    expect(script, contains('run_phase3'));
    expect(script, contains('run_phase4'));
    expect(script, contains('run_phase5'));
    expect(script, contains('run_phase6'));
    expect(script, contains('run_phase7'));
    expect(script, contains('run_quick'));
    expect(script, contains('run_stitch'));
    expect(script, contains('run_milestone'));
    expect(script, contains('run_full'));
    expect(script, contains('phase2_tests=('));
    expect(script, contains('phase3_tests=('));
    expect(script, contains('phase4_tests=('));
    expect(script, contains('phase5_tests=('));
    expect(script, contains('phase6_tests=('));
    expect(script, contains('phase7_tests=('));
    expect(script, contains('stitch_tests=('));
    expect(script, contains('milestone_only_tests=('));
    expect(script, contains('full_only_tests=('));
    expect(script, contains('test/receipt_capture_flow_handoff_order_test.dart'));
    expect(script, contains('test/receipt_camera_phase3_viewer_contract_test.dart'));
    expect(script, contains('test/receipt_camera_phase4_review_contract_test.dart'));
    expect(script, contains('test/receipt_photo_review_exit_completion_test.dart'));
    expect(script, contains('test/receipt_camera_phase5_long_receipt_contract_test.dart'));
    expect(script, contains('test/receipt_photo_review_retake_order_test.dart'));
    expect(script, contains('test/receipt_camera_phase6_stitching_handoff_contract_test.dart'));
    expect(script, contains('test/receipt_stitching_result_contract_test.dart'));
    expect(script, contains('test/receipt_camera_phase7_ocr_source_handoff_contract_test.dart'));
    expect(script, contains('test/receipt_ocr_source_relationship_test.dart'));
    expect(script, contains('test/receipt_native_camera_shell_test.dart'));
    expect(script, contains('test/receipt_camera_result_test.dart'));
    expect(
      script,
      contains('test/receipt_camera_result_frozen_brain_install_test.dart'),
    );
    expect(
      script,
      contains('test/receipt_native_android_diagnostics_payload_test.dart'),
    );
    expect(
      script,
      contains('test/receipt_native_ios_project_membership_test.dart'),
    );
    expect(script, contains('test/receipt_ocr_source_completion_test.dart'));
    expect(script, contains('dart analyze'));
    expect(script, contains('lib/shared/widgets/receipt_capture'));
    expect(script, contains('lib/shared/receipts'));
    expect(script, contains('tool/receipt_bug_regression_ledger_gate.dart'));
    expect(
      script,
      contains('tool/receipt_camera_changed_route_coverage_gate.dart'),
    );
    expect(script, contains('tool/receipt_external_dataset_local_audit.dart'));
    expect(script, contains('tool/receipt_external_dataset_gate.dart'));
    expect(script, contains('tool/receipt_external_fixture_schema_gate.dart'));
    expect(
      script,
      contains('dart tool/receipt_bug_regression_ledger_gate.dart'),
    );
    expect(script, contains('dart tool/receipt_external_dataset_gate.dart'));
    expect(
      script,
      contains('dart tool/receipt_external_dataset_local_audit.dart'),
    );
    expect(
      script,
      contains('dart tool/receipt_camera_changed_route_coverage_gate.dart'),
    );
    expect(
      script,
      contains('dart tool/receipt_external_fixture_schema_gate.dart'),
    );
    expect(script, contains('bash tool/receipt_camera_scope_gate.sh'));
    expect(script, contains('dart tool/maintainiac_source_audit.dart'));
    expect(script, contains('run_line_cap_gate'));
    expect(script, contains('run_stale_contract_scan'));
    expect(script, contains('git diff --check'));

    final shellSyntaxBlock = script
        .split('bash -n \\')
        .last
        .split('bash tool/receipt_camera_scope_gate.sh')
        .first;
    expect(
      shellSyntaxBlock,
      isNot(contains('tool/receipt_external_fixture_schema_gate.dart')),
    );
  });

  test('camera QA gate avoids rerunning broader packs already covered', () {
    final script = File('tool/receipt_camera_qa_gate.sh').readAsStringSync();

    expect(script, contains('run_flutter_tests "\${quick_tests[@]}"'));
    expect(script, contains('run_flutter_tests "\${milestone_only_tests[@]}"'));
    expect(script, contains('run_flutter_tests "\${full_only_tests[@]}"'));
    expect(script, isNot(contains('milestone_tests=(')));
    expect(script, isNot(contains('full_tests=(')));
  });

  test('camera QA gate owns camera capture and stitching regression packs', () {
    final script = File('tool/receipt_camera_qa_gate.sh').readAsStringSync();

    expect(
      script,
      contains(
        'test/receipt_native_android_bridge_capture_quality_contract_test.dart',
      ),
    );
    expect(
      script,
      contains('test/receipt_native_android_bridge_settings_quality_test.dart'),
    );
    expect(
      script,
      contains('test/receipt_camera_long_receipt_guidance_test.dart'),
    );
    expect(script, contains('test/receipt_import_source_sheet_test.dart'));
    expect(
      script,
      contains('test/receipt_photo_review_exit_completion_test.dart'),
    );
    expect(
      script,
      contains('test/receipt_photo_review_quality_handoff_test.dart'),
    );
    expect(
      script,
      contains('test/receipt_external_dataset_local_audit_test.dart'),
    );
    expect(script, contains('test/receipt_external_dataset_gate_test.dart'));
    expect(
      script,
      contains('test/receipt_external_fixture_schema_gate_test.dart'),
    );
    expect(script, contains('test/receipt_photo_section_labels_test.dart'));
    expect(
      script,
      contains('test/receipt_camera_real_device_snapshot_contract_test.dart'),
    );
    expect(
      script,
      contains('test/receipt_camera_changed_route_coverage_gate_test.dart'),
    );
    expect(script, contains('test/receipt_camera_qa_gate_execution_test.dart'));
    expect(
      script,
      contains('test/receipt_camera_result_stitch_scanner_test.dart'),
    );
    expect(script, contains('test/receipt_camera_fixture_matrix_test.dart'));
    expect(
      script,
      contains('test/receipt_capture_flow_barcode_handoff_test.dart'),
    );
    expect(script, contains('test/receipt_ocr_source_relationship_test.dart'));
    expect(script, contains('test/receipt_stitch_fallback_metadata_test.dart'));
    expect(script, contains('test/receipt_stitching_manual_overlap_test.dart'));
    expect(
      script,
      contains('test/receipt_stitching_result_contract_test.dart'),
    );
    expect(script, contains('test/receipt_stitching_test.dart'));
    expect(
      script,
      contains('test/receipt_native_ios_bridge_long_receipt_quality_test.dart'),
    );
    expect(script, contains('print_test_pack stitch "\${stitch_tests[@]}"'));
    expect(script, contains('run_flutter_tests "\${stitch_tests[@]}"'));
  });

  test('camera QA gate scans for stale wording and retired controls', () {
    final script = File('tool/receipt_camera_qa_gate.sh').readAsStringSync();

    expect(script, contains('Next will review'));
    expect(script, contains('Before Next'));
    expect(script, contains('Icons.play_arrow_rounded'));
    expect(script, contains('Use focus assist only if'));
    expect(script, contains('continuous autofocus/readability guidance'));
  });

  test('camera QA gate can run detached without terminal monitoring', () {
    final script = File(
      'tool/receipt_start_camera_qa_gate.sh',
    ).readAsStringSync();
    final summary = File(
      'tool/receipt_camera_qa_summary.sh',
    ).readAsStringSync();
    final fastGuard = File(
      'tool/receipt_fast_guard_gate.sh',
    ).readAsStringSync();

    expect(script, contains(r'mode="${1:-milestone}"'));
    expect(script, contains('phase2 | phase3 | phase4 | phase5 | phase6 | phase7 | quick | stitch | milestone | full'));
    expect(script, contains(r'receipt_camera_qa_${mode}'));
    expect(script, contains('tool/receipt_quiet_batch.sh'));
    expect(script, contains('tool/receipt_camera_qa_gate.sh'));
    expect(script, contains(r'cp tool/receipt_camera_qa_gate.sh "$payload"'));
    expect(
      script,
      isNot(contains(r'''sed '' tool/receipt_camera_qa_gate.sh''')),
    );
    expect(summary, contains('tool/receipt_quiet_batch_status.sh'));
    expect(summary, contains('status_output='));
    expect(summary, contains('summary=batch_stale_requires_restart'));
    expect(summary, contains('restart_command='));
    expect(summary, contains('receipt_camera_qa_phase2'));
    expect(summary, contains('receipt_camera_qa_phase3'));
    expect(summary, contains('receipt_camera_qa_phase4'));
    expect(summary, contains('receipt_camera_qa_phase5'));
    expect(summary, contains('receipt_camera_qa_phase6'));
    expect(summary, contains('receipt_camera_qa_phase7'));
    expect(summary, contains('receipt_camera_qa_quick'));
    expect(summary, contains('receipt_camera_qa_stitch'));
    expect(summary, contains('receipt_camera_qa_milestone'));
    expect(summary, contains('receipt_camera_qa_full'));
    expect(summary, contains('summary=failed_actionable_lines'));
    expect(summary, contains('tool/receipt_camera_failure_to_regression.sh'));
    expect(summary, contains('regression_task_command='));
    expect(summary, contains('failure_phase="camera_phase2_gate"'));
    expect(summary, contains('failure_phase="camera_phase3_gate"'));
    expect(summary, contains('failure_phase="camera_phase4_gate"'));
    expect(summary, contains('failure_phase="camera_phase5_gate"'));
    expect(summary, contains('failure_phase="camera_phase6_gate"'));
    expect(summary, contains('failure_phase="camera_phase7_gate"'));
    expect(summary, contains('failure_phase="camera_quick_gate"'));
    expect(summary, contains('failure_phase="camera_stitch_gate"'));
    expect(summary, contains('failure_phase="camera_milestone_gate"'));
    expect(summary, contains('failure_phase="camera_full_gate"'));
    expect(summary, contains(r'actionable_pattern='));
    expect(summary, contains(r'\[E\]|To run this test again'));
    expect(summary, contains('|| true'));
    expect(
      summary,
      contains('summary_detail=no_actionable_patterns_found_check_log_path'),
    );
    expect(summary, contains('log_path='));
    expect(summary, isNot(contains(r'tail -80 "$log_file"')));
    expect(fastGuard, contains('tool/receipt_camera_scope_gate.sh'));
    expect(fastGuard, contains('tool/receipt_camera_changed_gate.sh'));
    expect(fastGuard, contains('tool/receipt_camera_qa_summary.sh'));
    expect(fastGuard, contains('tool/receipt_camera_real_device_snapshot.sh'));
    expect(fastGuard, contains('tool/receipt_camera_stitch_gate.sh'));
    expect(fastGuard, contains('tool/receipt_start_camera_qa_gate.sh'));
    final stitchGate = File(
      'tool/receipt_camera_stitch_gate.sh',
    ).readAsStringSync();
    expect(stitchGate, contains('tool/receipt_camera_qa_gate.sh stitch'));
    expect(stitchGate, isNot(contains('flutter test')));
  });

  test(
    'camera scope gate protects the branch from unrelated tracked edits',
    () {
      final script = File(
        'tool/receipt_camera_scope_gate.sh',
      ).readAsStringSync();

      expect(script, contains('git diff --name-only'));
      expect(script, contains('SCOPE_FAIL'));
      expect(script, contains('tracked changes left the camera lane'));
      expect(script, contains('.gitignore'));
      expect(script, contains('lib/shared/widgets/receipt_capture/*'));
      expect(script, contains('lib/shared/receipts/*'));
      expect(
        script,
        contains('test/helpers/receipt_recovery_handoff_fixture.dart'),
      );
      expect(
        script,
        contains('test/receipt_capture_flow_barcode_handoff_test.dart'),
      );
      expect(
        script,
        contains('test/receipt_capture_flow_ocr_source_count_test.dart'),
      );
      expect(script, contains('test/receipt_photo_review_*'));
      expect(
        script,
        contains(
          'android/app/src/main/kotlin/com/maintainiac/ReceiptCamera*.kt',
        ),
      );
      expect(script, contains('ios/Runner/ReceiptCamera*.swift'));
      expect(script, contains('docs/receipt_camera_ocr_master_pass_plan.md'));
      expect(script, contains('docs/receipt_bug_regression_ledger.md'));
      expect(script, contains('test/receipt_camera_*'));
      expect(script, contains('test/receipt_native_*'));
      expect(script, contains('test/receipt_ocr_source_*'));
      expect(script, contains('test/receipt_photo_section_labels_test.dart'));
      expect(
        script,
        contains('test/receipt_external_dataset_local_audit_test.dart'),
      );
      expect(script, contains('test/receipt_external_dataset_gate_test.dart'));
      expect(
        script,
        contains('test/receipt_external_fixture_schema_gate_test.dart'),
      );
      expect(
        script,
        contains('test/receipt_stitch_fallback_metadata_test.dart'),
      );
      expect(
        script,
        contains('test/fixtures/receipt_qa/external_dataset_manifest.json'),
      );
      expect(script, contains('test/receipt_stitching_*'));
      expect(script, contains('tool/receipt_bug_regression_ledger_gate.dart'));
      expect(script, contains('tool/receipt_camera_*'));
      expect(
        script,
        contains('tool/receipt_external_dataset_local_audit.dart'),
      );
      expect(script, contains('tool/receipt_external_dataset_gate.dart'));
      expect(
        script,
        contains('tool/receipt_external_fixture_schema_gate.dart'),
      );
      expect(
        script,
        contains('tool/receipt_pipeline_failure_to_regression.dart'),
      );
      expect(script, contains('tool/receipt_quiet_batch.sh'));
      expect(script, contains('tool/receipt_quiet_batch_status.sh'));
      expect(
        script,
        contains('test/receipt_pipeline_failure_to_regression_test.dart'),
      );
      expect(script, isNot(contains('git ls-files --others')));
    },
  );

  test(
    'camera changed gate uses focused stitch mode for stitch-only edits',
    () {
      final script = File(
        'tool/receipt_camera_changed_gate.sh',
      ).readAsStringSync();

      expect(script, contains('lib/shared/widgets/receipt_capture/*stitch*'));
      expect(script, contains('lib/shared/receipts/*stitch*'));
      expect(script, contains('test/helpers/receipt_stitching_*'));
      expect(
        script,
        contains('test/receipt_stitch_fallback_metadata_test.dart'),
      );
      expect(
        script,
        contains('test/receipt_camera_result_stitch_scanner_test.dart'),
      );
      expect(
        script,
        contains('test/receipt_ocr_source_relationship_test.dart'),
      );
      expect(script, contains('tool/receipt_camera_stitch_gate.sh'));
      expect(script, contains('mode="stitch"'));
    },
  );

  test('camera failure wrapper creates regression tasks from QA logs', () {
    final script = File(
      'tool/receipt_camera_failure_to_regression.sh',
    ).readAsStringSync();
    final gate = File('tool/receipt_camera_qa_gate.sh').readAsStringSync();
    final fastGuard = File(
      'tool/receipt_fast_guard_gate.sh',
    ).readAsStringSync();

    expect(script, contains('<phase> <log-file>'));
    expect(script, contains('camera_pipeline_contracts'));
    expect(script, contains('native_camera_compile'));
    expect(script, contains('camera_stitching'));
    expect(script, contains('camera_stitch_gate'));
    expect(script, contains('phase="camera_pipeline_contracts"'));
    expect(script, contains('phase="camera_stitch_gate"'));
    expect(script, contains('phase="native_camera_compile"'));
    expect(script, contains('receipt_camera_qa_failure'));
    expect(script, contains('CAMERA_PHASE %s'));
    expect(script, contains('FAILED_PHASE %s'));
    expect(script, contains('LOG %s'));
    expect(
      script,
      contains('tool/receipt_pipeline_failure_to_regression.dart'),
    );
    expect(gate, contains('tool/receipt_camera_failure_to_regression.sh'));
    expect(fastGuard, contains('tool/receipt_camera_failure_to_regression.sh'));
  });

  test('camera stitch gate focuses long receipt stitching risk', () {
    final stitchGate = File(
      'tool/receipt_camera_stitch_gate.sh',
    ).readAsStringSync();
    final script = File('tool/receipt_camera_qa_gate.sh').readAsStringSync();

    expect(stitchGate, contains('tool/receipt_camera_qa_gate.sh stitch'));
    expect(stitchGate, isNot(contains('flutter test')));
    expect(stitchGate, isNot(contains('dart analyze')));
    expect(script, contains('tool/receipt_camera_scope_gate.sh'));
    expect(
      script,
      contains('dart tool/receipt_bug_regression_ledger_gate.dart'),
    );
    expect(script, contains('dart analyze'));
    expect(script, contains('tool/receipt_bug_regression_ledger_gate.dart'));
    expect(script, contains('flutter test'));
    expect(
      script,
      contains('test/receipt_camera_long_receipt_guidance_test.dart'),
    );
    expect(
      script,
      contains('test/receipt_camera_ocr_source_handoff_test.dart'),
    );
    expect(script, contains('test/receipt_camera_fixture_matrix_test.dart'));
    expect(
      script,
      contains('test/receipt_camera_result_stitch_scanner_test.dart'),
    );
    expect(
      script,
      contains('test/receipt_capture_flow_barcode_handoff_test.dart'),
    );
    expect(script, contains('test/receipt_ocr_source_relationship_test.dart'));
    expect(
      script,
      contains('test/receipt_native_camera_previous_section_channel_test.dart'),
    );
    expect(
      script,
      contains('test/receipt_photo_review_retake_order_test.dart'),
    );
    expect(script, contains('test/receipt_photo_section_labels_test.dart'));
    expect(script, contains('test/receipt_stitch_fallback_metadata_test.dart'));
    expect(script, contains('test/receipt_stitching_manual_overlap_test.dart'));
    expect(
      script,
      contains('test/receipt_stitching_result_contract_test.dart'),
    );
    expect(script, contains('test/receipt_stitching_test.dart'));
    expect(script, contains('git diff --check'));
  });
}
