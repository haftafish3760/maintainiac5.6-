import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/receipts/receipt_processing_contract.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_ocr_service.dart';

void main() {
  test(
    'ocr parser handoff exposes local line drafts without leaking text to summaries',
    () {
      const result = ReceiptOcrResult(
        rawText: '''
LOWE'S
06/12/2026
23536 OATEY 14-OZ PLUMBERS PUTT 2.99
SUBTOTAL 2.99
TAX 0.25
TOTAL 3.24
MERCH/GIFT CARD 3.24
STORE 2513 TERMINAL 18
''',
        parserText: '''
LOWE'S
06/12/2026
23536 OATEY 14-OZ PLUMBERS PUTT 2.99
SUBTOTAL 2.99
TAX 0.25
TOTAL 3.24
MERCH/GIFT CARD 3.24
STORE 2513 TERMINAL 18
''',
        textByAttachmentId: {'photo-1': 'private receipt text omitted'},
        source: ReceiptProcessingSource.photo,
      );

      final handoff = result.parserHandoff;
      final itemDraft = handoff.itemLineDrafts.single;
      final readyDraft = handoff.parserReadyItemLineDrafts.single;
      final localMap = itemDraft.toLocalReviewMap();
      final safeMap = itemDraft.toPrivacySafeSummaryMap();

      expect(itemDraft.stableLineId, 'ocr_line_002_item');
      expect(itemDraft.lineNumber, 3);
      expect(itemDraft.lineLabel, 'Line 3');
      expect(itemDraft.proofLineReferenceLabel, 'Line 3');
      expect(itemDraft.role, 'item');
      expect(itemDraft.parserBucket, 'item_ready');
      expect(itemDraft.expenseFamily, ReceiptOcrParserExpenseFamily.materials);
      expect(itemDraft.expenseFamilyToken, 'materials');
      expect(itemDraft.parserHint, 'materials_item_price');
      expect(itemDraft.amount, 2.99);
      expect(itemDraft.needsReview, isFalse);
      expect(itemDraft.isItem, isTrue);
      expect(itemDraft.isInventoryPrepCandidate, isTrue);
      expect(itemDraft.isMaterialCandidate, isTrue);
      expect(readyDraft.stableLineId, itemDraft.stableLineId);
      expect(handoff.reviewItemLineDrafts, isEmpty);
      expect(
        handoff.lineDraftsById[itemDraft.stableLineId]?.stableLineId,
        itemDraft.stableLineId,
      );
      expect(handoff.itemAmountsByLineId[itemDraft.stableLineId], 2.99);
      expect(
        handoff.itemTextByLineId[itemDraft.stableLineId],
        '23536 OATEY 14-OZ PLUMBERS PUTT 2.99',
      );
      expect(localMap['text'], contains('OATEY'));
      expect(localMap['amount'], 2.99);
      expect(localMap['expenseFamily'], 'materials');
      expect(localMap['parserHint'], 'materials_item_price');
      expect(safeMap['role'], 'item');
      expect(safeMap['parserBucket'], 'item_ready');
      expect(safeMap['confidenceBucket'], 'good');
      expect(safeMap['expenseFamily'], 'materials');
      expect(safeMap['parserHint'], 'materials_item_price');
      expect(safeMap['hasAmount'], isTrue);
      expect(safeMap['proofLineReferenceLabel'], 'Line 3');
      expect(
        safeMap['customerProofDefaultVisibility'],
        'review_for_customer_proof',
      );
      expect(safeMap.toString(), isNot(contains('OATEY')));
      expect(safeMap.toString(), isNot(contains('LOWE')));
      expect(handoff.localReviewLineMaps.length, handoff.lines.length);
      expect(handoff.privacySafeLineSummaryMaps.length, handoff.lines.length);
      final contract = handoff.privacySafeParserHandoffContract;
      final customerProofContract = handoff.privacySafeCustomerProofContract;
      final clientProofContract =
          handoff.privacySafeClientProofTelemetryContract;
      final diagnosticsContract = result.diagnostics.parserHandoffContract;
      expect(contract['schema'], 'receipt_ocr_parser_handoff_v1');
      expect(contract['privacyScope'], 'summary_only_no_receipt_content');
      expect(contract['lineCount'], handoff.lines.length);
      expect(
        contract['orderedLineIds'],
        containsAll(['ocr_line_000_vendor', 'ocr_line_002_item']),
      );
      expect(
        (contract['primaryFieldLineIds'] as Map)['vendor'],
        'ocr_line_000_vendor',
      );
      expect(
        (contract['primaryFieldLineIds'] as Map)['total'],
        'ocr_line_005_total',
      );
      expect((contract['roleByLineId'] as Map)['ocr_line_002_item'], 'item');
      expect(
        (contract['parserBucketByLineId'] as Map)['ocr_line_002_item'],
        'item_ready',
      );
      expect(
        (contract['expenseFamilyByLineId'] as Map)['ocr_line_002_item'],
        'materials',
      );
      expect(
        (contract['parserHintByLineId'] as Map)['ocr_line_002_item'],
        'materials_item_price',
      );
      expect((contract['lineNumberByLineId'] as Map)['ocr_line_002_item'], 3);
      expect(
        (contract['proofLineReferenceLabelByLineId']
            as Map)['ocr_line_002_item'],
        'Line 3',
      );
      expect(
        (contract['customerProofDefaultVisibilityByLineId']
            as Map)['ocr_line_002_item'],
        'review_for_customer_proof',
      );
      expect(
        (contract['customerProofDefaultVisibilityByLineId']
            as Map)['ocr_line_006_tender'],
        'redact_by_default',
      );
      expect(
        contract['customerProofReviewLineIds'],
        contains('ocr_line_002_item'),
      );
      expect(
        contract['customerProofRedactByDefaultLineIds'],
        containsAll(['ocr_line_006_tender', 'ocr_line_007_metadata']),
      );
      expect(
        (contract['customerProofVisibilityCounts']
            as Map)['review_for_customer_proof'],
        6,
      );
      expect(
        (contract['customerProofVisibilityCounts'] as Map)['redact_by_default'],
        2,
      );
      expect(contract['customerProofContract'], customerProofContract);
      expect(
        contract['clientProofRedactionStatus'],
        'redaction_defaults_present',
      );
      expect(
        (contract['clientProofVisibilityCounts']
            as Map)['review_for_client_proof'],
        6,
      );
      expect(
        (contract['clientProofVisibilityCounts'] as Map)['redact_by_default'],
        2,
      );
      expect(contract['clientProofTelemetryContract'], clientProofContract);
      expect(
        customerProofContract['schema'],
        'receipt_customer_proof_redaction_v1',
      );
      expect(
        customerProofContract['privacyScope'],
        'summary_only_no_receipt_content',
      );
      expect(
        (customerProofContract['lineNumberByLineId']
            as Map)['ocr_line_002_item'],
        3,
      );
      expect(
        customerProofContract['customerProofRedactByDefaultLineIds'],
        contains('ocr_line_006_tender'),
      );
      expect(
        clientProofContract['schema'],
        'receipt_client_proof_redaction_summary_v1',
      );
      expect(
        clientProofContract['privacyScope'],
        'summary_only_no_receipt_content',
      );
      expect(
        clientProofContract['clientProofRedactionStatus'],
        'redaction_defaults_present',
      );
      expect(
        (clientProofContract['clientProofVisibilityCounts']
            as Map)['review_for_client_proof'],
        6,
      );
      expect(
        result.diagnostics.clientProofRedactionStatus,
        'redaction_defaults_present',
      );
      expect(
        result.diagnostics.clientProofVisibilityCounts['redact_by_default'],
        2,
      );
      expect(
        (contract['parserTaskCounts'] as Map)['inventory_material_candidate'],
        1,
      );
      expect(contract['parserReadinessStatus'], 'inventory_ready');
      expect(contract['downstreamReadinessStatus'], 'inventory_material_ready');
      expect(contract['receiptStructureStatus'], 'ready_for_parser');
      expect(contract['summaryMathStatus'], 'matched');
      expect(contract['summaryMathReconciled'], isTrue);
      expect(contract['mixedClassificationReadinessStatus'], 'ready');
      expect(
        contract['mixedClassificationEvidenceLabel'],
        contains('mixed_classification_ready'),
      );
      expect(
        (contract['mixedClassificationEvidenceDiagnostics']
            as Map)['summaryMathStatus'],
        'matched',
      );
      expect(contract['itemAmountLineIds'], contains('ocr_line_002_item'));
      expect(contract['inventoryPrepLineIds'], contains('ocr_line_002_item'));
      expect(
        (contract['privacySafeLineSummaries'] as List).singleWhere(
          (line) => line is Map && line['stableLineId'] == 'ocr_line_002_item',
        ),
        isA<Map>(),
      );
      expect(diagnosticsContract['schema'], 'receipt_ocr_parser_handoff_v1');
      expect(contract.toString(), isNot(contains('OATEY')));
      expect(contract.toString(), isNot(contains('LOWE')));
      expect(contract.toString(), isNot(contains('2.99')));
      expect(customerProofContract.toString(), isNot(contains('OATEY')));
      expect(customerProofContract.toString(), isNot(contains('LOWE')));
      expect(customerProofContract.toString(), isNot(contains('2.99')));
      expect(clientProofContract.toString(), isNot(contains('OATEY')));
      expect(clientProofContract.toString(), isNot(contains('LOWE')));
      expect(clientProofContract.toString(), isNot(contains('2.99')));
      expect(
        clientProofContract.toString().toLowerCase(),
        isNot(contains('customer')),
      );
    },
  );
}
