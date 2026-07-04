import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_photo_review_retake_order.dart';

void main() {
  test('insert-after rejects normalized aliases of existing sections', () {
    final plan = ReceiptPhotoInsertAfterOrderPlan.build(
      currentPhotoPaths: const [
        '/tmp/receipt/top.jpg',
        '/tmp/receipt/middle.jpg',
        '/tmp/receipt/bottom.jpg',
      ],
      anchorIndex: 1,
      anchorPhotoPath: '/tmp/receipt/middle.jpg',
      insertedPhotoPaths: const ['/tmp/receipt/../receipt/bottom.jpg'],
    );

    expect(plan, isNull);
  });

  test('remove rejects normalized duplicate section paths', () {
    final plan = ReceiptPhotoRemovalOrderPlan.build(
      currentPhotoPaths: const [
        '/tmp/receipt/top.jpg',
        '/tmp/receipt/../receipt/top.jpg',
        '/tmp/receipt/bottom.jpg',
      ],
      targetIndex: 1,
      targetPhotoPath: '/tmp/receipt/../receipt/top.jpg',
    );

    expect(plan, isNull);
  });

  test('move rejects normalized duplicate section paths', () {
    final plan = ReceiptPhotoMoveOrderPlan.build(
      currentPhotoPaths: const [
        '/tmp/receipt/top.jpg',
        '/tmp/receipt/middle.jpg',
        '/tmp/receipt/../receipt/middle.jpg',
      ],
      selectedIndex: 1,
      selectedPhotoPath: '/tmp/receipt/middle.jpg',
      direction: 1,
    );

    expect(plan, isNull);
  });

  test('move diagnostics reject stale normalized aliases', () {
    final plan = ReceiptPhotoMoveOrderPlan.build(
      currentPhotoPaths: const [
        '/tmp/receipt/top.jpg',
        '/tmp/receipt/middle.jpg',
        '/tmp/receipt/bottom.jpg',
      ],
      selectedIndex: 1,
      selectedPhotoPath: '/tmp/receipt/middle.jpg',
      direction: 1,
    );

    expect(plan, isNotNull);
    expect(
      plan!.captureDiagnosticsForMovedPhotoPath(
        '/tmp/receipt/../receipt/middle.jpg',
      ),
      isEmpty,
    );
  });
}
