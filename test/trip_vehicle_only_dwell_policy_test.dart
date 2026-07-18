import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_vehicle_only_dwell_policy.dart';

void main() {
  test('rideshare vehicle-only dwell surfaces manual fallback only', () {
    final decision = TripVehicleOnlyDwellPolicy.evaluate(
      profile: TripTrackingProfile.rideshareVehicle,
      stationaryDuration: const Duration(minutes: 9),
      walkingEvidenceCount: 0,
      rejectedDriftCount: 0,
      acceptedDistanceCount: 8,
      acceptedVehicleMovementObserved: true,
      speedMps: 0.1,
      horizontalAccuracyMeters: 10,
    );
    final safe = decision.toSafeDashboardMap();

    expect(
      decision.status,
      TripVehicleOnlyDwellStatus.manualFallbackRecommended,
    );
    expect(decision.canSurfaceManualFallback, isTrue);
    expect(safe['vehicleOnlyDwellCanCreateOfficialStop'], isFalse);
    expect(safe['gpsCanConfirmVehicleOnlyStop'], isFalse);
    expect(safe['mapboxCanConfirmVehicleOnlyStop'], isFalse);
    expect(safe['firestoreCanCreateVehicleOnlyStop'], isFalse);
    expect(safe['mapsRequiredForVehicleOnlyDwell'], isFalse);
  });

  test(
    'delivery stoplight-length jitter remains protected traffic control',
    () {
      final decision = TripVehicleOnlyDwellPolicy.evaluate(
        profile: TripTrackingProfile.deliveryVehicle,
        stationaryDuration: const Duration(minutes: 3),
        walkingEvidenceCount: 0,
        rejectedDriftCount: 6,
        acceptedDistanceCount: 5,
        acceptedVehicleMovementObserved: true,
        speedMps: 0.2,
        horizontalAccuracyMeters: 15,
      );

      expect(
        decision.status,
        TripVehicleOnlyDwellStatus.trafficControlProtected,
      );
      expect(decision.canSurfaceManualFallback, isFalse);
      expect(
        decision.toSafeDashboardMap()['longTrafficLightProtected'],
        isTrue,
      );
    },
  );

  test(
    'walking evidence is handled by walking stop policy, not dwell fallback',
    () {
      final decision = TripVehicleOnlyDwellPolicy.evaluate(
        profile: TripTrackingProfile.deliveryVehicle,
        stationaryDuration: const Duration(minutes: 8),
        walkingEvidenceCount: 4,
        rejectedDriftCount: 0,
        acceptedDistanceCount: 5,
        acceptedVehicleMovementObserved: true,
        speedMps: 0,
        horizontalAccuracyMeters: 8,
      );

      expect(decision.status, TripVehicleOnlyDwellStatus.keepTracking);
      expect(
        decision.reasonCode,
        'vehicle_only_dwell_waiting_for_clean_evidence',
      );
      expect(decision.canSurfaceManualFallback, isFalse);
    },
  );

  test('vehicle-only dwell waits for accepted vehicle movement first', () {
    final decision = TripVehicleOnlyDwellPolicy.evaluate(
      profile: TripTrackingProfile.rideshareVehicle,
      stationaryDuration: const Duration(minutes: 12),
      walkingEvidenceCount: 0,
      rejectedDriftCount: 0,
      acceptedDistanceCount: 0,
      acceptedVehicleMovementObserved: false,
      speedMps: 0,
      horizontalAccuracyMeters: 9,
    );

    expect(decision.status, TripVehicleOnlyDwellStatus.keepTracking);
    expect(decision.canSurfaceManualFallback, isFalse);
  });

  test('unsafe provider values fail closed and expose no private data', () {
    final decision = TripVehicleOnlyDwellPolicy.evaluate(
      profile: TripTrackingProfile.deliveryVehicle,
      stationaryDuration: const Duration(minutes: 10),
      walkingEvidenceCount: 0,
      rejectedDriftCount: 0,
      acceptedDistanceCount: 8,
      acceptedVehicleMovementObserved: true,
      speedMps: double.nan,
      horizontalAccuracyMeters: 500,
    );
    final safe = decision.toSafeDashboardMap();

    expect(decision.status, TripVehicleOnlyDwellStatus.unsafeEvidence);
    expect(decision.canSurfaceManualFallback, isFalse);
    expect(safe['rawSamplesIncluded'], isFalse);
    expect(safe['coordinatesIncluded'], isFalse);
    expect(safe['tokensIncluded'], isFalse);
  });

  test(
    'equipment GPS-only profile gets conservative fallback after long dwell',
    () {
      final decision = TripVehicleOnlyDwellPolicy.evaluate(
        profile: TripTrackingProfile.lowSpeedEquipment,
        stationaryDuration: const Duration(minutes: 13),
        walkingEvidenceCount: 0,
        rejectedDriftCount: 0,
        acceptedDistanceCount: 6,
        acceptedVehicleMovementObserved: true,
        speedMps: 0,
        horizontalAccuracyMeters: 12,
      );

      expect(
        decision.status,
        TripVehicleOnlyDwellStatus.manualFallbackRecommended,
      );
      expect(decision.reasonCode, 'vehicle_only_dwell_manual_fallback');
      expect(decision.canSurfaceManualFallback, isTrue);
    },
  );
}
