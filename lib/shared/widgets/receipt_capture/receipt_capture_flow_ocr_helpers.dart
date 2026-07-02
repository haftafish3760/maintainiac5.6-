part of 'receipt_capture_flow.dart';

extension ReceiptCaptureFlowOcrHelpers on ReceiptCaptureFlow {
  Future<ReceiptCaptureFlowResult> captureReviewAndReadText(
    BuildContext context, {
    ReceiptCaptureFlowOptions options = const ReceiptCaptureFlowOptions(),
  }) async {
    final capability =
        ReceiptCaptureSettingsScope.maybeOf(context)?.deviceCapability ??
        const ReceiptDeviceCapability.standard();
    final capture = await captureAndReview(context, options: options);
    if (!capture.accepted || capture.reviewResult == null) return capture;
    final ocr = await ReceiptCaptureFlow.readTextFromReviewResult(
      capture.reviewResult!,
      deviceCapability: capability,
      module: options.module,
    );
    return ReceiptCaptureFlowResult.accepted(
      reviewResult: capture.reviewResult!,
      ocrResult: ocr,
      nativeCapabilities: capture.nativeCapabilities,
      recoveryManifestPath: capture.recoveryManifestPath,
      diagnostics: {
        ...capture.diagnostics,
        'ocrHasText': ocr.hasText,
        'ocrWarningCount': ocr.warnings.length,
        'ocrPhotosRead': ocr.stats.photosRead,
        'ocrPhotosSkipped': ocr.stats.photosSkipped,
        ..._receiptReaderHandoffDiagnosticsFor(capture.reviewResult!),
      },
    );
  }
}
