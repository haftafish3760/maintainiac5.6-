import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'production trip tracking hands reviewed records to durable storage',
    () {
      final mainSource = File('lib/main.dart').readAsStringSync();
      final controllerSource = File(
        'lib/shared/trip_tracking/trip_tracking_controller.dart',
      ).readAsStringSync();

      expect(mainSource, contains('TripTrackingDurableRecordBridge'));
      expect(mainSource, contains('TripTrackingTripLogProposalStore.create()'));
      expect(
        mainSource,
        contains('TripTrackingTripLogProposalStore.unavailable()'),
      );
      expect(mainSource, contains('tripLogProposalSink: tripLogProposalStore'));
      expect(
        mainSource,
        contains('tripTracking.retryPendingTripLogProposals()'),
      );
      expect(mainSource, contains('TripTrackingRoutePointStore.create()'));
      expect(mainSource, contains('TripTrackingRoutePointStore.unavailable()'));
      expect(mainSource, contains('routePointStore: routePointStore'));
      expect(
        mainSource,
        contains('routeSettings: () => tripTrackingSettings.settings'),
      );
      expect(mainSource, contains('localRouteDayKey: tripTrackingLocalDayKey'));
      expect(mainSource, contains('tripTracking.applyGpsAssistanceConsent('));
      expect(mainSource, contains('tripTracking.applyActiveTrackingSettings('));
      expect(mainSource, isNot(contains('TripTrackingFirebaseMirror')));
      expect(mainSource, isNot(contains('cloudMirror:')));
      expect(
        controllerSource,
        contains("import 'trip_tracking_backup_port.dart';"),
      );
      expect(
        controllerSource,
        isNot(contains("import 'trip_tracking_firebase_bridge.dart';")),
      );
      expect(controllerSource, isNot(contains('package:firebase_')));
    },
  );
}
