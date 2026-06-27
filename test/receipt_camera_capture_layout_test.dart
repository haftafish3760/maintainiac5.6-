import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('receipt camera controls are anchored to screen edges', () async {
    final screen = await File(
      'lib/shared/widgets/receipt_capture/receipt_camera_screen.dart',
    ).readAsString();
    final bars = await File(
      'lib/shared/widgets/receipt_capture/receipt_camera_bars.dart',
    ).readAsString();

    expect(screen, contains('Positioned('));
    expect(screen, contains('top: 0'));
    expect(screen, contains('_ReceiptCameraTopBar('));
    expect(screen, contains('onPopInvokedWithResult'));
    expect(screen, contains('_requestCloseCamera'));
    expect(screen, contains('HitTestBehavior.translucent'));
    expect(screen, contains('alignment: Alignment.bottomCenter'));
    expect(
      screen,
      isNot(contains('bottom: MediaQuery.paddingOf(context).bottom + 112')),
    );
    expect(screen, contains('SafeArea('));
    expect(screen, contains('_ReceiptZoomLevelBadge('));
    expect(screen, contains('_liveFrameForOverlay()'));
    expect(screen, contains('_mode != _ReceiptCameraMode.assisted'));
    expect(screen, contains('minimumLiveEdgeConfidence'));
    expect(screen, contains('_ReceiptCameraInteractionHint('));
    expect(screen, isNot(contains('_ReceiptLongReceiptFloatingHint()')));
    expect(screen, contains('_ReceiptPreviousSectionGuide('));
    expect(
      screen,
      contains('IgnorePointer(\n            child: _ReceiptCameraGuidancePill'),
    );
    expect(
      screen.lastIndexOf('_ReceiptCameraTopBar('),
      greaterThan(screen.lastIndexOf('_ReceiptCameraBottomBar(')),
    );
    expect(screen, contains('previousSectionGuidePath'));
    expect(screen, contains('Duration(milliseconds: 300)'));
    expect(screen, contains('canPop: false'));
    expect(screen, contains('unawaited(_stopLiveAssistance())'));
    expect(screen, contains('Navigator.of(context).pop();'));
    expect(screen, contains('void _finishCameraWithResult'));
    expect(screen, contains('_controller = null;'));
    expect(screen, contains('unawaited(_disposeCameraController(controller))'));
    expect(
      screen.indexOf('Navigator.of(context).pop();'),
      lessThan(
        screen.indexOf(
          'unawaited(_disposeCameraController(controller));',
          screen.indexOf('void _requestCloseCamera()'),
        ),
      ),
    );
    expect(
      screen.indexOf('Navigator.of(context).pop<ReceiptCameraResult>(result);'),
      lessThan(
        screen.indexOf(
          'unawaited(_disposeCameraController(controller));',
          screen.indexOf('void _finishCameraWithResult'),
        ),
      ),
    );
    expect(screen, contains('_closingCamera = true;'));
    expect(
      screen,
      isNot(contains('WidgetsBinding.instance.addPostFrameCallback')),
    );
    expect(screen, isNot(contains('Navigator.of(context).maybePop();')));
    expect(bars, contains('Icons.arrow_back_rounded'));
    expect(bars, contains('Icons.settings_rounded'));
    expect(bars, contains('Icons.flashlight_on_rounded'));
    expect(bars, contains('mainAxisAlignment: MainAxisAlignment.spaceBetween'));
    expect(bars, contains('_CameraModeBadge'));
    expect(bars, contains('LinearGradient'));
    expect(bars, contains("label: assistedMode ? 'Assisted' : 'Manual'"));
    expect(bars, contains("'Tap anytime'"));
    expect(
      bars,
      contains("label: longReceiptTipsEnabled ? 'Long Receipt' : 'Focus'"),
    );
    expect(bars, isNot(contains('String get _instruction')));
    expect(bars, isNot(contains('Icons.zoom_in_rounded')));
  });

  test('camera interaction feedback is compact and nonblocking', () async {
    final screen = await File(
      'lib/shared/widgets/receipt_capture/receipt_camera_screen.dart',
    ).readAsString();
    final feedback = await File(
      'lib/shared/widgets/receipt_capture/receipt_camera_feedback.dart',
    ).readAsString();
    final preview = await File(
      'lib/shared/widgets/receipt_capture/receipt_camera_preview.dart',
    ).readAsString();

    expect(screen, contains('_interactionHint'));
    expect(screen, contains('_queuedZoomLevel'));
    expect(screen, contains('_zoomSettingInFlight'));
    expect(screen, contains('_receiptExposureOffsetFor'));
    expect(
      screen,
      contains('Keep the camera at the native auto-exposure baseline.'),
    );
    expect(screen, contains('0.0.clamp(minOffset, maxOffset).toDouble()'));
    expect(screen, isNot(contains('ReceiptCapabilityTier.light => 0.35')));
    expect(screen, isNot(contains('ReceiptCapabilityTier.medium => 0.45')));
    expect(
      screen,
      isNot(contains('ReceiptCapabilityTier.heavyweight => 0.55')),
    );
    expect(screen, contains('_normalizedCameraPointForPreview('));
    expect(screen, contains('controller.value.previewSize'));
    expect(screen, contains('displayedPreviewSize'));
    expect(screen, contains('final scale = math.max('));
    expect(screen, contains('final cropOffset = Offset('));
    expect(
      screen,
      contains('bottom: MediaQuery.paddingOf(context).bottom + 166'),
    );
    expect(screen, contains("_showInteractionHint('Focus set')"));
    expect(
      screen,
      contains("_showInteractionHint(next ? 'Torch on' : 'Torch off')"),
    );
    expect(
      screen,
      contains("_showInteractionHint('Zoom is not available on this camera.')"),
    );
    expect(screen, isNot(contains('details.pointerCount < 2')));
    expect(feedback, contains('class _ReceiptCameraInteractionHint'));
    expect(feedback, contains('IgnorePointer('));
    expect(feedback, contains('maxWidth: 320'));
    expect(feedback, contains('maxLines: 1'));
    expect(preview, contains('if (!controller.value.isInitialized)'));
    expect(
      preview,
      contains("return const ColoredBox(color: Color(0xFF050607))"),
    );
  });

  test(
    'long receipt ghost guide is visual only and does not block focus',
    () async {
      final preview = await File(
        'lib/shared/widgets/receipt_capture/receipt_camera_preview.dart',
      ).readAsString();
      final capture = await File(
        'lib/shared/widgets/receipt_capture/receipt_camera_capture.dart',
      ).readAsString();

      expect(preview, contains('class _ReceiptPreviousSectionGuide'));
      expect(preview, contains('IgnorePointer('));
      expect(preview, contains('alignment: Alignment.bottomCenter'));
      expect(
        preview,
        contains(
          'Line up this previous bottom slice with the top of the next photo.',
        ),
      );
      expect(preview, contains('opacity: .34'));
      expect(capture, contains('minimumLiveEdgeConfidence'));
      expect(capture, contains('ReceiptCapabilityTier.light => false'));
    },
  );

  test('review add-photo flow avoids Play Services scanner on Android', () async {
    final actions = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart',
    ).readAsString();
    final scanner = await File(
      'lib/shared/widgets/receipt_capture/receipt_scanner_service.dart',
    ).readAsString();
    final imagePicker = await File(
      'lib/shared/widgets/receipt_capture/receipt_image_picker.dart',
    ).readAsString();

    expect(
      actions,
      contains(
        'NativeReceiptScannerService.documentScannerAllowedOnThisPlatform',
      ),
    );
    expect(actions, contains('const NativeReceiptScannerService()'));
    expect(actions, contains('.scanReceipt('));
    expect(actions, contains('ReceiptImagePicker.takeReceiptPhotoSet()'));
    expect(actions, contains('_nativeCameraOpenErrorMessage'));
    expect(actions, contains('Camera permission is blocked.'));
    expect(
      actions,
      contains('Camera was canceled. No receipt photo was added.'),
    );
    expect(actions, contains('Use Add Existing Photo'));
    expect(
      actions,
      contains(
        'Opening the phone camera instead so you can still capture the receipt.',
      ),
    );
    expect(actions, isNot(contains('ReceiptCameraScreen(')));
    expect(actions, isNot(contains("import 'receipt_camera_screen.dart'")));
    expect(actions, isNot(contains('CameraController')));
    expect(actions, isNot(contains('CameraPreview')));
    expect(actions, isNot(contains('previousSectionGuidePath')));
    expect(imagePicker, contains('ReceiptPickedPhotoSet'));
    expect(imagePicker, contains('takeReceiptPhotoSet'));
    expect(imagePicker, contains('chooseReceiptImageSet'));
    expect(
      imagePicker,
      isNot(contains('static Future<XFile?> takeReceiptPhoto')),
    );
    expect(imagePicker, isNot(contains('static Future<List<XFile>>')));
    expect(actions, contains('_reviewMode = _ReceiptReviewMode.order'));
    expect(actions, contains('_controlsVisible = true'));
    expect(scanner, contains('return Platform.isIOS;'));
    expect(
      scanner,
      contains('Do not make receipt capture wait on a Play Services'),
    );
  });

  test(
    'receipt import uses platform-safe scanner before camera fallback',
    () async {
      final actions = await File(
        'lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart',
      ).readAsString();
      final scanner = await File(
        'lib/shared/widgets/receipt_capture/receipt_scanner_service.dart',
      ).readAsString();
      final importSheet = await File(
        'lib/shared/widgets/receipt_capture/receipt_import_source_sheet.dart',
      ).readAsString();
      final standard = await File(
        'docs/receipt_camera_ocr_product_standard.md',
      ).readAsString();

      expect(
        actions,
        contains(
          'NativeReceiptScannerService.documentScannerAllowedOnThisPlatform',
        ),
      );
      expect(actions, contains('settings.setCameraSetupComplete(true)'));
      expect(
        actions,
        contains('final firstNewPhotoIndex = _photoPaths.length'),
      );
      expect(
        actions,
        isNot(
          contains('_openReceiptCaptureSettings(\n          setupMode: true'),
        ),
      );
      expect(actions, contains('const NativeReceiptScannerService()'));
      expect(actions, contains('.scanReceipt('));
      expect(actions, contains('_takeNativeCameraPhotoFallback'));
      expect(actions, contains('ReceiptImagePicker.takeReceiptPhotoSet()'));
      expect(actions, isNot(contains('ReceiptCameraScreen(')));
      expect(actions, isNot(contains("import 'receipt_camera_screen.dart'")));
      expect(actions, isNot(contains('CameraController')));
      expect(actions, isNot(contains('CameraPreview')));
      expect(actions, contains('initialSelectedIndex: firstNewPhotoIndex'));
      expect(importSheet, contains('Take Receipt Photo'));
      expect(importSheet, isNot(contains('Scan Receipt')));
      expect(actions, contains('_showScannerFallbackNotice'));
      expect(
        actions,
        contains(
          'Opening the phone camera instead so you can still capture the receipt.',
        ),
      );
      expect(actions, contains('_nativeCameraOpenErrorMessage'));
      expect(actions, contains('Camera permission is blocked.'));
      expect(actions, contains('try Take Receipt Photo again'));
      expect(actions, contains('choose an existing receipt image instead'));
      expect(
        actions,
        contains('Camera was canceled. No receipt photo was added.'),
      );
      expect(actions, contains('initialQualityChecksByPath'));
      expect(actions, contains('_qualityChecksByPathForCameraResult'));
      expect(scanner, contains('ReceiptCameraResult.single'));
      expect(
        scanner,
        contains('return const ReceiptNativeScanResult.unavailable();'),
      );
      expect(scanner, isNot(contains('Platform.isAndroid')));
      expect(
        scanner,
        isNot(contains('ReceiptCameraResult.bestShotCandidates')),
      );
      expect(
        standard,
        contains('Android receipt capture should use the phone camera path'),
      );
    },
  );

  test('photo review can open on a newly added receipt section', () async {
    final reviewScreen = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart',
    ).readAsString();
    final actions = await File(
      'lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart',
    ).readAsString();

    expect(reviewScreen, contains('this.initialSelectedIndex = 0'));
    expect(reviewScreen, contains('final int initialSelectedIndex'));
    expect(
      reviewScreen,
      contains('late var _selectedIndex = _initialSelectedIndex()'),
    );
    expect(reviewScreen, contains('int _initialSelectedIndex()'));
    expect(
      reviewScreen,
      contains('widget.initialSelectedIndex.clamp(0, _photoPaths.length - 1)'),
    );
    expect(actions, contains('final firstNewPhotoIndex = _photoPaths.length'));
    expect(actions, contains('initialSelectedIndex: firstNewPhotoIndex'));
  });

  test('assisted manual shutter does not block questionable photos', () async {
    final screen = await File(
      'lib/shared/widgets/receipt_capture/receipt_camera_screen.dart',
    ).readAsString();

    expect(
      screen,
      isNot(contains('Photo captured. Review the store, date, total')),
    );
    expect(screen, contains('_autoCaptureQueued = false;'));
    expect(screen, contains('_guidedCaptureWaiting = false;'));
    final liveAnalysis = await File(
      'lib/shared/widgets/receipt_capture/receipt_camera_live_analysis.dart',
    ).readAsString();
    expect(liveAnalysis, contains('!_autoCaptureQueued'));
    expect(
      liveAnalysis.indexOf('!_autoCaptureQueued'),
      lessThan(liveAnalysis.indexOf('await _captureAssistedScan();')),
    );
    expect(
      screen,
      isNot(contains('_deleteUnusedReceiptCameraPhotos(candidates, const {})')),
    );
    expect(
      screen,
      isNot(
        contains('return;\n      }\n      final selectedCandidates = [?best];'),
      ),
    );
  });

  test('photo review bottom controls stay capped by mode', () async {
    final reviewScreen = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart',
    ).readAsString();
    final controls = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart',
    ).readAsString();

    expect(
      reviewScreen,
      contains('double _reviewBottomControlsMaxHeight(BuildContext context)'),
    );
    expect(
      reviewScreen,
      contains('final proportional = MediaQuery.sizeOf(context).height * .22'),
    );
    expect(reviewScreen, contains('150.0 : 112.0'));
    expect(reviewScreen, contains('_ReceiptReviewMode.crop => 96.0'));
    expect(reviewScreen, contains('_ReceiptReviewMode.order => 154.0'));
    expect(reviewScreen, contains('_ReceiptReviewMode.stitch => 176.0'));
    expect(reviewScreen, contains('_ReceiptReviewMode.dataSaver => 170.0'));
    expect(
      reviewScreen,
      contains('return proportional < absolute ? proportional : absolute;'),
    );
    expect(
      reviewScreen,
      contains('double _reviewSurfaceBottomPadding(BuildContext context)'),
    );
    expect(
      reviewScreen,
      contains('return _reviewBottomControlsMaxHeight(context) + 8;'),
    );
    expect(
      reviewScreen,
      contains('_controlsVisible ? _reviewSurfaceBottomPadding(context) : 0'),
    );
    expect(
      reviewScreen,
      contains('final _toolControlsScrollController = ScrollController()'),
    );
    expect(reviewScreen, contains('_toolControlsScrollController.dispose();'));
    expect(reviewScreen, contains('toolControlsScrollController:'));
    expect(controls, contains('Scrollbar('));
    expect(controls, contains('thumbVisibility: true'));
    expect(controls, contains('trackVisibility: true'));
    expect(controls, contains('controller: toolControlsScrollController'));
  });

  test('photo review tray uses explicit next-photo receipt language', () async {
    final controls = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart',
    ).readAsString();

    expect(controls, contains('Add Another Photo'));
    expect(controls, contains('Add Next Photo'));
    expect(controls, contains('tap Add Another Photo'));
    expect(controls, contains('Tap Add Next Photo'));
    expect(controls, contains('Retake Clearer Photo'));
    expect(controls, isNot(contains("label: hasMultiplePhotos ? 'Add Photo'")));
    expect(controls, isNot(contains('Check order and match, then tap Next')));
  });

  test('tool mode context actions use labeled phone-visible buttons', () async {
    final controls = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart',
    ).readAsString();

    expect(controls, contains('class _MiniReceiptActionButton'));
    expect(controls, contains('FilledButton.icon('));
    expect(controls, contains('label: photoCount > 1'));
    expect(controls, contains("'Add Next Photo'"));
    expect(controls, contains("'Add Another Photo'"));
    expect(controls, contains("label: 'Retake'"));
    expect(controls, contains("label: 'Remove'"));
    expect(controls, contains('height: 34'));
    expect(
      controls.indexOf('class _ReceiptReviewContextRow'),
      lessThan(controls.indexOf('class _MiniReceiptActionButton')),
    );
  });

  test('tool mode next button stays outside scrollable controls', () async {
    final controls = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart',
    ).readAsString();
    final reviewScreen = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart',
    ).readAsString();

    expect(reviewScreen, contains('toolControlsScrollController:'));
    expect(
      controls,
      contains('final ScrollController toolControlsScrollController'),
    );
    expect(controls, contains('class _ReceiptPersistentContinueButton'));
    expect(controls, contains('Flexible('));
    expect(controls, contains('Scrollbar('));
    expect(controls, contains('SingleChildScrollView('));
    expect(
      controls.indexOf('Scrollbar('),
      lessThan(controls.indexOf('_ReceiptPersistentContinueButton(')),
    );
    expect(
      controls.indexOf('SingleChildScrollView('),
      lessThan(controls.indexOf('_ReceiptPersistentContinueButton(')),
    );
  });

  test('review mode transitions reset tool scroll position', () async {
    final screen = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart',
    ).readAsString();
    final editActions = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_image_edit_actions.dart',
    ).readAsString();

    expect(
      editActions,
      contains('void _setReviewMode(_ReceiptReviewMode mode)'),
    );
    expect(editActions, contains('_resetToolControlsScrollPosition();'));
    expect(editActions, contains('void _resetToolControlsScrollPosition()'));
    expect(editActions, contains('!_toolControlsScrollController.hasClients'));
    expect(editActions, contains('_toolControlsScrollController.jumpTo('));
    expect(editActions, contains('position.minScrollExtent'));
    expect(screen, contains('onClose: _reviewMode == _ReceiptReviewMode.crop'));
    expect(
      screen,
      contains('? () => _setReviewMode(_ReceiptReviewMode.preview)'),
    );
    expect(
      screen,
      contains(
        'onCancelCrop: () => _setReviewMode(_ReceiptReviewMode.preview)',
      ),
    );
  });

  test('photo review top controls stay edge anchored', () async {
    final topBar = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart',
    ).readAsString();

    expect(topBar, contains('Icons.arrow_back_rounded'));
    expect(topBar, contains('label: \'Back to receipt form\''));
    expect(topBar, contains('alignment: Alignment.centerLeft'));
    expect(
      topBar,
      contains('constraints: const BoxConstraints(maxWidth: 260)'),
    );
    expect(topBar, contains('Icons.fullscreen_rounded'));
    expect(topBar, contains('Icons.more_vert_rounded'));
    expect(topBar, isNot(contains('const Spacer()')));
    expect(
      topBar.indexOf('Icons.arrow_back_rounded'),
      lessThan(topBar.indexOf('alignment: Alignment.centerLeft')),
    );
    expect(
      topBar.indexOf('alignment: Alignment.centerLeft'),
      lessThan(topBar.indexOf('Icons.fullscreen_rounded')),
    );
    expect(
      topBar.indexOf('Icons.fullscreen_rounded'),
      lessThan(topBar.indexOf('Icons.more_vert_rounded')),
    );
  });
}
