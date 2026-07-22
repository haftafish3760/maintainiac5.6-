import 'receipt_capture_models.dart';
import 'receipt_capture_settings_store.dart';
import 'receipt_native_camera_contract.dart';

/// Applies the persisted, user-facing receipt camera preferences to every
/// native capture entry point. Keep this mapping centralized so an Add Photo
/// session cannot quietly behave differently from the first camera session.
ReceiptNativeCameraSettings receiptNativeCameraSettingsForCapture({
  required ReceiptCaptureSettingsController? settings,
  required bool assistedReceiptFill,
  required bool longReceiptMode,
  required bool autoCaptureEnabled,
  required ReceiptNativeReviewDepth reviewDepth,
  required ReceiptDataSaverLevel dataSaverLevel,
}) {
  final guidanceEnabled = settings?.cameraGuidanceEnabled ?? true;
  return ReceiptNativeCameraSettings(
    assistedReceiptFill: assistedReceiptFill,
    longReceiptMode: longReceiptMode,
    autoCaptureEnabled: autoCaptureEnabled,
    reviewDepth: reviewDepth,
    liveYuvAnalysisEnabled: guidanceEnabled,
    edgeDetectionEnabled: guidanceEnabled,
    edgeOverlayEnabled: guidanceEnabled,
    motionBlurWarningEnabled: guidanceEnabled,
    glareWarningEnabled: guidanceEnabled,
    dirtyLensWarningEnabled: guidanceEnabled,
    lowLightWarningEnabled: guidanceEnabled,
    shadowWarningEnabled: guidanceEnabled,
    tooFarTooCloseWarningEnabled: guidanceEnabled,
    receiptFullyVisibleWarningEnabled: guidanceEnabled,
    textTooSmallWarningEnabled: guidanceEnabled,
    previousSectionGhostGuideEnabled: settings?.cameraLongReceiptTips ?? true,
    receiptPhotoBackupEnabled: settings?.receiptPhotoBackupEnabled ?? false,
    askSavedProofSizeEachReceipt:
        settings?.askSavedProofSizeEachReceipt ?? false,
    dataSaverLevel: dataSaverLevel,
  );
}
