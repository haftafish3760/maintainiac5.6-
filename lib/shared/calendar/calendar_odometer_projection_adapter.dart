// Odometer Calendar projection. Odometer owns history and global truth;
// Calendar only presents recorded corrections without changing a reading.

import '../odometer/odometer_correction_review.dart';
import '../odometer/odometer_validation.dart';
import 'calendar_projection_contract.dart';

class CalendarOdometerProjectionAdapter {
  const CalendarOdometerProjectionAdapter._();

  static List<CalendarProjectionEvent> eventsForDay({
    required String vehicleId,
    required Iterable<OdometerReadingEvent> history,
    required DateTime day,
  }) => CalendarProjectionTimeline.normalize(
    history
        .where((event) => event.id.trim().isNotEmpty)
        .where((event) => _sameDay(event.recordedAt, day))
        .map((event) => fromEvent(vehicleId: vehicleId, event: event)),
  );

  static CalendarProjectionEvent fromEvent({
    required String vehicleId,
    required OdometerReadingEvent event,
  }) {
    if (event.id.trim().isEmpty) {
      throw ArgumentError.value(event.id, 'event.id', 'must not be empty');
    }
    final correction = event.correctionReview;
    final unresolved =
        correction?.reason == OdometerCorrectionReason.unresolved;
    return CalendarProjectionEvent(
      eventId: 'odometer:${event.id}',
      source: CalendarProjectionSource.odometer,
      sourceRecordId: event.id,
      timing: CalendarProjectionTiming(
        eventDate: event.recordedAt,
        recordedAt: event.recordedAt,
        timeSource: CalendarTimeSource.recorded,
      ),
      title: correction == null ? 'Odometer reading' : 'Odometer correction',
      conciseDetail: _detailFor(event),
      state: unresolved
          ? CalendarProjectionState.needsReview
          : event.affectsCurrentReading
          ? CalendarProjectionState.confirmed
          : CalendarProjectionState.historical,
      sourceRecordStatus: unresolved
          ? 'correction reason unresolved'
          : event.affectsCurrentReading
          ? 'confirmed odometer history'
          : 'historical odometer history',
      revision: _revisionFor(event),
      deepLink: CalendarProjectionDeepLink(
        target: CalendarDeepLinkTarget.odometerDetail,
        sourceRecordId: event.id,
      ),
      vehicleIds: [vehicleId],
      workProfileId: _emptyToNull(event.workProfileId),
      evidence: CalendarProjectionEvidence(
        evidenceId: _emptyToNull(event.sourceId),
        summary: _summaryFor(event),
        strength: 'source-recorded odometer entry',
        explanation: unresolved
            ? 'The Odometer owner requires a correction reason before this entry can be treated as resolved history.'
            : 'Confirmed odometer remains the global mileage truth.',
      ),
      auditReference: 'Recorded ${event.recordedAt.toIso8601String()}',
    );
  }
}

String _detailFor(OdometerReadingEvent event) {
  final prior = event.previousReading;
  final correction = event.correctionReview;
  final reading = prior == null
      ? '${event.reading} mi'
      : '$prior mi → ${event.reading} mi';
  return correction == null ? reading : '$reading · ${correction.reason.label}';
}

String _summaryFor(OdometerReadingEvent event) {
  final source = _emptyToNull(event.sourceType);
  return source == null
      ? 'Odometer entry recorded by the Odometer owner.'
      : 'Odometer entry recorded from $source.';
}

int _revisionFor(OdometerReadingEvent event) =>
    event.recordedAt.microsecondsSinceEpoch < 0
    ? 0
    : event.recordedAt.microsecondsSinceEpoch;

String? _emptyToNull(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}

bool _sameDay(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;
