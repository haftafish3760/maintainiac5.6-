import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shared native capability bridges expose Bluetooth safety only', () {
    final android = File(
      'android/app/src/main/kotlin/com/maintainiac/DeviceCapabilityBridge.kt',
    ).readAsStringSync();
    final ios = File(
      'ios/Runner/DeviceCapabilityBridge.swift',
    ).readAsStringSync();

    for (final source in [android, ios]) {
      expect(source, contains('readBluetoothCapabilities'));
      expect(source, contains('supportsApprovedDeviceObservation'));
      expect(source, isNot(contains('connectedDeviceIds')));
      expect(source, isNot(contains('bondedDevices')));
    }
  });
}
