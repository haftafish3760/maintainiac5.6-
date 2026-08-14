import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_photo_pipeline_contract.dart';

void main() {
  test('single photo advances from source review to saved-image review', () {
    expect(
      receiptPhotoPipelineNextStep(
        sourcePhotoCount: 1,
        reviewingSavedImage: false,
        reviewingLongReceipt: false,
        stitchResult: null,
      ),
      ReceiptPhotoPipelineNextStep.reviewSavedImage,
    );
  });

  test('multiple photos enter assembly before saved-image review', () {
    final fallback = ReceiptStitchResult.fallback(
      inputPaths: const ['/tmp/top.jpg', '/tmp/bottom.jpg'],
      warning: 'needs alignment',
      fallbackReasonCode: 'overlap_confidence_low',
    );
    expect(
      receiptPhotoPipelineNextStep(
        sourcePhotoCount: 2,
        reviewingSavedImage: false,
        reviewingLongReceipt: false,
        stitchResult: null,
      ),
      ReceiptPhotoPipelineNextStep.reviewLongReceipt,
    );
    expect(
      receiptPhotoPipelineNextStep(
        sourcePhotoCount: 2,
        reviewingSavedImage: false,
        reviewingLongReceipt: true,
        stitchResult: fallback,
      ),
      ReceiptPhotoPipelineNextStep.reviewSavedImage,
    );
    expect(
      acceptedReceiptImageSourcePaths(
        inputPaths: fallback.inputPaths,
        stitchResult: fallback,
        stitchMatchesCurrentReceipt: true,
      ),
      fallback.inputPaths,
    );
  });

  test(
    'original photos remain the saved proof when a combined preview exists',
    () {
      final stitched = ReceiptStitchResult(
        status: ReceiptStitchStatus.stitched,
        inputPaths: const ['/tmp/top.jpg', '/tmp/bottom.jpg'],
        ocrSourcePaths: const ['/tmp/combined.jpg'],
        stitchedPath: '/tmp/combined.jpg',
        confidence: .92,
      );
      expect(
        receiptPhotoPipelineNextStep(
          sourcePhotoCount: 2,
          reviewingSavedImage: false,
          reviewingLongReceipt: true,
          stitchResult: stitched,
        ),
        ReceiptPhotoPipelineNextStep.reviewSavedImage,
      );
      expect(
        acceptedReceiptImageSourcePaths(
          inputPaths: stitched.inputPaths,
          stitchResult: stitched,
          stitchMatchesCurrentReceipt: true,
        ),
        stitched.inputPaths,
      );
      expect(
        receiptPhotoPipelineNextStep(
          sourcePhotoCount: 2,
          reviewingSavedImage: true,
          reviewingLongReceipt: false,
          stitchResult: stitched,
        ),
        ReceiptPhotoPipelineNextStep.finalizeReceiptImage,
      );
    },
  );

  test('returning to source photos cannot skip combined receipt review', () {
    final stitched = ReceiptStitchResult(
      status: ReceiptStitchStatus.stitched,
      inputPaths: const ['/tmp/top.jpg', '/tmp/bottom.jpg'],
      ocrSourcePaths: const ['/tmp/combined.jpg'],
      stitchedPath: '/tmp/combined.jpg',
      confidence: .92,
    );

    expect(
      receiptPhotoPipelineNextStep(
        sourcePhotoCount: 2,
        reviewingSavedImage: false,
        reviewingLongReceipt: false,
        stitchResult: stitched,
      ),
      ReceiptPhotoPipelineNextStep.reviewLongReceipt,
    );
  });
}
