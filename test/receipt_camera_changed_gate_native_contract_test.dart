import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'camera changed gate can print exact targeted tests for native phase3 viewer files',
    () async {
      final result = await Process.run(
        'bash',
        ['tool/receipt_camera_changed_gate.sh', '--print-tests'],
        environment: {
          'RECEIPT_CAMERA_CHANGED_FILES_FOR_TEST': [
            'android/app/src/main/kotlin/com/maintainiac/ReceiptCameraActivity.kt',
            'android/app/src/main/kotlin/com/maintainiac/ReceiptCameraFraming.kt',
            'ios/Runner/ReceiptCameraViewController.swift',
            'ios/Runner/ReceiptCameraViewControllerLiveReadability.swift',
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
        contains(
          'targeted test/receipt_native_android_bridge_ui_contract_test.dart',
        ),
      );
      expect(
        stdout,
        contains(
          'targeted test/receipt_native_android_guidance_policy_gate_test.dart',
        ),
      );
      expect(
        stdout,
        contains(
          'targeted test/receipt_native_android_bridge_false_positive_guard_test.dart',
        ),
      );
      expect(
        stdout,
        contains(
          'targeted test/receipt_native_ios_guidance_warning_gate_test.dart',
        ),
      );
      expect(
        stdout,
        contains(
          'targeted test/receipt_native_ios_bridge_ui_session_test.dart',
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
    'camera changed gate keeps native phase3 viewer files on the phase3 lane by default',
    () async {
      final result = await Process.run(
        'bash',
        ['tool/receipt_camera_changed_gate.sh', '--print-mode'],
        environment: {
          'RECEIPT_CAMERA_CHANGED_FILES_FOR_TEST': [
            'android/app/src/main/kotlin/com/maintainiac/ReceiptCameraActivity.kt',
            'ios/Runner/ReceiptCameraViewController.swift',
          ].join('\n'),
        },
      );

      expect(result.exitCode, 0);
      expect(
        result.stdout.toString(),
        contains(
          'Receipt camera changed gate: selected phase3 for tracked camera changes.',
        ),
      );
    },
  );

  test(
    'camera changed gate selects core remaining for stitch and OCR handoff files',
    () async {
      final result = await Process.run(
        'bash',
        ['tool/receipt_camera_changed_gate.sh', '--print-mode'],
        environment: {
          'RECEIPT_CAMERA_CHANGED_FILES_FOR_TEST': [
            'lib/shared/widgets/receipt_capture/receipt_capture_stitch_models.dart',
            'lib/shared/widgets/receipt_capture/receipt_ocr_source_handoff.dart',
          ].join('\n'),
        },
      );

      expect(result.exitCode, 0);
      expect(
        result.stdout.toString(),
        contains(
          'Receipt camera changed gate: selected core_remaining for tracked camera changes.',
        ),
      );
    },
  );

  test(
    'camera changed gate selects core remaining for storage timing files',
    () async {
      final result = await Process.run(
        'bash',
        ['tool/receipt_camera_changed_gate.sh', '--print-mode'],
        environment: {
          'RECEIPT_CAMERA_CHANGED_FILES_FOR_TEST': [
            'lib/shared/widgets/receipt_capture/receipt_attachment_publish_helpers.dart',
            'ios/Runner/ReceiptCameraViewControllerSessionSettings.swift',
          ].join('\n'),
        },
      );

      expect(result.exitCode, 0);
      expect(
        result.stdout.toString(),
        contains(
          'Receipt camera changed gate: selected core_remaining for tracked camera changes.',
        ),
      );
    },
  );
}
