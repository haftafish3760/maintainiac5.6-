import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_settings_store.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'receipt_capture_settings_store_test_',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  test('stores shared receipt camera preferences', () async {
    final settings = await ReceiptCaptureSettingsController.create();

    expect(settings.cameraSetupComplete, isFalse);
    expect(settings.cameraGuidanceEnabled, isTrue);
    expect(settings.cameraStartAssisted, isTrue);
    expect(settings.cameraAutoCapture, isFalse);
    expect(settings.cameraVoiceCapture, isFalse);
    expect(settings.cameraLongReceiptTips, isTrue);

    await settings.setCameraSetupComplete(true);
    await settings.setCameraGuidanceEnabled(false);
    await settings.setCameraStartAssisted(false);
    await settings.setCameraAutoCapture(true);
    await settings.setCameraVoiceCapture(true);
    await settings.setCameraLongReceiptTips(false);

    expect(settings.cameraSetupComplete, isTrue);
    expect(settings.cameraGuidanceEnabled, isFalse);
    expect(settings.cameraStartAssisted, isFalse);
    expect(settings.cameraAutoCapture, isTrue);
    expect(settings.cameraVoiceCapture, isTrue);
    expect(settings.cameraLongReceiptTips, isFalse);
  });
}
