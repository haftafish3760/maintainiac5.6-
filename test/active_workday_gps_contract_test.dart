import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'starting GPS refreshes the shared runtime capability profile first',
    () {
      final source = File(
        'lib/screens/dashboard/active_workday_screen.dart',
      ).readAsStringSync();

      final start = source.indexOf('Future<void> _startGpsTripImpl() async');
      final refresh = source.indexOf(
        'DeviceCapabilityScope.refreshForHeavyWork(context)',
        start,
      );
      final gpsEnabledCheck = source.indexOf(
        'if (!settings.gpsAssistedTrackingEnabled)',
        start,
      );
      final nativeStart = source.indexOf(
        'tripTracking.startNativeTracking(',
        start,
      );

      expect(start, greaterThanOrEqualTo(0));
      expect(gpsEnabledCheck, greaterThan(start));
      expect(refresh, greaterThan(gpsEnabledCheck));
      expect(refresh, greaterThan(start));
      expect(nativeStart, greaterThan(refresh));
    },
  );

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

  test('active dashboard keeps a stale GPS stream visible for review', () {
    final source = File(
      'lib/screens/dashboard/active_workday_screen.dart',
    ).readAsStringSync();

    final liveOdometer = source.indexOf('const _LiveOdometerPanelLine()');
    final staleStatus = source.indexOf(
      "controller?.platformStatus == 'gps_signal_stale'",
    );
    final staleGuidance = source.indexOf(
      'GPS has not produced a location fix recently.',
    );

    expect(liveOdometer, greaterThanOrEqualTo(0));
    expect(staleStatus, greaterThan(liveOdometer));
    expect(staleGuidance, greaterThan(staleStatus));
  });
}
