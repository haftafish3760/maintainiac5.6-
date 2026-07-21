import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String mainSource;

  setUpAll(() {
    mainSource = File('lib/main.dart').readAsStringSync();
  });

  test('main routes trip summaries through shared durable storage only', () {
    expect(
      mainSource,
      isNot(
        contains(
          "import 'screens/dashboard/data/dashboard_firestore_mirror.dart';",
        ),
      ),
    );
    expect(
      mainSource,
      isNot(
        contains(
          "import 'screens/dashboard/data/dashboard_trip_tracking_summary_reporter.dart';",
        ),
      ),
    );
    expect(
      mainSource,
      isNot(contains('DashboardFirestoreMirror? dashboardMirror')),
    );
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
    expect(
      mainSource,
      isNot(contains('DashboardTripTrackingSummaryReporter(')),
    );
  });

  test('main does not hand trip state to direct Firebase identities', () {
    expect(
      mainSource,
      isNot(contains('uid: () => FirebaseAuth.instance.currentUser?.uid')),
    );
  });

  test('trip durable bridge remains wired before application startup', () {
    expect(mainSource, contains('TripTrackingDurableRecordBridge('));
    expect(mainSource, contains('await tripTracking.restore()'));
  });
}
