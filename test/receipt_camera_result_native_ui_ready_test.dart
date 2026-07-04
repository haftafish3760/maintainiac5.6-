import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_flow.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  test('photo review result summarizes native camera UI health', () {
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
          'nativeControlContractTags': [
            'settings',
            'back',
            'manual_shutter',
            'review_next',
            'receipt_guidance',
            'safe_close',
            'pinch_zoom',
            'brightness_slider',
            'brightness_reset',
            'auto_brightness_assist',
            'continuous_focus',
            'receipt_light',
            'edge_overlay',
          ],
          'backControlExpected': true,
          'backControlActual': 'ready',
          'settingsControlExpected': true,
          'settingsControlActual': 'ready',
          'manualShutterAlwaysAvailable': true,
          'manualShutterControlActual': 'ready',
          'tapFocusControlExpected': false,
          'tapFocusControlActual': 'disabled',
          'continuousFocusExpected': true,
          'focusStrategyPolicy': 'continuous_focus_primary_no_tap_assist',
          'lastFocusStatus': 'continuous_autofocus_configured',
          'readabilityGuidancePolicy':
              'live_readability_guides_blur_glare_light_edges_and_text_size',
          'receiptCameraQualityBaseline': true,
          'pinchZoomControlExpected': true,
          'pinchZoomControlActual': 'ready',
          'exposureSliderControlExpected': true,
          'exposureSliderControlActual': 'ready',
          'exposureResetControlExpected': true,
          'exposureResetControlActual': 'ready',
          'torchControlExpected': true,
          'torchControlActual': 'ready',
          'focusLockControlExpected': false,
          'focusLockControlActual': 'disabled',
          'exposureLockControlExpected': false,
          'exposureLockControlActual': 'disabled',
          'whiteBalanceLockControlExpected': false,
          'whiteBalanceLockControlActual': 'disabled',
          'latestNativeCaptureLatencyBucket': 'review_good_under_1200ms',
          'receiptReviewOpeningRoute': 'native_capture_to_photo_review',
          'receiptReviewOpeningSource': 'fresh_native_capture',
          'receiptReviewOpeningPolicy':
              'open_photo_review_before_ocr_or_receipt_form',
          'receiptReviewOpeningExpectedFirstAction':
              'next_or_add_photo_visible_before_scroll',
          'nativeCaptureReviewTransitionPolicy':
              'captured_photos_must_open_review_then_receipt_details',
          'nativeCaptureReviewTransitionTarget':
              'receipt_photo_review_next_to_receipt_details',
          'nativeCaptureReviewDiscardPolicy':
              'never_discard_captured_photo_on_back',
        },
      },
    );

    expect(result.nativeCameraUiHealthOutcome, 'native_controls_ready');
    expect(result.nativeCameraUiHealthCounts['native_controls_ready'], 1);
    expect(
      result.nativeCameraUiHealthCounts['native_control_readiness_ready'],
      1,
    );
    expect(
      result.nativeCameraUiHealthCounts['native_control_contract_tags_present'],
      1,
    );
    expect(
      result.nativeCameraUiHealthCounts['native_control_contract_13_tags'],
      1,
    );
    expect(
      result
          .nativeCameraUiHealthCounts['native_control_contract_expected_pinch_zoom'],
      1,
    );
    expect(
      result
          .nativeCameraUiHealthCounts['native_control_contract_expected_brightness_slider'],
      1,
    );
    expect(
      result.nativeCameraUiHealthCounts['pinch_zoom_actual_control_ready'],
      1,
    );
    expect(
      result.nativeCameraUiHealthCounts.containsKey(
        'tap_focus_actual_control_ready',
      ),
      isFalse,
    );
    expect(result.nativeCameraUiHealthCounts['tap_focus_retired'], 1);
    expect(result.nativeCameraUiHealthCounts['continuous_focus_expected'], 1);
    expect(
      result
          .nativeCameraUiHealthCounts['native_control_contract_expected_continuous_focus'],
      1,
    );
    expect(
      result.nativeCameraUiHealthCounts['continuous_focus_primary_ready'],
      1,
    );
    expect(
      result
          .nativeCameraUiHealthCounts['native_focus_status_continuous_configured'],
      1,
    );
    expect(
      result.nativeCameraUiHealthCounts['readability_guidance_live_ready'],
      1,
    );
    expect(
      result
          .nativeCameraUiHealthCounts['receipt_camera_quality_baseline_ready'],
      1,
    );
    expect(
      result.nativeCameraUiHealthCounts['manual_shutter_actual_control_ready'],
      1,
    );
    expect(result.nativeCameraUiHealthCounts['torch_actual_control_ready'], 1);
    expect(
      result.nativeCameraUiHealthCounts['focus_lock_actual_control_ready'],
      isNull,
    );
    expect(
      result.nativeCameraUiHealthCounts['exposure_lock_actual_control_ready'],
      isNull,
    );
    expect(
      result
          .nativeCameraUiHealthCounts['white_balance_lock_actual_control_ready'],
      isNull,
    );
    expect(
      result.nativeCameraUiHealthCounts['native_capture_latency_ready'],
      1,
    );
    expect(
      result
          .nativeCameraUiHealthCounts['receipt_review_opening_route_native_capture_to_photo_review'],
      1,
    );
    expect(
      result
          .nativeCameraUiHealthCounts['receipt_review_opening_source_fresh_native_capture'],
      1,
    );
    expect(
      result.nativeCameraUiHealthCounts['receipt_review_opening_before_ocr'],
      1,
    );
    expect(
      result
          .nativeCameraUiHealthCounts['receipt_review_opening_core_actions_visible'],
      1,
    );
    expect(result.nativeCameraUiHealthCounts['preview_dominance_expected'], 1);
    expect(
      result
          .receiptReaderHandoffCounts['native_camera_ui_native_controls_ready'],
      1,
    );
    expect(
      result
          .receiptReaderHandoffCounts['native_camera_ui_preview_dominance_expected'],
      1,
    );
    expect(
      result
          .receiptReaderHandoffCounts['native_camera_ui_continuous_focus_expected'],
      1,
    );
    expect(
      result
          .receiptReaderHandoffCounts['native_camera_ui_readability_guidance_live_ready'],
      1,
    );
    expect(
      result.privacySafeOcrHandoffEvidenceLabel,
      contains('ui=native_controls_ready'),
    );
    expect(
      result
          .privacySafeReceiptReaderHandoffMetadata['nativeCameraUiHealthOutcome'],
      'native_controls_ready',
    );
    expect(
      result
          .privacySafeReceiptReaderHandoffMetadata['nativeCameraUiHealthCounts'],
      containsPair('native_controls_ready', 1),
    );

    final attachments = ReceiptCaptureFlow.attachmentsFromReviewResult(
      result,
      ReceiptCaptureFlowModule.expenses,
    );
    expect(
      attachments.single.documentSignals,
      contains('native_camera_ui_native_controls_ready'),
    );
    expect(
      attachments.single.documentSignals,
      contains('native_camera_ui_preview_dominance_expected'),
    );
    expect(
      attachments.single.documentSignals,
      contains('native_camera_ui_health_available'),
    );
    expect(
      attachments.single.documentSignals,
      contains('native_camera_ui_native_capture_latency_ready'),
    );
    expect(
      attachments.single.documentSignals,
      contains('native_camera_ui_continuous_focus_expected'),
    );
    expect(
      attachments.single.documentSignals,
      contains('native_camera_ui_readability_guidance_live_ready'),
    );
    expect(
      attachments.single.documentSignals,
      contains('native_camera_ui_receipt_camera_quality_baseline_ready'),
    );
    expect(
      attachments.single.documentSignals,
      contains(
        'native_camera_ui_receipt_review_opening_route_native_capture_to_photo_review',
      ),
    );
    expect(
      attachments.single.documentSignals,
      contains('native_camera_ui_receipt_review_opening_before_ocr'),
    );
    expect(
      attachments.single.documentSignals,
      contains('native_camera_ui_receipt_review_opening_core_actions_visible'),
    );
    expect(attachments.single.riskFlags, isNot(contains('lowe')));
  });
}
