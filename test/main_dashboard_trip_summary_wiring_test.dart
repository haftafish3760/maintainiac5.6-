import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String mainSource;

  setUpAll(() {
    mainSource = File('lib/main.dart').readAsStringSync();
  });

  test('main wires dashboard trip summaries through the dashboard mirror', () {
    expect(
      mainSource,
      contains(
        "import 'screens/dashboard/data/dashboard_firestore_mirror.dart';",
      ),
    );
    expect(
      mainSource,
      contains(
        "import 'screens/dashboard/data/dashboard_trip_tracking_summary_reporter.dart';",
      ),
    );
    expect(mainSource, contains('DashboardFirestoreMirror? dashboardMirror'));
    expect(
      mainSource,
      contains(
        "MaintainiacDurableRecordStore.create(\n    'maintainiac_durable_records',",
      ),
    );
    expect(
      mainSource,
      contains('durableRecordBridge: TripTrackingDurableRecordBridge('),
    );
    expect(mainSource, contains('DashboardTripTrackingSummaryReporter('));
    expect(mainSource, contains('dashboardId: () => \'active_dashboard\''));
    expect(mainSource, contains('tripTracking: tripTracking'));
    expect(mainSource, contains('activeWorkday: activeWorkday'));
    expect(
      mainSource,
      contains(
        'deviceCapabilityProfile: () => DeviceCapabilityService.instance.profile()',
      ),
    );
  });

  test('dashboard trip summaries use reference-only scoped identifiers', () {
    expect(
      mainSource,
      contains('uid: () => FirebaseAuth.instance.currentUser?.uid'),
    );
    expect(
      mainSource,
      contains('orgId: () => operationalContext.context.companyId'),
    );
    expect(
      mainSource,
      contains(
        'activeVehicleId: () => operationalContext.context.activeVehicleId',
      ),
    );
    expect(
      mainSource,
      contains('activeWorkdayId: () => activeWorkday.activeSession?.id'),
    );
    expect(
      mainSource,
      contains(
        'activeWorkProfileId: () => operationalContext.context.workProfileId',
      ),
    );
  });

  test('dashboard trip summaries are refreshed from live trip and dashboard state', () {
    expect(mainSource, contains('unawaited(queueDashboardTripSummary())'));
    expect(
      mainSource,
      contains(
        'tripTracking.addListener(() {\n      unawaited(queueDashboardTripSummary());',
      ),
    );
    expect(
      mainSource,
      contains(
        'globalOdometer.addListener(() {\n      unawaited(queueDashboardTripSummary());',
      ),
    );
    expect(
      mainSource,
      contains(
        'tripTrackingSettings.addListener(() {\n      unawaited(queueDashboardTripSummary());',
      ),
    );
    expect(
      mainSource,
      contains(
        'activeWorkday.addListener(() {\n      unawaited(queueDashboardTripSummary());',
      ),
    );
    expect(
      mainSource,
      contains(
        'operationalContext.addListener(() {\n      unawaited(queueDashboardTripSummary());',
      ),
    );
  });

  test(
    'dashboard trip summaries use mileage storage guard not receipt storage',
    () {
      expect(
        mainSource,
        contains("import 'shared/storage/app_storage_guard.dart';"),
      );
      expect(
        mainSource,
        contains('AppStorageGuard.check(AppStoragePurpose.mileageTracking)'),
      );
      expect(
        mainSource.substring(
          mainSource.indexOf('DashboardTripTrackingSummaryReporter('),
          mainSource.indexOf('SystemChrome.setEnabledSystemUIMode'),
        ),
        isNot(contains('receipt')),
      );
    },
  );
}
