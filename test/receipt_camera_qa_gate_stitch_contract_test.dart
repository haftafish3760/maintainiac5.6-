import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
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
    expect(
      script,
      contains('test/receipt_camera_phase5_long_receipt_contract_test.dart'),
    );
    expect(
      script,
      contains(
        'test/receipt_camera_phase6_stitching_handoff_contract_test.dart',
      ),
    );
    expect(
      script,
      contains('test/receipt_camera_low_confidence_stack_handoff_test.dart'),
    );
    expect(
      script,
      contains('test/receipt_camera_oversized_stitch_handoff_test.dart'),
    );
    expect(
      script,
      contains('test/receipt_capture_flow_shareability_test.dart'),
    );
    expect(
      script,
      contains('test/receipt_native_camera_session_limits_test.dart'),
    );
    expect(script, contains('test/receipt_camera_fixture_matrix_test.dart'));
    expect(
      script,
      contains(
        'test/receipt_camera_result_stitch_handoff_followthrough_test.dart',
      ),
    );
    expect(
      script,
      contains('test/receipt_camera_stitch_candidate_metadata_test.dart'),
    );
    expect(
      script,
      contains('test/receipt_capture_flow_barcode_handoff_test.dart'),
    );
    expect(script, contains('test/receipt_ocr_source_relationship_test.dart'));
    expect(script, contains('test/receipt_stitch_fallback_metadata_test.dart'));
    expect(
      script,
      contains('test/receipt_stitching_duplicate_safety_test.dart'),
    );
    expect(
      script,
      contains('test/receipt_stitching_horizontal_drift_test.dart'),
    );
    expect(
      script,
      contains('test/receipt_stitching_horizontal_placement_test.dart'),
    );
    expect(script, contains('test/receipt_stitching_long_stack_test.dart'));
    expect(script, contains('test/receipt_stitching_manual_overlap_test.dart'));
    expect(
      script,
      contains('test/receipt_stitching_phone_window_safety_test.dart'),
    );
    expect(
      script,
      contains('test/receipt_stitching_result_contract_test.dart'),
    );
    expect(script, contains('test/receipt_stitching_scale_rotation_test.dart'));
    expect(script, contains('test/receipt_stitching_test.dart'));
    expect(script, contains('test/receipt_stitching_variants_test.dart'));
    expect(
      script,
      contains('test/receipt_stitching_weak_overlap_safety_test.dart'),
    );
    expect(script, contains('test/receipt_stitching_worn_receipt_test.dart'));
    expect(
      script,
      contains('test/receipt_native_ios_bridge_long_receipt_quality_test.dart'),
    );
    expect(script, contains('print_test_pack stitch "\${stitch_tests[@]}"'));
    expect(script, contains('run_flutter_tests "\${stitch_tests[@]}"'));
  });
}
