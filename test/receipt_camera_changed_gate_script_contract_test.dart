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
    expect(script, contains('mode="core_remaining"'));
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
    expect(script, contains('tool/receipt_quiet_batch_final_summary.sh'));
    expect(script, contains('tool/receipt_camera_qa_gate.sh'));
    expect(script, contains('tool/receipt_camera_qa_gate.sh --print-plan'));
    expect(script, contains('targeted_tests+=('));
    expect(
      script,
      contains(
        'lib/shared/widgets/receipt_capture/receipt_import_source_sheet.dart',
      ),
    );
    expect(
      script,
      contains(
        'lib/shared/widgets/receipt_capture/receipt_attachment_camera_actions.dart',
      ),
    );
    expect(
      script,
      contains(
        'lib/shared/widgets/receipt_capture/receipt_camera_first_use_intro_sheet.dart',
      ),
    );
    expect(script, contains('docs/receipt_camera_ocr_master_pass_plan.md'));
    expect(script, contains('docs/receipt_camera_completion_map.md'));
    expect(
      script,
      contains('docs/receipt_camera_ocr_pipeline_handoff_report.md'),
    );
    expect(script, contains('docs/receipt_camera_release_one_blueprint.md'));
    expect(script, contains('docs/receipt_camera_world_class_readiness.md'));
    expect(script, contains('docs/receipt_real_device_test_script.md'));
    expect(script, contains('docs/receipt_native_camera_service_spec.md'));
    expect(script, contains('docs/receipt_camera_ocr_product_standard.md'));
    expect(script, contains('docs/receipt_camera_roadmap.md'));
    expect(script, contains('PROJECT_RULES.md'));
    expect(script, contains('README.md'));
    expect(script, contains('tool/receipt_camera_real_device_snapshot.sh'));
    expect(script, contains('tool/receipt_real_device_matrix_gate.dart'));
    expect(script, contains('test/receipt_real_device_matrix_gate_test.dart'));
    expect(
      script,
      contains('test/receipt_camera_real_device_snapshot_contract_test.dart'),
    );
    expect(
      script,
      contains(
        'lib/shared/widgets/receipt_capture/receipt_native_camera_shell.dart',
      ),
    );
    expect(
      script,
      contains(
        'lib/shared/widgets/receipt_capture/receipt_native_camera_shell_bottom_bar.dart',
      ),
    );
    expect(
      script,
      contains(
        'android/app/src/main/kotlin/com/maintainiac/ReceiptCameraActivity.kt',
      ),
    );
    expect(
      script,
      contains(
        'android/app/src/main/kotlin/com/maintainiac/ReceiptCameraFraming.kt',
      ),
    );
    expect(script, contains('ios/Runner/ReceiptCameraViewController.swift'));
    expect(
      script,
      contains('ios/Runner/ReceiptCameraViewControllerLiveReadability.swift'),
    );
    expect(
      script,
      contains(
        'android/app/src/main/kotlin/com/maintainiac/ReceiptCameraSettingsDialog.kt',
      ),
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
      contains('test/receipt_camera_phase3_viewer_contract_test.dart'),
    );
    expect(
      script,
      contains('test/receipt_native_android_guidance_policy_gate_test.dart'),
    );
    expect(
      script,
      contains('test/receipt_native_android_bridge_ui_contract_test.dart'),
    );
    expect(
      script,
      contains(
        'test/receipt_native_android_bridge_false_positive_guard_test.dart',
      ),
    );
    expect(
      script,
      contains('test/receipt_native_ios_guidance_warning_gate_test.dart'),
    );
    expect(
      script,
      contains('test/receipt_native_ios_bridge_ui_session_test.dart'),
    );
    expect(
      script,
      contains(
        'android/app/src/main/kotlin/com/maintainiac/MainActivity.kt | \\',
      ),
    );
    expect(script, contains('ios/Runner/AppDelegate.swift)'));
    expect(
      script,
      contains('test/receipt_native_android_bridge_settings_quality_test.dart'),
    );
    expect(
      script,
      contains('test/receipt_native_ios_bridge_settings_close_test.dart'),
    );
    expect(
      script,
      contains(
        'test/receipt_camera_phase6_stitching_handoff_contract_test.dart',
      ),
    );
    expect(
      script,
      contains(
        'test/receipt_camera_phase7_ocr_source_handoff_contract_test.dart',
      ),
    );
    expect(
      script,
      contains('test/receipt_camera_attachment_helper_parity_test.dart'),
    );
    expect(
      script,
      contains('test/receipt_camera_pipeline_handoff_status_test.dart'),
    );
    expect(script, contains('test/receipt_real_device_matrix_gate_test.dart'));
    expect(script, contains('test/receipt_real_device_test_script_test.dart'));
    expect(
      script,
      contains(
        'test/receipt_camera_phase8_storage_proof_timing_contract_test.dart',
      ),
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
}
