import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_assistance_policy.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  test('camera storage bands honor exact commercial thresholds', () {
    expect(_policy(1024).band, ReceiptCameraStorageBand.green);
    expect(_policy(1023).band, ReceiptCameraStorageBand.yellow);
    expect(_policy(500).band, ReceiptCameraStorageBand.yellow);
    expect(_policy(499).band, ReceiptCameraStorageBand.orange);
    expect(_policy(251).band, ReceiptCameraStorageBand.orange);
    expect(_policy(250).band, ReceiptCameraStorageBand.red);
    expect(_policy(0).band, ReceiptCameraStorageBand.red);
    expect(_policy(null).band, ReceiptCameraStorageBand.unknown);
  });

  test('storage pressure never blocks receipt task completion', () {
    for (final freeMb in [null, 2048, 1024, 700, 499, 250, 249, 0, -1]) {
      final policy = _policy(freeMb);
      expect(policy.captureCompletionAllowed, isTrue, reason: '$freeMb MB');
      expect(policy.completionPolicyCode, isNot(contains('blocked')));
    }
    expect(_policy(249).isBelowSupportedFloor, isTrue);
    expect(_policy(250).isBelowSupportedFloor, isFalse);
  });

  test('cloud relief is suggested only for orange and red pressure', () {
    expect(_policy(1024).cloudReliefRecommended, isFalse);
    expect(_policy(500).cloudReliefRecommended, isFalse);
    expect(_policy(499).cloudReliefRecommended, isTrue);
    expect(_policy(250).cloudReliefRecommended, isTrue);
  });

  test('hardware storage classes use the same threshold boundaries', () {
    expect(_hardware(1024).storageClass, ReceiptDeviceStorageClass.roomy);
    expect(_hardware(500).storageClass, ReceiptDeviceStorageClass.comfortable);
    expect(_hardware(499).storageClass, ReceiptDeviceStorageClass.low);
    expect(_hardware(251).storageClass, ReceiptDeviceStorageClass.low);
    expect(_hardware(250).storageClass, ReceiptDeviceStorageClass.critical);
    expect(_hardware(0).storageClass, ReceiptDeviceStorageClass.critical);
    expect(_hardware(null).storageClass, ReceiptDeviceStorageClass.unknown);
  });

  test('hardware capability carries storage policy into camera session', () {
    final capability = ReceiptDeviceCapability.fromHardware(
      hardware: const ReceiptHardwareProfile(
        availableRamMb: 4096,
        cpuCores: 4,
        freeStorageMb: 249,
      ),
    );

    expect(capability.cameraStoragePolicy.band, ReceiptCameraStorageBand.red);
    expect(capability.cameraStoragePolicy.isBelowSupportedFloor, isTrue);
    expect(capability.cameraStoragePolicy.captureCompletionAllowed, isTrue);
  });

  test('orange storage uses strong saving while red uses maximum saving', () {
    final orange = ReceiptDeviceCapability.fromHardware(
      hardware: const ReceiptHardwareProfile(freeStorageMb: 320),
    );
    final red = ReceiptDeviceCapability.fromHardware(
      hardware: const ReceiptHardwareProfile(freeStorageMb: 250),
    );

    expect(orange.recommendedDataSaverLevel, ReceiptDataSaverLevel.strong);
    expect(red.recommendedDataSaverLevel, ReceiptDataSaverLevel.maximum);
    expect(orange.cameraStoragePolicy.captureCompletionAllowed, isTrue);
    expect(red.cameraStoragePolicy.captureCompletionAllowed, isTrue);
  });
}

ReceiptCameraStoragePolicy _policy(int? freeMb) =>
    ReceiptCameraStoragePolicy.forFreeStorageMb(freeMb);

ReceiptHardwareProfile _hardware(int? freeMb) =>
    ReceiptHardwareProfile(freeStorageMb: freeMb);
