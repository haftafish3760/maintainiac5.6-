import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_field_trial_summary.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  test(
    'field summary compares GPS with confirmed odometer without coordinates',
    () {
      final now = DateTime.utc(2026, 7, 22, 12);
      final review = TripTrackingReviewRecord(
        id: 'field_trial',
        vehicleId: 'vehicle_1',
        startingOdometer: 1000,
        estimatedEndingOdometer: 1010,
        confirmedEndingOdometer: 1011,
        odometerConfirmedAt: now.add(const Duration(hours: 2)),
        profile: TripTrackingProfile.roadVehicle,
        profileId: 'profile_1',
        startedAt: now,
        finishedAt: now.add(const Duration(hours: 1)),
        engineSnapshot: const TripTrackingEngineSnapshot(
          totalAcceptedMeters: 16093.44,
          walkingReviewSuggested: false,
          diagnostics: TripTrackingDiagnostics(
            receivedSamples: 12,
            acceptedSamples: 10,
            rejectedDistanceMeters: 160.9344,
            estimatedGapDistanceMeters: 80.4672,
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
        ],
        recoveryCount: 1,
      );

      final summary = TripTrackingFieldTrialSummary.fromReview(review);
      expect(summary.gpsAssistedMiles, closeTo(10, 0.0001));
      expect(summary.odometerMiles, 11);
      expect(summary.absoluteDifferenceMiles, closeTo(1, 0.0001));
      expect(summary.rejectedSamples, 2);
      expect(summary.confirmedStopCount, 1);
      expect(summary.recoveryCount, 1);
      expect(summary.toSafeSummary()['coordinatesIncluded'], isFalse);
      expect(summary.toSafeSummary()['odometerIsOfficial'], isTrue);
      expect(summary.toSafeSummary()['gpsCanConfirmMileage'], isFalse);
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
    expect(summary.absoluteDifferenceMiles, isNull);
    expect(summary.toSafeSummary()['absoluteDifferenceMiles'], isNull);
  });
}
