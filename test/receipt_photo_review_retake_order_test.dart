import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_photo_review_retake_order.dart';

void main() {
  test('retaking a middle receipt section keeps the same section slot', () {
    final plan = ReceiptPhotoRetakeOrderPlan.build(
      currentPhotoPaths: const ['top.jpg', 'middle-old.jpg', 'bottom.jpg'],
      targetPhotoPath: 'middle-old.jpg',
      replacementPhotoPaths: const ['middle-new.jpg'],
    );

    expect(plan, isNotNull);
    expect(plan!.selectedIndex, 1);
    expect(plan.replacedPhotoPath, 'middle-old.jpg');
    expect(plan.photoPaths, const ['top.jpg', 'middle-new.jpg', 'bottom.jpg']);
    expect(plan.alignmentContext.previousPhotoPath, 'top.jpg');
    expect(plan.alignmentContext.nextPhotoPath, 'bottom.jpg');
    expect(plan.alignmentContext.preferredGuidePhotoPath, 'top.jpg');
    expect(plan.alignmentContext.hasTwoSidedContext, isTrue);
    expect(
      plan.alignmentContext.guidanceCode,
      'retake_middle_with_previous_next_context',
    );
    expect(plan.originalSectionNumber, 2);
  });

  test(
    'retaking one section with multiple photos inserts extras after the slot',
    () {
      final plan = ReceiptPhotoRetakeOrderPlan.build(
        currentPhotoPaths: const ['top.jpg', 'middle-old.jpg', 'bottom.jpg'],
        targetPhotoPath: 'middle-old.jpg',
        replacementPhotoPaths: const ['middle-new-a.jpg', 'middle-new-b.jpg'],
      );

      expect(plan, isNotNull);
      expect(plan!.selectedIndex, 1);
      expect(plan.alignmentContext.previousPhotoPath, 'top.jpg');
      expect(plan.alignmentContext.nextPhotoPath, 'bottom.jpg');
      expect(plan.photoPaths, const [
        'top.jpg',
        'middle-new-a.jpg',
        'middle-new-b.jpg',
        'bottom.jpg',
      ]);
      final diagnostics = plan.captureDiagnosticsForReplacementPaths(const [
        'middle-new-a.jpg',
        'middle-new-b.jpg',
      ]);
      expect(
        diagnostics['middle-new-a.jpg'],
        containsPair('receiptRetakePreservedOriginalSlot', true),
      );
      expect(
        diagnostics['middle-new-a.jpg'],
        containsPair('receiptRetakeOriginalSectionNumber', 2),
      );
      expect(
        diagnostics['middle-new-a.jpg'],
        containsPair(
          'receiptRetakeGuidanceCode',
          'retake_middle_with_previous_next_context',
        ),
      );
      expect(
        diagnostics['middle-new-b.jpg'],
        containsPair('receiptRetakeInsertedExtraSection', true),
      );
      expect(
        diagnostics['middle-new-b.jpg'],
        containsPair('receiptRetakeFinalSectionNumber', 3),
      );
      expect(diagnostics.values.toString(), isNot(contains('top.jpg')));
      expect(diagnostics.values.toString(), isNot(contains('bottom.jpg')));
    },
  );

  test('retake diagnostics reject stale replacement path lists', () {
    final plan = ReceiptPhotoRetakeOrderPlan.build(
      currentPhotoPaths: const ['top.jpg', 'middle-old.jpg', 'bottom.jpg'],
      targetPhotoPath: 'middle-old.jpg',
      replacementPhotoPaths: const ['middle-new.jpg'],
    );

    expect(plan, isNotNull);
    expect(plan!.replacementPhotoPaths, const ['middle-new.jpg']);
    expect(
      plan.captureDiagnosticsForReplacementPaths(const ['stale-new.jpg']),
      isEmpty,
    );
    expect(
      plan.captureDiagnosticsForReplacementPaths(const [
        'middle-new.jpg',
        'extra-stale.jpg',
      ]),
      isEmpty,
    );
  });

  test('retake plan is rejected when the async target is gone', () {
    final plan = ReceiptPhotoRetakeOrderPlan.build(
      currentPhotoPaths: const ['top.jpg', 'bottom.jpg'],
      targetPhotoPath: 'middle-old.jpg',
      replacementPhotoPaths: const ['middle-new.jpg'],
    );

    expect(plan, isNull);
  });

  test('retake plan rejects empty replacement paths', () {
    final plan = ReceiptPhotoRetakeOrderPlan.build(
      currentPhotoPaths: const ['top.jpg', 'middle-old.jpg', 'bottom.jpg'],
      targetPhotoPath: 'middle-old.jpg',
      replacementPhotoPaths: const [''],
    );

    expect(plan, isNull);
  });

  test('retake plan rejects duplicate replacement paths', () {
    final plan = ReceiptPhotoRetakeOrderPlan.build(
      currentPhotoPaths: const ['top.jpg', 'middle-old.jpg', 'bottom.jpg'],
      targetPhotoPath: 'middle-old.jpg',
      replacementPhotoPaths: const ['middle-new.jpg', 'middle-new.jpg'],
    );

    expect(plan, isNull);
  });

  test('retake plan rejects paths already used by another section', () {
    final plan = ReceiptPhotoRetakeOrderPlan.build(
      currentPhotoPaths: const ['top.jpg', 'middle-old.jpg', 'bottom.jpg'],
      targetPhotoPath: 'middle-old.jpg',
      replacementPhotoPaths: const ['bottom.jpg'],
    );

    expect(plan, isNull);
  });

  test('retake plan rejects unnormalized replacement paths', () {
    final plan = ReceiptPhotoRetakeOrderPlan.build(
      currentPhotoPaths: const ['top.jpg', 'middle-old.jpg', 'bottom.jpg'],
      targetPhotoPath: 'middle-old.jpg',
      replacementPhotoPaths: const [' bottom.jpg '],
    );

    expect(plan, isNull);
  });

  test('retake plan rejects duplicate current section paths', () {
    final plan = ReceiptPhotoRetakeOrderPlan.build(
      currentPhotoPaths: const ['top.jpg', 'middle.jpg', 'middle.jpg'],
      targetPhotoPath: 'middle.jpg',
      replacementPhotoPaths: const ['middle-new.jpg'],
    );
    final context = ReceiptPhotoRetakeAlignmentContext.build(
      currentPhotoPaths: const ['top.jpg', 'middle.jpg', 'middle.jpg'],
      targetPhotoPath: 'middle.jpg',
    );

    expect(plan, isNull);
    expect(context, isNull);
  });

  test('retake plan rejects normalized receipt section path aliases', () {
    final duplicateCurrentPlan = ReceiptPhotoRetakeOrderPlan.build(
      currentPhotoPaths: const [
        '/tmp/receipt/top.jpg',
        '/tmp/receipt/../receipt/top.jpg',
        '/tmp/receipt/bottom.jpg',
      ],
      targetPhotoPath: '/tmp/receipt/top.jpg',
      replacementPhotoPaths: const ['/tmp/receipt/top-new.jpg'],
    );
    final duplicateReplacementPlan = ReceiptPhotoRetakeOrderPlan.build(
      currentPhotoPaths: const [
        '/tmp/receipt/top.jpg',
        '/tmp/receipt/middle.jpg',
        '/tmp/receipt/bottom.jpg',
      ],
      targetPhotoPath: '/tmp/receipt/middle.jpg',
      replacementPhotoPaths: const ['/tmp/receipt/../receipt/bottom.jpg'],
    );

    expect(duplicateCurrentPlan, isNull);
    expect(duplicateReplacementPlan, isNull);
  });

  test('insert-after plan preserves the selected receipt section slot', () {
    final plan = ReceiptPhotoInsertAfterOrderPlan.build(
      currentPhotoPaths: const ['top.jpg', 'middle.jpg', 'bottom.jpg'],
      anchorIndex: 1,
      anchorPhotoPath: 'middle.jpg',
      insertedPhotoPaths: const ['middle-extra.jpg'],
    );

    expect(plan, isNotNull);
    expect(plan!.selectedIndex, 2);
    expect(plan.photoPaths, const [
      'top.jpg',
      'middle.jpg',
      'middle-extra.jpg',
      'bottom.jpg',
    ]);
  });

  test(
    'insert-after plan rejects ambiguous or stale receipt section anchors',
    () {
      final duplicatePlan = ReceiptPhotoInsertAfterOrderPlan.build(
        currentPhotoPaths: const ['top.jpg', 'middle.jpg', 'middle.jpg'],
        anchorIndex: 1,
        anchorPhotoPath: 'middle.jpg',
        insertedPhotoPaths: const ['middle-extra.jpg'],
      );
      final stalePlan = ReceiptPhotoInsertAfterOrderPlan.build(
        currentPhotoPaths: const ['top.jpg', 'changed.jpg', 'bottom.jpg'],
        anchorIndex: 1,
        anchorPhotoPath: 'middle.jpg',
        insertedPhotoPaths: const ['middle-extra.jpg'],
      );

      expect(duplicatePlan, isNull);
      expect(stalePlan, isNull);
    },
  );

  test('remove plan removes the selected receipt section by stable slot', () {
    final plan = ReceiptPhotoRemovalOrderPlan.build(
      currentPhotoPaths: const ['top.jpg', 'middle.jpg', 'bottom.jpg'],
      targetIndex: 1,
      targetPhotoPath: 'middle.jpg',
    );

    expect(plan, isNotNull);
    expect(plan!.removedPhotoPath, 'middle.jpg');
    expect(plan.selectedIndex, 1);
    expect(plan.photoPaths, const ['top.jpg', 'bottom.jpg']);
  });

  test('remove plan rejects ambiguous or stale receipt section targets', () {
    final duplicatePlan = ReceiptPhotoRemovalOrderPlan.build(
      currentPhotoPaths: const ['top.jpg', 'middle.jpg', 'middle.jpg'],
      targetIndex: 1,
      targetPhotoPath: 'middle.jpg',
    );
    final stalePlan = ReceiptPhotoRemovalOrderPlan.build(
      currentPhotoPaths: const ['top.jpg', 'changed.jpg', 'bottom.jpg'],
      targetIndex: 1,
      targetPhotoPath: 'middle.jpg',
    );

    expect(duplicatePlan, isNull);
    expect(stalePlan, isNull);
  });

  test('retaking the top section uses the next section as context', () {
    final context = ReceiptPhotoRetakeAlignmentContext.build(
      currentPhotoPaths: const ['top-old.jpg', 'middle.jpg', 'bottom.jpg'],
      targetPhotoPath: 'top-old.jpg',
    );

    expect(context, isNotNull);
    expect(context!.previousPhotoPath, isNull);
    expect(context.nextPhotoPath, 'middle.jpg');
    expect(context.preferredGuidePhotoPath, 'middle.jpg');
    expect(context.guidanceCode, 'retake_top_with_next_context');
  });

  test('retaking the bottom section uses the previous section as context', () {
    final context = ReceiptPhotoRetakeAlignmentContext.build(
      currentPhotoPaths: const ['top.jpg', 'middle.jpg', 'bottom-old.jpg'],
      targetPhotoPath: 'bottom-old.jpg',
    );

    expect(context, isNotNull);
    expect(context!.previousPhotoPath, 'middle.jpg');
    expect(context.nextPhotoPath, isNull);
    expect(context.preferredGuidePhotoPath, 'middle.jpg');
    expect(context.guidanceCode, 'retake_bottom_with_previous_context');
  });
}
