import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_field_trial_summary.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';

void main() {
  test(
    'field summary compares GPS with confirmed odometer without coordinates',
    () {
      final now = DateTime.utc(2026, 7, 22, 12);
      final review = TripTrackingReviewRecord(
        id: 'field_trial',
        vehicleId: 'vehicle_1',
        gpsAssistanceCalibrationMultiplier: 1.02,
        startingOdometer: 1000,
        estimatedEndingOdometer: 1010,
        confirmedEndingOdometer: 1011,
        odometerConfirmedAt: now.add(const Duration(hours: 2)),
        profile: TripTrackingProfile.roadVehicle,
        profileId: 'profile_1',
        startedAt: now,
        finishedAt: now.add(const Duration(hours: 1)),
        engineSnapshot: TripTrackingEngineSnapshot(
          totalAcceptedMeters: 16093.44,
          walkingReviewSuggested: false,
          diagnostics: const TripTrackingDiagnostics(
            receivedSamples: 12,
            acceptedSamples: 10,
            rejectedDistanceMeters: 160.9344,
            estimatedGapDistanceMeters: 80.4672,
          ),
          initialFixAssessment: TripInitialFixAssessment(
            quality: TripInitialFixQuality.freshPrecise,
            assessedAt: now,
            confidence: TripTrackingConfidence.high,
            mayUseProvisionally: true,
          ),
        ),
        advisories: [
          TripTrackingAdvisoryEvent(
            id: 'stop_1',
            type: TripTrackingAdvisoryType.probableStop,
            sessionId: 'field_trial',
            vehicleId: 'vehicle_1',
            profile: TripTrackingProfile.roadVehicle,
            detectedAt: now,
            evidenceStartedAt: now,
            evidenceEndedAt: now,
            confidence: TripTrackingConfidence.high,
            suggestedAction: 'review',
            disposition: TripTrackingAdvisoryDisposition.confirmed,
          ),
          TripTrackingAdvisoryEvent(
            id: 'stop_2',
            type: TripTrackingAdvisoryType.probableStop,
            sessionId: 'field_trial',
            vehicleId: 'vehicle_1',
            profile: TripTrackingProfile.roadVehicle,
            detectedAt: now.add(const Duration(minutes: 30)),
            evidenceStartedAt: now.add(const Duration(minutes: 30)),
            evidenceEndedAt: now.add(const Duration(minutes: 31)),
            confidence: TripTrackingConfidence.medium,
            suggestedAction: 'review',
          ),
        ],
        recoveryCount: 1,
      );

      final summary = TripTrackingFieldTrialSummary.fromReview(review);
      expect(summary.gpsAssistedMiles, closeTo(10, 0.0001));
      expect(summary.calibrationAdjustedGpsMiles, closeTo(10.2, 0.0001));
      expect(summary.odometerMiles, 11);
      expect(summary.signedDifferenceMiles, closeTo(-1, 0.0001));
      expect(summary.calibrationAdjustedDifferenceMiles, closeTo(-0.8, 0.0001));
      expect(summary.absoluteDifferenceMiles, closeTo(1, 0.0001));
      expect(summary.rejectedSamples, 2);
      expect(summary.confirmedStopCount, 1);
      expect(summary.probableStopCount, 2);
      expect(summary.unresolvedStopCount, 1);
      expect(summary.recoveryCount, 1);
      expect(summary.durationMinutes, 60);
      expect(summary.initialFixQuality, 'freshPrecise');
      expect(summary.initialFixQualityLabel, 'fresh precise');
      expect(summary.algorithmVersion, 'gps-v1');
      expect(summary.vehicleConfigurationRevision, 0);
      expect(summary.gpsAssistanceCalibrationMultiplier, 1.02);
      expect(summary.acceptedSamplePercent, closeTo(83.333, 0.001));
      expect(summary.toSafeSummary()['coordinatesIncluded'], isFalse);
      expect(summary.toSafeSummary()['odometerIsOfficial'], isTrue);
      expect(summary.toSafeSummary()['gpsCanConfirmMileage'], isFalse);
      expect(summary.toSafeSummary()['signedDifferenceMiles'], -1);
      expect(summary.toSafeSummary()['durationMinutes'], 60);
      expect(summary.toSafeSummary()['acceptedSamplePercent'], 83.333);
      expect(summary.toSafeSummary()['algorithmVersion'], 'gps-v1');
      expect(
        summary.toSafeSummary()['gpsAssistanceCalibrationMultiplier'],
        1.02,
      );
      expect(summary.toPlainText(), contains('multiplier: 1.0200'));
      expect(
        summary.toPlainText(),
        contains('Measured GPS vs odometer: -1.00 mi'),
      );
      expect(
        summary.toPlainText(),
        contains('GPS estimate after calibration: 10.20 mi'),
      );
      expect(summary.toPlainText(), contains('unresolved: 1'));
      expect(summary.toPlainText(), isNot(contains('latitude')));
      expect(summary.toPlainText(), isNot(contains('longitude')));
      expect(summary.toPlainText(), isNot(contains('route geometry')));
    },
  );

  test('unconfirmed odometer never invents an accuracy difference', () {
    final now = DateTime.utc(2026, 7, 22, 12);
    final review = TripTrackingReviewRecord(
      id: 'unconfirmed_field_trial',
      vehicleId: 'vehicle_1',
      startingOdometer: 1000,
      estimatedEndingOdometer: 1001,
      profile: TripTrackingProfile.roadVehicle,
      profileId: 'profile_1',
      startedAt: now,
      finishedAt: now.add(const Duration(minutes: 10)),
      engineSnapshot: const TripTrackingEngineSnapshot(
        totalAcceptedMeters: 1609.344,
        walkingReviewSuggested: false,
      ),
    );

    final summary = TripTrackingFieldTrialSummary.fromReview(review);
    expect(summary.odometerMiles, isNull);
    expect(summary.signedDifferenceMiles, isNull);
    expect(summary.absoluteDifferenceMiles, isNull);
    expect(summary.toSafeSummary()['absoluteDifferenceMiles'], isNull);
  });

  test(
    'controller selects the latest review only for the requested vehicle',
    () async {
      final now = DateTime.utc(2026, 7, 22, 12);
      final store = TripTrackingSessionStore.memory();
      await store.saveReview(_simpleReview('older_current', 'vehicle_1', now));
      await store.saveReview(
        _simpleReview(
          'newer_foreign',
          'vehicle_2',
          now.add(const Duration(hours: 2)),
        ),
      );
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

      expect(controller.latestReview?.id, 'newer_foreign');
      expect(
        controller.latestReviewForVehicle('vehicle_1')?.id,
        'older_current',
      );
      expect(controller.latestReviewForVehicle('missing'), isNull);
      expect(controller.latestReviewForVehicle('  '), isNull);
    },
  );
}

TripTrackingReviewRecord _simpleReview(
  String id,
  String vehicleId,
  DateTime finishedAt,
) => TripTrackingReviewRecord(
  id: id,
  vehicleId: vehicleId,
  startingOdometer: 1000,
  estimatedEndingOdometer: 1001,
  profile: TripTrackingProfile.roadVehicle,
  profileId: TripTrackingProfile.roadVehicle.name,
  startedAt: finishedAt.subtract(const Duration(minutes: 10)),
  finishedAt: finishedAt,
  engineSnapshot: const TripTrackingEngineSnapshot(
    totalAcceptedMeters: 1609.344,
    walkingReviewSuggested: false,
  ),
);
