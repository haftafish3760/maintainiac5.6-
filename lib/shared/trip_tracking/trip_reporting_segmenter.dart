// odometerIsGlobalTruth: true.
import 'trip_tracking_session_store.dart';

enum TripReportingDistanceAllocation { elapsedTimeEstimate }

class TripReportingSegment {
  const TripReportingSegment({
    required this.id,
    required this.parentSessionId,
    required this.segmentIndex,
    required this.startedAt,
    required this.finishedAt,
    required this.allocatedGpsAssistedMeters,
    required this.allocation,
  });

  final String id;
  final String parentSessionId;
  final int segmentIndex;
  final DateTime startedAt;
  final DateTime finishedAt;
  final double allocatedGpsAssistedMeters;
  final TripReportingDistanceAllocation allocation;

  bool get isDerived => true;
  bool get ownsSourceTrip => false;
  bool get canConfirmMileage => false;
  bool get canChangeOdometer => false;
  bool get canWriteTripLog => false;

  Map<String, Object?> toSafeSummary() => {
    'id': id,
    'parentSessionId': parentSessionId,
    'segmentIndex': segmentIndex,
    'startedAt': startedAt.toUtc().toIso8601String(),
    'finishedAt': finishedAt.toUtc().toIso8601String(),
    'allocatedGpsAssistedMeters': allocatedGpsAssistedMeters,
    'allocation': allocation.name,
    'isDerived': true,
    'ownsSourceTrip': false,
    'canConfirmMileage': false,
    'canChangeOdometer': false,
    'canWriteTripLog': false,
    'coordinatesIncluded': false,
  };
}

class TripReportingSegmenter {
  const TripReportingSegmenter._();

  /// [reportingBoundariesUtc] are supplied by the timezone-aware calendar
  /// layer. This keeps DST and timezone policy out of the tracking engine.
  static List<TripReportingSegment> splitReview(
    TripTrackingReviewRecord review, {
    required Iterable<DateTime> reportingBoundariesUtc,
  }) {
    final startedAt = review.startedAt.toUtc();
    final finishedAt = review.finishedAt.toUtc();
    if (!review.hasValidTimeline ||
        review.id.trim().isEmpty ||
        !finishedAt.isAfter(startedAt)) {
      return const [];
    }
    final boundaries =
        reportingBoundariesUtc
            .map((value) => value.toUtc())
            .where(
              (value) => value.isAfter(startedAt) && value.isBefore(finishedAt),
            )
            .toSet()
            .toList(growable: false)
          ..sort();
    final points = <DateTime>[startedAt, ...boundaries, finishedAt];
    final totalMeters =
        review.engineSnapshot.totalAcceptedMeters.isFinite &&
            review.engineSnapshot.totalAcceptedMeters >= 0
        ? review.engineSnapshot.totalAcceptedMeters
        : 0.0;
    final totalMicros = finishedAt.difference(startedAt).inMicroseconds;
    var allocatedMeters = 0.0;
    final result = <TripReportingSegment>[];
    for (var index = 0; index < points.length - 1; index += 1) {
      final isLast = index == points.length - 2;
      final segmentMeters = isLast
          ? totalMeters - allocatedMeters
          : totalMeters *
                (points[index + 1].difference(points[index]).inMicroseconds /
                    totalMicros);
      allocatedMeters += segmentMeters;
      result.add(
        TripReportingSegment(
          id: '${review.id}:segment:${index + 1}',
          parentSessionId: review.id,
          segmentIndex: index + 1,
          startedAt: points[index],
          finishedAt: points[index + 1],
          allocatedGpsAssistedMeters: segmentMeters,
          allocation: TripReportingDistanceAllocation.elapsedTimeEstimate,
        ),
      );
    }
    return List.unmodifiable(result);
  }
}
