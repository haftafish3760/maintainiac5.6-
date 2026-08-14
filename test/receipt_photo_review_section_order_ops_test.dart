import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_photo_review_retake_order.dart';

void main() {
  test('insert-after plan preserves the selected receipt section slot', () {
    final plan = ReceiptPhotoInsertAfterOrderPlan.build(
      currentPhotoPaths: const ['top.jpg', 'middle.jpg', 'bottom.jpg'],
      anchorIndex: 1,
      anchorPhotoPath: 'middle.jpg',
      insertedPhotoPaths: const ['middle-extra.jpg'],
    );

    expect(plan, isNotNull);
    expect(plan!.selectedIndex, 2);
    expect(plan.anchorIndex, 1);
    expect(plan.anchorPhotoPath, 'middle.jpg');
    expect(plan.anchorSectionNumber, 2);
    expect(plan.insertedPhotoPaths, const ['middle-extra.jpg']);
    expect(plan.photoPaths, const [
      'top.jpg',
      'middle.jpg',
      'middle-extra.jpg',
      'bottom.jpg',
    ]);
  });

  test('insert-after plan records diagnostics for inserted sections', () {
    final plan = ReceiptPhotoInsertAfterOrderPlan.build(
      currentPhotoPaths: const ['top.jpg', 'middle.jpg', 'bottom.jpg'],
      anchorIndex: 1,
      anchorPhotoPath: 'middle.jpg',
      insertedPhotoPaths: const ['middle-extra-a.jpg', 'middle-extra-b.jpg'],
    );

    expect(plan, isNotNull);
    expect(plan!.selectedIndex, 2);
    expect(plan.photoPaths, const [
      'top.jpg',
      'middle.jpg',
      'middle-extra-a.jpg',
      'middle-extra-b.jpg',
      'bottom.jpg',
    ]);

    final diagnostics = plan.captureDiagnosticsForInsertedPhotoPaths(const [
      'middle-extra-a.jpg',
      'middle-extra-b.jpg',
    ]);
    expect(
      diagnostics['middle-extra-a.jpg'],
      containsPair('receiptInsertAfterAnchorSectionNumber', 2),
    );
    expect(
      diagnostics['middle-extra-a.jpg'],
      containsPair('receiptInsertAfterOffset', 0),
    );
    expect(
      diagnostics['middle-extra-a.jpg'],
      containsPair('receiptInsertFinalSectionNumber', 3),
    );
    expect(
      diagnostics['middle-extra-b.jpg'],
      containsPair('receiptInsertAfterOffset', 1),
    );
    expect(
      diagnostics['middle-extra-b.jpg'],
      containsPair('receiptInsertFinalSectionNumber', 4),
    );
    expect(
      diagnostics['middle-extra-a.jpg'],
      containsPair('receiptInsertCount', 2),
    );
    expect(
      diagnostics['middle-extra-b.jpg'],
      containsPair('receiptInsertFinalSectionCount', 5),
    );
    expect(
      diagnostics['middle-extra-b.jpg'],
      containsPair(
        'receiptInsertOrderPolicy',
        'insert_new_sections_after_selected_anchor',
      ),
    );
    expect(diagnostics.values.toString(), isNot(contains('top.jpg')));
    expect(diagnostics.values.toString(), isNot(contains('bottom.jpg')));
  });

  test('insert-after diagnostics reject stale inserted path lists', () {
    final plan = ReceiptPhotoInsertAfterOrderPlan.build(
      currentPhotoPaths: const ['top.jpg', 'middle.jpg', 'bottom.jpg'],
      anchorIndex: 1,
      anchorPhotoPath: 'middle.jpg',
      insertedPhotoPaths: const ['middle-extra.jpg'],
    );

    expect(plan, isNotNull);
    expect(
      plan!.captureDiagnosticsForInsertedPhotoPaths(const ['stale-extra.jpg']),
      isEmpty,
    );
    expect(
      plan.captureDiagnosticsForInsertedPhotoPaths(const [
        'middle-extra.jpg',
        'extra-stale.jpg',
      ]),
      isEmpty,
    );
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

  test('move plan reorders the selected section with diagnostics', () {
    final plan = ReceiptPhotoMoveOrderPlan.build(
      currentPhotoPaths: const ['top.jpg', 'middle.jpg', 'bottom.jpg'],
      selectedIndex: 1,
      selectedPhotoPath: 'middle.jpg',
      direction: 1,
    );

    expect(plan, isNotNull);
    expect(plan!.selectedIndex, 2);
    expect(plan.movedPhotoPath, 'middle.jpg');
    expect(plan.originalSectionNumber, 2);
    expect(plan.finalSectionNumber, 3);
    expect(plan.directionCode, 'later');
    expect(plan.photoPaths, const ['top.jpg', 'bottom.jpg', 'middle.jpg']);

    final diagnostics = plan.captureDiagnosticsForMovedPhotoPath('middle.jpg');
    expect(
      diagnostics,
      containsPair('receiptManualReorderOriginalSectionNumber', 2),
    );
    expect(
      diagnostics,
      containsPair('receiptManualReorderFinalSectionNumber', 3),
    );
    expect(diagnostics, containsPair('receiptManualReorderDirection', 'later'));
    expect(diagnostics, containsPair('receiptManualReorderSectionCount', 3));
    expect(
      diagnostics,
      containsPair('receiptManualReorderPreservedPhotoPath', true),
    );
    expect(
      diagnostics,
      containsPair(
        'receiptManualReorderPolicy',
        'user_reordered_sections_preserve_paths',
      ),
    );
    expect(plan.captureDiagnosticsForMovedPhotoPath('stale.jpg'), isEmpty);
  });

  test('move plan rejects stale or ambiguous reorder requests', () {
    final duplicatePlan = ReceiptPhotoMoveOrderPlan.build(
      currentPhotoPaths: const ['top.jpg', 'middle.jpg', 'middle.jpg'],
      selectedIndex: 1,
      selectedPhotoPath: 'middle.jpg',
      direction: 1,
    );
    final stalePlan = ReceiptPhotoMoveOrderPlan.build(
      currentPhotoPaths: const ['top.jpg', 'changed.jpg', 'bottom.jpg'],
      selectedIndex: 1,
      selectedPhotoPath: 'middle.jpg',
      direction: 1,
    );
    final outOfBoundsPlan = ReceiptPhotoMoveOrderPlan.build(
      currentPhotoPaths: const ['top.jpg', 'middle.jpg', 'bottom.jpg'],
      selectedIndex: 0,
      selectedPhotoPath: 'top.jpg',
      direction: -1,
    );
    final nonAdjacentPlan = ReceiptPhotoMoveOrderPlan.build(
      currentPhotoPaths: const ['top.jpg', 'middle.jpg', 'bottom.jpg'],
      selectedIndex: 0,
      selectedPhotoPath: 'top.jpg',
      direction: 2,
    );

    expect(duplicatePlan, isNull);
    expect(stalePlan, isNull);
    expect(outOfBoundsPlan, isNull);
    expect(nonAdjacentPlan, isNull);
  });
}
