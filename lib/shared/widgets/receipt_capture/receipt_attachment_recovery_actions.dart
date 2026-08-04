part of 'receipt_attachment_panel.dart';

extension _ReceiptAttachmentRecoveryActions
    on _SharedReceiptAttachmentPanelState {
  Future<void> _loadRecoverableNativeCaptures() async {
    if (_loadingRecoverableNativeCaptures) return;
    updateAttachmentState(() => _loadingRecoverableNativeCaptures = true);
    try {
      final records = await const ReceiptNativeCaptureStaging()
          .recoverableNativeCaptures();
      updateAttachmentState(() {
        _recoverableNativeCaptures = records;
        _loadingRecoverableNativeCaptures = false;
      });
    } catch (_) {
      updateAttachmentState(() {
        _recoverableNativeCaptures = const [];
        _loadingRecoverableNativeCaptures = false;
      });
    }
  }

  Future<void> _resumeRecoverableNativeCapture(
    ReceiptNativeCaptureRecoveryRecord record,
  ) async {
    if (_openingPicker) return;
    if (!updateAttachmentState(() => _openingPicker = true)) return;
    try {
      final previousPhotoIdByPath = {..._photoIdByPath};
      final result = await const ReceiptCaptureFlow().reviewRecoveredCapture(
        context,
        record,
        options: ReceiptCaptureFlowOptions(
          module: _receiptCaptureFlowModuleFor(widget.area),
          initialPhotoPaths: List.unmodifiable(_photoPaths),
          initialQualityChecksByPath: Map.unmodifiable(_photoQualityByPath),
          initialCaptureDiagnosticsByPath: Map.unmodifiable(
            _photoCaptureDiagnosticsByPath,
          ),
          initialDataSaverLevel: _dataSaverLevel,
          uiConfig: widget.uiConfig,
        ),
      );
      _publishSharedReceiptCaptureDiagnostic(result);
      switch (result.status) {
        case ReceiptCaptureFlowStatus.accepted:
          final reviewResult = result.reviewResult;
          if (reviewResult == null) return;
          final accepted = await _acceptReviewedPhotoResult(
            reviewResult,
            previousPhotoIdByPath: previousPhotoIdByPath,
          );
          if (accepted && result.recoveryManifestPath.trim().isNotEmpty) {
            await _retainAcceptedNativeRecoveryUntilReceiptSave(result);
          }
          break;
        case ReceiptCaptureFlowStatus.stagingFailed:
        case ReceiptCaptureFlowStatus.permissionDenied:
        case ReceiptCaptureFlowStatus.nativeUnavailable:
        case ReceiptCaptureFlowStatus.reviewUnavailable:
          if (result.status == ReceiptCaptureFlowStatus.reviewUnavailable) {
            _notifyReceiptCaptureDiagnostic(
              stage: 'receipt_photo_review',
              reason: 'recovered_review_screen_unavailable',
              action: 'resume_recovery_later_or_retake',
              nativeCapabilities: result.nativeCapabilities,
              extraMetadata: const {
                'nativeRecoveryOutcome': 'recovery_review_unavailable_kept',
                'nativeRecoveryUserNextStep': 'resume_recovery_later',
              },
            );
          }
          if (mounted && result.message.trim().isNotEmpty) {
            showPickerError(result.message);
          } else if (mounted &&
              result.status == ReceiptCaptureFlowStatus.reviewUnavailable) {
            showPickerError(
              'Recovered receipt photo review did not open. Resume these saved photos again, or retake the receipt photos.',
            );
          }
          break;
        case ReceiptCaptureFlowStatus.canceled:
          if (mounted && result.message.trim().isNotEmpty) {
            showPickerError(result.message);
          }
          break;
      }
    } finally {
      if (updateAttachmentState(() => _openingPicker = false)) {
        unawaited(_loadRecoverableNativeCaptures());
      }
    }
  }

  Future<void> _dismissRecoverableNativeCapture(
    ReceiptNativeCaptureRecoveryRecord record,
  ) async {
    await const ReceiptNativeCaptureStaging().discardRecoveryRecord(record);
    _notifyReceiptCaptureDiagnostic(
      stage: 'native_capture_recovery',
      reason: 'user_discarded_recovery',
      action: 'discarded_interrupted_receipt_photos',
      nativeCapabilities: ReceiptNativeCameraCapabilities(
        engine: record.engine,
        available: record.engine != ReceiptNativeCameraEngine.unavailable,
      ),
      extraMetadata: {
        'nativeRecoveryOutcome': 'recovery_discarded_by_user',
        'nativeRecoveryUserNextStep': 'discarded_no_receipt_details_handoff',
        'nativeRecoveryResumeOutcome': record.recoveryResumeOutcomeCode,
        'nativeRecoveryResumeOutcomeLabel': record.recoveryResumeOutcomeLabel,
        'nativeRecoveryDiscardedPhotoCount': record.recoveredPhotoCount,
        'nativeRecoveryDiscardedMultipleSections':
            record.hasMultipleReceiptSections,
        'nativeRecoveryFreshness': record.recoveryFreshnessBucket(),
        'nativeRecoveryStorageStatus': record.recoveryStorageStatus,
        'nativeRecoveryExistingPhotoCount': record.existingPhotoCount,
        'nativeRecoveryMissingPhotoCount': record.missingPhotoCount,
        'nativeRecoveryEvidence': record.privacySafeRecoveryEvidenceLabel,
      },
    );
    if (!mounted) return;
    unawaited(_loadRecoverableNativeCaptures());
  }
}
