import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_ocr_service.dart';

void main() {
  test('OCR field candidates preserve evidence and competing totals', () {
    const document = ReceiptOcrDocument(
      pages: [
        ReceiptOcrPage(
          attachmentId: 'receipt-1',
          pageIndex: 0,
          sourceImageReference: '/tmp/receipt-1.jpg',
          blocks: [
            ReceiptOcrBlock(
              text: 'HDWR MART',
              lines: [
                ReceiptOcrLine(
                  text: 'HDWR MART',
                  bounds: ReceiptOcrBounds(
                    left: 10,
                    top: 10,
                    right: 250,
                    bottom: 35,
                  ),
                ),
              ],
            ),
            ReceiptOcrBlock(
              text: '07/14/2026',
              lines: [
                ReceiptOcrLine(
                  text: '07/14/2026',
                  bounds: ReceiptOcrBounds(
                    left: 10,
                    top: 45,
                    right: 180,
                    bottom: 70,
                  ),
                ),
              ],
            ),
            ReceiptOcrBlock(
              text: 'SUBTOTAL 17.17',
              lines: [
                ReceiptOcrLine(
                  text: 'SUBTOTAL 17.17',
                  bounds: ReceiptOcrBounds(
                    left: 10,
                    top: 80,
                    right: 280,
                    bottom: 105,
                  ),
                ),
              ],
            ),
            ReceiptOcrBlock(
              text: 'TAX 1.20',
              lines: [
                ReceiptOcrLine(
                  text: 'TAX 1.20',
                  bounds: ReceiptOcrBounds(
                    left: 10,
                    top: 115,
                    right: 200,
                    bottom: 140,
                  ),
                ),
              ],
            ),
            ReceiptOcrBlock(
              text: 'TOTAL 18.37',
              lines: [
                ReceiptOcrLine(
                  text: 'TOTAL 18.37',
                  bounds: ReceiptOcrBounds(
                    left: 10,
                    top: 150,
                    right: 250,
                    bottom: 175,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );

    final candidates = document.fieldCandidates;
    final total = candidates.selectedFor(ReceiptOcrFieldKind.total)!;

    expect(
      candidates.selectedFor(ReceiptOcrFieldKind.merchant)?.value,
      'HDWR MART',
    );
    expect(
      candidates.selectedFor(ReceiptOcrFieldKind.date)?.value,
      '07/14/2026',
    );
    expect(
      candidates.selectedFor(ReceiptOcrFieldKind.subtotal)?.value,
      '17.17',
    );
    expect(candidates.selectedFor(ReceiptOcrFieldKind.tax)?.value, '1.20');
    expect(total.value, '18.37');
    expect(total.sourceText, 'TOTAL 18.37');
    expect(total.sourceLineIndexes, [4]);
    expect(total.bounds?.top, 150);
    expect(total.reason, contains('total-labelled'));
  });
}
