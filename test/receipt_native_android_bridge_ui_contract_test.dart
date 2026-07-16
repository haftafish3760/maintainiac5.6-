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
    expect(cameraActivity, contains('shouldShowSettingsStatusStrip()'));
    expect(
      cameraActivity,
      contains('visibility = if (shouldShowSettingsStatusStrip()) {'),
    );
    expect(
      cameraActivity,
      contains(
        'settingsStatusStrip.visibility = if (shouldShowSettingsStatusStrip()) {',
      ),
    );
    expect(cameraActivity, contains('private fun safeReceiptReviewDepth'));
    expect(cameraActivity, contains('Regex("[\\\\s_-]+")'));
    expect(cameraActivity, contains('?.lowercase()'));
    expect(cameraActivity, contains('"detailedlines" -> "detailedLines"'));
    expect(cameraActivity, contains('"pricesonly" -> "pricesOnly"'));
    expect(cameraActivity, contains('Receipt Camera Settings'));
    expect(cameraActivity, contains('Camera only'));
    expect(cameraActivity, isNot(contains('ACCOUNT AND STORAGE')));
    expect(cameraActivity, isNot(contains('RECEIPT ASSIST')));
    expect(cameraActivity, contains('CAPTURE FLOW'));
    expect(cameraActivity, isNot(contains('IMAGE HANDOFF')));
    expect(cameraActivity, contains('CAMERA CONTROLS'));
    expect(cameraActivity, isNot(contains('PRIVACY AND DIAGNOSTICS')));
    expect(
      cameraActivity,
      contains(r'return "$assist • $depth • $length • $light"'),
    );
    expect(
      cameraActivity,
      contains(
        'Fill the screen with readable receipt text. Auto capture can help when the receipt is steady.',
      ),
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
    expect(cameraActivity, contains('"Adjust brightness"'));
    expect(cameraActivity, contains('toggleExposureControls()'));
    expect(
      cameraActivity,
      contains('The phone still controls autofocus and exposure timing.'),
    );
    expect(
      cameraActivity,
      contains('"shutterButtonPlacement" to "bottom_center"'),
    );
    expect(
      cameraActivity,
      contains('"reviewNextButtonPlacement" to "bottom_only_after_capture"'),
    );
    expect(
      cameraActivity,
      isNot(contains('internal lateinit var doneButton: Button')),
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
    expect(
      cameraActivity,
      contains('WindowCompat.setDecorFitsSystemWindows(window, false)'),
    );
    expect(cameraActivity, contains('applyEdgeToEdgeReceiptInsets()'));
    expect(
      cameraActivity,
      contains('ViewCompat.setOnApplyWindowInsetsListener(cameraRootView)'),
    );
    expect(cameraActivity, contains('WindowInsetsCompat.Type.systemBars() or'));
    expect(cameraActivity, contains('WindowInsetsCompat.Type.displayCutout()'));
    expect(cameraActivity, contains('topBar.updatePadding('));
    expect(cameraActivity, contains('bottomBar.updatePadding('));
    expect(cameraActivity, contains('receiptFrameGuide.updateLayoutParams'));
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
    expect(cameraActivity, contains('Color.argb(168, 5, 6, 7)'));
    expect(cameraActivity, contains('Color.argb(118, 5, 6, 7)'));
    expect(cameraActivity, contains('Color.argb(104, 5, 6, 7)'));
    expect(cameraActivity, contains('Color.argb(92, 255, 209, 102)'));
    expect(cameraActivity, contains('alpha = 0.36f'));
    expect(cameraActivity, contains('PreviewView.ScaleType.FILL_CENTER'));
    expect(cameraActivity, isNot(contains('PreviewView.ScaleType.FIT_CENTER')));
    expect(cameraActivity, contains('nativePreviewScaleMode'));
    expect(
      cameraActivity,
      contains(
        'internal val nativePreviewScaleMode = "fill_center_full_receipt"',
      ),
    );
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
        '    )',
      ),
    );
    expect(cameraActivity, isNot(contains('controls.add("status")')));
    expect(
      cameraActivity,
      contains(
        'internal fun ReceiptCameraActivity.shouldShowSettingsStatusStrip(): Boolean {\n'
        '    // Keep the active preview chrome minimal. The full settings summary stays\n'
        '    // inside the dedicated receipt camera settings surface instead.\n'
        '    return false\n'
        '}',
      ),
    );
    expect(
      cameraActivity,
      contains('previousSectionGuidePanel.visibility == View.VISIBLE'),
    );
    expect(cameraActivity, contains('addPhotoButton.isEnabled'));
    expect(
      cameraActivity,
      contains('if (torchButton.isEnabled) controls.add("light")'),
    );
    expect(
      cameraActivity,
      contains('if (exposureControlsVisible()) controls.add("brightness")'),
    );
    expect(
      cameraActivity,
      contains(
        'internal fun ReceiptCameraActivity.exposureControlsVisible(): Boolean',
      ),
    );
    expect(
      cameraActivity,
      contains(
        'internal fun ReceiptCameraActivity.reviewNextControlReady(): Boolean',
      ),
    );
    expect(
      cameraActivity,
      contains('bottomReviewButton.visibility == View.VISIBLE'),
    );
    expect(
      cameraActivity,
      isNot(contains('doneButton.visibility == View.VISIBLE')),
    );
    expect(
      cameraActivity,
      contains(
        'internal fun ReceiptCameraActivity.reviewNextControlActualStatus(): String',
      ),
    );
    expect(cameraActivity, contains('return controls.joinToString("|")'));
    expect(
      cameraActivity,
      contains('"previewDominanceTarget" to "receipt_preview_75_80_percent"'),
    );
    expect(cameraActivity, contains('"manual_shutter"'));
    expect(cameraActivity, contains('controls.add("long_receipt_done")'));
    expect(cameraActivity, contains('controls.add("section_ghost_guide")'));
    expect(cameraActivity, contains('"edge_guide"'));
    expect(
      cameraActivity,
      contains(
        'Start at the top, add sections in order, and repeat a few readable lines so each section is ready for later receipt reconstruction.',
      ),
    );
    expect(
      cameraActivity,
      contains(
        '"longReceiptSectionGuidance" to "top_to_bottom_with_readable_overlap"',
      ),
    );
    expect(cameraActivity, contains('Color.argb(210, 5, 6, 7)'));
    expect(cameraActivity, contains('val assist = if (assistedReceiptFill)'));
    expect(cameraActivity, contains('"Assist on"'));
    expect(cameraActivity, contains('"Manual fill"'));
    expect(cameraActivity, contains('"Price-only lines"'));
    expect(cameraActivity, contains('"Long receipt"'));
    expect(cameraActivity, isNot(contains('"Price review"')));
    expect(cameraActivity, isNot(contains('"Long receipt on"')));
    expect(
      cameraActivity,
      isNot(
        contains('Maintainiac reads from the clearest temporary photo first'),
      ),
    );
    expect(cameraActivity, isNot(contains('OCR reads original first')));
    expect(cameraActivity, contains('Smaller saved proof copies'));
    expect(cameraActivity, isNot(contains('Capture order')));
    expect(cameraActivity, contains('updateSettingsStatusStrip()'));
    expect(cameraActivity, contains('Reset Receipt Camera Defaults'));
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

  test('Android native camera forces retired focus controls off', () async {
    final cameraActivity =
        (await readAndroidReceiptCameraBridgeSources()).cameraActivity;
    final sessionReader = cameraActivity.substring(
      cameraActivity.indexOf(
        'internal fun ReceiptCameraActivity.readSessionArguments()',
      ),
      cameraActivity.indexOf(
        'internal fun ReceiptCameraActivity.finiteDoubleExtra(',
      ),
    );
    final tapFocusStatus = cameraActivity.substring(
      cameraActivity.indexOf(
        'internal fun ReceiptCameraActivity.tapFocusControlActualStatus()',
      ),
      cameraActivity.indexOf(
        'internal fun ReceiptCameraActivity.pinchZoomControlActualStatus()',
      ),
    );
    final focusLockStatus = cameraActivity.substring(
      cameraActivity.indexOf(
        'internal fun ReceiptCameraActivity.focusLockEnabled()',
      ),
      cameraActivity.indexOf(
        'internal fun ReceiptCameraActivity.exposureLockControlActualStatus()',
      ),
    );
    final whiteBalanceStatus = cameraActivity.substring(
      cameraActivity.indexOf(
        'internal fun ReceiptCameraActivity.whiteBalanceLockControlActualStatus()',
      ),
    );

    expect(sessionReader, contains('tapFocusEnabled = false'));
    expect(sessionReader, contains('whiteBalanceLockEnabled = false'));
    expect(
      sessionReader,
      isNot(contains('intent.getBooleanExtra("tapFocusEnabled"')),
    );
    expect(
      sessionReader,
      isNot(contains('intent.getBooleanExtra("whiteBalanceLockEnabled"')),
    );
    expect(tapFocusStatus, contains('controlStatus(visible = false'));
    expect(tapFocusStatus, contains('enabled = false'));
    expect(focusLockStatus, contains('return false'));
    expect(whiteBalanceStatus, contains('controlStatus(visible = false'));
    expect(whiteBalanceStatus, contains('enabled = false'));
  });
}
