import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_settings_store.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_native_camera_contract.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_native_camera_preference_mapper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'receipt_camera_preference_mapper_test_',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  test(
    'saved camera preferences configure the native capture session',
    () async {
      final settings = await ReceiptCaptureSettingsController.create();
      await settings.setCameraGuidanceEnabled(false);
      await settings.setCameraAutoCapture(true);
      await settings.setCameraLongReceiptTips(false);
      await settings.setReceiptPhotoBackupEnabled(true);
      await settings.setAskSavedProofSizeEachReceipt(true);

      final camera = receiptNativeCameraSettingsForCapture(
        settings: settings,
        assistedReceiptFill: false,
        longReceiptMode: true,
        autoCaptureEnabled: settings.cameraAutoCapture,
        reviewDepth: ReceiptNativeReviewDepth.detailedLines,
        dataSaverLevel: ReceiptDataSaverLevel.balanced,
      );

      expect(camera.liveYuvAnalysisEnabled, isFalse);
      expect(camera.edgeDetectionEnabled, isFalse);
      expect(camera.edgeOverlayEnabled, isFalse);
      expect(camera.motionBlurWarningEnabled, isFalse);
      expect(camera.receiptFullyVisibleWarningEnabled, isFalse);
      expect(camera.previousSectionGhostGuideEnabled, isFalse);
      expect(camera.receiptPhotoBackupEnabled, isTrue);
      expect(camera.askSavedProofSizeEachReceipt, isTrue);
      expect(camera.autoCaptureEnabled, isTrue);
    },
  );
}
