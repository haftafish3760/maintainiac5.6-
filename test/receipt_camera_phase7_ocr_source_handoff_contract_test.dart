import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('phase 7 camera lane keeps OCR source handoff in receipt-camera scope', () async {
    final ocrContract = await File(
      'lib/shared/receipts/receipt_ocr_contract.dart',
    ).readAsString();
    final ocrHandoff = await File(
      'lib/shared/widgets/receipt_capture/receipt_ocr_source_handoff.dart',
    ).readAsString();
    final ocrReview = await File(
      'lib/shared/widgets/receipt_capture/receipt_ocr_source_handoff_review.dart',
    ).readAsString();
    final ocrLongReceipt = await File(
      'lib/shared/widgets/receipt_capture/receipt_ocr_source_handoff_long_receipt.dart',
    ).readAsString();
    final attachmentSignals = await File(
      'lib/shared/widgets/receipt_capture/receipt_attachment_ocr_source_signals.dart',
    ).readAsString();
    final attachmentRisks = await File(
      'lib/shared/widgets/receipt_capture/receipt_attachment_ocr_source_risk_flags.dart',
    ).readAsString();
    final flowSignals = await File(
      'lib/shared/widgets/receipt_capture/receipt_capture_flow_handoff_signals.dart',
    ).readAsString();
    final flowRisks = await File(
      'lib/shared/widgets/receipt_capture/receipt_capture_flow_handoff_risks.dart',
    ).readAsString();

    expect(
      ocrContract,
      contains("part '../widgets/receipt_capture/receipt_ocr_source_handoff.dart';"),
    );
    expect(
      ocrContract,
      contains(
        "part '../widgets/receipt_capture/receipt_ocr_source_handoff_review.dart';",
      ),
    );
    expect(
      ocrContract,
      contains(
        "part '../widgets/receipt_capture/receipt_ocr_source_handoff_long_receipt.dart';",
      ),
    );

    expect(ocrHandoff, contains('class ReceiptOcrSourceHandoffSummary'));
    expect(ocrHandoff, contains('factory ReceiptOcrSourceHandoffSummary.fromAttachments('));
    expect(ocrHandoff, contains('reviewDepthSignalCounts'));
    expect(ocrHandoff, contains('sectionOrderSignalCounts'));
    expect(ocrHandoff, contains('photoQualityRiskCounts'));
    expect(ocrHandoff, contains("_incrementOcrHandoffCount(stitches, token);"));
    expect(
      ocrHandoff,
      contains("token.startsWith('receipt_section_order_')"),
    );
    expect(
      ocrHandoff,
      contains("token.startsWith('receipt_review_depth_')"),
    );

    expect(ocrReview, contains('extension ReceiptOcrSourceHandoffReview'));
    expect(
      ocrReview,
      contains("return 'stitch_contract_review_required';"),
    );
    expect(
      ocrReview,
      contains("return 'ordered_sections_stitch_fallback';"),
    );
    expect(ocrReview, contains("return 'stitched_ocr_source';"));
    expect(ocrReview, contains('bool get hasSectionOrderReviewRisk =>'));
    expect(ocrReview, contains('String get sectionOrderReviewStatus {'));

    expect(
      ocrLongReceipt,
      contains('bool get hasGhostSliceAlignmentContract =>'),
    );
    expect(
      ocrLongReceipt,
      contains('String get ghostSliceAlignmentStatus {'),
    );
    expect(
      ocrLongReceipt,
      contains('String get ghostSliceReviewInstruction {'),
    );
    expect(
      ocrLongReceipt,
      contains('bool get hasMissingBottomEdgeAndTotalsEvidence {'),
    );
    expect(
      ocrLongReceipt,
      contains("return 'top_ghost_slice_repeat_3_to_5_lines_match_subtotal_total_final';"),
    );

    for (final source in [attachmentSignals, flowSignals]) {
      expect(source, contains('ocr_source_artifact_available'));
      expect(source, contains('stitch_ocr_source_contract_review_required'));
      expect(source, contains('stitch_ocr_source_result_contract_mismatch'));
      expect(source, contains('stitch_overlap_'));
      expect(source, contains('stitch_source_'));
      expect(source, contains('receipt_section_order_review_required'));
      expect(
        source,
        contains('ContinuationDocumentSignalsFor(result'),
      );
    }

    expect(
      ocrLongReceipt,
      contains('receipt_continuation_missing_bottom_edge_and_totals'),
    );

    for (final source in [attachmentRisks, flowRisks]) {
      expect(source, contains('ocr_source_stitch_contract_review_required'));
      expect(source, contains('ocr_source_stitch_result_contract_mismatch'));
      expect(source, contains('ocr_source_section_order_review_required'));
      expect(source, contains('ocr_source_fallback_saved_proof_review_required'));
      expect(source, contains('ocr_source_temporary_full_quality_guard_review'));
    }
  });
}
