import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_signal_quality.dart';
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
    expect(safe['mapboxCanInferVehicleOnlyStopAddress'], isFalse);
    expect(safe['firestoreCanCreateVehicleOnlyStop'], isFalse);
    expect(safe['remoteDwellCanSurfaceManualFallback'], isFalse);
    expect(safe['mapsRequiredForVehicleOnlyDwell'], isFalse);
    expect(safe['manualFallbackCannotInferJobsiteAddress'], isTrue);
    expect(safe['hasEnoughCleanDriveEvidence'], isTrue);
    expect(safe['manualFallbackRequiresActiveLocalTrip'], isTrue);
    expect(safe['manualFallbackRequiresUserAction'], isTrue);
    expect(safe['manualFallbackCanEditOdometer'], isFalse);
    expect(TripVehicleOnlyDwellSummaryValidation.isValid(safe), isTrue);
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
      expect(
        TripVehicleOnlyDwellSummaryValidation.isValid(
          decision.toSafeDashboardMap(),
        ),
        isTrue,
      );
    },
  );

  test('extended delivery gridlock jitter is protected before fallback', () {
    final decision = TripVehicleOnlyDwellPolicy.evaluate(
      profile: TripTrackingProfile.deliveryVehicle,
      stationaryDuration: const Duration(minutes: 5),
      walkingEvidenceCount: 0,
      rejectedDriftCount: 9,
      acceptedDistanceCount: 5,
      acceptedVehicleMovementObserved: true,
      speedMps: 0.1,
      horizontalAccuracyMeters: 16,
    );

    expect(decision.status, TripVehicleOnlyDwellStatus.trafficControlProtected);
    expect(decision.canSurfaceManualFallback, isFalse);
    expect(
      decision.toSafeDashboardMap()['manualFallbackRequiresUserAction'],
      isTrue,
    );
  });

  test('manual fallback requires enough clean drive evidence first', () {
    final decision = TripVehicleOnlyDwellPolicy.evaluate(
      profile: TripTrackingProfile.rideshareVehicle,
      stationaryDuration: const Duration(minutes: 10),
      walkingEvidenceCount: 0,
      rejectedDriftCount: 0,
      acceptedDistanceCount: 1,
      acceptedVehicleMovementObserved: true,
      speedMps: 0,
      horizontalAccuracyMeters: 10,
    );
    final safe = decision.toSafeDashboardMap();

    expect(decision.status, TripVehicleOnlyDwellStatus.keepTracking);
    expect(decision.reasonCode, 'vehicle_only_dwell_needs_more_drive_evidence');
    expect(decision.canSurfaceManualFallback, isFalse);
    expect(safe['hasEnoughCleanDriveEvidence'], isFalse);
    expect(safe['minimumAcceptedDistanceCount'], 4);
    expect(TripVehicleOnlyDwellSummaryValidation.isValid(safe), isTrue);
  });

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
      expect(
        TripVehicleOnlyDwellSummaryValidation.isValid(
          decision.toSafeDashboardMap(),
        ),
        isTrue,
      );
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
    expect(
      TripVehicleOnlyDwellSummaryValidation.isValid(
        decision.toSafeDashboardMap(),
      ),
      isTrue,
    );
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
    expect(safe['acceptedDistanceCount'], 8);
    expect(safe['minimumAcceptedDistanceCount'], 3);
    expect(TripVehicleOnlyDwellSummaryValidation.isValid(safe), isTrue);
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

  test(
    'two-person delivery vehicle-only dwell can suggest manual fallback only',
    () {
      final decision = TripVehicleOnlyDwellPolicy.evaluate(
        profile: TripTrackingProfile.deliveryVehicle,
        stationaryDuration: const Duration(minutes: 7),
        walkingEvidenceCount: 0,
        rejectedDriftCount: 0,
        acceptedDistanceCount: 7,
        acceptedVehicleMovementObserved: true,
        speedMps: 0,
        horizontalAccuracyMeters: 8,
      );
      final safe = decision.toSafeDashboardMap();

      expect(
        decision.status,
        TripVehicleOnlyDwellStatus.manualFallbackRecommended,
      );
      expect(decision.canSurfaceManualFallback, isTrue);
      expect(safe['manualFallbackRequiresUserAction'], isTrue);
      expect(safe['manualFallbackCanConfirmMileage'], isFalse);
      expect(safe['manualFallbackCanInferAddress'], isFalse);
      expect(safe['vehicleOnlyDwellCanCreateOfficialStop'], isFalse);
      expect(safe['activityRecognitionCanConfirmVehicleOnlyStop'], isFalse);
      expect(safe['walkingEvidenceCanBeReplayedFromCloud'], isFalse);
      expect(safe['dwellEvidenceCanCreateCalibration'], isFalse);
      expect(safe['dwellEvidenceCanApplyCalibration'], isFalse);
      expect(safe['calibrationRequiresTrustedGpsWindow'], isTrue);
      expect(safe['poorGpsDaysExcludedFromCalibration'], isTrue);
      expect(safe['twoPersonDeliveryRequiresManualConfirmation'], isTrue);
      expect(safe['manualFallbackCanBackdateWithoutReview'], isFalse);
      expect(safe['gridlockCanInferStopAddress'], isFalse);
      expect(safe['gridlockCanConfirmMileage'], isFalse);
      expect(TripVehicleOnlyDwellSummaryValidation.isValid(safe), isTrue);
    },
  );

  test('poor or interrupted GPS suppresses vehicle-only manual fallback', () {
    for (final quality in const [
      TripTrackingSignalQuality.noSamples,
      TripTrackingSignalQuality.poor,
      TripTrackingSignalQuality.interrupted,
    ]) {
      final decision = TripVehicleOnlyDwellPolicy.evaluate(
        profile: TripTrackingProfile.deliveryVehicle,
        stationaryDuration: const Duration(minutes: 7),
        walkingEvidenceCount: 0,
        rejectedDriftCount: 0,
        acceptedDistanceCount: 7,
        acceptedVehicleMovementObserved: true,
        speedMps: 0,
        horizontalAccuracyMeters: 8,
        signalQuality: quality,
      );

      expect(decision.status, TripVehicleOnlyDwellStatus.keepTracking);
      expect(decision.reasonCode, 'vehicle_only_dwell_waiting_for_trusted_gps');
      expect(decision.canSurfaceManualFallback, isFalse);
      expect(
        TripVehicleOnlyDwellSummaryValidation.isValid(
          decision.toSafeDashboardMap(),
        ),
        isTrue,
      );
    }
  });

  test('unsafe GPS blocks vehicle-only dwell evidence closed', () {
    final decision = TripVehicleOnlyDwellPolicy.evaluate(
      profile: TripTrackingProfile.deliveryVehicle,
      stationaryDuration: const Duration(minutes: 7),
      walkingEvidenceCount: 0,
      rejectedDriftCount: 0,
      acceptedDistanceCount: 7,
      acceptedVehicleMovementObserved: true,
      speedMps: 0,
      horizontalAccuracyMeters: 8,
      signalQuality: TripTrackingSignalQuality.unsafe,
    );

    expect(decision.status, TripVehicleOnlyDwellStatus.unsafeEvidence);
    expect(decision.reasonCode, 'unsafe_vehicle_only_dwell_evidence');
    expect(decision.canSurfaceManualFallback, isFalse);
  });

  test('summary validation rejects sensitive or authoritative dwell cards', () {
    final safe = TripVehicleOnlyDwellPolicy.evaluate(
      profile: TripTrackingProfile.deliveryVehicle,
      stationaryDuration: const Duration(minutes: 7),
      walkingEvidenceCount: 0,
      rejectedDriftCount: 0,
      acceptedDistanceCount: 7,
      acceptedVehicleMovementObserved: true,
      speedMps: 0,
      horizontalAccuracyMeters: 8,
    ).toSafeDashboardMap();

    expect(
      TripVehicleOnlyDwellSummaryValidation.isValid({
        ...safe,
        'vehicleOnlyDwellCanCreateOfficialStop': true,
        'mapboxCanInferVehicleOnlyStopAddress': true,
      }),
      isFalse,
    );
    expect(
      TripVehicleOnlyDwellSummaryValidation.isValid({
        ...safe,
        'manualFallbackCanEditOdometer': true,
      }),
      isFalse,
    );
    expect(
      TripVehicleOnlyDwellSummaryValidation.isValid({
        ...safe,
        'manualFallbackCanConfirmMileage': true,
      }),
      isFalse,
    );
    expect(
      TripVehicleOnlyDwellSummaryValidation.isValid({
        ...safe,
        'debugText': 'latitude=35 longitude=-80 token=sk.secret',
      }),
      isFalse,
    );
    expect(
      TripVehicleOnlyDwellSummaryValidation.isValid({
        ...safe,
        'remoteDwellCanSurfaceManualFallback': true,
      }),
      isFalse,
    );
  });
}
