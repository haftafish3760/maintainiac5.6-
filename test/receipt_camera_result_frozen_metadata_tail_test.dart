import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

import 'helpers/receipt_camera_result_frozen_fixture.dart';

void main() {
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
          'The receipt photo is ready for review.',
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
          'receiptReaderHandoffOcrSourceRelationship',
          'prepared_clear_source',
        ),
      );
      expect(
        handoffMetadata,
        containsPair(
          'receiptDetailsHandoffOcrSourceRelationship',
          'prepared_clear_source',
        ),
      );
      expect(
        handoffMetadata,
        containsPair(
          'ocrSourceFirstActionLabel',
          'Receipt details use the prepared photo before the saved copy',
        ),
      );
      expect(
        handoffMetadata,
        containsPair('nativeReceiptReviewDepth', 'detailedLines'),
      );
      expect(
        handoffMetadata,
        containsPair('receiptProofDataSaverLevel', 'balanced'),
      );
      expect(
        handoffMetadata,
        containsPair('receiptProofTargetPolicyCode', 'normal_proof_800_1000kb'),
      );
      expect(
        handoffMetadata,
        containsPair('receiptProofTargetBytes', 900 * 1024),
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
