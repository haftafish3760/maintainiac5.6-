import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'camera QA gate prints executable mode plans without running QA',
    () async {
      Future<String> planFor(String mode) async {
        final result = await Process.run('bash', [
          'tool/receipt_camera_qa_gate.sh',
          '--print-plan',
          mode,
        ]);
        expect(result.exitCode, 0, reason: result.stderr.toString());
        return result.stdout.toString();
      }

      final phase2Plan = await planFor('phase2');
      expect(phase2Plan, contains('mode=phase2'));
      expect(
        phase2Plan,
        contains('phase2 test/receipt_import_source_sheet_test.dart'),
      );
      expect(
        phase2Plan,
        contains(
          'phase2 test/receipt_capture_flow_assist_opt_in_contract_test.dart',
        ),
      );
      expect(
        phase2Plan,
        contains('phase2 test/receipt_camera_capture_layout_test.dart'),
      );
      expect(
        phase2Plan,
        contains('phase2 test/receipt_capture_flow_handoff_order_test.dart'),
      );
      expect(phase2Plan, isNot(contains('quick ')));
      expect(phase2Plan, isNot(contains('milestone ')));
      expect(phase2Plan, isNot(contains('full ')));

      final phase3Plan = await planFor('phase3');
      expect(phase3Plan, contains('mode=phase3'));
      expect(
        phase3Plan,
        contains('phase3 test/receipt_camera_phase3_viewer_contract_test.dart'),
      );
      expect(
        phase3Plan,
        contains('phase3 test/receipt_native_camera_shell_test.dart'),
      );
      expect(
        phase3Plan,
        contains(
          'phase3 test/receipt_native_android_guidance_policy_gate_test.dart',
        ),
      );
      expect(
        phase3Plan,
        contains(
          'phase3 test/receipt_native_ios_guidance_warning_gate_test.dart',
        ),
      );
      expect(
        phase3Plan,
        contains(
          'phase3 test/receipt_native_android_bridge_false_positive_guard_test.dart',
        ),
      );
      expect(
        phase3Plan,
        contains(
          'phase3 test/receipt_native_ios_bridge_false_positive_guard_test.dart',
        ),
      );
      expect(phase3Plan, isNot(contains('quick ')));
      expect(phase3Plan, isNot(contains('milestone ')));
      expect(phase3Plan, isNot(contains('full ')));

      final phase4Plan = await planFor('phase4');
      expect(phase4Plan, contains('mode=phase4'));
      expect(
        phase4Plan,
        contains('phase4 test/receipt_camera_phase4_review_contract_test.dart'),
      );
      expect(
        phase4Plan,
        contains('phase4 test/receipt_photo_review_exit_completion_test.dart'),
      );
      expect(
        phase4Plan,
        contains('phase4 test/receipt_photo_review_quality_handoff_test.dart'),
      );
      expect(
        phase4Plan,
        contains('phase4 test/receipt_photo_section_labels_test.dart'),
      );
      expect(phase4Plan, isNot(contains('quick ')));
      expect(phase4Plan, isNot(contains('milestone ')));
      expect(phase4Plan, isNot(contains('full ')));

      final phase5Plan = await planFor('phase5');
      expect(phase5Plan, contains('mode=phase5'));
      expect(
        phase5Plan,
        contains('phase5 test/receipt_camera_phase5_long_receipt_contract_test.dart'),
      );
      expect(
        phase5Plan,
        contains('phase5 test/receipt_camera_long_receipt_guidance_test.dart'),
      );
      expect(
        phase5Plan,
        contains('phase5 test/receipt_photo_review_retake_order_test.dart'),
      );
      expect(
        phase5Plan,
        contains('phase5 test/receipt_native_camera_previous_section_channel_test.dart'),
      );
      expect(phase5Plan, isNot(contains('quick ')));
      expect(phase5Plan, isNot(contains('milestone ')));
      expect(phase5Plan, isNot(contains('full ')));

      final phase6Plan = await planFor('phase6');
      expect(phase6Plan, contains('mode=phase6'));
      expect(
        phase6Plan,
        contains('phase6 test/receipt_camera_phase6_stitching_handoff_contract_test.dart'),
      );
      expect(
        phase6Plan,
        contains('phase6 test/receipt_stitch_fallback_metadata_test.dart'),
      );
      expect(
        phase6Plan,
        contains('phase6 test/receipt_stitching_manual_overlap_test.dart'),
      );
      expect(
        phase6Plan,
        contains('phase6 test/receipt_stitching_result_contract_test.dart'),
      );
      expect(phase6Plan, isNot(contains('quick ')));
      expect(phase6Plan, isNot(contains('milestone ')));
      expect(phase6Plan, isNot(contains('full ')));

      final phase7Plan = await planFor('phase7');
      expect(phase7Plan, contains('mode=phase7'));
      expect(
        phase7Plan,
        contains('phase7 test/receipt_camera_phase7_ocr_source_handoff_contract_test.dart'),
      );
      expect(
        phase7Plan,
        contains('phase7 test/receipt_camera_ocr_source_handoff_test.dart'),
      );
      expect(
        phase7Plan,
        contains('phase7 test/receipt_capture_flow_ocr_source_count_test.dart'),
      );
      expect(
        phase7Plan,
        contains('phase7 test/receipt_image_ocr_source_guard_test.dart'),
      );
      expect(
        phase7Plan,
        contains('phase7 test/receipt_ocr_source_relationship_test.dart'),
      );
      expect(
        phase7Plan,
        contains('phase7 test/receipt_ocr_source_section_order_handoff_test.dart'),
      );
      expect(phase7Plan, isNot(contains('quick ')));
      expect(phase7Plan, isNot(contains('milestone ')));
      expect(phase7Plan, isNot(contains('full ')));

      final phase8Plan = await planFor('phase8');
      expect(phase8Plan, contains('mode=phase8'));
      expect(
        phase8Plan,
        contains('phase8 test/receipt_camera_phase8_storage_proof_timing_contract_test.dart'),
      );
      expect(
        phase8Plan,
        contains('phase8 test/receipt_native_camera_phase8_storage_timing_test.dart'),
      );
      expect(phase8Plan, isNot(contains('quick ')));
      expect(phase8Plan, isNot(contains('milestone ')));
      expect(phase8Plan, isNot(contains('full ')));

      final phase9Plan = await planFor('phase9');
      expect(phase9Plan, contains('mode=phase9'));
      expect(
        phase9Plan,
        contains('phase9 test/receipt_camera_completion_map_test.dart'),
      );
      expect(
        phase9Plan,
        contains('phase9 test/receipt_camera_release_one_blueprint_test.dart'),
      );
      expect(
        phase9Plan,
        contains('phase9 test/receipt_camera_release_control_priority_test.dart'),
      );
      expect(
        phase9Plan,
        contains('phase9 test/receipt_camera_native_baseline_policy_test.dart'),
      );
      expect(phase9Plan, isNot(contains('quick ')));
      expect(phase9Plan, isNot(contains('milestone ')));
      expect(phase9Plan, isNot(contains('full ')));

      final coreRemainingPlan = await planFor('core_remaining');
      expect(coreRemainingPlan, contains('mode=core_remaining'));
      expect(
        coreRemainingPlan,
        contains(
          'core_remaining test/receipt_camera_phase6_stitching_handoff_contract_test.dart',
        ),
      );
      expect(
        coreRemainingPlan,
        contains(
          'core_remaining test/receipt_camera_phase7_ocr_source_handoff_contract_test.dart',
        ),
      );
      expect(
        coreRemainingPlan,
        contains(
          'core_remaining test/receipt_camera_phase8_storage_proof_timing_contract_test.dart',
        ),
      );
      expect(coreRemainingPlan, isNot(contains('quick ')));
      expect(coreRemainingPlan, isNot(contains('milestone ')));
      expect(coreRemainingPlan, isNot(contains('full ')));

      final quickPlan = await planFor('quick');
      expect(quickPlan, contains('mode=quick'));
      expect(
        quickPlan,
        contains(
          'quick test/receipt_camera_dataset_qa_gate_contract_test.dart',
        ),
      );
      expect(
        quickPlan,
        contains('quick test/receipt_camera_qa_gate_contract_test.dart'),
      );
      expect(
        quickPlan,
        contains(
          'quick test/receipt_capture_flow_assist_opt_in_contract_test.dart',
        ),
      );
      expect(
        quickPlan,
        contains('quick test/receipt_import_source_sheet_test.dart'),
      );
      expect(
        quickPlan,
        contains('quick test/receipt_photo_review_exit_completion_test.dart'),
      );
      expect(
        quickPlan,
        contains('quick test/receipt_photo_review_quality_handoff_test.dart'),
      );
      expect(
        quickPlan,
        contains('quick test/receipt_external_dataset_local_audit_test.dart'),
      );
      expect(
        quickPlan,
        contains('quick test/receipt_external_dataset_gate_test.dart'),
      );
      expect(
        quickPlan,
        contains('quick test/receipt_external_fixture_schema_gate_test.dart'),
      );
      expect(
        quickPlan,
        contains('quick test/receipt_photo_section_labels_test.dart'),
      );
      expect(
        quickPlan,
        contains(
          'quick test/receipt_camera_real_device_snapshot_contract_test.dart',
        ),
      );
      expect(quickPlan, isNot(contains('milestone ')));
      expect(quickPlan, isNot(contains('full ')));

      final stitchPlan = await planFor('stitch');
      expect(stitchPlan, contains('mode=stitch'));
      expect(stitchPlan, contains('stitch test/receipt_stitching_test.dart'));
      expect(
        stitchPlan,
        contains(
          'stitch test/receipt_camera_result_frozen_handoff_counts_test.dart',
        ),
      );
      expect(
        stitchPlan,
        contains('stitch test/receipt_capture_flow_ocr_source_count_test.dart'),
      );
      expect(
        stitchPlan,
        contains('stitch test/receipt_photo_review_retake_order_test.dart'),
      );
      expect(stitchPlan, isNot(contains('quick ')));
      expect(stitchPlan, isNot(contains('milestone ')));
      expect(stitchPlan, isNot(contains('full ')));

      final milestonePlan = await planFor('milestone');
      expect(milestonePlan, contains('mode=milestone'));
      expect(
        milestonePlan,
        contains('milestone test/receipt_camera_ocr_source_handoff_test.dart'),
      );
      expect(
        milestonePlan,
        contains(
          'milestone test/receipt_camera_result_saved_photo_warning_test.dart',
        ),
      );
      expect(
        milestonePlan,
        contains(
          'milestone test/receipt_native_android_guidance_policy_gate_test.dart',
        ),
      );
      expect(
        milestonePlan,
        contains(
          'milestone test/receipt_native_ios_guidance_warning_gate_test.dart',
        ),
      );
      expect(
        milestonePlan,
        contains(
          'milestone test/receipt_capture_flow_ocr_source_count_test.dart',
        ),
      );
      expect(
        milestonePlan,
        contains('milestone test/receipt_photo_review_retake_order_test.dart'),
      );
      expect(milestonePlan, isNot(contains('full ')));

      final fullPlan = await planFor('full');
      expect(fullPlan, contains('mode=full'));
      expect(
        fullPlan,
        contains(
          'full test/receipt_native_ios_bridge_analysis_exposure_test.dart',
        ),
      );
      expect(fullPlan, contains('full test/receipt_camera_result_test.dart'));
      expect(
        fullPlan,
        contains('full test/receipt_ocr_source_completion_test.dart'),
      );
    },
  );

  test('camera QA printed plans only reference existing tests', () async {
    final missingPaths = <String>[];

    for (final mode in ['phase2', 'phase3', 'phase4', 'phase5', 'phase6', 'phase7', 'quick', 'stitch', 'milestone', 'full']) {
      final result = await Process.run('bash', [
        'tool/receipt_camera_qa_gate.sh',
        '--print-plan',
        mode,
      ]);
      expect(result.exitCode, 0, reason: result.stderr.toString());

      final lines = result.stdout
          .toString()
          .split('\n')
          .where(
            (line) =>
                line.startsWith('phase2 ') ||
                line.startsWith('phase3 ') ||
                line.startsWith('phase4 ') ||
                line.startsWith('phase5 ') ||
                line.startsWith('phase6 ') ||
                line.startsWith('phase7 ') ||
                line.startsWith('quick ') ||
                line.startsWith('stitch ') ||
                line.startsWith('milestone ') ||
                line.startsWith('full '),
          );
      for (final line in lines) {
        final path = line.split(' ').last;
        if (!File(path).existsSync()) {
          missingPaths.add('$mode: $path');
        }
      }
    }

    expect(missingPaths, isEmpty);
  });

  test(
    'full camera QA plan covers every camera native stitch and OCR test',
    () async {
      final result = await Process.run('bash', [
        'tool/receipt_camera_qa_gate.sh',
        '--print-plan',
        'full',
      ]);
      expect(result.exitCode, 0, reason: result.stderr.toString());
      final planned = result.stdout
          .toString()
          .split('\n')
          .where(
            (line) =>
                line.startsWith('quick ') ||
                line.startsWith('milestone ') ||
                line.startsWith('full '),
          )
          .map((line) => line.split(' ').last)
          .toSet();

      final diskTests = Directory('test')
          .listSync()
          .whereType<File>()
          .map((file) => file.path)
          .where(
            (path) =>
                path.contains('/receipt_camera_') ||
                path.contains('/receipt_native_') ||
                path.contains('/receipt_stitch') ||
                path.contains('/receipt_photo_review_retake_order') ||
                path.contains('/receipt_ocr_source'),
          )
          .where((path) => path.endsWith('.dart'))
          .map((path) => path.replaceFirst('${Directory.current.path}/', ''))
          .toSet();

      expect(planned, containsAll(diskTests));
    },
  );

  test('full camera QA plan includes every focused stitch test', () async {
    Future<Set<String>> plannedTestsFor(String mode) async {
      final result = await Process.run('bash', [
        'tool/receipt_camera_qa_gate.sh',
        '--print-plan',
        mode,
      ]);
      expect(result.exitCode, 0, reason: result.stderr.toString());
      return result.stdout
          .toString()
          .split('\n')
          .where(
            (line) =>
                line.startsWith('quick ') ||
                line.startsWith('stitch ') ||
                line.startsWith('milestone ') ||
                line.startsWith('full '),
          )
          .map((line) => line.split(' ').last)
          .toSet();
    }

    final stitchPlan = await plannedTestsFor('stitch');
    final fullPlan = await plannedTestsFor('full');

    expect(fullPlan, containsAll(stitchPlan));
  });

}
