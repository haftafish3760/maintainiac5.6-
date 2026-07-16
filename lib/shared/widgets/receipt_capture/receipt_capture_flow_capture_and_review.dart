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

  const nativeCapabilities = ReceiptNativeCameraCapabilities(
    engine: ReceiptNativeCameraEngine.systemCamera,
    available: true,
    cameraPermissionGranted: true,
    cameraCount: 1,
    hasRearCamera: true,
  );
  final cameraSettings = _cameraSettingsFor(settings, options);
  ReceiptNativeCaptureResult capture;
  try {
    final picked = await ReceiptImagePicker.takeReceiptPhotoSet();
    if (picked.isEmpty) {
      return ReceiptCaptureFlowResult.canceled(
        message:
            'No receipt photo was added. Open Phone Camera again, or choose an existing receipt image.',
        nativeCapabilities: nativeCapabilities,
        diagnostics: _diagnostics(
          stage: 'system_camera_close',
          reason: 'user_canceled_before_photo',
          action: 'retry_or_import_existing_photo',
          nativeCapabilities: nativeCapabilities,
          options: options,
        ),
      );
    }
    capture = ReceiptNativeCaptureResult(
      engine: ReceiptNativeCameraEngine.systemCamera,
      originalPhotoPaths: picked.paths,
      temporaryCaptureIds: _systemCameraCaptureIds(picked.paths.length),
      capturedAt: DateTime.now(),
      captureDiagnostics: {
        'captureFlow': 'system_phone_camera_receipt_photo',
        'systemPhoneCameraUsed': true,
        'systemPhoneCameraRole': 'primary_capture',
        'systemPhoneCameraReturnsToReceiptReview': true,
        ..._previousSectionGuideDiagnostics(options),
      },
    );
  } catch (_) {
    return ReceiptCaptureFlowResult.failed(
      status: ReceiptCaptureFlowStatus.nativeUnavailable,
      message:
          'Phone Camera did not open. Try Capture Receipt Photo again, or choose an existing receipt image.',
      nativeCapabilities: nativeCapabilities,
      diagnostics: _diagnostics(
        stage: 'system_camera_open',
        reason: 'system_camera_unavailable',
        action: 'retry_or_import_existing_photo',
        nativeCapabilities: nativeCapabilities,
        options: options,
      ),
    );
  }

  if (!context.mounted) return ReceiptCaptureFlowResult.canceled();
  if (!capture.hasPhotos) {
    return ReceiptCaptureFlowResult.failed(
      status: ReceiptCaptureFlowStatus.nativeUnavailable,
      message:
          'Phone Camera did not return a photo. Try Capture Receipt Photo again, or choose an existing receipt image.',
      nativeCapabilities: nativeCapabilities,
      diagnostics: _diagnostics(
        stage: 'system_camera_result',
        reason: 'system_camera_returned_no_photos',
        action: 'retry_or_import_existing_photo',
        nativeCapabilities: nativeCapabilities,
        options: options,
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
    route: 'system_camera_to_photo_review',
    source: 'fresh_system_phone_camera',
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
            assistedReceiptFill: cameraSettings.assistedReceiptFill,
            uiConfig:
                options.uiConfig?.review ?? const ReceiptPhotoReviewUiConfig(),
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

List<String> _systemCameraCaptureIds(int count) {
  final timestamp = DateTime.now().microsecondsSinceEpoch;
  return List<String>.generate(
    count,
    (index) => 'system-camera-$timestamp-$index',
    growable: false,
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
