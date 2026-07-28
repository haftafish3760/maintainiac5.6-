// Production Bluetooth trip-bootstrap source-contract tests.
//
// Owns regression evidence that the app entry point constructs the existing
// binding and that the root lifecycle starts, retries, and disposes it. It does
// not emulate Bluetooth hardware or assert GPS field accuracy. The complete
// trip gate consumes this contract alongside behavioral binding tests.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production entry point injects the Bluetooth trip binding', () {
    final source = File('lib/main.dart').readAsStringSync();

    expect(source, contains('TripTrackingBluetoothVehicleLinkStore.create()'));
    expect(source, contains('TripTrackingBluetoothCoordinator('));
    expect(source, contains('TripTrackingBluetoothBinding('));
    expect(source, contains('probe: DeviceCapabilityService.instance'));
    expect(source, contains('bluetoothTripBinding:'));
  });

  test('root lifecycle starts retries and disposes the binding', () {
    final source = File('lib/app/maintaniac_app.dart').readAsStringSync();

    expect(
      RegExp(r'bluetoothTripBinding\?\.start\(\)').allMatches(source).length,
      2,
    );
    expect(source, contains('bluetoothTripBinding?.dispose()'));
    expect(source, contains('state == AppLifecycleState.resumed'));
    final dependencyStart = source.indexOf('void didChangeDependencies()');
    final disposeStart = source.indexOf('void dispose()');
    expect(
      source.substring(dependencyStart, disposeStart),
      isNot(contains('bluetoothTripBinding?.dispose()')),
    );
    expect(
      source.substring(disposeStart),
      contains('bluetoothTripBinding?.dispose()'),
    );
  });
}
