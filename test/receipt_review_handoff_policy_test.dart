import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

void main() {
  test('Continue is the only review outcome that starts receipt reading', () {
    final plan = ReceiptReviewHandoffPlan.forOutcome(
      ReceiptPhotoReviewOutcome.acceptedForReceiptDetails,
    );

    expect(plan.installReviewedPhotos, isTrue);
    expect(plan.retainReviewedSources, isTrue);
    expect(plan.notifyReceiptDetails, isTrue);
    expect(plan.startReceiptRead, isTrue);
    expect(plan.discardStagedPhotos, isFalse);
    expect(plan.exitsReceiptFlow, isFalse);
  });

  test('manual proof Continue preserves proof without starting reading', () {
    final plan = ReceiptReviewHandoffPlan.forOutcome(
      ReceiptPhotoReviewOutcome.acceptedForReceiptDetails,
      assistedReceiptFill: false,
    );

    expect(plan.installReviewedPhotos, isTrue);
    expect(plan.retainReviewedSources, isTrue);
    expect(plan.notifyReceiptDetails, isTrue);
    expect(plan.startReceiptRead, isFalse);
    expect(plan.discardStagedPhotos, isFalse);
    expect(plan.exitsReceiptFlow, isFalse);
  });

  test('Save draft preserves proof but does not notify or start reading', () {
    final plan = ReceiptReviewHandoffPlan.forOutcome(
      ReceiptPhotoReviewOutcome.saveDraftAndExit,
    );

    expect(plan.installReviewedPhotos, isTrue);
    expect(plan.retainReviewedSources, isTrue);
    expect(plan.notifyReceiptDetails, isFalse);
    expect(plan.startReceiptRead, isFalse);
    expect(plan.discardStagedPhotos, isFalse);
    expect(plan.exitsReceiptFlow, isTrue);
  });

  test('Discard does not install, notify, retain, or read staged proof', () {
    final plan = ReceiptReviewHandoffPlan.forOutcome(
      ReceiptPhotoReviewOutcome.discardAndExit,
    );

    expect(plan.installReviewedPhotos, isFalse);
    expect(plan.retainReviewedSources, isFalse);
    expect(plan.notifyReceiptDetails, isFalse);
    expect(plan.startReceiptRead, isFalse);
    expect(plan.discardStagedPhotos, isTrue);
    expect(plan.exitsReceiptFlow, isTrue);
  });

  test('native capture preserves a terminal review result explicitly', () {
    final reviewResult = ReceiptPhotoReviewResult.keptForLater(
      photoPaths: const ['/tmp/saved-proof.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
    );
    final flowResult = ReceiptCaptureFlowResult.reviewCompleted(
      reviewResult: reviewResult,
      recoveryManifestPath: '/tmp/recovery.json',
    );

    expect(flowResult.status, ReceiptCaptureFlowStatus.reviewCompleted);
    expect(flowResult.reviewResult, same(reviewResult));
    expect(flowResult.exitsReceiptFlow, isTrue);
    expect(flowResult.recoveryManifestPath, '/tmp/recovery.json');
  });
}
