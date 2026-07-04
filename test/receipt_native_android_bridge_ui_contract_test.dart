import 'package:flutter_test/flutter_test.dart';

import 'helpers/receipt_native_android_bridge_source_readers.dart';

void main() {
  test('Android native receipt camera exposes custom UI controls', () async {
    final sources = await readAndroidReceiptCameraBridgeSources();
    final cameraActivity = sources.cameraActivity;
    final readinessSummary = cameraActivity.substring(
      cameraActivity.indexOf(
        'internal fun ReceiptCameraActivity.nativeControlReadinessSummary()',
      ),
      cameraActivity.indexOf(
        'internal fun ReceiptCameraActivity.backControlActualStatus()',
      ),
    );

    expect(cameraActivity, contains('ProcessCameraProvider'));
    expect(cameraActivity, contains('BitmapFactory'));
    expect(cameraActivity, contains('PreviewView'));
    expect(cameraActivity, contains('ImageCapture'));
    expect(cameraActivity, contains('ImageAnalysis'));
    expect(cameraActivity, contains('ImageProxy'));
    expect(cameraActivity, contains('finishPendingCloseAfterCaptureFailure'));
    expect(
      cameraActivity,
      contains('back_capture_failed_returned_existing_sections'),
    );
    expect(
      cameraActivity,
      contains('Opening review with the receipt photos already captured.'),
    );
    expect(
      cameraActivity.indexOf(
        'if (pendingCloseAfterCapture) {\n'
        '                        finishPendingCloseAfterCaptureFailure()',
      ),
      lessThan(
        cameraActivity.indexOf(
          'cancelWithoutCapturedPhoto("back_capture_failed_cancel")',
        ),
      ),
    );
    expect(cameraActivity, contains('settingsStatusStrip'));
    expect(cameraActivity, contains('buildSettingsStatusStrip'));
    expect(cameraActivity, contains('settingsStatusText'));
    expect(cameraActivity, contains('private fun safeReceiptReviewDepth'));
    expect(cameraActivity, contains('Regex("[\\\\s_-]+")'));
    expect(cameraActivity, contains('?.lowercase()'));
    expect(cameraActivity, contains('"detailedlines" -> "detailedLines"'));
    expect(cameraActivity, contains('"pricesonly" -> "pricesOnly"'));
    expect(cameraActivity, contains('Maintainiac receipt camera'));
    expect(cameraActivity, contains("not the phone's regular camera app"));
    expect(cameraActivity, contains('Capture quality'));
    expect(
      cameraActivity,
      contains(
        'Take the clearest receipt photo for OCR first. Save-space proof size is applied only after receipt assistance uses the clearest source.',
      ),
    );
    expect(
      cameraActivity,
      contains(r'Maintainiac receipt camera • $assist • $depth'),
    );
    expect(
      cameraActivity,
      contains('"nativeCameraIdentity" to "maintainiac_in_app_receipt_camera"'),
    );
    expect(
      cameraActivity,
      contains(
        '"nativeCaptureUiContract" to "maintainiac_custom_receipt_capture_ui_v1"',
      ),
    );
    expect(cameraActivity, contains('"stockCameraUiUsed" to false'));
    expect(
      cameraActivity,
      contains('"settingsButtonPlacement" to "top_bar_right"'),
    );
    expect(cameraActivity, contains('"backButtonPlacement" to "top_bar_left"'));
    expect(
      cameraActivity,
      contains('"torchButtonPlacement" to "top_bar_right"'),
    );
    expect(
      cameraActivity,
      contains('"shutterButtonPlacement" to "bottom_center"'),
    );
    expect(
      cameraActivity,
      contains('"reviewNextButtonPlacement" to "top_and_bottom_after_capture"'),
    );
    expect(
      cameraActivity,
      contains(
        '"nativeTouchControlPolicy" to "continuous_focus_readability_and_pinch_zoom_v1"',
      ),
    );
    expect(
      cameraActivity,
      contains(
        '"readabilityGuidanceCoordinateSpace" to "preview_metering_point_factory"',
      ),
    );
    expect(cameraActivity, isNot(contains('"tapFocusCoordinateSpace"')));
    expect(
      cameraActivity,
      contains(
        'internal var zoomGesturePolicy = "cameraX_zoom_ratio_clamped_to_capability"',
      ),
    );
    expect(
      cameraActivity,
      contains(
        'internal var focusStrategyPolicy = "continuous_focus_primary_no_tap_assist"',
      ),
    );
    expect(
      cameraActivity,
      contains('internal var continuousFocusEnabled = true'),
    );
    expect(
      cameraActivity,
      contains(
        'intent.getBooleanExtra("continuousFocusEnabled", continuousFocusEnabled)',
      ),
    );
    expect(
      cameraActivity,
      contains('"focusStrategyPolicy" to focusStrategyPolicy'),
    );
    expect(
      cameraActivity,
      contains('"continuousFocusEnabled" to continuousFocusEnabled'),
    );
    expect(
      cameraActivity,
      contains('"readabilityGuidancePolicy" to readabilityGuidancePolicy'),
    );
    expect(cameraActivity, contains('"tapFocusControlExpected" to false'));
    expect(cameraActivity, contains('"focusLockControlExpected" to false'));
    expect(cameraActivity, contains('"exposureLockControlExpected" to false'));
    expect(
      cameraActivity,
      contains('"whiteBalanceLockControlExpected" to false'),
    );
    expect(
      cameraActivity,
      isNot(contains('"tapFocusControlExpected" to tapFocusEnabled')),
    );
    expect(
      cameraActivity,
      isNot(contains('"focusLockControlExpected" to focusLockEnabled()')),
    );
    expect(
      cameraActivity,
      isNot(contains('"exposureLockControlExpected" to exposureLockEnabled()')),
    );
    expect(
      cameraActivity,
      isNot(
        contains(
          '"whiteBalanceLockControlExpected" to whiteBalanceLockEnabled',
        ),
      ),
    );
    expect(readinessSummary, isNot(contains('tapFocusControlActualStatus()')));
    expect(readinessSummary, isNot(contains('focusLockControlActualStatus()')));
    expect(
      readinessSummary,
      isNot(contains('exposureLockControlActualStatus()')),
    );
    expect(
      readinessSummary,
      isNot(contains('whiteBalanceLockControlActualStatus()')),
    );
    expect(readinessSummary, isNot(contains('pinchZoomControlActualStatus()')));
    expect(
      readinessSummary,
      isNot(contains('exposureSliderControlActualStatus()')),
    );
    expect(
      readinessSummary,
      isNot(contains('exposureResetControlActualStatus()')),
    );
    expect(readinessSummary, isNot(contains('torchControlActualStatus()')));
    expect(
      cameraActivity,
      contains(
        '"receiptCameraQualityBaseline" to receiptCameraQualityBaseline',
      ),
    );
    expect(cameraActivity, contains('"pinchZoomPolicy" to zoomGesturePolicy'));
    expect(cameraActivity, contains('Color.argb(126, 5, 6, 7)'));
    expect(cameraActivity, contains('Color.argb(134, 5, 6, 7)'));
    expect(cameraActivity, contains('Color.argb(138, 255, 209, 102)'));
    expect(cameraActivity, contains('alpha = 0.54f'));
    expect(cameraActivity, contains('PreviewView.ScaleType.FIT_CENTER'));
    expect(cameraActivity, contains('nativePreviewScaleMode'));
    expect(cameraActivity, contains('nativeControlDensity'));
    expect(
      cameraActivity,
      contains('internal fun ReceiptCameraActivity.visibleControlSet()'),
    );
    expect(
      cameraActivity,
      contains('"visibleControlSet" to visibleControlSet()'),
    );
    expect(
      cameraActivity,
      contains(
        'val controls = mutableListOf(\n'
        '        "back",\n'
        '        "settings",\n'
        '        "manual_shutter",\n'
        '        "status",\n'
        '    )',
      ),
    );
    expect(
      cameraActivity,
      contains('if (torchButton.isEnabled) controls.add("light")'),
    );
    expect(
      cameraActivity,
      contains('if (exposureSliderEnabled) controls.add("brightness")'),
    );
    expect(cameraActivity, contains('return controls.joinToString("|")'));
    expect(
      cameraActivity,
      contains('"previewDominanceTarget" to "receipt_preview_75_80_percent"'),
    );
    expect(cameraActivity, contains('"manual_shutter"'));
    expect(cameraActivity, contains('"long_receipt_done"'));
    expect(cameraActivity, contains('"section_ghost_guide"'));
    expect(cameraActivity, contains('"edge_guide"'));
    expect(
      cameraActivity,
      contains(
        'Start at the top, add sections in order, and repeat a few readable lines so Maintainiac can match the receipt pieces.',
      ),
    );
    expect(
      cameraActivity,
      contains(
        '"longReceiptSectionGuidance" to "top_to_bottom_with_readable_overlap"',
      ),
    );
    expect(cameraActivity, isNot(contains('Color.argb(210, 5, 6, 7)')));
    expect(cameraActivity, contains('val assist = if (assistedReceiptFill)'));
    expect(cameraActivity, contains('"Assist on"'));
    expect(cameraActivity, contains('"Manual fill"'));
    expect(cameraActivity, contains('OCR reads original first'));
    expect(cameraActivity, contains('open receipt details'));
    expect(cameraActivity, contains('proof and cloud backup'));
    expect(cameraActivity, contains('always works immediately'));
    expect(cameraActivity, contains('updateSettingsStatusStrip()'));
    expect(cameraActivity, contains('Reset receipt camera defaults'));
    expect(
      cameraActivity,
      contains(
        'internal fun ReceiptCameraActivity.resetReceiptCameraDefaults()',
      ),
    );
    expect(cameraActivity, contains('settingsResetCount += 1'));
    expect(
      cameraActivity,
      contains('Receipt camera defaults restored. Manual shutter is ready.'),
    );
    expect(
      cameraActivity,
      contains('"settingsResetCount" to settingsResetCount'),
    );
    expect(cameraActivity, contains('receiptFrameGuide'));
    expect(cameraActivity, contains('LiveReceiptFraming'));
    expect(cameraActivity, contains('CameraSelector.DEFAULT_BACK_CAMERA'));
    expect(cameraActivity, contains('receiptStillCaptureMode'));
    expect(cameraActivity, contains('CAPTURE_MODE_MINIMIZE_LATENCY'));
    expect(cameraActivity, contains('"receipt_latency_light_device"'));
    expect(cameraActivity, contains('"receipt_fast_document_shutter"'));
    expect(cameraActivity, contains('receiptStillJpegQuality'));
  });
}
