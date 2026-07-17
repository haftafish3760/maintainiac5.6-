import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('end day reviews active GPS trip before ending odometer entry', () {
    final source = File(
      'lib/screens/dashboard/active_workday_screen.dart',
    ).readAsStringSync();

    final endDayCase = source.indexOf('case WorkdayQuickActionKind.endDay:');
    final gpsReview = source.indexOf('_finishAndReviewGpsTrip', endDayCase);
    final endingOdometer = source.indexOf(
      "title: 'Ending Odometer'",
      endDayCase,
    );

    expect(endDayCase, greaterThanOrEqualTo(0));
    expect(gpsReview, greaterThan(endDayCase));
    expect(endingOdometer, greaterThan(gpsReview));
    expect(
      source.substring(endDayCase, endingOdometer),
      contains(
        "missingTripMessage: 'GPS trip could not be reviewed before ending.'",
      ),
    );
  });
}
