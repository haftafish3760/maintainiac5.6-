part of 'receipt_capture_flow.dart';

Future<ReceiptCaptureFlowResult> _resultFromNativePhotoReview({
  required ReceiptCaptureFlow flow,
  required ReceiptNativeCaptureStagingResult staged,
  required ReceiptPhotoReviewResult? reviewResult,
  required ReceiptNativeCameraCapabilities nativeCapabilities,
  required ReceiptCaptureFlowOptions options,
}) async {
  if (reviewResult == null) {
    await flow._staging.markRecoveryStage(
      staged.recoveryManifestPath,
      stage: 'review_closed',
      reason: 'user_closed_review_before_accept',
      action: 'keep_staged_receipt_for_recovery',
      extraMetadata: {
        'nativeRecoveryReviewClosed': true,
        'nativeRecoveryReviewedPhotoCount': staged.photoPaths.length,
      },
    );
    return ReceiptCaptureFlowResult.canceled(
      message: 'Receipt photo review was closed.',
      nativeCapabilities: nativeCapabilities,
      diagnostics: _diagnostics(
        stage: 'receipt_photo_review',
        reason: 'user_closed_review',
        action: 'keep_staged_receipt_for_recovery',
        nativeCapabilities: nativeCapabilities,
        options: options,
      ),
    );
  }

  if (reviewResult.keptForLater) {
    await flow._staging.markRecoveryStage(
      staged.recoveryManifestPath,
      stage: 'review_closed_kept_for_later',
      reason: 'user_kept_review_photos_before_receipt_details',
      action: 'resume_saved_receipt_photo_review',
      extraMetadata: {
        'nativeRecoveryReviewClosed': true,
        'nativeRecoveryOcrPending': true,
        'nativeRecoveryKeptPhotoCount': reviewResult.photoPaths.length,
        'nativeRecoveryKeptMultipleSections':
            reviewResult.photoPaths.length > 1,
        'receiptReviewExitAction': reviewResult.reviewExitAction,
      },
    );
    return ReceiptCaptureFlowResult.canceled(
      message:
          'Receipt photos were kept on this device. Resume the saved receipt review when you are ready.',
      nativeCapabilities: nativeCapabilities,
      diagnostics: _diagnostics(
        stage: 'receipt_photo_review',
        reason: 'review_closed_kept_for_later',
        action: 'resume_saved_receipt_photo_review',
        nativeCapabilities: nativeCapabilities,
        options: options,
        extraMetadata: {
          'nativeRecoveryLastStage': 'review_closed_kept_for_later',
          'nativeRecoveryLastReason':
              'user_kept_review_photos_before_receipt_details',
          'nativeRecoveryNextAction': 'resume_saved_receipt_photo_review',
          'nativeRecoveryReviewClosed': true,
          'nativeRecoveryOcrPending': true,
          'nativeRecoveryKeptPhotoCount': reviewResult.photoPaths.length,
          'nativeRecoveryKeptMultipleSections':
              reviewResult.photoPaths.length > 1,
          'receiptReviewExitAction': reviewResult.reviewExitAction,
          'receiptReviewKeptForLater': true,
          ..._receiptReaderHandoffDiagnosticsFor(reviewResult),
        },
      ),
    );
  }

  await flow._staging.markRecoveryStage(
    staged.recoveryManifestPath,
    stage: 'review_accepted',
    reason: 'receipt_photos_accepted_for_receipt_details',
    action: 'open_filled_review_or_save_proof',
    extraMetadata: {
      'nativeRecoveryReviewAccepted': true,
      'nativeRecoveryOcrPending': true,
      'nativeRecoveryReviewedPhotoCount': reviewResult.photoPaths.length,
      'nativeRecoveryOcrSourcePhotoCount':
          reviewResult.ocrSourcePhotoPaths.length,
    },
  );
  return ReceiptCaptureFlowResult.accepted(
    reviewResult: reviewResult,
    nativeCapabilities: nativeCapabilities,
    recoveryManifestPath: staged.recoveryManifestPath,
    diagnostics: _diagnostics(
      stage: 'receipt_photo_review',
      reason: 'review_accepted',
      action: 'open_filled_review_or_save_proof',
      nativeCapabilities: nativeCapabilities,
      options: options,
      extraMetadata: {
        'nativeRecoveryLastStage': 'review_accepted',
        'nativeRecoveryLastReason':
            'receipt_photos_accepted_for_receipt_details',
        'nativeRecoveryNextAction': 'open_filled_review_or_save_proof',
        'nativeRecoveryReviewAccepted': true,
        'nativeRecoveryOcrPending': true,
        'nativeRecoveryReviewedPhotoCount': reviewResult.photoPaths.length,
        'nativeRecoveryOcrSourcePhotoCount':
            reviewResult.ocrSourcePhotoPaths.length,
        'reviewedPhotoCount': reviewResult.photoPaths.length,
        'ocrSourcePhotoCount': reviewResult.ocrSourcePhotoPaths.length,
        'dataSaverLevel': reviewResult.dataSaverLevel.name,
        'stitchStatus': reviewResult.stitchResult.status.name,
        ..._receiptReaderHandoffDiagnosticsFor(reviewResult),
      },
    ),
  );
}
