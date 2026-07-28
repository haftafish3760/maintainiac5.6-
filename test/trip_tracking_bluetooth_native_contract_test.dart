import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'native bridges report Bluetooth capability without device identity',
    () {
      final android = File(
        'android/app/src/main/kotlin/com/maintainiac/DeviceCapabilityBridge.kt',
      ).readAsStringSync();
      final ios = File(
        'ios/Runner/DeviceCapabilityBridge.swift',
      ).readAsStringSync();
      final activity = File(
        'android/app/src/main/kotlin/com/maintainiac/MainActivity.kt',
      ).readAsStringSync();

      for (final source in [android, ios]) {
        expect(source, contains('readBluetoothCapabilities'));
        expect(source, contains('supportsApprovedDeviceObservation'));
        expect(source, isNot(contains('connectedDeviceIds')));
        expect(source, isNot(contains('bondedDevices')));
      }
      expect(android, contains('requestBluetoothConnectionAccess'));
      expect(android, contains('bluetoothPermissionRequestCode'));
      expect(
        activity,
        contains('deviceCapabilityBridge.onRequestPermissionsResult'),
      );
    },
  );

  test('Android publishes privacy-safe Bluetooth connection observations', () {
    final events = File(
      'android/app/src/main/kotlin/com/maintainiac/DeviceCapabilityEvents.kt',
    ).readAsStringSync();
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final service = File(
      'lib/shared/device_capabilities/device_capability_service.dart',
    ).readAsStringSync();

    expect(manifest, contains('android.permission.BLUETOOTH_CONNECT'));
    expect(events, contains('BluetoothDevice.ACTION_ACL_CONNECTED'));
    expect(events, contains('BluetoothDevice.ACTION_ACL_DISCONNECTED'));
    expect(events, contains('"opaqueDeviceId"'));
    expect(events, contains('MessageDigest.getInstance("SHA-256")'));
    expect(events, isNot(contains('"deviceName"')));
    expect(events, isNot(contains('"deviceAddress"')));
    expect(service, contains('DeviceBluetoothConnectionProbe'));
    expect(service, contains('approvedConnectionChanges'));
    expect(service, contains('requestBluetoothConnectionAccess'));
    expect(service, contains("event['reason'] != 'bluetoothConnection'"));
  });
}
