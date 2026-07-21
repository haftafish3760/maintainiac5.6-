import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_boundary_candidate.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';

TripTrackingAdvisoryEvent advisory({
  required String id,
  required TripTrackingAdvisoryType type,
  TripTrackingAdvisoryDisposition disposition =
      TripTrackingAdvisoryDisposition.pending,
}) {
  final detectedAt = DateTime.utc(2026, 7, 21, 12, 5);
  return TripTrackingAdvisoryEvent(
    id: id,
    type: type,
    sessionId: 'trip_1',
    vehicleId: 'vehicle_1',
    profile: TripTrackingProfile.deliveryVehicle,
    detectedAt: detectedAt,
    evidenceStartedAt: detectedAt.subtract(const Duration(minutes: 2)),
    evidenceEndedAt: detectedAt,
    confidence: TripTrackingConfidence.high,
    suggestedAction: 'review_stop',
    disposition: disposition,
  );
}

void main() {
  test('only pending probable stops become review-only boundaries', () {
    final candidates = TripBoundaryCandidateResolver.fromAdvisories([
      advisory(id: 'pending', type: TripTrackingAdvisoryType.probableStop),
      advisory(id: 'movement', type: TripTrackingAdvisoryType.resumedMovement),
      advisory(
        id: 'confirmed',
        type: TripTrackingAdvisoryType.probableStop,
        disposition: TripTrackingAdvisoryDisposition.confirmed,
      ),
    ]);

    expect(candidates, hasLength(1));
    final candidate = candidates.single;
    expect(candidate.sourceAdvisoryId, 'pending');
    expect(candidate.requiresUserReview, isTrue);
    expect(candidate.canFinalizeTrip, isFalse);
    expect(candidate.canSplitTripAutomatically, isFalse);
    expect(candidate.canChangeMileage, isFalse);
    expect(candidate.canWriteTripLog, isFalse);
    expect(candidate.toSafeSummary()['coordinatesIncluded'], isFalse);
  });
}
