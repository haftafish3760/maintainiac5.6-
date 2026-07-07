import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('camera QA gate exposes quick milestone and full modes', () {
    final script = File('tool/receipt_camera_qa_gate.sh').readAsStringSync();

    expect(script, contains(r'mode="${1:-milestone}"'));
    expect(script, contains('quick | milestone | full'));
    expect(script, contains('run_quick'));
    expect(script, contains('run_milestone'));
    expect(script, contains('run_full'));
    expect(script, contains('milestone_only_tests=('));
    expect(script, contains('full_only_tests=('));
    expect(script, contains('dart analyze lib/shared/widgets/receipt_capture'));
    expect(script, contains('dart tool/maintainiac_source_audit.dart'));
    expect(script, contains('run_line_cap_gate'));
    expect(script, contains('run_stale_contract_scan'));
    expect(script, contains('git diff --check'));
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
    expect(
      script,
      contains('test/receipt_camera_result_stitch_scanner_test.dart'),
    );
    expect(script, contains('test/receipt_stitching_manual_overlap_test.dart'));
    expect(script, contains('test/receipt_stitching_test.dart'));
    expect(
      script,
      contains('test/receipt_native_ios_bridge_long_receipt_quality_test.dart'),
    );
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
    expect(script, contains('quick | milestone | full'));
    expect(script, contains(r'receipt_camera_qa_${mode}'));
    expect(script, contains('tool/receipt_quiet_batch.sh'));
    expect(script, contains('tool/receipt_camera_qa_gate.sh'));
    expect(summary, contains('tool/receipt_quiet_batch_status.sh'));
    expect(summary, contains(r'receipt_camera_qa_$name'));
    expect(summary, contains('summary=failed_actionable_lines'));
    expect(summary, contains('tail -80'));
    expect(fastGuard, contains('tool/receipt_camera_qa_summary.sh'));
    expect(fastGuard, contains('tool/receipt_start_camera_qa_gate.sh'));
  });
}
