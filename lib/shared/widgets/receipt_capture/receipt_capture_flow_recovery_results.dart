part of 'receipt_capture_flow.dart';

extension ReceiptCaptureFlowRecoveryResults on ReceiptCaptureFlow {
  ReceiptCaptureFlowResult _missingRecoveryPhotosResult(
    ReceiptNativeCaptureRecoveryRecord record,
    ReceiptNativeCameraCapabilities nativeCapabilities,
    ReceiptCaptureFlowOptions options,
  ) {
    return ReceiptCaptureFlowResult.failed(
      status: ReceiptCaptureFlowStatus.stagingFailed,
      message:
          'Those saved receipt photos are no longer on this device. Take the receipt photos again.',
      nativeCapabilities: nativeCapabilities,
      diagnostics: _diagnostics(
        stage: 'native_capture_recovery',
        reason: 'recovery_photos_missing',
        action: 'retake_receipt_photos',
        nativeCapabilities: nativeCapabilities,
        options: options,
        extraMetadata: {
          'nativeRecoveryOutcome': 'recovery_photos_missing',
          'nativeRecoveryUserNextStep': 'retake_receipt_photos',
          ..._nativeRecoveryMetadata(record),
        },
      ),
    );
  }

  ReceiptCaptureFlowResult _recoveryReviewNotOpenedResult(
    ReceiptNativeCaptureRecoveryRecord record,
    ReceiptNativeCameraCapabilities nativeCapabilities,
    ReceiptCaptureFlowOptions options,
  ) {
    return ReceiptCaptureFlowResult.canceled(
      message: 'Recovered receipt photo review was closed before it opened.',
      nativeCapabilities: nativeCapabilities,
      diagnostics: _diagnostics(
        stage: 'native_capture_recovery',
        reason: 'recovery_context_closed_before_review',
        action: 'keep_staged_receipt_for_recovery',
        nativeCapabilities: nativeCapabilities,
        options: options,
        extraMetadata: {
          'nativeRecoveryOutcome': 'recovery_review_not_opened',
          'nativeRecoveryUserNextStep': 'resume_recovery_later',
          ..._nativeRecoveryMetadata(record),
        },
      ),
    );
  }

  ReceiptCaptureFlowResult _recoveryReviewInterruptedResult(
    ReceiptNativeCaptureRecoveryRecord record,
    ReceiptNativeCameraCapabilities nativeCapabilities,
    ReceiptCaptureFlowOptions options,
  ) {
    return ReceiptCaptureFlowResult.canceled(
      message: 'Recovered receipt photo review was interrupted.',
      nativeCapabilities: nativeCapabilities,
      diagnostics: _diagnostics(
        stage: 'native_capture_recovery',
        reason: 'recovery_context_closed_after_review',
        action: 'keep_staged_receipt_for_recovery',
        nativeCapabilities: nativeCapabilities,
        options: options,
        extraMetadata: {
          'nativeRecoveryOutcome': 'recovery_review_interrupted_kept',
          'nativeRecoveryUserNextStep': 'resume_recovery_later',
          ..._nativeRecoveryMetadata(record),
        },
      ),
    );
  }

  ReceiptCaptureFlowResult _recoveryReviewClosedResult(
    ReceiptNativeCaptureRecoveryRecord record,
    ReceiptNativeCameraCapabilities nativeCapabilities,
    ReceiptCaptureFlowOptions options,
    int photoCount,
  ) {
    return ReceiptCaptureFlowResult.canceled(
      message: 'Recovered receipt photo review was closed.',
      nativeCapabilities: nativeCapabilities,
      diagnostics: _diagnostics(
        stage: 'native_capture_recovery',
        reason: 'recovery_review_closed',
        action: 'kept_recovery_for_later_resume',
        nativeCapabilities: nativeCapabilities,
        options: options,
        extraMetadata: {
          'nativeRecoveryOutcome': 'recovery_review_closed_kept',
          'nativeRecoveryUserNextStep': 'resume_recovery_later',
          'nativeRecoveryKeptPhotoCount': photoCount,
          'nativeRecoveryKeptMultipleSections': photoCount > 1,
          ..._nativeRecoveryMetadata(record),
        },
      ),
    );
  }

  ReceiptCaptureFlowResult _recoveryReviewKeptForLaterResult(
    ReceiptNativeCaptureRecoveryRecord record,
    ReceiptNativeCameraCapabilities nativeCapabilities,
    ReceiptCaptureFlowOptions options,
    ReceiptPhotoReviewResult reviewResult,
  ) {
    return ReceiptCaptureFlowResult.reviewCompleted(
      reviewResult: reviewResult,
      message:
          'Recovered receipt photos were kept on this device. Resume the saved review when you are ready.',
      nativeCapabilities: nativeCapabilities,
      recoveryManifestPath: record.manifestPath,
      diagnostics: _diagnostics(
        stage: 'native_capture_recovery',
        reason: 'recovery_review_closed_kept_for_later',
        action: 'resume_saved_receipt_photo_review',
        nativeCapabilities: nativeCapabilities,
        options: options,
        extraMetadata: {
          'nativeRecoveryOutcome': 'recovery_review_closed_kept_for_later',
          'nativeRecoveryUserNextStep': 'resume_recovery_later',
          'nativeRecoveryKeptPhotoCount': reviewResult.photoPaths.length,
          'nativeRecoveryKeptMultipleSections':
              reviewResult.photoPaths.length > 1,
          'receiptReviewExitAction': reviewResult.reviewExitAction,
          'receiptReviewKeptForLater': true,
          ..._nativeRecoveryMetadata(record),
          ..._receiptReaderHandoffDiagnosticsFor(reviewResult),
        },
      ),
    );
  }

  ReceiptCaptureFlowResult _recoveryReviewDiscardedResult(
    ReceiptNativeCaptureRecoveryRecord record,
    ReceiptNativeCameraCapabilities nativeCapabilities,
    ReceiptCaptureFlowOptions options,
    ReceiptPhotoReviewResult reviewResult,
  ) {
    return ReceiptCaptureFlowResult.reviewCompleted(
      reviewResult: reviewResult,
      message: 'Recovered receipt photos were discarded.',
      nativeCapabilities: nativeCapabilities,
      diagnostics: _diagnostics(
        stage: 'native_capture_recovery',
        reason: 'user_discarded_recovered_receipt_photos',
        action: 'discard_recovered_receipt_photos',
        nativeCapabilities: nativeCapabilities,
        options: options,
        extraMetadata: {
          'nativeRecoveryOutcome': 'recovery_review_discarded_by_user',
          'nativeRecoveryUserNextStep': 'return_to_receipt_entry',
          'receiptReviewExitAction': reviewResult.reviewExitAction,
          ..._nativeRecoveryMetadata(record),
        },
      ),
    );
  }

  ReceiptCaptureFlowResult _recoveryReviewAcceptedResult(
    ReceiptNativeCaptureRecoveryRecord record,
    ReceiptNativeCameraCapabilities nativeCapabilities,
    ReceiptCaptureFlowOptions options,
    ReceiptPhotoReviewResult reviewResult,
    int recoveredPhotoCount,
  ) {
    return ReceiptCaptureFlowResult.accepted(
      reviewResult: reviewResult,
      nativeCapabilities: nativeCapabilities,
      recoveryManifestPath: record.manifestPath,
      diagnostics: _diagnostics(
        stage: 'native_capture_recovery',
        reason: 'recovery_review_accepted',
        action: 'open_filled_review_or_save_proof',
        nativeCapabilities: nativeCapabilities,
        options: options,
        extraMetadata: {
          'nativeRecoveryOutcome':
              'recovery_review_accepted_for_receipt_details',
          'nativeRecoveryUserNextStep': 'open_filled_review_or_save_proof',
          'nativeRecoveryAcceptedPhotoCount': recoveredPhotoCount,
          'nativeRecoveryAcceptedMultipleSections': recoveredPhotoCount > 1,
          ..._nativeRecoveryMetadata(record),
          'reviewedPhotoCount': reviewResult.photoPaths.length,
          'ocrSourcePhotoCount': reviewResult.ocrSourcePhotoPaths.length,
          'dataSaverLevel': reviewResult.dataSaverLevel.name,
          'stitchStatus': reviewResult.stitchResult.status.name,
          ..._receiptReaderHandoffDiagnosticsFor(reviewResult),
        },
      ),
    );
  }
}
