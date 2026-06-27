import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  test(
    'receipt quality scoring gives real receipts a bounded review score',
    () {
      const unreadable = ReceiptPhotoQualityCheck(
        width: 0,
        height: 0,
        focusScore: 0,
        isLikelyReadable: false,
      );
      const blurry = ReceiptPhotoQualityCheck(
        width: 900,
        height: 1100,
        focusScore: 5,
        isLikelyReadable: false,
      );
      const readable = ReceiptPhotoQualityCheck(
        width: 1600,
        height: 2200,
        focusScore: 14,
        isLikelyReadable: true,
      );

      expect(unreadable.reviewScore, 0);
      expect(blurry.reviewScore, inInclusiveRange(1, 60));
      expect(readable.reviewScore, greaterThan(blurry.reviewScore));
      expect(readable.reviewScore, inInclusiveRange(80, 100));
      expect(blurry.focusLabel, 'may be blurry');
      expect(blurry.reviewTitle, 'Retake Recommended');
      expect(blurry.reviewGuidance, contains('Tap the receipt text'));
      expect(readable.focusLabel, 'sharp');
    },
  );

  test('review guidance separates soft warnings from critical retakes', () {
    const soft = ReceiptPhotoQualityCheck(
      width: 1600,
      height: 2200,
      focusScore: 7,
      brightness: 130,
      contrast: 30,
      cropScore: .7,
      textBandScore: 10,
      isLikelyReadable: false,
    );
    const glare = ReceiptPhotoQualityCheck(
      width: 1600,
      height: 2200,
      focusScore: 14,
      brightness: 240,
      contrast: 30,
      cropScore: .7,
      textBandScore: 10,
      isLikelyReadable: false,
    );

    expect(soft.needsReview, isTrue);
    expect(soft.hasCriticalIssue, isFalse);
    expect(soft.canContinueWithReview, isTrue);
    expect(soft.reviewTitle, 'Check Before Continuing');
    expect(soft.reviewGuidance, contains('Zoom in and check'));
    expect(glare.hasCriticalIssue, isTrue);
    expect(glare.canContinueWithReview, isFalse);
    expect(glare.reviewTitle, 'Retake Recommended');
    expect(glare.reviewGuidance, contains('Reduce glare'));
  });

  test('receipt framing warnings do not fight readable dark borders', () {
    const readableWithDarkBorder = ReceiptPhotoQualityCheck(
      width: 1600,
      height: 2200,
      focusScore: 14,
      brightness: 135,
      contrast: 34,
      cropScore: .32,
      textBandScore: 12,
      isLikelyReadable: true,
    );
    const possiblyCutOff = ReceiptPhotoQualityCheck(
      width: 1600,
      height: 2200,
      focusScore: 14,
      brightness: 135,
      contrast: 34,
      cropScore: .22,
      textBandScore: 12,
      isLikelyReadable: false,
    );

    expect(readableWithDarkBorder.isPoorlyFramed, isFalse);
    expect(readableWithDarkBorder.needsReview, isFalse);
    expect(possiblyCutOff.isPoorlyFramed, isTrue);
    expect(possiblyCutOff.hasCriticalIssue, isFalse);
    expect(possiblyCutOff.reviewGuidance, contains('If every line'));
  });

  test('camera keeps quality scoring off the live preview chrome', () async {
    final assistSource = await File(
      'lib/shared/widgets/receipt_capture/receipt_camera_assist.dart',
    ).readAsString();
    final analysisSource = await File(
      'lib/shared/widgets/receipt_capture/receipt_camera_live_analysis.dart',
    ).readAsString();
    final barsSource = await File(
      'lib/shared/widgets/receipt_capture/receipt_camera_bars.dart',
    ).readAsString();
    final screenSource = await File(
      'lib/shared/widgets/receipt_capture/receipt_camera_screen.dart',
    ).readAsString();
    final feedbackSource = await File(
      'lib/shared/widgets/receipt_capture/receipt_camera_feedback.dart',
    ).readAsString();

    expect(assistSource, contains("title: 'Add Light'"));
    expect(assistSource, contains("title: 'Reduce Glare'"));
    expect(assistSource, contains("title: 'Tap To Focus'"));
    expect(assistSource, contains("title: 'Move Closer'"));
    expect(assistSource, contains("title: 'Fill The View'"));
    expect(assistSource, contains('Capture still works.'));
    expect(assistSource, isNot(contains('Show the receipt edges')));
    expect(assistSource, contains('Color(0xFFFF4D5E)'));
    expect(assistSource, contains('Color(0xFFFFD166)'));
    expect(assistSource, contains('Color(0xFF8EF6A4)'));
    expect(analysisSource, contains('_ReceiptCameraReadiness.notReady'));
    expect(analysisSource, contains('_ReceiptCameraReadiness.almostReady'));
    expect(analysisSource, contains('_ReceiptCameraReadiness.ready'));
    expect(barsSource, isNot(contains('_CameraQualityStrip')));
    expect(barsSource, contains('_CameraModeBadge'));
    expect(screenSource, contains('onTapUp: (details) => _focusAt'));
    expect(screenSource, contains('onScaleUpdate: _updateZoomGesture'));
    expect(screenSource, contains('controller.setFocusPoint(point)'));
    expect(screenSource, contains('controller.setExposurePoint(point)'));
    expect(screenSource, contains('_resetReceiptExposureCompensation'));
    expect(screenSource, contains('controller.getMinExposureOffset()'));
    expect(screenSource, contains('controller.setExposureOffset(safeOffset)'));
    expect(screenSource, contains('Some devices expose tap focus poorly'));
    expect(screenSource, contains('_zoomUnavailableNotified'));
    expect(feedbackSource, isNot(contains('_ReceiptLongReceiptFloatingHint')));
    expect(feedbackSource, isNot(contains('Do not squeeze tiny text')));
    expect(feedbackSource, contains('_ReceiptCameraInteractionHint'));
    expect(feedbackSource, contains('_ReceiptZoomLevelBadge'));
    expect(feedbackSource, isNot(contains('showLongReceiptTip')));
  });

  test('auto capture allows stable usable receipt frames', () async {
    final screenSource = await File(
      'lib/shared/widgets/receipt_capture/receipt_camera_screen.dart',
    ).readAsString();
    final analysisSource = await File(
      'lib/shared/widgets/receipt_capture/receipt_camera_live_analysis.dart',
    ).readAsString();

    expect(analysisSource, contains('canAutoCaptureReceipt'));
    expect(analysisSource, contains('meetsAutoCapturePolicy'));
    expect(analysisSource, contains('autoCaptureStatusLabel'));
    expect(analysisSource, contains('looksReady'));
    expect(analysisSource, contains('textBandScore >= 8'));
    expect(analysisSource, contains('contrast >= 18'));
    expect(analysisSource, contains('cropScore >= .48'));
    final processorSource = await File(
      'lib/shared/widgets/receipt_capture/receipt_image_processor.dart',
    ).readAsString();
    expect(processorSource, contains('final readableCrop = cropScore >= .30'));
    expect(analysisSource, contains('policy.minimumAutoFocusScore'));
    expect(analysisSource, contains('policy.minimumAutoContrast'));
    expect(analysisSource, contains('policy.minimumAutoTextBandScore'));
    expect(analysisSource, contains('policy.minimumAutoCropScore'));
    expect(analysisSource, contains('Tap receipt text'));
    expect(analysisSource, contains('Show full receipt'));
    expect(analysisSource, contains('Square it up'));
    expect(analysisSource, contains('Move closer'));
    expect(analysisSource, isNot(contains('Waiting:')));
    expect(analysisSource, isNot(contains('Check:')));
    expect(screenSource, contains('stableQuality.meetsAutoCapturePolicy'));
    expect(screenSource, contains('_stableReadyFrameCount'));
    expect(screenSource, contains('stableQuality.stableFor'));
  });

  test(
    'auto capture policy is stricter than manual capture guidance',
    () async {
      final captureSource = await File(
        'lib/shared/widgets/receipt_capture/receipt_camera_capture.dart',
      ).readAsString();
      final feedbackSource = await File(
        'lib/shared/widgets/receipt_capture/receipt_camera_feedback.dart',
      ).readAsString();
      final screenSource = await File(
        'lib/shared/widgets/receipt_capture/receipt_camera_screen.dart',
      ).readAsString();

      expect(captureSource, contains('minimumAutoCaptureFrames'));
      expect(captureSource, contains('minimumAutoFocusScore'));
      expect(captureSource, contains('minimumAutoContrast'));
      expect(captureSource, contains('minimumAutoTextBandScore'));
      expect(captureSource, contains('minimumAutoCropScore'));
      expect(captureSource, contains('enableLiveEdgeOverlay'));
      expect(captureSource, contains('ReceiptCapabilityTier.heavyweight => 5'));
      expect(captureSource, contains('ReceiptCapabilityTier.light => false'));
      expect(feedbackSource, contains('autoCaptureReady'));
      expect(screenSource, contains('meetsAutoCapturePolicy(_capturePolicy)'));
    },
  );

  test('live edge overlay is capability gated and signal based', () async {
    final screenSource = await File(
      'lib/shared/widgets/receipt_capture/receipt_camera_screen.dart',
    ).readAsString();
    final previewSource = await File(
      'lib/shared/widgets/receipt_capture/receipt_camera_preview.dart',
    ).readAsString();
    final analysisSource = await File(
      'lib/shared/widgets/receipt_capture/receipt_camera_live_analysis.dart',
    ).readAsString();

    expect(analysisSource, contains('class _ReceiptDocumentFrame'));
    expect(analysisSource, contains('normalizedRect'));
    expect(analysisSource, contains('confidence'));
    expect(analysisSource, contains('_documentFrameFor'));
    expect(analysisSource, contains('hasUsableDocumentFrame'));
    expect(screenSource, contains('_capturePolicy.enableLiveEdgeOverlay'));
    expect(
      screenSource,
      contains('_ReceiptLiveEdgeOverlay(frame: liveFrame!)'),
    );
    expect(previewSource, contains('class _ReceiptLiveEdgeOverlay'));
    expect(previewSource, contains('IgnorePointer('));
    expect(previewSource, contains('CustomPainter'));
    expect(previewSource, isNot(contains('ReceiptCameraFrameOverlay')));
  });

  test(
    'camera setup uses capability fallbacks without raw hardware UI',
    () async {
      final setupSource = await File(
        'lib/shared/widgets/receipt_capture/receipt_camera_setup.dart',
      ).readAsString();
      final settingsSource = await File(
        'lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart',
      ).readAsString();

      expect(setupSource, contains('_capturePolicy.resolutionTier'));
      expect(setupSource, contains('ReceiptCameraResolutionTier.medium'));
      expect(setupSource, contains('ResolutionPreset.medium'));
      expect(setupSource, contains('ReceiptCameraResolutionTier.high'));
      expect(setupSource, contains('ResolutionPreset.high'));
      expect(setupSource, contains('ReceiptCameraResolutionTier.max'));
      expect(setupSource, contains('ResolutionPreset.veryHigh'));

      expect(settingsSource, contains('Receipt Scanner'));
      expect(
        settingsSource,
        contains('Android, it opens the phone camera first'),
      );
      expect(settingsSource, contains('Google Play Services scanner update'));
      expect(settingsSource, isNot(contains('deviceModel')));
      expect(settingsSource, isNot(contains('availableRamLabel')));
      expect(settingsSource, isNot(contains('cpuCoresLabel')));
      expect(settingsSource, isNot(contains('Android SDK')));
    },
  );

  test('fallback camera keeps manual shutter available', () async {
    final screenSource = await File(
      'lib/shared/widgets/receipt_capture/receipt_camera_screen.dart',
    ).readAsString();
    final barsSource = await File(
      'lib/shared/widgets/receipt_capture/receipt_camera_bars.dart',
    ).readAsString();
    final settingsSource = await File(
      'lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart',
    ).readAsString();

    expect(screenSource, contains('void _handleCapturePressed()'));
    expect(screenSource, contains('unawaited(_capturePhoto());'));
    expect(
      screenSource,
      contains('settleDelay: _capturePolicy.manualSettleDelay'),
    );
    expect(
      screenSource,
      contains('settleDelay: _capturePolicy.assistedSettleDelay'),
    );
    expect(
      screenSource.indexOf('settleDelay: _capturePolicy.manualSettleDelay'),
      lessThan(
        screenSource.indexOf('final candidates = <_ReceiptCameraCandidate>[]'),
      ),
    );
    expect(
      screenSource,
      isNot(contains('Photo captured. Review the store, date, total')),
    );
    expect(
      screenSource,
      isNot(contains('_handleCapturePressed() {\n    if (_mode')),
    );
    expect(barsSource, contains("'Tap shutter'"));
    expect(barsSource, contains("'Tap anytime'"));
    expect(barsSource, contains('_CameraShutterButton'));
    expect(barsSource, contains('onPressed: capturing ? null : onCapture'));
    final captureSource = await File(
      'lib/shared/widgets/receipt_capture/receipt_camera_capture.dart',
    ).readAsString();
    expect(
      captureSource,
      contains('manualSettleDelay => const Duration(milliseconds: 120)'),
    );
    expect(
      captureSource,
      contains('assistedSettleDelay => const Duration(milliseconds: 520)'),
    );
    expect(settingsSource, contains('Receipt Scanner'));
    expect(settingsSource, isNot(contains('Let Camera Take Photo When Ready')));
  });
}
