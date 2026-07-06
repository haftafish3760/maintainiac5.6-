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

    expect(settings.appAssistedReceiptFill, isFalse);
    expect(settings.appAssistedExpenses, isFalse);
    expect(settings.appAssistedMaterials, isFalse);
    expect(settings.appAssistedMaintenance, isFalse);
    expect(
      settings.appAssistedEnabledFor(ReceiptCaptureArea.expenses),
      isFalse,
    );
    expect(
      settings.appAssistedEnabledFor(ReceiptCaptureArea.materialsInventory),
      isFalse,
    );
    expect(
      settings.appAssistedEnabledFor(ReceiptCaptureArea.maintenanceRepair),
      isFalse,
    );
    expect(settings.cameraSetupComplete, isFalse);
    expect(settings.cameraGuidanceEnabled, isTrue);
    expect(settings.cameraStartAssisted, isFalse);
    expect(settings.cameraAutoCapture, isFalse);
    expect(settings.cameraVoiceCapture, isFalse);
    expect(settings.cameraLongReceiptTips, isTrue);
    expect(settings.cameraDiagnosticsImprovementOptIn, isFalse);

    await settings.setCameraSetupComplete(true);
    await settings.setAppAssistedReceiptFill(true);
    await settings.setAppAssistedExpenses(true);
    await settings.setAppAssistedMaterials(true);
    await settings.setAppAssistedMaintenance(true);
    await settings.setCameraGuidanceEnabled(false);
    await settings.setCameraStartAssisted(false);
    await settings.setCameraAutoCapture(true);
    await settings.setCameraVoiceCapture(true);
    await settings.setCameraLongReceiptTips(false);
    await settings.setCameraDiagnosticsImprovementOptIn(true);

    expect(settings.cameraSetupComplete, isTrue);
    expect(settings.appAssistedReceiptFill, isTrue);
    expect(settings.appAssistedExpenses, isTrue);
    expect(settings.appAssistedMaterials, isTrue);
    expect(settings.appAssistedMaintenance, isTrue);
    expect(settings.appAssistedEnabledFor(ReceiptCaptureArea.expenses), isTrue);
    expect(settings.cameraGuidanceEnabled, isFalse);
    expect(settings.cameraStartAssisted, isFalse);
    expect(settings.cameraAutoCapture, isTrue);
    expect(settings.cameraVoiceCapture, isTrue);
    expect(settings.cameraLongReceiptTips, isFalse);
    expect(settings.cameraDiagnosticsImprovementOptIn, isTrue);
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

  test('restores padded receipt performance mode preference', () async {
    final box = await Hive.openBox<dynamic>(
      ReceiptCaptureSettingsController.boxName,
    );
    await box.put('receipt_performance_mode', ' batterySaver ');

    final settings = await ReceiptCaptureSettingsController.create();

    expect(
      settings.receiptPerformanceMode,
      ReceiptPerformanceMode.batterySaver,
    );
    expect(settings.receiptCapabilityTier, ReceiptCapabilityTier.light);
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
      final source = await _readReceiptCaptureSettingsSource();
      final displaySource = await _readReceiptCaptureSettingsDisplaySource();

      expect(source, contains('_ReceiptCameraRuntimeSummary'));
      expect(source, contains('defaultDataSaverLocalOnlyReadinessSummary'));
      expect(source, contains('defaultDataSaverFirstInstallBoundarySummary'));
      expect(source, contains('defaultDataSaverInstallFootprintSummary'));
      expect(source, contains('defaultDataSaverProofTargetSummary'));
      expect(
        source,
        contains('defaultDataSaverCanRunBaseReceiptFlowLocallyNow'),
      );
      expect(source, contains('effectiveCameraRuntimeProfile'));
      expect(source, contains('profile.summaryLabel'));
      expect(source, contains('profile.notesLabel'));
      expect(source, contains('Help Improve Receipt Camera'));
      expect(source, contains('cameraDiagnosticsImprovementOptIn'));
      expect(source, contains('_receiptCaptureDiagnosticsImprovementEnabled'));
      expect(source, contains('_publishReceiptCaptureDiagnostic'));
      expect(
        source,
        contains("'adminDiagnosticOwnerImagePreviewAllowed': false"),
      );
      expect(source, contains('Automatic photo capture stays off'));
      expect(source, contains('You stay in control'));
      expect(source, contains('Receipt images and receipt text stay out'));
      expect(displaySource, isNot(contains('deviceModel')));
      expect(displaySource, isNot(contains('availableRamLabel')));
      expect(displaySource, isNot(contains('Android SDK')));
    },
  );

  test('resets receipt photo settings to defaults for one area', () async {
    final settings = await ReceiptCaptureSettingsController.create();

    await settings.setAppAssistedReceiptFill(true);
    await settings.setAppAssistedExpenses(true);
    await settings.setAppAssistedMaterials(true);
    await settings.setCameraGuidanceEnabled(false);
    await settings.setCameraStartAssisted(true);
    await settings.setCameraAutoCapture(true);
    await settings.setCameraVoiceCapture(true);
    await settings.setCameraLongReceiptTips(false);
    await settings.setCameraDiagnosticsImprovementOptIn(true);
    await settings.setDefaultDataSaverLevel(ReceiptDataSaverLevel.maximum);
    await settings.setReceiptPerformanceMode(
      ReceiptPerformanceMode.maximumPerformance,
    );

    await settings.resetReceiptPhotoDefaultsFor(ReceiptCaptureArea.expenses);

    expect(settings.appAssistedReceiptFill, isTrue);
    expect(settings.appAssistedExpenses, isFalse);
    expect(settings.appAssistedMaterials, isTrue);
    expect(
      settings.appAssistedEnabledFor(ReceiptCaptureArea.expenses),
      isFalse,
    );
    expect(
      settings.appAssistedEnabledFor(ReceiptCaptureArea.materialsInventory),
      isTrue,
    );
    expect(settings.cameraGuidanceEnabled, isTrue);
    expect(settings.cameraStartAssisted, isFalse);
    expect(settings.cameraAutoCapture, isFalse);
    expect(settings.cameraVoiceCapture, isFalse);
    expect(settings.cameraLongReceiptTips, isTrue);
    expect(settings.cameraDiagnosticsImprovementOptIn, isFalse);
    expect(settings.defaultDataSaverUsesDeviceRecommendation, isTrue);
    expect(settings.receiptPerformanceMode, ReceiptPerformanceMode.automatic);
  });
}

Future<String> _readReceiptCaptureSettingsSource() async {
  final paths = [
    ..._receiptCaptureSettingsDisplayPaths,
    'lib/shared/widgets/receipt_capture/receipt_capture_diagnostics_policy.dart',
  ];
  final contents = <String>[];
  for (final path in paths) {
    contents.add(await File(path).readAsString());
  }
  return contents.join('\n');
}

Future<String> _readReceiptCaptureSettingsDisplaySource() async {
  final contents = <String>[];
  for (final path in _receiptCaptureSettingsDisplayPaths) {
    contents.add(await File(path).readAsString());
  }
  return contents.join('\n');
}

const _receiptCaptureSettingsDisplayPaths = [
  'lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart',
  'lib/shared/widgets/receipt_capture/receipt_capture_runtime_settings.dart',
  'lib/shared/widgets/receipt_capture/receipt_expense_review_default_picker.dart',
  'lib/shared/widgets/receipt_capture/receipt_capture_review_storage_settings.dart',
  'lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart',
  'lib/shared/widgets/receipt_capture/receipt_attachment_camera_actions.dart',
  'lib/shared/widgets/receipt_capture/receipt_attachment_review_read_actions.dart',
];
