part of 'receipt_attachment_panel.dart';

extension _ReceiptAttachmentCameraActions
    on _SharedReceiptAttachmentPanelState {
  Future<void> takeReceiptPhoto() async {
    if (_openingPicker) return;
    updateAttachmentState(() => _openingPicker = true);
    try {
      final settings = ReceiptCaptureSettingsScope.maybeOf(context);
      if (settings != null &&
          !settings.hasReceiptAssistChoiceFor(widget.area)) {
        final ready = await _showFirstUseReceiptCameraIntro(settings);
        if (!mounted) return;
        if (!ready) {
          await returnToReceiptImportOptions();
          return;
        }
      }
      final nativeOutcome = await _takeMaintainiacNativeCameraPhoto(settings);
      if (nativeOutcome == _MaintainiacNativeCameraPhotoOutcome.added) return;
      if (nativeOutcome == _MaintainiacNativeCameraPhotoOutcome.canceled) {
        await returnToReceiptImportOptions();
        return;
      }
      await _openReceiptBackupCaptureAfterNativeUnavailable(settings);
    } on MissingPluginException {
      if (!mounted) return;
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
      await _takePhoneCameraBackupPhoto();
    } on PlatformException catch (error) {
      if (!mounted) return;
      _notifyReceiptCaptureDiagnostic(
        stage: 'native_camera_platform',
        reason: _platformCameraFailureReason(error),
        action: 'retry_or_import_existing_photo',
      );
      showPickerError(_nativeCameraOpenErrorMessage(error));
    } catch (_) {
      if (!mounted) return;
      _notifyReceiptCaptureDiagnostic(
        stage: 'native_camera_unknown',
        reason: 'native_camera_unexpected_failure',
        action: 'retry_or_import_existing_photo',
      );
      showPickerError(
        'The receipt camera did not open. Try Capture Receipt Photo again, or choose an existing receipt image instead.',
      );
    } finally {
      if (mounted) updateAttachmentState(() => _openingPicker = false);
    }
  }

  Future<_MaintainiacNativeCameraPhotoOutcome>
  _takeMaintainiacNativeCameraPhoto(
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
          forceLongReceiptMode: _nextReceiptForceLongReceiptMode(settings),
          forceAutoCapture: _nextReceiptForceAutoCapture(settings),
          forceReviewDepth: _receiptNativeReviewDepthForCurrentCapture(),
        ),
      ),
    );
    if (!mounted) return _MaintainiacNativeCameraPhotoOutcome.canceled;
    _publishSharedReceiptCaptureDiagnostic(flowResult);
    switch (flowResult.status) {
      case ReceiptCaptureFlowStatus.accepted:
        final result = flowResult.reviewResult;
        if (result == null) {
          return _MaintainiacNativeCameraPhotoOutcome.canceled;
        }
        final accepted = await _acceptReviewedPhotoResult(result);
        if (!accepted || !mounted) {
          return _MaintainiacNativeCameraPhotoOutcome.canceled;
        }
        await _clearAcceptedNativeRecovery(flowResult);
        if (!mounted) return _MaintainiacNativeCameraPhotoOutcome.canceled;
        return _MaintainiacNativeCameraPhotoOutcome.added;
      case ReceiptCaptureFlowStatus.canceled:
        if (flowResult.message.trim().isNotEmpty) {
          showPickerError(flowResult.message);
        }
        return _MaintainiacNativeCameraPhotoOutcome.canceled;
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
        return _MaintainiacNativeCameraPhotoOutcome.canceled;
      case ReceiptCaptureFlowStatus.permissionDenied:
        if (flowResult.message.trim().isNotEmpty) {
          showPickerError(flowResult.message);
        }
        return _MaintainiacNativeCameraPhotoOutcome.canceled;
      case ReceiptCaptureFlowStatus.nativeUnavailable:
        if (flowResult.message.trim().isNotEmpty &&
            flowResult.nativeCapabilities?.available == true) {
          showPickerError(
            '${flowResult.message.trim()} Opening the phone camera as backup capture; the photo still returns to Maintainiac receipt review.',
          );
        }
        return _MaintainiacNativeCameraPhotoOutcome.unavailable;
      case ReceiptCaptureFlowStatus.stagingFailed:
        if (flowResult.message.trim().isNotEmpty) {
          showPickerError(flowResult.message);
        }
        return _MaintainiacNativeCameraPhotoOutcome.canceled;
    }
  }

  ReceiptNativeReviewDepth _receiptNativeReviewDepthForCurrentCapture() {
    if (widget.area == ReceiptCaptureArea.expenses) {
      return _receiptNativeReviewDepthForExpenseStyle(
        ExpenseSettingsScope.maybeOf(context)?.receiptReviewStyle,
      );
    }
    return ReceiptNativeReviewDepth.detailedLines;
  }

  ReceiptNativeReviewDepth _receiptNativeReviewDepthForExpenseStyle(
    ExpenseReceiptReviewStyle? style,
  ) {
    return switch (style) {
      ExpenseReceiptReviewStyle.fullItemDetails =>
        ReceiptNativeReviewDepth.detailedLines,
      ExpenseReceiptReviewStyle.simpleAmounts ||
      null => ReceiptNativeReviewDepth.pricesOnly,
    };
  }

  String? _nextReceiptContinuationReasonCode() {
    if (_needsBottomReceiptSection) return 'missing_bottom_edge_and_totals';
    return widget.receiptContinuationReasonCode;
  }

  String? _nextReceiptContinuationGuidance() {
    if (_needsBottomReceiptSection) {
      return 'Add the bottom receipt section and repeat 3-5 readable lines in the top ghost slice so subtotal, total, and final lines can be matched.';
    }
    return widget.receiptContinuationGuidance;
  }

  bool? _nextReceiptForceLongReceiptMode(
    ReceiptCaptureSettingsController? settings,
  ) {
    if (_needsBottomReceiptSection) return true;
    return settings?.cameraLongReceiptTips;
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

  Future<void> _clearAcceptedNativeRecovery(
    ReceiptCaptureFlowResult result,
  ) async {
    if (!result.accepted || result.reviewResult == null) return;
    final review = result.reviewResult!;
    if (review.photoPaths.isEmpty || review.ocrSourcePhotoPaths.isEmpty) {
      return;
    }
    final manifestPath = result.recoveryManifestPath.trim();
    if (manifestPath.isEmpty) return;
    await const ReceiptNativeCaptureStaging().clearRecoveryManifestPath(
      manifestPath,
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

  Future<bool> _showFirstUseReceiptCameraIntro(
    ReceiptCaptureSettingsController settings,
  ) async {
    final action = await Navigator.of(context)
        .push<_ReceiptFirstUseCameraAction>(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => _ReceiptFirstUseCameraIntroSheet(
              area: widget.area,
              uiConfig: widget.uiConfig,
            ),
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
    if (useAssist) {
      await settings.setAppAssistedReceiptFill(true);
    }
    switch (widget.area) {
      case ReceiptCaptureArea.expenses:
        await settings.setAppAssistedExpenses(useAssist);
      case ReceiptCaptureArea.materialsInventory:
        await settings.setAppAssistedMaterials(useAssist);
      case ReceiptCaptureArea.maintenanceRepair:
        await settings.setAppAssistedMaintenance(useAssist);
    }
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
