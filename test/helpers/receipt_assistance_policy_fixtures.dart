import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

ReceiptAttachmentRecord receiptAttachmentFixture({
  required ReceiptAttachmentKind kind,
  String importedText = '',
  int? byteSize,
  int? pageCount,
  List<String> riskFlags = const [],
  String idSuffix = '',
}) {
  return ReceiptAttachmentRecord(
    id: 'att-${kind.name}$idSuffix',
    path:
        kind == ReceiptAttachmentKind.photo || kind == ReceiptAttachmentKind.pdf
        ? '/tmp/receipt'
        : '',
    kind: kind,
    dataSaverLevel: ReceiptDataSaverLevel.balanced,
    createdAt: DateTime(2026, 6, 22),
    importedText: importedText,
    byteSize: byteSize,
    pageCount: pageCount,
    pageCountStatus: pageCount == null
        ? ReceiptPdfPageCountStatus.unknown
        : ReceiptPdfPageCountStatus.estimated,
    validationStatus: ReceiptPdfValidationStatus.valid,
    riskFlags: riskFlags,
  );
}
