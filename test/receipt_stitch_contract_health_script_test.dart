import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('receipt stitch contract health script runs stitch and handoff tests', () {
    final script = File('tool/receipt_stitch_contract_health.sh');
    expect(script.existsSync(), isTrue);

    final source = script.readAsStringSync();
    expect(source, contains(r'mode="${1:-full}"'));
    expect(source, contains('run_milestone()'));
    expect(source, contains('delayed_overlap)'));
    expect(source, contains("--name 'delayed overlap'"));
    expect(source, contains('Receipt stitch delayed-overlap health: PASS'));
    expect(source, contains('edge_cases)'));
    expect(
      source,
      contains(
        "--name 'delayed overlap|horizontal drift correction|auto-cropped sideways continuation|blurred continuation overlap|wider handheld horizontal drift|faded worn receipt sections|continuation edge is clipped|severely cropped|faded receipt sections when continuation edge is clipped|missing middle section|middle section is missing|reverse order'",
      ),
    );
    expect(
      source,
      contains('receipt_stitching_horizontal_placement_test.dart'),
    );
    expect(source, contains('receipt_stitching_weak_overlap_safety_test.dart'));
    expect(source, contains('--concurrency=1'));
    expect(source, contains('receipt_stitching_horizontal_drift_test.dart'));
    expect(source, contains('receipt_stitching_worn_receipt_test.dart'));
    expect(source, contains('Receipt stitch edge-case health: PASS'));
    expect(source, contains('long_stack)'));
    expect(source, contains('Receipt stitch long-stack health: PASS'));
    expect(source, contains('phone_windows)'));
    expect(source, contains('Receipt stitch phone-window health'));
    expect(
      source,
      contains('test/receipt_stitching_phone_window_safety_test.dart'),
    );
    expect(
      source,
      contains(
        "--name 'phone-window captures|skipped phone-window|eleven-section|ugly seven-section'",
      ),
    );
    expect(source, contains('Receipt stitch phone-window health: PASS'));
    expect(source, contains('handoff)'));
    expect(
      source,
      contains('receipt_camera_phase5_long_receipt_contract_test.dart'),
    );
    expect(
      source,
      contains('receipt_camera_low_confidence_stack_handoff_test.dart'),
    );
    expect(
      source,
      contains('receipt_camera_oversized_stitch_handoff_test.dart'),
    );
    expect(
      source,
      contains('receipt_camera_phase6_stitching_handoff_contract_test.dart'),
    );
    expect(
      source,
      contains('receipt_camera_result_stitch_handoff_followthrough_test.dart'),
    );
    expect(
      source,
      contains('receipt_camera_stitch_candidate_metadata_test.dart'),
    );
    expect(source, contains('Receipt stitch handoff health: PASS'));
    expect(source, contains('duplicates)'));
    expect(source, contains('Receipt stitch duplicate-section health'));
    expect(source, contains('receipt_stitching_duplicate_safety_test.dart'));
    expect(source, contains('Receipt stitch duplicate-section health: PASS'));
    expect(source, contains('source_size)'));
    expect(source, contains('Receipt stitch source-size health'));
    expect(source, contains('receipt_image_processor_stitch_helpers.dart'));
    expect(source, contains(r'exceeds $max_lines-line stitch source cap'));
    expect(source, contains('test/receipt_stitching_*_test.dart'));
    expect(
      source,
      contains(
        'test/receipt_camera_result_stitch_handoff_followthrough_test.dart',
      ),
    );
    expect(source, contains(r'exceeds $max_lines-line stitch test cap'));
    expect(source, contains('Receipt stitch source-size health: PASS'));
    expect(source, contains('milestone)'));
    expect(source, contains('run_source_size'));
    expect(source, contains('run_edge_cases'));
    expect(source, contains('run_phone_windows'));
    expect(source, contains('run_long_stack'));
    expect(source, contains('run_duplicates'));
    expect(source, contains('run_handoff'));
    expect(source, contains('Receipt stitch milestone health: PASS'));
    expect(
      source,
      contains(
        r'Usage: $0 [delayed_overlap|edge_cases|phone_windows|long_stack|duplicates|handoff|source_size|milestone|full]',
      ),
    );
    expect(source, contains('receipt_native_camera_session_limits_test.dart'));
    expect(source, contains('receipt_capture_flow_shareability_test.dart'));
    expect(
      source,
      contains('receipt_camera_phase5_long_receipt_contract_test.dart'),
    );
    expect(source, contains('receipt_stitching_test.dart'));
    expect(source, contains('receipt_stitching_manual_overlap_test.dart'));
    expect(source, contains('receipt_stitching_duplicate_safety_test.dart'));
    expect(source, contains('receipt_stitching_scale_rotation_test.dart'));
    expect(source, contains('receipt_stitching_horizontal_drift_test.dart'));
    expect(source, contains('receipt_stitching_worn_receipt_test.dart'));
    expect(source, contains('receipt_stitching_long_stack_test.dart'));
    expect(source, contains('receipt_stitching_variants_test.dart'));
    expect(source, contains('receipt_camera_result_stitch_scanner_test.dart'));
    expect(
      source,
      contains('receipt_camera_low_confidence_stack_handoff_test.dart'),
    );
    expect(
      source,
      contains('receipt_camera_oversized_stitch_handoff_test.dart'),
    );
    expect(
      source,
      contains('receipt_camera_phase6_stitching_handoff_contract_test.dart'),
    );
    expect(
      source,
      contains('receipt_camera_result_stitch_handoff_followthrough_test.dart'),
    );
    expect(source, contains('Receipt stitch contract health: PASS'));
    expect(source, isNot(contains('receipt_camera_qa_gate.sh full')));
  });
}
