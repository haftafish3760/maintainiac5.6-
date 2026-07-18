import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_live_odometer_projection.dart';

void main() {
  test('live projection is display-only and monotonic', () {
    final projection = TripLiveOdometerProjection(startingOdometer: 1000);

    expect(projection.updateAcceptedMeters(10 * metersPerMile), 1010);
    expect(projection.updateAcceptedMeters(5 * metersPerMile), 1010);
    expect(projection.projectedReading, 1010);
    expect(projection.toSafeDashboardMap()['writesConfirmedOdometer'], isFalse);
    expect(
      projection.toSafeDashboardMap()['displayOnlyMileageSource'],
      'gps_assisted_projection',
    );
    expect(
      projection
          .toSafeDashboardMap()['externalDistanceValidatedBeforeProjection'],
      isTrue,
    );
    expect(
      projection.toSafeDashboardMap()['liveUiMustRefreshOnProjectionChange'],
      isTrue,
    );
    expect(
      projection.toSafeDashboardMap()['globalOdometerScopeMustNotifyListeners'],
      isTrue,
    );
    expect(
      projection
          .toSafeDashboardMap()['dashboardActiveVehicleBlockUsesLiveProjection'],
      isTrue,
    );
    expect(
      projection.toSafeDashboardMap()['contractorDashboardUsesLiveProjection'],
      isTrue,
    );
    expect(
      projection.toSafeDashboardMap()['crossDashboardLiveOdometerReady'],
      isTrue,
    );
    expect(
      projection.toSafeDashboardMap()['remoteProjectionRequiresMatchingTripId'],
      isTrue,
    );
    expect(
      projection.toSafeDashboardMap()['staleProjectionCanCommitMileage'],
      isFalse,
    );
    expect(
      projection.toSafeDashboardMap()['remoteProjectionCanOverrideLocalTrip'],
      isFalse,
    );
    expect(
      projection.toSafeDashboardMap()['confirmedOdometerRemainsCanonical'],
      isTrue,
    );
    expect(projection.toSafeDashboardMap()['projectionIsMonotonic'], isTrue);
    expect(projection.toSafeDashboardMap()['tokensIncluded'], isFalse);
  });

  test('invalid GPS distance cannot poison live projection', () {
    final projection = TripLiveOdometerProjection(startingOdometer: 1000);

    expect(projection.updateAcceptedMeters(double.nan), 1000);
    expect(projection.updateAcceptedMeters(double.infinity), 1000);
    expect(projection.updateAcceptedMeters(-1), 1000);
    expect(projection.lastUpdateExceededMax, isFalse);
    expect(projection.toSafeDashboardMap()['lastUpdateExceededMax'], isFalse);
  });

  test('overrange GPS projection fails closed with dashboard-safe flag', () {
    final projection = TripLiveOdometerProjection(
      startingOdometer: 999998,
      maxSupportedReading: 999999,
    );

    expect(projection.updateAcceptedMeters(3 * metersPerMile), 999998);
    expect(projection.lastUpdateExceededMax, isTrue);
    expect(projection.toSafeDashboardMap()['lastUpdateExceededMax'], isTrue);
    expect(
      projection.toSafeDashboardMap()['malformedProjectionPayloadFailsSafe'],
      isTrue,
    );
    expect(
      projection.toSafeDashboardMap()['projectionExceededSupportedRange'],
      isTrue,
    );
    expect(projection.toSafeDashboardMap()['rawGpsIncluded'], isFalse);
  });

  test('calibration assistance is clamped and cannot reverse projection', () {
    final projection = TripLiveOdometerProjection(startingOdometer: 1000);

    expect(
      projection.updateAcceptedMeters(
        10 * metersPerMile,
        gpsAssistanceCalibrationMultiplier: .01,
      ),
      1008,
    );
    expect(
      projection.updateAcceptedMeters(
        10 * metersPerMile,
        gpsAssistanceCalibrationMultiplier: 2,
      ),
      1013,
    );
    expect(
      projection.updateAcceptedMeters(
        9 * metersPerMile,
        gpsAssistanceCalibrationMultiplier: .8,
      ),
      1013,
    );
  });

  test('malformed calibration multipliers fall back to neutral assistance', () {
    final projection = TripLiveOdometerProjection(startingOdometer: 1000);

    expect(
      projection.updateAcceptedMeters(
        10 * metersPerMile,
        gpsAssistanceCalibrationMultiplier: double.nan,
      ),
      1010,
    );
    expect(
      projection.updateAcceptedMeters(
        11 * metersPerMile,
        gpsAssistanceCalibrationMultiplier: -2,
      ),
      1011,
    );
  });

  test('malformed odometer bounds are sanitized before display', () {
    final projection = TripLiveOdometerProjection(
      startingOdometer: -100,
      maxSupportedReading: -1,
    );

    expect(projection.projectedReading, 0);
    expect(projection.maxSupportedReading, 0);
    expect(projection.updateAcceptedMeters(0), 0);
    expect(projection.toSafeDashboardMap()['startingOdometer'], 0);
    expect(projection.toSafeDashboardMap()['maxSupportedReading'], 0);
    expect(
      projection.toSafeDashboardMap()['firestoreCanOverrideLiveProjection'],
      isFalse,
    );
    expect(
      projection.toSafeDashboardMap()['mapboxCanOverrideLiveProjection'],
      isFalse,
    );
  });

  test('dashboard payload validator accepts only display-safe projections', () {
    final projection = TripLiveOdometerProjection(startingOdometer: 1000)
      ..updateAcceptedMeters(12 * metersPerMile);
    final validation = TripLiveOdometerDashboardPayloadValidation.fromPayload(
      projection.toSafeDashboardMap(),
    );

    expect(validation.isRenderable, isTrue);
    expect(validation.projectedReading, 1012);
    expect(validation.reasons, isEmpty);
  });

  test('dashboard payload validator rejects remote overwrite semantics', () {
    final payload =
        Map<String, Object?>.from(
          TripLiveOdometerProjection(
            startingOdometer: 1000,
          ).toSafeDashboardMap(),
        )..addAll({
          'remoteProjectionCanOverrideLocalTrip': true,
          'firestoreCanOverrideLiveProjection': true,
          'mapboxCanOverrideLiveProjection': true,
          'writesConfirmedOdometer': true,
        });
    final validation = TripLiveOdometerDashboardPayloadValidation.fromPayload(
      payload,
    );

    expect(validation.isRenderable, isFalse);
    expect(validation.projectedReading, isNull);
    expect(
      validation.reasons,
      containsAll([
        'payload_can_write_confirmed_odometer',
        'remote_projection_can_override_local_trip',
        'firestore_can_override_live_projection',
        'mapbox_can_override_live_projection',
      ]),
    );
  });

  test(
    'dashboard payload validator rejects malformed or sensitive payloads',
    () {
      final payload =
          Map<String, Object?>.from(
            TripLiveOdometerProjection(
              startingOdometer: 1000,
            ).toSafeDashboardMap(),
          )..addAll({
            'schemaVersion': 99,
            'projectedReading': 999,
            'rawGpsIncluded': true,
            'routeGeometryIncluded': true,
            'tokensIncluded': true,
            'mapsRequiredForTracking': true,
          });
      final validation = TripLiveOdometerDashboardPayloadValidation.fromPayload(
        payload,
      );

      expect(validation.isRenderable, isFalse);
      expect(validation.projectedReading, isNull);
      expect(
        validation.reasons,
        containsAll([
          'unsupported_schema_version',
          'projection_below_starting_odometer',
          'payload_contains_sensitive_trip_material',
          'maps_required_for_tracking',
        ]),
      );
    },
  );
}
