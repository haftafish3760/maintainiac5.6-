import 'package:flutter_test/flutter_test.dart';

import 'helpers/receipt_native_ios_bridge_source_readers.dart';

void main() {
  test('iOS native receipt camera keeps custom UI and session close protections', () async {
    final sources = await readIosReceiptCameraBridgeSources();
    final cameraController = sources.cameraController;
    final readinessSummary = cameraController.substring(
      cameraController.indexOf('func nativeControlReadinessSummary()'),
      cameraController.indexOf('func backControlActualStatus()'),
    );

    expect(cameraController, contains('AVCaptureSession'));
    expect(cameraController, contains('UIImage(data: data)'));
    expect(cameraController, contains('AVCaptureVideoPreviewLayer'));
    expect(cameraController, contains('AVCapturePhotoOutput'));
    expect(cameraController, contains('AVCaptureVideoDataOutput'));
    expect(cameraController, contains('finishPendingCloseAfterCaptureFailure'));
    expect(
      cameraController,
      contains('back_capture_failed_returned_existing_sections'),
    );
    expect(
      cameraController,
      contains('Opening review with the receipt photos already captured.'),
    );
    expect(
      cameraController.indexOf(
        'if pendingCloseAfterCapture {\n'
        '        finishPendingCloseAfterCaptureFailure()',
      ),
      lessThan(
        cameraController.indexOf(
          'cancelWithoutCapturedPhoto(reason: "back_capture_failed_cancel")',
        ),
      ),
    );
    expect(cameraController, contains('let bottomReviewButton'));
    expect(
      cameraController,
      contains(
        'bottomReviewButton.addTarget(self, action: #selector(finishWithCapturedPhotos)',
      ),
    );
    expect(
      cameraController,
      contains('bottomReviewButton.isEnabled = false'),
    );
    expect(
      cameraController,
      contains('bottomReviewButton.setTitle(title, for: .normal)'),
    );
    expect(cameraController, contains('var cameraViewClosing = false'));
    expect(cameraController, contains('cameraViewClosing = false'));
    expect(cameraController, contains('cameraViewClosing = true'));
    expect(
      cameraController,
      contains('lastBackDispatchPath = "top_bar_back_button"'),
    );
    expect(
      cameraController,
      contains('"lastBackDispatchPath": lastBackDispatchPath'),
    );
    expect(cameraController, contains('var isCameraSessionUsable: Bool'));
    expect(cameraController, contains('var isCameraUiUsable: Bool'));
    expect(
      cameraController,
      contains('guard let self, self.isCameraSessionUsable'),
    );
    expect(
      cameraController,
      contains(
        'self.lastPreCaptureExposureDecision = "aborted_camera_closing"',
      ),
    );
    expect(
      cameraController,
      contains(
        'guard isCameraSessionUsable, !closingCamera, !closeResultDelivered else { return }',
      ),
    );
    expect(
      cameraController,
      contains('videoOutput.setSampleBufferDelegate(nil, queue: nil)'),
    );
    expect(cameraController, contains('receiptFrameGuide'));
    expect(cameraController, contains('alpha: 0.56'));
    expect(cameraController, contains('alpha: 0.50'));
    expect(cameraController, contains('alpha: 0.52'));
    expect(cameraController, contains('alpha: 0.41'));
    expect(cameraController, contains('alpha: 0.46'));
    expect(cameraController, contains('latestCapturedBottomTopLumaDelta'));
    expect(
      cameraController,
      contains('latestCapturedBottomTopLumaDeltaBucket'),
    );
    expect(cameraController, contains('latestFramingWidthRatio'));
    expect(cameraController, contains('latestFramingHeightRatio'));
    expect(
      cameraController,
      contains('"latestFramingWidthRatio": latestFramingWidthRatio'),
    );
    expect(
      cameraController,
      contains('"latestFramingHeightRatio": latestFramingHeightRatio'),
    );
    expect(cameraController, contains('capturedBottomTopLumaDelta(sample)'));
    expect(cameraController, contains('capturedBottomTopLumaDeltaBucket('));
    expect(
      cameraController,
      contains(
        'if sample.bottomLuma < 0 || sample.topLuma < 0 { return -10000 }',
      ),
    );
    expect(
      cameraController,
      contains('if !delta.isFinite || delta < -999 { return "unknown" }'),
    );
    expect(cameraController, contains('bottom_darker_than_top'));
    expect(cameraController, contains('bottom_brighter_than_top'));
    expect(cameraController, contains('preview.videoGravity = .resizeAspectFill'));
    expect(cameraController, isNot(contains('preview.videoGravity = .resizeAspect\n')));
    expect(cameraController, contains('nativePreviewScaleMode'));
    expect(cameraController, contains('nativeControlDensity'));
    expect(cameraController, contains('Reset receipt camera defaults'));
    expect(cameraController, contains('func resetReceiptCameraDefaults()'));
    expect(cameraController, contains('settingsResetCount += 1'));
    expect(
      cameraController,
      contains('Receipt camera defaults restored. Manual shutter is ready.'),
    );
    expect(
      cameraController,
      contains('"settingsResetCount": settingsResetCount'),
    );
    expect(
      cameraController,
      contains(r'return "\(fillMode) | \(reviewMode) | \(receiptMode) | \(lightMode)"'),
    );
    expect(cameraController, contains('private func safeReceiptReviewDepth'));
    expect(cameraController, contains('replacingOccurrences(of: "[\\\\s_-]+"'));
    expect(cameraController, contains('.lowercased()'));
    expect(cameraController, contains('case "detailedlines":'));
    expect(cameraController, contains('case "pricesonly":'));
    expect(
      cameraController,
      contains('"nativeCameraIdentity": "maintainiac_in_app_receipt_camera"'),
    );
    expect(
      cameraController,
      contains(
        '"nativeCaptureUiContract": "maintainiac_custom_receipt_capture_ui_v1"',
      ),
    );
    expect(cameraController, contains('"stockCameraUiUsed": false'));
    expect(
      cameraController,
      contains('"settingsButtonPlacement": "top_bar_right"'),
    );
    expect(cameraController, contains('"backButtonPlacement": "top_bar_left"'));
    expect(
      cameraController,
      contains('"torchButtonPlacement": "top_bar_right"'),
    );
    expect(
      cameraController,
      contains('"shutterButtonPlacement": "bottom_center"'),
    );
    expect(
      cameraController,
      contains('"reviewNextButtonPlacement": "top_and_bottom_after_capture"'),
    );
    expect(
      cameraController,
      contains(
        '"nativeTouchControlPolicy": "continuous_focus_readability_and_pinch_zoom_v1"',
      ),
    );
    expect(
      cameraController,
      contains(
        '"readabilityGuidanceCoordinateSpace": "avfoundation_preview_layer_device_point"',
      ),
    );
    expect(cameraController, isNot(contains('"tapFocusCoordinateSpace"')));
    expect(
      cameraController,
      contains(
        'var zoomGesturePolicy = "avfoundation_video_zoom_factor_clamped_to_capability"',
      ),
    );
    expect(
      cameraController,
      contains(
        'var focusStrategyPolicy = "continuous_focus_primary_no_tap_assist"',
      ),
    );
    expect(cameraController, contains('var continuousFocusEnabled = true'));
    expect(
      cameraController,
      contains('"focusStrategyPolicy": focusStrategyPolicy'),
    );
    expect(
      cameraController,
      contains('"continuousFocusEnabled": continuousFocusEnabled'),
    );
    expect(
      cameraController,
      contains('"readabilityGuidancePolicy": readabilityGuidancePolicy'),
    );
    expect(cameraController, contains('"tapFocusControlExpected": false'));
    expect(cameraController, contains('"focusLockControlExpected": false'));
    expect(cameraController, contains('"exposureLockControlExpected": false'));
    expect(
      cameraController,
      contains('"whiteBalanceLockControlExpected": false'),
    );
    expect(
      cameraController,
      isNot(contains('"tapFocusControlExpected": tapFocusEnabled')),
    );
    expect(
      cameraController,
      isNot(contains('"focusLockControlExpected": focusLockEnabled')),
    );
    expect(
      cameraController,
      isNot(contains('"exposureLockControlExpected": exposureLockEnabled')),
    );
    expect(
      cameraController,
      isNot(
        contains('"whiteBalanceLockControlExpected": whiteBalanceLockEnabled'),
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
      cameraController,
      contains('"receiptCameraQualityBaseline": receiptCameraQualityBaseline'),
    );
    expect(
      cameraController,
      contains(
        'sessionMinZoom = max(doubleArgument("minZoom", fallback: 1.0), 1.0)',
      ),
    );
    expect(
      cameraController,
      contains(
        'sessionMaxZoom = max(doubleArgument("maxZoom", fallback: 1.0), sessionMinZoom)',
      ),
    );
    expect(
      cameraController,
      contains('return value.isFinite ? value : fallback'),
    );
    expect(
      cameraController,
      contains(
        'return value.doubleValue.isFinite ? value.doubleValue : fallback',
      ),
    );
    expect(cameraController, contains('"pinchZoomPolicy": zoomGesturePolicy'));
    expect(cameraController, contains('func visibleControlSet()'));
    expect(
      cameraController,
      contains('"visibleControlSet": visibleControlSet()'),
    );
    expect(
      cameraController,
      contains(
        'var controls = [\n'
        '      "back",\n'
        '      "settings",\n'
        '      "manual_shutter",\n'
        '      "status"\n'
        '    ]',
      ),
    );
    expect(
      cameraController,
      contains(
        'if !torchButton.isHidden && torchButton.isEnabled {\n'
        '      controls.append("light")\n'
        '    }',
      ),
    );
    expect(
      cameraController,
      contains(
        'if exposureSliderEnabled {\n      controls.append("brightness")',
      ),
    );
    expect(
      cameraController,
      contains('return controls.joined(separator: "|")'),
    );
    expect(
      cameraController,
      contains('"previewDominanceTarget": "receipt_preview_75_80_percent"'),
    );
    expect(cameraController, contains('"manual_shutter"'));
    expect(cameraController, contains('"long_receipt_done"'));
    expect(cameraController, contains('"section_ghost_guide"'));
    expect(cameraController, contains('"edge_guide"'));
    expect(
      cameraController,
      contains(
        'Start at the top, add sections in order, and repeat a few readable lines so Maintainiac can match the receipt pieces.',
      ),
    );
    expect(
      cameraController,
      contains(
        '"longReceiptSectionGuidance": "top_to_bottom_with_readable_overlap"',
      ),
    );
    expect(
      cameraController,
      isNot(
        contains(
          'guidanceLabel.backgroundColor = UIColor(white: 0.02, alpha: 0.84)',
        ),
      ),
    );
    expect(
      cameraController,
      isNot(
        contains(
          'bottomBar.backgroundColor = UIColor(white: 0.02, alpha: 0.84)',
        ),
      ),
    );
  });

  test('iOS native camera forces retired focus controls off', () async {
    final cameraController =
        (await readIosReceiptCameraBridgeSources()).cameraController;
    final sessionReader = cameraController.substring(
      cameraController.indexOf('func readSessionArguments()'),
      cameraController.indexOf('func doubleArgument('),
    );
    final tapFocusStatus = cameraController.substring(
      cameraController.indexOf('func tapFocusControlActualStatus()'),
      cameraController.indexOf('func pinchZoomControlActualStatus()'),
    );
    final focusLockStatus = cameraController.substring(
      cameraController.indexOf('func focusLockControlActualStatus()'),
      cameraController.indexOf('func exposureLockControlActualStatus()'),
    );
    final whiteBalanceStatus = cameraController.substring(
      cameraController.indexOf('func whiteBalanceLockControlActualStatus()'),
      cameraController.indexOf('func nextReceiptSectionNumber()'),
    );

    expect(sessionReader, contains('tapFocusEnabled = false'));
    expect(sessionReader, contains('whiteBalanceLockEnabled = false'));
    expect(
      sessionReader,
      isNot(contains('arguments["tapFocusEnabled"] as? Bool')),
    );
    expect(
      sessionReader,
      isNot(contains('arguments["whiteBalanceLockEnabled"] as? Bool')),
    );
    expect(tapFocusStatus, contains('controlStatus(visible: false'));
    expect(tapFocusStatus, contains('enabled: false'));
    expect(focusLockStatus, contains('controlStatus(visible: false'));
    expect(focusLockStatus, contains('enabled: false'));
    expect(whiteBalanceStatus, contains('controlStatus(visible: false'));
    expect(whiteBalanceStatus, contains('enabled: false'));
  });
}
