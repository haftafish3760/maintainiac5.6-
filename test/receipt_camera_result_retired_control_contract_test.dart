import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_flow.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  test('stale retired control contract tags become native UI risks', () {
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
            'brightness_slider',
            'brightness_reset',
            'focus_lock',
            'brightness_lock',
            'white_balance_lock',
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
          'focusLockControlExpected': false,
          'exposureLockControlExpected': false,
          'whiteBalanceLockControlExpected': false,
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
      'tap_focus_contract_retirement_regressed',
    );
    expect(
      result
          .nativeCameraUiHealthCounts['tap_focus_contract_retirement_regressed'],
      1,
    );
    expect(
      result
          .nativeCameraUiHealthCounts['focus_lock_contract_retirement_regressed'],
      1,
    );
    expect(
      result
          .nativeCameraUiHealthCounts['exposure_lock_contract_retirement_regressed'],
      1,
    );
    expect(
      result
          .nativeCameraUiHealthCounts['white_balance_lock_contract_retirement_regressed'],
      1,
    );
    expect(
      result.nativeCameraUiHealthCounts.keys,
      isNot(contains('tap_focus_actual_control_missing')),
    );
    expect(
      result.nativeCameraUiHealthCounts.keys,
      isNot(contains('focus_lock_actual_control_missing')),
    );

    final attachments = ReceiptCaptureFlow.attachmentsFromReviewResult(
      result,
      ReceiptCaptureFlowModule.expenses,
    );
    expect(
      attachments.single.riskFlags,
      contains('native_camera_ui_tap_focus_contract_retirement_regressed'),
    );
  });
}
