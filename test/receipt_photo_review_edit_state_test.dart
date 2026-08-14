import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_photo_review_edit_state.dart';

void main() {
  group('ReceiptPhotoEditTarget', () {
    test('rejects a late edit after selection changes', () {
      final target = ReceiptPhotoEditTarget.capture(
        photoPaths: const ['/top.jpg', '/bottom.jpg'],
        selectedIndex: 0,
      );

      expect(target, isNotNull);
      expect(
        target!.stillOwns(
          photoPaths: const ['/top.jpg', '/bottom.jpg'],
          selectedIndex: 1,
        ),
        isFalse,
      );
    });

    test('rejects a late edit after replacement or reorder', () {
      final target = ReceiptPhotoEditTarget.capture(
        photoPaths: const ['/top.jpg', '/middle.jpg', '/bottom.jpg'],
        selectedIndex: 1,
      )!;

      expect(
        target.stillOwns(
          photoPaths: const ['/top.jpg', '/replacement.jpg', '/bottom.jpg'],
          selectedIndex: 1,
        ),
        isFalse,
      );
      expect(
        target.stillOwns(
          photoPaths: const ['/middle.jpg', '/top.jpg', '/bottom.jpg'],
          selectedIndex: 0,
        ),
        isFalse,
      );
    });

    test('accepts only the unchanged source identity and slot', () {
      final target = ReceiptPhotoEditTarget.capture(
        photoPaths: const ['/top.jpg', '/bottom.jpg'],
        selectedIndex: 1,
      )!;

      expect(
        target.stillOwns(
          photoPaths: const ['/top.jpg', '/bottom.jpg'],
          selectedIndex: 1,
        ),
        isTrue,
      );
    });
  });

  group('ReceiptPhotoPairAdjustmentState', () {
    test('creates one neutral adjustment slot per adjacent photo pair', () {
      final state = ReceiptPhotoPairAdjustmentState()..syncForPhotoCount(4);

      expect(state.pairCount, 3);
      expect(state.overlapFractions, everyElement(isNull));
      expect(state.scaleCorrections, everyElement(1));
      expect(state.rotationCorrectionsDegrees, everyElement(0));
      expect(state.horizontalOffsetFractions, everyElement(0));
      expect(state.zeroOverlapPairs, everyElement(isFalse));
    });

    test('photo topology change erases adjustments from former pairs', () {
      final state = ReceiptPhotoPairAdjustmentState()..syncForPhotoCount(3);
      state.overlapFractions[0] = .24;
      state.scaleCorrections[1] = .93;
      state.rotationCorrectionsDegrees[1] = 1.5;
      state.horizontalOffsetFractions[0] = .04;
      state.zeroOverlapPairs[1] = true;

      state.resetForPhotoSetChange(3);

      expect(state.overlapFractions, everyElement(isNull));
      expect(state.scaleCorrections, everyElement(1));
      expect(state.rotationCorrectionsDegrees, everyElement(0));
      expect(state.horizontalOffsetFractions, everyElement(0));
      expect(state.zeroOverlapPairs, everyElement(isFalse));
    });

    test('reset follows the new pair count after add or removal', () {
      final state = ReceiptPhotoPairAdjustmentState()..syncForPhotoCount(2);

      state.resetForPhotoSetChange(5);
      expect(state.pairCount, 4);

      state.resetForPhotoSetChange(1);
      expect(state.pairCount, 0);
    });
  });

  test('evicting a photo clears its former completion authority', () {
    final state = ReceiptPhotoReviewDecisionState();
    state.promptedPhotoPaths.addAll(['/removed.jpg', '/kept.jpg']);
    state.decisionsByPath.addAll({
      '/removed.jpg': {'receiptCompletionConfirmed': true},
      '/kept.jpg': {'receiptCompletionConfirmed': false},
    });

    state.evictPhotoPath('/removed.jpg');

    expect(state.promptedPhotoPaths, {'/kept.jpg'});
    expect(state.decisionsByPath.keys, {'/kept.jpg'});
  });
}
