part of 'receipt_capture_flow.dart';

List<ReceiptAttachmentRecord> _attachmentsFromReviewResult(
  ReceiptPhotoReviewResult result,
  ReceiptCaptureFlowModule module,
) {
  final createdAt = DateTime.now();
  return [
    for (var index = 0; index < result.ocrSourcePhotoPaths.length; index++)
      ReceiptAttachmentRecord(
        id: 'shared_receipt_ocr_${createdAt.microsecondsSinceEpoch}_$index',
        path: result.ocrSourcePhotoPaths[index],
        kind: ReceiptAttachmentKind.photo,
        dataSaverLevel: result.dataSaverLevel,
        createdAt: createdAt,
        displayName: 'Receipt OCR source ${index + 1}',
        sourceLabel: 'Maintainiac clear receipt photo',
        linkedModule: module.storageName,
        storageState: ReceiptAttachmentStorageState.staged,
        documentSignals: _ocrSourceDocumentSignalsFor(result, index),
        riskFlags: _ocrSourceRiskFlagsFor(result, index),
      ),
  ];
}
