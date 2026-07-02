import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/receipts/receipt_processing_contract.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_ocr_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('missing vendor recovery explains no header text without raw content', () {
    const result = ReceiptOcrResult(
      rawText: '''
06/12/2026
PVC ELBOW 1/2 IN 2.49
TAX 0.20
TOTAL 2.69
''',
      parserText: '''
06/12/2026
PVC ELBOW 1/2 IN 2.49
TAX 0.20
TOTAL 2.69
''',
      textByAttachmentId: {'photo-1': 'private receipt text omitted'},
      source: ReceiptProcessingSource.photo,
    );

    final handoff = result.parserHandoff;
    final contract = handoff.privacySafeParserHandoffContract;

    expect(handoff.vendorLines, isEmpty);
    expect(handoff.hasRecoverableMissingVendorHeader, isTrue);
    expect(handoff.addressContactMetadataLineCount, 0);
    expect(
      handoff.vendorReviewStatus,
      'vendor_missing_recoverable_no_header_text',
    );
    expect(
      handoff.vendorReviewLabel,
      'Store name needs review; date, line items, and total can still continue.',
    );
    expect(
      handoff.headerRecoveryDiagnostics['vendorReviewStatus'],
      'vendor_missing_recoverable_no_header_text',
    );
    expect(
      handoff
          .parserReviewTaskCounts['vendor_missing_recoverable_no_header_text'],
      1,
    );
    expect(
      result.diagnostics.vendorReviewStatus,
      'vendor_missing_recoverable_no_header_text',
    );
    expect(
      contract['vendorReviewStatus'],
      'vendor_missing_recoverable_no_header_text',
    );
    expect((contract['vendorReviewDiagnostics'] as Map)['recoverable'], isTrue);
    expect(contract.toString(), isNot(contains('PVC ELBOW')));
    expect(contract.toString(), isNot(contains('2.69')));
  });

  test('weak damaged merchant header is review-only and privacy safe', () {
    const result = ReceiptOcrResult(
      rawText: '''
L0W35
06/12/2026
PVC ELBOW 1/2 IN 2.49
TAX 0.20
TOTAL 2.69
''',
      parserText: '''
L0W35
06/12/2026
PVC ELBOW 1/2 IN 2.49
TAX 0.20
TOTAL 2.69
''',
      textByAttachmentId: {'photo-1': 'private receipt text omitted'},
      source: ReceiptProcessingSource.photo,
    );

    final handoff = result.parserHandoff;
    final weakHeaderSignal = result.parserLineSignals.first;
    final contract = handoff.privacySafeParserHandoffContract;

    expect(result.vendorCandidateLines, isEmpty);
    expect(weakHeaderSignal.kind, ReceiptOcrParserLineKind.other);
    expect(weakHeaderSignal.traits, contains('weak_header_candidate'));
    expect(handoff.weakHeaderCandidateLineCount, 1);
    expect(handoff.weakHeaderCandidateLineIds, ['ocr_line_000_other']);
    expect(handoff.hasRecoverableMissingVendorHeader, isTrue);
    expect(
      handoff.vendorReviewStatus,
      'vendor_missing_recoverable_weak_header_candidate',
    );
    expect(
      handoff.vendorReviewLabel,
      'Store name needs review; OCR found weak header text near the top.',
    );
    expect(handoff.vendorReviewDiagnostics['weakHeaderCandidateLineCount'], 1);
    expect(
      handoff.headerRecoveryDiagnostics['weakHeaderCandidateLineCount'],
      1,
    );
    expect(
      handoff
          .parserReviewTaskCounts['vendor_missing_recoverable_weak_header_candidate'],
      1,
    );
    expect(
      result.diagnostics.vendorReviewStatus,
      'vendor_missing_recoverable_weak_header_candidate',
    );
    expect(
      result.diagnostics.parserSignalSummaryLabel,
      contains(
        'vendor review vendor_missing_recoverable_weak_header_candidate',
      ),
    );
    expect(
      contract['vendorReviewStatus'],
      'vendor_missing_recoverable_weak_header_candidate',
    );
    expect(
      (contract['vendorReviewDiagnostics']
          as Map)['weakHeaderCandidateLineIds'],
      ['ocr_line_000_other'],
    );
    expect(contract.toString(), isNot(contains('L0W35')));
    expect(contract.toString(), isNot(contains('PVC ELBOW')));
    expect(contract.toString(), isNot(contains('2.69')));
  });

  test('missing vendor with unsafe order stays unrecoverable for review', () {
    const result = ReceiptOcrResult(
      rawText: '''
06/12/2026
TOTAL 12.34
SERVICE ITEM 12.34
''',
      parserText: '''
06/12/2026
TOTAL 12.34
SERVICE ITEM 12.34
''',
      textByAttachmentId: {'photo-1': 'private receipt text omitted'},
      source: ReceiptProcessingSource.photo,
    );

    final handoff = result.parserHandoff;
    final contract = handoff.privacySafeParserHandoffContract;

    expect(handoff.vendorLines, isEmpty);
    expect(handoff.hasRecoverableMissingVendorHeader, isFalse);
    expect(handoff.lineSequenceStatus, 'summary_before_items');
    expect(
      handoff.vendorReviewStatus,
      'vendor_missing_unrecoverable_line_order',
    );
    expect(
      handoff.vendorReviewLabel,
      'Store name needs review and receipt line order is not safe enough yet.',
    );
    expect(handoff.parserReadinessStatus, 'missing_vendor');
    expect(handoff.downstreamReadinessStatus, 'proof_needs_review');
    expect(
      handoff.parserReviewTaskCounts['vendor_missing_unrecoverable_line_order'],
      1,
    );
    expect(
      result.diagnostics.vendorReviewStatus,
      'vendor_missing_unrecoverable_line_order',
    );
    expect(
      contract['vendorReviewStatus'],
      'vendor_missing_unrecoverable_line_order',
    );
    expect(
      (contract['vendorReviewDiagnostics'] as Map)['lineSequenceStatus'],
      'summary_before_items',
    );
    expect(contract.toString(), isNot(contains('SERVICE ITEM')));
    expect(contract.toString(), isNot(contains('12.34')));
  });
}
