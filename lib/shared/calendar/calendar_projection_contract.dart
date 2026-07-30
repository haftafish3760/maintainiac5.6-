// Calendar projection contract. The Calendar is a read-only chronological
// projection; source modules retain record ownership and detail routing.

enum CalendarProjectionSource {
  activeWorkday,
  trip,
  stop,
  job,
  expense,
  receipt,
  invoice,
  estimate,
  payment,
  maintenance,
  inventory,
  reminder,
  calendarSchedule,
  workTime,
  odometer,
  vehicleProfile,
}

enum CalendarProjectionState {
  confirmed,
  proposed,
  needsReview,
  rejected,
  voided,
  historical,
  incomplete,
  blocked,
}

enum CalendarTimeSource { actual, recorded, scheduled, unknown }

/// A source-owned use classification, when the record supports one. Calendar
/// only uses it to filter the read-only projection; it never infers or edits it.
enum CalendarBusinessClassification { business, personal, mixed, unclassified }

enum CalendarDeepLinkTarget {
  activeWorkday,
  tripReview,
  stopReview,
  jobDetail,
  expenseDetail,
  receiptDetail,
  invoiceDetail,
  estimateDetail,
  paymentDetail,
  maintenanceDetail,
  inventoryDetail,
  reminderDetail,
  calendarScheduleDetail,
  workTimeDetail,
  odometerDetail,
  vehicleProfileDetail,
}

/// A source-owned route. Calendar may navigate to it but must not edit the
/// source record through a generic calendar editor.
class CalendarProjectionDeepLink {
  const CalendarProjectionDeepLink({
    required this.target,
    required this.sourceRecordId,
    this.argumentId,
  }) : assert(sourceRecordId != '');

  final CalendarDeepLinkTarget target;
  final String sourceRecordId;

  /// Optional source-owned child identifier, such as a review/proposal ID.
  final String? argumentId;
}

/// Timing is deliberately explicit so recorded/entered time is never rendered
/// as the time an expense, service, trip, or appointment actually occurred.
class CalendarProjectionTiming {
  CalendarProjectionTiming({
    required DateTime eventDate,
    required this.recordedAt,
    required this.timeSource,
    this.actualAt,
    this.scheduledAt,
    this.scheduledEndAt,
    this.timezoneId,
    this.actualTimezoneOffsetMinutes,
    this.recordedTimezoneOffsetMinutes,
    this.scheduledTimezoneOffsetMinutes,
  }) : eventDate = _dateOnly(eventDate) {
    if (timeSource == CalendarTimeSource.actual && actualAt == null) {
      throw ArgumentError.value(
        actualAt,
        'actualAt',
        'Actual time is required when timeSource is actual.',
      );
    }
    if (timeSource == CalendarTimeSource.scheduled && scheduledAt == null) {
      throw ArgumentError.value(
        scheduledAt,
        'scheduledAt',
        'Scheduled time is required when timeSource is scheduled.',
      );
    }
    if (scheduledEndAt != null && scheduledAt == null) {
      throw ArgumentError.value(
        scheduledEndAt,
        'scheduledEndAt',
        'A planned end requires a scheduled start time.',
      );
    }
    if (scheduledEndAt != null && !scheduledEndAt!.isAfter(scheduledAt!)) {
      throw ArgumentError.value(
        scheduledEndAt,
        'scheduledEndAt',
        'A planned end must be after the scheduled start time.',
      );
    }
    for (final offset in [
      actualTimezoneOffsetMinutes,
      recordedTimezoneOffsetMinutes,
      scheduledTimezoneOffsetMinutes,
    ]) {
      if (offset != null && (offset < -14 * 60 || offset > 14 * 60)) {
        throw ArgumentError.value(
          offset,
          'timezone offset',
          'must be between UTC-14:00 and UTC+14:00.',
        );
      }
    }
  }

  final DateTime eventDate;
  final DateTime recordedAt;
  final CalendarTimeSource timeSource;
  final DateTime? actualAt;
  final DateTime? scheduledAt;
  final DateTime? scheduledEndAt;

  /// IANA zone when the source has it; null means the source did not retain it.
  final String? timezoneId;

  /// Source wall-clock offsets, retained separately because a trip can cross
  /// a daylight-saving boundary between its actual and recorded timestamps.
  final int? actualTimezoneOffsetMinutes;
  final int? recordedTimezoneOffsetMinutes;
  final int? scheduledTimezoneOffsetMinutes;

  DateTime get chronologicalTime => switch (timeSource) {
    CalendarTimeSource.actual => actualAt!,
    CalendarTimeSource.scheduled => scheduledAt!,
    CalendarTimeSource.recorded || CalendarTimeSource.unknown => recordedAt,
  };

  String get displayTimeLabel => switch (timeSource) {
    CalendarTimeSource.actual => 'Actual time',
    CalendarTimeSource.recorded => 'Recorded time',
    CalendarTimeSource.scheduled => 'Scheduled time',
    CalendarTimeSource.unknown => 'Time not recorded',
  };

  DateTime displayActualAt(DateTime value) =>
      _withSourceOffset(value, actualTimezoneOffsetMinutes);

  DateTime displayRecordedAt(DateTime value) =>
      _withSourceOffset(value, recordedTimezoneOffsetMinutes);

  DateTime displayScheduledAt(DateTime value) =>
      _withSourceOffset(value, scheduledTimezoneOffsetMinutes);

  DateTime get displayChronologicalTime => switch (timeSource) {
    CalendarTimeSource.actual => displayActualAt(actualAt!),
    CalendarTimeSource.scheduled => displayScheduledAt(scheduledAt!),
    CalendarTimeSource.recorded ||
    CalendarTimeSource.unknown => displayRecordedAt(recordedAt),
  };
}

DateTime _withSourceOffset(DateTime value, int? offsetMinutes) {
  if (offsetMinutes == null) return value;
  final utc = value.isUtc ? value : value.toUtc();
  final wallClock = utc.add(Duration(minutes: offsetMinutes));
  return DateTime(
    wallClock.year,
    wallClock.month,
    wallClock.day,
    wallClock.hour,
    wallClock.minute,
    wallClock.second,
    wallClock.millisecond,
    wallClock.microsecond,
  );
}

/// Evidence is advisory unless the source record has a confirmed state.
class CalendarProjectionEvidence {
  const CalendarProjectionEvidence({
    this.evidenceId,
    this.proposalId,
    this.summary,
    this.strength,
    this.recommendationConfidence,
    this.explanation,
    this.acceptanceImpact,
    this.ignoreImpact,
  });

  final String? evidenceId;
  final String? proposalId;
  final String? summary;
  final String? strength;
  final double? recommendationConfidence;
  final String? explanation;
  final String? acceptanceImpact;
  final String? ignoreImpact;
}

/// A stable, source-owned event revision for a chronological calendar view.
class CalendarProjectionEvent {
  CalendarProjectionEvent({
    required this.eventId,
    required this.source,
    required this.sourceRecordId,
    required this.timing,
    required this.title,
    required this.conciseDetail,
    required this.state,
    required this.sourceRecordStatus,
    required this.revision,
    required this.deepLink,
    this.vehicleIds = const [],
    this.workProfileId,
    this.participantIds = const [],
    this.jobId,
    this.customerId,
    this.businessClassification,
    this.evidence = const CalendarProjectionEvidence(),
    this.auditReference,
  }) {
    if (eventId.trim().isEmpty || sourceRecordId.trim().isEmpty) {
      throw ArgumentError('Calendar projection IDs must not be empty.');
    }
    if (title.trim().isEmpty || conciseDetail.trim().isEmpty) {
      throw ArgumentError(
        'Calendar projection title and detail must not be empty.',
      );
    }
    if (revision < 0) {
      throw ArgumentError.value(revision, 'revision', 'Must not be negative.');
    }
    if (deepLink.sourceRecordId != sourceRecordId) {
      throw ArgumentError(
        'Calendar deep link must reference the owning source record.',
      );
    }
  }

  final String eventId;
  final CalendarProjectionSource source;
  final String sourceRecordId;
  final CalendarProjectionTiming timing;
  final String title;
  final String conciseDetail;
  final CalendarProjectionState state;
  final String sourceRecordStatus;
  final int revision;
  final CalendarProjectionDeepLink deepLink;
  final List<String> vehicleIds;
  final String? workProfileId;
  final List<String> participantIds;
  final String? jobId;
  final String? customerId;
  final CalendarBusinessClassification? businessClassification;
  final CalendarProjectionEvidence evidence;
  final String? auditReference;

  bool get isActionable => switch (state) {
    CalendarProjectionState.proposed ||
    CalendarProjectionState.needsReview ||
    CalendarProjectionState.incomplete ||
    CalendarProjectionState.blocked => true,
    _ => false,
  };
}

/// Produces a deterministic display list from independent source adapters.
/// Newer revisions replace an older revision for the same immutable event ID.
class CalendarProjectionTimeline {
  const CalendarProjectionTimeline._();

  static List<CalendarProjectionEvent> normalize(
    Iterable<CalendarProjectionEvent> events,
  ) {
    final latestByEventId = <String, CalendarProjectionEvent>{};
    for (final event in events) {
      final existing = latestByEventId[event.eventId];
      if (existing == null ||
          event.revision > existing.revision ||
          (event.revision == existing.revision &&
              _stableEventTieBreak(event, existing) > 0)) {
        latestByEventId[event.eventId] = event;
      }
    }
    final normalized = latestByEventId.values.toList()
      ..sort((left, right) {
        final time = left.timing.chronologicalTime.compareTo(
          right.timing.chronologicalTime,
        );
        if (time != 0) return time;
        final source = left.source.index.compareTo(right.source.index);
        if (source != 0) return source;
        return left.eventId.compareTo(right.eventId);
      });
    return List.unmodifiable(normalized);
  }
}

int _stableEventTieBreak(
  CalendarProjectionEvent left,
  CalendarProjectionEvent right,
) {
  final leftKey = [
    left.source.index,
    left.sourceRecordId,
    left.timing.chronologicalTime.toUtc().microsecondsSinceEpoch,
    left.state.index,
    left.sourceRecordStatus,
    left.title,
    left.conciseDetail,
  ].join('|');
  final rightKey = [
    right.source.index,
    right.sourceRecordId,
    right.timing.chronologicalTime.toUtc().microsecondsSinceEpoch,
    right.state.index,
    right.sourceRecordStatus,
    right.title,
    right.conciseDetail,
  ].join('|');
  return leftKey.compareTo(rightKey);
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
