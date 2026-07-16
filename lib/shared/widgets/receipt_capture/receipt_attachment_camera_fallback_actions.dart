part of 'receipt_attachment_panel.dart';

extension _ReceiptAttachmentCameraFallbackActions
    on _SharedReceiptAttachmentPanelState {
  /// Uses the phone's normal rear-camera experience, then returns to the
  /// Maintainiac review flow where sections can be ordered and stitched.
  Future<void> _takeSystemCameraReceiptPhoto() async {
    final picked = await ReceiptImagePicker.takeReceiptPhotoSet();
    if (picked.isEmpty || !mounted) {
      await returnToReceiptImportOptions();
      return;
    }
    await reviewPickedPhotoPaths(
      picked.paths,
      initialQualityChecksByPath: await qualityChecksForPhotoPaths(
        picked.paths,
      ),
      initialCaptureDiagnosticsByPath: receiptBrainDiagnosticsByPath(
        picked.paths,
        captureRoute: 'system_phone_camera_receipt_photo',
        extra: const {
          'captureFlow': 'system_phone_camera_receipt_photo',
          'systemPhoneCameraUsed': true,
          'systemPhoneCameraRole': 'primary_capture',
          'systemPhoneCameraUserFacingLabel':
              'Phone camera; returns to Maintainiac review',
        },
      ),
    );
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
