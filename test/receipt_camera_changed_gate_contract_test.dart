import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'camera changed gate can print exact targeted tests for known native files',
    () async {
      final result = await Process.run(
        'bash',
        ['tool/receipt_camera_changed_gate.sh', '--print-tests'],
        environment: {
          'RECEIPT_CAMERA_CHANGED_FILES_FOR_TEST': [
            'android/app/src/main/kotlin/com/maintainiac/ReceiptCameraSettingsDialog.kt',
            'ios/Runner/ReceiptCameraViewControllerSessionSettings.swift',
          ].join('\n'),
        },
      );

      expect(result.exitCode, 0);
      final stdout = result.stdout.toString();
      expect(stdout, contains('mode=core_remaining'));
      expect(
        stdout,
        contains(
          'targeted test/receipt_native_android_bridge_settings_quality_test.dart',
        ),
      );
      expect(
        stdout,
        contains(
          'targeted test/receipt_native_ios_bridge_settings_close_test.dart',
        ),
      );
      expect(
        stdout,
        isNot(
          contains('quick test/receipt_camera_coverage_decision_test.dart'),
        ),
      );
    },
  );

  test(
    'camera changed gate routes real-device snapshot tooling to phase9 coverage',
    () async {
      final result = await Process.run(
        'bash',
        ['tool/receipt_camera_changed_gate.sh', '--print-tests'],
        environment: {
          'RECEIPT_CAMERA_CHANGED_FILES_FOR_TEST':
              'tool/receipt_camera_real_device_snapshot.sh',
        },
      );

      expect(result.exitCode, 0);
      final stdout = result.stdout.toString();
      expect(stdout, contains('mode=phase9'));
      expect(
        stdout,
        contains('targeted test/receipt_real_device_matrix_gate_test.dart'),
      );
      expect(
        stdout,
        contains(
          'targeted test/receipt_camera_real_device_snapshot_contract_test.dart',
        ),
      );
      expect(
        stdout,
        contains(
          'targeted test/receipt_real_device_result_start_script_test.dart',
        ),
      );
    },
  );

  test(
    'camera changed gate can print exact targeted tests for phase2 entry flow files',
    () async {
      final result = await Process.run(
        'bash',
        ['tool/receipt_camera_changed_gate.sh', '--print-tests'],
        environment: {
          'RECEIPT_CAMERA_CHANGED_FILES_FOR_TEST': [
            'lib/shared/widgets/receipt_capture/receipt_import_source_sheet.dart',
            'lib/shared/widgets/receipt_capture/receipt_attachment_camera_actions.dart',
            'lib/shared/widgets/receipt_capture/receipt_camera_first_use_intro_sheet.dart',
          ].join('\n'),
        },
      );

      expect(result.exitCode, 0);
      final stdout = result.stdout.toString();
      expect(stdout, contains('mode=phase2'));
      expect(
        stdout,
        contains('targeted test/receipt_import_source_sheet_test.dart'),
      );
      expect(
        stdout,
        contains(
          'targeted test/receipt_capture_flow_assist_opt_in_contract_test.dart',
        ),
      );
      expect(
        stdout,
        isNot(
          contains(
            'milestone test/receipt_camera_phase3_viewer_contract_test.dart',
          ),
        ),
      );
    },
  );

  test(
    'camera changed gate prints helper-parity checks for late OCR helper files',
    () async {
      final result = await Process.run(
        'bash',
        ['tool/receipt_camera_changed_gate.sh', '--print-tests'],
        environment: {
          'RECEIPT_CAMERA_CHANGED_FILES_FOR_TEST': [
            'lib/shared/widgets/receipt_capture/receipt_attachment_ocr_source_signals.dart',
            'lib/shared/widgets/receipt_capture/receipt_capture_flow_handoff_risks.dart',
          ].join('\n'),
        },
      );

      expect(result.exitCode, 0);
      final stdout = result.stdout.toString();
      expect(stdout, contains('mode=core_remaining'));
      expect(
        stdout,
        contains(
          'targeted test/receipt_camera_phase7_ocr_source_handoff_contract_test.dart',
        ),
      );
      expect(
        stdout,
        contains(
          'targeted test/receipt_camera_attachment_helper_parity_test.dart',
        ),
      );
      expect(
        stdout,
        isNot(
          contains(
            'milestone test/receipt_camera_phase4_review_contract_test.dart',
          ),
        ),
      );
    },
  );

  test(
    'camera changed gate prints exact phase9 checks for receipt-camera doc edits',
    () async {
      final result = await Process.run(
        'bash',
        ['tool/receipt_camera_changed_gate.sh', '--print-tests'],
        environment: {
          'RECEIPT_CAMERA_CHANGED_FILES_FOR_TEST': [
            'docs/receipt_camera_ocr_pipeline_handoff_report.md',
            'docs/receipt_camera_completion_map.md',
          ].join('\n'),
        },
      );

      expect(result.exitCode, 0);
      final stdout = result.stdout.toString();
      expect(stdout, contains('mode=phase9'));
      expect(
        stdout,
        contains('targeted test/receipt_camera_active_phase_docs_test.dart'),
      );
      expect(
        stdout,
        contains('targeted test/receipt_camera_completion_map_test.dart'),
      );
      expect(
        stdout,
        contains(
          'targeted test/receipt_camera_pipeline_handoff_status_test.dart',
        ),
      );
      expect(
        stdout,
        contains('targeted test/receipt_real_device_matrix_gate_test.dart'),
      );
      expect(
        stdout,
        contains('targeted test/receipt_real_device_result_gate_test.dart'),
      );
      expect(
        stdout,
        contains(
          'targeted test/receipt_real_device_result_start_script_test.dart',
        ),
      );
      expect(
        stdout,
        contains('targeted test/receipt_real_device_test_script_test.dart'),
      );
      expect(
        stdout,
        contains(
          'targeted test/receipt_camera_world_class_readiness_test.dart',
        ),
      );
      expect(
        stdout,
        isNot(
          contains('quick test/receipt_camera_coverage_decision_test.dart'),
        ),
      );
    },
  );

  test(
    'camera changed gate selects phase2 for entry flow files by default',
    () async {
      final result = await Process.run(
        'bash',
        ['tool/receipt_camera_changed_gate.sh', '--print-mode'],
        environment: {
          'RECEIPT_CAMERA_CHANGED_FILES_FOR_TEST': [
            'lib/shared/widgets/receipt_capture/receipt_import_source_sheet.dart',
            'lib/shared/widgets/receipt_capture/receipt_attachment_camera_actions.dart',
          ].join('\n'),
        },
      );

      expect(result.exitCode, 0);
      expect(
        result.stdout.toString(),
        contains(
          'Receipt camera changed gate: selected phase2 for tracked camera changes.',
        ),
      );
    },
  );

  test(
    'camera changed gate can print exact targeted tests for phase3 viewer shell files',
    () async {
      final result = await Process.run(
        'bash',
        ['tool/receipt_camera_changed_gate.sh', '--print-tests'],
        environment: {
          'RECEIPT_CAMERA_CHANGED_FILES_FOR_TEST': [
            'lib/shared/widgets/receipt_capture/receipt_native_camera_shell.dart',
            'lib/shared/widgets/receipt_capture/receipt_native_camera_shell_bottom_bar.dart',
          ].join('\n'),
        },
      );

      expect(result.exitCode, 0);
      final stdout = result.stdout.toString();
      expect(stdout, contains('mode=phase3'));
      expect(
        stdout,
        contains(
          'targeted test/receipt_camera_phase3_viewer_contract_test.dart',
        ),
      );
      expect(
        stdout,
        isNot(
          contains(
            'milestone test/receipt_camera_phase4_review_contract_test.dart',
          ),
        ),
      );
    },
  );

  test(
    'camera changed gate can print exact targeted tests for phase6 stitch files',
    () async {
      final result = await Process.run(
        'bash',
        ['tool/receipt_camera_changed_gate.sh', '--print-tests'],
        environment: {
          'RECEIPT_CAMERA_CHANGED_FILES_FOR_TEST': [
            'lib/shared/widgets/receipt_capture/receipt_capture_stitch_models.dart',
            'lib/shared/widgets/receipt_capture/receipt_image_processor_stitch_api.dart',
          ].join('\n'),
        },
      );

      expect(result.exitCode, 0);
      final stdout = result.stdout.toString();
      expect(stdout, contains('mode=phase6'));
      expect(
        stdout,
        contains(
          'targeted test/receipt_camera_phase6_stitching_handoff_contract_test.dart',
        ),
      );
      expect(
        stdout,
        contains(
          'targeted test/receipt_camera_low_confidence_stack_handoff_test.dart',
        ),
      );
      expect(
        stdout,
        contains(
          'targeted test/receipt_camera_oversized_stitch_handoff_test.dart',
        ),
      );
      expect(
        stdout,
        contains(
          'targeted test/receipt_camera_result_stitch_handoff_followthrough_test.dart',
        ),
      );
      expect(
        stdout,
        contains('targeted test/receipt_stitching_duplicate_safety_test.dart'),
      );
      expect(
        stdout,
        contains('targeted test/receipt_stitching_long_stack_test.dart'),
      );
      expect(
        stdout,
        contains(
          'targeted test/receipt_stitching_phone_window_safety_test.dart',
        ),
      );
      expect(
        stdout,
        contains('targeted test/receipt_stitching_variants_test.dart'),
      );
      expect(
        stdout,
        contains(
          'targeted test/receipt_stitching_weak_overlap_safety_test.dart',
        ),
      );
      expect(
        stdout,
        isNot(
          contains(
            'core_remaining test/receipt_camera_phase7_ocr_source_handoff_contract_test.dart',
          ),
        ),
      );
    },
  );
}
