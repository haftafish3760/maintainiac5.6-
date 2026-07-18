import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/odometer/live_odometer_display.dart';
import 'package:maintaniac/shared/trip_tracking/trip_live_odometer_render_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_live_odometer_ui_validation.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_live_odometer_broadcast.dart';

void main() {
  final now = DateTime.utc(2026, 7, 18, 18);

  LiveOdometerDisplaySnapshot liveSnapshot() => LiveOdometerDisplaySnapshot(
    confirmedReading: 1200,
    displayReading: 1203,
    isLive: true,
    liveUpdatedAt: now.subtract(const Duration(seconds: 15)),
    projectionRevision: 3,
  );

  Map<String, Object?> safeBroadcastMap() =>
      TripTrackingLiveOdometerBroadcast.fromSnapshot(
        liveSnapshot(),
        now: now,
        activeTripId: 'trip-live-1',
        expectedTripId: 'trip-live-1',
      ).toSafeDashboardMap();

  Map<String, Object?> safeRenderMap() => TripLiveOdometerRenderPolicy.evaluate(
    snapshot: liveSnapshot(),
    now: now,
    activeTripId: 'trip-live-1',
    expectedTripId: 'trip-live-1',
    subscribedSurfaces: const {
      TripLiveOdometerRenderSurface.dashboard,
      TripLiveOdometerRenderSurface.activeVehicleBlock,
      TripLiveOdometerRenderSurface.contractorDashboard,
    },
  ).toSafeUiMap();

  test('broadcast map validates as advisory live odometer UI payload', () {
    final validation = TripLiveOdometerUiValidation.fromBroadcastMap(
      safeBroadcastMap(),
    );

    expect(validation.isRenderable, isTrue);
    expect(validation.status, 'renderable');
    expect(validation.displayValue, '0001203');
    expect(validation.reasons, isEmpty);
    expect(safeBroadcastMap()['odometerIsGlobalTruth'], isTrue);
    expect(
      safeBroadcastMap()['physicalOdometerRequiredForOfficialMileage'],
      isTrue,
    );
    expect(
      safeBroadcastMap()['confirmedOdometerOverridesExternalMileage'],
      isTrue,
    );
    expect(
      safeBroadcastMap()['externalMileageCannotBecomeGlobalTruth'],
      isTrue,
    );
  });

  test('render map validates across subscribed dashboard surfaces', () {
    final validation = TripLiveOdometerUiValidation.fromRenderMap(
      safeRenderMap(),
    );

    expect(validation.isRenderable, isTrue);
    expect(validation.status, 'liveRenderable');
    expect(validation.displayValue, '0001203');
    expect(validation.reasons, isEmpty);
    expect(safeRenderMap()['odometerIsGlobalTruth'], isTrue);
    expect(
      safeRenderMap()['physicalOdometerRequiredForOfficialMileage'],
      isTrue,
    );
    expect(
      safeRenderMap()['confirmedOdometerOverridesExternalMileage'],
      isTrue,
    );
    expect(safeRenderMap()['externalMileageCannotBecomeGlobalTruth'], isTrue);
  });

  test('remote authority and odometer replacement claims fail closed', () {
    final validation = TripLiveOdometerUiValidation.fromBroadcastMap(
      safeBroadcastMap()..addAll({
        'writesConfirmedOdometer': true,
        'gpsCanReplaceOdometer': true,
        'mapboxCanReplaceOdometer': true,
        'firestoreCanOverrideLiveDisplay': true,
        'remoteDisplayCanOverrideLocalTrip': true,
        'importedDisplayCanOverrideLocalTrip': true,
        'dashboardCacheCanOverrideLocalTrip': true,
        'odometerIsGlobalTruth': false,
        'physicalOdometerRequiredForOfficialMileage': false,
        'confirmedOdometerOverridesExternalMileage': false,
        'externalMileageCannotBecomeGlobalTruth': false,
        'gpsDistanceCanOnlyAdviseMileageReview': false,
        'mapMatchingCanOnlyAdviseMileageReview': false,
        'optimizationCannotChangeOfficialMileage': false,
        'authenticationDoesNotGrantDisplayAuthority': false,
        'matchingActiveTripRequired': false,
      }),
    );

    expect(validation.isRenderable, isFalse);
    expect(
      validation.reasons,
      containsAll([
        'payload_can_replace_odometer',
        'remote_display_can_override_local_trip',
        'authentication_treated_as_display_authority',
        'matching_active_trip_not_required',
      ]),
    );
  });

  test(
    'surface-specific odometer math and stale surface contracts fail closed',
    () {
      final validation = TripLiveOdometerUiValidation.fromRenderMap(
        safeRenderMap()..addAll({
          'liveUiMustRefreshOnProjectionChange': false,
          'singleLiveOdometerSnapshotRequired': false,
          'allDashboardSurfacesUseSameSnapshot': false,
          'allDashboardSurfacesUseSameProjectionRevision': false,
          'surfaceSpecificMileageCalculationAllowed': true,
          'activeVehicleBlockUsesLiveProjection': false,
          'activeVehicleBlockMustNotCacheProjection': false,
          'vehicleProfileUsesLiveProjection': false,
          'contractorDashboardUsesLiveProjection': false,
          'fleetDashboardUsesLiveProjection': false,
          'standardDashboardUsesLiveProjection': false,
          'calendarReviewUsesConfirmedTruth': false,
          'odometerIsGlobalTruth': false,
          'physicalOdometerRequiredForOfficialMileage': false,
          'confirmedOdometerOverridesExternalMileage': false,
          'externalMileageCannotBecomeGlobalTruth': false,
          'gpsDistanceCanOnlyAdviseMileageReview': false,
          'mapMatchingCanOnlyAdviseMileageReview': false,
          'optimizationCannotChangeOfficialMileage': false,
        }),
      );

      expect(validation.isRenderable, isFalse);
      expect(
        validation.reasons,
        contains('live_odometer_surface_contract_missing'),
      );
    },
  );

  test(
    'identifiers, sensitive material, and unsafe rendering flags are blocked',
    () {
      final validation = TripLiveOdometerUiValidation.fromRenderMap(
        safeRenderMap()..addAll({
          'activeTripIdIncluded': true,
          'ownerUserIdIncluded': true,
          'futureProjectionCanRender': true,
          'impossibleProjectionCanRender': true,
          'rawGpsIncluded': true,
          'preciseLocationIncluded': true,
          'routeGeometryIncluded': true,
          'tokensIncluded': true,
          'debugLocation': '35.123456,-80.987654',
        }),
      );

      expect(validation.isRenderable, isFalse);
      expect(
        validation.reasons,
        containsAll([
          'payload_contains_trip_owner_identifiers',
          'unsafe_projection_can_render',
          'payload_contains_sensitive_trip_material',
          'payload_contains_sensitive_text',
        ]),
      );
    },
  );

  test(
    'malformed display values, statuses, reasons, and surfaces are rejected',
    () {
      final validation = TripLiveOdometerUiValidation.fromRenderMap(
        safeRenderMap()..addAll({
          'schemaVersion': 2,
          'status': 'forceRender',
          'displayValue': '1203',
          'confirmedDisplayValue': '00012A3',
          'displayValueValidated': false,
          'confirmedDisplayValueValidated': false,
          'reasonCodes': ['live_projection_renderable', 'private_location'],
          'surfaces': ['dashboard', 'secretSurface'],
          'shouldRender': 'yes',
          'shouldNotifyListeners': 'yes',
        }),
      );

      expect(validation.isRenderable, isFalse);
      expect(
        validation.reasons,
        containsAll([
          'unsupported_schema_version',
          'invalid_display_value',
          'invalid_confirmed_display_value',
          'invalid_reason_codes',
          'invalid_live_render_status',
          'invalid_render_flag',
          'invalid_listener_notify_flag',
          'invalid_render_surfaces',
        ]),
      );
    },
  );

  test('broadcast payload must expose dashboard flags as booleans', () {
    final validation = TripLiveOdometerUiValidation.fromBroadcastMap(
      safeBroadcastMap()..addAll({
        'shouldNotifyDashboard': 'yes',
        'reviewRequired': 'no',
        'status': 'ghost',
        'reasonCodes': 'live_projection_renderable',
      }),
    );

    expect(validation.isRenderable, isFalse);
    expect(validation.reasons, contains('invalid_dashboard_notify_flag'));
    expect(validation.reasons, contains('invalid_review_required_flag'));
    expect(validation.reasons, contains('invalid_live_broadcast_status'));
    expect(validation.reasons, contains('invalid_reason_codes'));
  });

  test('vehicle and projection revision boundaries fail closed', () {
    final validation = TripLiveOdometerUiValidation.fromBroadcastMap(
      safeBroadcastMap()..addAll({
        'matchingVehicleProfileRequired': false,
        'projectionRevisionMustIncrease': false,
        'sameOrOlderProjectionRevisionCanNotify': true,
        'mapboxCanIncreaseLiveMileage': true,
        'calibrationCanDecreaseLiveProjection': true,
      }),
    );

    expect(validation.isRenderable, isFalse);
    expect(
      validation.reasons,
      contains('live_projection_revision_boundary_missing'),
    );
    expect(validation.reasons, contains('payload_can_replace_odometer'));
  });
}
