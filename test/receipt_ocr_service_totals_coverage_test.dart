import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/receipts/receipt_processing_contract.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
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

  test('ocr parser line signals flag totals before item lines for review', () {
    const result = ReceiptOcrResult(
      rawText: '''
PRIVATE STORE
06/12/2026
TOTAL 12.34
SERVICE ITEM 12.34
''',
      parserText: '''
PRIVATE STORE
06/12/2026
TOTAL 12.34
SERVICE ITEM 12.34
''',
      textByAttachmentId: {'photo-1': 'PRIVATE STORE'},
      source: ReceiptProcessingSource.photo,
    );

    final handoff = result.parserHandoff;

    expect(handoff.itemLines.single.text, 'SERVICE ITEM 12.34');
    expect(handoff.primaryTotalLine?.text, 'TOTAL 12.34');
    expect(handoff.firstItemLineIndex, 3);
    expect(handoff.firstSummaryLineIndex, 2);
    expect(handoff.lineSequenceStatus, 'summary_before_items');
    expect(handoff.hasExpectedLineSequence, isFalse);
    expect(handoff.needsLineSequenceReview, isTrue);
    expect(handoff.parserReviewSignalCount, 3);
    expect(handoff.receiptStructureStatus, 'missing_vendor');
    expect(handoff.parserMissingFieldCounts['vendor_missing'], 1);
    expect(handoff.parserReviewTaskCounts['line_sequence_needs_review'], 1);
    expect(handoff.parserTaskCounts['vendor_missing'], 1);
    expect(handoff.parserTaskCounts['line_sequence_needs_review'], 1);
    expect(handoff.counts['expectedLineSequenceCount'], 0);
    expect(handoff.counts['lineSequenceReviewCount'], 1);
    expect(handoff.counts['parserReviewSignalCount'], 3);
    expect(handoff.counts['vendor_missing'], 1);
    expect(handoff.counts['line_sequence_needs_review'], 1);
    expect(result.diagnostics.ocrLineSequenceStatus, 'summary_before_items');
    expect(result.diagnostics.ocrReceiptStructureStatus, 'missing_vendor');
    expect(
      result.diagnostics.parserSignalSummaryLabel,
      contains('line order summary_before_items'),
    );
  });

  test('ocr parser handoff flags out-of-order long receipt sections', () {
    const result = ReceiptOcrResult(
      rawText: '''
SECTION TWO ITEM 4.99
SECTION ONE ITEM 2.99
TOTAL 7.98
''',
      parserText: '''
SECTION TWO ITEM 4.99
SECTION ONE ITEM 2.99
TOTAL 7.98
''',
      textByAttachmentId: {'photo-1': 'private receipt text omitted'},
      source: ReceiptProcessingSource.photo,
      parserLineSourceLocations: [
        ReceiptOcrParserLineLocation(sectionNumber: 2, sectionLineNumber: 1),
        ReceiptOcrParserLineLocation(sectionNumber: 1, sectionLineNumber: 1),
        ReceiptOcrParserLineLocation(sectionNumber: 1, sectionLineNumber: 2),
      ],
    );

    final handoff = result.parserHandoff;
    final contract = handoff.privacySafeParserHandoffContract;

    expect(handoff.sourceSectionNumbersInOrder, [2, 1]);
    expect(handoff.uniqueSourceSectionNumbers, [1, 2]);
    expect(handoff.sourceSectionCount, 2);
    expect(handoff.sourceSectionContinuityStatus, 'out_of_order_sections');
    expect(handoff.needsSourceSectionContinuityReview, isTrue);
    expect(handoff.counts['sourceSectionCount'], 2);
    expect(handoff.counts['sourceSectionContinuityReviewCount'], 1);
    expect(handoff.counts['sourceSectionContinuity_out_of_order_sections'], 1);
    expect(contract['sourceSectionContinuityStatus'], 'out_of_order_sections');
    expect(contract['sourceSectionContinuityReviewNeeded'], isTrue);
    expect(
      result.diagnostics.ocrSourceSectionContinuityStatus,
      'out_of_order_sections',
    );
    expect(result.diagnostics.ocrSourceSectionCount, 2);
    expect(result.diagnostics.ocrSourceSectionContinuityReviewNeeded, isTrue);
    expect(
      result.diagnostics.parserSignalSummaryLabel,
      contains('section order out_of_order_sections'),
    );
    expect(contract.toString(), isNot(contains('SECTION TWO ITEM')));
    expect(contract.toString(), isNot(contains('4.99')));
  });

  test('ocr result warns when parser handoff signals are missing', () {
    const result = ReceiptOcrResult(
      rawText: '''
06/12/2026
12345
''',
      parserText: '''
06/12/2026
12345
''',
      textByAttachmentId: {'photo-1': '06/12/2026'},
      source: ReceiptProcessingSource.photo,
    );

    expect(result.hasText, isTrue);
    expect(result.itemCandidateLines, isEmpty);
    expect(result.totalCandidateLines, isEmpty);
    expect(
      result.structuredParserHandoffWarnings,
      contains(
        'Receipt Assist found receipt text but no priced item lines. Review line items or enter them by hand.',
      ),
    );
    expect(
      result.structuredParserHandoffWarnings,
      contains(
        'Receipt Assist found receipt text but no subtotal, tax, or total signals. Review the receipt totals before saving.',
      ),
    );
    expect(
      result.structuredParserHandoffWarnings,
      contains(
        'Receipt Assist found receipt text but no clear store header. Review the vendor before saving.',
      ),
    );
    expect(result.parserHandoff.parserMissingFieldCounts, {
      'vendor_missing': 1,
      'item_price_missing': 1,
      'summary_missing': 1,
      'total_missing': 1,
    });
    expect(result.parserHandoff.fieldReadinessCounts['vendor_missing'], 1);
    expect(result.parserHandoff.fieldReadinessCounts['item_price_missing'], 1);
    expect(result.parserHandoff.fieldReadinessCounts['summary_missing'], 1);
    expect(result.parserHandoff.fieldReadinessCounts['total_missing'], 1);
    expect(result.parserHandoff.parserTaskCounts['vendor_missing'], 1);
    expect(result.parserHandoff.parserTaskCounts['item_price_missing'], 1);
    expect(result.parserHandoff.parserTaskCounts['summary_missing'], 1);
    expect(result.parserHandoff.parserTaskCounts['total_missing'], 1);
    expect(result.parserHandoff.counts['vendor_missing'], 1);
    expect(result.parserHandoff.counts['item_price_missing'], 1);
    expect(result.parserHandoff.counts['summary_missing'], 1);
    expect(result.parserHandoff.counts['total_missing'], 1);
    expect(result.diagnostics.parserTaskCounts['vendor_missing'], 1);
    expect(result.diagnostics.fieldReadinessCounts['summary_missing'], 1);
  });

  test('ocr diagnostics exposes receipt totals coverage evidence', () {
    const result = ReceiptOcrResult(
      rawText: '''
LOWE'S
06/12/2026
PVC GLUE 7.99
SUBTOTAL 7.99
TAX 0.66
TOTAL 8.65
''',
      parserText: '''
LOWE'S
06/12/2026
PVC GLUE 7.99
SUBTOTAL 7.99
TAX 0.66
TOTAL 8.65
''',
      textByAttachmentId: {'photo-1': 'private receipt text omitted'},
      source: ReceiptProcessingSource.photo,
    );

    final diagnostics = result.diagnostics;
    final coverageEvidence =
        diagnostics.receiptTotalsCoverageEvidenceDiagnostics;

    expect(diagnostics.receiptSubtotalDetected, isTrue);
    expect(diagnostics.receiptTotalDetected, isTrue);
    expect(diagnostics.receiptTotalAmountDetected, isTrue);
    expect(
      diagnostics.receiptTotalsTextEvidenceStatus,
      'subtotal_and_total_found',
    );
    expect(diagnostics.receiptMayNeedBottomSection, isFalse);
    expect(
      diagnostics.receiptBottomTotalsEvidenceLabel,
      'totals_ready_edge_ok',
    );
    expect(
      diagnostics.receiptCompletionReviewReasonCode,
      'summary_evidence_present',
    );
    expect(
      diagnostics.receiptCompletionReviewActionLabel,
      'Review parsed receipt details',
    );
    expect(diagnostics.receiptPostCaptureRouteStatus, 'parsed_receipt_review');
    expect(
      diagnostics.receiptPostCaptureRouteLabel,
      'Continue to parsed receipt review.',
    );
    expect(
      coverageEvidence[ReceiptCaptureDiagnosticKeys.receiptSubtotalDetected],
      isTrue,
    );
    expect(
      coverageEvidence[ReceiptCaptureDiagnosticKeys.receiptTotalDetected],
      isTrue,
    );
    expect(
      coverageEvidence[ReceiptCaptureDiagnosticKeys.receiptTotalAmountDetected],
      isTrue,
    );
    expect(
      coverageEvidence[ReceiptCaptureDiagnosticKeys
          .receiptTotalsTextEvidenceStatus],
      'subtotal_and_total_found',
    );
    expect(coverageEvidence['receiptSummaryLineCount'], 3);
    expect(coverageEvidence['receiptMayNeedBottomSection'], isFalse);
    expect(
      coverageEvidence['receiptBottomTotalsEvidenceLabel'],
      'totals_ready_edge_ok',
    );
    expect(
      coverageEvidence['receiptCompletionReviewReasonCode'],
      'summary_evidence_present',
    );
    expect(
      coverageEvidence['receiptPostCaptureRouteStatus'],
      'parsed_receipt_review',
    );
  });
}
