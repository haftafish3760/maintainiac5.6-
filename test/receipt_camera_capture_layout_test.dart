import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'receipt import uses Maintainiac native camera before any fallback',
    () async {
      final pubspec = await File('pubspec.yaml').readAsString();
      final actions = await File(
        'lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart',
      ).readAsString();
      final scanner = await File(
        'lib/shared/widgets/receipt_capture/receipt_scanner_service.dart',
      ).readAsString();
      final imagePicker = await File(
        'lib/shared/widgets/receipt_capture/receipt_image_picker.dart',
      ).readAsString();
      final importSheet = await File(
        'lib/shared/widgets/receipt_capture/receipt_import_source_sheet.dart',
      ).readAsString();
      final standard = await File(
        'docs/receipt_camera_ocr_product_standard.md',
      ).readAsString();
      final oldFlutterCameraScreen = File(
        'lib/shared/widgets/receipt_capture/receipt_camera_screen.dart',
      );

      expect(
        pubspec,
        isNot(contains(RegExp(r'^\s*camera:\s', multiLine: true))),
      );
      expect(pubspec, isNot(contains('package:camera')));
      expect(oldFlutterCameraScreen.existsSync(), isFalse);
      expect(actions, contains('_takeMaintainiacNativeCameraPhoto'));
      expect(actions, contains('ReceiptCameraPermission'));
      expect(
        actions.indexOf('ReceiptCameraPermission().ensureReady()'),
        lessThan(actions.indexOf('ReceiptNativeCameraService')),
      );
      expect(actions, contains('ReceiptNativeCameraService'));
      expect(actions, contains('readCapabilities'));
      expect(actions, contains('captureReceipt'));
      expect(actions, contains('on ReceiptNativeCameraCanceledException'));
      expect(
        actions.indexOf('on ReceiptNativeCameraCanceledException'),
        lessThan(actions.indexOf('on ReceiptNativeCameraUnavailableException')),
      );
      expect(
        actions.indexOf('_takeMaintainiacNativeCameraPhoto(settings)'),
        lessThan(actions.indexOf('NativeReceiptScannerService')),
      );
      expect(
        actions.indexOf('NativeReceiptScannerService'),
        lessThan(actions.indexOf('_takeNativeCameraPhotoFallback')),
      );
      expect(actions, contains('ReceiptImagePicker.takeReceiptPhotoSet()'));
      expect(actions, isNot(contains('ReceiptCameraScreen(')));
      expect(actions, isNot(contains("import 'receipt_camera_screen.dart'")));
      expect(actions, isNot(contains('CameraController')));
      expect(actions, isNot(contains('CameraPreview')));
      expect(actions, contains('initialSelectedIndex: firstNewPhotoIndex'));
      expect(actions, contains('initialCaptureDiagnosticsByPath'));
      expect(actions, contains('staged.captureDiagnosticsByPhotoPath'));
      expect(importSheet, contains('Take Receipt Photo'));
      expect(importSheet, isNot(contains('Scan Receipt')));
      expect(scanner, contains('return Platform.isIOS;'));
      expect(
        scanner,
        contains('Do not make receipt capture wait on a Play Services'),
      );
      expect(scanner, isNot(contains('Platform.isAndroid')));
      expect(
        imagePicker,
        contains('Backup receipt capture uses the phone camera'),
      );
      expect(imagePicker, contains('camera service first'));
      expect(
        standard,
        contains(
          'Android receipt capture should use Maintainiac UI backed by CameraX',
        ),
      );
    },
  );

  test(
    'review add-photo flow also uses native capture before fallback',
    () async {
      final actions = await File(
        'lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart',
      ).readAsString();

      expect(actions, contains('_pickWithMaintainiacNativeCamera'));
      expect(actions, contains('ReceiptCameraPermission'));
      expect(
        actions.indexOf('ReceiptCameraPermission().ensureReady()'),
        lessThan(actions.indexOf('ReceiptNativeCameraService')),
      );
      expect(
        actions,
        contains(
          'final nativeCapabilities = await service.readCapabilities();\n'
          '    if (!mounted) return const _PickedReceiptPhotos.empty();',
        ),
      );
      expect(actions, contains('void _showCameraError(String message)'));
      expect(actions, contains('if (!mounted) return;'));
      expect(actions, contains('previousSectionGuidePhotoPath'));
      expect(actions, contains('ReceiptNativeCameraService'));
      expect(actions, contains('captureReceipt'));
      expect(actions, contains('ReceiptNativeCaptureStaging().stage'));
      expect(
        actions,
        contains(
          'captureDiagnosticsByPath: staged.captureDiagnosticsByPhotoPath',
        ),
      );
      expect(actions, contains('on ReceiptNativeCameraCanceledException'));
      expect(
        actions.indexOf('on ReceiptNativeCameraCanceledException'),
        lessThan(actions.indexOf('on ReceiptNativeCameraUnavailableException')),
      );
      expect(
        actions,
        contains('previousSectionGuidePhotoPath: alignmentGuidePhotoPath'),
      );
      expect(actions, contains('ReceiptImagePicker.takeReceiptPhotoSet()'));
      expect(actions, isNot(contains('ReceiptCameraScreen(')));
      expect(actions, isNot(contains("import 'receipt_camera_screen.dart'")));
      expect(actions, isNot(contains('CameraController')));
      expect(actions, isNot(contains('CameraPreview')));
      expect(actions, contains('Use Add Existing Photo'));
      expect(
        actions,
        contains('Opening the backup receipt photo option instead.'),
      );
    },
  );

  test('native bridge source rejects stock camera controllers', () async {
    final androidActivity = await File(
      'android/app/src/main/kotlin/com/maintainiac/ReceiptCameraActivity.kt',
    ).readAsString();
    final androidMain = await File(
      'android/app/src/main/kotlin/com/maintainiac/MainActivity.kt',
    ).readAsString();
    final iosController = await File(
      'ios/Runner/ReceiptCameraViewController.swift',
    ).readAsString();
    final iosDelegate = await File(
      'ios/Runner/AppDelegate.swift',
    ).readAsString();

    expect(androidActivity, contains('ProcessCameraProvider'));
    expect(androidActivity, contains('PreviewView'));
    expect(androidActivity, contains('ImageCapture'));
    expect(androidActivity, contains('CameraSelector.DEFAULT_BACK_CAMERA'));
    expect(androidActivity, contains('CAPTURE_MODE_MAXIMIZE_QUALITY'));
    expect(androidActivity, contains('setJpegQuality(98)'));
    expect(androidActivity, contains('ScaleGestureDetector'));
    expect(androidActivity, contains('FocusMeteringAction'));
    expect(androidActivity, contains('setExposureCompensationIndex'));
    expect(androidActivity, isNot(contains('MediaStore.ACTION_IMAGE_CAPTURE')));
    expect(androidActivity, isNot(contains('ACTION_IMAGE_CAPTURE')));
    expect(androidMain, contains('ReceiptCameraActivity::class.java'));
    expect(androidMain, isNot(contains('MediaStore.ACTION_IMAGE_CAPTURE')));

    expect(iosController, contains('AVCaptureSession'));
    expect(iosController, contains('AVCaptureVideoPreviewLayer'));
    expect(iosController, contains('AVCapturePhotoOutput'));
    expect(iosController, contains('UITapGestureRecognizer'));
    expect(iosController, contains('UIPinchGestureRecognizer'));
    expect(iosController, contains('setExposureTargetBias'));
    expect(iosController, isNot(contains('UIImagePickerController')));
    expect(iosDelegate, contains('ReceiptCameraViewController'));
    expect(iosDelegate, isNot(contains('UIImagePickerController')));
  });

  test(
    'native camera permission helper requests access before capture',
    () async {
      final helper = await File(
        'lib/shared/widgets/receipt_capture/receipt_camera_permission.dart',
      ).readAsString();
      final panel = await File(
        'lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart',
      ).readAsString();
      final review = await File(
        'lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart',
      ).readAsString();

      expect(helper, contains('Permission.camera.status'));
      expect(helper, contains('Permission.camera.request()'));
      expect(helper, contains('canUseCamera'));
      expect(helper, contains('needsSystemSettings'));
      expect(
        helper,
        contains(
          'Camera permission is needed before Maintainiac can photograph a receipt.',
        ),
      );
      expect(
        helper,
        contains('Camera permission is blocked. Open your phone settings'),
      );
      expect(panel, contains("import 'receipt_camera_permission.dart';"));
      expect(review, contains("import 'receipt_camera_permission.dart';"));
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
    expect(reviewScreen, contains('_ReceiptReviewMode.preview => .18'));
    expect(reviewScreen, contains('roughly 75-80% of the screen'));
    expect(reviewScreen, contains('_ReceiptReviewMode.crop => 88.0'));
    expect(reviewScreen, contains('_ReceiptReviewMode.order => .17'));
    expect(reviewScreen, contains('_ReceiptReviewMode.dataSaver => .18'));
    expect(reviewScreen, contains('_ReceiptReviewMode.dataSaver => 142.0'));
    expect(
      reviewScreen,
      contains('return proportional < absolute ? proportional : absolute;'),
    );
    expect(
      reviewScreen,
      contains('_controlsVisible ? _reviewSurfaceBottomPadding(context) : 0'),
    );
    expect(controls, contains('Scrollbar('));
    expect(controls, contains('thumbVisibility: true'));
    expect(controls, contains('trackVisibility: true'));
  });

  test('photo review tray uses explicit long-receipt language', () async {
    final controls = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart',
    ).readAsString();
    final sectionLabels = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_section_labels.dart',
    ).readAsString();

    expect(controls, contains('class _ReceiptPreviewPrimaryRow'));
    expect(controls, contains('Add Another Photo'));
    expect(controls, contains('add the next section if needed'));
    expect(controls, contains('Photo 1 should be the top'));
    expect(controls, contains('Photo Order'));
    expect(controls, contains('Match Photos'));
    expect(sectionLabels, contains('Receipt Sections'));
    expect(sectionLabels, contains(r'Section ${index + 1} of $total'));
    expect(sectionLabels, contains('Add Next Receipt Section'));
    expect(sectionLabels, contains('Add Next Photo'));
    expect(controls, isNot(contains('Add Another Receipt Photo')));
  });

  test('receipt review continuation copy explains the next screen', () async {
    final controls = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart',
    ).readAsString();
    final dataSaverPanel = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_data_saver_panel.dart',
    ).readAsString();

    expect(controls, contains('Preparing receipt details'));
    expect(controls, contains('Check Match'));
    expect(controls, contains('Receipt Details And Backup Image'));
    expect(controls, contains('Read First'));
    expect(controls, contains('Save After'));
    expect(controls, contains('tap Next to review item prices'));
    expect(dataSaverPanel, contains('Receipt Proof Storage'));
    expect(dataSaverPanel, contains('Uses clear photo first'));
    expect(
      dataSaverPanel,
      contains('clear OCR source before this smaller backup'),
    );
  });

  test('crop mode keeps receipt edges touchable and plainly labeled', () async {
    final cropper = await File(
      'lib/shared/widgets/receipt_capture/receipt_edge_cropper.dart',
    ).readAsString();
    final controls = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart',
    ).readAsString();

    expect(cropper, contains('static const _hitSize = 56.0'));
    expect(cropper, contains('static const _edgeVisibleSize = 8.0'));
    expect(cropper, contains('Semantics('));
    expect(cropper, contains('Move bottom right receipt crop corner'));
    expect(controls, contains('class _ReceiptCropInstructionStrip'));
    expect(
      controls,
      contains(
        'Drag the yellow edges until the full receipt is inside the frame.',
      ),
    );
    expect(
      controls,
      contains('label: Text(cropProcessing ? \'Cropping\' : \'Apply Crop\')'),
    );
  });

  test(
    'receipt photo back protects captured images from silent discard',
    () async {
      final saveActions = await File(
        'lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart',
      ).readAsString();
      final reviewScreen = await File(
        'lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart',
      ).readAsString();

      expect(reviewScreen, contains('enum _ReceiptReviewExitAction'));
      expect(saveActions, contains('_confirmReceiptReviewExit'));
      expect(saveActions, contains('Leave receipt photo?'));
      expect(saveActions, contains('Leave receipt photos?'));
      expect(saveActions, contains('Tap Next to review what Maintainiac read'));
      expect(saveActions, contains('Discard Photo'));
      expect(saveActions, contains('Discard Photos'));
      expect(saveActions, contains('Keep Reviewing'));
      expect(saveActions, contains("child: const Text('Next')"));
    },
  );

  test('long receipt stitch review shows plain decision evidence', () async {
    final controls = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart',
    ).readAsString();
    final models = await File(
      'lib/shared/widgets/receipt_capture/receipt_capture_models.dart',
    ).readAsString();

    expect(models, contains('String get matchConfidenceLabel'));
    expect(models, contains('String get reviewPathLabel'));
    expect(models, contains('String get reviewDecisionLabel'));
    expect(models, contains('String get userFallbackReasonLabel'));
    expect(models, contains('Overlap was not clear enough'));
    expect(models, contains('Receipt is too long for this device'));
    expect(models, contains('1 combined receipt image'));
    expect(models, contains('photos top to bottom'));
    expect(controls, contains('Next reviews photos in this order.'));
    expect(controls, contains("'Combined Receipt Ready'"));
    expect(controls, contains("'Safe Fallback Ready'"));
    expect(controls, contains('preview.userFallbackReasonLabel'));
    expect(controls, contains('Previous Pair'));
    expect(controls, contains('Next Pair'));
    expect(controls, contains('selectedPair.matchEvidenceLabel'));
  });

  test('reviewed receipt photos announce app fill handoff safely', () async {
    final importActions = await File(
      'lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart',
    ).readAsString();
    final ocrActions = await File(
      'lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart',
    ).readAsString();
    final models = await File(
      'lib/shared/widgets/receipt_capture/receipt_capture_models.dart',
    ).readAsString();

    expect(importActions, contains('_startReviewedPhotoReadStatus(result);'));
    expect(models, contains('String get savedProofCountLabel'));
    expect(models, contains('String get ocrSourceCountLabel'));
    expect(models, contains('1 saved proof photo'));
    expect(models, contains('combined OCR image'));
    expect(
      importActions,
      contains(
        r'Backup image saved: $proofCount. Preparing $ocrSourceCount so you can review what Maintainiac read. $qualitySummary Decision: $reviewDecision.',
      ),
    );
    expect(
      importActions,
      contains('String _reviewedPhotoOcrSourceQualitySummary('),
    );
    expect(importActions, contains('OCR source quality'));
    expect(importActions, contains('may need review'));
    expect(
      importActions,
      contains(
        r'Receipt backup image saved: ${result.savedProofCountLabel}. No clear OCR source was available for app-assisted receipt filling.',
      ),
    );
    expect(
      importActions.indexOf('_startReviewedPhotoReadStatus(result);'),
      lessThan(
        importActions.indexOf('await _readReviewedPhotosForReceiptForm'),
      ),
    );
    expect(ocrActions, contains('String _receiptReadSourceSummary'));
    expect(ocrActions, contains('class _ReceiptReadRecoveryAdvice'));
    expect(
      ocrActions,
      contains(
        r'Preparing $sourceSummary for app assistance. When text is found, Maintainiac shows the receipt details so you can check the store, date, total, and item lines.',
      ),
    );
    expect(ocrActions, contains('await Future<void>.sync('));
  });

  test('post-capture quality copy leads with action and evidence', () async {
    final controls = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart',
    ).readAsString();
    final models = await File(
      'lib/shared/widgets/receipt_capture/receipt_capture_models.dart',
    ).readAsString();

    expect(models, contains('String get nextReviewActionLabel'));
    expect(models, contains('String get userFacingStatusLabel'));
    expect(models, contains('String get qualityEvidenceLabel'));
    expect(models, contains('Retake before receipt review'));
    expect(models, contains('Tap Next for filled receipt review'));
    expect(models, contains(r'$reviewBandLabel ($reviewScoreLabel)'));
    expect(controls, contains('quality.userFacingStatusLabel'));
    expect(controls, contains('quality.qualityEvidenceLabel'));
    expect(controls, contains('Add a photo if the receipt continues'));
    expect(controls, isNot(contains('final score =')));
  });

  test('photo review surfaces native saved-photo quality warnings', () async {
    final reviewScreen = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart',
    ).readAsString();
    final controls = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart',
    ).readAsString();

    expect(
      reviewScreen,
      contains(
        'selectedCaptureDiagnostics: _captureDiagnosticsByPath[photoPath]',
      ),
    );
    expect(controls, contains('selectedCaptureDiagnostics'));
    expect(controls, contains('latestCapturedExposureMismatch'));
    expect(controls, contains('latestCapturedQualitySignal'));
    expect(controls, contains('latestCapturedBrightnessBucket'));
    expect(controls, contains('latestCapturedSharpnessBucket'));
    expect(controls, contains('Photo saved darker than the camera preview.'));
    expect(controls, contains('Retake with more light or raise Brightness'));
    expect(controls, contains('Photo may be too soft for receipt reading.'));
    expect(controls, contains('Photo may have glare.'));
  });

  test(
    'photo review async preview work cleans up after lifecycle changes',
    () async {
      final reviewScreen = await File(
        'lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart',
      ).readAsString();
      final editActions = await File(
        'lib/shared/widgets/receipt_capture/receipt_photo_review_image_edit_actions.dart',
      ).readAsString();

      expect(reviewScreen, contains('var _reviewDisposed = false;'));
      expect(reviewScreen, contains('_reviewDisposed = true;'));
      expect(
        reviewScreen,
        contains('bool _updateReviewState(VoidCallback update)'),
      );
      expect(
        reviewScreen,
        contains('if (!mounted || _reviewDisposed) return false;'),
      );
      expect(
        reviewScreen,
        contains('!_dataSaverPreviewKeysInFlight.contains(key)'),
      );
      expect(reviewScreen, contains('!_photoPaths.contains(photoPath)'));
      expect(
        reviewScreen,
        contains(
          'await _deleteDataSaverPreviewPath(previewPath, sourcePath: photoPath)',
        ),
      );
      expect(reviewScreen, contains('keepRetained = true'));
      expect(
        reviewScreen,
        contains(
          'await _deleteDataSaverPreviewPath(path, keepRetained: false)',
        ),
      );
      expect(editActions, contains('await _deleteDataSaverPreviewPath(path);'));
    },
  );
}
