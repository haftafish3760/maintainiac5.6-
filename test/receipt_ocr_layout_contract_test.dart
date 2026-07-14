import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/receipts/receipt_processing_contract.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_ocr_service.dart';

void main() {
  test(
    'normalized OCR layout preserves rows, tokens, bounds, and uncertainty',
    () {
      const layout = ReceiptOcrDocument(
        pages: [
          ReceiptOcrPage(
            attachmentId: 'receipt-photo',
            pageIndex: 2,
            blocks: [
              ReceiptOcrBlock(
                text: '2 PVC 2.58',
                lines: [
                  ReceiptOcrLine(
                    text: '2 PVC 2.58',
                    bounds: ReceiptOcrBounds(
                      left: 10,
                      top: 20,
                      right: 210,
                      bottom: 44,
                    ),
                    tokens: [
                      ReceiptOcrToken(text: '2'),
                      ReceiptOcrToken(text: 'PVC'),
                      ReceiptOcrToken(text: '2.58'),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      expect(layout.hasLayout, isTrue);
      expect(layout.lineCount, 1);
      expect(layout.pages.single.lines.single.tokens, hasLength(3));
      expect(layout.pages.single.lines.single.bounds?.width, 200);
      expect(layout.pages.single.pageIndex, 2);
      expect(layout.pages.single.lines.single.confidence, isNull);
      expect(layout.pages.single.blocks.single.sourceText, '2 PVC 2.58');
      expect(layout.pages.single.lines.single.displayText, '2 PVC 2.58');
      expect(layout.pages.single.lines.single.normalizedText, '2 PVC 2.58');
      expect(layout.pages.single.lines.single.tokens[1].sourceText, 'PVC');
    },
  );

  test('OCR result retains normalized layout for downstream handoff', () {
    const layout = ReceiptOcrDocument(
      pages: [ReceiptOcrPage(attachmentId: 'receipt-photo')],
    );
    const result = ReceiptOcrResult(
      rawText: 'STORE\nTOTAL 12.99',
      parserText: 'STORE\nTOTAL 12.99',
      textByAttachmentId: {'receipt-photo': 'STORE\nTOTAL 12.99'},
      source: ReceiptProcessingSource.photo,
      layout: layout,
    );

    expect(result.layout.pages.single.attachmentId, 'receipt-photo');
    expect(result.appFillText, contains('TOTAL 12.99'));
  });

  test(
    'coordinate reconstruction joins same-row fragments without rewriting',
    () {
      const layout = ReceiptOcrDocument(
        engineIdentity: 'test-engine',
        processingVersion: 'test-v1',
        pages: [
          ReceiptOcrPage(
            attachmentId: 'receipt-photo',
            sourceImageReference: '/tmp/receipt.jpg',
            blocks: [
              ReceiptOcrBlock(
                text: 'BLK NTR GLV XL',
                lines: [
                  ReceiptOcrLine(
                    text: 'BLK NTR GLV XL',
                    bounds: ReceiptOcrBounds(
                      left: 10,
                      top: 50,
                      right: 150,
                      bottom: 70,
                    ),
                  ),
                ],
              ),
              ReceiptOcrBlock(
                text: '9.99',
                lines: [
                  ReceiptOcrLine(
                    text: '9.99',
                    bounds: ReceiptOcrBounds(
                      left: 220,
                      top: 51,
                      right: 260,
                      bottom: 70,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      final row = layout.reconstructedRows.single;
      expect(row.sourceFragments, ['BLK NTR GLV XL', '9.99']);
      expect(row.sourceText, 'BLK NTR GLV XL\t9.99');
      expect(row.displayText, 'BLK NTR GLV XL\t9.99');
      expect(row.optionalInterpretation, isNull);
      expect(row.needsReview, isTrue);
      expect(row.sourceLineIndexes, [0, 1]);
      expect(layout.engineIdentity, 'test-engine');
      expect(layout.processingVersion, 'test-v1');
      expect(layout.pages.single.sourceImageReference, '/tmp/receipt.jpg');

      const result = ReceiptOcrResult(
        rawText: 'BLK NTR GLV XL\n9.99',
        parserText: 'provider order was wrong',
        textByAttachmentId: {'receipt-photo': 'BLK NTR GLV XL\n9.99'},
        source: ReceiptProcessingSource.photo,
        layout: layout,
      );
      expect(result.appFillText, 'BLK NTR GLV XL\t9.99');
    },
  );
}
