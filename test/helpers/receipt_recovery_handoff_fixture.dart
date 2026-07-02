import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

ReceiptPhotoReviewResult buildNativeRecoveryReviewResult() {
  return ReceiptPhotoReviewResult(
    photoPaths: const ['/tmp/recovered-top.jpg', '/tmp/recovered-bottom.jpg'],
    ocrSourcePhotoPaths: const ['/tmp/recovered-ocr.jpg'],
    dataSaverLevel: ReceiptDataSaverLevel.strong,
    stitchResult: const ReceiptStitchResult(
      status: ReceiptStitchStatus.stitched,
      inputPaths: ['/tmp/recovered-top.jpg', '/tmp/recovered-bottom.jpg'],
      ocrSourcePaths: ['/tmp/recovered-ocr.jpg'],
      stitchedPath: '/tmp/recovered-ocr.jpg',
      confidence: .82,
    ),
    captureDiagnosticsByPhotoPath: const {
      '/tmp/recovered-top.jpg': {
        'nativeRecoveryResumeStatus': 'resume_review_started',
        'nativeRecoveryRecoveredPhotoCount': 2,
        'nativeRecoveryMultipleSections': true,
        'nativeRecoveryFreshness': 'stale',
        'nativeRecoveryStorageStatus': 'partial_photos_available',
        'nativeCaptureMemoryPolicy':
            'small_local_proof_original_for_ocr_then_cleanup',
        'storageConstrained': true,
        'cameraWorkloadTier': 'light',
        'reviewDepth': 'detailedLines',
        'nativeReceiptCameraSurfaceActual': 'maintainiac_native_android',
        'nativeReceiptCameraSurfaceVerification':
            'maintainiac_custom_surface_verified',
        'nativeCameraIdentity': 'maintainiac_in_app_receipt_camera',
        'userEditedPhoto': true,
        'photoEditAction': 'manual_crop',
        'photoEditReplacedOriginal': true,
        'receiptBrainRequiredBaseReleaseActionCode':
            'ship_lean_base_and_defer_optional_receipt_packs',
        'receiptBrainInstallDistributionModeCode':
            'base_app_only_optional_cloud_assist',
        'receiptBrainStorageClass': 'critical',
        'receiptBrainLocalOcrMode': 'lean_local_ocr',
      },
      '/tmp/recovered-bottom.jpg': {
        'nativeRecoveryResumeStatus': 'resume_review_started',
        'nativeRecoveryRecoveredPhotoCount': 2,
        'nativeRecoveryMultipleSections': true,
        'nativeRecoveryFreshness': 'stale',
        'nativeRecoveryStorageStatus': 'partial_photos_available',
        'nativeCaptureMemoryPolicy':
            'small_local_proof_original_for_ocr_then_cleanup',
        'storageConstrained': true,
        'cameraWorkloadTier': 'light',
        'nativeReceiptCameraSurfaceActual': 'maintainiac_native_android',
        'nativeReceiptCameraSurfaceVerification':
            'maintainiac_custom_surface_verified',
        'nativeCameraIdentity': 'maintainiac_in_app_receipt_camera',
        'receiptBrainRequiredBaseReleaseActionCode':
            'ship_lean_base_and_defer_optional_receipt_packs',
        'receiptBrainInstallDistributionModeCode':
            'base_app_only_optional_cloud_assist',
        'receiptBrainStorageClass': 'critical',
        'receiptBrainLocalOcrMode': 'lean_local_ocr',
      },
    },
  );
}
