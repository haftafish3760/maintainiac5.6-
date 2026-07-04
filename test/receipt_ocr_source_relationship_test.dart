import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  group('OCR source proof relationship', () {
    test('marks accepted proof reused as the same source, not fallback', () {
      final result = ReceiptPhotoReviewResult(
        photoPaths: const ['/tmp/accepted-receipt.jpg'],
        ocrSourcePhotoPaths: const ['/tmp/accepted-receipt.jpg'],
        dataSaverLevel: ReceiptDataSaverLevel.balanced,
        stitchResult: const ReceiptStitchResult.notNeeded([
          '/tmp/accepted-receipt.jpg',
        ]),
      );

      expect(result.ocrSourceProofRelationship, 'same_accepted_source');
      expect(result.ocrSourceFirstOutcome, 'saved_source_matched_original');
      expect(result.usedSavedProofAsOcrSourceFallback, isFalse);
      expect(result.ocrReadsClearSourceBeforeSavedProof, isTrue);
      expect(
        result.privacySafeOcrSourceFirstSummary,
        containsPair('ocrSourceProofRelationship', 'same_accepted_source'),
      );
    });

    test('marks missing OCR paths as saved proof fallback review risk', () {
      final result = ReceiptPhotoReviewResult(
        photoPaths: const ['/tmp/saved-proof.jpg'],
        ocrSourcePhotoPaths: const [],
        dataSaverLevel: ReceiptDataSaverLevel.maximum,
        stitchResult: const ReceiptStitchResult.notNeeded([
          '/tmp/saved-proof.jpg',
        ]),
      );

      expect(result.ocrSourcePhotoPaths, ['/tmp/saved-proof.jpg']);
      expect(result.ocrSourceProofRelationship, 'saved_proof_fallback');
      expect(
        result.ocrSourceFirstDecisionCode,
        'saved_proof_fallback_review_required',
      );
      expect(result.ocrReadsClearSourceBeforeSavedProof, isFalse);
      expect(
        result.privacySafeOcrSourceFirstSummary,
        containsPair('ocrSourceProofRelationship', 'saved_proof_fallback'),
      );
    });

    test('marks separate OCR copies as clear source before proof', () {
      final result = ReceiptPhotoReviewResult(
        photoPaths: const ['/tmp/saved-proof.jpg'],
        ocrSourcePhotoPaths: const ['/tmp/ocr-clear.jpg'],
        dataSaverLevel: ReceiptDataSaverLevel.strong,
        stitchResult: const ReceiptStitchResult.notNeeded([
          '/tmp/ocr-clear.jpg',
        ]),
      );

      expect(result.ocrSourceProofRelationship, 'separate_clear_source');
      expect(result.usesSeparateOcrSourceCopies, isTrue);
      expect(result.ocrReadsClearSourceBeforeSavedProof, isTrue);
      expect(
        result.privacySafeOcrSourceFirstSummary,
        containsPair('ocrSourceProofRelationship', 'separate_clear_source'),
      );
    });
  });
}
