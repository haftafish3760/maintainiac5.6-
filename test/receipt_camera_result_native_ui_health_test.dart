import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_flow.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  test(
    'photo review result flags missing native controls from contract tags',
    () {
      final result = ReceiptPhotoReviewResult(
        photoPaths: const ['/tmp/proof.jpg'],
        ocrSourcePhotoPaths: const ['/tmp/ocr.jpg'],
        dataSaverLevel: ReceiptDataSaverLevel.balanced,
        stitchResult: const ReceiptStitchResult.notNeeded(['/tmp/ocr.jpg']),
        captureDiagnosticsByPhotoPath: const {
          '/tmp/proof.jpg': {
            'nativeControlContractTags': [
              'settings',
              'back',
              'manual_shutter',
              'pinch_zoom',
              'brightness_slider',
              'brightness_reset',
            ],
            'backControlActual': 'ready',
            'settingsControlActual': 'missing',
            'manualShutterControlActual': 'ready',
            'pinchZoomControlActual': 'missing',
            'exposureSliderControlActual': 'ready',
          },
        },
      );

      expect(
        result
            .nativeCameraUiHealthCounts['native_control_contract_tags_present'],
        1,
      );
      expect(
        result.nativeCameraUiHealthCounts['native_control_contract_6_tags'],
        1,
      );
      expect(
        result.nativeCameraUiHealthCounts['settings_actual_control_missing'],
        1,
      );
      expect(
        result.nativeCameraUiHealthCounts['pinch_zoom_actual_control_missing'],
        1,
      );
      expect(
        result
            .nativeCameraUiHealthCounts['exposure_slider_actual_control_ready'],
        1,
      );
      expect(
        result
            .nativeCameraUiHealthCounts['exposure_reset_actual_control_missing'],
        1,
      );
      expect(
        result.nativeCameraUiHealthCounts['native_control_readiness_missing'],
        1,
      );
      expect(
        result.receiptReaderHandoffCounts.containsKey(
          'native_camera_ui_tap_focus_actual_control_missing',
        ),
        isFalse,
      );
    },
  );

  test('photo review result flags slow native capture review latency', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/proof.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: const ReceiptStitchResult.notNeeded(['/tmp/ocr.jpg']),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/proof.jpg': {
          'visibleControlSet':
              'back|settings|manual_shutter|status|light|brightness',
          'previewDominanceTarget': 'receipt_preview_75_80_percent',
          'settingsContractVersion': 'receipt_native_camera_settings_v1',
          'settingsButtonPlacement': 'top_bar_right',
          'nativeControlReadinessSummary': 'ready',
          'latestCaptureToSavedMs': 1920,
          'latestCaptureToReviewReadyMs': 4410,
          'latestNativeCaptureLatencyBucket': 'review_very_slow_over_3800ms',
          'nativeCaptureResponsivenessPolicy':
              'manual_shutter_to_review_should_feel_immediate',
        },
      },
    );

    expect(result.nativeCameraUiHealthOutcome, 'native_capture_latency_slow');
    expect(result.nativeCameraUiHealthCounts['native_capture_latency_slow'], 1);
    expect(
      result
          .receiptReaderHandoffCounts['native_camera_ui_native_capture_latency_slow'],
      1,
    );
    expect(
      result.privacySafeOcrHandoffEvidenceLabel,
      contains('ui=native_capture_latency_slow'),
    );
  });

  test('photo review result rejects native readiness without focus guidance', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/proof.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: const ReceiptStitchResult.notNeeded(['/tmp/ocr.jpg']),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/proof.jpg': {
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
            'receipt_guidance',
            'safe_close',
            'pinch_zoom',
            'brightness_slider',
            'brightness_reset',
            'edge_overlay',
          ],
          'backControlExpected': true,
          'backControlActual': 'ready',
          'settingsControlExpected': true,
          'settingsControlActual': 'ready',
          'manualShutterAlwaysAvailable': true,
          'manualShutterControlActual': 'ready',
          'tapFocusControlExpected': false,
          'nativeTapFocusGesturePolicy':
              'removed_continuous_focus_readability_primary',
          'pinchZoomControlExpected': true,
          'pinchZoomControlActual': 'ready',
          'exposureSliderControlExpected': true,
          'exposureSliderControlActual': 'ready',
          'exposureResetControlExpected': true,
          'exposureResetControlActual': 'ready',
          'continuousFocusExpected': false,
          'focusStrategyPolicy': 'non_continuous_focus_requires_device_review',
          'readabilityGuidancePolicy':
              'saved_photo_readability_review_required',
          'receiptCameraQualityBaseline': false,
        },
      },
    );

    expect(result.nativeCameraUiHealthOutcome, 'continuous_focus_missing');
    expect(result.nativeCameraUiHealthCounts['tap_focus_retired'], 1);
    expect(result.nativeCameraUiHealthCounts['tap_focus_gesture_removed'], 1);
    expect(result.nativeCameraUiHealthCounts['continuous_focus_missing'], 1);
    expect(
      result.nativeCameraUiHealthCounts['continuous_focus_primary_missing'],
      1,
    );
    expect(
      result.nativeCameraUiHealthCounts['readability_guidance_live_missing'],
      1,
    );
    expect(
      result
          .nativeCameraUiHealthCounts['receipt_camera_quality_baseline_missing'],
      1,
    );

    final attachments = ReceiptCaptureFlow.attachmentsFromReviewResult(
      result,
      ReceiptCaptureFlowModule.expenses,
    );
    expect(
      attachments.single.riskFlags,
      contains('native_camera_ui_continuous_focus_missing'),
    );
  });

  test('photo review result treats tap focus comeback as native risk', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/proof.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: const ReceiptStitchResult.notNeeded(['/tmp/ocr.jpg']),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/proof.jpg': {
          'visibleControlSet':
              'back|settings|manual_shutter|status|light|brightness',
          'previewDominanceTarget': 'receipt_preview_75_80_percent',
          'settingsContractVersion': 'receipt_native_camera_settings_v1',
          'settingsButtonPlacement': 'top_bar_right',
          'nativeControlReadinessSummary': 'ready',
          'backControlExpected': true,
          'backControlActual': 'ready',
          'settingsControlExpected': true,
          'settingsControlActual': 'ready',
          'manualShutterAlwaysAvailable': true,
          'manualShutterControlActual': 'ready',
          'tapFocusControlExpected': true,
          'tapFocusControlActual': 'ready',
          'continuousFocusExpected': true,
          'focusStrategyPolicy': 'continuous_focus_primary_no_tap_assist',
          'readabilityGuidancePolicy':
              'live_readability_guides_blur_glare_light_edges_and_text_size',
          'receiptCameraQualityBaseline': true,
        },
      },
    );

    expect(
      result.nativeCameraUiHealthOutcome,
      'tap_focus_retirement_regressed',
    );
    expect(
      result.nativeCameraUiHealthCounts['tap_focus_retirement_regressed'],
      1,
    );

    final attachments = ReceiptCaptureFlow.attachmentsFromReviewResult(
      result,
      ReceiptCaptureFlowModule.expenses,
    );
    expect(
      attachments.single.riskFlags,
      contains('native_camera_ui_tap_focus_retirement_regressed'),
    );
  });

  test('tap focus comeback outranks generic missing control readiness', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/proof.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: const ReceiptStitchResult.notNeeded(['/tmp/ocr.jpg']),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/proof.jpg': {
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
            'tap_focus',
            'pinch_zoom',
          ],
          'backControlActual': 'ready',
          'settingsControlActual': 'ready',
          'manualShutterControlActual': 'ready',
          'tapFocusControlExpected': true,
          'tapFocusControlActual': 'missing',
          'continuousFocusExpected': true,
          'focusStrategyPolicy': 'continuous_focus_primary_no_tap_assist',
          'readabilityGuidancePolicy':
              'live_readability_guides_blur_glare_light_edges_and_text_size',
          'receiptCameraQualityBaseline': true,
        },
      },
    );

    expect(
      result.nativeCameraUiHealthOutcome,
      'tap_focus_retirement_regressed',
    );
    expect(
      result.nativeCameraUiHealthCounts['tap_focus_retirement_regressed'],
      1,
    );
    expect(
      result.nativeCameraUiHealthCounts['tap_focus_actual_control_missing'],
      1,
    );
    expect(
      result.nativeCameraUiHealthCounts['native_control_readiness_missing'],
      1,
    );
  });

  test('continuous focus loss outranks generic missing control readiness', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/proof.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: const ReceiptStitchResult.notNeeded(['/tmp/ocr.jpg']),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/proof.jpg': {
          'visibleControlSet':
              'back|settings|manual_shutter|status|light|brightness',
          'previewDominanceTarget': 'receipt_preview_75_80_percent',
          'settingsContractVersion': 'receipt_native_camera_settings_v1',
          'settingsButtonPlacement': 'top_bar_right',
          'nativeControlContractTags': [
            'settings',
            'back',
            'manual_shutter',
            'pinch_zoom',
            'brightness_slider',
          ],
          'backControlActual': 'ready',
          'settingsControlActual': 'ready',
          'manualShutterControlActual': 'ready',
          'pinchZoomControlActual': 'missing',
          'exposureSliderControlActual': 'ready',
          'tapFocusControlExpected': false,
          'continuousFocusExpected': false,
          'focusStrategyPolicy': 'non_continuous_focus_requires_device_review',
          'readabilityGuidancePolicy':
              'saved_photo_readability_review_required',
          'receiptCameraQualityBaseline': false,
        },
      },
    );

    expect(result.nativeCameraUiHealthOutcome, 'continuous_focus_missing');
    expect(result.nativeCameraUiHealthCounts['continuous_focus_missing'], 1);
    expect(
      result.nativeCameraUiHealthCounts['native_control_readiness_missing'],
      1,
    );
    expect(
      result.nativeCameraUiHealthCounts['pinch_zoom_actual_control_missing'],
      1,
    );
  });

  test('live readability guidance requires visible native UI evidence', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/proof.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: const ReceiptStitchResult.notNeeded(['/tmp/ocr.jpg']),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/proof.jpg': {
          'visibleControlSet':
              'back|settings|manual_shutter|status|light|brightness|edge_guide',
          'previewDominanceTarget': 'receipt_preview_75_80_percent',
          'settingsContractVersion': 'receipt_native_camera_settings_v1',
          'settingsButtonPlacement': 'top_bar_right',
          'nativeControlReadinessSummary': 'ready',
          'backControlActual': 'ready',
          'settingsControlActual': 'ready',
          'manualShutterControlActual': 'ready',
          'tapFocusControlExpected': false,
          'continuousFocusExpected': true,
          'focusStrategyPolicy': 'continuous_focus_primary_no_tap_assist',
          'readabilityGuidancePolicy':
              'live_readability_guides_blur_glare_light_edges_and_text_size',
          'receiptCameraQualityBaseline': true,
        },
      },
    );

    expect(
      result.nativeCameraUiHealthOutcome,
      'readability_guidance_visible_missing',
    );
    expect(
      result.nativeCameraUiHealthCounts['readability_guidance_visible_missing'],
      1,
    );

    final attachments = ReceiptCaptureFlow.attachmentsFromReviewResult(
      result,
      ReceiptCaptureFlowModule.expenses,
    );
    expect(
      attachments.single.riskFlags,
      contains('native_camera_ui_readability_guidance_visible_missing'),
    );
  });

  test('photo review result flags incomplete native camera controls', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/proof.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: const ReceiptStitchResult.notNeeded(['/tmp/ocr.jpg']),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/proof.jpg': {
          'visibleControlSet': 'back|manual_shutter',
          'previewDominanceTarget': 'unknown',
          'nativeControlReadinessSummary': 'review_needed',
          'backControlExpected': true,
          'backControlActual': 'ready',
          'settingsControlExpected': true,
          'settingsControlActual': 'missing',
          'manualShutterAlwaysAvailable': true,
          'manualShutterControlActual': 'visible_disabled',
          'pinchZoomControlExpected': true,
          'pinchZoomControlActual': 'missing',
          'torchControlExpected': true,
          'torchControlActual': 'missing',
          'focusLockControlExpected': true,
          'focusLockControlActual': 'missing',
          'exposureLockControlExpected': true,
          'exposureLockControlActual': 'missing',
          'whiteBalanceLockControlExpected': true,
          'whiteBalanceLockControlActual': 'missing',
        },
      },
    );

    expect(result.nativeCameraUiHealthOutcome, 'settings_contract_missing');
    expect(result.nativeCameraUiHealthCounts['native_controls_incomplete'], 1);
    expect(
      result.nativeCameraUiHealthCounts['native_control_readiness_missing'],
      1,
    );
    expect(
      result.nativeCameraUiHealthCounts['settings_actual_control_missing'],
      1,
    );
    expect(
      result
          .nativeCameraUiHealthCounts['manual_shutter_actual_control_missing'],
      1,
    );
    expect(
      result.nativeCameraUiHealthCounts['pinch_zoom_actual_control_missing'],
      1,
    );
    expect(
      result.nativeCameraUiHealthCounts['torch_actual_control_missing'],
      1,
    );
    expect(
      result.nativeCameraUiHealthCounts['focus_lock_actual_control_missing'],
      1,
    );
    expect(
      result.nativeCameraUiHealthCounts['exposure_lock_actual_control_missing'],
      1,
    );
    expect(
      result
          .nativeCameraUiHealthCounts['white_balance_lock_actual_control_missing'],
      1,
    );
    expect(result.nativeCameraUiHealthCounts['preview_dominance_missing'], 1);
    expect(
      result.privacySafeOcrHandoffEvidenceLabel,
      contains('ui=settings_contract_missing'),
    );

    final attachments = ReceiptCaptureFlow.attachmentsFromReviewResult(
      result,
      ReceiptCaptureFlowModule.expenses,
    );
    expect(
      attachments.single.documentSignals,
      contains('native_camera_ui_native_controls_incomplete'),
    );
    expect(
      attachments.single.documentSignals,
      contains('native_camera_ui_native_control_readiness_missing'),
    );
    expect(
      attachments.single.documentSignals,
      contains('native_camera_ui_preview_dominance_missing'),
    );
    expect(
      attachments.single.riskFlags,
      contains('native_camera_ui_native_controls_incomplete'),
    );
    expect(
      attachments.single.riskFlags,
      contains('native_camera_ui_preview_dominance_missing'),
    );
  });
}
