import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'helpers/receipt_camera_capture_layout_source_readers.dart';

void main() {
  test(
    'receipt import uses Maintainiac native camera before any fallback',
    () async {
      final pubspec = await File('pubspec.yaml').readAsString();
      final actions = await readReceiptAttachmentImportActionsSource();
      final flow = await readReceiptCaptureFlowSource();
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
      final resultModels = await readReceiptCaptureModelsSource();
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
      expect(actions, contains('_MaintainiacNativeCameraPhotoOutcome'));
      expect(actions, contains('ReceiptCaptureFlow().captureAndReview'));
      expect(
        actions.indexOf('_takeMaintainiacNativeCameraPhoto(settings)'),
        lessThan(
          actions.indexOf('_openReceiptBackupCaptureAfterNativeUnavailable'),
        ),
      );
      expect(flow, contains('ReceiptCameraPermission'));
      expect(
        flow.indexOf('ReceiptCameraPermission().ensureReady()'),
        lessThan(flow.indexOf('readCapabilities()')),
      );
      expect(flow, contains('ReceiptNativeCameraService'));
      expect(flow, contains('readCapabilities'));
      expect(flow, contains('captureReceipt'));
      expect(flow, contains('_stagedDataSaverLevelFor('));
      expect(flow, contains("capture.captureDiagnostics['dataSaverLevel']"));
      expect(
        flow.indexOf('final stagedDataSaverLevel = _stagedDataSaverLevelFor('),
        lessThan(flow.indexOf('staged = await flow._staging.stage(')),
      );
      expect(flow, contains('dataSaverLevel: stagedDataSaverLevel'));
      expect(
        flow,
        contains('on ReceiptNativeCameraCanceledException catch (error)'),
      );
      expect(flow, contains("'closeAction': error.closeAction"));
      expect(
        actions,
        contains(
          'nativeOutcome == _MaintainiacNativeCameraPhotoOutcome.canceled',
        ),
      );
      expect(
        flow.indexOf('on ReceiptNativeCameraCanceledException catch (error)'),
        lessThan(flow.indexOf('on ReceiptNativeCameraUnavailableException')),
      );
      expect(
        actions.indexOf('_takeMaintainiacNativeCameraPhoto(settings)'),
        lessThan(actions.indexOf('NativeReceiptScannerService')),
      );
      expect(
        actions.indexOf('_openReceiptBackupCaptureAfterNativeUnavailable'),
        lessThan(actions.indexOf('NativeReceiptScannerService')),
      );
      expect(actions, isNot(contains('_takeNativeCameraPhotoFallback')));
      expect(actions, contains('_takePhoneCameraBackupPhoto'));
      expect(
        actions,
        contains('ReceiptImagePicker.takeBackupReceiptPhotoSet()'),
      );
      expect(
        actions,
        isNot(contains('ReceiptImagePicker.takeReceiptPhotoSet()')),
      );
      expect(actions, contains('phone_camera_backup_receipt_photo'));
      expect(actions, contains('document_scanner_backup_receipt_photo'));
      expect(
        actions,
        contains(
          "'backupCaptureAuthorizedBy': 'maintainiac_native_unavailable'",
        ),
      );
      expect(actions, contains("'stockCameraUiAllowedAsPrimary': false"));
      expect(actions, contains("'documentScannerBackupRole': 'fallback_only'"));
      expect(
        actions,
        contains(
          'Opening the phone camera as backup capture; the photo still returns to Maintainiac receipt review.',
        ),
      );
      final backupHelperStart = actions.indexOf(
        'Future<void> _openReceiptBackupCaptureAfterNativeUnavailable',
      );
      final backupHelperEnd = actions.indexOf(
        'Future<void> _reviewDocumentScannerBackup',
        backupHelperStart,
      );
      final backupHelperBlock = actions.substring(
        backupHelperStart,
        backupHelperEnd,
      );
      expect(
        backupHelperBlock.indexOf('NativeReceiptScannerService'),
        lessThan(backupHelperBlock.indexOf('_takePhoneCameraBackupPhoto')),
      );
      expect(actions, isNot(contains('ReceiptCameraScreen(')));
      expect(actions, isNot(contains("import 'receipt_camera_screen.dart'")));
      expect(actions, isNot(contains('CameraController')));
      expect(actions, isNot(contains('CameraPreview')));
      expect(actions, contains('initialSelectedIndex: firstNewPhotoIndex'));
      expect(actions, contains('uniqueNormalizedReceiptPhotoPaths('));
      expect(actions, contains('initialCaptureDiagnosticsByPath'));
      expect(actions, contains('receiptBrainDiagnosticsByPath'));
      expect(actions, contains('_defaultReceiptBrainDiagnosticMetadata'));
      expect(actions, contains('receiptBrainFootprintSummaryFor'));
      expect(actions, contains('...footprint.toPrivacySafeDiagnostics()'));
      expect(
        actions,
        contains('receipt_attachment_import_default_local_policy'),
      );
      expect(actions, contains('existing_receipt_photo_import'));
      expect(flow, contains('staged.captureDiagnosticsByPhotoPath'));
      expect(importSheet, contains('Capture Photo'));
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
        imagePicker,
        contains(
          'static Future<ReceiptPickedPhotoSet> takeBackupReceiptPhotoSet()',
        ),
      );
      expect(imagePicker, contains('return takeBackupReceiptPhotoSet();'));
      expect(
        standard,
        contains(
          'Android receipt capture should use Maintainiac UI backed by CameraX',
        ),
      );
      expect(resultModels, isNot(contains('flutter_camera_native_backend')));
      expect(resultModels, contains('maintainiac_native_android'));
      expect(resultModels, contains('maintainiac_native_ios'));
    },
  );

  test('review add-photo flow also uses native capture before fallback', () async {
    final actions = await readReceiptPhotoReviewSaveActionsSource();
    final previewActionTray =
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_preview_action_tray.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_preview_action_status.dart',
        ).readAsString();
    final service =
        await File(
          'lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_native_camera_service_contract_helpers.dart',
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
        '    if (!_reviewWorkActive) return const _PickedReceiptPhotos.empty();',
      ),
    );
    expect(actions, contains('void _showCameraError(String message)'));
    expect(actions, contains('if (!_reviewWorkActive) return;'));
    expect(actions, contains('previousSectionGuidePhotoPath'));
    expect(actions, contains('ReceiptNativeCameraService'));
    expect(actions, contains('captureReceipt'));
    expect(actions, contains('ReceiptNativeCaptureStaging().stage'));
    expect(
      actions,
      contains(
        'final result = await service.captureReceipt(\n'
        '        cameraSettings.sessionFor(',
      ),
    );
    expect(
      actions,
      contains(
        'if (!_reviewWorkActive) return const _PickedReceiptPhotos.empty();\n'
        '      if (!result.hasPhotos) return const _PickedReceiptPhotos.empty();',
      ),
    );
    expect(
      actions,
      contains(
        'if (!_reviewWorkActive) return const _PickedReceiptPhotos.empty();\n'
        '      if (!staged.hasPhotos) return const _PickedReceiptPhotos.empty();',
      ),
    );
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
    expect(actions, contains('ReceiptImagePicker.takeBackupReceiptPhotoSet()'));
    expect(
      actions,
      isNot(contains('ReceiptImagePicker.takeReceiptPhotoSet()')),
    );
    expect(actions, contains('fromPhoneCameraBackupPaths'));
    expect(actions, contains('hadPreviousSectionGuide:'));
    expect(actions, contains('phone_camera_backup_receipt_photo'));
    expect(actions, contains('primaryCaptureFlow'));
    expect(actions, contains('maintainiac_native_receipt_camera'));
    expect(actions, contains('phoneCameraBackupRole'));
    expect(actions, contains('fallback_only'));
    expect(actions, contains('phoneCameraBackupUserFacingLabel'));
    expect(
      actions,
      contains('Phone camera backup; returns to Maintainiac review'),
    );
    expect(service, contains('stockCameraUiPolicy'));
    expect(service, contains('phoneCameraBackupAllowed'));
    expect(service, contains('phoneCameraBackupRole'));
    expect(actions, contains('phoneCameraBackupHadPreviousSectionGuide'));
    expect(actions, contains('Opening the phone camera as backup capture'));
    expect(actions, contains('still returns to Maintainiac receipt review'));
    expect(actions, isNot(contains('ReceiptCameraScreen(')));
    expect(actions, isNot(contains("import 'receipt_camera_screen.dart'")));
    expect(actions, isNot(contains('CameraController')));
    expect(actions, isNot(contains('CameraPreview')));
    expect(actions, contains('Use Add Existing Photo'));
    expect(
      previewActionTray,
      contains(
        "return 'Phone camera backup capture; still reviewed in Maintainiac. ';",
      ),
    );
    expect(previewActionTray, contains('isPhoneCameraBackupCapture'));
  });

  test(
    'first-use receipt camera setup is full screen, not a slide-up sheet',
    () async {
      final actions = await readReceiptAttachmentImportActionsSource();
      final intro = await File(
        'lib/shared/widgets/receipt_capture/receipt_camera_first_use_intro_sheet.dart',
      ).readAsString();
      final bottomBar = await File(
        'lib/shared/widgets/receipt_capture/receipt_native_camera_shell_bottom_bar.dart',
      ).readAsString();

      final firstUseStart = actions.indexOf(
        'Future<bool> _showFirstUseReceiptCameraIntro',
      );
      final firstUseEnd = actions.indexOf(
        'String _nativeCameraOpenErrorMessage',
        firstUseStart,
      );
      final firstUseBlock = actions.substring(firstUseStart, firstUseEnd);

      expect(firstUseBlock, contains('Navigator.of(context)'));
      expect(firstUseBlock, contains('.push<_ReceiptFirstUseCameraAction>'));
      expect(firstUseBlock, contains('MaterialPageRoute'));
      expect(firstUseBlock, contains('fullscreenDialog: true'));
      expect(firstUseBlock, isNot(contains('showModalBottomSheet')));
      expect(intro, contains('return Scaffold('));
      expect(intro, contains('Receipt Assist'));
      expect(
        intro,
        contains(
          'Would you like Maintainiac to help fill out receipt details?',
        ),
      );
      expect(intro, contains('Yes, Use Receipt Assist'));
      expect(intro, contains('No, Manual Entry'));
      expect(intro, isNot(contains('Receipt Camera Setup')));
      expect(intro, isNot(contains('ListView(')));
      expect(intro, isNot(contains('Continue To Camera')));
      expect(intro, isNot(contains('Open Receipt Settings')));
      expect(bottomBar, contains('SafeArea('));
      expect(bottomBar, contains('minimum: const EdgeInsets.only(bottom: 8)'));
      expect(bottomBar, contains('_ReceiptNativeCameraShutterButton'));
      expect(bottomBar, contains('class _ReceiptNativeCameraNextStepStrip'));
      expect(
        bottomBar,
        contains('capturedPhotoCount > 0 && onReviewCapturedPhotos != null'),
      );
      expect(bottomBar, contains("return 'Done';"));
      expect(bottomBar, contains("return 'Done (\$capturedPhotoCount)';"));
      expect(bottomBar, contains("label: 'Add Photo'"));
    },
  );
}
