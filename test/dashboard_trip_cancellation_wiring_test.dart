import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dashboard cancellation is explicit and preserves trip evidence', () {
    final source = File(
      'lib/screens/dashboard/active_workday_screen.dart',
    ).readAsStringSync();

    expect(
      source,
      contains("title: const Text(\n          'Cancel GPS Trip?'"),
    );
    expect(source, contains("child: const Text('Keep Tracking')"));
    expect(source, contains("child: const Text('Cancel GPS Trip')"));
    expect(source, contains('cancelActiveTrip(userConfirmed: true)'));
    expect(source, contains('preserved as a cancelled trip for'));
    expect(source, contains('Your workday and odometer will not be changed.'));
    expect(source, isNot(contains('deleteActiveTrip')));
  });

  test('cancel is serialized against start and stop operations', () {
    final source = File(
      'lib/screens/dashboard/active_workday_screen.dart',
    ).readAsStringSync();

    expect(
      source,
      contains(
        'if (_gpsCancelInFlight || _gpsStopInFlight || _gpsStartInFlight) return;',
      ),
    );
    expect(source, contains('startInFlight || stopInFlight || cancelInFlight'));
  });
}
