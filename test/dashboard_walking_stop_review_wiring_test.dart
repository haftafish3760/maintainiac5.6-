import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dashboard exposes an explicit walking-stop review flow', () {
    final source = File(
      'lib/screens/dashboard/active_workday_screen.dart',
    ).readAsStringSync();

    expect(source, contains('onReviewWalkingStop: _reviewWalkingStop'));
    expect(source, contains("child: const Text('REVIEW POSSIBLE STOP')"));
    expect(source, contains("child: const Text('Not a Stop')"));
    expect(source, contains("child: const Text('Add Stop')"));
    expect(source, contains('TripTrackingAdvisoryDisposition.dismissed'));
    expect(
      source,
      contains("await _openStopDialog('Stop', ActiveWorkdayEventType.stop)"),
    );
    expect(source, contains("'not end GPS tracking or change your mileage.'"));
  });
}
