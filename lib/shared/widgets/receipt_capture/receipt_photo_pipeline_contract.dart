import 'receipt_capture_models.dart';

enum ReceiptPhotoPipelineNextStep {
  reviewLongReceipt,
  reviewSavedImage,
  finalizeReceiptImage,
}

ReceiptPhotoPipelineNextStep receiptPhotoPipelineNextStep({
  required int sourcePhotoCount,
  required bool reviewingSavedImage,
  required ReceiptStitchResult? stitchResult,
}) {
  if (reviewingSavedImage) {
    return ReceiptPhotoPipelineNextStep.finalizeReceiptImage;
  }
  // A multi-photo receipt must be assembled and reviewed before the saved
  // proof choice. If assembly cannot be verified, that review state supplies
  // the recovery path while preserving every original section.
  if (sourcePhotoCount > 1 && stitchResult == null) {
    return ReceiptPhotoPipelineNextStep.reviewLongReceipt;
  }
  return ReceiptPhotoPipelineNextStep.reviewSavedImage;
}

List<String> acceptedReceiptImageSourcePaths({
  required List<String> inputPaths,
  required ReceiptStitchResult? stitchResult,
  required bool stitchMatchesCurrentReceipt,
}) {
  // Receipt proof always retains the original photo sections. A combined
  // image is an optional derived OCR artifact, never the sole saved proof.
  return List<String>.of(inputPaths);
}
