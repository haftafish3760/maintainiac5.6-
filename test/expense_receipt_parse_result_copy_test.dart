import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_ocr_candidate_fallback.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_ocr_service.dart';

void main() {
  test(
    'copyWith fills missing receipt fields without changing existing evidence',
    () {
      final original = ExpenseReceiptParseResult(
        sourceText: 'HDWR MART\nTOTAL 18.37',
        merchantName: 'HDWR MART',
        enteredTotal: 18.37,
        lines: const [],
      );

      final completed = original.copyWith(
        receiptDate: DateTime(2026, 7, 14),
        enteredSubtotal: 17.17,
        enteredTax: 1.20,
      );

      expect(completed.sourceText, original.sourceText);
      expect(completed.merchantName, 'HDWR MART');
      expect(completed.enteredTotal, 18.37);
      expect(completed.receiptDate, DateTime(2026, 7, 14));
      expect(completed.enteredSubtotal, 17.17);
      expect(completed.enteredTax, 1.20);
    },
  );

  test(
    'OCR candidates fill missing fields without replacing parser values',
    () {
      const document = ReceiptOcrDocument(
        pages: [
          ReceiptOcrPage(
            attachmentId: 'receipt-1',
            pageIndex: 0,
            sourceImageReference: '/tmp/receipt-1.jpg',
            blocks: [
              ReceiptOcrBlock(
                text: 'HDWR MART',
                lines: [ReceiptOcrLine(text: 'HDWR MART')],
              ),
              ReceiptOcrBlock(
                text: '07/14/2026',
                lines: [ReceiptOcrLine(text: '07/14/2026')],
              ),
              ReceiptOcrBlock(
                text: r'TOTAL $18.37',
                lines: [ReceiptOcrLine(text: r'TOTAL $18.37')],
              ),
              ReceiptOcrBlock(
                text: r'AMOUNT DUE $18.37',
                lines: [ReceiptOcrLine(text: r'AMOUNT DUE $18.37')],
              ),
            ],
          ),
        ],
      );
      final parsed = ExpenseReceiptParseResult(
        sourceText: 'parser output',
        merchantName: 'Parser Merchant',
        fieldConfidences: const {
          'date': ExpenseReceiptFieldConfidence(
            fieldKey: 'date',
            confidence: .12,
            needsReview: true,
            reason: 'Receipt date was not found.',
          ),
        },
        lines: const [],
      );

      final completed = fillMissingExpenseReceiptFieldsFromOcrCandidates(
        parsed,
        document,
      );

      expect(completed.merchantName, 'Parser Merchant');
      expect(completed.receiptDate, DateTime(2026, 7, 14));
      expect(completed.enteredTotal, 18.37);
      expect(
        completed.fieldConfidences['total']?.reason,
        contains('1 competing receipt candidate remains available for review'),
      );
      expect(completed.fieldConfidences['merchant'], isNull);
      expect(completed.fieldConfidences['date']?.needsReview, isTrue);
      expect(
        completed.fieldConfidences['date']?.reason,
        contains('Confirm against the receipt proof'),
      );
    },
  );

  test('OCR candidate fallback rejects impossible calendar dates', () {
    const document = ReceiptOcrDocument(
      pages: [
        ReceiptOcrPage(
          attachmentId: 'receipt-1',
          pageIndex: 0,
          sourceImageReference: '/tmp/receipt-1.jpg',
          blocks: [
            ReceiptOcrBlock(
              text: '02/30/2026',
              lines: [ReceiptOcrLine(text: '02/30/2026')],
            ),
          ],
        ),
      ],
    );

    final completed = fillMissingExpenseReceiptFieldsFromOcrCandidates(
      const ExpenseReceiptParseResult(sourceText: '', lines: []),
      document,
    );

    expect(completed.receiptDate, isNull);
  });

  test('OCR merchant evidence fills an empty parser field for review', () {
    const document = ReceiptOcrDocument(
      pages: [
        ReceiptOcrPage(
          attachmentId: 'receipt-merchant',
          blocks: [
            ReceiptOcrBlock(
              text: 'HDWR MART #42',
              lines: [ReceiptOcrLine(text: 'HDWR MART #42')],
            ),
          ],
        ),
      ],
    );

    final completed = fillMissingExpenseReceiptFieldsFromOcrCandidates(
      const ExpenseReceiptParseResult(sourceText: '', lines: []),
      document,
    );

    expect(completed.merchantName, 'HDWR MART #42');
    expect(completed.fieldConfidences['merchant']?.needsReview, isTrue);
    expect(
      completed.fieldConfidences['merchant']?.reason,
      contains('Confirm against the receipt proof'),
    );
  });

  test('OCR candidate fallback accepts dotted receipt dates', () {
    const document = ReceiptOcrDocument(
      pages: [
        ReceiptOcrPage(
          attachmentId: 'receipt-1',
          pageIndex: 0,
          sourceImageReference: '/tmp/receipt-1.jpg',
          blocks: [
            ReceiptOcrBlock(
              text: '07.14.2026',
              lines: [ReceiptOcrLine(text: '07.14.2026')],
            ),
          ],
        ),
      ],
    );

    final completed = fillMissingExpenseReceiptFieldsFromOcrCandidates(
      const ExpenseReceiptParseResult(sourceText: '', lines: []),
      document,
    );

    expect(completed.receiptDate, DateTime(2026, 7, 14));
  });

  test('OCR candidate fallback retains parenthetical refund totals', () {
    const document = ReceiptOcrDocument(
      pages: [
        ReceiptOcrPage(
          attachmentId: 'receipt-1',
          pageIndex: 0,
          sourceImageReference: '/tmp/receipt-1.jpg',
          blocks: [
            ReceiptOcrBlock(
              text: r'TOTAL ($18.37)',
              lines: [ReceiptOcrLine(text: r'TOTAL ($18.37)')],
            ),
          ],
        ),
      ],
    );

    final completed = fillMissingExpenseReceiptFieldsFromOcrCandidates(
      const ExpenseReceiptParseResult(sourceText: '', lines: []),
      document,
    );

    expect(completed.enteredTotal, -18.37);
  });
}
