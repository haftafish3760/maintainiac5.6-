import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_ocr_service.dart';

void main() {
  test('raw receipt text keeps source spacing while app fill is cleaned', () async {
    const source = '  HDWR  \nBLK NTR GLV XL  9.99  \n';
    final result = await const ReceiptOcrService().recognizeTextFromAttachments([
      ReceiptAttachmentRecord(
        id: 'source-text',
        path: '',
        kind: ReceiptAttachmentKind.emailText,
        dataSaverLevel: ReceiptDataSaverLevel.balanced,
        createdAt: DateTime(2026, 6, 20),
        importedText: source,
      ),
    ]);

    expect(result.rawText, source);
    expect(result.textByAttachmentId.values.single, source);
    expect(result.parserText, 'HDWR\nBLK NTR GLV XL  9.99');
    expect(result.appFillText, contains('HDWR'));
  });
}
