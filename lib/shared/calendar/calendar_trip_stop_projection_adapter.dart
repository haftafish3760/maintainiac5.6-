// Trip-stop Calendar projection. It renders only source-owned, user-confirmed
// manual stop events; Calendar never turns location evidence into work truth.

import '../trip_tracking/trip_tracking_session_store.dart';
import 'calendar_projection_contract.dart';

class CalendarTripStopProjectionAdapter {
  const CalendarTripStopProjectionAdapter._();

  static List<CalendarProjectionEvent> eventsForDay(
    Iterable<TripTrackingReviewRecord> reviews,
    DateTime day,
  ) => CalendarProjectionTimeline.normalize(
    reviews.expand((review) {
      return review.tripEvents
          .where((event) => event.isValid)
          .where((event) => _isStopEvent(event.type))
          .where(
            (event) => _sameDay(
              _businessDay(
                event.occurredAt,
                review.startedTimeZoneOffsetMinutes,
              ),
              day,
            ),
          )
          .map((event) => fromReviewEvent(review: review, event: event));
    }),
  );

  static CalendarProjectionEvent fromReviewEvent({
    required TripTrackingReviewRecord review,
    required TripManualEvent event,
  }) {
    if (!event.isValid || !_isStopEvent(event.type)) {
      throw ArgumentError(
        'Calendar stops require a valid, confirmed stop event.',
      );
    }
    return CalendarProjectionEvent(
      eventId: 'trip-stop:${event.id}',
      source: CalendarProjectionSource.stop,
      sourceRecordId: event.id,
      timing: CalendarProjectionTiming(
        eventDate: _businessDay(
          event.occurredAt,
          review.startedTimeZoneOffsetMinutes,
        ),
        actualAt: event.occurredAt,
        recordedAt: event.recordedAt ?? event.occurredAt,
        timeSource: CalendarTimeSource.actual,
        timezoneId: review.startedTimeZoneName,
        actualTimezoneOffsetMinutes: _stableOffsetFor(review),
        recordedTimezoneOffsetMinutes: _stableOffsetFor(review),
      ),
      title: _titleFor(event.type),
      conciseDetail: _detailFor(event),
      state: CalendarProjectionState.confirmed,
      sourceRecordStatus: 'user-confirmed trip event',
      revision: review.revision < 0 ? 0 : review.revision,
      deepLink: CalendarProjectionDeepLink(
        target: CalendarDeepLinkTarget.stopReview,
        sourceRecordId: event.id,
        argumentId: review.id,
      ),
      vehicleIds: [review.vehicleId],
      workProfileId: review.effectiveProfileId,
      evidence: CalendarProjectionEvidence(
        evidenceId: review.id,
        summary: 'User-confirmed ${_titleFor(event.type).toLowerCase()}.',
        strength: 'user-confirmed trip event',
        explanation:
            'This confirms the recorded stop event, not that a job or service was completed.',
      ),
      auditReference: 'Trip review ${review.id} · revision ${review.revision}',
    );
  }
}

bool _isStopEvent(TripManualEventType type) => switch (type) {
  TripManualEventType.pickup ||
  TripManualEventType.dropoff ||
  TripManualEventType.stop ||
  TripManualEventType.workStop ||
  TripManualEventType.fuelStop ||
  TripManualEventType.loading ||
  TripManualEventType.unloading ||
  TripManualEventType.customerWait ||
  TripManualEventType.jobSite ||
  TripManualEventType.breakTime ||
  TripManualEventType.personalInterruption => true,
  TripManualEventType.note || TripManualEventType.other => false,
};

String _titleFor(TripManualEventType type) => switch (type) {
  TripManualEventType.pickup => 'Pickup stop',
  TripManualEventType.dropoff => 'Drop-off stop',
  TripManualEventType.stop => 'Recorded stop',
  TripManualEventType.workStop => 'Work stop',
  TripManualEventType.fuelStop => 'Fuel stop',
  TripManualEventType.loading => 'Loading stop',
  TripManualEventType.unloading => 'Unloading stop',
  TripManualEventType.customerWait => 'Customer wait',
  TripManualEventType.jobSite => 'Job-site stop',
  TripManualEventType.breakTime => 'Break',
  TripManualEventType.personalInterruption => 'Personal interruption',
  TripManualEventType.note || TripManualEventType.other => 'Trip event',
};

String _detailFor(TripManualEvent event) {
  final note = event.note?.trim() ?? '';
  return note.isEmpty ? 'User-confirmed trip event' : note;
}

DateTime _businessDay(DateTime value, int offsetMinutes) {
  final wallClock = value.toUtc().add(Duration(minutes: offsetMinutes));
  return DateTime(wallClock.year, wallClock.month, wallClock.day);
}

bool _sameDay(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;

/// Manual stop events do not retain their own offset. A trip that crossed a
/// DST boundary therefore cannot safely inherit either endpoint's offset.
int? _stableOffsetFor(TripTrackingReviewRecord review) =>
    review.startedTimeZoneOffsetMinutes == review.finishedTimeZoneOffsetMinutes
    ? review.startedTimeZoneOffsetMinutes
    : null;
