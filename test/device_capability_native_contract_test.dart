import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android and iOS expose the complete shared capability channel', () {
    final android = File(
      'android/app/src/main/kotlin/com/maintainiac/DeviceCapabilityBridge.kt',
    ).readAsStringSync();
    final ios = File(
      'ios/Runner/DeviceCapabilityBridge.swift',
    ).readAsStringSync();

    for (final source in [android, ios]) {
      expect(source, contains('maintainiac/device_capabilities'));
      expect(source, contains('readRuntimeCapabilities'));
      expect(source, contains('readCameraCapabilities'));
      expect(source, contains('readExtendedCapabilities'));
      expect(source, contains('readDynamicCapabilities'));
      expect(source, contains('readCameraLenses'));
      expect(source, contains('readSensors'));
      expect(source, contains('readBattery'));
      expect(source, contains('readDisplay'));
      expect(source, contains('readMedia'));
      expect(source, contains('readGraphics'));
      expect(source, contains('readConnectivity'));
      expect(source, contains('powerSaving'));
      expect(source, contains('thermalState'));
      expect(source, isNot(contains('SSID')));
      expect(source, isNot(contains('BSSID')));
      expect(source, isNot(contains('uniqueID')));
    }
    expect(android, contains('mediaPerformanceClass'));
    expect(android, contains('sharedDevicePerformance'));
    expect(android, contains('performanceInstance'));
    expect(android, contains('availableRamMb'));
    expect(ios, contains('isLowPowerModeEnabled'));
    expect(ios, contains('ProcessInfo.ThermalState'));
  });

  test('native bridges stay below the 500 line source limit', () {
    for (final path in [
      'android/app/src/main/kotlin/com/maintainiac/DeviceCapabilityBridge.kt',
      'ios/Runner/DeviceCapabilityBridge.swift',
      'android/app/src/main/kotlin/com/maintainiac/DeviceCapabilityEvents.kt',
      'ios/Runner/DeviceCapabilityEvents.swift',
    ]) {
      expect(File(path).readAsLinesSync().length, lessThan(500));
    }
  });

  test('Android and iOS publish live capability-change events', () {
    final android = File(
      'android/app/src/main/kotlin/com/maintainiac/DeviceCapabilityEvents.kt',
    ).readAsStringSync();
    final ios = File(
      'ios/Runner/DeviceCapabilityEvents.swift',
    ).readAsStringSync();

    for (final source in [android, ios]) {
      expect(source, contains('maintainiac/device_capability_events'));
      expect(source, contains('battery'));
      expect(source, contains('power'));
      expect(source, contains('thermal'));
      expect(source, contains('network'));
    }
  });
}
