import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_documents.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_upload_queue.dart';

void main() {
  test(
    'dashboard upload policy rejects raw location and module data aliases',
    () {
      final doc =
          MaintainiacFirestoreDocumentBuilder.dashboardCommandCenterDocument(
            uid: 'firebaseUid-1',
            dashboardId: 'today',
            updatedAtUtc: DateTime.utc(2026, 7, 16, 12),
          );

      for (final forbidden in const [
        'latitude',
        'longitude',
        'coordinates',
        'route',
        'mapboxRoute',
        'mapboxGeometry',
        'mapboxPolyline',
        'mapMatching',
        'optimizationRoute',
        'directionsRoute',
        'routePoints',
        'routeSummary',
        'polyline',
        'geometry',
        'geometries',
        'waypoints',
        'legs',
        'maneuvers',
        'navigationRoute',
        'directions',
        'matrix',
        'durations',
        'distances',
        'isochrone',
        'contours',
        'optimization',
        'optimizedWaypoints',
        'mapMatchedTrace',
        'tracepoints',
        'evChargeFinder',
        'chargingStations',
        'stationCoordinates',
        'address',
        'rawSamples',
        'walkingEvidence',
        'rawModuleRecord',
      ]) {
        final poisoned = MaintainiacFirestoreDocumentDraft(
          path: doc.path,
          data: {...doc.data, forbidden: 'not allowed'},
        );

        expect(
          () => MaintainiacFirestoreUploadPolicy.validateDraft(poisoned),
          throwsArgumentError,
          reason: '$forbidden must not be accepted in dashboard summaries',
        );
      }
    },
  );

  test(
    'Firestore rules contain dashboard summary ownership and privacy gates',
    () {
      final rules = File('firestore.rules').readAsStringSync();

      expect(rules, contains('match /dashboardSummaries/{dashboardId}'));
      expect(rules, contains('function isDashboardCommandCenterSummary'));
      expect(rules, contains('hasOnlyDashboardSummaryFields'));
      expect(rules, contains('hasValidDashboardSyncCounters'));
      expect(rules, contains('function isAllowedDashboardMode'));
      expect(rules, contains('function isAllowedDashboardSyncMode'));
      expect(rules, contains('function isAllowedGpsAssistState'));
      expect(rules, contains('function isAllowedOdometerUsageState'));
      expect(rules, contains('function hasValidDashboardSummaryStrings'));
      expect(
        rules,
        contains('request.resource.data.dashboardId.size() <= 128'),
      );
      expect(
        rules,
        contains('request.resource.data.activeVehicleId.size() <= 128'),
      );
      for (final field in const <String>[
        'dashboardId',
        'createdByUid',
        'updatedByUid',
        'updatedAt',
      ]) {
        expect(rules, contains('request.resource.data.$field.size() > 0'));
      }
      for (final field in const <String>[
        'orgId',
        'activeVehicleId',
        'activeWorkdayId',
        'activeWorkProfileId',
      ]) {
        expect(rules, contains('request.resource.data.$field is string'));
        expect(rules, contains('request.resource.data.$field.size() > 0'));
      }
      expect(rules, contains('request.resource.data.freeSyncsRemaining <= 6'));
      expect(rules, contains('request.resource.data.syncsUsedInWindow <= 999'));
      expect(rules, contains('6 - request.resource.data.syncsUsedInWindow'));
      expect(rules, contains('request.resource.data.stopSignal'));
      expect(rules, contains('request.resource.data.stopActionToken'));
      expect(rules, contains('request.resource.data.stopClassificationReason'));
      expect(
        rules,
        contains('request.resource.data.odometerCalibrationMultiplier <= 1.25'),
      );
      expect(
        rules,
        contains('request.resource.data.locationDataIncluded == false'),
      );
      for (final forbiddenRouteField in const [
        'mapboxRoute',
        'mapboxGeometry',
        'mapboxPolyline',
        'mapMatching',
        'optimizationRoute',
        'directionsRoute',
        'geometry',
        'waypoints',
        'navigationRoute',
        'directions',
        'matrix',
        'isochrone',
        'optimization',
        'mapMatchedTrace',
        'evChargeFinder',
        'chargingStations',
      ]) {
        expect(rules, contains("'$forbiddenRouteField'"));
      }
      expect(
        rules,
        contains('request.resource.data.rawModuleDataIncluded == false'),
      );
      expect(rules, contains('request.resource.data.createdByUid == uid'));
      expect(
        rules,
        contains('request.resource.data.createdByUid == request.auth.uid'),
      );
      expect(rules, contains('allow delete: if false;'));
    },
  );
}
