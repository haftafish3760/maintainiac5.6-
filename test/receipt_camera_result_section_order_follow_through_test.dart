import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  test('retake follow-through labels stay explicit after stitch fallback', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/top.jpg', '/tmp/middle-new.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/top-ocr.jpg', '/tmp/middle-ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: ReceiptStitchResult.fallback(
        inputPaths: ['/tmp/top-ocr.jpg', '/tmp/middle-ocr.jpg'],
        warning: 'Review retaken section order.',
        fallbackReasonCode: 'manual_overlap_unsafe',
      ),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/middle-new.jpg': {
          'receiptRetakePreservedOriginalSlot': true,
          'receiptRetakeOriginalSectionNumber': 2,
          'receiptRetakeReplacementOffset': 0,
          'receiptRetakeFinalSectionNumber': 2,
          'receiptRetakeGuidanceCode':
              'retake_middle_with_previous_next_context',
          'receiptRetakeHasPreviousAlignmentContext': true,
          'receiptRetakeHasNextAlignmentContext': true,
          'receiptRetakeHasTwoSidedAlignmentContext': true,
          'receiptRetakePreviousContextSectionNumber': 1,
          'receiptRetakeNextContextSectionNumber': 3,
        },
      },
    );

    expect(result.receiptSectionOrderHasFollowThroughAction, isTrue);
    expect(
      result.acceptedPhotoHandoffNextStepLabel,
      'Confirm the retaken section stayed in its original receipt position. Then receipt details open.',
    );
    expect(
      result.acceptedPhotoHandoffRouteResultLabel,
      'Confirm the retaken section stayed in its original receipt position. Receipt details open immediately after that confirmation.',
    );
  });

  test('insert follow-through labels stay explicit after stitch fallback', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const [
        '/tmp/top.jpg',
        '/tmp/middle.jpg',
        '/tmp/middle-extra.jpg',
      ],
      ocrSourcePhotoPaths: const [
        '/tmp/top-ocr.jpg',
        '/tmp/middle-ocr.jpg',
        '/tmp/middle-extra-ocr.jpg',
      ],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: ReceiptStitchResult.fallback(
        inputPaths: [
          '/tmp/top-ocr.jpg',
          '/tmp/middle-ocr.jpg',
          '/tmp/middle-extra-ocr.jpg',
        ],
        warning: 'Review inserted section order.',
        fallbackReasonCode: 'manual_overlap_unsafe',
      ),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/middle-extra.jpg': {
          'receiptInsertAfterAnchorSectionNumber': 2,
          'receiptInsertAfterOffset': 0,
          'receiptInsertFinalSectionNumber': 3,
          'receiptInsertPreservedAnchorSlot': true,
          'receiptInsertOrderPolicy':
              'insert_new_sections_after_selected_anchor',
        },
      },
    );

    expect(result.receiptSectionOrderHasFollowThroughAction, isTrue);
    expect(
      result.acceptedPhotoHandoffNextStepLabel,
      'Confirm the inserted receipt section appears after the selected section. Then receipt details open.',
    );
    expect(
      result.acceptedPhotoHandoffRouteResultLabel,
      'Confirm the inserted receipt section appears after the selected section. Receipt details open immediately after that confirmation.',
    );
  });
}
