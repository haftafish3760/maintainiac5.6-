import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

import 'helpers/receipt_camera_capture_layout_source_readers.dart';

void main() {
  test('receipt coverage decision softens readable native cutoff warnings', () {
    const quality = ReceiptPhotoQualityCheck(
      width: 1600,
      height: 2200,
      focusScore: 14,
      brightness: 136,
      contrast: 32,
      cropScore: .70,
      textBandScore: 12,
      isLikelyReadable: true,
    );

    final decision = ReceiptPhotoCoverageDecision.fromSignals(
      quality: quality,
      diagnostics: const {
        'latestFramingSignal': 'possibly_cut_off',
        'latestPerspectiveReadiness': 'perspective_skipped_cut_off_risk',
        'latestEdgeCoverage': .88,
      },
    );

    expect(decision.status, ReceiptPhotoCoverageStatus.likelyComplete);
    expect(decision.reasonCode, 'native_cut_off_readable_check');
    expect(decision.shouldPromptForMorePhotos, isFalse);
    expect(decision.shouldEmphasizeAddPhoto, isFalse);
    expect(decision.title, 'Check Receipt Edges');
    expect(decision.guidance, contains('use this photo if nothing is missing'));
  });

  test(
    'receipt coverage decision still prompts for weak native cutoff photos',
    () {
      const quality = ReceiptPhotoQualityCheck(
        width: 1600,
        height: 2200,
        focusScore: 7,
        brightness: 104,
        contrast: 18,
        cropScore: .26,
        textBandScore: 4,
        isLikelyReadable: false,
      );

      final decision = ReceiptPhotoCoverageDecision.fromSignals(
        quality: quality,
        diagnostics: const {
          'latestFramingSignal': 'possibly_cut_off',
          'latestPerspectiveReadiness': 'perspective_skipped_cut_off_risk',
          'latestEdgeCoverage': .48,
        },
      );

      expect(decision.status, ReceiptPhotoCoverageStatus.likelyCutOff);
      expect(decision.reasonCode, 'native_cut_off_risk');
      expect(decision.shouldPromptForMorePhotos, isTrue);
      expect(decision.shouldEmphasizeAddPhoto, isTrue);
    },
  );

  test('receipt coverage prompts when native framing says text is tiny', () {
    final decision = ReceiptPhotoCoverageDecision.fromSignals(
      quality: const ReceiptPhotoQualityCheck(
        width: 1600,
        height: 2200,
        focusScore: 14,
        brightness: 132,
        contrast: 30,
        cropScore: .62,
        textBandScore: 10,
        isLikelyReadable: true,
      ),
      diagnostics: const {
        'latestFramingSignal': 'framing_ok',
        'latestFramingWidthRatio': .38,
        'latestFramingHeightRatio': .74,
      },
    );

    expect(decision.status, ReceiptPhotoCoverageStatus.maybeContinues);
    expect(decision.reasonCode, 'text_may_be_too_small');
    expect(decision.shouldPromptForMorePhotos, isTrue);
    expect(decision.guidance, contains('closer photos from top to bottom'));
  });

  test('receipt coverage decision accepts readable framed photos', () {
    const quality = ReceiptPhotoQualityCheck(
      width: 1800,
      height: 2600,
      focusScore: 15,
      brightness: 148,
      contrast: 36,
      cropScore: .70,
      textBandScore: 12,
      isLikelyReadable: true,
    );

    final decision = ReceiptPhotoCoverageDecision.fromSignals(
      quality: quality,
      diagnostics: const {
        'latestFramingSignal': 'framing_ok',
        'latestPerspectiveReadiness': 'perspective_ready_safe_bounds',
        'latestEdgeCoverage': .62,
      },
    );

    expect(decision.status, ReceiptPhotoCoverageStatus.likelyComplete);
    expect(decision.shouldPromptForMorePhotos, isFalse);
    expect(decision.isLikelyComplete, isTrue);
    expect(decision.guidance, contains('Use this photo'));
  });

  test('native camera contract carries user control and OCR-first rules', () async {
    final contract = await readReceiptNativeCameraContractSource();
    final androidActivity = await readAndroidReceiptCameraUnit();
    final iosController = await readIosReceiptCameraUnit();

    expect(contract, contains('manualShutterAlwaysAvailable = true'));
    expect(contract, contains('autoCaptureEnabled = false'));
    expect(contract, contains('tapFocusEnabled = false'));
    expect(contract, contains('pinchZoomEnabled = true'));
    expect(contract, contains('exposureSliderEnabled = true'));
    expect(contract, contains('motionBlurWarningEnabled = true'));
    expect(contract, contains('glareWarningEnabled = true'));
    expect(contract, contains('shadowWarningEnabled = true'));
    expect(contract, contains('edgeDetectionEnabled = true'));
    expect(contract, contains('previousSectionGhostGuideEnabled = true'));
    expect(contract, contains('ocrUsesOriginalFirst = true'));
    expect(contract, contains('queueAcceptedCaptureLocally = true'));
    expect(
      androidActivity,
      contains(
        'readabilityGuidancePolicy == "experimental_live_receipt_quality_opt_in"',
      ),
    );
    expect(
      iosController,
      contains(
        'readabilityGuidancePolicy == "experimental_live_receipt_quality_opt_in"',
      ),
    );
    expect(androidActivity, contains('Take receipt photo'));
    expect(androidActivity, contains('Receipt camera settings'));
    expect(androidActivity, contains('manualShutterAlwaysAvailable'));
    expect(androidActivity, contains('ocrUsesOriginalFirst'));
    expect(iosController, contains('Take receipt photo'));
    expect(iosController, contains('Receipt camera settings'));
    expect(iosController, contains('manualShutterAlwaysAvailable'));
    expect(iosController, contains('ocrUsesOriginalFirst'));
  });
}
