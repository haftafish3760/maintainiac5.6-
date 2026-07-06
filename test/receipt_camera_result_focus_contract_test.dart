import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  test('continuous focus diagnostics require matching contract tag', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/continuous-proof.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/continuous-ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: const ReceiptStitchResult.notNeeded([
        '/tmp/continuous-ocr.jpg',
      ]),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/continuous-proof.jpg': {
          'visibleControlSet':
              'back|settings|manual_shutter|status|light|brightness',
          'previewDominanceTarget': 'receipt_preview_75_80_percent',
          'settingsContractVersion': 'receipt_native_camera_settings_v1',
          'settingsButtonPlacement': 'top_bar_right',
          'nativeControlReadinessSummary': 'ready',
          'nativeControlContractTags': [
            'settings',
            'back',
            'manual_shutter',
            'pinch_zoom',
            'brightness_slider',
            'brightness_reset',
          ],
          'backControlExpected': true,
          'backControlActual': 'ready',
          'settingsControlExpected': true,
          'settingsControlActual': 'ready',
          'manualShutterAlwaysAvailable': true,
          'manualShutterControlActual': 'ready',
          'tapFocusControlExpected': false,
          'pinchZoomControlExpected': true,
          'pinchZoomControlActual': 'ready',
          'exposureSliderControlExpected': true,
          'exposureSliderControlActual': 'ready',
          'exposureResetControlExpected': true,
          'exposureResetControlActual': 'ready',
          'continuousFocusExpected': true,
          'focusStrategyPolicy': 'continuous_focus_primary_no_tap_assist',
          'lastFocusStatus': 'continuous_autofocus_configured',
          'readabilityGuidancePolicy':
              'live_receipt_workflow_guidance_only_unproven_quality_claims_off',
          'receiptCameraQualityBaseline': true,
        },
      },
    );

    expect(
      result.nativeCameraUiHealthOutcome,
      'continuous_focus_contract_missing',
    );
    expect(
      result.nativeCameraUiHealthCounts['continuous_focus_contract_missing'],
      1,
    );
  });

  test('non-continuous focus diagnostics require fallback review tag', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/fallback-proof.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/fallback-ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: const ReceiptStitchResult.notNeeded([
        '/tmp/fallback-ocr.jpg',
      ]),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/fallback-proof.jpg': {
          'visibleControlSet':
              'back|settings|manual_shutter|status|light|brightness',
          'previewDominanceTarget': 'receipt_preview_75_80_percent',
          'settingsContractVersion': 'receipt_native_camera_settings_v1',
          'settingsButtonPlacement': 'top_bar_right',
          'nativeControlReadinessSummary': 'ready',
          'nativeControlContractTags': [
            'settings',
            'back',
            'manual_shutter',
            'pinch_zoom',
            'brightness_slider',
            'brightness_reset',
          ],
          'backControlExpected': true,
          'backControlActual': 'ready',
          'settingsControlExpected': true,
          'settingsControlActual': 'ready',
          'manualShutterAlwaysAvailable': true,
          'manualShutterControlActual': 'ready',
          'tapFocusControlExpected': false,
          'pinchZoomControlExpected': true,
          'pinchZoomControlActual': 'ready',
          'exposureSliderControlExpected': true,
          'exposureSliderControlActual': 'ready',
          'exposureResetControlExpected': true,
          'exposureResetControlActual': 'ready',
          'continuousFocusExpected': false,
          'focusStrategyPolicy': 'non_continuous_focus_requires_device_review',
          'focusReadabilityFallbackPolicy':
              'non_continuous_focus_saved_photo_review_required',
          'lastFocusStatus': 'continuous_autofocus_unavailable',
          'readabilityGuidancePolicy':
              'saved_photo_readability_review_required',
          'receiptCameraQualityBaseline': false,
        },
      },
    );

    expect(result.nativeCameraUiHealthOutcome, 'continuous_focus_missing');
    expect(
      result
          .nativeCameraUiHealthCounts['focus_readability_review_contract_missing'],
      1,
    );
  });

  test('focus status must match continuous-focus expectation', () {
    final expectedButUnavailable = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/expected-focus-proof.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/expected-focus-ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: const ReceiptStitchResult.notNeeded([
        '/tmp/expected-focus-ocr.jpg',
      ]),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/expected-focus-proof.jpg': {
          'visibleControlSet':
              'back|settings|manual_shutter|status|light|brightness',
          'previewDominanceTarget': 'receipt_preview_75_80_percent',
          'settingsContractVersion': 'receipt_native_camera_settings_v1',
          'settingsButtonPlacement': 'top_bar_right',
          'nativeControlReadinessSummary': 'ready',
          'nativeControlContractTags': [
            'settings',
            'back',
            'manual_shutter',
            'continuous_focus',
            'brightness_slider',
          ],
          'backControlExpected': true,
          'backControlActual': 'ready',
          'settingsControlExpected': true,
          'settingsControlActual': 'ready',
          'manualShutterAlwaysAvailable': true,
          'manualShutterControlActual': 'ready',
          'tapFocusControlExpected': false,
          'continuousFocusExpected': true,
          'focusStrategyPolicy': 'continuous_focus_primary_no_tap_assist',
          'lastFocusStatus': 'continuous_autofocus_unavailable',
          'readabilityGuidancePolicy':
              'live_receipt_workflow_guidance_only_unproven_quality_claims_off',
          'receiptCameraQualityBaseline': true,
        },
      },
    );
    final configuredButNotExpected = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/unexpected-focus-proof.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/unexpected-focus-ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: const ReceiptStitchResult.notNeeded([
        '/tmp/unexpected-focus-ocr.jpg',
      ]),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/unexpected-focus-proof.jpg': {
          'visibleControlSet':
              'back|settings|manual_shutter|status|light|brightness',
          'previewDominanceTarget': 'receipt_preview_75_80_percent',
          'settingsContractVersion': 'receipt_native_camera_settings_v1',
          'settingsButtonPlacement': 'top_bar_right',
          'nativeControlReadinessSummary': 'ready',
          'nativeControlContractTags': [
            'settings',
            'back',
            'manual_shutter',
            'focus_readability_review',
            'brightness_slider',
          ],
          'backControlExpected': true,
          'backControlActual': 'ready',
          'settingsControlExpected': true,
          'settingsControlActual': 'ready',
          'manualShutterAlwaysAvailable': true,
          'manualShutterControlActual': 'ready',
          'tapFocusControlExpected': false,
          'continuousFocusExpected': false,
          'focusStrategyPolicy': 'non_continuous_focus_requires_device_review',
          'focusReadabilityFallbackPolicy':
              'non_continuous_focus_saved_photo_review_required',
          'lastFocusStatus': 'continuous_autofocus_configured',
          'readabilityGuidancePolicy':
              'saved_photo_readability_review_required',
          'receiptCameraQualityBaseline': false,
        },
      },
    );

    expect(
      expectedButUnavailable.nativeCameraUiHealthOutcome,
      'continuous_focus_expected_but_not_configured_regressed',
    );
    expect(
      expectedButUnavailable
          .nativeCameraUiHealthCounts['continuous_focus_expected_but_not_configured_regressed'],
      1,
    );
    expect(
      configuredButNotExpected.nativeCameraUiHealthOutcome,
      'continuous_focus_configured_when_not_expected_regressed',
    );
    expect(
      configuredButNotExpected
          .nativeCameraUiHealthCounts['continuous_focus_configured_when_not_expected_regressed'],
      1,
    );
  });
}
