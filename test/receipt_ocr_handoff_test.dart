import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/receipts/receipt_ocr_handoff.dart';
import 'package:maintaniac/shared/receipts/receipt_processing_contract.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_ocr_service.dart';

void main() {
  const ocr = ReceiptOcrResult(
    rawText: 'FUEL MART\nTOTAL 40.00',
    parserText: 'FUEL MART\nTOTAL 40.00',
    textByAttachmentId: {'photo': 'FUEL MART\nTOTAL 40.00'},
    source: ReceiptProcessingSource.photo,
  );

  test('a user-selected fuel receipt routes to the fuel handoff', () {
    final handoff = ReceiptOcrHandoff.forUserSelection(
      ocr: ocr,
      selectedCategory: 'Fuel',
    );

    expect(handoff.destination, ReceiptOcrHandoffDestination.fuel);
    expect(handoff.hasReadableText, isTrue);
    expect(
      handoff.documentClassification.documentType,
      ReceiptOcrDocumentType.generalExpense,
    );
  });

  test('a user-selected inventory receipt routes to inventory', () {
    expect(
      receiptOcrHandoffDestinationFor(selectedCategory: 'Materials'),
      ReceiptOcrHandoffDestination.inventory,
    );
    expect(
      receiptOcrHandoffDestinationFor(inventoryRequested: true),
      ReceiptOcrHandoffDestination.inventory,
    );
  });

  test('OCR does not infer a domain when the user selected none', () {
    expect(
      receiptOcrHandoffDestinationFor(selectedCategory: 'Electrical'),
      ReceiptOcrHandoffDestination.expenseReview,
    );
  });

  test(
    'dedicated routes receive the exact OCR handoff when available',
    () async {
      final fuelHandoff = ReceiptOcrHandoff.forUserSelection(
        ocr: ocr,
        selectedCategory: 'Fuel',
      );
      final router = ReceiptOcrHandoffRouter<String>(
        expenseReview: (_) => 'expense',
        fuel: (handoff) => 'fuel:${handoff.ocr.rawText}',
        inventory: (_) => 'inventory',
      );

      expect(await router.dispatch(fuelHandoff), 'fuel:FUEL MART\nTOTAL 40.00');
    },
  );

  test(
    'a missing dedicated consumer falls back without changing the route',
    () async {
      final inventoryHandoff = ReceiptOcrHandoff.forUserSelection(
        ocr: ocr,
        selectedCategory: 'Inventory',
      );
      final router = ReceiptOcrHandoffRouter<String>(
        expenseReview: (handoff) => 'fallback:${handoff.destination.name}',
      );

      expect(await router.dispatch(inventoryHandoff), 'fallback:inventory');
    },
  );

  test('router reports whether a selected route has a dedicated consumer', () {
    final router = ReceiptOcrHandoffRouter<String>(
      expenseReview: (_) => 'expense',
      fuel: (_) => 'fuel',
    );

    expect(
      router.hasDedicatedHandlerFor(ReceiptOcrHandoffDestination.fuel),
      isTrue,
    );
    expect(
      router.hasDedicatedHandlerFor(ReceiptOcrHandoffDestination.inventory),
      isFalse,
    );
  });

  test('an ambiguous document recommends both dedicated consumers', () {
    const classification = ReceiptOcrDocumentClassification(
      documentType: ReceiptOcrDocumentType.ambiguous,
      detailLevel: ReceiptOcrDetailLevel.detailed,
      confidence: .58,
      evidence: ['fuel_line_evidence', 'inventory_line_evidence'],
    );

    final plan = receiptOcrHandoffPlanFor(classification: classification);

    expect(plan.destinations, [
      ReceiptOcrHandoffDestination.fuel,
      ReceiptOcrHandoffDestination.inventory,
    ]);
    expect(plan.runsBothDedicatedConsumers, isTrue);
    expect(plan.needsReview, isTrue);
  });

  test(
    'the user-selected category takes precedence over an ambiguous hint',
    () {
      const classification = ReceiptOcrDocumentClassification(
        documentType: ReceiptOcrDocumentType.ambiguous,
        detailLevel: ReceiptOcrDetailLevel.detailed,
        confidence: .58,
        evidence: ['fuel_line_evidence', 'inventory_line_evidence'],
      );

      final plan = receiptOcrHandoffPlanFor(
        selectedCategory: 'Fuel',
        classification: classification,
      );

      expect(plan.destinations, [ReceiptOcrHandoffDestination.fuel]);
      expect(plan.runsBothDedicatedConsumers, isFalse);
    },
  );

  test(
    'an ambiguous plan sends unchanged evidence to both consumers',
    () async {
      final router = ReceiptOcrHandoffRouter<String>(
        expenseReview: (_) => 'review',
        fuel: (handoff) => 'fuel:${handoff.ocr.rawText}',
        inventory: (handoff) => 'inventory:${handoff.ocr.rawText}',
      );
      const plan = ReceiptOcrHandoffPlan(
        destinations: [
          ReceiptOcrHandoffDestination.fuel,
          ReceiptOcrHandoffDestination.inventory,
        ],
        needsReview: true,
      );

      final results = await router.dispatchPlan(
        ReceiptOcrHandoff.forUserSelection(ocr: ocr),
        plan: plan,
      );

      expect(results, {
        ReceiptOcrHandoffDestination.fuel: 'fuel:FUEL MART\nTOTAL 40.00',
        ReceiptOcrHandoffDestination.inventory:
            'inventory:FUEL MART\nTOTAL 40.00',
      });
    },
  );

  test(
    'an ambiguous plan falls back to one editable review when unavailable',
    () async {
      var reviewCalls = 0;
      final router = ReceiptOcrHandoffRouter<String>(
        expenseReview: (_) {
          reviewCalls += 1;
          return 'review';
        },
      );
      const plan = ReceiptOcrHandoffPlan(
        destinations: [
          ReceiptOcrHandoffDestination.fuel,
          ReceiptOcrHandoffDestination.inventory,
        ],
        needsReview: true,
      );

      final results = await router.dispatchPlan(
        ReceiptOcrHandoff.forUserSelection(ocr: ocr),
        plan: plan,
      );

      expect(results, {ReceiptOcrHandoffDestination.expenseReview: 'review'});
      expect(reviewCalls, 1);
    },
  );
}
