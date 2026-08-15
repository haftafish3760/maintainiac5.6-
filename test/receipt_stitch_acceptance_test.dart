import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_stitch_acceptance.dart';

void main() {
  test(
    'trusts a transformed seam only with dense positioned OCR and image support',
    () {
      expect(
        hasHighTrustPositionedReceiptOverlap(
          visualConfidence: .545,
          textConfidence: 1,
          matchedTextLineCount: 11,
          hasTextPositionEvidence: true,
          textPositionalConfidence: .948,
        ),
        isTrue,
      );
    },
  );

  test(
    'does not trust repeated text or weak imagery for a transformed seam',
    () {
      expect(
        hasHighTrustPositionedReceiptOverlap(
          visualConfidence: .49,
          textConfidence: 1,
          matchedTextLineCount: 12,
          hasTextPositionEvidence: true,
          textPositionalConfidence: .97,
        ),
        isFalse,
      );
      expect(
        hasHighTrustPositionedReceiptOverlap(
          visualConfidence: .80,
          textConfidence: 1,
          matchedTextLineCount: 3,
          hasTextPositionEvidence: true,
          textPositionalConfidence: .97,
        ),
        isFalse,
      );
    },
  );

  test('does not replace a high-trust positioned join with fixed scale', () {
    expect(
      shouldTryFixedScaleReceiptFallback(
        continuityProven: false,
        hasHighTrustPositionedText: true,
        scaleCorrection: .84,
        rotationCorrectionDegrees: .8,
        perspectiveCorrection: .04,
      ),
      isFalse,
    );
    expect(
      shouldTryFixedScaleReceiptFallback(
        continuityProven: false,
        hasHighTrustPositionedText: false,
        scaleCorrection: .84,
        rotationCorrectionDegrees: .8,
        perspectiveCorrection: .04,
      ),
      isTrue,
    );
  });

  test('crops through the final OCR-matched line at a receipt seam', () {
    expect(
      receiptTextCoveredSeamSkipPixels(
        geometricOverlapPixels: 1333,
        nextImageHeight: 2634,
        nextMatchedBlockEnd: .5467,
      ),
      1441,
    );
  });

  test('never moves a text-guided seam above the geometric overlap', () {
    expect(
      receiptTextCoveredSeamSkipPixels(
        geometricOverlapPixels: 1400,
        nextImageHeight: 2600,
        nextMatchedBlockEnd: .40,
      ),
      1400,
    );
  });

  test('keeps a complete continuation line that crosses the seam', () {
    expect(
      receiptTextAwareSeamCropPixels(
        geometricOverlapPixels: 1197,
        nextImageHeight: 2275,
        matchedTextEnd: .503,
        continuationTextStart: .524,
        continuationTextEnd: .547,
        hasHighTrustPositionedText: true,
      ),
      1190,
    );
    expect(
      receiptTextAwareSeamCropPixels(
        geometricOverlapPixels: 1180,
        nextImageHeight: 2275,
        matchedTextEnd: .5029,
        continuationTextStart: .5246,
        continuationTextEnd: .5466,
        hasHighTrustPositionedText: true,
      ),
      1191,
    );
  });

  test('OCR continuation bounds never move physical photo placement', () {
    expect(
      receiptGeometryPlacementOverlapPixels(
        seamSkipPixels: 1197,
        overlapPixels: 1100,
        nextImageHeight: 2275,
      ),
      1197,
    );
  });

  test('stitch worker receives only the time left after registration', () {
    expect(
      receiptRemainingStitchWorkerTimeout(
        totalBudget: const Duration(seconds: 6),
        elapsedBeforeWorker: const Duration(milliseconds: 125),
      ),
      const Duration(milliseconds: 5875),
    );
    expect(
      receiptRemainingStitchWorkerTimeout(
        totalBudget: const Duration(seconds: 1),
        elapsedBeforeWorker: const Duration(seconds: 2),
      ),
      Duration.zero,
    );
  });

  test('accepts strong geometry and continuity when OCR is unavailable', () {
    final decision = evaluateReceiptStitchEvidence(
      visualConfidence: .72,
      continuityCorrelation: .81,
      continuityDetailedBands: 5,
      continuityMatchingBands: 5,
      continuityProven: true,
      geometryCorrelation: .84,
      geometryDetailedCells: 10,
      geometryMatchingCells: 9,
      geometryProven: true,
      textConfidence: 0,
      matchedTextLineCount: 0,
      textStrong: false,
      hasTextPositionEvidence: false,
      textPositionalConfidence: 0,
    );

    expect(decision.accepted, isTrue);
    expect(decision.reasonCode, 'fused_visual_document_geometry');
  });

  test('does not accept OCR or visual similarity as a lone signal', () {
    final decision = evaluateReceiptStitchEvidence(
      visualConfidence: .40,
      continuityCorrelation: .10,
      continuityDetailedBands: 1,
      continuityMatchingBands: 0,
      continuityProven: false,
      geometryCorrelation: .10,
      geometryDetailedCells: 2,
      geometryMatchingCells: 0,
      geometryProven: false,
      textConfidence: .96,
      matchedTextLineCount: 2,
      textStrong: true,
      hasTextPositionEvidence: true,
      textPositionalConfidence: .90,
    );

    expect(decision.accepted, isFalse);
    expect(decision.reasonCode, 'document_geometry_not_proven');
  });

  test('dense positioned OCR cannot replace missing document geometry', () {
    final decision = evaluateReceiptStitchEvidence(
      visualConfidence: .506,
      continuityCorrelation: .174,
      continuityDetailedBands: 7,
      continuityMatchingBands: 4,
      continuityProven: false,
      geometryCorrelation: .087,
      geometryDetailedCells: 12,
      geometryMatchingCells: 0,
      geometryProven: false,
      textConfidence: 1,
      matchedTextLineCount: 10,
      textStrong: true,
      hasTextPositionEvidence: true,
      textPositionalConfidence: .947,
    );

    expect(decision.accepted, isFalse);
    expect(decision.reasonCode, 'document_geometry_not_proven');
  });

  test('positioned receipt lines and continuity cannot replace geometry', () {
    final decision = evaluateReceiptStitchEvidence(
      visualConfidence: .26,
      continuityCorrelation: .75,
      continuityDetailedBands: 6,
      continuityMatchingBands: 6,
      continuityProven: true,
      geometryCorrelation: .08,
      geometryDetailedCells: 12,
      geometryMatchingCells: 0,
      geometryProven: false,
      textConfidence: 1,
      matchedTextLineCount: 2,
      textStrong: true,
      hasTextPositionEvidence: true,
      textPositionalConfidence: .99,
    );

    expect(decision.accepted, isFalse);
    expect(decision.reasonCode, 'document_geometry_not_proven');
    expect(decision.confidence, lessThan(.50));
  });

  test('requires two-dimensional geometry when OCR is unavailable', () {
    final decision = evaluateReceiptStitchEvidence(
      visualConfidence: .72,
      continuityCorrelation: .86,
      continuityDetailedBands: 5,
      continuityMatchingBands: 5,
      continuityProven: true,
      geometryCorrelation: .42,
      geometryDetailedCells: 10,
      geometryMatchingCells: 3,
      geometryProven: false,
      textConfidence: 0,
      matchedTextLineCount: 0,
      textStrong: false,
      hasTextPositionEvidence: false,
      textPositionalConfidence: 0,
    );

    expect(decision.accepted, isFalse);
    expect(decision.reasonCode, 'document_geometry_not_proven');
  });

  test('rejects a geometry candidate with weak direct visual support', () {
    final decision = evaluateReceiptStitchEvidence(
      visualConfidence: .32,
      continuityCorrelation: .76,
      continuityDetailedBands: 6,
      continuityMatchingBands: 6,
      continuityProven: true,
      geometryCorrelation: .64,
      geometryDetailedCells: 12,
      geometryMatchingCells: 7,
      geometryProven: false,
      textConfidence: 0,
      matchedTextLineCount: 0,
      textStrong: false,
      hasTextPositionEvidence: false,
      textPositionalConfidence: 0,
    );

    expect(decision.accepted, isFalse);
    expect(decision.reasonCode, 'visual_overlap_support_low');
  });

  test('accepts bounded drift when every continuity band corroborates it', () {
    final decision = evaluateReceiptStitchEvidence(
      visualConfidence: .376,
      continuityCorrelation: .872,
      continuityDetailedBands: 6,
      continuityMatchingBands: 6,
      continuityProven: true,
      geometryCorrelation: .563,
      geometryDetailedCells: 12,
      geometryMatchingCells: 6,
      geometryProven: false,
      textConfidence: 0,
      matchedTextLineCount: 0,
      textStrong: false,
      hasTextPositionEvidence: false,
      textPositionalConfidence: 0,
    );

    expect(decision.accepted, isTrue);
    expect(decision.corroboratingSignalCount, 2);
  });

  test('rejects a near-maximum overlap that needs unsupported zoom', () {
    expect(
      isLargeReceiptOverlapTransformAmbiguous(
        overlapPixels: 1376,
        overlapReferenceHeight: 3032,
        scaleCorrection: 1.12,
        rotationCorrectionDegrees: 0,
        perspectiveCorrection: 0,
        continuityCorrelation: .583289896,
        continuityDetailedBands: 7,
        continuityMatchingBands: 7,
      ),
      isTrue,
    );
  });

  test('allows a transformed overlap backed by exceptional continuity', () {
    expect(
      isLargeReceiptOverlapTransformAmbiguous(
        overlapPixels: 159,
        overlapReferenceHeight: 360,
        scaleCorrection: 1.18,
        rotationCorrectionDegrees: -.8,
        perspectiveCorrection: 0,
        continuityCorrelation: .8269922107,
        continuityDetailedBands: 3,
        continuityMatchingBands: 3,
      ),
      isFalse,
    );
  });

  test('does not reject ordinary overlap without a large transform', () {
    expect(
      isLargeReceiptOverlapTransformAmbiguous(
        overlapPixels: 1217,
        overlapReferenceHeight: 3032,
        scaleCorrection: 1.06,
        rotationCorrectionDegrees: 0,
        perspectiveCorrection: 0,
        continuityCorrelation: .318835413,
        continuityDetailedBands: 7,
        continuityMatchingBands: 4,
      ),
      isFalse,
    );
  });
}
