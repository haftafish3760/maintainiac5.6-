part of 'receipt_capture_flow.dart';

extension ReceiptCaptureFlowRecovery on ReceiptCaptureFlow {
  Future<ReceiptCaptureFlowResult> reviewRecoveredCapture(
    BuildContext context,
    ReceiptNativeCaptureRecoveryRecord record, {
    ReceiptCaptureFlowOptions options = const ReceiptCaptureFlowOptions(),
  }) async {
    final nativeCapabilities = ReceiptNativeCameraCapabilities(
      engine: record.engine,
      available: record.engine != ReceiptNativeCameraEngine.unavailable,
    );
    final photoPaths = _existingUniqueRecoveryPhotoPaths(
      record.recoverablePhotoPaths,
    );
    if (photoPaths.isEmpty) {
      await _staging.discardRecoveryRecord(record);
      return _missingRecoveryPhotosResult(record, nativeCapabilities, options);
    }

    final initialPhotoPaths = _normalizedInitialReviewPhotoPaths(options);
    final reviewPhotoPaths = [...initialPhotoPaths, ...photoPaths];
    final firstRecoveredPhotoIndex = initialPhotoPaths.length;
    final recoveryDiagnostics = <String, Object?>{
      ...record.captureDiagnostics,
      'nativeRecoveryResumeStatus': 'resume_review_started',
      'nativeRecoveryResumeSource': 'saved_native_capture',
      'nativeRecoveryResumeRoute':
          'receipt_photo_review_before_receipt_details',
      'nativeRecoveryRecoveredPhotoCount': photoPaths.length,
      'nativeRecoveryOriginalPhotoCount': record.recoveredPhotoCount,
      'nativeRecoveryExistingPhotoCount': record.existingPhotoCount,
      'nativeRecoveryMissingPhotoCount': record.missingPhotoCount,
      'nativeRecoveryMultipleSections': photoPaths.length > 1,
      'nativeRecoveryFreshness': record.recoveryFreshnessBucket(),
      'nativeRecoveryStorageStatus': record.recoveryStorageStatus,
      'nativeRecoveryResumeReadiness': record.recoveryResumeOutcomeCode,
      'nativeRecoveryPartialResumeReviewRequired': record.missingPhotoCount > 0,
      'nativeRecoveryReviewOpened': true,
      'nativeRecoveryOcrPending': true,
    };
    if (!context.mounted) {
      return _recoveryReviewNotOpenedResult(
        record,
        nativeCapabilities,
        options,
      );
    }

    await _staging.markRecoveryStage(
      record.manifestPath,
      stage: 'recovery_review_opening',
      reason: 'saved_native_photos_ready_for_review',
      action: 'open_receipt_photo_review_before_receipt_details',
      extraMetadata: {
        'nativeRecoveryReviewOpened': true,
        'nativeRecoveryOcrPending': true,
        'nativeRecoveryResumeSource': 'saved_native_capture',
        'nativeRecoveryResumeRoute':
            'receipt_photo_review_before_receipt_details',
        'nativeRecoveryRecoveredPhotoCount': photoPaths.length,
        'nativeRecoveryOriginalPhotoCount': record.recoveredPhotoCount,
        'nativeRecoveryExistingPhotoCount': record.existingPhotoCount,
        'nativeRecoveryMissingPhotoCount': record.missingPhotoCount,
        'nativeRecoveryMultipleSections': photoPaths.length > 1,
        'nativeRecoveryResumeReadiness': record.recoveryResumeOutcomeCode,
        'nativeRecoveryPartialResumeReviewRequired':
            record.missingPhotoCount > 0,
      },
    );
    if (!context.mounted) {
      return _recoveryReviewNotOpenedResult(
        record,
        nativeCapabilities,
        options,
      );
    }
    final reviewOpeningDiagnostics = _withReviewOpeningDiagnostics(
      _recoveryDiagnosticsByPhotoPath(photoPaths, recoveryDiagnostics),
      route: 'native_recovery_to_photo_review',
      source: 'saved_native_capture_recovery',
      photoCount: photoPaths.length,
      options: options,
    );
    final reviewResult = await Navigator.of(context)
        .push<ReceiptPhotoReviewResult>(
          appNativeRoute(
            context,
            ReceiptPhotoReviewScreen(
              initialPhotoPaths: reviewPhotoPaths,
              initialSelectedIndex: firstRecoveredPhotoIndex,
              initialDataSaverLevel:
                  options.initialDataSaverLevel ?? record.dataSaverLevel,
              initialQualityChecksByPath: {
                ...options.initialQualityChecksByPath,
              },
              initialCaptureDiagnosticsByPath: {
                ...options.initialCaptureDiagnosticsByPath,
                ...reviewOpeningDiagnostics,
              },
            ),
          ),
        );
    if (!context.mounted) {
      await _staging.markRecoveryStage(
        record.manifestPath,
        stage: 'recovery_review_interrupted',
        reason: 'context_closed_after_recovery_review',
        action: 'keep_staged_receipt_for_recovery',
        extraMetadata: {
          'nativeRecoveryReviewClosed': true,
          'nativeRecoveryOcrPending': true,
          'nativeRecoveryKeptPhotoCount': photoPaths.length,
          'nativeRecoveryKeptMultipleSections': photoPaths.length > 1,
        },
      );
      return _recoveryReviewInterruptedResult(
        record,
        nativeCapabilities,
        options,
      );
    }
    if (reviewResult == null) {
      await _staging.markRecoveryStage(
        record.manifestPath,
        stage: 'recovery_review_closed',
        reason: 'user_closed_recovered_review_before_accept',
        action: 'keep_staged_receipt_for_recovery',
        extraMetadata: {
          'nativeRecoveryReviewClosed': true,
          'nativeRecoveryOcrPending': true,
          'nativeRecoveryKeptPhotoCount': photoPaths.length,
          'nativeRecoveryKeptMultipleSections': photoPaths.length > 1,
        },
      );
      return _recoveryReviewClosedResult(
        record,
        nativeCapabilities,
        options,
        photoPaths.length,
      );
    }
    if (reviewResult.keptForLater) {
      await _staging.markRecoveryStage(
        record.manifestPath,
        stage: 'recovery_review_closed_kept_for_later',
        reason: 'user_kept_recovered_review_before_receipt_details',
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
      return _recoveryReviewKeptForLaterResult(
        record,
        nativeCapabilities,
        options,
        reviewResult,
      );
    }

    await _staging.markRecoveryStage(
      record.manifestPath,
      stage: 'recovery_review_accepted',
      reason: 'recovered_receipt_photos_accepted_for_receipt_details',
      action: 'open_filled_review_or_save_proof',
      extraMetadata: {
        'nativeRecoveryReviewAccepted': true,
        'nativeRecoveryOcrPending': true,
        'nativeRecoveryAcceptedPhotoCount': reviewResult.photoPaths.length,
        'nativeRecoveryAcceptedMultipleSections':
            reviewResult.photoPaths.length > 1,
        'nativeRecoveryOcrSourcePhotoCount':
            reviewResult.ocrSourcePhotoPaths.length,
      },
    );
    return _recoveryReviewAcceptedResult(
      record,
      nativeCapabilities,
      options,
      reviewResult,
      photoPaths.length,
    );
  }

  Map<String, Object?> _nativeRecoveryMetadata(
    ReceiptNativeCaptureRecoveryRecord record,
  ) {
    return {
      'nativeRecoveryFreshness': record.recoveryFreshnessBucket(),
      'nativeRecoveryStorageStatus': record.recoveryStorageStatus,
      'nativeRecoveryResumeOutcome': record.recoveryResumeOutcomeCode,
      'nativeRecoveryResumeOutcomeLabel': record.recoveryResumeOutcomeLabel,
      'nativeRecoveryExistingPhotoCount': record.existingPhotoCount,
      'nativeRecoveryMissingPhotoCount': record.missingPhotoCount,
      'nativeRecoveryEvidence': record.privacySafeRecoveryEvidenceLabel,
    };
  }
}

List<String> _existingUniqueRecoveryPhotoPaths(List<String> paths) {
  final unique = <String>[];
  final seen = <String>{};
  for (final rawPath in paths) {
    final path = rawPath.trim();
    if (path.isEmpty || !seen.add(path)) continue;
    if (File(path).existsSync()) unique.add(path);
  }
  return List<String>.unmodifiable(unique);
}

Map<String, Map<String, Object?>> _recoveryDiagnosticsByPhotoPath(
  List<String> photoPaths,
  Map<String, Object?> recoveryDiagnostics,
) {
  return Map<String, Map<String, Object?>>.unmodifiable({
    for (final path in photoPaths)
      path: Map<String, Object?>.unmodifiable(recoveryDiagnostics),
  });
}
