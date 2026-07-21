import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_reporting_segmenter.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  test(
    'multi-day reporting children preserve ancestry without double count',
    () {
      final startedAt = DateTime.utc(2026, 7, 20, 20);
      final finishedAt = DateTime.utc(2026, 7, 22, 8);
      final review = TripTrackingReviewRecord(
        id: 'multi_day_trip',
        vehicleId: 'vehicle_1',
        startingOdometer: 1000,
        estimatedEndingOdometer: 1180,
        profile: TripTrackingProfile.roadVehicle,
        startedAt: startedAt,
        finishedAt: finishedAt,
        engineSnapshot: const TripTrackingEngineSnapshot(
          totalAcceptedMeters: 180000,
          walkingReviewSuggested: false,
        ),
      );

      final segments = TripReportingSegmenter.splitReview(
        review,
        reportingBoundariesUtc: [
          DateTime.utc(2026, 7, 21),
          DateTime.utc(2026, 7, 22),
          DateTime.utc(2026, 7, 22),
          DateTime.utc(2026, 7, 19),
        ],
      );

      expect(segments, hasLength(3));
      expect(segments.map((item) => item.parentSessionId).toSet(), {review.id});
      expect(segments.first.startedAt, startedAt);
      expect(segments.last.finishedAt, finishedAt);
      expect(
        segments.fold<double>(
          0,
          (sum, item) => sum + item.allocatedGpsAssistedMeters,
        ),
        closeTo(180000, 0.000001),
      );
      expect(segments.every((item) => item.isDerived), isTrue);
      expect(segments.every((item) => !item.ownsSourceTrip), isTrue);
      expect(segments.every((item) => !item.canConfirmMileage), isTrue);
      expect(segments.every((item) => !item.canWriteTripLog), isTrue);
      expect(segments.first.toSafeSummary()['coordinatesIncluded'], isFalse);
    },
  );
}
