import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/receipts/receipt_line_models.dart';
import 'package:maintaniac/shared/receipts/receipt_processing_contract.dart';

void main() {
  test(
    'selected receipt line bundle keeps local totals for downstream flows',
    () {
      const businessLine = ReceiptLineDraft(
        kind: ReceiptLineKind.inventory,
        description: 'Private job copper elbow',
        receiptLineId: 'RCP-9-L1',
        subtotal: 12,
        taxRate: .08,
        businessUse: 'business',
        rawReceiptText: 'LOWES PRIVATE JOB COPPER ELBOW 12.00',
        proofLineReferenceLabel: 'Line 1',
        clientProofDefaultVisibility:
            ReceiptLineClientProofVisibility.reviewForClientProof,
        sourceReceiptSectionLabel: 'Photo receipt RCP-9',
      );
      const splitLine = ReceiptLineDraft(
        kind: ReceiptLineKind.expense,
        description: 'Shared cleaner',
        receiptLineId: 'RCP-9-L2',
        subtotal: 5,
        taxRate: .08,
        businessUse: 'split',
        businessPercent: .5,
        rawReceiptText: 'LOWES SHARED CLEANER 5.00',
        proofLineReferenceLabel: 'Line 2',
        clientProofDefaultVisibility:
            ReceiptLineClientProofVisibility.reviewBeforeClientShare,
      );
      const personalLine = ReceiptLineDraft(
        kind: ReceiptLineKind.expense,
        description: 'Personal snack',
        receiptLineId: 'RCP-9-L3',
        subtotal: 3,
        businessUse: 'personal',
        rawReceiptText: 'LOWES PERSONAL SNACK 3.00',
        proofLineReferenceLabel: 'Line 3',
        clientProofDefaultVisibility:
            ReceiptLineClientProofVisibility.redactByDefault,
      );

      final bundle = ReceiptLineSelectionBundle.fromDrafts(
        receiptId: 'RCP-9',
        purpose: ReceiptLineSelectionPurpose.invoice,
        sourceLines: const [businessLine, splitLine, personalLine],
      );

      expect(bundle.selectedLineCount, 2);
      expect(bundle.excludedLineCount, 1);
      expect(bundle.reviewBeforeShareCount, 2);
      expect(bundle.redactedByDefaultCount, 0);
      expect(bundle.selectedSubtotal, 17);
      expect(bundle.selectedTax, closeTo(1.36, .001));
      expect(bundle.selectedTotal, closeTo(18.36, .001));

      final local = bundle.toLocalMap();
      expect(local['purpose'], 'invoice');
      expect(local['selectedLineCount'], 2);
      expect(local['selectedSubtotal'], 17);
      expect(local['selectedTax'], closeTo(1.36, .001));
      expect(local['selectedTotal'], closeTo(18.36, .001));
      expect(local.toString(), contains('lineSubtotal'));
      expect(local.toString(), contains('RCP-9-L1'));
    },
  );

  test(
    'selected receipt line privacy map exposes references without content',
    () {
      const businessLine = ReceiptLineDraft(
        kind: ReceiptLineKind.inventory,
        description: 'Secret customer material',
        receiptLineId: 'RCP-10-L1',
        subtotal: 45.99,
        taxRate: .07,
        businessUse: 'business',
        rawReceiptText: 'HOME DEPOT SECRET CUSTOMER MATERIAL 45.99',
        proofLineReferenceLabel: 'Line 1',
        clientProofDefaultVisibility:
            ReceiptLineClientProofVisibility.reviewForClientProof,
      );
      const personalLine = ReceiptLineDraft(
        kind: ReceiptLineKind.expense,
        description: 'Private personal item',
        receiptLineId: 'RCP-10-L2',
        subtotal: 8.50,
        businessUse: 'personal',
        rawReceiptText: 'HOME DEPOT PRIVATE PERSONAL ITEM 8.50',
        proofLineReferenceLabel: 'Line 2',
        clientProofDefaultVisibility:
            ReceiptLineClientProofVisibility.redactByDefault,
      );

      final bundle = ReceiptLineSelectionBundle.fromDrafts(
        receiptId: 'RCP-10',
        purpose: ReceiptLineSelectionPurpose.clientProof,
        sourceLines: const [businessLine, personalLine],
        includeLine: (line) => line.isBusinessUse,
      );

      final safe = bundle.toPrivacySafeMap();
      expect(safe['purpose'], 'clientProof');
      expect(safe['selectedLineCount'], 1);
      expect(safe['totalSourceLineCount'], 2);
      expect(safe['excludedLineCount'], 1);
      expect(safe['hasSelectedSubtotal'], isTrue);
      expect(safe['hasSelectedTotal'], isTrue);
      expect(safe.toString(), contains('RCP-10-L1'));
      expect(safe.toString(), contains('Line 1'));
      expect(safe.toString(), isNot(contains('HOME DEPOT')));
      expect(safe.toString(), isNot(contains('Secret customer material')));
      expect(safe.toString(), isNot(contains('Private personal item')));
      expect(safe.toString(), isNot(contains('45.99')));
      expect(safe.toString(), isNot(contains('8.50')));
    },
  );

  test(
    'client proof redaction plan separates visible review and hidden lines',
    () {
      const businessLine = ReceiptLineDraft(
        kind: ReceiptLineKind.inventory,
        description: 'Secret customer material',
        receiptLineId: 'RCP-12-L1',
        subtotal: 21.49,
        businessUse: 'business',
        rawReceiptText: 'HOME DEPOT SECRET CUSTOMER MATERIAL 21.49',
        proofLineReferenceLabel: 'Line 1',
        clientProofDefaultVisibility:
            ReceiptLineClientProofVisibility.reviewForClientProof,
      );
      const personalLine = ReceiptLineDraft(
        kind: ReceiptLineKind.expense,
        description: 'Private household item',
        receiptLineId: 'RCP-12-L2',
        subtotal: 9.99,
        businessUse: 'personal',
        rawReceiptText: 'HOME DEPOT PRIVATE HOUSEHOLD ITEM 9.99',
        proofLineReferenceLabel: 'Line 2',
        clientProofDefaultVisibility:
            ReceiptLineClientProofVisibility.redactByDefault,
      );

      final bundle = ReceiptLineSelectionBundle.fromDrafts(
        receiptId: 'RCP-12',
        purpose: ReceiptLineSelectionPurpose.clientProof,
        sourceLines: const [businessLine, personalLine],
      );

      final plan = ReceiptClientProofRedactionPlan.fromBundle(bundle);
      final safe = plan.toPrivacySafeMap();

      expect(plan.visibleLineCount, 0);
      expect(plan.reviewLineCount, 1);
      expect(plan.hiddenLineCount, 1);
      expect(plan.needsReviewBeforeShare, isTrue);
      expect(plan.hasHiddenLines, isTrue);
      expect(plan.canShareNow, isFalse);
      expect(safe['purpose'], 'clientProof');
      expect(safe['totalSourceLineCount'], 2);
      expect(safe['reviewLineCount'], 1);
      expect(safe['hiddenLineCount'], 1);
      expect(safe.toString(), contains('Line 1'));
      expect(safe.toString(), contains('Excluded line 1'));
      expect(safe.toString(), isNot(contains('HOME DEPOT')));
      expect(safe.toString(), isNot(contains('Secret customer material')));
      expect(safe.toString(), isNot(contains('Private household item')));
      expect(safe.toString(), isNot(contains('21.49')));
      expect(safe.toString(), isNot(contains('9.99')));
    },
  );

  test(
    'client proof review summary reports share readiness without content',
    () {
      const visibleLine = ReceiptLineDraft(
        kind: ReceiptLineKind.inventory,
        description: 'Visible part',
        receiptLineId: 'RCP-13-L1',
        subtotal: 10,
        businessUse: 'business',
        rawReceiptText: 'PRIVATE STORE VISIBLE PART 10.00',
        proofLineReferenceLabel: 'Line 1',
        clientProofDefaultVisibility:
            ReceiptLineClientProofVisibility.reviewBeforeClientShare,
        sourceReceiptSectionLabel: 'Photo 1',
      );
      const hiddenLine = ReceiptLineDraft(
        kind: ReceiptLineKind.expense,
        description: 'Hidden personal part',
        receiptLineId: 'RCP-13-L2',
        subtotal: 3,
        businessUse: 'personal',
        rawReceiptText: 'PRIVATE STORE HIDDEN PERSONAL 3.00',
        proofLineReferenceLabel: 'Line 2',
        clientProofDefaultVisibility:
            ReceiptLineClientProofVisibility.redactByDefault,
        sourceReceiptSectionLabel: 'Photo 2',
      );

      final bundle = ReceiptLineSelectionBundle.fromDrafts(
        receiptId: 'RCP-13',
        purpose: ReceiptLineSelectionPurpose.clientProof,
        sourceLines: const [visibleLine, hiddenLine],
      );
      final plan = ReceiptClientProofRedactionPlan.fromBundle(bundle);
      final summary = ReceiptClientProofReviewSummary.fromPlan(plan);
      final safe = summary.toPrivacySafeMap();

      expect(summary.status, 'review_required');
      expect(summary.visibleLineCount, 0);
      expect(summary.hiddenLineCount, 1);
      expect(summary.reviewLineCount, 1);
      expect(summary.sourceSectionCount, 1);
      expect(summary.needsManualReview, isTrue);
      expect(summary.readyToShare, isFalse);
      expect(summary.recommendedNextAction, 'review_lines_before_client_share');
      expect(safe['hasHiddenLines'], isTrue);
      expect(safe['hasMultipleSourceSections'], isFalse);
      expect(safe.toString(), isNot(contains('PRIVATE STORE')));
      expect(safe.toString(), isNot(contains('Visible part')));
      expect(safe.toString(), isNot(contains('Hidden personal part')));
      expect(safe.toString(), isNot(contains('10.00')));
      expect(safe.toString(), isNot(contains('3.00')));
    },
  );

  test(
    'client proof image review plan groups section counts without content',
    () {
      const firstPhotoLine = ReceiptLineDraft(
        kind: ReceiptLineKind.inventory,
        description: 'Invoice material',
        receiptLineId: 'RCP-14-L1',
        subtotal: 19,
        businessUse: 'business',
        rawReceiptText: 'PRIVATE STORE INVOICE MATERIAL 19.00',
        proofLineReferenceLabel: 'Line 1',
        clientProofDefaultVisibility:
            ReceiptLineClientProofVisibility.reviewBeforeClientShare,
        sourceReceiptSectionLabel: 'Photo 1',
      );
      const secondPhotoLine = ReceiptLineDraft(
        kind: ReceiptLineKind.inventory,
        description: 'Safe visible material',
        receiptLineId: 'RCP-14-L2',
        subtotal: 11,
        businessUse: 'business',
        rawReceiptText: 'PRIVATE STORE SAFE MATERIAL 11.00',
        proofLineReferenceLabel: 'Line 2',
        clientProofDefaultVisibility: '',
        sourceReceiptSectionLabel: 'Photo 2',
      );
      const hiddenSecondPhotoLine = ReceiptLineDraft(
        kind: ReceiptLineKind.expense,
        description: 'Hidden private item',
        receiptLineId: 'RCP-14-L3',
        subtotal: 4,
        businessUse: 'personal',
        rawReceiptText: 'PRIVATE STORE HIDDEN ITEM 4.00',
        proofLineReferenceLabel: 'Line 3',
        clientProofDefaultVisibility:
            ReceiptLineClientProofVisibility.redactByDefault,
        sourceReceiptSectionLabel: 'Photo 2',
      );

      final bundle = ReceiptLineSelectionBundle.fromDrafts(
        receiptId: 'RCP-14',
        purpose: ReceiptLineSelectionPurpose.clientProof,
        sourceLines: const [
          firstPhotoLine,
          secondPhotoLine,
          hiddenSecondPhotoLine,
        ],
        includeLine: (_) => true,
      );
      final redactionPlan = ReceiptClientProofRedactionPlan.fromBundle(bundle);
      final imagePlan = ReceiptClientProofImageReviewPlan.fromRedactionPlan(
        redactionPlan,
      );
      final safe = imagePlan.toPrivacySafeMap();

      expect(imagePlan.sectionCount, 2);
      expect(imagePlan.visibleSectionCount, 1);
      expect(imagePlan.hiddenSectionCount, 1);
      expect(imagePlan.reviewSectionCount, 1);
      expect(imagePlan.needsManualImageReview, isTrue);
      expect(imagePlan.needsRedactionPreview, isTrue);
      expect(imagePlan.unassignedLineCount, 0);
      expect(imagePlan.sections.first.sourceReceiptSectionLabel, 'Photo 1');
      expect(imagePlan.sections.first.reviewLineCount, 1);
      expect(imagePlan.sections.last.sourceReceiptSectionLabel, 'Photo 2');
      expect(imagePlan.sections.last.visibleLineCount, 1);
      expect(imagePlan.sections.last.hiddenLineCount, 1);
      expect(safe.toString(), isNot(contains('PRIVATE STORE')));
      expect(safe.toString(), isNot(contains('Invoice material')));
      expect(safe.toString(), isNot(contains('Safe visible material')));
      expect(safe.toString(), isNot(contains('Hidden private item')));
      expect(safe.toString(), isNot(contains('19.00')));
      expect(safe.toString(), isNot(contains('11.00')));
      expect(safe.toString(), isNot(contains('4.00')));
    },
  );

  test('client proof privacy maps redact unsafe source section labels', () {
    const line = ReceiptLineDraft(
      kind: ReceiptLineKind.inventory,
      description: 'Private job material',
      receiptLineId: 'RCP-15-L1',
      subtotal: 18,
      businessUse: 'business',
      rawReceiptText: 'PRIVATE STORE JOB MATERIAL 18.00',
      proofLineReferenceLabel: 'Line 1',
      clientProofDefaultVisibility:
          ReceiptLineClientProofVisibility.reviewBeforeClientShare,
      sourceReceiptSectionLabel: 'PRIVATE STORE COUNTER 18.00',
    );
    final bundle = ReceiptLineSelectionBundle.fromDrafts(
      receiptId: 'RCP-15',
      purpose: ReceiptLineSelectionPurpose.clientProof,
      sourceLines: const [line],
      includeLine: (_) => true,
    );
    final redactionPlan = ReceiptClientProofRedactionPlan.fromBundle(bundle);
    final imagePlan = ReceiptClientProofImageReviewPlan.fromRedactionPlan(
      redactionPlan,
    );

    expect(
      line.privacySafeProofReference['sourceReceiptSectionLabel'],
      'source_section',
    );
    expect(bundle.toPrivacySafeMap().toString(), contains('source_section'));
    expect(
      redactionPlan.toPrivacySafeMap().toString(),
      contains('source_section'),
    );
    expect(imagePlan.toPrivacySafeMap().toString(), contains('source_section'));
    expect(bundle.toPrivacySafeMap().toString(), isNot(contains('PRIVATE')));
    expect(
      redactionPlan.toPrivacySafeMap().toString(),
      isNot(contains('PRIVATE')),
    );
    expect(imagePlan.toPrivacySafeMap().toString(), isNot(contains('18.00')));
  });
}
