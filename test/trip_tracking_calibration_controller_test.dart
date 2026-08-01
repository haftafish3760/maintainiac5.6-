import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_live_odometer_projection.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  final driveStart = DateTime.utc(2026, 7, 12, 8);

  TripLocationSample sample(double longitude, int seconds) =>
      TripLocationSample(
        latitude: 35,
        longitude: longitude,
        recordedAt: driveStart.add(Duration(seconds: seconds)),
        horizontalAccuracyMeters: 5,
      );

  test(
    'controller requires explicit acceptance before applying reviewed calibration',
    () async {
      final store = TripTrackingSessionStore.memory();
      final odometer = GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      );
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: odometer,
        clockNow: () => DateTime.utc(2026, 7, 10, 12),
      );
      addTearDown(controller.dispose);
      addTearDown(odometer.dispose);
      for (var day = 0; day < 7; day += 1) {
        await store.saveReview(
          _confirmedReview(
            id: 'calibration_$day',
            startedAt: DateTime.utc(2026, 7, 1 + day, 8),
            filteredGpsMiles: 110,
            odometerMiles: 100,
          ),
        );
      }

      controller.refreshGpsAssistanceCalibration(enabled: true);

      expect(controller.gpsAssistanceCalibrationMultiplier, 1);
      expect(controller.calibrationReviewAcceptedForCurrentEvidence, isFalse);
      expect(controller.acceptGpsAssistanceCalibrationReview(), isTrue);

      expect(
        controller.gpsAssistanceCalibrationMultiplier,
        closeTo(.9091, .001),
      );
      controller.refreshGpsAssistanceCalibration(enabled: false);
      expect(controller.gpsAssistanceCalibrationMultiplier, 1);
    },
  );

  test(
    'a new inconsistent confirmed review fails neutral after acceptance resets',
    () async {
      final store = TripTrackingSessionStore.memory();
      final odometer = GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1600,
      );
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: odometer,
        clockNow: () => DateTime.utc(2026, 7, 10, 12),
      );
      addTearDown(controller.dispose);
      addTearDown(odometer.dispose);
      for (var day = 0; day < 6; day += 1) {
        await store.saveReview(
          _confirmedReview(
            id: 'prior_calibration_$day',
            startedAt: DateTime.utc(2026, 7, 1 + day, 8),
            startingOdometer: 1000 + (day * 100),
            filteredGpsMiles: 110,
            odometerMiles: 100,
          ),
        );
      }
      final currentReview = _unconfirmedReview(
        id: 'current_calibration',
        startedAt: DateTime.utc(2026, 7, 7, 8),
        startingOdometer: 1600,
        filteredGpsMiles: 120,
        odometerMiles: 100,
      );
      await store.saveReview(currentReview);
      controller.refreshGpsAssistanceCalibration(enabled: true);
      expect(controller.gpsAssistanceCalibrationMultiplier, 1);

      final confirmed = await controller.confirmOdometerReview(
        reviewId: currentReview.id,
        confirmedEndingOdometer: 1700,
        confirmedAt: currentReview.finishedAt.add(const Duration(minutes: 5)),
        userAcknowledgedReviewPrompt: true,
      );

      expect(confirmed, isTrue);
      expect(controller.gpsAssistanceCalibrationMultiplier, 1);
      expect(controller.calibrationReviewAcceptedForCurrentEvidence, isFalse);
      expect(controller.acceptGpsAssistanceCalibrationReview(), isFalse);
      expect(controller.gpsAssistanceCalibrationMultiplier, 1);
    },
  );

  test(
    'controller ignores poor GPS days when refreshing calibration',
    () async {
      final store = TripTrackingSessionStore.memory();
      final odometer = GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      );
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: odometer,
        clockNow: () => DateTime.utc(2026, 7, 10, 12),
      );
      addTearDown(controller.dispose);
      addTearDown(odometer.dispose);

      for (var day = 0; day < 7; day += 1) {
        await store.saveReview(
          _confirmedReview(
            id: 'poor_signal_calibration_$day',
            startedAt: DateTime.utc(2026, 7, 1 + day, 8),
            filteredGpsMiles: 110,
            odometerMiles: 100,
            diagnostics: day == 0
                ? const TripTrackingDiagnostics(
                    receivedSamples: 100,
                    acceptedSamples: 50,
                    dispositionCounts: {
                      TripSampleDisposition.acceptedDistance: 50,
                      TripSampleDisposition.rejectedAccuracy: 50,
                    },
                  )
                : const TripTrackingDiagnostics(
                    receivedSamples: 100,
                    acceptedSamples: 90,
                    dispositionCounts: {
                      TripSampleDisposition.acceptedDistance: 90,
                      TripSampleDisposition.rejectedAccuracy: 10,
                    },
                  ),
          ),
        );
      }

      controller.refreshGpsAssistanceCalibration(enabled: true);

      expect(controller.gpsAssistanceCalibrationMultiplier, 1);
      expect(
        controller.odometerCalibrationSignal().reasonCode,
        'needs_more_reviewed_days',
      );
      expect(controller.odometerCalibrationSignal().eligibleSampleCount, 6);
    },
  );

  test('controller excludes future-dated reviews from calibration', () async {
    final store = TripTrackingSessionStore.memory();
    final odometer = GlobalOdometerController(
      vehicleId: 'vehicle_1',
      initialReading: 1000,
    );
    final controller = TripTrackingController(
      sessionStore: store,
      odometer: odometer,
      clockNow: () => DateTime.utc(2026, 7, 18, 12),
    );
    addTearDown(controller.dispose);
    addTearDown(odometer.dispose);
    for (var day = 0; day < 7; day += 1) {
      await store.saveReview(
        _confirmedReview(
          id: 'current_calibration_$day',
          startedAt: DateTime.utc(2026, 7, 1 + day, 8),
          filteredGpsMiles: 110,
          odometerMiles: 100,
        ),
      );
    }
    await store.saveReview(
      _confirmedReview(
        id: 'future_calibration',
        startedAt: DateTime.utc(2099, 1, 1, 8),
        filteredGpsMiles: 200,
        odometerMiles: 100,
      ),
    );

    controller.refreshGpsAssistanceCalibration(enabled: true);
    expect(controller.gpsAssistanceCalibrationMultiplier, 1);
    expect(controller.acceptGpsAssistanceCalibrationReview(), isTrue);

    expect(controller.gpsAssistanceCalibrationMultiplier, closeTo(.9091, .001));
    expect(controller.odometerCalibrationSignal().eligibleSampleCount, 7);
  });

  test(
    'mid-trip calibration refresh waits for the next trip projection',
    () async {
      final store = TripTrackingSessionStore.memory();
      final odometer = GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      );
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: odometer,
        clockNow: () => DateTime.utc(2026, 7, 15, 12),
      );
      addTearDown(controller.dispose);
      addTearDown(odometer.dispose);

      final started = await controller.start(
        tripId: 'trip_calibration_freeze',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: driveStart,
      );
      expect(started, isTrue);
      expect(await controller.ingest(sample(-80, 0)), isNotNull);
      expect(await controller.ingest(sample(-79.985, 60)), isNotNull);
      expect(await controller.ingest(sample(-79.97, 120)), isNotNull);
      expect(await controller.ingest(sample(-79.955, 180)), isNotNull);
      final readingBeforeRefresh = odometer.reading;

      for (var day = 0; day < 7; day += 1) {
        await store.saveReview(
          _confirmedReview(
            id: 'active_freeze_calibration_$day',
            startedAt: DateTime.utc(2026, 7, 1 + day, 8),
            filteredGpsMiles: 110,
            odometerMiles: 100,
          ),
        );
      }
      controller.refreshGpsAssistanceCalibration(enabled: true);
      expect(controller.gpsAssistanceCalibrationMultiplier, 1);
      expect(controller.acceptGpsAssistanceCalibrationReview(), isTrue);
      expect(
        controller.gpsAssistanceCalibrationMultiplier,
        closeTo(.9091, .001),
      );

      expect(await controller.ingest(sample(-79.94, 240)), isNotNull);
      expect(await controller.ingest(sample(-79.925, 300)), isNotNull);
      expect(await controller.ingest(sample(-79.91, 360)), isNotNull);
      expect(await controller.ingest(sample(-79.895, 420)), isNotNull);
      final acceptedMeters = controller.acceptedMeters;
      final neutralProjection = TripLiveOdometerProjection(
        startingOdometer: 1000,
      );
      final recalibratedProjection = TripLiveOdometerProjection(
        startingOdometer: 1000,
      );
      final neutralReading = neutralProjection.updateAcceptedMeters(
        acceptedMeters,
      );
      final recalibratedReading = recalibratedProjection.updateAcceptedMeters(
        acceptedMeters,
        gpsAssistanceCalibrationMultiplier:
            controller.gpsAssistanceCalibrationMultiplier,
      );

      expect(odometer.reading, greaterThan(readingBeforeRefresh));
      expect(odometer.reading, neutralReading);
      expect(odometer.reading, isNot(recalibratedReading));
      final review = await controller.finishForReview(
        finishedAt: driveStart.add(const Duration(minutes: 25)),
      );
      expect(review, isNotNull);
      expect(review!.estimatedEndingOdometer, neutralReading);
      expect(odometer.confirmedReading, 1000);
    },
  );
}

TripTrackingReviewRecord _confirmedReview({
  required String id,
  required DateTime startedAt,
  int startingOdometer = 1000,
  required double filteredGpsMiles,
  required int odometerMiles,
  TripTrackingDiagnostics diagnostics = const TripTrackingDiagnostics(
    receivedSamples: 100,
    acceptedSamples: 90,
    dispositionCounts: {
      TripSampleDisposition.acceptedDistance: 90,
      TripSampleDisposition.rejectedAccuracy: 10,
    },
  ),
}) {
  return TripTrackingReviewRecord(
    id: id,
    vehicleId: 'vehicle_1',
    startingOdometer: startingOdometer,
    estimatedEndingOdometer: startingOdometer + odometerMiles,
    confirmedEndingOdometer: startingOdometer + odometerMiles,
    profile: TripTrackingProfile.roadVehicle,
    startedAt: startedAt,
    finishedAt: startedAt.add(const Duration(hours: 2)),
    odometerConfirmedAt: startedAt.add(const Duration(hours: 3)),
    engineSnapshot: TripTrackingEngineSnapshot(
      totalAcceptedMeters: filteredGpsMiles * 1609.344,
      walkingReviewSuggested: false,
      diagnostics: diagnostics,
    ),
  );
}

TripTrackingReviewRecord _unconfirmedReview({
  required String id,
  required DateTime startedAt,
  int startingOdometer = 1000,
  required double filteredGpsMiles,
  required int odometerMiles,
}) {
  return TripTrackingReviewRecord(
    id: id,
    vehicleId: 'vehicle_1',
    startingOdometer: startingOdometer,
    estimatedEndingOdometer: startingOdometer + odometerMiles,
    profile: TripTrackingProfile.roadVehicle,
    startedAt: startedAt,
    finishedAt: startedAt.add(const Duration(hours: 2)),
    engineSnapshot: TripTrackingEngineSnapshot(
      totalAcceptedMeters: filteredGpsMiles * 1609.344,
      walkingReviewSuggested: false,
      diagnostics: const TripTrackingDiagnostics(
        receivedSamples: 100,
        acceptedSamples: 90,
        dispositionCounts: {
          TripSampleDisposition.acceptedDistance: 90,
          TripSampleDisposition.rejectedAccuracy: 10,
        },
      ),
    ),
  );
}
