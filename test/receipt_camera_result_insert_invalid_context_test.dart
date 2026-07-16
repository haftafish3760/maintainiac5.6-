import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  test('insert-after offset mismatches require order review', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/extra.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/extra-ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: ReceiptStitchResult.fallback(
        inputPaths: ['/tmp/extra-ocr.jpg'],
        warning: 'Review inserted section.',
        fallbackReasonCode: 'manual_overlap_unsafe',
      ),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/extra.jpg': {
          'receiptInsertAfterAnchorSectionNumber': 2,
          'receiptInsertAfterOffset': 2,
          'receiptInsertFinalSectionNumber': 3,
          'receiptInsertPreservedAnchorSlot': true,
          'receiptInsertOrderPolicy':
              'insert_new_sections_after_selected_anchor',
        },
      },
    );

    expect(result.receiptSectionOrderOutcome, 'insert_order_invalid');
    expect(
      result.receiptSectionOrderCounts['insert_invalid_offset_final_mismatch'],
      1,
    );
    expect(result.receiptSectionOrderNeedsReview, true);
    expect(
      result.acceptedPhotoHandoffActionLabel,
      'Review the inserted receipt section order before Maintainiac reads the receipt.',
    );
  });

  test('insert metadata missing section numbers requires order review', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/insert.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/insert-ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: ReceiptStitchResult.fallback(
        inputPaths: ['/tmp/insert-ocr.jpg'],
        warning: 'Review inserted section.',
        fallbackReasonCode: 'manual_overlap_unsafe',
      ),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/insert.jpg': {
          'receiptInsertAfterOffset': 0,
          'receiptInsertPreservedAnchorSlot': true,
          'receiptInsertOrderPolicy':
              'insert_new_sections_after_selected_anchor',
        },
      },
    );

    expect(result.receiptSectionOrderOutcome, 'insert_order_invalid');
    expect(
      result.receiptSectionOrderCounts['insert_invalid_missing_anchor_section'],
      1,
    );
    expect(
      result.receiptSectionOrderCounts['insert_invalid_missing_final_section'],
      1,
    );
    expect(result.acceptedPhotoHandoffOutcome, 'needs_review_before_ocr');
  });

  test('invalid insert review keeps later failed stitch pair explicit', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const [
        '/tmp/top-proof.jpg',
        '/tmp/middle-proof.jpg',
        '/tmp/insert-proof.jpg',
      ],
      ocrSourcePhotoPaths: const [
        '/tmp/top-ocr.jpg',
        '/tmp/middle-ocr.jpg',
        '/tmp/insert-ocr.jpg',
      ],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: ReceiptStitchResult.fallback(
        inputPaths: [
          '/tmp/top-ocr.jpg',
          '/tmp/middle-ocr.jpg',
          '/tmp/insert-ocr.jpg',
        ],
        warning: 'Inserted section order still needs review.',
        fallbackReasonCode: 'overlap_confidence_low',
        failedPairIndex: 1,
      ),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/insert-proof.jpg': {
          'receiptInsertAfterAnchorSectionNumber': 2,
          'receiptInsertAfterOffset': 2,
          'receiptInsertFinalSectionNumber': 3,
          'receiptInsertPreservedAnchorSlot': true,
          'receiptInsertOrderPolicy':
              'insert_new_sections_after_selected_anchor',
        },
      },
    );

    expect(result.receiptSectionOrderOutcome, 'insert_order_invalid');
    expect(
      result.acceptedPhotoHandoffActionLabel,
      'Review the inserted receipt section order before Maintainiac reads the receipt. Photo 2 to 3 still needs review.',
    );
    expect(
      result
          .privacySafeReceiptReaderHandoffMetadata['receiptSectionOrderFailedPairLabel'],
      'Photo 2 to 3',
    );
  });

  test('invalid manual reorder review keeps later failed stitch pair explicit', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const [
        '/tmp/top-proof.jpg',
        '/tmp/bottom-proof.jpg',
        '/tmp/middle-proof.jpg',
      ],
      ocrSourcePhotoPaths: const [
        '/tmp/top-ocr.jpg',
        '/tmp/bottom-ocr.jpg',
        '/tmp/middle-ocr.jpg',
      ],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: ReceiptStitchResult.fallback(
        inputPaths: [
          '/tmp/top-ocr.jpg',
          '/tmp/bottom-ocr.jpg',
          '/tmp/middle-ocr.jpg',
        ],
        warning: 'Manual order still needs review.',
        fallbackReasonCode: 'overlap_confidence_low',
        failedPairIndex: 1,
      ),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/middle-proof.jpg': {
          'receiptManualReorderOriginalSectionNumber': 2,
          'receiptManualReorderFinalSectionNumber': 5,
          'receiptManualReorderDirection': 'later',
          'receiptManualReorderPreservedPhotoPath': true,
        },
      },
    );

    expect(result.receiptSectionOrderOutcome, 'manual_reorder_invalid');
    expect(
      result.acceptedPhotoHandoffActionLabel,
      'Review the manually reordered receipt sections before Maintainiac reads the receipt. Photo 2 to 3 still needs review.',
    );
    expect(
      result
          .privacySafeReceiptReaderHandoffMetadata['receiptSectionOrderFailedPairLabel'],
      'Photo 2 to 3',
    );
  });
}
