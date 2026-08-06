// Regression coverage for the debug-only, privacy-safe field-test monitor.
//
// Owns source contracts for redacted Android diagnostic log output and its
// read-only monitor script. It does not connect to a device or start tracking.
// Consumed by the trip-tracking QA gate before a controlled road test.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'debug field monitor keeps location diagnostics redacted and read-only',
    () {
      final bridge = File(
        'android/app/src/main/kotlin/com/maintainiac/TripTrackingNativeBridge.kt',
      ).readAsStringSync();
      final script = File(
        'tool/trip_tracking_live_device_monitor.sh',
      ).readAsStringSync();
      final start = bridge.indexOf('private fun safeDiagnosticEvent');
      final end = bridge.indexOf(
        '\n    private fun safeDiagnosticToken',
        start,
      );
      final diagnosticFunction = bridge.substring(start, end);

      expect(
        bridge,
        contains('private const val tripTrackingDiagnosticLogTag'),
      );
      expect(bridge, contains('private var debugDiagnosticsEnabled = false'));
      expect(bridge, contains('ApplicationInfo.FLAG_DEBUGGABLE'));
      expect(bridge, contains('if (debugDiagnosticsEnabled)'));
      expect(bridge, contains('Log.i(tripTrackingDiagnosticLogTag'));
      expect(diagnosticFunction, isNot(contains('latitude')));
      expect(diagnosticFunction, isNot(contains('longitude')));
      expect(diagnosticFunction, isNot(contains('recordedAt')));
      expect(diagnosticFunction, isNot(contains('errorMessage')));
      expect(script, contains('MaintainiacTripDiag:I'));
      expect(script, isNot(contains('logcat -c')));
      expect(script, isNot(contains('pm grant')));
    },
  );
}
