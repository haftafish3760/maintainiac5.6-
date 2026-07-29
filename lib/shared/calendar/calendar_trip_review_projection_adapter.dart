// Trip-review Calendar projection. It reads GPS review records only; the Trip
// owner remains responsible for confirmation, persistence, and review routes.

import '../trip_tracking/trip_tracking_session_store.dart';
import 'calendar_projection_contract.dart';

class CalendarTripReviewProjectionAdapter {
  const CalendarTripReviewProjectionAdapter._();

  static List<CalendarProjectionEvent> eventsForDay(
    Iterable<TripTrackingReviewRecord> reviews,
    DateTime day,
  ) => CalendarProjectionTimeline.normalize(
    reviews
        .where((review) => _overlapsBusinessDay(review, day))
        .map((review) => fromReview(review, day: day)),
  );

  static CalendarProjectionEvent fromReview(
    TripTrackingReviewRecord review, {
    DateTime? day,
  }) {
    final continuesFromPreviousDay =
        day != null &&
        !_sameDay(
          _businessDay(review.startedAt, review.startedTimeZoneOffsetMinutes),
          day,
        );
    final proposed =
        review.tripLogProposalState == TripTrackingTripLogProposalState.pending;
    final timelineBlocked = !review.hasValidTimeline;
    return CalendarProjectionEvent(
      eventId: 'trip-review:${review.id}',
      source: CalendarProjectionSource.trip,
      sourceRecordId: review.id,
      timing: CalendarProjectionTiming(
        eventDate: _businessDay(
          review.startedAt,
          review.startedTimeZoneOffsetMinutes,
        ),
        actualAt: review.startedAt,
        recordedAt: review.finishedAt,
        timeSource: CalendarTimeSource.actual,
        timezoneId: review.startedTimeZoneName,
        actualTimezoneOffsetMinutes: review.startedTimeZoneOffsetMinutes,
        recordedTimezoneOffsetMinutes: review.finishedTimeZoneOffsetMinutes,
      ),
      title: 'GPS-assisted trip review',
      conciseDetail: continuesFromPreviousDay
          ? 'Continues from previous day · review required'
          : 'GPS-assisted trip · review required',
      state: timelineBlocked
          ? CalendarProjectionState.blocked
          : proposed
          ? CalendarProjectionState.proposed
          : CalendarProjectionState.needsReview,
      sourceRecordStatus: timelineBlocked
          ? 'timeline unavailable'
          : proposed
          ? 'trip-log proposal pending'
          : 'source review required',
      revision: review.revision < 0 ? 0 : review.revision,
      deepLink: CalendarProjectionDeepLink(
        target: CalendarDeepLinkTarget.tripReview,
        sourceRecordId: review.id,
      ),
      vehicleIds: [review.vehicleId],
      workProfileId: review.effectiveProfileId,
      evidence: CalendarProjectionEvidence(
        proposalId: proposed ? review.id : null,
        summary: _evidenceSummary(review),
        strength: 'GPS-assisted evidence; requires review',
        explanation:
            'GPS evidence can suggest a trip, but it does not confirm business work or official mileage.',
        acceptanceImpact:
            'The Trip owner can create or update its source-owned review outcome.',
        ignoreImpact:
            'This GPS-assisted proposal remains unconfirmed and does not become business truth.',
      ),
      auditReference:
          'Trip review revision ${review.revision} · finished ${review.finishedAt.toIso8601String()}',
    );
  }
}

bool _overlapsBusinessDay(TripTrackingReviewRecord review, DateTime day) {
  final target = _dateOnly(day);
  final start = _businessDay(
    review.startedAt,
    review.startedTimeZoneOffsetMinutes,
  );
  final end = _businessDay(
    review.finishedAt,
    review.finishedTimeZoneOffsetMinutes,
  );
  return !target.isBefore(start) && !target.isAfter(end);
}

DateTime _businessDay(DateTime value, int offsetMinutes) {
  final wallClock = value.toUtc().add(Duration(minutes: offsetMinutes));
  return DateTime(wallClock.year, wallClock.month, wallClock.day);
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

bool _sameDay(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;

String _evidenceSummary(TripTrackingReviewRecord review) {
  final gpsMeters = review.engineSnapshot.totalAcceptedMeters;
  final gapMeters =
      review.engineSnapshot.diagnostics.estimatedGapDistanceMeters;
  return 'GPS-assisted distance ${gpsMeters.toStringAsFixed(0)} m; estimated signal gap ${gapMeters.toStringAsFixed(0)} m.';
}
