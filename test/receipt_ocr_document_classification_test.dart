import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_ocr_service.dart';

void main() {
  ReceiptOcrParserLineSignal line({
    required ReceiptOcrParserLineKind kind,
    ReceiptOcrParserExpenseFamily family =
        ReceiptOcrParserExpenseFamily.unknown,
  }) {
    return ReceiptOcrParserLineSignal(
      index: 0,
      text: 'receipt evidence',
      kind: kind,
      expenseFamily: family,
    );
  }

  ReceiptOcrParserHandoff handoff({
    List<ReceiptOcrParserLineSignal> vendors = const [],
    List<ReceiptOcrParserLineSignal> items = const [],
    List<ReceiptOcrParserLineSignal> summaries = const [],
  }) => ReceiptOcrParserHandoff(
    lines: [...vendors, ...items, ...summaries],
    vendorLines: vendors,
    dateLines: const [],
    itemLines: items,
    summaryLines: summaries,
    tenderLines: const [],
    metadataLines: const [],
  );

  test('classifies unreadable input as not a receipt', () {
    final result = classifyReceiptOcrDocument(
      hasReadableText: false,
      handoff: handoff(),
    );

    expect(result.documentType, ReceiptOcrDocumentType.notAReceipt);
    expect(result.detailLevel, ReceiptOcrDetailLevel.unknown);
    expect(result.needsReview, isTrue);
  });

  test('marks generic fuel evidence for review without invoking a parser', () {
    final result = classifyReceiptOcrDocument(
      hasReadableText: true,
      handoff: handoff(
        vendors: [line(kind: ReceiptOcrParserLineKind.vendorCandidate)],
        items: [
          line(
            kind: ReceiptOcrParserLineKind.itemCandidate,
            family: ReceiptOcrParserExpenseFamily.fuel,
          ),
        ],
        summaries: [line(kind: ReceiptOcrParserLineKind.totalCandidate)],
      ),
    );

    expect(result.documentType, ReceiptOcrDocumentType.fuel);
    expect(result.detailLevel, ReceiptOcrDetailLevel.simple);
    expect(result.needsReview, isTrue);
  });

  test('marks mixed fuel and inventory evidence as ambiguous', () {
    final result = classifyReceiptOcrDocument(
      hasReadableText: true,
      handoff: handoff(
        items: [
          line(
            kind: ReceiptOcrParserLineKind.itemCandidate,
            family: ReceiptOcrParserExpenseFamily.fuel,
          ),
          line(
            kind: ReceiptOcrParserLineKind.itemCandidate,
            family: ReceiptOcrParserExpenseFamily.materials,
          ),
        ],
        summaries: [line(kind: ReceiptOcrParserLineKind.totalCandidate)],
      ),
    );

    expect(result.documentType, ReceiptOcrDocumentType.ambiguous);
    expect(result.detailLevel, ReceiptOcrDetailLevel.detailed);
    expect(result.needsReview, isTrue);
  });

  test('keeps a header-only document unsupported for manual review', () {
    final result = classifyReceiptOcrDocument(
      hasReadableText: true,
      handoff: handoff(
        vendors: [line(kind: ReceiptOcrParserLineKind.vendorCandidate)],
      ),
    );

    expect(result.documentType, ReceiptOcrDocumentType.unsupported);
    expect(result.detailLevel, ReceiptOcrDetailLevel.basic);
    expect(result.needsReview, isTrue);
  });
}
