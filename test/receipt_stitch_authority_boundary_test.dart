import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_photo_review_edit_state.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_stitch_acceptance.dart';

void main() {
  test('dense OCR cannot override unproven document geometry', () {
    final decision = evaluateReceiptStitchEvidence(
      visualConfidence: .80,
      continuityCorrelation: .88,
      continuityDetailedBands: 6,
      continuityMatchingBands: 6,
      continuityProven: true,
      geometryCorrelation: .12,
      geometryDetailedCells: 12,
      geometryMatchingCells: 2,
      geometryProven: false,
      textConfidence: 1,
      matchedTextLineCount: 12,
      textStrong: true,
      hasTextPositionEvidence: true,
      textPositionalConfidence: .99,
    );

    expect(decision.accepted, isFalse);
    expect(decision.reasonCode, 'document_geometry_not_proven');
  });

  test('OCR corroborates one geometry-owned placement', () {
    final decision = evaluateReceiptStitchEvidence(
      visualConfidence: .72,
      continuityCorrelation: .54,
      continuityDetailedBands: 4,
      continuityMatchingBands: 3,
      continuityProven: false,
      geometryCorrelation: .86,
      geometryDetailedCells: 12,
      geometryMatchingCells: 11,
      geometryProven: true,
      textConfidence: .94,
      matchedTextLineCount: 4,
      textStrong: true,
      hasTextPositionEvidence: true,
      textPositionalConfidence: .91,
    );

    expect(decision.accepted, isTrue);
    expect(
      decision.reasonCode,
      'positioned_text_corroborates_document_geometry',
    );
  });

  test('a fresh preview invalidates every prior user decision', () {
    final decisions = ReceiptStitchReviewDecisionState();

    decisions.accept('preview-v1');
    expect(decisions.isAccepted('preview-v1'), isTrue);
    decisions.invalidate();
    expect(decisions.isAccepted('preview-v1'), isFalse);

    decisions.reject('preview-v2');
    expect(decisions.isRejected('preview-v2'), isTrue);
    decisions.accept('preview-v3');
    expect(decisions.isRejected('preview-v2'), isFalse);
    expect(decisions.isAccepted('preview-v3'), isTrue);
  });
}
