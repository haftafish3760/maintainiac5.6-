import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

import 'helpers/receipt_camera_result_frozen_fixture.dart';

void main() {
  test(
    'price-only receipt review intent stays explicit in handoff metadata',
    () {
      final result = ReceiptPhotoReviewResult(
        photoPaths: const ['/tmp/proof.jpg'],
        ocrSourcePhotoPaths: const ['/tmp/proof.jpg'],
        dataSaverLevel: ReceiptDataSaverLevel.balanced,
        stitchResult: const ReceiptStitchResult.notNeeded(['/tmp/proof.jpg']),
        captureDiagnosticsByPhotoPath: const {
          '/tmp/proof.jpg': {'reviewDepth': 'pricesOnly'},
        },
      );
      final handoffMetadata = result.privacySafeReceiptReaderHandoffMetadata;

      expect(
        handoffMetadata,
        containsPair('nativeReceiptReviewDepth', 'pricesOnly'),
      );
      expect(
        handoffMetadata,
        containsPair('receiptDetailsReviewIntent', 'price_only'),
      );
      expect(
        handoffMetadata,
        containsPair('receiptDetailsLineReviewMode', 'amounts_only'),
      );
    },
  );

  test(
    'accepted review freezes receipt proof metadata and immutable diagnostics',
    () {
      final fixture = frozenReceiptCameraDiagnosticsFixture();
      final result = fixture.result;
      final handoffMetadata = result.privacySafeReceiptReaderHandoffMetadata;

      expect(
        handoffMetadata,
        containsPair(
          'nextReviewMatchReadinessOutcome',
          'single_receipt_source_ready',
        ),
      );
      expect(
        handoffMetadata,
        containsPair(
          'nextReviewMatchReadinessLabel',
          'Single receipt source is ready for app-assisted review.',
        ),
      );
      expect(
        handoffMetadata,
        containsPair(
          'ocrSourceFirstPolicy',
          'ocr_reads_clear_source_before_saved_proof',
        ),
      );
      expect(
        handoffMetadata,
        containsPair('ocrSourceFirstOutcome', 'prepared_source_ready'),
      );
      expect(
        handoffMetadata,
        containsPair(
          'ocrSourceFirstActionLabel',
          'OCR reads prepared receipt source before saved proof',
        ),
      );
      expect(
        handoffMetadata,
        containsPair('nativeReceiptReviewDepth', 'detailedLines'),
      );
      expect(
        handoffMetadata,
        containsPair('receiptDetailsReviewIntent', 'detailed_lines'),
      );
      expect(
        handoffMetadata,
        containsPair('receiptDetailsLineReviewMode', 'full_item_details'),
      );
      expect(
        handoffMetadata,
        containsPair('receiptProofDataSaverLevel', 'balanced'),
      );
      expect(
        handoffMetadata,
        containsPair('receiptProofTargetPolicyCode', 'normal_proof_200_300kb'),
      );
      expect(
        handoffMetadata,
        containsPair('receiptProofTargetBytes', 250 * 1024),
      );
      expect(
        handoffMetadata,
        containsPair('receiptProofCloudBackupDefaultAllowed', true),
      );
      expect(
        handoffMetadata,
        containsPair('receiptProofReadabilityReviewRequired', false),
      );
      expect(handoffMetadata, containsPair('ocrSourcePreparationCount', 1));
      expect(handoffMetadata['ocrSourcePreparationDecisionCounts'], {
        'cleanup_applied_dark_receipt': 1,
        'ocr_source_enhanced_selected': 1,
      });
      expect(handoffMetadata['receiptPhotoCoverageStatusCounts'], {
        ReceiptPhotoCoverageStatus.likelyComplete.name: 1,
      });
      expect(handoffMetadata['nativeCameraUiHealthCounts'], {
        'native_capture_review_transition_ready': 1,
        'native_capture_review_target_receipt_details': 1,
        'native_capture_review_discard_protected': 1,
      });
      expect(
        handoffMetadata,
        containsPair('nativeCameraUiHealthOutcome', 'native_ui_signal_missing'),
      );
      expect(result.photoCoverageStatuses, [
        ReceiptPhotoCoverageStatus.likelyComplete.name,
      ]);
      expect(
        result.photoCoverageStatusCounts[ReceiptPhotoCoverageStatus
            .likelyComplete
            .name],
        1,
      );
      expect(result.hasPossiblePartialReceiptPhotos, isFalse);
      expect(
        result
            .captureDiagnosticsByPhotoPath['/tmp/proof.jpg']!['latestBrightnessBucket'],
        'good',
      );
      expect(
        () => result.photoPaths.add('/tmp/nope.jpg'),
        throwsUnsupportedError,
      );
      expect(
        () =>
            result.captureDiagnosticsByPhotoPath['/tmp/proof.jpg']!['latestBrightnessBucket'] =
                'changed',
        throwsUnsupportedError,
      );
    },
  );
}
