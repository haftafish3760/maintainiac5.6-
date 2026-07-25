import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/device_capabilities/device_bluetooth_capabilities.dart';

void main() {
  test('parses a privacy-safe native Bluetooth connection event', () {
    final observation = DeviceBluetoothConnectionObservation.tryParseNative({
      'reason': 'bluetoothConnection',
      'opaqueDeviceId': '  app-local-hash  ',
      'connected': true,
      'atMs': 1784894400123,
    });

    expect(observation, isNotNull);
    expect(observation!.opaqueDeviceId, 'app-local-hash');
    expect(observation.connected, isTrue);
    expect(observation.observedAtUtc.isUtc, isTrue);
    expect(
      observation.observedAtUtc.millisecondsSinceEpoch,
      1784894400123,
    );
  });

  test('ignores unrelated capability events', () {
    expect(
      DeviceBluetoothConnectionObservation.tryParseNative({
        'reason': 'battery',
        'atMs': 1784894400123,
      }),
      isNull,
    );
  });

  test('rejects malformed Bluetooth connection events', () {
    final malformed = <Object?>[
      null,
      'bluetoothConnection',
      {'reason': 'bluetoothConnection'},
      {
        'reason': 'bluetoothConnection',
        'opaqueDeviceId': ' ',
        'connected': true,
        'atMs': 1784894400123,
      },
      {
        'reason': 'bluetoothConnection',
        'opaqueDeviceId': 'hash',
        'connected': 'yes',
        'atMs': 1784894400123,
      },
      {
        'reason': 'bluetoothConnection',
        'opaqueDeviceId': 'hash',
        'connected': true,
        'atMs': double.nan,
      },
      {
        'reason': 'bluetoothConnection',
        'opaqueDeviceId': 'hash',
        'connected': true,
        'atMs': 0,
      },
    ];

    for (final event in malformed) {
      expect(
        DeviceBluetoothConnectionObservation.tryParseNative(event),
        isNull,
        reason: '$event',
      );
    }
  });
}
