import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';

void main() {
  test(
    'out-of-range activity confidence cannot support walking-stop evidence',
    () {
      final observation = TripActivityObservation(
        activity: TripActivity.walking,
        confidence: 999,
        recordedAt: DateTime.utc(2026, 7, 18, 12),
      );
      final summary = observation.toSafeSummary();

      expect(observation.isHighConfidenceWalking, isFalse);
      expect(observation.canSupportStopReview, isFalse);
      expect(summary['confidenceBucket'], 'unknown');
      expect(summary['advisoryOnly'], isTrue);
      expect(summary['activityRecognitionRequiresOptIn'], isTrue);
      expect(summary['activityCanCreateOfficialStop'], isFalse);
      expect(summary['activityCanEndTripAutomatically'], isFalse);
      expect(summary['requiresAcceptedVehicleMovement'], isTrue);
      expect(summary['minimumTrustedSensorYear'], 2020);
      expect(summary['walkingEvidenceCanOnlySuggestReview'], isTrue);
      expect(summary['odometerRemainsCanonical'], isTrue);
      expect(summary['rawSensorPayloadIncluded'], isFalse);
      expect(summary['preciseTimestampIncluded'], isFalse);
      expect(summary['preciseLocationIncluded'], isFalse);
    },
  );

  test('native activity parsing rejects malformed confidence before use', () {
    final accepted = TripActivityObservation.tryFromMap({
      'activity': 'walking',
      'confidence': 95,
      'recordedAt': DateTime.utc(2026, 7, 18, 12).toIso8601String(),
    });
    final rejected = TripActivityObservation.tryFromMap({
      'activity': 'walking',
      'confidence': 101,
      'recordedAt': DateTime.utc(2026, 7, 18, 12).toIso8601String(),
    });

    expect(accepted?.isHighConfidenceWalking, isTrue);
    expect(rejected, isNull);
  });

  test('high confidence walking stays advisory and review gated', () {
    final observation = TripActivityObservation(
      activity: TripActivity.walking,
      confidence: 95,
      recordedAt: DateTime.utc(2026, 7, 18, 12),
    );
    final summary = observation.toSafeSummary();

    expect(observation.canSupportStopReview, isTrue);
    expect(summary['confidenceBucket'], 'high');
    expect(summary['activityCanCreateOfficialStop'], isFalse);
    expect(summary['activityCanEndTripAutomatically'], isFalse);
    expect(summary['walkingEvidenceCanOnlySuggestReview'], isTrue);
    expect(summary['rawSensorPayloadIncluded'], isFalse);
  });
}
