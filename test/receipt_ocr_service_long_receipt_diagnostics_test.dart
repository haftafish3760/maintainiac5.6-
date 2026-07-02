import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/receipts/receipt_processing_contract.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_ocr_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('damaged merchant header recovers receipt structure with review', () {
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
    final diagnostics = result.diagnostics;
    final contract = handoff.privacySafeParserHandoffContract;

    expect(handoff.vendorLines, isEmpty);
    expect(handoff.dateLines.single.text, '06/12/2026');
    expect(handoff.itemLines.single.text, 'PVC ELBOW 1/2 IN 2.49');
    expect(handoff.primaryTotalAmount, 2.69);
    expect(handoff.lineSequenceStatus, 'expected_order');
    expect(handoff.hasRecoverableMissingVendorHeader, isTrue);
    expect(handoff.headerRecoveryStatus, 'missing_vendor_recoverable');
    expect(
      handoff.headerRecoveryLabel,
      'Receipt store header needs review, but date, items, and total are usable.',
    );
    expect(handoff.parserReadinessStatus, 'needs_vendor_review');
    expect(handoff.downstreamReadinessStatus, 'receipt_header_needs_review');
    expect(handoff.receiptStructureStatus, 'recoverable_missing_vendor');
    expect(handoff.parserMissingFieldCounts['vendor_missing'], 1);
    expect(handoff.parserReviewTaskCounts['missing_vendor_recoverable'], 1);
    expect(
      handoff.parserTaskCounts['missing_vendor_recoverable'],
      greaterThan(0),
    );
    expect(handoff.counts['recoverableMissingVendorCount'], 1);
    expect(handoff.counts['headerRecovery_missing_vendor_recoverable'], 1);
    expect(
      handoff.merchantIndependentStructureStatus,
      'generic_material_receipt_ready',
    );
    expect(contract['headerRecoveryStatus'], 'missing_vendor_recoverable');
    expect(
      (contract['headerRecoveryDiagnostics'] as Map)['recoverable'],
      isTrue,
    );
    expect(
      contract['missingVendorRecoveryEvidenceLineIds'],
      containsAll([
        'ocr_line_000_date',
        'ocr_line_001_item',
        'ocr_line_003_total',
      ]),
    );
    expect(diagnostics.headerRecoveryStatus, 'missing_vendor_recoverable');
    expect(diagnostics.ocrReceiptStructureStatus, 'recoverable_missing_vendor');
    expect(
      diagnostics
          .receiptTotalsCoverageEvidenceDiagnostics['headerRecoveryStatus'],
      'missing_vendor_recoverable',
    );
    expect(
      diagnostics.parserSignalSummaryLabel,
      contains('header missing_vendor_recoverable'),
    );
    expect(
      diagnostics.parserSignalSummaryLabel,
      contains('parser readiness needs_vendor_review'),
    );
    expect(contract.toString(), isNot(contains('PVC ELBOW')));
    expect(contract.toString(), isNot(contains('2.69')));
  });

  test(
    'address and phone rows are not promoted to vendor on damaged headers',
    () {
      const result = ReceiptOcrResult(
        rawText: '''
6400 BRODIE LANE
AUSTIN TX 78745 (512) 895-5560
06/12/2026
PVC ELBOW 1/2 IN 2.49
TAX 0.20
TOTAL 2.69
''',
        parserText: '''
6400 BRODIE LANE
AUSTIN TX 78745 (512) 895-5560
06/12/2026
PVC ELBOW 1/2 IN 2.49
TAX 0.20
TOTAL 2.69
''',
        textByAttachmentId: {'photo-1': 'private receipt text omitted'},
        source: ReceiptProcessingSource.photo,
      );

      final handoff = result.parserHandoff;
      final addressSignal = result.parserLineSignals.firstWhere(
        (signal) => signal.text == '6400 BRODIE LANE',
      );
      final contactSignal = result.parserLineSignals.firstWhere(
        (signal) => signal.text == 'AUSTIN TX 78745 (512) 895-5560',
      );

      expect(result.vendorCandidateLines, isEmpty);
      expect(addressSignal.kind, ReceiptOcrParserLineKind.receiptMetadata);
      expect(contactSignal.kind, ReceiptOcrParserLineKind.receiptMetadata);
      expect(addressSignal.traits, contains('address_or_contact_metadata'));
      expect(contactSignal.traits, contains('address_or_contact_metadata'));
      expect(handoff.metadataLines, hasLength(2));
      expect(handoff.addressContactMetadataLineCount, 2);
      expect(
        handoff.addressContactMetadataLineIds,
        containsAll(['ocr_line_000_metadata', 'ocr_line_001_metadata']),
      );
      expect(handoff.headerRecoveryStatus, 'missing_vendor_recoverable');
      expect(
        handoff.vendorReviewStatus,
        'vendor_missing_recoverable_address_contact_suppressed',
      );
      expect(
        handoff.vendorReviewLabel,
        'Store name needs review; address or phone rows were kept as metadata.',
      );
      expect(handoff.receiptStructureStatus, 'recoverable_missing_vendor');
      expect(handoff.parserReadinessStatus, 'needs_vendor_review');
      expect(handoff.downstreamReadinessStatus, 'receipt_header_needs_review');
      expect(handoff.parserMissingFieldCounts['vendor_missing'], 1);
      expect(
        handoff
            .parserReviewTaskCounts['vendor_missing_recoverable_address_contact_suppressed'],
        1,
      );
      expect(
        handoff.parserTaskCounts['missing_vendor_recoverable'],
        greaterThan(0),
      );
      expect(
        handoff.missingVendorRecoveryEvidenceLineIds,
        containsAll([
          'ocr_line_002_date',
          'ocr_line_003_item',
          'ocr_line_005_total',
        ]),
      );
      expect(
        result.diagnostics.parserSignalSummaryLabel,
        contains('header missing_vendor_recoverable'),
      );
      expect(
        result.diagnostics.vendorReviewStatus,
        'vendor_missing_recoverable_address_contact_suppressed',
      );
      expect(
        result
            .diagnostics
            .vendorReviewDiagnostics['addressContactMetadataLineCount'],
        2,
      );
      expect(
        result.diagnostics.parserSignalSummaryLabel,
        contains(
          'vendor review vendor_missing_recoverable_address_contact_suppressed',
        ),
      );
      expect(
        handoff.privacySafeParserHandoffContract['vendorReviewStatus'],
        'vendor_missing_recoverable_address_contact_suppressed',
      );
      expect(
        (handoff.privacySafeParserHandoffContract['vendorReviewDiagnostics']
            as Map)['addressContactMetadataLineCount'],
        2,
      );
      expect(
        handoff.privacySafeParserHandoffContract.toString(),
        isNot(contains('BRODIE')),
      );
      expect(
        handoff.privacySafeParserHandoffContract.toString(),
        isNot(contains('895-5560')),
      );
    },
  );
}
