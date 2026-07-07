import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  test('photo review result summarizes saved-photo camera warnings', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/dim.jpg', '/tmp/readable.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/dim-ocr.jpg', '/tmp/readable-ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: ReceiptStitchResult.notNeeded([
        '/tmp/dim-ocr.jpg',
        '/tmp/readable-ocr.jpg',
      ]),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/dim.jpg': {
          'latestCapturedExposureMismatch': 'live_ok_capture_dim',
          'latestCapturedBrightnessBucket': 'captured_dim',
          'latestCapturedAverageLuma': 91.2,
          'latestCapturedEdgeScore': 8.4,
        },
        '/tmp/readable.jpg': {
          'latestCapturedExposureMismatch': 'live_ok_capture_dim',
          'latestCapturedBrightnessBucket': 'captured_dim',
          'latestCapturedAverageLuma': 102.4,
          'latestCapturedEdgeScore': 18.6,
        },
      },
    );

    expect(result.hasSavedPhotoQualityWarning, isTrue);
    expect(result.savedPhotoWarningCodes, ['saved_photo_dimmer_than_preview']);
    expect(result.savedPhotoWarningSeverities, ['warning']);
    expect(
      result.savedPhotoWarningCounts['saved_photo_dimmer_than_preview'],
      1,
    );
    expect(result.savedPhotoWarningCauseCounts, {
      'saved_photo_dim_or_live_to_saved_mismatch': 1,
    });
    expect(
      result.privacySafeOcrHandoffEvidenceLabel,
      contains('saved=saved_warning_warning'),
    );
    expect(result.savedPhotoWarningSeverityCounts['warning'], 1);
    expect(result.savedPhotoParserRiskCounts, {'ocr_text_may_need_review': 1});
    expect(result.savedPhotoWarningReviewActionLabels, [
      'Check readability, then add light if needed',
    ]);
    expect(
      result.acceptedPhotoWarningReviewActionLabel,
      'Check readability, then add light if needed',
    );
    expect(
      result.acceptedPhotoWarningProfile,
      'saved_photo_dimmer_than_preview',
    );
    expect(
      result.acceptedPhotoHandoffActionLabel,
      'Check readability, then add light or retake if needed.',
    );
    expect(
      result.acceptedPhotoHandoffEvidenceLabel,
      contains('saved_photo_dimmer_than_preview'),
    );
    expect(
      result.privacySafeOcrHandoffEvidenceLabel,
      contains('savedProfile=saved_photo_dimmer_than_preview'),
    );
    expect(
      result.privacySafeReceiptReaderHandoffMetadata,
      containsPair(
        'acceptedPhotoWarningProfile',
        'saved_photo_dimmer_than_preview',
      ),
    );
    expect(
      result.privacySafeReceiptReaderHandoffMetadata,
      containsPair('savedPhotoWarningCauseCounts', {
        'saved_photo_dim_or_live_to_saved_mismatch': 1,
      }),
    );
    expect(
      result.privacySafeReceiptReaderHandoffMetadata,
      containsPair(
        'acceptedPhotoWarningActionLabel',
        'Check readability, then add light if needed',
      ),
    );
    expect(
      result.privacySafeReceiptReaderHandoffMetadata,
      containsPair('savedPhotoWarningReviewActions', [
        'Check readability, then add light if needed',
      ]),
    );
    expect(
      result.receiptReaderHandoffCounts['parser_risk_ocr_text_may_need_review'],
      1,
    );
    expect(
      result
          .receiptReaderHandoffCounts['saved_photo_action_review_or_add_light'],
      1,
    );
    expect(
      result.savedPhotoWarningCounts.containsKey(
        'saved_photo_darker_than_preview',
      ),
      isFalse,
    );
  });

  test('photo review result profiles dirty lens handoff warning', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/hazy.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/hazy-ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: ReceiptStitchResult.notNeeded(['/tmp/hazy-ocr.jpg']),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/hazy.jpg': {
          'latestReadabilitySignal': 'dirty_lens_or_haze',
          'latestCapturedEdgeScore': 6.0,
        },
      },
    );

    expect(result.savedPhotoWarningCodes, ['saved_photo_dirty_lens_or_haze']);
    expect(
      result.acceptedPhotoWarningProfile,
      'saved_photo_dirty_lens_or_haze',
    );
    expect(result.savedPhotoWarningReviewActionLabels, ['Wipe lens or retake']);
    expect(
      result.acceptedPhotoHandoffActionLabel,
      'Wipe the lens or retake before relying on automatic fill.',
    );
    expect(
      result.receiptReaderHandoffCounts['parser_risk_ocr_hazy_text_may_fail'],
      1,
    );
    expect(
      result
          .receiptReaderHandoffCounts['saved_photo_action_wipe_lens_or_retake'],
      1,
    );
  });

  test('bare readability advisories do not create saved-photo warnings', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/advisory-shadow.jpg', '/tmp/advisory-haze.jpg'],
      ocrSourcePhotoPaths: const [
        '/tmp/advisory-shadow-ocr.jpg',
        '/tmp/advisory-haze-ocr.jpg',
      ],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: ReceiptStitchResult.notNeeded([
        '/tmp/advisory-shadow-ocr.jpg',
        '/tmp/advisory-haze-ocr.jpg',
      ]),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/advisory-shadow.jpg': {'latestReadabilitySignal': 'shadow_risk'},
        '/tmp/advisory-haze.jpg': {
          'latestReadabilitySignal': 'dirty_lens_or_haze',
        },
      },
    );

    expect(result.savedPhotoWarningCodes, isEmpty);
    expect(result.acceptedPhotoWarningProfile, 'saved_photo_ok');
    expect(result.hasSavedPhotoQualityWarning, isFalse);
  });

  test('shadow advisory needs captured luma and edge evidence', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/shadow.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/shadow-ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: ReceiptStitchResult.notNeeded(['/tmp/shadow-ocr.jpg']),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/shadow.jpg': {
          'latestReadabilitySignal': 'shadow_risk',
          'latestCapturedAverageLuma': 82.0,
          'latestCapturedEdgeScore': 6.0,
        },
      },
    );

    expect(result.savedPhotoWarningCodes, ['saved_photo_shadow_risk']);
    expect(result.savedPhotoWarningCauseCounts, {
      'uneven_shadow_over_receipt_text': 1,
    });
  });
}
