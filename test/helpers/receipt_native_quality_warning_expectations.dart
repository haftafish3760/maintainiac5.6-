import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void expectBridgedDimGlareCaptureWarnings() {
  final dimWarning = ReceiptNativeSavedPhotoReviewWarning.fromDiagnostics({
    'latestCapturedExposureMismatch': 'live_dim_capture_dim',
    'latestCapturedBrightnessBucket': 'dim',
    'latestCapturedAverageLuma': 88.0,
    'latestCapturedEdgeScore': 8.0,
  });
  final glareWarning = ReceiptNativeSavedPhotoReviewWarning.fromDiagnostics({
    'latestCapturedExposureMismatch': 'live_glare_capture_glare',
    'latestCapturedBrightnessBucket': 'too_bright',
    'latestCapturedAverageLuma': 248.0,
    'latestCapturedEdgeScore': 9.0,
  });

  expect(dimWarning.code, 'saved_photo_dimmer_than_preview');
  expect(dimWarning.causeCode, 'saved_photo_dim_or_live_to_saved_mismatch');
  expect(dimWarning.parserRiskCode, 'ocr_text_may_need_review');
  final parityWatchWarning =
      ReceiptNativeSavedPhotoReviewWarning.fromDiagnostics({
        'latestCapturedPreviewParitySignal':
            'saved_photo_darker_than_preview_watch',
        'latestCapturedAverageLuma': 118.0,
        'latestCapturedEdgeScore': 10.0,
      });
  expect(parityWatchWarning.code, 'saved_photo_dimmer_than_preview');
  expect(
    parityWatchWarning.causeCode,
    'saved_photo_dim_or_live_to_saved_mismatch',
  );
  expect(parityWatchWarning.parserRiskCode, 'ocr_text_may_need_review');
  expect(glareWarning.code, 'saved_photo_glare_risk');
  expect(glareWarning.causeCode, 'saved_photo_glare_or_too_bright');
  expect(glareWarning.parserRiskCode, 'ocr_washed_out_text_may_fail');
  final hazyWarning = ReceiptNativeSavedPhotoReviewWarning.fromDiagnostics({
    'latestReadabilitySignal': 'dirty_lens_or_haze',
    'latestCapturedEdgeScore': 7.0,
  });
  expect(hazyWarning.code, 'saved_photo_dirty_lens_or_haze');
  expect(hazyWarning.causeCode, 'dirty_lens_or_hazy_live_preview');
  expect(hazyWarning.actionCode, 'wipe_lens_or_retake');
  expect(hazyWarning.parserRiskCode, 'ocr_hazy_text_may_fail');

  final brighterWarning = ReceiptNativeSavedPhotoReviewWarning.fromDiagnostics({
    'latestCapturedPreviewParitySignal':
        'saved_photo_brighter_than_preview_review_needed',
    'latestCapturedAverageLuma': 252.0,
    'latestCapturedEdgeScore': 8.0,
  });
  expect(brighterWarning.code, 'saved_photo_brighter_than_preview');
  expect(brighterWarning.causeCode, 'saved_photo_brighter_than_live_preview');
  expect(brighterWarning.actionCode, 'reduce_brightness_or_glare');
  expect(brighterWarning.parserRiskCode, 'ocr_washed_out_text_may_fail');

  final phoneBackupWarning =
      ReceiptNativeSavedPhotoReviewWarning.fromDiagnostics({
        'captureFlow': 'phone_camera_backup_receipt_photo',
        'phoneCameraBackupUsed': true,
      });
  expect(phoneBackupWarning.code, 'saved_photo_phone_camera_backup');
  expect(phoneBackupWarning.causeCode, 'phone_camera_backup_capture');
  expect(phoneBackupWarning.actionCode, 'review_phone_backup_focus');
  expect(
    phoneBackupWarning.parserRiskCode,
    'ocr_phone_backup_focus_may_need_review',
  );

  final documentScannerBackupWarning =
      ReceiptNativeSavedPhotoReviewWarning.fromDiagnostics({
        'captureFlow': 'document_scanner_backup_receipt_photo',
        'documentScannerBackupUsed': true,
      });
  expect(
    documentScannerBackupWarning.code,
    'saved_photo_document_scanner_backup',
  );
  expect(
    documentScannerBackupWarning.causeCode,
    'document_scanner_backup_capture',
  );
  expect(documentScannerBackupWarning.actionCode, 'review_backup_scan_crop');
  expect(
    documentScannerBackupWarning.parserRiskCode,
    'ocr_backup_scan_crop_may_need_review',
  );
}
