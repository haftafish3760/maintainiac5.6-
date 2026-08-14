part of 'receipt_attachment_panel.dart';

extension _ReceiptAttachmentCameraActions
    on _SharedReceiptAttachmentPanelState {
  Future<ReceiptImportActionResult> takeReceiptPhoto({
    bool skipFirstUseReceiptAssistIntro = false,
  }) async {
    if (_openingPicker) {
      return const ReceiptImportActionResult.stayOnChooser();
    }
    updateAttachmentState(() => _openingPicker = true);
    try {
      final settings = ReceiptCaptureSettingsScope.maybeOf(context);
      if (!skipFirstUseReceiptAssistIntro &&
          settings != null &&
          !settings.hasReceiptAssistChoiceFor(widget.area)) {
        final ready = await _showFirstUseReceiptAssistIntro(settings);
        if (!mounted) return const ReceiptImportActionResult.stayOnChooser();
        if (!ready) {
          return const ReceiptImportActionResult.stayOnChooser();
        }
      }
      final nativeResult = await _takeMaintainiacNativeCameraPhoto(settings);
      if (nativeResult.outcome == _MaintainiacNativeCameraPhotoOutcome.added ||
          nativeResult.outcome ==
              _MaintainiacNativeCameraPhotoOutcome.reviewCompleted) {
        return nativeResult.sourceResult;
      }
      if (nativeResult.outcome ==
          _MaintainiacNativeCameraPhotoOutcome.canceled) {
        return const ReceiptImportActionResult.stayOnChooser();
      }
      return _openReceiptBackupCaptureAfterNativeUnavailable(settings);
    } on MissingPluginException {
      if (!mounted) return const ReceiptImportActionResult.stayOnChooser();
      _notifyReceiptCaptureDiagnostic(
        stage: 'native_camera_plugin',
        reason: 'native_camera_plugin_missing',
        action: 'open_phone_camera_backup',
      );
      _showScannerFallbackNotice(
        const ReceiptNativeScanResult.unavailable(
          'Document scanning is not available in this build.',
        ),
      );
      showPickerError(
        'Maintainiac receipt camera is not installed in this build. Opening the phone camera as backup capture; the photo still returns to Maintainiac receipt review.',
      );
      return _takePhoneCameraBackupPhoto();
    } on PlatformException catch (error) {
      if (!mounted) return const ReceiptImportActionResult.stayOnChooser();
      _notifyReceiptCaptureDiagnostic(
        stage: 'native_camera_platform',
        reason: _platformCameraFailureReason(error),
        action: 'retry_or_import_existing_photo',
      );
      showPickerError(_nativeCameraOpenErrorMessage(error));
      return const ReceiptImportActionResult.stayOnChooser();
    } catch (_) {
      if (!mounted) return const ReceiptImportActionResult.stayOnChooser();
      _notifyReceiptCaptureDiagnostic(
        stage: 'native_camera_unknown',
        reason: 'native_camera_unexpected_failure',
        action: 'retry_or_import_existing_photo',
      );
      showPickerError(
        'The receipt camera did not open. Try Capture Receipt Photo again, or choose an existing receipt image instead.',
      );
      return const ReceiptImportActionResult.stayOnChooser();
    } finally {
      if (mounted) updateAttachmentState(() => _openingPicker = false);
    }
  }

  Future<_MaintainiacNativeCameraPhotoResult> _takeMaintainiacNativeCameraPhoto(
    ReceiptCaptureSettingsController? settings,
  ) async {
    final continuationGuide =
        ReceiptCaptureContinuationGuide.fromPreviousPhotos(
          previousPhotoPaths: _photoPaths,
          reasonCode: _nextReceiptContinuationReasonCode(),
          guidance: _nextReceiptContinuationGuidance(),
        );
    final flowResult = await const ReceiptCaptureFlow().captureAndReview(
      context,
      options: continuationGuide.applyTo(
        ReceiptCaptureFlowOptions(
          module: _receiptCaptureFlowModuleFor(widget.area),
          initialPhotoPaths: _photoPaths,
          initialQualityChecksByPath: _photoQualityByPath,
          initialDataSaverLevel: _dataSaverLevel,
          uiConfig: widget.uiConfig,
          forceAssistedReceiptFill: settings?.appAssistedEnabledFor(
            widget.area,
          ),
          forceLongReceiptMode: _nextReceiptForceLongReceiptMode(),
          forceAutoCapture: _nextReceiptForceAutoCapture(settings),
          forceReviewDepth: _receiptNativeReviewDepthForCurrentCapture(),
        ),
      ),
    );
    if (!mounted) {
      return const _MaintainiacNativeCameraPhotoResult(
        _MaintainiacNativeCameraPhotoOutcome.canceled,
      );
    }
    _publishSharedReceiptCaptureDiagnostic(flowResult);
    switch (flowResult.status) {
      case ReceiptCaptureFlowStatus.accepted:
        final result = flowResult.reviewResult;
        if (result == null) {
          return const _MaintainiacNativeCameraPhotoResult(
            _MaintainiacNativeCameraPhotoOutcome.canceled,
          );
        }
        final accepted = await _completeReviewedPhotoResult(result);
        if (!accepted || !mounted) {
          return const _MaintainiacNativeCameraPhotoResult(
            _MaintainiacNativeCameraPhotoOutcome.canceled,
          );
        }
        await _retainNativeRecoveryUntilReceiptSave(flowResult);
        if (!mounted) {
          return const _MaintainiacNativeCameraPhotoResult(
            _MaintainiacNativeCameraPhotoOutcome.canceled,
          );
        }
        return _MaintainiacNativeCameraPhotoResult(
          _MaintainiacNativeCameraPhotoOutcome.added,
          sourceResult: ReceiptImportActionResult.reviewCompleted(result),
        );
      case ReceiptCaptureFlowStatus.reviewCompleted:
        final result = flowResult.reviewResult;
        if (result == null) {
          return const _MaintainiacNativeCameraPhotoResult(
            _MaintainiacNativeCameraPhotoOutcome.canceled,
          );
        }
        final completed = await _completeReviewedPhotoResult(result);
        if (!completed || !mounted) {
          return const _MaintainiacNativeCameraPhotoResult(
            _MaintainiacNativeCameraPhotoOutcome.canceled,
          );
        }
        if (result.keptForLater) {
          await _retainNativeRecoveryUntilReceiptSave(flowResult);
        }
        return _MaintainiacNativeCameraPhotoResult(
          _MaintainiacNativeCameraPhotoOutcome.reviewCompleted,
          sourceResult: ReceiptImportActionResult.reviewCompleted(result),
        );
      case ReceiptCaptureFlowStatus.canceled:
        if (flowResult.message.trim().isNotEmpty) {
          showPickerError(flowResult.message);
        }
        return const _MaintainiacNativeCameraPhotoResult(
          _MaintainiacNativeCameraPhotoOutcome.canceled,
        );
      case ReceiptCaptureFlowStatus.reviewUnavailable:
        _notifyReceiptCaptureDiagnostic(
          stage: 'receipt_photo_review',
          reason: 'review_screen_unavailable',
          action: 'retry_or_import_existing_photo',
          nativeCapabilities: flowResult.nativeCapabilities,
          extraMetadata: const {
            'userNextStep':
                'retry_receipt_photo_or_import_existing_receipt_image',
          },
        );
        showPickerError(
          'Receipt photo review did not open. Try Capture Receipt Photo again, or choose an existing receipt image instead.',
        );
        return const _MaintainiacNativeCameraPhotoResult(
          _MaintainiacNativeCameraPhotoOutcome.canceled,
        );
      case ReceiptCaptureFlowStatus.permissionDenied:
        if (flowResult.message.trim().isNotEmpty) {
          showPickerError(flowResult.message);
        }
        return const _MaintainiacNativeCameraPhotoResult(
          _MaintainiacNativeCameraPhotoOutcome.canceled,
        );
      case ReceiptCaptureFlowStatus.nativeUnavailable:
        if (flowResult.message.trim().isNotEmpty &&
            flowResult.nativeCapabilities?.available == true) {
          showPickerError(
            '${flowResult.message.trim()} Opening the phone camera as backup capture; the photo still returns to Maintainiac receipt review.',
          );
        }
        return const _MaintainiacNativeCameraPhotoResult(
          _MaintainiacNativeCameraPhotoOutcome.unavailable,
        );
      case ReceiptCaptureFlowStatus.stagingFailed:
        if (flowResult.message.trim().isNotEmpty) {
          showPickerError(flowResult.message);
        }
        return const _MaintainiacNativeCameraPhotoResult(
          _MaintainiacNativeCameraPhotoOutcome.canceled,
        );
    }
  }

  ReceiptNativeReviewDepth _receiptNativeReviewDepthForCurrentCapture() {
    // Every receipt opens the same comprehensive, editable review form.
    return ReceiptNativeReviewDepth.detailedLines;
  }

  String? _nextReceiptContinuationReasonCode() {
    if (_needsBottomReceiptSection) return 'missing_bottom_edge_and_totals';
    return widget.receiptContinuationReasonCode;
  }

  String? _nextReceiptContinuationGuidance() {
    if (_needsBottomReceiptSection) {
      return 'Add the bottom receipt section and repeat 3-5 readable lines in the top reference strip so subtotal, total, and final lines can be matched.';
    }
    return widget.receiptContinuationGuidance;
  }

  bool? _nextReceiptForceLongReceiptMode() {
    if (_needsBottomReceiptSection) return true;
    return null;
  }

  bool? _nextReceiptForceAutoCapture(
    ReceiptCaptureSettingsController? settings,
  ) {
    if (_needsBottomReceiptSection) return false;
    return settings?.cameraAutoCapture;
  }

  void _publishSharedReceiptCaptureDiagnostic(ReceiptCaptureFlowResult result) {
    if (result.diagnostics.isEmpty) return;
    _publishReceiptCaptureDiagnostic(result.diagnostics);
  }

  Future<void> _retainNativeRecoveryUntilReceiptSave(
    ReceiptCaptureFlowResult result,
  ) async {
    final review = result.reviewResult;
    if (review == null || review.photoPaths.isEmpty) return;
    final manifestPath = result.recoveryManifestPath.trim();
    if (manifestPath.isEmpty) return;
    widget.controller?._retainNativeRecoveryManifest(manifestPath);
    if (!result.accepted || review.ocrSourcePhotoPaths.isEmpty) return;
    await const ReceiptNativeCaptureStaging().markRecoveryStage(
      manifestPath,
      stage: 'receipt_save_pending',
      reason: 'accepted_original_retained_until_receipt_save',
      action: 'finalize_after_durable_receipt_save',
    );
  }

  ReceiptCaptureFlowModule _receiptCaptureFlowModuleFor(
    ReceiptCaptureArea area,
  ) {
    return switch (area) {
      ReceiptCaptureArea.expenses => ReceiptCaptureFlowModule.expenses,
      ReceiptCaptureArea.materialsInventory =>
        ReceiptCaptureFlowModule.materialsInventory,
      ReceiptCaptureArea.maintenanceRepair =>
        ReceiptCaptureFlowModule.maintenanceRepair,
    };
  }

  void _notifyReceiptCaptureDiagnostic({
    required String stage,
    required String reason,
    required String action,
    ReceiptNativeCameraCapabilities? nativeCapabilities,
    Map<String, Object?> extraMetadata = const {},
  }) {
    _publishReceiptCaptureDiagnostic({
      'captureFlow': 'maintainiac_native_receipt_camera',
      'nativeCaptureFailureStage': stage,
      'nativeCaptureFailureReason': reason,
      'nativeCaptureRecoveryAction': action,
      ..._defaultReceiptBrainDiagnosticMetadata(
        captureRoute: 'receipt_import_diagnostic',
      ),
      if (nativeCapabilities != null) ...{
        'nativeCameraEngine': nativeCapabilities.engine.name,
        'nativeCameraAvailable': nativeCapabilities.available,
        'nativeCameraPermissionGranted':
            nativeCapabilities.cameraPermissionGranted,
        'nativeCameraHasRearCamera': nativeCapabilities.hasRearCamera,
      },
      ...extraMetadata,
    });
  }

  Future<bool> _showFirstUseReceiptAssistIntro(
    ReceiptCaptureSettingsController settings,
  ) async {
    final action = await showModalBottomSheet<_ReceiptFirstUseCameraAction>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ReceiptFirstUseCameraIntroSheet(
        area: widget.area,
        uiConfig: widget.uiConfig,
      ),
    );
    if (!mounted || action == null) return false;
    await _applyFirstUseReceiptAssistChoice(settings, action);
    if (!mounted) return false;
    await settings.setReceiptAssistChoiceMadeFor(widget.area, true);
    return true;
  }

  Future<void> _applyFirstUseReceiptAssistChoice(
    ReceiptCaptureSettingsController settings,
    _ReceiptFirstUseCameraAction action,
  ) async {
    final useAssist = action == _ReceiptFirstUseCameraAction.useReceiptAssist;
    if (widget.area == ReceiptCaptureArea.expenses) {
      // Expense entry has a richer settings screen, but first use is one
      // question. Persist the same canonical preference now so that screen
      // never presents a second, conflicting setup wall.
      await settings.setExpenseReceiptAssistanceChoice(
        useAssist
            ? ExpenseReceiptAssistanceChoice.onDevice
            : ExpenseReceiptAssistanceChoice.manual,
      );
      return;
    }
    await settings.setAppAssistedFor(widget.area, useAssist);
  }

  String _nativeCameraOpenErrorMessage(PlatformException error) {
    final code = error.code.toLowerCase();
    final message = error.message?.trim();
    final combined = '$code ${message ?? ''}'.toLowerCase();
    if (combined.contains('permission') ||
        combined.contains('denied') ||
        combined.contains('restricted')) {
      return 'Camera permission is blocked. Open your phone settings, allow camera access for Maintainiac, then try Capture Receipt Photo again.';
    }
    if (combined.contains('cancel')) {
      return 'Camera was canceled. No receipt photo was added.';
    }
    if (message != null && message.isNotEmpty) {
      return '$message Try Capture Receipt Photo again, or choose an existing receipt image instead.';
    }
    return 'Maintainiac receipt camera could not open. Try Capture Receipt Photo again, or choose an existing receipt image instead.';
  }

  String _platformCameraFailureReason(PlatformException error) {
    final code = error.code.toLowerCase();
    final message = error.message?.toLowerCase() ?? '';
    final combined = '$code $message';
    if (combined.contains('permission')) return 'permission_denied';
    if (combined.contains('cancel')) return 'user_canceled_before_photo';
    if (combined.contains('camera')) return 'native_camera_platform_error';
    if (combined.contains('storage')) return 'native_camera_storage_error';
    return 'platform_exception';
  }
}
