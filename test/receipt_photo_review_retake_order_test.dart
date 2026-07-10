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
    expect(plan.alignmentContext.previousSectionGuidePhotoPath, 'top.jpg');
    expect(plan.alignmentContext.nextSectionGuidePhotoPath, 'bottom.jpg');
    expect(plan.alignmentContext.hasTwoSidedContext, isTrue);
    expect(
      plan.alignmentContext.guidanceCode,
      'retake_middle_with_previous_next_context',
    );
    expect(
      plan.alignmentContext.guidanceText,
      contains('previous and next sections'),
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
        diagnostics['middle-new-a.jpg'],
        containsPair('receiptRetakePreviousContextSectionNumber', 1),
      );
      expect(
        diagnostics['middle-new-a.jpg'],
        containsPair('receiptRetakeNextContextSectionNumber', 3),
      );
      expect(
        diagnostics['middle-new-a.jpg'],
        containsPair('receiptRetakePreviousContextFinalSectionNumber', 1),
      );
      expect(
        diagnostics['middle-new-a.jpg'],
        containsPair('receiptRetakeNextContextFinalSectionNumber', 4),
      );
      expect(
        diagnostics['middle-new-b.jpg'],
        containsPair('receiptRetakeInsertedExtraSection', true),
      );
      expect(
        diagnostics['middle-new-b.jpg'],
        containsPair('receiptRetakeFinalSectionNumber', 3),
      );
      expect(
        diagnostics['middle-new-a.jpg'],
        containsPair('receiptRetakeReplacementCount', 2),
      );
      expect(
        diagnostics['middle-new-b.jpg'],
        containsPair('receiptRetakeFinalSectionCount', 4),
      );
      expect(diagnostics.values.toString(), isNot(contains('top.jpg')));
      expect(diagnostics.values.toString(), isNot(contains('bottom.jpg')));
    },
  );

  test(
    'insert-after diagnostics track the following section after insertion',
    () {
      final plan = ReceiptPhotoInsertAfterOrderPlan.build(
        currentPhotoPaths: const ['top.jpg', 'middle.jpg', 'bottom.jpg'],
        anchorIndex: 0,
        anchorPhotoPath: 'top.jpg',
        insertedPhotoPaths: const ['top-extra-a.jpg', 'top-extra-b.jpg'],
      );

      expect(plan, isNotNull);
      expect(plan!.followingPhotoPath, 'middle.jpg');
      expect(plan.followingOriginalSectionNumber, 2);
      expect(plan.followingFinalSectionNumber, 4);
      final diagnostics = plan.captureDiagnosticsForInsertedPhotoPaths(const [
        'top-extra-a.jpg',
        'top-extra-b.jpg',
      ]);
      expect(
        diagnostics['top-extra-a.jpg'],
        containsPair('receiptInsertFollowingContextSectionNumber', 2),
      );
      expect(
        diagnostics['top-extra-a.jpg'],
        containsPair('receiptInsertFollowingContextFinalSectionNumber', 4),
      );
    },
  );

  test(
    'removal diagnostics preserve remaining section order after a shift',
    () {
      final plan = ReceiptPhotoRemovalOrderPlan.build(
        currentPhotoPaths: const ['top.jpg', 'middle.jpg', 'bottom.jpg'],
        targetIndex: 1,
        targetPhotoPath: 'middle.jpg',
      );

      expect(plan, isNotNull);
      expect(plan!.removedSectionNumber, 2);
      expect(plan.photoPaths, const ['top.jpg', 'bottom.jpg']);
      final diagnostics = plan.captureDiagnosticsForRemainingPaths(const [
        'top.jpg',
        'bottom.jpg',
      ]);
      expect(
        diagnostics['top.jpg'],
        containsPair('receiptRemoveRemainingSectionOriginalNumber', 1),
      );
      expect(
        diagnostics['top.jpg'],
        containsPair('receiptRemoveSectionShifted', false),
      );
      expect(
        diagnostics['bottom.jpg'],
        containsPair('receiptRemoveRemainingSectionOriginalNumber', 3),
      );
      expect(
        diagnostics['bottom.jpg'],
        containsPair('receiptRemoveFinalSectionNumber', 2),
      );
      expect(
        diagnostics['bottom.jpg'],
        containsPair('receiptRemoveSectionShifted', true),
      );
    },
  );

  test(
    'top-section multi-photo retake stays before the original next section',
    () {
      final plan = ReceiptPhotoRetakeOrderPlan.build(
        currentPhotoPaths: const ['top-old.jpg', 'middle.jpg', 'bottom.jpg'],
        targetPhotoPath: 'top-old.jpg',
        replacementPhotoPaths: const ['top-new-a.jpg', 'top-new-b.jpg'],
      );

      expect(plan, isNotNull);
      expect(plan!.selectedIndex, 0);
      expect(plan.photoPaths, const [
        'top-new-a.jpg',
        'top-new-b.jpg',
        'middle.jpg',
        'bottom.jpg',
      ]);
      expect(plan.alignmentContext.previousPhotoPath, isNull);
      expect(plan.alignmentContext.nextPhotoPath, 'middle.jpg');
      expect(plan.alignmentContext.nextSectionGuidePhotoPath, isNull);
      expect(
        plan.alignmentContext.guidanceCode,
        'retake_top_with_next_context',
      );
      final diagnostics = plan.captureDiagnosticsForReplacementPaths(const [
        'top-new-a.jpg',
        'top-new-b.jpg',
      ]);
      expect(
        diagnostics['top-new-a.jpg'],
        containsPair('receiptRetakePreservedOriginalSlot', true),
      );
      expect(
        diagnostics['top-new-b.jpg'],
        containsPair('receiptRetakeInsertedExtraSection', true),
      );
      expect(
        diagnostics['top-new-b.jpg'],
        containsPair('receiptRetakeFinalSectionNumber', 2),
      );
      expect(
        diagnostics['top-new-a.jpg'],
        containsPair('receiptRetakeNextContextSectionNumber', 2),
      );
    },
  );

  test(
    'bottom-section multi-photo retake appends extras after bottom slot',
    () {
      final plan = ReceiptPhotoRetakeOrderPlan.build(
        currentPhotoPaths: const ['top.jpg', 'middle.jpg', 'bottom-old.jpg'],
        targetPhotoPath: 'bottom-old.jpg',
        replacementPhotoPaths: const ['bottom-new-a.jpg', 'bottom-new-b.jpg'],
      );

      expect(plan, isNotNull);
      expect(plan!.selectedIndex, 2);
      expect(plan.photoPaths, const [
        'top.jpg',
        'middle.jpg',
        'bottom-new-a.jpg',
        'bottom-new-b.jpg',
      ]);
      expect(plan.alignmentContext.previousPhotoPath, 'middle.jpg');
      expect(plan.alignmentContext.nextPhotoPath, isNull);
      expect(plan.alignmentContext.nextSectionGuidePhotoPath, isNull);
      expect(
        plan.alignmentContext.guidanceCode,
        'retake_bottom_with_previous_context',
      );
      final diagnostics = plan.captureDiagnosticsForReplacementPaths(const [
        'bottom-new-a.jpg',
        'bottom-new-b.jpg',
      ]);
      expect(
        diagnostics['bottom-new-a.jpg'],
        containsPair('receiptRetakeOriginalSectionNumber', 3),
      );
      expect(
        diagnostics['bottom-new-b.jpg'],
        containsPair('receiptRetakeFinalSectionNumber', 4),
      );
      expect(
        diagnostics['bottom-new-a.jpg'],
        containsPair('receiptRetakePreviousContextSectionNumber', 2),
      );
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

  test('section order plans reject padded or aliased target paths', () {
    final retakePaddedTarget = ReceiptPhotoRetakeOrderPlan.build(
      currentPhotoPaths: const [
        '/tmp/receipt/top.jpg',
        '/tmp/receipt/middle.jpg',
        '/tmp/receipt/bottom.jpg',
      ],
      targetPhotoPath: ' /tmp/receipt/middle.jpg ',
      replacementPhotoPaths: const ['/tmp/receipt/middle-new.jpg'],
    );
    final retakeAliasedTarget = ReceiptPhotoRetakeOrderPlan.build(
      currentPhotoPaths: const [
        '/tmp/receipt/top.jpg',
        '/tmp/receipt/middle.jpg',
        '/tmp/receipt/bottom.jpg',
      ],
      targetPhotoPath: '/tmp/receipt/../receipt/middle.jpg',
      replacementPhotoPaths: const ['/tmp/receipt/middle-new.jpg'],
    );
    final insertPaddedAnchor = ReceiptPhotoInsertAfterOrderPlan.build(
      currentPhotoPaths: const [
        '/tmp/receipt/top.jpg',
        '/tmp/receipt/middle.jpg',
      ],
      anchorIndex: 1,
      anchorPhotoPath: ' /tmp/receipt/middle.jpg ',
      insertedPhotoPaths: const ['/tmp/receipt/bottom.jpg'],
    );
    final moveAliasedSelection = ReceiptPhotoMoveOrderPlan.build(
      currentPhotoPaths: const [
        '/tmp/receipt/top.jpg',
        '/tmp/receipt/middle.jpg',
      ],
      selectedIndex: 1,
      selectedPhotoPath: '/tmp/receipt/../receipt/middle.jpg',
      direction: -1,
    );

    expect(retakePaddedTarget, isNull);
    expect(retakeAliasedTarget, isNull);
    expect(insertPaddedAnchor, isNull);
    expect(moveAliasedSelection, isNull);
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
    expect(context.previousSectionGuidePhotoPath, isNull);
    expect(context.guidanceCode, 'retake_top_with_next_context');
    expect(
      context.guidanceText,
      contains('check that it still joins cleanly with the next section'),
    );

    final plan = ReceiptPhotoRetakeOrderPlan.build(
      currentPhotoPaths: const ['top-old.jpg', 'middle.jpg', 'bottom.jpg'],
      targetPhotoPath: 'top-old.jpg',
      replacementPhotoPaths: const ['top-new.jpg'],
    );
    final diagnostics = plan!.captureDiagnosticsForReplacementPaths(const [
      'top-new.jpg',
    ]);

    expect(
      diagnostics['top-new.jpg'],
      isNot(contains('receiptRetakePreviousContextSectionNumber')),
    );
    expect(
      diagnostics['top-new.jpg'],
      containsPair('receiptRetakeNextContextSectionNumber', 2),
    );
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
    expect(context.previousSectionGuidePhotoPath, 'middle.jpg');
    expect(context.guidanceCode, 'retake_bottom_with_previous_context');
    expect(context.guidanceText, contains('previous section'));

    final plan = ReceiptPhotoRetakeOrderPlan.build(
      currentPhotoPaths: const ['top.jpg', 'middle.jpg', 'bottom-old.jpg'],
      targetPhotoPath: 'bottom-old.jpg',
      replacementPhotoPaths: const ['bottom-new.jpg'],
    );
    final diagnostics = plan!.captureDiagnosticsForReplacementPaths(const [
      'bottom-new.jpg',
    ]);

    expect(
      diagnostics['bottom-new.jpg'],
      containsPair('receiptRetakePreviousContextSectionNumber', 2),
    );
    expect(
      diagnostics['bottom-new.jpg'],
      isNot(contains('receiptRetakeNextContextSectionNumber')),
    );
  });
}
