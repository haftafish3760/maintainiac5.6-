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
              'live_receipt_workflow_guidance_only_unproven_quality_claims_off',
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

  test('active retired controls become native UI risks without contract tags', () {
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
          'tapFocusControlActual': 'ready',
          'pinchZoomControlExpected': true,
          'pinchZoomControlActual': 'ready',
          'exposureSliderControlExpected': true,
          'exposureSliderControlActual': 'ready',
          'exposureResetControlExpected': true,
          'exposureResetControlActual': 'ready',
          'focusLockControlExpected': false,
          'focusLockControlActual': 'locked',
          'exposureLockControlExpected': false,
          'exposureLockControlActual': 'enabled',
          'whiteBalanceLockControlExpected': false,
          'whiteBalanceLockControlActual': 'visible_enabled',
          'continuousFocusExpected': true,
          'focusStrategyPolicy': 'continuous_focus_primary_no_tap_assist',
          'readabilityGuidancePolicy':
              'live_receipt_workflow_guidance_only_unproven_quality_claims_off',
          'receiptCameraQualityBaseline': true,
        },
      },
    );

    expect(
      result.nativeCameraUiHealthOutcome,
      'tap_focus_actual_retirement_regressed',
    );
    expect(
      result
          .nativeCameraUiHealthCounts['tap_focus_actual_retirement_regressed'],
      1,
    );
    expect(
      result
          .nativeCameraUiHealthCounts['focus_lock_actual_retirement_regressed'],
      1,
    );
    expect(
      result
          .nativeCameraUiHealthCounts['exposure_lock_actual_retirement_regressed'],
      1,
    );
    expect(
      result
          .nativeCameraUiHealthCounts['white_balance_lock_actual_retirement_regressed'],
      1,
    );
    expect(
      result.nativeCameraUiHealthCounts.keys,
      isNot(contains('tap_focus_actual_control_ready')),
    );

    final attachments = ReceiptCaptureFlow.attachmentsFromReviewResult(
      result,
      ReceiptCaptureFlowModule.expenses,
    );
    expect(
      attachments.single.riskFlags,
      contains('native_camera_ui_tap_focus_actual_retirement_regressed'),
    );
  });

  test('lock-only retirement regression drives native UI outcome', () {
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
          'tapFocusControlActual': 'disabled',
          'pinchZoomControlExpected': true,
          'pinchZoomControlActual': 'ready',
          'exposureSliderControlExpected': true,
          'exposureSliderControlActual': 'ready',
          'exposureResetControlExpected': true,
          'exposureResetControlActual': 'ready',
          'focusLockControlExpected': false,
          'focusLockControlActual': 'locked',
          'exposureLockControlExpected': false,
          'exposureLockControlActual': 'disabled',
          'whiteBalanceLockControlExpected': false,
          'whiteBalanceLockControlActual': 'disabled',
          'continuousFocusExpected': true,
          'focusStrategyPolicy': 'continuous_focus_primary_no_tap_assist',
          'readabilityGuidancePolicy':
              'live_receipt_workflow_guidance_only_unproven_quality_claims_off',
          'receiptCameraQualityBaseline': true,
        },
      },
    );

    expect(
      result.nativeCameraUiHealthOutcome,
      'focus_lock_actual_retirement_regressed',
    );
    expect(
      result
          .nativeCameraUiHealthCounts['focus_lock_actual_retirement_regressed'],
      1,
    );
    expect(
      result.nativeCameraUiHealthCounts['native_control_readiness_ready'],
      1,
    );

    final attachments = ReceiptCaptureFlow.attachmentsFromReviewResult(
      result,
      ReceiptCaptureFlowModule.expenses,
    );
    expect(
      attachments.single.riskFlags,
      contains('native_camera_ui_focus_lock_actual_retirement_regressed'),
    );
  });
}
