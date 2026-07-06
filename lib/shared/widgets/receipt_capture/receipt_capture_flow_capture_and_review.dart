part of 'receipt_capture_flow.dart';

Future<ReceiptCaptureFlowResult> _captureAndReview(
  ReceiptCaptureFlow flow,
  BuildContext context, {
  required ReceiptCaptureFlowOptions options,
}) async {
  final settings = ReceiptCaptureSettingsScope.maybeOf(context);
  final permission = await const ReceiptCameraPermission().ensureReady();
  if (!context.mounted) return ReceiptCaptureFlowResult.canceled();
  if (!permission.canUseCamera) {
    return ReceiptCaptureFlowResult.failed(
      status: ReceiptCaptureFlowStatus.permissionDenied,
      message: permission.userMessage,
      diagnostics: const {
        'captureFlow': 'maintainiac_shared_receipt_camera',
        'nativeCaptureFailureStage': 'camera_permission',
        'nativeCaptureFailureReason': 'permission_denied',
        'nativeCaptureRecoveryAction': 'grant_camera_permission',
      },
    );
  }

  final nativeCapabilities = await flow._nativeCameraService.readCapabilities();
  if (!context.mounted) return ReceiptCaptureFlowResult.canceled();
  if (!nativeCapabilities.canOpenReceiptCamera) {
    return ReceiptCaptureFlowResult.failed(
      status: ReceiptCaptureFlowStatus.nativeUnavailable,
      message: nativeCapabilities.userSafeSummary,
      nativeCapabilities: nativeCapabilities,
      diagnostics: _diagnostics(
        stage: 'native_camera_capabilities',
        reason: _nativeCapabilityFailureReason(nativeCapabilities),
        action: 'open_backup_receipt_photo_option',
        nativeCapabilities: nativeCapabilities,
        options: options,
      ),
    );
  }

  final deviceCapability =
      settings?.deviceCapability ?? const ReceiptDeviceCapability.standard();
  final cameraSettings = _cameraSettingsFor(settings, options);
  ReceiptNativeCaptureResult capture;
  try {
    capture = await flow._nativeCameraService.captureReceipt(
      cameraSettings.sessionFor(
        deviceCapability: deviceCapability,
        nativeCapabilities: nativeCapabilities,
        previousSectionGuidePhotoPath: options.previousSectionGuidePhotoPath,
        previousSectionReasonCode: options.previousSectionReasonCode,
        previousSectionGuidance: options.previousSectionGuidance,
        previousSectionGhostSourceStartFraction:
            options.previousSectionGhostSourceStartFraction,
        previousSectionGhostSourceHeightFraction:
            options.previousSectionGhostSourceHeightFraction,
        previousSectionGhostOverlayTopFraction:
            options.previousSectionGhostOverlayTopFraction,
        previousSectionGhostOverlayHeightFraction:
            options.previousSectionGhostOverlayHeightFraction,
        previousSectionGhostOpacity: options.previousSectionGhostOpacity,
      ),
    );
  } on ReceiptNativeCameraCanceledException catch (error) {
    return ReceiptCaptureFlowResult.canceled(
      message:
          'No receipt photo was added. Tap Capture Receipt Photo again, or choose an existing receipt image.',
      nativeCapabilities: nativeCapabilities,
      diagnostics: _diagnostics(
        stage: 'native_camera_close',
        reason: 'user_canceled_before_photo',
        action: 'retry_or_import_existing_photo',
        nativeCapabilities: nativeCapabilities,
        options: options,
        extraMetadata: {
          'closeAction': error.closeAction,
          'nativeCaptureOutcome': 'user_canceled_without_photo',
          'nativeCaptureFallbackPolicy': 'offer_retry_or_import',
          'userNextStep':
              'retry_receipt_photo_or_import_existing_receipt_image',
        },
      ),
    );
  } on ReceiptNativeCameraUnavailableException catch (error) {
    return ReceiptCaptureFlowResult.failed(
      status: ReceiptCaptureFlowStatus.nativeUnavailable,
      message: error.message,
      nativeCapabilities: nativeCapabilities,
      diagnostics: _diagnostics(
        stage: 'native_camera_open',
        reason: 'native_camera_unavailable',
        action: 'open_backup_receipt_photo_option',
        nativeCapabilities: nativeCapabilities,
        options: options,
        extraMetadata: const {
          'nativeCaptureOutcome': 'native_camera_open_failed',
          'nativeCaptureFallbackPolicy': 'open_backup_or_import',
          'userNextStep': 'use_phone_camera_backup_or_import_existing_photo',
        },
      ),
    );
  }

  if (!context.mounted) return ReceiptCaptureFlowResult.canceled();
  if (!capture.hasPhotos) {
    return ReceiptCaptureFlowResult.failed(
      status: ReceiptCaptureFlowStatus.nativeUnavailable,
      message:
          'Maintainiac receipt camera did not return a photo. Try Capture Receipt Photo again, or choose an existing receipt image.',
      nativeCapabilities: nativeCapabilities,
      diagnostics: _diagnostics(
        stage: 'native_camera_result',
        reason: 'native_camera_returned_no_photos',
        action: 'retry_or_import_existing_photo',
        nativeCapabilities: nativeCapabilities,
        options: options,
        extraMetadata: {
          'nativeCaptureOutcome': 'native_camera_returned_no_photo',
          'nativeCaptureFallbackPolicy': 'offer_retry_or_import',
          'userNextStep':
              'retry_receipt_photo_or_import_existing_receipt_image',
        },
      ),
    );
  }

  ReceiptNativeCaptureStagingResult staged;
  try {
    final stagedDataSaverLevel = _stagedDataSaverLevelFor(
      capture,
      options: options,
      settings: settings,
    );
    staged = await flow._staging.stage(
      capture,
      dataSaverLevel: stagedDataSaverLevel,
    );
  } on ReceiptProofStorageException catch (error) {
    return ReceiptCaptureFlowResult.failed(
      status: ReceiptCaptureFlowStatus.stagingFailed,
      message: error.message,
      nativeCapabilities: nativeCapabilities,
      diagnostics: _diagnostics(
        stage: 'native_capture_staging',
        reason: 'proof_storage_failed',
        action: 'retry_receipt_camera_or_import_existing_photo',
        nativeCapabilities: nativeCapabilities,
        options: options,
      ),
    );
  }

  if (!context.mounted) {
    return ReceiptCaptureFlowResult.canceled(
      message: 'Receipt photo review was closed before the photo opened.',
      nativeCapabilities: nativeCapabilities,
      diagnostics: _diagnostics(
        stage: 'native_capture_staging',
        reason: 'review_context_closed_after_staging',
        action: 'keep_staged_receipt_for_recovery',
        nativeCapabilities: nativeCapabilities,
        options: options,
        extraMetadata: {
          'nativeRecoveryLastStage': 'review_closed',
          'nativeRecoveryLastReason': 'user_closed_review_before_accept',
          'nativeRecoveryNextAction': 'keep_staged_receipt_for_recovery',
          'nativeRecoveryReviewClosed': true,
          'nativeRecoveryReviewedPhotoCount': staged.photoPaths.length,
        },
      ),
    );
  }
  if (!staged.hasPhotos) {
    return ReceiptCaptureFlowResult.failed(
      status: ReceiptCaptureFlowStatus.stagingFailed,
      message: 'Maintainiac could not prepare the receipt photo for review.',
      nativeCapabilities: nativeCapabilities,
      diagnostics: _diagnostics(
        stage: 'native_capture_staging',
        reason: 'native_capture_staged_no_photos',
        action: 'retry_receipt_camera',
        nativeCapabilities: nativeCapabilities,
        options: options,
      ),
    );
  }

  await flow._staging.markRecoveryStage(
    staged.recoveryManifestPath,
    stage: 'review_opening',
    reason: 'staged_photos_ready_for_review',
    action: 'open_receipt_photo_review',
    extraMetadata: {
      'nativeRecoveryReviewOpened': true,
      'nativeRecoveryReviewedPhotoCount': staged.photoPaths.length,
    },
  );
  if (!context.mounted) return ReceiptCaptureFlowResult.canceled();
  final reviewOpeningDiagnostics = _withReviewOpeningDiagnostics(
    staged.captureDiagnosticsByPhotoPath,
    route: 'native_capture_to_photo_review',
    source: 'fresh_native_capture',
    photoCount: staged.photoPaths.length,
    options: options,
  );
  final initialPhotoPaths = _normalizedInitialReviewPhotoPaths(options);
  final reviewResult = await Navigator.of(context)
      .push<ReceiptPhotoReviewResult>(
        appNativeRoute(
          context,
          ReceiptPhotoReviewScreen(
            initialPhotoPaths: [...initialPhotoPaths, ...staged.photoPaths],
            initialSelectedIndex: _reviewInitialSelectedIndex(
              options: options,
              staged: staged,
            ),
            initialDataSaverLevel:
                options.initialDataSaverLevel ??
                settings?.defaultDataSaverLevel ??
                ReceiptDataSaverLevel.balanced,
            initialQualityChecksByPath: {...options.initialQualityChecksByPath},
            initialCaptureDiagnosticsByPath: {
              ...options.initialCaptureDiagnosticsByPath,
              ...reviewOpeningDiagnostics,
            },
          ),
        ),
      );
  if (!context.mounted) return ReceiptCaptureFlowResult.canceled();
  return _resultFromNativePhotoReview(
    flow: flow,
    staged: staged,
    reviewResult: reviewResult,
    nativeCapabilities: nativeCapabilities,
    options: options,
  );
}

int _reviewInitialSelectedIndex({
  required ReceiptCaptureFlowOptions options,
  required ReceiptNativeCaptureStagingResult staged,
}) {
  final initialPhotoCount = _normalizedInitialReviewPhotoPaths(options).length;
  final addedPhotoCount = staged.photoPaths.length;
  if (addedPhotoCount <= 0) return initialPhotoCount;
  final addedPhotoIndex = options.initialSelectedIndex
      .clamp(0, addedPhotoCount - 1)
      .toInt();
  return initialPhotoCount + addedPhotoIndex;
}

List<String> _normalizedInitialReviewPhotoPaths(
  ReceiptCaptureFlowOptions options,
) {
  return uniqueNormalizedReceiptPhotoPaths(options.initialPhotoPaths);
}
