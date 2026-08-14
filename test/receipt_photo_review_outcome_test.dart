import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

void main() {
  test('accepted, saved draft, and discard are typed terminal outcomes', () {
    final accepted = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/proof.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: ReceiptStitchResult.notNeeded(const ['/tmp/ocr.jpg']),
    );
    final savedDraft = ReceiptPhotoReviewResult.keptForLater(
      photoPaths: const ['/tmp/proof.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
    );
    final discarded = ReceiptPhotoReviewResult.discardedByUser(
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
    );

    expect(
      accepted.outcome,
      ReceiptPhotoReviewOutcome.acceptedForReceiptDetails,
    );
    expect(accepted.acceptedForReceiptDetails, isTrue);
    expect(accepted.exitsReceiptFlow, isFalse);

    expect(savedDraft.outcome, ReceiptPhotoReviewOutcome.saveDraftAndExit);
    expect(savedDraft.keptForLater, isTrue);
    expect(savedDraft.exitsReceiptFlow, isTrue);

    expect(discarded.outcome, ReceiptPhotoReviewOutcome.discardAndExit);
    expect(discarded.discardedByUser, isTrue);
    expect(discarded.exitsReceiptFlow, isTrue);
  });

  test('source action result preserves the exact review terminal result', () {
    final savedDraft = ReceiptPhotoReviewResult.keptForLater(
      photoPaths: const ['/tmp/proof.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
    );
    final result = ReceiptImportActionResult.reviewCompleted(savedDraft);

    expect(result.closesChooser, isTrue);
    expect(result.reviewResult, same(savedDraft));
    expect(result.exitsReceiptFlow, isTrue);
    expect(
      result.reviewResult!.outcome,
      ReceiptPhotoReviewOutcome.saveDraftAndExit,
    );
  });
}
