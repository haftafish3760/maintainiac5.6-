import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  test(
    'native workload protection policy is summarized without receipt content',
    () {
      final result = ReceiptPhotoReviewResult(
        photoPaths: const ['/tmp/flagship.jpg', '/tmp/storage.jpg'],
        ocrSourcePhotoPaths: const ['/tmp/flagship.jpg', '/tmp/storage.jpg'],
        dataSaverLevel: ReceiptDataSaverLevel.balanced,
        stitchResult: const ReceiptStitchResult.notNeeded([
          '/tmp/flagship.jpg',
          '/tmp/storage.jpg',
        ]),
        captureDiagnosticsByPhotoPath: const {
          '/tmp/flagship.jpg': {
            'captureFlow': 'maintainiac_native_receipt_camera',
            'workloadProtectionPolicy': 'flagship_full_workload',
            'cameraWorkloadTier': 'flagship',
          },
          '/tmp/storage.jpg': {
            'captureFlow': 'maintainiac_native_receipt_camera',
            'workloadProtectionPolicy': 'storage_saver_light_workload',
            'cameraWorkloadTier': 'light',
          },
        },
      );

      expect(
        result.nativeCaptureSourcePolicyCounts,
        containsPair('flagship_native', 1),
      );
      expect(
        result.nativeCaptureSourcePolicyCounts,
        containsPair('storage_saver_native', 1),
      );
      expect(
        result.nativeCaptureSourcePolicyCounts,
        containsPair('older_phone_native', 1),
      );
      expect(result.nativeCaptureSourcePolicyOutcome, 'storage_saver_native');
      expect(
        result.privacySafeReceiptReaderHandoffMetadata,
        containsPair(
          'nativeCaptureSourcePolicyCounts',
          result.nativeCaptureSourcePolicyCounts,
        ),
      );
      expect(
        result.privacySafeReceiptReaderHandoffMetadata.toString().toLowerCase(),
        allOf(
          isNot(contains("lowe's")),
          isNot(contains('lowes')),
          isNot(contains('brodie')),
          isNot(contains('78745')),
        ),
      );
    },
  );

  test('photo review result summarizes possible partial receipt photos', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/top-proof.jpg', '/tmp/bottom-proof.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/top-ocr.jpg', '/tmp/bottom-ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: const ReceiptStitchResult.notNeeded([
        '/tmp/top-ocr.jpg',
        '/tmp/bottom-ocr.jpg',
      ]),
      captureDiagnosticsByPhotoPath: {
        '/tmp/top-proof.jpg': {
          'photoCoverageStatus': ReceiptPhotoCoverageStatus.likelyCutOff.name,
          'photoCoverageReason': 'native_cut_off_risk',
          'photoCoverageNeedsMorePhotos': true,
        },
        '/tmp/bottom-proof.jpg': {
          'photoCoverageStatus': ReceiptPhotoCoverageStatus.likelyComplete.name,
          'photoCoverageReason': 'readable_framed_photo',
          'photoCoverageNeedsMorePhotos': false,
        },
      },
    );

    expect(result.hasPossiblePartialReceiptPhotos, isTrue);
    expect(result.needsAnotherReceiptSectionBeforeDetails, isFalse);
    expect(
      result.photoCoverageStatusCounts[ReceiptPhotoCoverageStatus
          .likelyCutOff
          .name],
      1,
    );
    expect(
      result.photoCoverageStatusCounts[ReceiptPhotoCoverageStatus
          .likelyComplete
          .name],
      1,
    );
    expect(result.nextReviewUsesOrderedSections, isTrue);
    expect(result.nextReviewSourceLabel, '2 ordered receipt sections');
    expect(
      result.nextReviewHandoffLabel,
      'Receipt details open from 2 ordered receipt sections in top-to-bottom order. No stitch needed.',
    );
    expect(
      result.nextReviewDiagnosticLabel,
      'notNeeded:notNeeded:possible_partial_receipt:2:details_ready',
    );
    expect(
      result.privacySafeOcrHandoffEvidenceLabel,
      contains('coverage=possible_partial_receipt'),
    );
  });

  test(
    'single partial receipt photo recommends next section before details',
    () {
      final result = ReceiptPhotoReviewResult(
        photoPaths: const ['/tmp/top-proof.jpg'],
        ocrSourcePhotoPaths: const ['/tmp/top-ocr.jpg'],
        dataSaverLevel: ReceiptDataSaverLevel.balanced,
        stitchResult: const ReceiptStitchResult.notNeeded(['/tmp/top-ocr.jpg']),
        captureDiagnosticsByPhotoPath: const {
          '/tmp/top-proof.jpg': {
            'photoCoverageStatus': 'likelyCutOff',
            'photoCoverageReason': 'native_cut_off_risk',
            'photoCoverageNeedsMorePhotos': true,
          },
        },
      );

      expect(result.hasPossiblePartialReceiptPhotos, isTrue);
      expect(result.needsAnotherReceiptSectionBeforeDetails, isTrue);
      expect(
        result.acceptedPhotoHandoffActionLabel,
        contains('Add the next receipt section'),
      );
      expect(
        result.acceptedPhotoHandoffUserAction,
        'add_next_section_or_confirm_complete_receipt',
      );
      expect(
        result.nextReviewMatchReadinessOutcome,
        'needs_next_receipt_section',
      );
      expect(
        result.nextReviewDiagnosticLabel,
        'notNeeded:notNeeded:possible_partial_receipt:1:needs_next_section',
      );
      expect(
        result.privacySafeReceiptReaderHandoffMetadata,
        containsPair('receiptNeedsAnotherSectionBeforeDetails', true),
      );
      expect(
        result.privacySafeReceiptReaderHandoffMetadata,
        containsPair('receiptNeedsAnotherSectionReason', 'native_cut_off_risk'),
      );
    },
  );

  test(
    'ordered sections still request bottom section when final totals are missing',
    () {
      final result = ReceiptPhotoReviewResult(
        photoPaths: const ['/tmp/top-proof.jpg', '/tmp/bottom-proof.jpg'],
        ocrSourcePhotoPaths: const ['/tmp/top-ocr.jpg', '/tmp/bottom-ocr.jpg'],
        dataSaverLevel: ReceiptDataSaverLevel.balanced,
        stitchResult: const ReceiptStitchResult.notNeeded([
          '/tmp/top-ocr.jpg',
          '/tmp/bottom-ocr.jpg',
        ]),
        captureDiagnosticsByPhotoPath: const {
          '/tmp/top-proof.jpg': {
            'photoCoverageStatus': 'likelyComplete',
            'photoCoverageReason': 'readable_framed_photo',
            'photoCoverageNeedsMorePhotos': false,
          },
          '/tmp/bottom-proof.jpg': {
            'photoCoverageStatus': 'likelyCutOff',
            'photoCoverageReason': 'missing_bottom_edge_and_totals',
            'photoCoverageNeedsMorePhotos': true,
            'receiptBottomEdgeDetected': false,
            'receiptSubtotalDetected': false,
            'receiptTotalDetected': false,
            'receiptTotalAmountDetected': false,
            'receiptTotalsTextEvidenceStatus': 'missing',
          },
        },
      );

      expect(result.nextReviewUsesOrderedSections, isTrue);
      expect(result.hasPossiblePartialReceiptPhotos, isTrue);
      expect(result.finalReceiptSectionNeedsBottomTotalsContinuation, isTrue);
      expect(result.needsAnotherReceiptSectionBeforeDetails, isTrue);
      expect(
        result.firstPossiblePartialReceiptReasonCode,
        'missing_bottom_edge_and_totals',
      );
      expect(
        result.nextReviewHandoffLabel,
        contains('Add the bottom receipt section'),
      );
      expect(
        result.acceptedPhotoHandoffRoute,
        'photo_review_add_next_receipt_section',
      );
      expect(
        result.receiptCompletionReviewOutcome,
        'needs_next_section_before_details',
      );
      expect(
        result.finalReceiptSectionContinuationEvidence,
        containsPair('evidenceFamilyCount', 3),
      );
      expect(
        result.finalReceiptSectionContinuationEvidence,
        containsPair('totalsTextEvidenceStatus', 'missing'),
      );
      expect(
        result.finalReceiptSectionContinuationEvidenceLabel,
        contains('bottom edge, subtotal/total words, and total amount'),
      );
      expect(
        result.privacySafeReceiptReaderHandoffMetadata,
        containsPair(
          'receiptFinalSectionContinuationEvidence',
          result.finalReceiptSectionContinuationEvidence,
        ),
      );
      expect(
        result.privacySafeReceiptReaderHandoffMetadata.toString().toLowerCase(),
        allOf(
          isNot(contains("lowe's")),
          isNot(contains('walmart')),
          isNot(contains('brodie')),
        ),
      );
    },
  );

  test('native bottom soft status requests another section before details', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/section-proof.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/section-ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: const ReceiptStitchResult.notNeeded([
        '/tmp/section-ocr.jpg',
      ]),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/section-proof.jpg': {
          'photoCoverageStatus': 'bottom_soft_or_missing',
          'photoCoverageReason': 'missing_bottom_edge_and_totals',
          'receiptBottomEdgeDetected': false,
          'receiptSubtotalDetected': false,
          'receiptTotalDetected': false,
          'receiptTotalAmountDetected': false,
        },
      },
    );

    expect(result.hasPossiblePartialReceiptPhotos, isTrue);
    expect(result.finalReceiptSectionNeedsBottomTotalsContinuation, isTrue);
    expect(result.needsAnotherReceiptSectionBeforeDetails, isTrue);
    expect(
      result.nextReviewMatchReadinessOutcome,
      'needs_next_receipt_section',
    );
  });

  test(
    'single partial receipt photo can continue after user confirms complete',
    () {
      final result = ReceiptPhotoReviewResult(
        photoPaths: const ['/tmp/top-proof.jpg'],
        ocrSourcePhotoPaths: const ['/tmp/top-ocr.jpg'],
        dataSaverLevel: ReceiptDataSaverLevel.balanced,
        stitchResult: const ReceiptStitchResult.notNeeded(['/tmp/top-ocr.jpg']),
        captureDiagnosticsByPhotoPath: const {
          '/tmp/top-proof.jpg': {
            'photoCoverageStatus': 'likelyCutOff',
            'photoCoverageReason': 'missing_bottom_edge_and_totals',
            'photoCoverageNeedsMorePhotos': true,
            'receiptCompletionUserDecision': 'continue_anyway',
            'receiptCompletionUserConfirmedComplete': true,
            'receiptCompletionPromptReasonCode':
                'missing_bottom_edge_and_totals',
            'receiptCompletionPromptNeedsMorePhotos': true,
          },
        },
      );

      expect(result.hasPossiblePartialReceiptPhotos, isTrue);
      expect(result.userConfirmedPossiblePartialReceiptComplete, isTrue);
      expect(result.needsAnotherReceiptSectionBeforeDetails, isFalse);
      expect(
        result.receiptCompletionReviewOutcome,
        'user_confirmed_complete_after_prompt',
      );
      expect(
        result.acceptedPhotoHandoffUserAction,
        'confirm_complete_receipt_and_review_details',
      );
      expect(
        result.acceptedPhotoHandoffActionLabel,
        contains('user confirmed this photo shows the full receipt'),
      );
      expect(
        result.privacySafeOcrHandoffEvidenceLabel,
        contains('completion=user_confirmed_complete_after_prompt'),
      );
      expect(
        result.privacySafeReceiptReaderHandoffMetadata,
        containsPair('receiptNeedsAnotherSectionBeforeDetails', false),
      );
      expect(
        result.privacySafeReceiptReaderHandoffMetadata,
        containsPair(
          'receiptCompletionReviewOutcome',
          'user_confirmed_complete_after_prompt',
        ),
      );
      expect(
        result.privacySafeReceiptReaderHandoffMetadata,
        containsPair('receiptCompletionUserConfirmedComplete', true),
      );
      expect(
        result.receiptCompletionChoiceCounts,
        containsPair('continue_anyway', 1),
      );
      expect(
        result.receiptCompletionChoiceCounts,
        containsPair('reason_missing_bottom_edge_and_totals', 1),
      );
    },
  );
}
