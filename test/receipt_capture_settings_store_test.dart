import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_assistance_policy.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_settings_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
    expect(settings.cameraStartAssisted, isFalse);
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

  test('stores receipt performance mode preference', () async {
    final settings = await ReceiptCaptureSettingsController.create();

    expect(settings.receiptPerformanceMode, ReceiptPerformanceMode.automatic);

    await settings.setReceiptPerformanceMode(
      ReceiptPerformanceMode.maximumPerformance,
    );

    expect(
      settings.receiptPerformanceMode,
      ReceiptPerformanceMode.maximumPerformance,
    );
  });

  test('auto capture preference enables assisted camera mode', () async {
    final settings = await ReceiptCaptureSettingsController.create();

    expect(settings.cameraStartAssisted, isFalse);
    expect(settings.cameraAutoCapture, isFalse);

    await settings.setCameraAutoCapturePreference(true);

    expect(settings.cameraStartAssisted, isTrue);
    expect(settings.cameraAutoCapture, isTrue);

    await settings.setCameraAutoCapturePreference(false);

    expect(settings.cameraStartAssisted, isTrue);
    expect(settings.cameraAutoCapture, isFalse);
  });

  test(
    'exposes effective camera runtime profile from capability and settings',
    () async {
      final settings = await ReceiptCaptureSettingsController.create();

      await settings.setCameraGuidanceEnabled(true);
      await settings.setCameraStartAssisted(true);
      await settings.setCameraAutoCapture(true);
      await settings.setCameraLongReceiptTips(true);
      await settings.setReceiptPerformanceMode(
        ReceiptPerformanceMode.batterySaver,
      );

      final profile = settings.effectiveCameraRuntimeProfile;

      expect(profile.tier, ReceiptCapabilityTier.light);
      expect(profile.liveGuidanceEnabled, isTrue);
      expect(profile.startAssistedEnabled, isFalse);
      expect(profile.autoCaptureEnabled, isFalse);
      expect(profile.longReceiptTipsEnabled, isTrue);
      expect(profile.summaryLabel, contains('Manual capture with guidance'));
      expect(profile.notesLabel, contains('manual capture first'));
    },
  );

  test(
    'receipt scanner settings include capability summary without raw hardware',
    () async {
      final source = await File(
        'lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart',
      ).readAsString();

      expect(source, contains('_ReceiptCameraRuntimeSummary'));
      expect(source, contains('effectiveCameraRuntimeProfile'));
      expect(source, contains('profile.summaryLabel'));
      expect(source, contains('profile.notesLabel'));
      expect(source, contains('Automatic photo capture stays off'));
      expect(source, contains('You stay in control'));
      expect(source, isNot(contains('deviceModel')));
      expect(source, isNot(contains('availableRamLabel')));
      expect(source, isNot(contains('Android SDK')));
    },
  );

  test('resets receipt photo settings to defaults for one area', () async {
    final settings = await ReceiptCaptureSettingsController.create();

    await settings.setAppAssistedExpenses(false);
    await settings.setCameraGuidanceEnabled(false);
    await settings.setCameraStartAssisted(true);
    await settings.setCameraAutoCapture(true);
    await settings.setCameraVoiceCapture(true);
    await settings.setCameraLongReceiptTips(false);
    await settings.setDefaultDataSaverLevel(ReceiptDataSaverLevel.maximum);
    await settings.setReceiptPerformanceMode(
      ReceiptPerformanceMode.maximumPerformance,
    );

    await settings.resetReceiptPhotoDefaultsFor(ReceiptCaptureArea.expenses);

    expect(settings.appAssistedExpenses, isTrue);
    expect(settings.cameraGuidanceEnabled, isTrue);
    expect(settings.cameraStartAssisted, isFalse);
    expect(settings.cameraAutoCapture, isFalse);
    expect(settings.cameraVoiceCapture, isFalse);
    expect(settings.cameraLongReceiptTips, isTrue);
    expect(settings.defaultDataSaverUsesDeviceRecommendation, isTrue);
    expect(settings.receiptPerformanceMode, ReceiptPerformanceMode.automatic);
  });
}
