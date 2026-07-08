import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('camera scope gate protects the branch from unrelated tracked edits', () {
    final script = File('tool/receipt_camera_scope_gate.sh').readAsStringSync();

    expect(script, contains('git diff --name-only'));
    expect(script, contains('SCOPE_FAIL'));
    expect(script, contains('tracked changes left the camera lane'));
    expect(script, contains('.gitignore'));
    expect(script, contains('lib/shared/widgets/receipt_capture/*'));
    expect(script, contains('lib/shared/receipts/*'));
    expect(script, contains('test/helpers/receipt_recovery_handoff_fixture.dart'));
    expect(script, contains('test/receipt_capture_flow_barcode_handoff_test.dart'));
    expect(script, contains('test/receipt_capture_flow_ocr_source_count_test.dart'));
    expect(script, contains('test/receipt_attachment_panel_actions_test.dart'));
    expect(script, contains('test/receipt_photo_review_*'));
    expect(
      script,
      contains('android/app/src/main/kotlin/com/maintainiac/ReceiptCamera*.kt'),
    );
    expect(script, contains('ios/Runner/ReceiptCamera*.swift'));
    expect(script, contains('docs/receipt_camera_completion_map.md'));
    expect(script, contains('docs/receipt_camera_ocr_pipeline_handoff_report.md'));
    expect(script, contains('docs/receipt_camera_roadmap.md'));
    expect(script, contains('docs/receipt_camera_ocr_product_standard.md'));
    expect(script, contains('docs/receipt_camera_ocr_master_pass_plan.md'));
    expect(script, contains('docs/receipt_camera_release_one_blueprint.md'));
    expect(script, contains('docs/receipt_camera_world_class_readiness.md'));
    expect(script, contains('docs/receipt_native_camera_service_spec.md'));
    expect(script, contains('docs/receipt_bug_regression_ledger.md'));
    expect(script, contains('test/receipt_camera_*'));
    expect(script, contains('test/receipt_native_*'));
    expect(script, contains('test/receipt_ocr_source_*'));
    expect(script, contains('test/receipt_photo_section_labels_test.dart'));
    expect(script, contains('test/receipt_external_dataset_local_audit_test.dart'));
    expect(script, contains('test/receipt_external_dataset_gate_test.dart'));
    expect(script, contains('test/receipt_external_fixture_schema_gate_test.dart'));
    expect(script, contains('test/receipt_stitch_fallback_metadata_test.dart'));
    expect(
      script,
      contains('test/fixtures/receipt_qa/external_dataset_manifest.json'),
    );
    expect(script, contains('test/receipt_stitching_*'));
    expect(script, contains('tool/receipt_bug_regression_ledger_gate.dart'));
    expect(script, contains('tool/receipt_camera_*'));
    expect(script, contains('tool/receipt_external_dataset_local_audit.dart'));
    expect(script, contains('tool/receipt_external_dataset_gate.dart'));
    expect(script, contains('tool/receipt_external_fixture_schema_gate.dart'));
    expect(script, contains('tool/receipt_pipeline_failure_to_regression.dart'));
    expect(script, contains('tool/receipt_quiet_batch.sh'));
    expect(script, contains('tool/receipt_quiet_batch_status.sh'));
    expect(
      script,
      contains('test/receipt_pipeline_failure_to_regression_test.dart'),
    );
    expect(script, isNot(contains('git ls-files --others')));
  });

  test('camera changed gate uses focused stitch mode for stitch-only edits', () {
    final script = File('tool/receipt_camera_changed_gate.sh').readAsStringSync();

    expect(script, contains('lib/shared/widgets/receipt_capture/*stitch*'));
    expect(script, contains('lib/shared/receipts/*stitch*'));
    expect(script, contains('test/helpers/receipt_stitching_*'));
    expect(script, contains('test/receipt_stitch_fallback_metadata_test.dart'));
    expect(script, contains('test/receipt_camera_result_stitch_scanner_test.dart'));
    expect(script, contains('test/receipt_ocr_source_relationship_test.dart'));
    expect(script, contains('tool/receipt_camera_stitch_gate.sh'));
    expect(script, contains('mode="stitch"'));
  });

  test('camera failure wrapper creates regression tasks from QA logs', () {
    final script = File(
      'tool/receipt_camera_failure_to_regression.sh',
    ).readAsStringSync();
    final gate = File('tool/receipt_camera_qa_gate.sh').readAsStringSync();
    final fastGuard = File('tool/receipt_fast_guard_gate.sh').readAsStringSync();

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
    expect(script, contains('dart tool/receipt_bug_regression_ledger_gate.dart'));
    expect(script, contains('dart analyze'));
    expect(script, contains('tool/receipt_bug_regression_ledger_gate.dart'));
    expect(script, contains('flutter test'));
    expect(script, contains('test/receipt_camera_long_receipt_guidance_test.dart'));
    expect(script, contains('test/receipt_camera_ocr_source_handoff_test.dart'));
    expect(script, contains('test/receipt_camera_fixture_matrix_test.dart'));
    expect(script, contains('test/receipt_camera_result_stitch_scanner_test.dart'));
    expect(script, contains('test/receipt_capture_flow_barcode_handoff_test.dart'));
    expect(script, contains('test/receipt_ocr_source_relationship_test.dart'));
    expect(
      script,
      contains('test/receipt_native_camera_previous_section_channel_test.dart'),
    );
    expect(script, contains('test/receipt_photo_review_retake_order_test.dart'));
    expect(script, contains('test/receipt_photo_section_labels_test.dart'));
    expect(script, contains('test/receipt_stitch_fallback_metadata_test.dart'));
    expect(script, contains('test/receipt_stitching_manual_overlap_test.dart'));
    expect(script, contains('test/receipt_stitching_result_contract_test.dart'));
    expect(script, contains('test/receipt_stitching_test.dart'));
    expect(script, contains('git diff --check'));
  });
}
