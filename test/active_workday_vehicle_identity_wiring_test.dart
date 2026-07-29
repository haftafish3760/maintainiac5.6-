import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('active workday uses the durable context handoff coordinator', () {
    final source = File(
      'lib/screens/dashboard/active_workday_screen.dart',
    ).readAsStringSync();

    expect(source, contains('onChangeContext: _openContextHandoff'));
    expect(source, contains('ActiveWorkdayContextHandoffScope.maybeOf(context)'));
    expect(source, contains('openActiveWorkdayContextHandoffSheet('));
    expect(source, contains('await coordinator.apply('));
    expect(source, contains('workday-handoff-'));
  });

  test(
    'active GPS collection blocks context change until review is complete',
    () {
      final source = File(
        'lib/screens/dashboard/active_workday_screen.dart',
      ).readAsStringSync();

      expect(source, contains('tripTracking?.isTracking == true'));
      expect(
        source,
        contains(
          'Finish and review the active GPS trip before changing vehicles or work profiles.',
        ),
      );
      expect(
        source,
        contains(
          'currentOdometer: session.latestOdometerForContext(activeContext.id)',
        ),
      );
    },
  );
}
