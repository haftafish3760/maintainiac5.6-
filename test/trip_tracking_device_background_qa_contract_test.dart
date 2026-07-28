// Two-phone lifecycle QA script contract checks.
//
// Owns safety and bounded-batch assertions for the physical-device helper.
// Does not connect devices, alter app data, or simulate GPS coordinates.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('two-phone lifecycle script is bounded and app-data safe', () {
    final script = File(
      'tool/trip_tracking_device_background_qa.sh',
    ).readAsStringSync();

    expect(script, contains(r'batch_count="${3:-1}"'));
    expect(script, contains(r'stress_scenarios="${4:-0}"'));
    expect(script, contains('./tool/trip_tracking_stress_gate.sh'));
    expect(script, contains(r'PASS_${stress_scenarios}_SCENARIOS'));
    expect(script, contains('batch count must be between 1 and 10'));
    expect(script, contains(r'PROCESS_SURVIVED_HOME_${batch_count}_BATCHES'));
    expect(script, contains('LAUNCHED_MANUAL_BACKGROUND_REQUIRED'));
    expect(script, contains('input keyevent HOME'));
    expect(script, isNot(contains('adb install')));
    expect(script, isNot(contains('adb uninstall')));
    expect(script, isNot(contains('pm clear')));
    expect(script, isNot(contains('location set')));
    expect(
      script,
      isNot(contains(r'adb -s "${android_serial}" shell am force-stop')),
    );
  });
}
