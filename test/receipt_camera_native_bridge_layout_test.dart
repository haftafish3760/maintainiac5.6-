import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'helpers/receipt_camera_capture_layout_source_readers.dart';

void main() {
  test('native bridge source rejects stock camera controllers', () async {
    final androidCameraUnit = await readAndroidReceiptCameraUnit();
    final androidMain = await File(
      'android/app/src/main/kotlin/com/maintainiac/MainActivity.kt',
    ).readAsString();
    final iosCameraUnit = await readIosReceiptCameraUnit();
    final iosDelegate = await File(
      'ios/Runner/AppDelegate.swift',
    ).readAsString();

    expect(androidCameraUnit, contains('ProcessCameraProvider'));
    expect(androidCameraUnit, contains('PreviewView'));
    expect(androidCameraUnit, contains('ImageCapture'));
    expect(androidCameraUnit, contains('CameraSelector.DEFAULT_BACK_CAMERA'));
    expect(androidCameraUnit, contains('receiptStillCaptureMode'));
    expect(androidCameraUnit, contains('CAPTURE_MODE_MINIMIZE_LATENCY'));
    expect(androidCameraUnit, contains('"receipt_latency_light_device"'));
    expect(androidCameraUnit, contains('"receipt_fast_document_shutter"'));
    expect(androidCameraUnit, contains('PreviewView.ScaleType.FILL_CENTER'));
    expect(
      androidCameraUnit,
      isNot(contains('PreviewView.ScaleType.FIT_CENTER')),
    );
    expect(
      androidCameraUnit,
      contains('nativePreviewScaleMode = "fill_center_full_screen_preview"'),
    );
    expect(androidCameraUnit, contains('AspectRatio.RATIO_4_3'));
    expect(
      androidCameraUnit,
      contains('setJpegQuality(stillCaptureJpegQuality)'),
    );
    expect(androidCameraUnit, contains('ScaleGestureDetector'));
    expect(androidCameraUnit, isNot(contains('FocusMeteringAction')));
    expect(androidCameraUnit, contains('setExposureCompensationIndex'));
    expect(androidCameraUnit, contains('nativeControlReadinessSummary'));
    expect(androidCameraUnit, contains('"pinchZoomControlActual"'));
    expect(androidCameraUnit, contains('"tapFocusControlActual"'));
    expect(androidCameraUnit, contains('"manualShutterControlActual"'));
    expect(androidCameraUnit, contains('"torchControlActual"'));
    expect(androidCameraUnit, contains('"focusLockControlActual"'));
    expect(androidCameraUnit, contains('"exposureLockControlActual"'));
    expect(androidCameraUnit, contains('"whiteBalanceLockControlActual"'));
    expect(androidCameraUnit, contains('previousSectionGuideUsesNextContext'));
    expect(
      androidCameraUnit,
      contains('next_section_top_context_ghost_at_bottom_repeat_3_to_5_lines'),
    );
    expect(androidCameraUnit, contains('next_section_top_lines'));
    expect(
      androidCameraUnit,
      contains('Line up 3-5 readable lines at the top.'),
    );
    expect(androidCameraUnit, contains('latestCapturedBottomTopLumaDelta'));
    expect(
      androidCameraUnit,
      contains('latestCapturedBottomTopLumaDeltaBucket'),
    );
    expect(
      androidCameraUnit,
      contains('text = receiptCameraText("Done", "Listo")'),
    );
    expect(
      androidCameraUnit,
      contains('text = receiptCameraText("Add Photo", "Agregar foto")'),
    );
    expect(androidCameraUnit, contains('"manual_add_photo"'));
    expect(
      androidCameraUnit,
      contains(
        r'"${receiptCameraText("Review Photos", "Revisar fotos")} ($count)"',
      ),
    );
    expect(androidCameraUnit, contains('bottomBar.addView(addPhotoButton)'));
    expect(
      androidCameraUnit,
      contains('bottomBar.addView(bottomReviewButton)'),
    );
    expect(
      androidCameraUnit,
      contains('Saving this receipt photo before opening review.'),
    );
    expect(
      androidCameraUnit,
      isNot(contains('MediaStore.ACTION_IMAGE_CAPTURE')),
    );
    expect(androidCameraUnit, isNot(contains('ACTION_IMAGE_CAPTURE')));
    expect(androidMain, contains('ReceiptCameraActivity::class.java'));
    expect(androidMain, contains('if (pendingReceiptCameraResult != null) {'));
    expect(androidMain, contains('"native_camera_busy"'));
    final androidResultClear = androidMain.indexOf(
      'pendingReceiptCameraResult = null',
    );
    expect(androidResultClear, greaterThanOrEqualTo(0));
    expect(
      androidResultClear,
      lessThan(
        androidMain.indexOf('if (resultCode != RESULT_OK || data == null)'),
      ),
    );
    expect(androidMain, isNot(contains('MediaStore.ACTION_IMAGE_CAPTURE')));

    expect(iosCameraUnit, contains('AVCaptureSession'));
    expect(iosCameraUnit, contains('AVCaptureVideoPreviewLayer'));
    expect(iosCameraUnit, contains('AVCapturePhotoOutput'));
    expect(iosCameraUnit, isNot(contains('UITapGestureRecognizer')));
    expect(iosCameraUnit, contains('UIPinchGestureRecognizer'));
    expect(iosCameraUnit, contains('setExposureTargetBias'));
    expect(iosCameraUnit, contains('nativeControlReadinessSummary'));
    expect(iosCameraUnit, contains('"pinchZoomControlActual"'));
    expect(iosCameraUnit, contains('"tapFocusControlActual"'));
    expect(iosCameraUnit, contains('"manualShutterControlActual"'));
    expect(iosCameraUnit, contains('"torchControlActual"'));
    expect(iosCameraUnit, contains('"focusLockControlActual"'));
    expect(iosCameraUnit, contains('"exposureLockControlActual"'));
    expect(iosCameraUnit, contains('"whiteBalanceLockControlActual"'));
    expect(iosCameraUnit, contains('previousSectionGuideUsesNextContext'));
    expect(
      iosCameraUnit,
      contains('next_section_top_context_ghost_at_top_repeat_3_to_5_lines'),
    );
    expect(iosCameraUnit, contains('next_section_top_lines'));
    expect(iosCameraUnit, contains('Match the next section'));
    expect(iosCameraUnit, contains('latestCapturedBottomTopLumaDelta'));
    expect(iosCameraUnit, contains('latestCapturedBottomTopLumaDeltaBucket'));
    expect(
      iosCameraUnit,
      contains('let addPhotoButton = UIButton(type: .system)'),
    );
    expect(
      iosCameraUnit,
      contains('let bottomReviewButton = UIButton(type: .system)'),
    );
    expect(iosCameraUnit, contains('captureAdditionalPhoto'));
    expect(
      iosCameraUnit,
      contains('Saving this receipt photo before opening review.'),
    );
    expect(iosCameraUnit, isNot(contains('UIImagePickerController')));
    expect(iosDelegate, contains('ReceiptCameraViewController'));
    expect(iosDelegate, contains('if pendingReceiptCameraResult != nil {'));
    expect(iosDelegate, contains('code: "native_camera_busy"'));
    expect(
      iosDelegate,
      contains('let pending = self.pendingReceiptCameraResult'),
    );
    expect(iosDelegate, contains('self.pendingReceiptCameraResult = nil'));
    expect(iosDelegate, isNot(contains('UIImagePickerController')));
  });

  test(
    'android receipt camera split keeps activity overrides in the activity',
    () {
      final directory = Directory(
        'android/app/src/main/kotlin/com/maintainiac',
      );
      final offenders = <String>[];
      for (final file in directory.listSync().whereType<File>()) {
        final name = file.uri.pathSegments.last;
        if (!name.startsWith('ReceiptCamera') || !name.endsWith('.kt')) {
          continue;
        }
        if (name == 'ReceiptCameraActivity.kt') continue;
        final source = file.readAsStringSync();
        if (RegExp(r'^override fun ', multiLine: true).hasMatch(source)) {
          offenders.add(name);
        }
      }

      expect(offenders, isEmpty);
    },
  );

  test(
    'native camera permission helper requests access before capture',
    () async {
      final helper = await File(
        'lib/shared/widgets/receipt_capture/receipt_camera_permission.dart',
      ).readAsString();
      final flow = await readReceiptCaptureFlowSource();
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
      expect(flow, contains("import 'receipt_camera_permission.dart';"));
      expect(flow, contains('ReceiptCameraPermission().ensureReady()'));
      expect(review, contains("import 'receipt_camera_permission.dart';"));
    },
  );

  test(
    'receipt capture declares only the platform permissions it needs',
    () async {
      final androidManifest = await File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsString();
      final iosInfo = await File('ios/Runner/Info.plist').readAsString();

      expect(androidManifest, contains('android.permission.CAMERA'));
      expect(
        androidManifest,
        isNot(contains('android.permission.READ_EXTERNAL_STORAGE')),
      );
      expect(
        androidManifest,
        isNot(contains('android.permission.READ_MEDIA_IMAGES')),
      );
      expect(iosInfo, contains('<key>NSCameraUsageDescription</key>'));
      expect(iosInfo, contains('<key>NSPhotoLibraryUsageDescription</key>'));
    },
  );

  test('photo review can open on a newly added receipt section', () async {
    final reviewScreen = await readReceiptPhotoReviewScreenSource();
    final reviewActions = await File(
      'lib/shared/widgets/receipt_capture/'
      'receipt_attachment_review_read_actions.dart',
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
    expect(reviewActions, contains('ReceiptPhotoImportOrderPlan.build('));
    expect(reviewActions, contains('importOrder.mergedPhotoPaths'));
    expect(
      reviewActions,
      contains('initialSelectedIndex: importOrder.firstImportedPhotoIndex'),
    );
  });
}
