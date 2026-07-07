import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_flow.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  test(
    'review result preserves bottom-section continuation handoff context',
    () {
      final result = ReceiptPhotoReviewResult(
        photoPaths: const ['/tmp/bottom-section-proof.jpg'],
        ocrSourcePhotoPaths: const ['/tmp/bottom-section-ocr.jpg'],
        dataSaverLevel: ReceiptDataSaverLevel.balanced,
        stitchResult: ReceiptStitchResult.notNeeded([
          '/tmp/bottom-section-ocr.jpg',
        ]),
        captureDiagnosticsByPhotoPath: const {
          '/tmp/bottom-section-proof.jpg': {
            'previousSectionGuideRequested': true,
            'previousSectionGuidePhotoAvailable': true,
            'previousSectionReasonCode': 'missing_bottom_edge_and_totals',
            'previousSectionMissingBottomAndTotals': true,
            'previousSectionGhostGuidePolicy':
                'bottom_overlap_ghost_at_top_repeat_3_to_5_lines',
            'previousSectionGhostGuideRepeatLineTarget':
                'repeat_3_to_5_readable_lines',
            'previousSectionGhostGuidePlacement': 'top_ghost_slice',
            'previousSectionGhostGuideMatchTarget':
                'subtotal_total_and_final_lines',
            'previousSectionGhostSourceHeightFraction': .20,
            'previousSectionGhostSlicePercent': 20,
            'previousSectionGuidanceAvailable': true,
            'receiptContinuationSource': 'ocr_missing_bottom_totals',
            'receiptContinuationGhostGuideStatus': 'ready_with_previous_photo',
          },
        },
      );

      _expectBottomContinuationSummary(result);
      expect(
        result.receiptContinuationHandoffStatus,
        'ocr_requested_bottom_section_continuation',
      );
      expect(
        result.privacySafeReceiptContinuationSummary,
        containsPair('schema', 'receipt_continuation_handoff_v1'),
      );
      expect(
        result.privacySafeReceiptContinuationSummary,
        containsPair('hasOcrRequestedBottomSectionContinuation', true),
      );
      expect(
        result.privacySafeReceiptContinuationSummary.toString(),
        contains('ghost_slice_percent_20'),
      );
      final attachment = ReceiptCaptureFlow.attachmentsFromReviewResult(
        result,
        ReceiptCaptureFlowModule.expenses,
      ).single;
      expect(
        attachment.riskFlags,
        contains('ocr_source_continuation_ocr_requested_bottom_section_review'),
      );
      expect(
        attachment.riskFlags,
        contains('ocr_source_continuation_missing_bottom_totals_review'),
      );
      expect(
        attachment.riskFlags,
        contains('ocr_source_continuation_ghost_guide_ready'),
      );
      expect(
        attachment.riskFlags,
        contains('ocr_source_continuation_bottom_overlap_ghost_policy'),
      );
    },
  );

  test('phone camera fallback preserves bottom-section continuation handoff', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/fallback-bottom-proof.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/fallback-bottom-ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: ReceiptStitchResult.notNeeded([
        '/tmp/fallback-bottom-ocr.jpg',
      ]),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/fallback-bottom-proof.jpg': {
          'phoneCameraBackupUsed': true,
          'phoneCameraBackupHadPreviousSectionGuide': true,
          'phoneCameraBackupPreviousSectionReasonCode':
              'missing_bottom_edge_and_totals',
          'phoneCameraBackupPreviousSectionGuidance':
              'The bottom edge and subtotal/total lines were not found together.',
          'phoneCameraBackupPreviousSectionMissingBottomAndTotals': true,
          'phoneCameraBackupPreviousSectionGhostGuidePolicy':
              'bottom_overlap_ghost_at_top_repeat_3_to_5_lines',
          'phoneCameraBackupPreviousSectionGhostGuideRepeatLineTarget':
              'repeat_3_to_5_readable_lines',
          'phoneCameraBackupPreviousSectionGhostGuidePlacement':
              'top_ghost_slice',
          'phoneCameraBackupPreviousSectionGhostGuideMatchTarget':
              'subtotal_total_and_final_lines',
          'previousSectionGhostSourceHeightFraction': .20,
        },
      },
    );

    _expectBottomContinuationSummary(result);
    expect(
      result.receiptContinuationSignalCounts,
      containsPair('reason_missing_bottom_edge_and_totals', 1),
    );
    expect(
      result.receiptContinuationSignalCounts,
      containsPair('ghost_slice_percent_20', 1),
    );
  });

  test('continuation handoff ignores malformed ghost slice diagnostics', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/malformed-ghost-proof.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/malformed-ghost-ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: ReceiptStitchResult.notNeeded([
        '/tmp/malformed-ghost-ocr.jpg',
      ]),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/malformed-ghost-proof.jpg': {
          'previousSectionGuideRequested': true,
          'previousSectionReasonCode': 'missing_bottom_edge_and_totals',
          'previousSectionMissingBottomAndTotals': true,
          'previousSectionGhostSourceHeightFraction': double.nan,
          'previousSectionGhostSlicePercent': 20.5,
          'receiptText': 'private receipt text should not leak',
        },
      },
    );

    expect(result.hasPreviousSectionContinuationRequest, isTrue);
    expect(result.hasOcrRequestedBottomSectionContinuation, isTrue);
    expect(
      result.receiptContinuationSignalCounts,
      containsPair('reason_missing_bottom_edge_and_totals', 1),
    );
    expect(
      result.receiptContinuationSignalCounts,
      containsPair('missing_bottom_edge_and_totals_continuation', 1),
    );
    expect(
      result.receiptContinuationSignalCounts.containsKey(
        'ghost_slice_percent_20',
      ),
      isFalse,
    );
    expect(
      result.privacySafeReceiptContinuationSummary.toString(),
      isNot(contains('private receipt text')),
    );
  });

  test('phone backup continuation survives blank native values', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/blank-native-bottom-proof.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/blank-native-bottom-ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: ReceiptStitchResult.notNeeded([
        '/tmp/blank-native-bottom-ocr.jpg',
      ]),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/blank-native-bottom-proof.jpg': {
          'phoneCameraBackupHadPreviousSectionGuide': true,
          'previousSectionReasonCode': '   ',
          'phoneCameraBackupPreviousSectionReasonCode':
              'missing_bottom_edge_and_totals',
          'previousSectionGhostGuidePolicy': '',
          'phoneCameraBackupPreviousSectionGhostGuidePolicy':
              'bottom_overlap_ghost_at_top_repeat_3_to_5_lines',
          'previousSectionGhostGuideRepeatLineTarget': '',
          'phoneCameraBackupPreviousSectionGhostGuideRepeatLineTarget':
              'repeat_3_to_5_readable_lines',
          'previousSectionGhostGuidePlacement': ' ',
          'phoneCameraBackupPreviousSectionGhostGuidePlacement':
              'top_ghost_slice',
          'previousSectionGhostGuideMatchTarget': '',
          'phoneCameraBackupPreviousSectionGhostGuideMatchTarget':
              'subtotal_total_and_final_lines',
          'phoneCameraBackupPreviousSectionMissingBottomAndTotals': true,
          'receiptText': 'private receipt text should not leak',
        },
      },
    );

    _expectBottomContinuationSummary(result);
    final summary = result.privacySafeReceiptContinuationSummary.toString();
    expect(summary, contains('reason_missing_bottom_edge_and_totals'));
    expect(summary, isNot(contains('/tmp/')));
    expect(summary, isNot(contains('private receipt text')));
    final attachment = ReceiptCaptureFlow.attachmentsFromReviewResult(
      result,
      ReceiptCaptureFlowModule.expenses,
    ).single;
    expect(
      attachment.documentSignals,
      contains(
        'receipt_continuation_ghost_policy_bottom_overlap_ghost_at_top_repeat_3_to_5_lines',
      ),
    );
    expect(
      attachment.riskFlags,
      contains('ocr_source_continuation_bottom_overlap_ghost_policy'),
    );
  });

  test('continuation guide normalizes missing-bottom reason codes', () {
    final guide = ReceiptCaptureContinuationGuide.fromPreviousPhotos(
      previousPhotoPaths: const [
        '/tmp/receipt-section-1.jpg',
        ' /tmp/receipt-section-2.jpg ',
      ],
      reasonCode: ' MISSING_BOTTOM_EDGE_AND_TOTALS ',
      guidance: ' Add the bottom receipt section. ',
    );
    final options = guide.applyTo(
      const ReceiptCaptureFlowOptions(
        module: ReceiptCaptureFlowModule.expenses,
      ),
    );

    expect(guide.reasonCode, 'missing_bottom_edge_and_totals');
    expect(guide.guidePhotoPath, '/tmp/receipt-section-2.jpg');
    expect(guide.ghostSourceStartFraction, .80);
    expect(guide.ghostSourceHeightFraction, .20);
    expect(guide.ghostOpacity, .36);
    expect(options.previousSectionReasonCode, 'missing_bottom_edge_and_totals');
  });
}

void _expectBottomContinuationSummary(ReceiptPhotoReviewResult result) {
  expect(result.hasPreviousSectionContinuationRequest, isTrue);
  expect(result.hasOcrRequestedBottomSectionContinuation, isTrue);
  expect(
    result.receiptContinuationSignalCounts,
    containsPair('previous_section_guide_requested', 1),
  );
  expect(
    result.receiptContinuationSignalCounts,
    containsPair('missing_bottom_edge_and_totals_continuation', 1),
  );
  expect(
    result.receiptContinuationSignalCounts,
    containsPair(
      'ghost_policy_bottom_overlap_ghost_at_top_repeat_3_to_5_lines',
      1,
    ),
  );
  expect(
    result.receiptContinuationSignalCounts,
    containsPair('ghost_repeat_target_repeat_3_to_5_readable_lines', 1),
  );
  expect(
    result.receiptContinuationSignalCounts,
    containsPair('ghost_placement_top_ghost_slice', 1),
  );
  expect(
    result.receiptContinuationSignalCounts,
    containsPair('ghost_match_target_subtotal_total_and_final_lines', 1),
  );
  expect(
    result.receiptContinuationSignalCounts.keys.where(
      (key) => key.startsWith('ghost_slice_percent_'),
    ),
    everyElement(matches(RegExp(r'^ghost_slice_percent_\d+$'))),
  );
  expect(
    result.receiptContinuationSignalCounts,
    containsPair('ocr_requested_bottom_section', 1),
  );
  expect(
    result.privacySafeReceiptContinuationSummary.toString(),
    isNot(contains('/tmp/')),
  );
}
