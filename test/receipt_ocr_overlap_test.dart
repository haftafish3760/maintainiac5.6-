import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_ocr_service.dart';

void main() {
  test(
    'ocr keeps raw exact overlap text but suppresses it for app fill',
    () async {
      final result = await const ReceiptOcrService()
          .recognizeTextFromAttachments([
            _textAttachment(
              id: 'section-top',
              text: 'LOWES\nPVC COUPLING 2.49\nPVC GLUE 7.99',
            ),
            _textAttachment(
              id: 'section-bottom',
              text: 'PVC GLUE 7.99\nPIPE STRAP 3.49\nTOTAL 13.97',
            ),
          ]);

      expect(result.rawText, contains('LOWES'));
      expect(result.rawText, contains('PIPE STRAP 3.49'));
      expect('PVC GLUE 7.99'.allMatches(result.rawText), hasLength(2));
      expect('PVC GLUE 7.99'.allMatches(result.appFillText), hasLength(1));
      expect(
        result.warnings.single,
        contains('Ignored 1 repeated receipt line for app-assisted fill'),
      );
      expect(
        result.warnings.single,
        contains('Original receipt text was kept'),
      );
      expect(
        result.appFillText.indexOf('PVC COUPLING 2.49'),
        lessThan(result.appFillText.indexOf('PIPE STRAP 3.49')),
      );
    },
  );

  test('ocr warns about probable overlap without changing text', () async {
    final result = await const ReceiptOcrService()
        .recognizeTextFromAttachments([
          _textAttachment(
            id: 'section-top',
            text: 'LOWES\nPVC GLUE 7.99\nPVC PIPE 12.49',
          ),
          _textAttachment(
            id: 'section-bottom',
            text: 'PVC GLUE 8.99\nPIPE STRAP 3.49\nTOTAL 24.97',
          ),
        ]);

    expect('PVC GLUE'.allMatches(result.rawText), hasLength(2));
    expect('PVC GLUE'.allMatches(result.appFillText), hasLength(2));
    expect(
      result.warnings.single,
      contains('possible overlapping receipt line'),
    );
    expect(result.warnings.single, contains('Nothing was changed'));
  });
}

ReceiptAttachmentRecord _textAttachment({
  required String id,
  required String text,
}) {
  return ReceiptAttachmentRecord(
    id: id,
    path: '',
    kind: ReceiptAttachmentKind.emailText,
    dataSaverLevel: ReceiptDataSaverLevel.balanced,
    createdAt: DateTime(2026, 6, 12),
    importedText: text,
  );
}
