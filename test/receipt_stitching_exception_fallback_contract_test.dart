import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

void main() {
  test('stitch exception fallback preserves known pair review context', () {
    final fallback = ReceiptStitchResult.fallback(
      inputPaths: const ['/tmp/top.jpg', '/tmp/middle.jpg', '/tmp/bottom.jpg'],
      warning: 'The stitched artifact could not be written safely.',
      fallbackReasonCode: 'stitch_exception',
      confidence: .42,
      failedPairIndex: 1,
      pairs: const [
        ReceiptStitchPairResult(
          pairIndex: 0,
          overlapPixels: 220,
          confidence: .81,
        ),
      ],
    );

    expect(fallback.failedPairLabel, 'Photo 2 to 3');
    expect(fallback.pairs.single.pairIndex, 0);
    expect(fallback.confidence, .42);
    // The person already reviewed and ordered these original sections before
    // Continue. A derived-image failure must preserve that safe OCR handoff,
    // not block assisted reading on another stitch review loop.
    expect(fallback.requiresOcrSourceReviewBeforeAssistedRead, isFalse);
    expect(fallback.assistedReadinessCode, 'ordered_sections_ready');
    expect(fallback.hasValidOcrSourceContract, isTrue);
    expect(fallback.ocrSourcePaths, fallback.inputPaths);
  });
}
