import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_photo_review_retake_order.dart';

void main() {
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

  test('removal diagnostics reject stale or reordered remaining paths', () {
    final plan = ReceiptPhotoRemovalOrderPlan.build(
      currentPhotoPaths: const ['top.jpg', 'middle.jpg', 'bottom.jpg'],
      targetIndex: 1,
      targetPhotoPath: 'middle.jpg',
    );

    expect(plan, isNotNull);
    expect(
      plan!.captureDiagnosticsForRemainingPaths(const [
        'bottom.jpg',
        'top.jpg',
      ]),
      isEmpty,
    );
    expect(
      plan.captureDiagnosticsForRemainingPaths(const [
        'top.jpg',
        'changed.jpg',
      ]),
      isEmpty,
    );
  });
}
