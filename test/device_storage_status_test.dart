import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/device_capabilities/device_storage_status.dart';

void main() {
  test('storage thresholds use the shared four-color warning contract', () {
    expect(status(null), DeviceStorageStatus.unknown);
    expect(status(2048), DeviceStorageStatus.green);
    expect(status(1024), DeviceStorageStatus.green);
    expect(status(1023), DeviceStorageStatus.yellow);
    expect(status(500), DeviceStorageStatus.yellow);
    expect(status(499), DeviceStorageStatus.orange);
    expect(status(251), DeviceStorageStatus.orange);
    expect(status(250), DeviceStorageStatus.red);
    expect(status(0), DeviceStorageStatus.red);
  });

  test('storage pressure warns but never blocks an app action', () {
    final red = DeviceStorageAssessment.fromFreeMb(100);

    expect(red.shouldWarn, isTrue);
    expect(red.blocksUserAction, isFalse);
    expect(red.userMessage, contains('critically low'));
  });
}

DeviceStorageStatus status(int? freeStorageMb) =>
    DeviceStorageAssessment.fromFreeMb(freeStorageMb).status;
