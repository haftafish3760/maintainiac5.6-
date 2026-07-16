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
      await _takeSystemCameraReceiptPhoto();
    } on MissingPluginException {
      if (!mounted) return;
      _notifyReceiptCaptureDiagnostic(
        stage: 'system_camera_plugin',
        reason: 'system_camera_plugin_missing',
        action: 'use_receipt_photo_upload',
      );
      showPickerError(
        'The phone camera is not available in this build. Use Upload Photos or reinstall the app and try again.',
      );
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

  void _publishSharedReceiptCaptureDiagnostic(ReceiptCaptureFlowResult result) {
    if (result.diagnostics.isEmpty) return;
    _publishReceiptCaptureDiagnostic(result.diagnostics);
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

  Future<bool> _showFirstUseReceiptCameraIntro(
    ReceiptCaptureSettingsController settings,
  ) async {
    final action = await showModalBottomSheet<_ReceiptFirstUseCameraAction>(
      context: context,
      backgroundColor: widget.uiConfig.pageBackgroundColor,
      showDragHandle: true,
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
