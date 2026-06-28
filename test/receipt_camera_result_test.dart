import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/receipts/receipt_processing_contract.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_ocr_service.dart';

void main() {
  test('photo review results freeze accepted camera diagnostics', () {
    const quality = ReceiptPhotoQualityCheck(
      width: 1200,
      height: 1800,
      focusScore: 12,
      isLikelyReadable: true,
    );
    final photoPaths = ['/tmp/proof.jpg'];
    final ocrPaths = ['/tmp/ocr.jpg'];
    final qualityByPath = {'/tmp/proof.jpg': quality};
    final prepDiagnostics = {
      '/tmp/ocr.jpg': {
        'usedEnhancedOcrSource': true,
        'cleanupActions': ['grayscale'],
        'scannerDecisionCodes': [
          'cleanup_applied_dark_receipt',
          'ocr_source_enhanced_selected',
        ],
      },
    };
    final captureDiagnostics = {
      '/tmp/proof.jpg': {
        'latestBrightnessBucket': 'good',
        'pinchZoomEnabled': true,
      },
    };

    final result = ReceiptPhotoReviewResult(
      photoPaths: photoPaths,
      ocrSourcePhotoPaths: ocrPaths,
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: ReceiptStitchResult.notNeeded(ocrPaths),
      photoQualityChecksByPath: qualityByPath,
      preparationDiagnosticsByOcrPath: prepDiagnostics,
      captureDiagnosticsByPhotoPath: captureDiagnostics,
    );

    photoPaths.add('/tmp/late-proof.jpg');
    ocrPaths.add('/tmp/late-ocr.jpg');
    qualityByPath.clear();
    prepDiagnostics['/tmp/ocr.jpg']!['usedEnhancedOcrSource'] = false;
    captureDiagnostics['/tmp/proof.jpg']!['latestBrightnessBucket'] = 'dark';

    expect(result.photoPaths, ['/tmp/proof.jpg']);
    expect(result.ocrSourcePhotoPaths, ['/tmp/ocr.jpg']);
    expect(result.photoQualityChecksByPath['/tmp/proof.jpg'], quality);
    expect(
      result
          .preparationDiagnosticsByOcrPath['/tmp/ocr.jpg']!['usedEnhancedOcrSource'],
      isTrue,
    );
    expect(result.scannerDecisionCodes, [
      'cleanup_applied_dark_receipt',
      'ocr_source_enhanced_selected',
    ]);
    expect(result.scannerDecisionCounts['cleanup_applied_dark_receipt'], 1);
    expect(result.scannerUsedEnhancedOcrSource, isTrue);
    expect(result.scannerKeptOriginalForQuality, isFalse);
    expect(result.scannerNeedsOperatorReview, isFalse);
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
  });

  test('photo review result summarizes scanner prep concerns', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/proof.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: const ReceiptStitchResult.notNeeded(['/tmp/ocr.jpg']),
      preparationDiagnosticsByOcrPath: const {
        '/tmp/ocr.jpg': {
          'scannerDecisionCodes': [
            'crop_skipped_bounds_off_center_x',
            'perspective_skipped_bounds_off_center_x',
            'cleanup_skipped_quality_guard',
            'ocr_source_original_selected_quality_guard',
          ],
        },
      },
    );

    expect(result.scannerDecisionCounts['crop_skipped_bounds_off_center_x'], 1);
    expect(
      result.scannerDecisionCounts['perspective_skipped_bounds_off_center_x'],
      1,
    );
    expect(result.scannerDecisionCounts['cleanup_skipped_quality_guard'], 1);
    expect(result.scannerKeptOriginalForQuality, isTrue);
    expect(result.scannerUsedEnhancedOcrSource, isFalse);
    expect(result.scannerNeedsOperatorReview, isTrue);
  });

  test('best shot camera results preserve quality checks by index', () {
    const first = ReceiptPhotoQualityCheck(
      width: 1800,
      height: 2400,
      focusScore: 16,
      isLikelyReadable: true,
    );
    const second = ReceiptPhotoQualityCheck(
      width: 1200,
      height: 1600,
      focusScore: 10,
      isLikelyReadable: true,
    );

    const result = ReceiptCameraResult.bestShotCandidates(
      ['/tmp/best.jpg', '/tmp/backup.jpg'],
      qualityChecks: [first, second],
    );

    expect(result.isBestShotCandidateSet, isTrue);
    expect(result.qualityForIndex(0), first);
    expect(result.qualityForIndex(1), second);
    expect(result.qualityForIndex(2), isNull);
  });

  test(
    'receipt quality scores rank sharper higher resolution photos higher',
    () {
      const strong = ReceiptPhotoQualityCheck(
        width: 1800,
        height: 2400,
        focusScore: 16,
        isLikelyReadable: true,
        brightness: 142,
        contrast: 42,
        cropScore: .78,
        textBandScore: 14,
      );
      const weak = ReceiptPhotoQualityCheck(
        width: 700,
        height: 900,
        focusScore: 5,
        isLikelyReadable: false,
        brightness: 90,
        contrast: 12,
        cropScore: .32,
        textBandScore: 3,
      );

      expect(strong.reviewScore, greaterThan(weak.reviewScore));
      expect(strong.reviewScoreLabel, endsWith('%'));
      expect(weak.reviewScore, inInclusiveRange(0, 100));
      expect(strong.brightnessDistanceFromReceiptIdeal, 8);
      expect(weak.qualityWarnings, isNotEmpty);
      expect(weak.primaryIssueLabel, 'looks blurry');
      expect(weak.hasCriticalIssue, isTrue);
      expect(weak.reviewTitle, 'Retake Recommended');
    },
  );

  test('camera result summarizes best candidate quality and review state', () {
    const dim = ReceiptPhotoQualityCheck(
      width: 1800,
      height: 2400,
      focusScore: 15,
      brightness: 42,
      contrast: 35,
      cropScore: .7,
      textBandScore: 12,
      isLikelyReadable: false,
    );
    const readable = ReceiptPhotoQualityCheck(
      width: 1600,
      height: 2200,
      focusScore: 13,
      brightness: 150,
      contrast: 38,
      cropScore: .76,
      textBandScore: 12,
      isLikelyReadable: true,
    );

    const result = ReceiptCameraResult.bestShotCandidates(
      ['/tmp/dim.jpg', '/tmp/readable.jpg'],
      qualityChecks: [dim, readable],
    );

    expect(result.hasQuestionablePhoto, isTrue);
    expect(result.bestQualityCheck, readable);
    expect(result.qualitySummaryLabel, contains('Best of 2 photos'));
    expect(result.qualitySummaryLabel, contains('looks readable'));
  });

  test('soft but usable photos warn without becoming retake blockers', () {
    const soft = ReceiptPhotoQualityCheck(
      width: 1600,
      height: 2200,
      focusScore: 7,
      brightness: 142,
      contrast: 34,
      cropScore: .72,
      textBandScore: 12,
      isLikelyReadable: false,
    );

    expect(soft.needsReview, isTrue);
    expect(soft.hasCriticalIssue, isFalse);
    expect(soft.canContinueWithReview, isTrue);
    expect(soft.primaryIssueLabel, 'check sharpness');
    expect(soft.reviewTitle, 'Readable receipt photo');
    expect(soft.reviewGuidance, contains('Zoom in and check'));
  });

  test('single camera results may carry a photo quality check', () {
    const quality = ReceiptPhotoQualityCheck(
      width: 1400,
      height: 1900,
      focusScore: 12,
      isLikelyReadable: true,
    );

    const result = ReceiptCameraResult.single(
      ['/tmp/receipt.jpg'],
      qualityChecks: [quality],
    );

    expect(result.isBestShotCandidateSet, isFalse);
    expect(result.qualityForIndex(0), quality);
  });

  test('camera results carry privacy-safe native capture evidence', () {
    const evidence = ReceiptCameraCaptureEvidence(
      captureSurface: 'flutter_camera_native_backend',
      captureFlow: 'assisted',
      resolutionTier: 'high',
      resolutionPreset: 'veryHigh',
      flashMode: 'off',
      exposureMode: 'auto',
      focusMode: 'auto',
      exposurePointSupported: true,
      focusPointSupported: true,
      exposureOffset: 0,
      minExposureOffset: -2,
      maxExposureOffset: 2,
      zoomLevel: 1,
      minZoomLevel: 1,
      maxZoomLevel: 10,
      previewWidth: 1920,
      previewHeight: 1080,
      liveBrightness: 54,
      liveContrast: 24,
      liveFocusScore: 12,
      liveReadiness: 'notReady',
      imageStreamActiveAtCapture: false,
      selectedExposureOffset: .32,
      candidateExposureOffsets: [0, .32],
    );

    const result = ReceiptCameraResult.bestShotCandidates([
      '/tmp/receipt.jpg',
    ], captureEvidence: evidence);

    expect(result.captureEvidence, evidence);
    expect(evidence.usesNativeAutoExposure, isTrue);
    expect(evidence.exposureAtNativeBaseline, isFalse);
    expect(evidence.selectedExposureOffset, .32);
    expect(evidence.candidateExposureOffsets, [0, .32]);
    expect(evidence.hasDarkLiveFrame, isTrue);
    expect(evidence.brightnessSummaryLabel, 'Live preview was dark');
    expect(
      evidence.exposureSummaryLabel,
      'Bracketed brighter exposure candidate',
    );

    const underexposedEvidence = ReceiptCameraCaptureEvidence(
      captureSurface: 'flutter_camera_native_backend',
      captureFlow: 'manual',
      resolutionTier: 'high',
      resolutionPreset: 'veryHigh',
      flashMode: 'off',
      exposureMode: 'auto',
      focusMode: 'auto',
      exposurePointSupported: true,
      focusPointSupported: true,
      exposureOffset: 0,
      minExposureOffset: -2,
      maxExposureOffset: 2,
      zoomLevel: 1,
      minZoomLevel: 1,
      maxZoomLevel: 10,
      previewWidth: 1920,
      previewHeight: 1080,
      liveBrightness: 88,
      liveContrast: 30,
      liveFocusScore: 12,
      liveReadiness: 'ready',
      imageStreamActiveAtCapture: false,
    );
    expect(underexposedEvidence.hasDarkLiveFrame, isFalse);
    expect(underexposedEvidence.hasUnderexposedLiveFrame, isTrue);
    expect(
      underexposedEvidence.brightnessSummaryLabel,
      'Live preview was darker than ideal',
    );
    expect(
      underexposedEvidence.exposureSummaryLabel,
      'Native auto exposure baseline',
    );
  });

  test('photo quality gives clear dark and glare retake guidance', () {
    const dark = ReceiptPhotoQualityCheck(
      width: 1400,
      height: 2200,
      focusScore: 14,
      brightness: 48,
      contrast: 30,
      isLikelyReadable: false,
    );
    const glare = ReceiptPhotoQualityCheck(
      width: 1400,
      height: 2200,
      focusScore: 14,
      brightness: 235,
      contrast: 30,
      isLikelyReadable: false,
    );

    expect(dark.hasCriticalIssue, isTrue);
    expect(dark.primaryIssueLabel, 'too dark');
    expect(dark.reviewTitle, 'Retake Recommended');
    expect(dark.reviewGuidance, contains('Add light or turn on the torch'));
    expect(glare.hasCriticalIssue, isTrue);
    expect(glare.primaryIssueLabel, 'glare or too bright');
    expect(glare.reviewGuidance, contains('Reduce glare by tilting'));
  });

  test('ocr result promotes strongest warning into user action copy', () {
    const result = ReceiptOcrResult(
      rawText: '',
      parserText: '',
      textByAttachmentId: {},
      source: ReceiptProcessingSource.photo,
      warnings: [
        'Repeated receipt text was ignored.',
        'No readable receipt text was found.',
      ],
    );

    expect(result.primaryWarning?.kind, ReceiptOcrWarningKind.noReadableText);
    expect(result.strongestActionMessage, contains('No readable text'));
    expect(result.strongestActionMessage, contains('Retake the photo'));
    expect(
      result.reviewMessage(successMessage: 'Receipt photo was read.'),
      contains('No readable text'),
    );
    expect(
      result.reviewMessage(successMessage: 'Receipt photo was read.'),
      isNot(contains('Repeated receipt text was ignored.')),
    );
  });

  test('ocr result explains warning review burden before saving', () {
    const result = ReceiptOcrResult(
      rawText: 'LOWES\nTOTAL 3.24',
      parserText: 'LOWES\nTOTAL 3.24',
      textByAttachmentId: {'photo-1': 'LOWES\nTOTAL 3.24'},
      source: ReceiptProcessingSource.photo,
      stats: ReceiptOcrReadStats(photosRead: 1),
      warnings: ['Repeated receipt text was ignored.'],
    );

    final message = result.reviewMessage(
      successMessage: 'Receipt photo was read.',
    );

    expect(result.hasText, isTrue);
    expect(result.primaryWarning?.kind, ReceiptOcrWarningKind.duplicateText);
    expect(message, contains('Receipt photo was read.'));
    expect(message, contains('Read 1 receipt photo.'));
    expect(message, contains('Duplicate lines ignored.'));
    expect(
      message,
      contains('Compare the filled form with the receipt proof before saving.'),
    );
  });

  test('ocr warnings target the exact receipt area to review', () {
    final overlap = ReceiptOcrWarning.fromMessage(
      'Repeated receipt text was ignored.',
    );
    final missingSection = ReceiptOcrWarning.fromMessage(
      'Possible missing receipt section between photos.',
    );
    final photoQuality = ReceiptOcrWarning.fromMessage(
      'Receipt photo quality warning: bottom section may be soft.',
    );

    expect(overlap.reviewTargetLabel, 'Check long receipt overlap');
    expect(
      overlap.reviewTargetInstruction,
      contains('same charge was not counted twice'),
    );
    expect(missingSection.reviewTargetLabel, 'Check missing receipt section');
    expect(
      missingSection.reviewTargetInstruction,
      contains('receipt photos from top to bottom'),
    );
    expect(photoQuality.reviewTargetLabel, 'Check photo proof');
    expect(
      photoQuality.reviewTargetInstruction,
      contains('store, date, total, tax, and item prices'),
    );
  });

  test('ocr warning priority puts blockers before review warnings', () {
    const result = ReceiptOcrResult(
      rawText: 'LOWES\nTOTAL 3.24',
      parserText: 'LOWES\nTOTAL 3.24',
      textByAttachmentId: {'photo-1': 'LOWES\nTOTAL 3.24'},
      source: ReceiptProcessingSource.photo,
      warnings: [
        'Repeated receipt text was ignored.',
        'Receipt photo quality warning: bottom section may be soft.',
        'PDF receipt reading could not read one PDF.',
      ],
    );

    expect(
      result.structuredWarnings.first.kind,
      ReceiptOcrWarningKind.duplicateText,
    );
    expect(result.primaryWarning?.kind, ReceiptOcrWarningKind.pdfReadFailure);
    expect(
      result.diagnostics.primaryWarningKind,
      ReceiptOcrWarningKind.pdfReadFailure.name,
    );
    expect(result.diagnostics.primaryWarningLabel, 'PDF read failed');
    expect(result.diagnostics.primaryWarningTargetLabel, 'Check receipt PDF');
    expect(
      result.diagnostics.primaryWarningTargetInstruction,
      contains('Attach a clearer PDF'),
    );
    expect(result.prioritizedWarnings.map((warning) => warning.kind), [
      ReceiptOcrWarningKind.pdfReadFailure,
      ReceiptOcrWarningKind.duplicateText,
      ReceiptOcrWarningKind.photoQuality,
    ]);
  });
}
