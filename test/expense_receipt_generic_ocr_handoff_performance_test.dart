import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_item_memory_store.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_assistance_policy.dart';
import 'dart:io';

import 'helpers/receipt_ocr_parser_ready_fixture.dart';

void main() {
  test(
    'generic Lowe receipt handoff stays out of inventory matching',
    () async {
      final stopwatch = Stopwatch()..start();
      final prepared = await prepareGenericExpenseReceiptOcrReviewInWorker(
        parserReadyLowesReceiptResult(),
      );
      stopwatch.stop();

      final parsed = prepared.parsed;
      expect(parsed.merchantName, "Lowe's");
      expect(parsed.enteredTotal, 3.24);
      expect(parsed.diagnostics.parserDepth, ReceiptParserDepth.lineItems);
      // Detailed coordinate diagnostics are optional review evidence. They
      // must not serialize a full OCR graph before the editable form opens.
      expect(prepared.ocrDiagnostics, isNull);
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 2)));
    },
  );

  test('generic worker sends compact text, not the full OCR graph', () async {
    final source = await File(
      'lib/screens/expenses/data/expense_receipt_item_memory_store.dart',
    ).readAsString();

    final worker = source.substring(
      source.indexOf('prepareGenericExpenseReceiptOcrReviewInWorker('),
      source.indexOf('class ExpenseReceiptItemMemoryStore'),
    );
    expect(worker, contains('final textForGenericReview = ocr.appFillText;'));
    expect(
      worker,
      contains(
        'final itemDraftsForGenericReview = ocr.parserHandoff.itemLineDrafts;',
      ),
    );
    expect(
      worker,
      contains('parseExpenseReceiptText(\n      textForGenericReview,'),
    );
    expect(
      worker,
      isNot(contains('parseExpenseReceiptOcrResult(\n      ocr,')),
    );
    expect(worker, isNot(contains('final diagnostics = ocr.diagnostics;')));
    expect(worker, contains('recoverMissingOcrItemDrafts('));
    expect(worker, contains('candidateLineCount:'));
    expect(worker, contains('recoveredLineCount:'));
  });
}
