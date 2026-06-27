import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_export_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';
import 'package:maintaniac/shared/receipts/receipt_processing_contract.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

import 'helpers/receipt_parse_accuracy_harness.dart';
import 'helpers/receipt_regression_fixture_packs.dart';

void main() {
  test('synthetic receipts parse into saved and export-ready records', () {
    final fixtures = [
      for (final pack in receiptRegressionFixturePacks.values) ...pack,
    ];
    final receipts = <ExpenseReceiptRecord>[];

    for (var index = 0; index < fixtures.length; index++) {
      final fixture = fixtures[index];
      final parsed = parseExpenseReceiptText(fixture.text);
      final receipt = _receiptFromParsedFixture(index, fixture, parsed);
      receipts.add(receipt);

      expect(
        receipt.merchantName,
        isNotEmpty,
        reason: '${fixture.name}: merchant must survive save model',
      );
      expect(
        receipt.lines,
        isNotEmpty,
        reason: '${fixture.name}: parsed lines must survive save model',
      );
      expect(
        receipt.total,
        greaterThan(0),
        reason: '${fixture.name}: saved receipt total must be usable',
      );
      expect(
        receipt.hasReceiptAttachment,
        isTrue,
        reason: '${fixture.name}: proof metadata must survive save model',
      );
      expect(
        receipt.ocrReview.hasData,
        isTrue,
        reason: '${fixture.name}: OCR review metadata must survive save model',
      );
      expect(
        receipt.ocrReview.parserLineCount,
        parsed.lines.length,
        reason: '${fixture.name}: parser line count must match saved review',
      );
      expect(
        receipt.businessTotal + receipt.personalTotal,
        closeTo(receipt.total, .02),
        reason: '${fixture.name}: business/personal allocation must reconcile',
      );
      expect(
        receipt.rawOcrText,
        fixture.text,
        reason: '${fixture.name}: raw OCR text stays local on receipt record',
      );
    }

    final snapshot = buildExpenseExportSnapshot(
      receipts: receipts,
      range: ExpenseDateRange(
        start: DateTime(2026, 6, 1),
        end: DateTime(2026, 6, 30),
      ),
      categoryFilter: ExpenseExportCategoryFilter.all,
      exportedAt: DateTime.utc(2026, 6, 26, 12),
    );
    final receiptsCsv = snapshot.toReceiptsCsv();
    final linesCsv = snapshot.toLineItemsCsv();
    final manifest = snapshot.toManifest();

    expect(snapshot.receiptCount, receipts.length);
    expect(
      snapshot.lineCount,
      receipts.fold(0, (sum, r) => sum + r.lines.length),
    );
    expect(snapshot.receiptProofCount, receipts.length);
    expect(snapshot.receiptsMissingProof, 0);
    expect(snapshot.receiptsWithOcrReview, receipts.length);
    expect(snapshot.receiptsNeedingOcrReview, greaterThan(0));
    expect(receiptsCsv, contains('receipt_proof_count'));
    expect(receiptsCsv, contains('ocr_review_status'));
    expect(receiptsCsv, isNot(contains('LOWES H0ME IMPR0VEMENT')));
    expect(receiptsCsv, isNot(contains('PUMP O4 UNLEADED')));
    expect(linesCsv, contains('business_percent'));
    expect(linesCsv, contains('tax_adjusted_line_total'));
    expect(manifest['privacyNote'], contains('Raw OCR text'));
    expect(manifest['receiptProofCount'], receipts.length);
  });
}

ExpenseReceiptRecord _receiptFromParsedFixture(
  int index,
  ReceiptParseFixture fixture,
  ExpenseReceiptParseResult parsed,
) {
  final receiptDate = parsed.receiptDate ?? DateTime(2026, 6, 1);
  return ExpenseReceiptRecord(
    id: 'SYNTH-${index.toString().padLeft(3, '0')}',
    receiptDate: receiptDate,
    receiptTimeMinutes: parsed.receiptTimeMinutes,
    merchantName: parsed.merchantName ?? fixture.expectedMerchant,
    hasReceiptProof: true,
    attachments: [
      ReceiptAttachmentRecord(
        id: 'SYNTH-PROOF-$index',
        path: '/synthetic/receipt_$index.txt',
        kind: ReceiptAttachmentKind.emailText,
        dataSaverLevel: ReceiptDataSaverLevel.balanced,
        createdAt: DateTime.utc(2026, 6, 26, 12, index),
        byteSize: fixture.text.length,
        readState: ReceiptAttachmentReadState.readIntoForm,
      ),
    ],
    rawOcrText: fixture.text,
    ocrReview: ExpenseReceiptOcrReview(
      severity: parsed.quality.needsReview ? 'review' : 'good',
      source: ReceiptProcessingSource.importedText.name,
      warningCount: parsed.warnings.length,
      reviewWarningCount: parsed.quality.needsReview ? 1 : 0,
      attachmentsRead: 1,
      rawLineCount: _receiptTextLineCount(fixture.text),
      parserLineCount: parsed.lines.length,
    ),
    enteredSubtotal: parsed.enteredSubtotal,
    enteredTax: parsed.enteredTax,
    enteredTotal: parsed.enteredTotal,
    lines: parsed.lines,
    sourceScreen: 'synthetic_receipt_regression',
    createdAt: DateTime.utc(2026, 6, 26, 12, index),
  );
}

int _receiptTextLineCount(String text) {
  return text
      .split(RegExp(r'\r?\n'))
      .where((line) => line.trim().isNotEmpty)
      .length;
}
