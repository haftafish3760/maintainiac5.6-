import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_odometer_calibration.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  final started = DateTime.utc(2026, 7, 20, 8);

  test(
    'active session and review preserve vehicle configuration revision',
    () async {
      final store = TripTrackingSessionStore.memory();
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
        activeVehicleConfigurationRevision: () => 4,
        gpsAssistanceCalibrationMultiplier: 1.02,
        clockNow: () => started.add(const Duration(hours: 2)),
      );

      expect(
        await controller.start(
          tripId: 'trip_configuration_revision',
          vehicleId: 'vehicle_1',
          profile: TripTrackingProfile.roadVehicle,
          profileId: 'profile_1',
          startedAt: started,
        ),
        isTrue,
      );
      expect(store.activeSession?.vehicleConfigurationRevision, 4);
      expect(store.activeSession?.gpsAssistanceCalibrationMultiplier, 1.02);

      final review = await controller.finishForReview(
        finishedAt: started.add(const Duration(hours: 1)),
      );
      expect(review?.vehicleConfigurationRevision, 4);
      expect(review?.gpsAssistanceCalibrationMultiplier, 1.02);
      expect(review?.effectiveProfileId, 'profile_1');
      expect(store.pendingReviews.single.vehicleConfigurationRevision, 4);
    },
  );

  test(
    'mid-trip context changes cannot rewrite bound review identity',
    () async {
      var configurationRevision = 7;
      final store = TripTrackingSessionStore.memory();
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
        activeVehicleConfigurationRevision: () => configurationRevision,
        clockNow: () => started.add(const Duration(hours: 2)),
      );
      await controller.start(
        tripId: 'trip_bound_context',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        profileId: 'profile_original',
        startedAt: started,
      );

      configurationRevision = 8;
      final review = await controller.finishForReview(
        finishedAt: started.add(const Duration(hours: 1)),
      );

      expect(review?.effectiveProfileId, 'profile_original');
      expect(review?.vehicleConfigurationRevision, 7);
    },
  );

  test(
    'session and review migrations default legacy configuration to zero',
    () {
      final session = TripTrackingSessionRecord.fromMap(
        TripTrackingSessionRecord(
            id: 'legacy_session',
            vehicleId: 'vehicle_1',
            startingOdometer: 1000,
            profile: TripTrackingProfile.roadVehicle,
            startedAt: started,
            updatedAt: started,
            engineSnapshot: const TripTrackingEngineSnapshot(
              totalAcceptedMeters: 0,
              walkingReviewSuggested: false,
            ),
          ).toMap()
          ..remove('vehicleConfigurationRevision')
          ..remove('gpsAssistanceCalibrationMultiplier'),
      );
      final review = TripTrackingReviewRecord.fromMap(
        _confirmedReview(id: 'legacy_review', revision: 0, day: 1).toMap()
          ..remove('vehicleConfigurationRevision')
          ..remove('gpsAssistanceCalibrationMultiplier'),
      );

      expect(session.vehicleConfigurationRevision, 0);
      expect(session.gpsAssistanceCalibrationMultiplier, 1);
      expect(session.schemaVersion, 1);
      expect(review.vehicleConfigurationRevision, 0);
      expect(review.gpsAssistanceCalibrationMultiplier, 1);
      expect(review.schemaVersion, 2);
    },
  );

  test('recovery retains the multiplier bound when the trip started', () async {
    final store = TripTrackingSessionStore.memory();
    await store.save(
      TripTrackingSessionRecord(
        id: 'calibration_recovery_trip',
        vehicleId: 'vehicle_1',
        startingOdometer: 1000,
        profile: TripTrackingProfile.roadVehicle,
        startedAt: started,
        updatedAt: started,
        engineSnapshot: const TripTrackingEngineSnapshot(
          totalAcceptedMeters: 1609.344,
          walkingReviewSuggested: false,
        ),
        gpsAssistanceCalibrationMultiplier: 1.1,
      ),
    );
    final controller = TripTrackingController(
      sessionStore: store,
      odometer: GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      ),
      gpsAssistanceCalibrationMultiplier: 0.9,
      clockNow: () => started.add(const Duration(hours: 1)),
    );

    expect(await controller.restore(), isTrue);
    expect(controller.activeSession?.gpsAssistanceCalibrationMultiplier, 1.1);
    final review = await controller.finishForReview();
    expect(review?.gpsAssistanceCalibrationMultiplier, 1.1);
    expect(review?.estimatedEndingOdometer, 1001);
  });

  test(
    'negative persisted configuration revisions fail the trust boundary',
    () {
      final sessionMap = TripTrackingSessionRecord(
        id: 'invalid_session_revision',
        vehicleId: 'vehicle_1',
        startingOdometer: 1000,
        profile: TripTrackingProfile.roadVehicle,
        startedAt: started,
        updatedAt: started,
        engineSnapshot: const TripTrackingEngineSnapshot(
          totalAcceptedMeters: 0,
          walkingReviewSuggested: false,
        ),
      ).toMap()..['vehicleConfigurationRevision'] = -1;
      final reviewMap = _confirmedReview(
        id: 'invalid_review_revision',
        revision: 0,
        day: 1,
      ).toMap()..['vehicleConfigurationRevision'] = -1;

      expect(
        TripTrackingSessionRecord.fromMap(sessionMap).hasValidTimeline,
        false,
      );
      expect(
        TripTrackingReviewRecord.fromMap(reviewMap).hasValidTimeline,
        false,
      );
    },
  );

  test('malformed persisted calibration multipliers fail closed', () {
    final sessionMap = TripTrackingSessionRecord(
      id: 'invalid_session_calibration',
      vehicleId: 'vehicle_1',
      startingOdometer: 1000,
      profile: TripTrackingProfile.roadVehicle,
      startedAt: started,
      updatedAt: started,
      engineSnapshot: const TripTrackingEngineSnapshot(
        totalAcceptedMeters: 0,
        walkingReviewSuggested: false,
      ),
    ).toMap()..['gpsAssistanceCalibrationMultiplier'] = 5;
    final reviewMap = _confirmedReview(
      id: 'invalid_review_calibration',
      revision: 0,
      day: 1,
    ).toMap()..['gpsAssistanceCalibrationMultiplier'] = double.nan;

    expect(
      TripTrackingSessionRecord.fromMap(sessionMap).hasValidTimeline,
      false,
    );
    expect(TripTrackingReviewRecord.fromMap(reviewMap).hasValidTimeline, false);
  });

  test('calibration uses only the requested tire configuration cohort', () {
    final reviews = <TripTrackingReviewRecord>[
      for (var day = 1; day <= 7; day += 1)
        _confirmedReview(id: 'old_$day', revision: 1, day: day),
      for (var day = 1; day <= 7; day += 1)
        _confirmedReview(id: 'current_$day', revision: 2, day: day + 10),
    ];

    final signal = TripOdometerCalibrationSignal.evaluateConfirmedReviews(
      reviews: reviews,
      vehicleId: 'vehicle_1',
      vehicleConfigurationRevision: 2,
      nowUtc: DateTime.utc(2026, 7, 25),
    );

    expect(signal.eligibleSampleCount, 7);
    expect(signal.averageGpsToOdometerRatio, closeTo(1.1, .001));
  });
}

TripTrackingReviewRecord _confirmedReview({
  required String id,
  required int revision,
  required int day,
}) {
  final startedAt = DateTime.utc(2026, 7, day, 8);
  return TripTrackingReviewRecord(
    id: id,
    vehicleId: 'vehicle_1',
    vehicleConfigurationRevision: revision,
    startingOdometer: 1000,
    estimatedEndingOdometer: 1100,
    confirmedEndingOdometer: 1100,
    odometerConfirmedAt: startedAt.add(const Duration(hours: 3)),
    profile: TripTrackingProfile.roadVehicle,
    startedAt: startedAt,
    finishedAt: startedAt.add(const Duration(hours: 2)),
    engineSnapshot: const TripTrackingEngineSnapshot(
      totalAcceptedMeters: 110 * 1609.344,
      walkingReviewSuggested: false,
      diagnostics: TripTrackingDiagnostics(
        receivedSamples: 100,
        acceptedSamples: 100,
        dispositionCounts: {TripSampleDisposition.acceptedDistance: 100},
      ),
    ),
  );
}
