import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dashboard cancellation is explicit and preserves trip evidence', () {
    final source = File(
      'lib/screens/dashboard/active_workday_screen.dart',
    ).readAsStringSync();

    expect(source, contains("'Stop Location Tracking?'"));
    expect(source, contains("child: const Text('Keep Tracking')"));
    expect(source, contains("child: const Text('Stop Location Tracking')"));
    expect(source, contains('cancelActiveTrip(userConfirmed: true)'));
    expect(source, contains('will stay available for review'));
    expect(source, contains('Your workday and odometer'));
    expect(source, contains('will not change.'));
    expect(source, isNot(contains('deleteActiveTrip')));
  });

  test('cancel is serialized against the active start operation', () {
    final source = File(
      'lib/screens/dashboard/active_workday_screen.dart',
    ).readAsStringSync();

    expect(
      source,
      contains('if (_gpsCancelInFlight || _gpsStartInFlight) return;'),
    );
    expect(source, contains('onStop: _cancelGpsTrip'));
  });
}
