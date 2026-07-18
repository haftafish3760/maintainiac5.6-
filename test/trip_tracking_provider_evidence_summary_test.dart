import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_provider_evidence_summary.dart';

void main() {
  final recordedAt = DateTime.utc(2026, 7, 18, 12);

  test('GPS evidence summary is coordinate-free and advisory only', () {
    final summary =
        TripLocationSample(
          latitude: 35.123456,
          longitude: -80.123456,
          recordedAt: recordedAt,
          horizontalAccuracyMeters: 8,
          speedMetersPerSecond: 12,
          mockedLocation: true,
        ).toEvidenceBoundarySummary(
          receivedAtUtc: recordedAt.add(const Duration(minutes: 1)),
        );

    expect(summary['evidenceType'], 'gps_location_sample');
    expect(summary['hasValidCoordinate'], isTrue);
    expect(summary['accuracyBucket'], 'high');
    expect(summary['speedBucket'], 'road_speed');
    expect(summary['timestampBucket'], 'fresh');
    expect(summary['mockedLocationReported'], isTrue);
    expect(summary['trustedAfterValidationOnly'], isTrue);
    expect(summary['canCreateOfficialMileage'], isFalse);
    expect(summary['canOverrideOdometer'], isFalse);
    expect(summary['canCreateOfficialStop'], isFalse);
    expect(summary['mapboxCanOverrideSample'], isFalse);
    expect(summary['firestoreCanOverrideSample'], isFalse);
    expect(summary['rawLatitudeIncluded'], isFalse);
    expect(summary['rawLongitudeIncluded'], isFalse);
    expect(summary['rawTimestampIncluded'], isFalse);
    expect(summary['rawProviderPayloadIncluded'], isFalse);
    expect(summary['tokensIncluded'], isFalse);
    expect(summary.toString(), isNot(contains('35.123456')));
    expect(summary.toString(), isNot(contains('-80.123456')));
  });

  test('malformed GPS evidence summaries fail into untrusted buckets', () {
    final summary = TripLocationSample(
      latitude: double.nan,
      longitude: -181,
      recordedAt: recordedAt.add(const Duration(minutes: 1)),
      horizontalAccuracyMeters: double.infinity,
      speedMetersPerSecond: double.nan,
    ).toEvidenceBoundarySummary(receivedAtUtc: recordedAt);

    expect(summary['hasValidCoordinate'], isFalse);
    expect(summary['hasValidAccuracy'], isFalse);
    expect(summary['accuracyBucket'], 'invalid');
    expect(summary['speedBucket'], 'invalid');
    expect(summary['timestampBucket'], 'future');
    expect(summary['canCreateOfficialMileage'], isFalse);
    expect(summary.toString(), isNot(contains('NaN')));
  });

  test('activity evidence summary cannot create official stops', () {
    final summary = TripActivityObservation(
      activity: TripActivity.walking,
      confidence: 92,
      recordedAt: recordedAt,
    ).toEvidenceBoundarySummary();

    expect(summary['evidenceType'], 'activity_observation');
    expect(summary['confidenceBucket'], 'high');
    expect(summary['activityRecognitionRequiresOptIn'], isTrue);
    expect(summary['canSupportStopReview'], isTrue);
    expect(summary['canCreateOfficialStop'], isFalse);
    expect(summary['canEndTripAutomatically'], isFalse);
    expect(summary['canOverrideOdometer'], isFalse);
    expect(summary['requiresAcceptedVehicleMovement'], isTrue);
    expect(summary['rawSensorPayloadIncluded'], isFalse);
    expect(summary['preciseTimestampIncluded'], isFalse);
    expect(summary['tokensIncluded'], isFalse);
  });
}
