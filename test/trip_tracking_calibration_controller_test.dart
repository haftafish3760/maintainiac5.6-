import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  test(
    'controller refreshes opt-in calibration from reviewed history',
    () async {
      final store = TripTrackingSessionStore.memory();
      final odometer = GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      );
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: odometer,
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

      expect(
        controller.gpsAssistanceCalibrationMultiplier,
        closeTo(.9091, .001),
      );
      controller.refreshGpsAssistanceCalibration(enabled: false);
      expect(controller.gpsAssistanceCalibrationMultiplier, 1);
    },
  );

  test(
    'confirmed odometer review refreshes enabled calibration immediately',
    () async {
      final store = TripTrackingSessionStore.memory();
      final odometer = GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1600,
      );
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: odometer,
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
      );

      expect(confirmed, isTrue);
      expect(
        controller.gpsAssistanceCalibrationMultiplier,
        closeTo(.8974, .001),
      );
    },
  );
}

TripTrackingReviewRecord _confirmedReview({
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
    confirmedEndingOdometer: startingOdometer + odometerMiles,
    profile: TripTrackingProfile.roadVehicle,
    startedAt: startedAt,
    finishedAt: startedAt.add(const Duration(hours: 2)),
    odometerConfirmedAt: startedAt.add(const Duration(hours: 3)),
    engineSnapshot: TripTrackingEngineSnapshot(
      totalAcceptedMeters: filteredGpsMiles * 1609.344,
      walkingReviewSuggested: false,
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
    ),
  );
}
