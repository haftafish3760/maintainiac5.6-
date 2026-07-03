import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/receipts/receipt_processing_contract.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_ocr_service.dart';

void main() {
  test('camera results carry privacy-safe native capture evidence', () {
    const evidence = ReceiptCameraCaptureEvidence(
      captureSurface: 'maintainiac_native_android',
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
      captureSurface: 'maintainiac_native_ios',
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

  test('camera result converts native evidence into per-photo diagnostics', () {
    const quality = ReceiptPhotoQualityCheck(
      width: 1400,
      height: 2200,
      focusScore: 9,
      brightness: 62,
      isLikelyReadable: false,
    );
    const evidence = ReceiptCameraCaptureEvidence(
      captureSurface: 'maintainiac_native_android',
      captureFlow: 'assisted',
      resolutionTier: 'high',
      resolutionPreset: 'veryHigh',
      flashMode: 'off',
      exposureMode: 'auto',
      focusMode: 'continuous',
      exposurePointSupported: true,
      focusPointSupported: true,
      exposureOffset: 0,
      minExposureOffset: -2,
      maxExposureOffset: 2,
      zoomLevel: 1.4,
      minZoomLevel: 1,
      maxZoomLevel: 10,
      previewWidth: 1920,
      previewHeight: 1080,
      liveBrightness: 64,
      liveContrast: 22,
      liveFocusScore: 10,
      liveReadiness: 'move_closer',
      imageStreamActiveAtCapture: true,
      selectedExposureOffset: .5,
      candidateExposureOffsets: [0, .5],
    );
    const result = ReceiptCameraResult.single(
      ['/tmp/receipt-a.jpg'],
      qualityChecks: [quality],
      captureEvidence: evidence,
    );

    final diagnostics = result.captureDiagnosticsByPhotoPath([
      '/tmp/receipt-a.jpg',
    ]);
    final photoDiagnostics = diagnostics['/tmp/receipt-a.jpg']!;

    expect(photoDiagnostics['engine'], 'maintainiac_native_android');
    expect(photoDiagnostics['captureFlow'], 'assisted');
    expect(photoDiagnostics['captureFallbackSource'], 'receipt_camera_result');
    expect(photoDiagnostics['latestBrightnessBucket'], 'dim');
    expect(photoDiagnostics['latestCapturedBrightnessBucket'], 'dim');
    expect(
      photoDiagnostics['latestCapturedSharpnessBucket'],
      'captured_usable',
    );
    expect(
      photoDiagnostics['latestCapturedQualitySignal'],
      'captured_needs_review',
    );
    expect(
      photoDiagnostics['latestCapturedQualityAction'],
      'retake_recommended_continue_allowed',
    );
    expect(photoDiagnostics['latestCapturedQualityActionFamily'], 'retake');
    expect(
      photoDiagnostics['latestCapturedExposureMismatch'],
      'live_dim_capture_dim',
    );
    expect(photoDiagnostics['selectedExposureBucket'], 'exposure_brighter');
    expect(
      photoDiagnostics['scannerDecisionCodes'],
      containsAll([
        'receipt_camera_result_bridge',
        'live_preview_dark',
        'live_preview_underexposed',
        'captured_needs_review',
      ]),
    );
    expect(
      photoDiagnostics.toString().toLowerCase(),
      isNot(contains('lowe private fixture')),
    );
    expect(photoDiagnostics.toString().toLowerCase(), isNot(contains('7.99')));
  });

  test('camera result rejects ambiguous duplicate photo diagnostic paths', () {
    const firstQuality = ReceiptPhotoQualityCheck(
      width: 1400,
      height: 2200,
      focusScore: 14,
      brightness: 142,
      isLikelyReadable: true,
    );
    const secondQuality = ReceiptPhotoQualityCheck(
      width: 1400,
      height: 2200,
      focusScore: 5,
      brightness: 48,
      isLikelyReadable: false,
    );
    const evidence = ReceiptCameraCaptureEvidence(
      captureSurface: 'maintainiac_native_android',
      captureFlow: 'assisted',
      resolutionTier: 'high',
      resolutionPreset: 'veryHigh',
      flashMode: 'off',
      exposureMode: 'auto',
      focusMode: 'continuous',
      exposurePointSupported: true,
      focusPointSupported: true,
      exposureOffset: 0,
      minExposureOffset: -2,
      maxExposureOffset: 2,
      zoomLevel: 1.4,
      minZoomLevel: 1,
      maxZoomLevel: 10,
      previewWidth: 1920,
      previewHeight: 1080,
      liveBrightness: 140,
      liveContrast: 22,
      liveFocusScore: 10,
      liveReadiness: 'ready',
      imageStreamActiveAtCapture: true,
    );
    const duplicateResult = ReceiptCameraResult.single(
      ['/tmp/section.jpg', '/tmp/section.jpg'],
      qualityChecks: [firstQuality, secondQuality],
      captureEvidence: evidence,
    );
    const uniqueResult = ReceiptCameraResult.single(
      ['/tmp/section-a.jpg', '/tmp/section-b.jpg'],
      qualityChecks: [firstQuality, secondQuality],
      captureEvidence: evidence,
    );

    expect(
      duplicateResult.captureDiagnosticsByPhotoPath(const ['/tmp/section.jpg']),
      isEmpty,
    );
    expect(
      uniqueResult.captureDiagnosticsByPhotoPath(const [
        '/tmp/section-a.jpg',
        '/tmp/section-a.jpg',
      ]),
      isEmpty,
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
      brightness: 250,
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
        'PDF receipt assistance could not find text in one PDF.',
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
