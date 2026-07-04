import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_flow.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  test('auto capture cannot be ready without manual shutter fallback', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/auto-no-manual.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/auto-no-manual-ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: const ReceiptStitchResult.notNeeded([
        '/tmp/auto-no-manual-ocr.jpg',
      ]),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/auto-no-manual.jpg': {
          'captureReadinessCode': 'auto_capture_ready',
          'manualCaptureAllowed': false,
          'autoCaptureAllowed': true,
          'autoCaptureEnabled': true,
          'manualCapturePolicy':
              'guidance_advisory_manual_shutter_always_allowed',
        },
      },
    );

    expect(
      result.nativeCameraUiHealthOutcome,
      'auto_capture_without_manual_shutter_regressed',
    );
    expect(
      result
          .nativeCameraUiHealthCounts['auto_capture_without_manual_shutter_regressed'],
      1,
    );

    final attachments = ReceiptCaptureFlow.attachmentsFromReviewResult(
      result,
      ReceiptCaptureFlowModule.expenses,
    );
    expect(
      attachments.single.riskFlags,
      contains(
        'native_camera_ui_auto_capture_without_manual_shutter_regressed',
      ),
    );
  });

  test('auto capture ready cannot be reported while blocked', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/auto-blocked.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/auto-blocked-ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: const ReceiptStitchResult.notNeeded([
        '/tmp/auto-blocked-ocr.jpg',
      ]),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/auto-blocked.jpg': {
          'captureReadinessCode': 'auto_capture_ready',
          'manualCaptureAllowed': true,
          'autoCaptureAllowed': false,
          'autoCaptureEnabled': true,
        },
      },
    );

    expect(
      result.nativeCameraUiHealthOutcome,
      'auto_capture_ready_while_blocked_regressed',
    );
    expect(
      result
          .nativeCameraUiHealthCounts['auto_capture_ready_while_blocked_regressed'],
      1,
    );
  });

  test('auto capture allowed requires an explicit opt-in request', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/auto-unrequested.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/auto-unrequested-ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: const ReceiptStitchResult.notNeeded([
        '/tmp/auto-unrequested-ocr.jpg',
      ]),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/auto-unrequested.jpg': {
          'captureReadinessCode': 'manual_ready_auto_capture_off',
          'manualCaptureAllowed': true,
          'autoCaptureAllowed': true,
          'autoCaptureEnabled': false,
        },
      },
    );

    expect(
      result.nativeCameraUiHealthOutcome,
      'auto_capture_allowed_without_request_regressed',
    );
    expect(
      result
          .nativeCameraUiHealthCounts['auto_capture_allowed_without_request_regressed'],
      1,
    );
  });

  test('auto capture ready requires enough stable frames', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/auto-early.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/auto-early-ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: const ReceiptStitchResult.notNeeded([
        '/tmp/auto-early-ocr.jpg',
      ]),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/auto-early.jpg': {
          'captureReadinessCode': 'auto_capture_ready',
          'manualCaptureAllowed': true,
          'autoCaptureAllowed': true,
          'autoCaptureEnabled': true,
          'stableFrameCount': 1,
          'requiredStableFrames': 3,
        },
      },
    );

    expect(
      result.nativeCameraUiHealthOutcome,
      'auto_capture_ready_before_stable_regressed',
    );
    expect(
      result
          .nativeCameraUiHealthCounts['auto_capture_ready_before_stable_regressed'],
      1,
    );
  });

  test('auto capture ready requires stability diagnostics', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/auto-missing-stability.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/auto-missing-stability-ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: const ReceiptStitchResult.notNeeded([
        '/tmp/auto-missing-stability-ocr.jpg',
      ]),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/auto-missing-stability.jpg': {
          'captureReadinessCode': 'auto_capture_ready',
          'manualCaptureAllowed': true,
          'autoCaptureAllowed': true,
          'autoCaptureEnabled': true,
        },
      },
    );

    expect(
      result.nativeCameraUiHealthOutcome,
      'auto_capture_ready_missing_stability_evidence',
    );
    expect(
      result
          .nativeCameraUiHealthCounts['auto_capture_ready_missing_stability_evidence'],
      1,
    );
  });

  test('auto capture waiting cannot be reported after stability target', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/auto-waiting-stable.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/auto-waiting-stable-ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: const ReceiptStitchResult.notNeeded([
        '/tmp/auto-waiting-stable-ocr.jpg',
      ]),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/auto-waiting-stable.jpg': {
          'captureReadinessCode': 'auto_capture_waiting_for_stability',
          'manualCaptureAllowed': true,
          'autoCaptureAllowed': false,
          'autoCaptureEnabled': true,
          'stableFrameCount': 3,
          'requiredStableFrames': 3,
        },
      },
    );

    expect(
      result.nativeCameraUiHealthOutcome,
      'auto_capture_waiting_after_stable_regressed',
    );
    expect(
      result
          .nativeCameraUiHealthCounts['auto_capture_waiting_after_stable_regressed'],
      1,
    );
  });

  test('auto capture waiting requires opt-in and stability diagnostics', () {
    final noRequest = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/auto-waiting-off.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/auto-waiting-off-ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: const ReceiptStitchResult.notNeeded([
        '/tmp/auto-waiting-off-ocr.jpg',
      ]),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/auto-waiting-off.jpg': {
          'captureReadinessCode': 'auto_capture_waiting_for_stability',
          'manualCaptureAllowed': true,
          'autoCaptureAllowed': false,
          'autoCaptureEnabled': false,
          'stableFrameCount': 1,
          'requiredStableFrames': 3,
        },
      },
    );
    final missingEvidence = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/auto-waiting-missing.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/auto-waiting-missing-ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: const ReceiptStitchResult.notNeeded([
        '/tmp/auto-waiting-missing-ocr.jpg',
      ]),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/auto-waiting-missing.jpg': {
          'captureReadinessCode': 'auto_capture_waiting_for_stability',
          'manualCaptureAllowed': true,
          'autoCaptureAllowed': false,
          'autoCaptureEnabled': true,
        },
      },
    );

    expect(
      noRequest.nativeCameraUiHealthOutcome,
      'auto_capture_waiting_without_request_regressed',
    );
    expect(
      noRequest
          .nativeCameraUiHealthCounts['auto_capture_waiting_without_request_regressed'],
      1,
    );
    expect(
      missingEvidence.nativeCameraUiHealthOutcome,
      'auto_capture_waiting_missing_stability_evidence',
    );
    expect(
      missingEvidence
          .nativeCameraUiHealthCounts['auto_capture_waiting_missing_stability_evidence'],
      1,
    );
  });
}
