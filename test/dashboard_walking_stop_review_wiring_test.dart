import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dashboard exposes an explicit walking-stop review flow', () {
    final source = File(
      'lib/screens/dashboard/active_workday_screen.dart',
    ).readAsStringSync();

    expect(source, contains('case WorkdayQuickActionKind.reviewStops:'));
    expect(source, contains('await _reviewWalkingStop();'));
    expect(source, contains("'REVIEW POSSIBLE STOP'"));
    expect(source, contains('controller?.pendingStopReviewCount'));
    expect(source, contains('latestPendingStopBoundaryCandidate'));
    expect(source, contains("'Possible Stop at \$candidateTime'"));
    expect(source, contains("'High-confidence motion evidence.'"));
    expect(source, contains("'Motion confidence is unavailable.'"));
    expect(source, contains('bool confirmGpsStopCandidate = false'));
    expect(source, contains('confirmGpsStopCandidate: true'));
    expect(source, contains('if (confirmGpsStopCandidate)'));
    expect(
      source,
      contains("'REVIEW POSSIBLE STOPS (\$pendingStopReviewCount)'"),
    );
    expect(source, contains("child: const Text('Not a Stop')"));
    expect(source, contains("child: const Text('Add Stop')"));
    expect(source, contains('TripTrackingAdvisoryDisposition.dismissed'));
    expect(
      source,
      contains("await _openStopDialog('Stop', ActiveWorkdayEventType.stop)"),
    );
    expect(source, contains('tripTracking!.recordUserTripEvent('));
    expect(source, contains("commandId: 'workday.\${newWorkdayEvent.id}'"));
    expect(source, contains("initiatingSource: 'dashboard'"));
    expect(source, contains('TripManualEventType.pickup'));
    expect(source, contains('TripManualEventType.dropoff'));
    expect(source, contains("'not end GPS tracking or change your mileage.'"));
  });
}
