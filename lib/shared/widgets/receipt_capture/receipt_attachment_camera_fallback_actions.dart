part of 'receipt_attachment_panel.dart';

extension _ReceiptAttachmentCameraFallbackActions
    on _SharedReceiptAttachmentPanelState {
  Future<void> _takePhoneCameraBackupPhoto() async {
    final picked = await ReceiptImagePicker.takeBackupReceiptPhotoSet();
    if (picked.isEmpty || !mounted) {
      await returnToReceiptImportOptions();
      return;
    }
    _notifyReceiptCaptureDiagnostic(
      stage: 'phone_camera_backup',
      reason: 'maintainiac_native_camera_unavailable',
      action: 'review_phone_camera_receipt_photo',
      extraMetadata: {
        'captureFlow': 'phone_camera_backup_receipt_photo',
        'primaryCaptureFlow': 'maintainiac_native_receipt_camera',
        'phoneCameraBackupRole': 'fallback_only',
        'backupCaptureAuthorizedBy': 'maintainiac_native_unavailable',
        'stockCameraUiAllowedAsPrimary': false,
        'phoneCameraBackupUserFacingLabel':
            'Phone camera backup; returns to Maintainiac review',
        'phoneCameraBackupUsed': true,
        'phoneCameraBackupPhotoCount': picked.paths.length,
      },
    );
    await reviewPickedPhotoPaths(
      picked.paths,
      initialCaptureDiagnosticsByPath: receiptBrainDiagnosticsByPath(
        picked.paths,
        captureRoute: 'phone_camera_backup_receipt_photo',
        extra: const {
          'captureFlow': 'phone_camera_backup_receipt_photo',
          'primaryCaptureFlow': 'maintainiac_native_receipt_camera',
          'phoneCameraBackupRole': 'fallback_only',
          'backupCaptureAuthorizedBy': 'maintainiac_native_unavailable',
          'stockCameraUiAllowedAsPrimary': false,
          'phoneCameraBackupUserFacingLabel':
              'Phone camera backup; returns to Maintainiac review',
          'phoneCameraBackupUsed': true,
        },
      ),
    );
  }

  Future<void> _openReceiptBackupCaptureAfterNativeUnavailable(
    ReceiptCaptureSettingsController? settings,
  ) async {
    if (NativeReceiptScannerService.documentScannerAllowedOnThisPlatform) {
      final scanResult = await const NativeReceiptScannerService().scanReceipt(
        pageLimit:
            settings?.deviceCapability.maxLocalPhotoCount ??
            const ReceiptDeviceCapability.standard().maxLocalPhotoCount,
        allowGalleryImport: false,
      );
      if (scanResult.hasScannedPages) {
        await _reviewDocumentScannerBackup(scanResult.cameraResult!);
        return;
      }
      if (scanResult.status == ReceiptNativeScanStatus.canceled) {
        if (mounted) await returnToReceiptImportOptions();
        return;
      }
      _showScannerFallbackNotice(scanResult);
    }
    _notifyReceiptCaptureDiagnostic(
      stage: 'native_camera_unavailable',
      reason: 'maintainiac_camera_not_available',
      action: 'open_phone_camera_backup',
      extraMetadata: const {
        'backupCaptureAuthorizedBy': 'maintainiac_native_unavailable',
        'stockCameraUiAllowedAsPrimary': false,
      },
    );
    showPickerError(
      'Maintainiac receipt camera is not available. Opening the phone camera as backup capture; the photo still returns to Maintainiac receipt review.',
    );
    await _takePhoneCameraBackupPhoto();
  }

  Future<void> _reviewDocumentScannerBackup(
    ReceiptCameraResult cameraResult,
  ) async {
    _notifyReceiptCaptureDiagnostic(
      stage: 'document_scanner_backup',
      reason: 'maintainiac_native_camera_unavailable',
      action: 'review_document_scanner_receipt_photo',
      extraMetadata: {
        'captureFlow': 'document_scanner_backup_receipt_photo',
        'primaryCaptureFlow': 'maintainiac_native_receipt_camera',
        'documentScannerBackupRole': 'fallback_only',
        'phoneCameraBackupRole': 'fallback_only',
        'backupCaptureAuthorizedBy': 'maintainiac_native_unavailable',
        'stockCameraUiAllowedAsPrimary': false,
        'documentScannerBackupUsed': true,
        'documentScannerBackupPhotoCount': cameraResult.photoPaths.length,
      },
    );
    await reviewPickedPhotoPaths(
      cameraResult.photoPaths,
      initialQualityChecksByPath: qualityChecksByPathForCameraResult(
        cameraResult,
      ),
      initialCaptureDiagnosticsByPath: receiptBrainDiagnosticsByPath(
        cameraResult.photoPaths,
        captureRoute: 'document_scanner_backup_receipt_photo',
        extra: const {
          'captureFlow': 'document_scanner_backup_receipt_photo',
          'primaryCaptureFlow': 'maintainiac_native_receipt_camera',
          'documentScannerBackupRole': 'fallback_only',
          'phoneCameraBackupRole': 'fallback_only',
          'backupCaptureAuthorizedBy': 'maintainiac_native_unavailable',
          'stockCameraUiAllowedAsPrimary': false,
          'documentScannerBackupUsed': true,
        },
      ),
    );
  }

  void _showScannerFallbackNotice(ReceiptNativeScanResult result) {
    if (!mounted || result.status == ReceiptNativeScanStatus.scanned) return;
    final detail = result.message.trim();
    final message = detail.isEmpty
        ? 'Document scanner was not available. Maintainiac will use your phone camera as a fallback if needed.'
        : '$detail Maintainiac will use your phone camera as a fallback if needed.';
    showPickerError(message);
  }

  Map<String, Map<String, Object?>> receiptBrainDiagnosticsByPath(
    Iterable<String> paths, {
    required String captureRoute,
    Map<String, Object?> extra = const {},
  }) {
    return {
      for (final path in paths)
        path: {
          ..._defaultReceiptBrainDiagnosticMetadata(captureRoute: captureRoute),
          ...extra,
        },
    };
  }

  Map<String, Object?> _defaultReceiptBrainDiagnosticMetadata({
    required String captureRoute,
  }) {
    final deviceCapability =
        ReceiptCaptureSettingsScope.maybeOf(context)?.deviceCapability ??
        const ReceiptDeviceCapability.standard();
    final storageClass = storageClassForDataSaverLevel(_dataSaverLevel);
    final cloudAssistPlan = deviceCapability.cloudAssistPlanFor(
      dataSaverLevel: _dataSaverLevel,
    );
    final receiptBrain = deviceCapability.receiptBrainRecommendationFor(
      storageClass,
      cloudAssistPlan: cloudAssistPlan,
    );
    final footprint = deviceCapability.receiptBrainFootprintSummaryFor(
      storageClass,
      cloudAssistPlan: cloudAssistPlan,
    );
    return {
      ...receiptBrain.toPrivacySafeDiagnostics(),
      ...footprint.toPrivacySafeDiagnostics(),
      'receiptBrainDiagnosticsSource':
          'receipt_attachment_import_default_local_policy',
      'receiptBrainCaptureRoute': captureRoute,
      'receiptBrainCloudAssistExplicitOnly':
          receiptBrain.requiresInternetForAssist,
      'receiptBrainBaseCaptureAvailableWithoutPack':
          receiptBrain.baseCaptureAlwaysAvailable &&
          footprint.baseCaptureWorksWithoutOptionalPacks,
      'receiptBrainOcrReadsBeforeSavedProof': true,
    };
  }
}
