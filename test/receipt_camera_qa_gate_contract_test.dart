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
          'Usage: tool/receipt_start_camera_qa_gate.sh [phase2|phase3|phase4|phase5|phase6|phase7|phase8|phase9|core_remaining|quick|stitch|milestone|full]',
        ),
      );
    },
  );

  test('camera QA gate exposes phase2 phase3 phase4 phase5 phase6 phase7 phase8 phase9 core_remaining quick stitch milestone and full modes', () {
    final script = File('tool/receipt_camera_qa_gate.sh').readAsStringSync();

    expect(script, contains('--print-plan'));
    expect(script, contains(r'mode="${1:-milestone}"'));
    expect(script, contains('phase2 | phase3 | phase4 | phase5 | phase6 | phase7 | phase8 | phase9 | core_remaining | quick | stitch | milestone | full'));
    expect(script, contains('run_phase2'));
    expect(script, contains('run_phase3'));
    expect(script, contains('run_phase4'));
    expect(script, contains('run_phase5'));
    expect(script, contains('run_phase6'));
    expect(script, contains('run_phase7'));
    expect(script, contains('run_phase8'));
    expect(script, contains('run_phase9'));
    expect(script, contains('run_core_remaining'));
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
    expect(script, contains('phase8_tests=('));
    expect(script, contains('phase9_tests=('));
    expect(script, contains('core_remaining_tests=('));
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
    expect(script, contains('test/receipt_camera_phase8_storage_proof_timing_contract_test.dart'));
    expect(script, contains('test/receipt_native_camera_phase8_storage_timing_test.dart'));
    expect(script, contains('test/receipt_camera_completion_map_test.dart'));
    expect(script, contains('test/receipt_camera_pipeline_handoff_status_test.dart'));
    expect(script, contains('test/receipt_camera_active_phase_docs_test.dart'));
    expect(script, contains('test/receipt_camera_release_one_blueprint_test.dart'));
    expect(script, contains('test/receipt_camera_release_control_priority_test.dart'));
    expect(script, contains('test/receipt_camera_native_baseline_policy_test.dart'));
    expect(script, contains('test/receipt_real_device_matrix_gate_test.dart'));
    expect(script, contains('test/receipt_real_device_test_script_test.dart'));
    expect(script, contains('test/receipt_camera_world_class_readiness_test.dart'));
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

  test('camera phase9 gate blocks retired receipt-camera milestone claims', () {
    final script = File('tool/receipt_camera_qa_gate.sh').readAsStringSync();

    expect(script, contains('run_phase9_stale_contract_scan() {'));
    expect(script, contains('docs/receipt_camera_ocr_master_pass_plan.md'));
    expect(script, contains('docs/receipt_camera_completion_map.md'));
    expect(script, contains('docs/receipt_camera_ocr_pipeline_handoff_report.md'));
    expect(script, contains('docs/receipt_camera_release_one_blueprint.md'));
    expect(script, contains('docs/receipt_camera_world_class_readiness.md'));
    expect(script, contains('docs/receipt_real_device_test_script.md'));
    expect(script, contains('docs/receipt_real_device_result_template.md'));
    expect(script, contains('tool/receipt_real_device_matrix_gate.dart'));
    expect(script, contains('tool/receipt_real_device_result_gate.dart'));
    expect(script, contains('tool/receipt_real_device_result_start.sh'));
    expect(script, contains('PROJECT_RULES.md'));
    expect(script, contains('Current active phase: Phase 8'));
    expect(script, contains('Current active phase: Phase 9, Milestone validation'));
    expect(
      script,
      contains('Active roadmap focus: Phase 2 receipt entry flow verification'),
    );
    expect(
      script,
      contains('Active roadmap focus: Phase 6 through Phase 9 non-UI hardening and'),
    );
    expect(script, contains('1,500-2,500'));
    expect(script, contains('4,000-pass camera-app'));
    expect(script, contains('tap-to-focus'));
    expect(script, contains('tap to focus'));
    expect(
      script,
      contains('echo "Stale Phase 9 milestone-validation contract found." >&2'),
    );
    expect(script, contains('run_phase9_stale_contract_scan'));
  });

  test('camera milestone gate composes quick plus milestone-only checks', () {
    final script = File('tool/receipt_camera_qa_gate.sh').readAsStringSync();
    final milestoneBlock = _sourceBlock(
      script,
      'run_milestone() {',
      'run_full() {',
    );

    expect(milestoneBlock, contains('run_quick'));
    expect(
      milestoneBlock,
      contains(r'run_flutter_tests "${milestone_only_tests[@]}"'),
    );
    expect(milestoneBlock, isNot(contains('run_phase9')));
    expect(
      milestoneBlock,
      isNot(contains(r'run_flutter_tests "${full_only_tests[@]}"')),
    );
    expect(milestoneBlock, isNot(contains('receipt_camera_real_device_snapshot.sh')));
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
    expect(script, contains('phase2 | phase3 | phase4 | phase5 | phase6 | phase7 | phase8 | phase9 | core_remaining | quick | stitch | milestone | full'));
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
    expect(summary, contains('receipt_camera_qa_phase8'));
    expect(summary, contains('receipt_camera_qa_phase9'));
    expect(summary, contains('receipt_camera_qa_core_remaining'));
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
    expect(summary, contains('failure_phase="camera_phase8_gate"'));
    expect(summary, contains('failure_phase="camera_phase9_gate"'));
    expect(summary, contains('failure_phase="camera_core_remaining_gate"'));
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
    expect(fastGuard, contains('tool/receipt_real_device_result_start.sh'));
    expect(fastGuard, contains('tool/receipt_camera_stitch_gate.sh'));
    expect(fastGuard, contains('tool/receipt_start_camera_qa_gate.sh'));
    final stitchGate = File(
      'tool/receipt_camera_stitch_gate.sh',
    ).readAsStringSync();
    expect(stitchGate, contains('tool/receipt_camera_qa_gate.sh stitch'));
    expect(stitchGate, isNot(contains('flutter test')));
  });

}

String _sourceBlock(String source, String startToken, String endToken) {
  final start = source.indexOf(startToken);
  final end = source.indexOf(endToken, start);
  expect(start, greaterThanOrEqualTo(0));
  expect(end, greaterThan(start));
  return source.substring(start, end);
}
