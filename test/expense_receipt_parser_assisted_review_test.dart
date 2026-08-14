import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';
import 'package:maintaniac/shared/receipts/receipt_processing_contract.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

void main() {
  test(
    'routes footer-seen subtotal receipt without final total to OCR review',
    () {
      final parsed = parseExpenseReceiptText('''
COUNTY LINE MARKET
06/20/2026
SHOP TOWELS 8.97
CASE WATER 5.99
SUBTOTAL 14.96
TAX 1.05
THANK YOU FOR SHOPPING
VISIT COUNTYLINE.EXAMPLE
''');

      expect(parsed.lines, hasLength(2));
      expect(parsed.enteredSubtotal, 14.96);
      expect(parsed.enteredTax, 1.05);
      expect(parsed.enteredTotal, closeTo(16.01, .001));
      expect(
        parsed.warnings,
        contains(
          'The final printed total was not found. Check the working total before saving.',
        ),
      );
      expect(
        parsed.diagnostics.parserTaskCount(
          'receipt_footer_seen_final_total_missing_review',
        ),
        1,
      );
      expect(
        parsed.diagnostics.parserTaskCount(
          'receipt_possible_lower_section_missing',
        ),
        0,
      );
      expect(parsed.diagnostics.hasParserPossibleLowerSectionMissing, isFalse);
      expect(parsed.diagnostics.shouldSuggestLowerReceiptSection, isFalse);
      expect(
        parsed.diagnostics.missingBottomTotalsEvidenceCode,
        'local_text_footer_seen_final_total_missing',
      );
      expect(
        parsed.diagnostics.missingBottomTotalsLocalEvidenceReviewLabel,
        contains('final total is still missing'),
      );
    },
  );

  test(
    'routes quality action retake evidence into assisted review guidance',
    () {
      final sourceHandoff = ReceiptOcrSourceHandoffSummary.fromAttachments([
        ReceiptAttachmentRecord(
          id: 'photo-1',
          path: '/tmp/receipt.jpg',
          kind: ReceiptAttachmentKind.photo,
          dataSaverLevel: ReceiptDataSaverLevel.balanced,
          createdAt: DateTime(2026, 7, 1),
          riskFlags: const [
            'ocr_source_quality_action_retake_recommended_continue_allowed',
            'ocr_source_quality_family_retake',
          ],
        ),
      ]);
      final parsed = parseExpenseReceiptOcrResult(
        ReceiptOcrResult(
          rawText: '''
WALMART
06/12/2026
GENERAL MDSE 17.48
TOTAL 17.48
''',
          parserText: '''
WALMART
06/12/2026
GENERAL MDSE 17.48
TOTAL 17.48
''',
          textByAttachmentId: const {'photo-1': 'private receipt text omitted'},
          source: ReceiptProcessingSource.photo,
          sourceHandoffSummary: sourceHandoff,
        ),
        capability: const ReceiptDeviceCapability.highCapacity(),
        parserDepth: ReceiptParserDepth.lineItems,
      );

      expect(parsed.diagnostics.hasOcrPhotoQualityActionReview, isTrue);
      expect(parsed.diagnostics.hasOcrPhotoRetakeActionReview, isTrue);
      expect(
        parsed.diagnostics.ocrPhotoQualityActionReviewCode,
        'retake_photo_recommended',
      );
      expect(
        parsed.diagnostics.ocrPhotoQualityActionReviewLabel,
        'Retake recommended',
      );
      expect(parsed.diagnostics.parserTaskSummaryLabel, 'Retake recommended');
      expect(
        parsed.diagnostics.ocrPhotoQualityActionReviewActionLabel,
        'Retake or confirm readable',
      );
      expect(
        parsed.diagnostics.ocrPhotoQualityActionReviewInstruction,
        contains('every line is readable'),
      );
    },
  );

  test(
    'bottom continuation evidence outranks crop and retake review actions',
    () {
      final sourceHandoff = ReceiptOcrSourceHandoffSummary.fromAttachments([
        ReceiptAttachmentRecord(
          id: 'photo-1',
          path: '/tmp/receipt.jpg',
          kind: ReceiptAttachmentKind.photo,
          dataSaverLevel: ReceiptDataSaverLevel.balanced,
          createdAt: DateTime(2026, 7, 1),
          documentSignals: const [
            'receipt_coverage_bottom_edge_and_totals_missing_together',
            'receipt_coverage_contract_bottom_edge_totals_missing_use_ghost_overlap',
          ],
          riskFlags: const [
            'ocr_source_quality_action_crop_or_retake_then_next',
            'ocr_source_quality_family_review',
          ],
        ),
      ]);
      final parsed = parseExpenseReceiptOcrResult(
        ReceiptOcrResult(
          rawText: '''
WALMART
06/12/2026
GENERAL MDSE 17.48
''',
          parserText: '''
WALMART
06/12/2026
GENERAL MDSE 17.48
''',
          textByAttachmentId: const {'photo-1': 'private receipt text omitted'},
          source: ReceiptProcessingSource.photo,
          sourceHandoffSummary: sourceHandoff,
        ),
        capability: const ReceiptDeviceCapability.highCapacity(),
        parserDepth: ReceiptParserDepth.lineItems,
      );

      expect(parsed.diagnostics.hasOcrPhotoQualityActionReview, isTrue);
      expect(parsed.diagnostics.hasOcrPhotoCropOrRetakeActionReview, isTrue);
      expect(
        parsed.diagnostics.hasOcrSourceMissingBottomCoverageEvidence,
        isTrue,
      );
      expect(
        parsed.diagnostics.ocrPhotoQualityActionReviewCode,
        'add_bottom_section_first',
      );
      expect(
        parsed.diagnostics.ocrPhotoQualityActionReviewLabel,
        'Add bottom receipt section first',
      );
      expect(
        parsed.diagnostics.parserTaskSummaryLabel,
        'Add bottom receipt section first',
      );
      expect(
        parsed.diagnostics.ocrPhotoQualityActionReviewActionLabel,
        'Add bottom section',
      );
    },
  );

  test('routes saved bottom photo quality into assisted review guidance', () {
    final sourceHandoff = ReceiptOcrSourceHandoffSummary.fromAttachments([
      ReceiptAttachmentRecord(
        id: 'photo-1',
        path: '/tmp/receipt.jpg',
        kind: ReceiptAttachmentKind.photo,
        dataSaverLevel: ReceiptDataSaverLevel.balanced,
        createdAt: DateTime(2026, 7, 1),
        riskFlags: const [
          'ocr_source_saved_photo_bottom_soft',
          'ocr_source_action_check_bottom_or_retake',
        ],
      ),
    ]);
    final parsed = parseExpenseReceiptOcrResult(
      ReceiptOcrResult(
        rawText: '''
LOWE'S
06/12/2026
PVC GLUE 7.99
TOTAL 7.99
''',
        parserText: '''
LOWE'S
06/12/2026
PVC GLUE 7.99
TOTAL 7.99
''',
        textByAttachmentId: const {'photo-1': 'private receipt text omitted'},
        source: ReceiptProcessingSource.photo,
        sourceHandoffSummary: sourceHandoff,
      ),
      capability: const ReceiptDeviceCapability.highCapacity(),
      parserDepth: ReceiptParserDepth.lineItems,
    );

    expect(parsed.diagnostics.hasOcrPhotoQualityActionReview, isTrue);
    expect(parsed.diagnostics.hasOcrSavedBottomQualityReview, isTrue);
    expect(
      parsed.diagnostics.ocrSourceQualityReviewStatus,
      'saved_bottom_quality_review',
    );
    expect(
      parsed.diagnostics.ocrSourceQualityReviewAction,
      'check_bottom_or_add_photo',
    );
    expect(
      parsed.diagnostics.parserReviewRootCauseCode,
      'camera_source_quality',
    );
    expect(
      parsed.diagnostics.parserReviewRootCauseLabel,
      'Camera/source photo quality',
    );
    expect(
      parsed.diagnostics.parserReviewRootCauseActionLabel,
      'Check bottom or add photo',
    );
    expect(
      parsed.diagnostics.parserReviewRootCauseInstruction,
      contains('bottom receipt lines may be dark or soft'),
    );
    expect(
      parsed.diagnostics.ocrPhotoQualityActionReviewCode,
      'check_bottom_photo_quality',
    );
    expect(
      parsed.diagnostics.ocrPhotoQualityActionReviewActionLabel,
      'Check bottom or add photo',
    );
    expect(
      parsed.diagnostics.parserTaskSummaryLabel,
      'Check bottom receipt section',
    );
    expect(
      parsed.diagnostics.ocrPhotoQualityActionReviewInstruction,
      contains('bottom receipt lines may be dark or soft'),
    );
  });

  test(
    'routes out-of-order OCR sections into long-receipt review guidance',
    () {
      final sourceHandoff = ReceiptOcrSourceHandoffSummary.fromAttachments([
        ReceiptAttachmentRecord(
          id: 'section-order-source',
          path: '',
          kind: ReceiptAttachmentKind.emailText,
          dataSaverLevel: ReceiptDataSaverLevel.balanced,
          createdAt: DateTime(2026, 7, 6),
          importedText: 'STORE\nTOTAL 14.50',
          documentSignals: const [
            'receipt_section_order_expected_order_invalid',
            'receipt_section_order_review_required',
          ],
          riskFlags: const ['ocr_source_section_order_review_required'],
        ),
      ]);
      final parsed = parseExpenseReceiptOcrResult(
        ReceiptOcrResult(
          rawText: '''
LOWE'S
06/12/2026
PVC PIPE 14.50
TOTAL 14.50
''',
          parserText: '''
LOWE'S
06/12/2026
PVC PIPE 14.50
TOTAL 14.50
''',
          textByAttachmentId: {'photo-1': 'private receipt text omitted'},
          source: ReceiptProcessingSource.photo,
          sourceHandoffSummary: sourceHandoff,
          parserLineSourceLocations: [
            ReceiptOcrParserLineLocation(
              sectionNumber: 2,
              sectionLineNumber: 1,
            ),
            ReceiptOcrParserLineLocation(
              sectionNumber: 2,
              sectionLineNumber: 2,
            ),
            ReceiptOcrParserLineLocation(
              sectionNumber: 1,
              sectionLineNumber: 1,
            ),
            ReceiptOcrParserLineLocation(
              sectionNumber: 1,
              sectionLineNumber: 2,
            ),
          ],
        ),
        capability: const ReceiptDeviceCapability.highCapacity(),
        parserDepth: ReceiptParserDepth.lineItems,
      );

      expect(
        parsed.diagnostics.ocrSourceSectionContinuityStatus,
        'out_of_order_sections',
      );
      expect(parsed.diagnostics.ocrSourceSectionOrderSignalCounts, {
        'receipt_section_order_expected_order_invalid': 1,
        'receipt_section_order_review_required': 1,
        'ocr_source_section_order_review_required': 1,
      });
      expect(
        parsed.diagnostics.ocrSourceSectionOrderReviewStatus,
        'receipt_section_order_review_required',
      );
      expect(parsed.diagnostics.ocrSourceSectionOrderFailedPairStatus, '');
      expect(
        parsed.diagnostics.receiptSequenceReviewStatus,
        'section_order_review_needed',
      );
      expect(
        parsed.diagnostics.receiptSequenceReviewLabel,
        'Check receipt photo order',
      );
      expect(
        parsed.diagnostics.parserReviewRootCauseCode,
        'capture_coverage_or_long_receipt',
      );
      expect(
        parsed.diagnostics.parserReviewRootCauseActionLabel,
        'Check receipt photo order',
      );
      expect(
        parsed.diagnostics.parserReviewRootCauseInstruction,
        contains('Review the receipt photos from top to bottom before saving'),
      );
    },
  );

  test('summarizes OCR required field issues by field', () {
    const diagnostics = ExpenseReceiptParseDiagnostics(
      ocrRequiredFieldStatusCounts: {
        'vendor_needs_review': 1,
        'date_ready': 1,
        'subtotal_missing': 1,
        'tax_ready': 1,
        'total_missing': 1,
        'item_price_needs_review': 1,
        'required_missing_total': 2,
        'required_needs_review_total': 2,
      },
    );

    expect(diagnostics.ocrRequiredFieldIssueLabels, [
      'missing subtotal',
      'missing total',
      'check store',
      'check item prices',
    ]);
    expect(
      diagnostics.ocrRequiredFieldIssueSummaryLabel,
      'missing subtotal, missing total, check store, +1 more',
    );
    expect(diagnostics.parserReviewRootCauseCode, 'ocr_required_fields');
    expect(
      diagnostics.parserReviewRootCauseInstruction,
      contains('missing subtotal, missing total, check store'),
    );
  });

  test(
    'accepts reconciled total-only fuel receipt without lower section review',
    () {
      final parsed = parseExpenseReceiptText('''
CORNER MART #42
06/12/2026
PUMP 07
UNLEADED FUEL 35.00
TOTAL 35.00
CARD 35.00
''');

      expect(parsed.merchantName, 'Corner Mart 42');
      expect(parsed.lines, hasLength(1));
      expect(parsed.enteredSubtotal, isNull);
      expect(parsed.enteredTax, isNull);
      expect(parsed.enteredTotal, 35.00);
      expect(parsed.diagnostics.hasExplicitSubtotal, isFalse);
      expect(parsed.diagnostics.hasExplicitTax, isFalse);
      expect(parsed.diagnostics.hasExplicitTotal, isTrue);
      expect(
        parsed.warnings,
        isNot(
          contains('Receipt total found, but subtotal and tax need review.'),
        ),
      );
      expect(
        parsed.warnings,
        isNot(
          contains(
            'Subtotal and total were not found. If this is a long receipt, add the lower receipt section before saving; otherwise enter the total manually.',
          ),
        ),
      );
      expect(parsed.diagnostics.parserTaskCount('receipt_total_only_ready'), 1);
      expect(parsed.diagnostics.parserTaskCount('fuel_line_ready'), 0);
      expect(parsed.diagnostics.parserTaskCount('fuel_detail_needs_review'), 1);
      expect(
        parsed.diagnostics.parserTaskCount('fuel_quantity_needs_review'),
        1,
      );
      expect(
        parsed.diagnostics.parserTaskCount(
          'receipt_total_only_line_math_review',
        ),
        0,
      );
      expect(parsed.diagnostics.hasParserPossibleLowerSectionMissing, isFalse);
      expect(parsed.diagnostics.shouldSuggestLowerReceiptSection, isFalse);
      expect(parsed.diagnostics.receiptSequenceReviewStatus, 'sequence_ready');
      expect(
        parsed.diagnostics.receiptSequenceReviewLabel,
        'Receipt line order ready',
      );
      expect(
        parsed.fieldConfidences['receiptMath']?.reason,
        contains('Receipt total matches parsed line amounts'),
      );
    },
  );
}
