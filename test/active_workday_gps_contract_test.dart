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

  test('end day reuses a trip-confirmed odometer without a second sheet', () {
    final source = File(
      'lib/screens/dashboard/active_workday_screen.dart',
    ).readAsStringSync();

    expect(source, contains('Future<int?> _finishAndReviewGpsTrip('));
    expect(source, contains('confirmedTripEndingOdometer = await'));
    expect(source, contains('odometerReading: confirmedTripEndingOdometer'));
    expect(source, contains('if (tripTracking.isTracking) return;'));
    expect(
      source,
      contains('return reviewConfirmed ? confirmedEndingOdometer : null;'),
    );
  });

  test('live dashboard labels GPS as assistance, not odometer truth', () {
    final source = File(
      'lib/screens/dashboard/active_workday_screen.dart',
    ).readAsStringSync();

    expect(source, contains('your odometer stays official'));
    expect(source, contains('controller!.acceptedMiles.toStringAsFixed(2)'));
    expect(source, contains(r'Location estimate: ${display.displayValue}'));
    expect(
      source,
      contains(r'Last confirmed: ${display.confirmedDisplayValue}'),
    );
    expect(source, isNot(contains('odometer is live')));
  });

  test('active dashboard keeps a stale GPS stream visible for review', () {
    final source = File(
      'lib/screens/dashboard/active_workday_screen.dart',
    ).readAsStringSync();

    final liveOdometer = source.indexOf('const _LiveOdometerPanelLine()');
    final liveWarning = source.indexOf(
      'TripTrackingDashboardLiveStatusPolicy.warning(',
    );

    expect(liveOdometer, greaterThanOrEqualTo(0));
    expect(liveWarning, greaterThan(liveOdometer));
    expect(source, contains('if (showLiveTrackingWarning)'));
    expect(
      source,
      contains('awaitingInitialFix: controller?.awaitingInitialFix'),
    );
  });

  test('field summary can be copied without route coordinates', () {
    final source = File(
      'lib/screens/dashboard/active_workday_screen.dart',
    ).readAsStringSync();

    expect(source, contains('Clipboard.setData'));
    expect(source, contains("child: const Text('Copy Summary')"));
    expect(source, contains('copied without route coordinates'));
    expect(source, contains('final summaryText = summary.toPlainText()'));
    expect(source, contains('content: SingleChildScrollView('));
  });

  test(
    'Android background permission handoff is explicit and preserves cleanup',
    () {
      final source = File(
        'lib/screens/dashboard/active_workday_screen.dart',
      ).readAsStringSync();
      final start = source.indexOf('Future<void> _startGpsTripImpl() async');
      final status = source.indexOf(
        "'background_location_settings_required'",
        start,
      );
      final discard = source.indexOf('tripTracking.discardEmptyTrip()', status);
      final prompt = source.indexOf(
        'showTripBackgroundLocationSettingsPrompt(',
        status,
      );
      final userChoice = source.indexOf('if (openSettings)', prompt);
      final openSettings = source.indexOf(
        'tripTracking.openBackgroundLocationSettings()',
        userChoice,
      );

      expect(status, greaterThan(start));
      expect(
        source.substring(start, status),
        contains('defaultTargetPlatform == TargetPlatform.android'),
      );
      expect(discard, greaterThan(status));
      expect(prompt, greaterThan(discard));
      expect(userChoice, greaterThan(prompt));
      expect(openSettings, greaterThan(userChoice));
    },
  );
}
