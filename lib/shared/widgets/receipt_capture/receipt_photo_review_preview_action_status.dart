part of 'receipt_photo_review_screen.dart';

extension _ReceiptPreviewActionTrayStatus on _ReceiptPreviewActionTray {
  ReceiptPhotoCoverageDecision get coverageDecisionForSelectedPhoto {
    return ReceiptPhotoCoverageDecision.fromSignals(
      quality: selectedQualityCheck,
      diagnostics: selectedCaptureDiagnostics,
    );
  }

  _NativeCaptureReviewWarning? get nativeCaptureReviewWarning {
    final warning = ReceiptNativeSavedPhotoReviewWarning.maybeFromDiagnostics(
      selectedCaptureDiagnostics,
    );
    if (warning == null) return null;
    return _NativeCaptureReviewWarning.fromModel(warning);
  }
}
