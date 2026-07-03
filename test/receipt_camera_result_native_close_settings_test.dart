import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_flow.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  test('photo review result summarizes native camera close health', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/proof.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: const ReceiptStitchResult.notNeeded(['/tmp/ocr.jpg']),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/proof.jpg': {
          'visibleControlSet': 'back|settings|manual_shutter|status',
          'previewDominanceTarget': 'receipt_preview_75_80_percent',
          'closeAction': 'back_returned_captured_sections',
          'closeCapturedPhotoPolicy':
              'back_returns_captured_sections_before_cancel',
          'closeCapturedPhotoOutcome': 'back_returned_captured_sections',
          'closeRequestCount': 1,
          'closeDuringCaptureCount': 1,
          'closeReturnedSectionsCount': 1,
          'closeResultDelivered': true,
        },
      },
    );

    expect(
      result.nativeCameraUiHealthOutcome,
      'native_close_deferred_during_capture',
    );
    expect(
      result.nativeCameraUiHealthCounts['native_close_deferred_during_capture'],
      1,
    );
    expect(
      result
          .nativeCameraUiHealthCounts['native_close_returned_captured_sections'],
      1,
    );
    expect(
      result
          .nativeCameraUiHealthCounts['native_close_action_back_returned_captured_sections'],
      1,
    );
    expect(
      result
          .nativeCameraUiHealthCounts['native_close_policy_back_returns_captured_sections_before_cancel'],
      1,
    );
    expect(
      result.nativeCameraUiHealthCounts['native_close_request_recorded'],
      1,
    );
    expect(
      result.nativeCameraUiHealthCounts['native_close_result_delivered'],
      1,
    );
    expect(
      result.nativeCloseCapturedPhotoHealthOutcome,
      'back_returned_captured_sections',
    );
    expect(
      result.nativeCloseCapturedPhotoActionLabel,
      'Back returned captured receipt sections for review',
    );
    expect(result.nativeCloseCapturedPhotoOutcomeCounts, {
      'back_returned_captured_sections': 1,
    });
    expect(
      result.privacySafeOcrHandoffEvidenceLabel,
      contains('close=back_returned_captured_sections'),
    );
    expect(
      result.privacySafeReceiptReaderHandoffMetadata,
      containsPair(
        'nativeCloseCapturedPhotoHealthOutcome',
        'back_returned_captured_sections',
      ),
    );
    expect(
      result.privacySafeReceiptReaderHandoffMetadata,
      containsPair(
        'nativeCloseCapturedPhotoActionLabel',
        'Back returned captured receipt sections for review',
      ),
    );

    final attachments = ReceiptCaptureFlow.attachmentsFromReviewResult(
      result,
      ReceiptCaptureFlowModule.expenses,
    );
    expect(
      attachments.single.documentSignals,
      contains('native_camera_ui_native_close_deferred_during_capture'),
    );
    expect(
      attachments.single.documentSignals,
      contains(
        'native_camera_ui_native_close_policy_back_returns_captured_sections_before_cancel',
      ),
    );
    expect(
      attachments.single.documentSignals,
      contains('native_camera_ui_native_close_result_delivered'),
    );
    expect(
      attachments.single.riskFlags,
      contains('native_camera_ui_native_close_deferred_during_capture'),
    );
    expect(
      attachments.single.documentSignals,
      contains('native_close_captured_photo_back_returned_captured_sections'),
    );
    expect(
      attachments.single.riskFlags,
      isNot(
        contains('native_close_captured_photo_back_returned_captured_sections'),
      ),
    );
  });

  test('native close health ignores non-finite numeric counts', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/proof.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: const ReceiptStitchResult.notNeeded(['/tmp/ocr.jpg']),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/proof.jpg': {
          'closeAction': 'back_returned_captured_sections',
          'closeRequestCount': double.infinity,
          'closeDuringCaptureCount': double.nan,
          'closeRetryCount': double.negativeInfinity,
          'closeNoPhotoCancelCount': double.nan,
        },
      },
    );

    expect(
      result.nativeCameraUiHealthCounts,
      isNot(contains('native_close_request_recorded')),
    );
    expect(
      result.nativeCameraUiHealthCounts,
      isNot(contains('native_close_deferred_during_capture')),
    );
    expect(
      result.nativeCameraUiHealthCounts,
      isNot(contains('native_close_retry_after_result')),
    );
    expect(
      result.nativeCameraUiHealthCounts,
      isNot(contains('native_close_no_photo_cancel')),
    );
    expect(
      result.nativeCameraUiHealthCounts,
      containsPair('native_close_returned_captured_sections', 1),
    );
  });

  test('photo review result flags failed native close after capture', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/proof.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: const ReceiptStitchResult.notNeeded(['/tmp/ocr.jpg']),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/proof.jpg': {
          'visibleControlSet': 'back|settings|manual_shutter|status',
          'previewDominanceTarget': 'receipt_preview_75_80_percent',
          'closeCapturedPhotoOutcome': 'capture_failed_after_close',
          'closeCapturedPhotoPolicy':
              'back_returns_captured_sections_before_cancel',
        },
      },
    );

    expect(
      result.nativeCloseCapturedPhotoHealthOutcome,
      'capture_failed_after_close',
    );
    expect(result.nativeCloseCapturedPhotoOutcomeCounts, {
      'capture_failed_after_close': 1,
    });
    expect(
      result
          .nativeCameraUiHealthCounts['native_close_capture_failed_after_close'],
      1,
    );
    expect(
      result
          .nativeCameraUiHealthCounts['native_close_policy_back_returns_captured_sections_before_cancel'],
      1,
    );
    expect(
      result
          .receiptReaderHandoffCounts['native_close_captured_photo_capture_failed_after_close'],
      1,
    );
    expect(
      result.privacySafeOcrHandoffEvidenceLabel,
      contains('close=capture_failed_after_close'),
    );
    expect(
      result.privacySafeReceiptReaderHandoffMetadata,
      containsPair('nativeCloseCapturedPhotoOutcomeCounts', {
        'capture_failed_after_close': 1,
      }),
    );

    final attachments = ReceiptCaptureFlow.attachmentsFromReviewResult(
      result,
      ReceiptCaptureFlowModule.expenses,
    );
    expect(
      attachments.single.documentSignals,
      contains('native_close_captured_photo_capture_failed_after_close'),
    );
    expect(
      attachments.single.riskFlags,
      contains('native_close_captured_photo_capture_failed_after_close'),
    );
    expect(
      attachments.single.riskFlags,
      contains('native_camera_ui_native_close_capture_failed_after_close'),
    );
  });

  test('photo review result reports native receipt settings control health', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/proof.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: const ReceiptStitchResult.notNeeded(['/tmp/ocr.jpg']),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/proof.jpg': {
          'visibleControlSet': 'back|settings|manual_shutter|status',
          'nativeControlContractTags': ['back', 'settings', 'manual_shutter'],
          'backControlExpected': true,
          'backControlActual': 'ready',
          'previewDominanceTarget': 'receipt_preview_75_80_percent',
          'settingsControlExpected': true,
          'settingsControlActual': 'ready',
          'manualShutterAlwaysAvailable': true,
          'manualShutterControlActual': 'ready',
          'settingsButtonPlacement': 'top_bar_right',
          'settingsContractVersion': 'receipt_native_camera_settings_v1',
          'settingsOpenCount': 2,
          'nativeCaptureReviewTransitionPolicy':
              'captured_photos_must_open_review_then_receipt_details',
          'nativeCaptureReviewTransitionTarget':
              'receipt_photo_review_next_to_receipt_details',
          'nativeCaptureReviewDiscardPolicy':
              'never_discard_captured_photo_on_back',
        },
      },
    );

    expect(result.nativeCameraUiHealthOutcome, 'native_controls_ready');
    expect(result.nativeCameraUiHealthCounts['settings_control_visible'], 1);
    expect(result.nativeCameraUiHealthCounts['settings_contract_v1'], 1);
    expect(
      result
          .nativeCameraUiHealthCounts['native_capture_review_transition_ready'],
      greaterThanOrEqualTo(1),
    );
    expect(
      result
          .nativeCameraUiHealthCounts['native_capture_review_target_receipt_details'],
      greaterThanOrEqualTo(1),
    );
    expect(
      result
          .nativeCameraUiHealthCounts['native_capture_review_discard_protected'],
      greaterThanOrEqualTo(1),
    );
    expect(
      result.nativeCameraUiHealthCounts['settings_button_top_bar_right'],
      1,
    );
    expect(result.nativeCameraUiHealthCounts['settings_opened'], 1);

    final attachments = ReceiptCaptureFlow.attachmentsFromReviewResult(
      result,
      ReceiptCaptureFlowModule.expenses,
    );
    expect(
      attachments.single.documentSignals,
      contains('native_camera_ui_settings_control_visible'),
    );
    expect(
      attachments.single.documentSignals,
      contains('native_camera_ui_settings_contract_v1'),
    );
    expect(
      attachments.single.documentSignals,
      contains('native_camera_ui_settings_button_top_bar_right'),
    );
    expect(
      attachments.single.documentSignals,
      contains('native_camera_ui_settings_opened'),
    );
  });

  test('photo review result flags missing native receipt settings control', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/proof.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: const ReceiptStitchResult.notNeeded(['/tmp/ocr.jpg']),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/proof.jpg': {
          'visibleControlSet': 'back|manual_shutter|status',
          'previewDominanceTarget': 'receipt_preview_75_80_percent',
          'settingsControlExpected': true,
        },
      },
    );

    expect(result.nativeCameraUiHealthOutcome, 'settings_contract_missing');
    expect(result.nativeCameraUiHealthCounts['settings_control_missing'], 1);
    expect(result.nativeCameraUiHealthCounts['settings_contract_missing'], 1);
    expect(
      result.nativeCameraUiHealthCounts['settings_button_placement_missing'],
      1,
    );

    final attachments = ReceiptCaptureFlow.attachmentsFromReviewResult(
      result,
      ReceiptCaptureFlowModule.expenses,
    );
    expect(
      attachments.single.riskFlags,
      contains('native_camera_ui_settings_contract_missing'),
    );
    expect(
      attachments.single.riskFlags,
      contains('native_camera_ui_settings_control_missing'),
    );
  });
}
