import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/receipts/receipt_processing_contract.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_ocr_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory documentsDirectory;

  setUp(() async {
    documentsDirectory = await Directory.systemTemp.createTemp(
      'receipt_proof_storage_test_',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => switch (call.method) {
            'getApplicationDocumentsDirectory' => documentsDirectory.path,
            _ => null,
          },
        );
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
    if (await documentsDirectory.exists()) {
      await documentsDirectory.delete(recursive: true);
    }
  });

  test('ocr recognizes common subtotal and total wording variants', () {
    const result = ReceiptOcrResult(
      rawText: '''
HARDWARE SUPPLY
MERCHANDISE TOTAL 12.40
TAX 1.02
TRANSACTION TOTAL 13.42
ENDING BAL 4.00
GIFT CARD BALANCE 20.00
YOU SAVED 2.00
''',
      parserText: '''
HARDWARE SUPPLY
MERCHANDISE TOTAL 12.40
TAX 1.02
TRANSACTION TOTAL 13.42
ENDING BAL 4.00
GIFT CARD BALANCE 20.00
YOU SAVED 2.00
''',
      textByAttachmentId: {'photo-1': 'private receipt text omitted'},
      source: ReceiptProcessingSource.photo,
    );

    expect(result.subtotalCandidateLines, contains('MERCHANDISE TOTAL 12.40'));
    expect(result.totalCandidateLines, contains('TRANSACTION TOTAL 13.42'));
    expect(result.taxCandidateLines, contains('TAX 1.02'));
    expect(result.tenderCandidateLines, contains('ENDING BAL 4.00'));
    expect(result.tenderCandidateLines, contains('GIFT CARD BALANCE 20.00'));
    expect(result.totalCandidateLines, isNot(contains('ENDING BAL 4.00')));
    expect(
      result.totalCandidateLines,
      isNot(contains('GIFT CARD BALANCE 20.00')),
    );
    expect(result.totalCandidateLines, isNot(contains('YOU SAVED 2.00')));
    expect(
      result.diagnostics.receiptTotalsTextEvidenceStatus,
      'subtotal_and_total_found',
    );
    expect(
      result.diagnostics.receiptBottomTotalsEvidenceLabel,
      'totals_ready_edge_ok',
    );
  });

  test('ocr diagnostics flags partial totals when final total is missing', () {
    const result = ReceiptOcrResult(
      rawText: '''
HARDWARE SUPPLY
PVC GLUE 7.99
PAINTERS TAPE 5.99
SUBTOTAL 13.98
TAX 1.12
''',
      parserText: '''
HARDWARE SUPPLY
PVC GLUE 7.99
PAINTERS TAPE 5.99
SUBTOTAL 13.98
TAX 1.12
''',
      textByAttachmentId: {'photo-1': 'private receipt text omitted'},
      source: ReceiptProcessingSource.photo,
    );

    final diagnostics = result.diagnostics;
    expect(result.subtotalCandidateLines, contains('SUBTOTAL 13.98'));
    expect(result.taxCandidateLines, contains('TAX 1.12'));
    expect(result.totalCandidateLines, isEmpty);
    expect(
      diagnostics.receiptTotalsTextEvidenceStatus,
      'summary_partial_found',
    );
    expect(
      diagnostics.receiptBottomTotalsEvidenceLabel,
      'partial_totals_evidence',
    );
    expect(diagnostics.parserTaskCounts['receipt_partial_totals_review'], 1);
    expect(
      diagnostics.parserTaskCounts['receipt_final_total_missing_review'],
      1,
    );
    expect(
      diagnostics.parserTaskCounts['receipt_possible_lower_section_missing'],
      1,
    );
    expect(
      diagnostics.receiptCompletionReviewReasonCode,
      'partial_totals_evidence',
    );
    expect(
      diagnostics.receiptCompletionReviewActionLabel,
      'Review subtotal, tax, and total',
    );
  });
}
