import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../shared/odometer/odometer_correction_review.dart';
import '../../../shared/storage/app_storage_guard.dart';
import 'active_workday_context_segment.dart';
import 'active_workday_odometer_review.dart';

typedef ActiveWorkdayStorageCheck = Future<AppStorageCheck> Function();

enum ActiveWorkdayStatus { active, paused, ended }

enum ActiveWorkdayEventType {
  started,
  paused,
  resumed,
  contextChanged,
  ended,
  stop,
  pickup,
  dropOff,
  fuel,
  expense,
  note,
}

class ActiveWorkdayEvent {
  const ActiveWorkdayEvent({
    required this.id,
    required this.type,
    required this.occurredAt,
    required this.odometerReading,
    required this.label,
    this.note,
    this.sourceType,
    this.sourceId,
    this.contextSegmentId,
    this.hasValidIdentity = true,
  });

  final String id;
  final ActiveWorkdayEventType type;
  final DateTime occurredAt;
  final int odometerReading;
  final String label;
  final String? note;
  final String? sourceType;
  final String? sourceId;
  final String? contextSegmentId;
  final bool hasValidIdentity;

  String get timeLabel {
    final hour = occurredAt.hour == 0
        ? 12
        : occurredAt.hour > 12
        ? occurredAt.hour - 12
        : occurredAt.hour;
    final minute = occurredAt.minute.toString().padLeft(2, '0');
    final suffix = occurredAt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  String get displayText {
    final odometer = odometerReading.toString();
    final suffix = note == null || note!.trim().isEmpty ? '' : ' - $note';
    return '$label at $odometer mi$suffix';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'occurredAt': occurredAt.toIso8601String(),
      'odometerReading': _safeOdometer(odometerReading) ?? 0,
      'label': _safeText(label, fallback: 'Workday event', maxLength: 80),
      'note': _optionalSafeText(note, maxLength: 240),
      'sourceType': _optionalSafeText(sourceType, maxLength: 80),
      'sourceId': _optionalSafeText(sourceId, maxLength: 160),
      'contextSegmentId': _optionalSafeText(contextSegmentId, maxLength: 160),
    };
  }

  factory ActiveWorkdayEvent.fromMap(Map<dynamic, dynamic> map) {
    final rawId = map['id'];
    final rawType = _stringValue(map['type']);
    return ActiveWorkdayEvent(
      id: _safeText(rawId, fallback: _newId('event'), maxLength: 160),
      type: _eventTypeFromName(rawType),
      occurredAt:
          DateTime.tryParse(_stringValue(map['occurredAt']) ?? '') ??
          _fallbackWorkdayTimestamp(),
      odometerReading: _safeOdometer(map['odometerReading']) ?? 0,
      label: _safeText(map['label'], fallback: 'Workday event', maxLength: 80),
      note: _optionalSafeText(map['note'], maxLength: 240),
      sourceType: _optionalSafeText(map['sourceType'], maxLength: 80),
      sourceId: _optionalSafeText(map['sourceId'], maxLength: 160),
      contextSegmentId: _optionalSafeText(
        map['contextSegmentId'],
        maxLength: 160,
      ),
      hasValidIdentity:
          _isSafeActiveWorkdayIdValue(rawId) &&
          _hasKnownEventTypeName(rawType) &&
          _isSafeOptionalActiveWorkdayReference(map['sourceType']) &&
          _isSafeOptionalActiveWorkdayReference(map['sourceId']) &&
          _isSafeOptionalActiveWorkdayReference(map['contextSegmentId']),
    );
  }
}

class ActiveWorkdaySessionRecord {
  const ActiveWorkdaySessionRecord({
    required this.id,
    required this.vehicleId,
    required this.vehicleLabel,
    required this.workProfileId,
    required this.startedAt,
    required this.startOdometer,
    this.startOdometerTenths,
    required this.status,
    required this.events,
    this.contextSegments = const [],
    this.odometerReviews = const [],
    this.endedAt,
    this.endOdometer,
    this.endOdometerTenths,
    this.hasValidIdentity = true,
  });

  final String id;
  final String vehicleId;
  final String vehicleLabel;
  final String workProfileId;
  final DateTime startedAt;
  final int startOdometer;
  final int? startOdometerTenths;
  final ActiveWorkdayStatus status;
  final List<ActiveWorkdayEvent> events;
  final List<ActiveWorkdayContextSegment> contextSegments;
  final List<ActiveWorkdayOdometerReview> odometerReviews;
  final DateTime? endedAt;
  final int? endOdometer;
  final int? endOdometerTenths;
  final bool hasValidIdentity;

  bool get isActive => status != ActiveWorkdayStatus.ended;
  bool get isPaused => status == ActiveWorkdayStatus.paused;
  int get effectiveStartOdometerTenths =>
      startOdometerTenths ?? startOdometer * 10;
  int? get effectiveEndOdometerTenths => endOdometer == null
      ? endOdometerTenths
      : endOdometerTenths ?? endOdometer! * 10;

  /// Legacy sessions resolve to one immutable segment until they are saved
  /// again. This preserves their original vehicle/profile attribution.
  List<ActiveWorkdayContextSegment> get resolvedContextSegments {
    if (contextSegments.isNotEmpty) return List.unmodifiable(contextSegments);
    return List.unmodifiable([
      ActiveWorkdayContextSegment(
        id: 'legacy-$id',
        vehicleId: vehicleId,
        vehicleLabel: vehicleLabel,
        workProfileId: workProfileId,
        startedAt: startedAt,
        startOdometer: startOdometer,
        startOdometerTenths: startOdometerTenths,
        endedAt: status == ActiveWorkdayStatus.ended ? endedAt : null,
        endOdometer: status == ActiveWorkdayStatus.ended ? endOdometer : null,
        endOdometerTenths: status == ActiveWorkdayStatus.ended
            ? endOdometerTenths
            : null,
      ),
    ]);
  }

  ActiveWorkdayContextSegment get currentContextSegment {
    final segments = resolvedContextSegments;
    for (final segment in segments.reversed) {
      if (segment.isOpen) return segment;
    }
    return segments.last;
  }

  int latestOdometerForContext(String contextSegmentId) {
    final initialSegmentId = resolvedContextSegments.first.id;
    final segment = resolvedContextSegments.firstWhere(
      (candidate) => candidate.id == contextSegmentId,
      orElse: () => currentContextSegment,
    );
    return events
        .where(
          (event) =>
              event.contextSegmentId == contextSegmentId ||
              (event.contextSegmentId == null &&
                  contextSegmentId == initialSegmentId),
        )
        .fold<int>(
          segment.startOdometer,
          (latest, event) =>
              event.odometerReading > latest ? event.odometerReading : latest,
        );
  }

  /// Elapsed work time excludes each durable paused interval. Event timestamps
  /// are clamped to the requested end so a stale or future-dated record cannot
  /// make the dashboard timer negative.
  Duration elapsedWorkTimeAt(DateTime now) {
    final end = endedAt != null && endedAt!.isBefore(now) ? endedAt! : now;
    if (!end.isAfter(startedAt)) return Duration.zero;

    var pausedTotal = Duration.zero;
    DateTime? pausedAt;
    final orderedEvents = [...events]
      ..sort((left, right) => left.occurredAt.compareTo(right.occurredAt));
    for (final event in orderedEvents) {
      final occurredAt = event.occurredAt.isBefore(startedAt)
          ? startedAt
          : event.occurredAt.isAfter(end)
          ? end
          : event.occurredAt;
      if (event.type == ActiveWorkdayEventType.paused && pausedAt == null) {
        pausedAt = occurredAt;
      } else if (event.type == ActiveWorkdayEventType.resumed &&
          pausedAt != null) {
        pausedTotal += occurredAt.difference(pausedAt);
        pausedAt = null;
      }
    }
    if (pausedAt != null) pausedTotal += end.difference(pausedAt);

    final elapsed = end.difference(startedAt) - pausedTotal;
    return elapsed.isNegative ? Duration.zero : elapsed;
  }

  int milesSoFar(int currentOdometer) {
    final end = endOdometer ?? currentOdometer;
    final delta = end - startOdometer;
    return delta < 0 ? 0 : delta;
  }

  ActiveWorkdaySessionRecord copyWith({
    String? id,
    String? vehicleId,
    String? vehicleLabel,
    String? workProfileId,
    DateTime? startedAt,
    int? startOdometer,
    int? startOdometerTenths,
    ActiveWorkdayStatus? status,
    List<ActiveWorkdayEvent>? events,
    List<ActiveWorkdayContextSegment>? contextSegments,
    List<ActiveWorkdayOdometerReview>? odometerReviews,
    DateTime? endedAt,
    int? endOdometer,
    int? endOdometerTenths,
    bool clearEndedAt = false,
    bool clearEndOdometer = false,
    bool clearEndOdometerTenths = false,
  }) {
    return ActiveWorkdaySessionRecord(
      id: _safeText(id ?? this.id, fallback: _newId('workday'), maxLength: 160),
      vehicleId: _safeText(
        vehicleId ?? this.vehicleId,
        fallback: 'default_vehicle',
        maxLength: 160,
      ),
      vehicleLabel: _safeText(
        vehicleLabel ?? this.vehicleLabel,
        fallback: 'Active vehicle',
        maxLength: 120,
      ),
      workProfileId: _safeText(
        workProfileId ?? this.workProfileId,
        fallback: 'default_work',
        maxLength: 160,
      ),
      startedAt: startedAt ?? this.startedAt,
      startOdometer: startOdometer ?? this.startOdometer,
      startOdometerTenths: startOdometerTenths ?? this.startOdometerTenths,
      status: status ?? this.status,
      events: events ?? this.events,
      contextSegments: contextSegments ?? this.contextSegments,
      odometerReviews: odometerReviews ?? this.odometerReviews,
      endedAt: clearEndedAt ? null : endedAt ?? this.endedAt,
      endOdometer: clearEndOdometer ? null : endOdometer ?? this.endOdometer,
      endOdometerTenths: clearEndOdometerTenths
          ? null
          : endOdometerTenths ?? this.endOdometerTenths,
      hasValidIdentity: hasValidIdentity,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': _safeText(id, fallback: _newId('workday'), maxLength: 160),
      'vehicleId': _safeText(
        vehicleId,
        fallback: 'default_vehicle',
        maxLength: 160,
      ),
      'vehicleLabel': _safeText(
        vehicleLabel,
        fallback: 'Active vehicle',
        maxLength: 120,
      ),
      'workProfileId': _safeText(
        workProfileId,
        fallback: 'default_work',
        maxLength: 160,
      ),
      'startedAt': startedAt.toIso8601String(),
      'startOdometer': _safeOdometer(startOdometer) ?? 0,
      if (startOdometerTenths != null)
        'startOdometerTenths': startOdometerTenths,
      'status': status.name,
      'events': events.map((event) => event.toMap()).toList(),
      'contextSegments': resolvedContextSegments
          .map((segment) => segment.toMap())
          .toList(growable: false),
      'odometerReviews': odometerReviews
          .map((review) => review.toMap())
          .toList(growable: false),
      'endedAt': endedAt?.toIso8601String(),
      'endOdometer': _safeOdometer(endOdometer),
      if (endOdometerTenths != null) 'endOdometerTenths': endOdometerTenths,
    };
  }

  factory ActiveWorkdaySessionRecord.fromMap(Map<dynamic, dynamic> map) {
    final rawId = map['id'];
    final rawVehicleId = map['vehicleId'];
    final rawWorkProfileId = map['workProfileId'];
    final rawEvents = map['events'];
    final rawContextSegments = map['contextSegments'];
    final rawOdometerReviews = map['odometerReviews'];
    final parsedEvents = <ActiveWorkdayEvent>[];
    if (rawEvents is Iterable) {
      for (final event in rawEvents) {
        if (event is ActiveWorkdayEvent) {
          parsedEvents.add(event);
        } else if (event is Map) {
          parsedEvents.add(ActiveWorkdayEvent.fromMap(event));
        }
      }
    }
    final parsedContextSegments = <ActiveWorkdayContextSegment>[];
    var hasInvalidContextSegment = false;
    if (rawContextSegments != null) {
      if (rawContextSegments is! Iterable) {
        hasInvalidContextSegment = true;
      } else {
        for (final segment in rawContextSegments) {
          if (segment is! Map) {
            hasInvalidContextSegment = true;
            continue;
          }
          final parsed = ActiveWorkdayContextSegment.tryFromMap(segment);
          if (parsed == null) {
            hasInvalidContextSegment = true;
          } else {
            parsedContextSegments.add(parsed);
          }
        }
      }
    }
    final parsedOdometerReviews = <ActiveWorkdayOdometerReview>[];
    var hasInvalidOdometerReview = false;
    if (rawOdometerReviews != null) {
      if (rawOdometerReviews is! Iterable) {
        hasInvalidOdometerReview = true;
      } else {
        for (final review in rawOdometerReviews) {
          if (review is! Map) {
            hasInvalidOdometerReview = true;
            continue;
          }
          final parsed = ActiveWorkdayOdometerReview.fromMap(review);
          if (parsed.id == 'invalid-review' ||
              parsed.effectiveEnteredOdometerTenths >=
                  parsed.effectiveStartingOdometerTenths ||
              parsed.effectiveStartingOdometerTenths ~/ 10 !=
                  parsed.startingOdometer ||
              parsed.effectiveEnteredOdometerTenths ~/ 10 !=
                  parsed.enteredOdometer) {
            hasInvalidOdometerReview = true;
            continue;
          }
          final duplicate = parsedOdometerReviews.any(
            (existing) =>
                existing.startingOdometer == parsed.startingOdometer &&
                existing.effectiveEnteredOdometerTenths ==
                    parsed.effectiveEnteredOdometerTenths &&
                existing.reason == parsed.reason,
          );
          // Older interrupted writes may contain the same unresolved review
          // more than once. Preserve the first evidence record and recover
          // the workday without multiplying a user-facing review queue.
          if (duplicate) continue;
          parsedOdometerReviews.add(parsed);
        }
      }
    }
    final startedAt =
        DateTime.tryParse(_stringValue(map['startedAt']) ?? '') ??
        _fallbackWorkdayTimestamp();
    final startOdometer = _safeOdometer(map['startOdometer']) ?? 0;
    final rawStartOdometerTenths = map['startOdometerTenths'];
    final startOdometerTenths = _safeOdometerTenths(rawStartOdometerTenths);
    final effectiveStartTenths = startOdometerTenths ?? startOdometer * 10;
    final events = _coherentWorkdayEvents(
      parsedEvents,
      startedAt: startedAt,
      startOdometer: startOdometer,
      contextSegments: parsedContextSegments,
    );
    final endOdometer = _safeOdometer(map['endOdometer']);
    final rawEndOdometerTenths = map['endOdometerTenths'];
    final endOdometerTenths = _safeOdometerTenths(rawEndOdometerTenths);
    final effectiveEndTenths = endOdometer == null
        ? endOdometerTenths
        : endOdometerTenths ?? endOdometer * 10;
    final endedAt = DateTime.tryParse(_stringValue(map['endedAt']) ?? '');
    final rawStatus = _stringValue(map['status']);
    final status = _statusFromName(rawStatus);
    final hasEndedEvent = events.any(
      (event) => event.type == ActiveWorkdayEventType.ended,
    );
    final hasLegacyCoherentEndedState =
        status == ActiveWorkdayStatus.ended &&
        endedAt != null &&
        !endedAt.isBefore(startedAt) &&
        endOdometer != null &&
        effectiveEndTenths != null &&
        effectiveStartTenths ~/ 10 == startOdometer &&
        effectiveEndTenths ~/ 10 == endOdometer &&
        effectiveEndTenths >= effectiveStartTenths &&
        hasEndedEvent &&
        events.every(
          (event) =>
              !event.occurredAt.isAfter(endedAt) &&
              event.odometerReading <= endOdometer,
        );
    final finalContext = parsedContextSegments.isEmpty
        ? null
        : parsedContextSegments.last;
    final hasSegmentAwareCoherentEndedState =
        status == ActiveWorkdayStatus.ended &&
        endedAt != null &&
        !endedAt.isBefore(startedAt) &&
        endOdometer != null &&
        _hasCoherentContextSegmentOrder(parsedContextSegments) &&
        parsedContextSegments.every((segment) => segment.isClosed) &&
        finalContext != null &&
        finalContext.endedAt!.isAtSameMomentAs(endedAt) &&
        finalContext.endOdometer == endOdometer &&
        finalContext.effectiveEndOdometerTenths == effectiveEndTenths &&
        hasEndedEvent &&
        events.every((event) => !event.occurredAt.isAfter(endedAt));
    final hasCoherentEndedState = parsedContextSegments.isEmpty
        ? hasLegacyCoherentEndedState
        : hasSegmentAwareCoherentEndedState;
    final recoveredStatus = status == ActiveWorkdayStatus.ended
        ? hasCoherentEndedState
              ? ActiveWorkdayStatus.ended
              : ActiveWorkdayStatus.active
        : status;

    return ActiveWorkdaySessionRecord(
      id: _safeText(map['id'], fallback: _newId('workday'), maxLength: 160),
      vehicleId: _safeText(
        map['vehicleId'],
        fallback: 'default_vehicle',
        maxLength: 160,
      ),
      vehicleLabel: _safeText(
        map['vehicleLabel'],
        fallback: 'Active vehicle',
        maxLength: 120,
      ),
      workProfileId: _safeText(
        map['workProfileId'],
        fallback: 'default_work',
        maxLength: 160,
      ),
      startedAt: startedAt,
      startOdometer: startOdometer,
      startOdometerTenths: startOdometerTenths,
      status: recoveredStatus,
      events: events,
      contextSegments: parsedContextSegments,
      odometerReviews: parsedOdometerReviews,
      endedAt: hasCoherentEndedState ? endedAt : null,
      endOdometer: hasCoherentEndedState ? endOdometer : null,
      endOdometerTenths: hasCoherentEndedState ? endOdometerTenths : null,
      hasValidIdentity:
          _isSafeActiveWorkdayIdValue(rawId) &&
          _isSafeActiveWorkdayIdValue(rawVehicleId) &&
          _isSafeActiveWorkdayIdValue(rawWorkProfileId) &&
          _hasKnownStatusName(rawStatus) &&
          !hasInvalidContextSegment &&
          !hasInvalidOdometerReview &&
          (rawStartOdometerTenths == null || startOdometerTenths != null) &&
          (rawEndOdometerTenths == null || endOdometerTenths != null) &&
          effectiveStartTenths ~/ 10 == startOdometer &&
          _hasCoherentContextSegmentLifecycle(
            parsedContextSegments,
            status: recoveredStatus,
          ) &&
          events.every((event) => event.hasValidIdentity),
    );
  }
}

bool _hasCoherentContextSegmentOrder(
  List<ActiveWorkdayContextSegment> segments,
) {
  final seenIds = <String>{};
  for (var index = 0; index < segments.length; index++) {
    final current = segments[index];
    if (!seenIds.add(current.id)) return false;
    if (index == 0) continue;
    final previous = segments[index - 1];
    if (!previous.isClosed || current.startedAt.isBefore(previous.endedAt!)) {
      return false;
    }
  }
  return true;
}

bool _hasCoherentContextSegmentLifecycle(
  List<ActiveWorkdayContextSegment> segments, {
  required ActiveWorkdayStatus status,
}) {
  if (!_hasCoherentContextSegmentOrder(segments) || segments.isEmpty) {
    return segments.isEmpty;
  }
  if (status == ActiveWorkdayStatus.ended) {
    return segments.every((segment) => segment.isClosed);
  }
  return segments.last.isOpen &&
      segments.take(segments.length - 1).every((segment) => segment.isClosed);
}

List<ActiveWorkdayEvent> _coherentWorkdayEvents(
  Iterable<ActiveWorkdayEvent> source, {
  required DateTime startedAt,
  required int startOdometer,
  required List<ActiveWorkdayContextSegment> contextSegments,
}) {
  if (contextSegments.isNotEmpty) {
    final contextsById = {
      for (final segment in contextSegments) segment.id: segment,
    };
    final latestByContext = {
      for (final segment in contextSegments) segment.id: segment.startOdometer,
    };
    final events = <ActiveWorkdayEvent>[];
    final ordered = source.toList(growable: false)
      ..sort((left, right) => left.occurredAt.compareTo(right.occurredAt));
    for (final event in ordered) {
      final contextId = event.contextSegmentId ?? contextSegments.first.id;
      final context = contextsById[contextId];
      final latestOdometer = latestByContext[contextId];
      if (context == null ||
          latestOdometer == null ||
          event.occurredAt.isBefore(context.startedAt) ||
          (context.endedAt != null &&
              event.occurredAt.isAfter(context.endedAt!)) ||
          event.odometerReading < latestOdometer ||
          (context.endOdometer != null &&
              event.odometerReading > context.endOdometer!)) {
        continue;
      }
      events.add(event);
      latestByContext[contextId] = event.odometerReading;
    }
    return List.unmodifiable(events);
  }
  final events = <ActiveWorkdayEvent>[];
  var latestOdometer = startOdometer;
  final ordered = source.toList(growable: false)
    ..sort((left, right) => left.occurredAt.compareTo(right.occurredAt));
  for (final event in ordered) {
    if (event.occurredAt.isBefore(startedAt) ||
        event.odometerReading < latestOdometer) {
      continue;
    }
    events.add(event);
    latestOdometer = event.odometerReading;
  }
  return List.unmodifiable(events);
}

class ActiveWorkdayController extends ChangeNotifier {
  ActiveWorkdayController._(
    this._box, {
    ActiveWorkdayStorageCheck? storageCheck,
  }) : _storageCheck = storageCheck ?? _defaultStorageCheck;
  ActiveWorkdayController.memory({ActiveWorkdayStorageCheck? storageCheck})
    : _box = null,
      _storageCheck = storageCheck;

  static const boxName = 'active_workday_sessions';
  static const activeSessionKey = '__active_session_id__';

  final Box<dynamic>? _box;
  final ActiveWorkdayStorageCheck? _storageCheck;
  final _memoryRecords = <String, ActiveWorkdaySessionRecord>{};
  String? _memoryActiveSessionId;
  Future<void> _writeTail = Future<void>.value();

  static Future<ActiveWorkdayController> create({
    ActiveWorkdayStorageCheck? storageCheck,
  }) async {
    final box = await Hive.openBox<dynamic>(boxName);
    return ActiveWorkdayController._(box, storageCheck: storageCheck);
  }

  ActiveWorkdaySessionRecord? get activeSession {
    final id = _activeSessionId;
    if (id == null) return null;
    final session = sessionById(id);
    if (session == null || !session.isActive || !session.hasValidIdentity) {
      return null;
    }
    return session;
  }

  List<ActiveWorkdaySessionRecord> get sessions {
    final source = _box == null ? _memoryRecords.values : _box.values;
    final records = <ActiveWorkdaySessionRecord>[];
    for (final value in source) {
      if (value is ActiveWorkdaySessionRecord && value.hasValidIdentity) {
        records.add(value);
      } else if (value is Map && value['startedAt'] != null) {
        final parsed = ActiveWorkdaySessionRecord.fromMap(value);
        if (parsed.hasValidIdentity) records.add(parsed);
      }
    }
    records.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return records;
  }

  ActiveWorkdaySessionRecord? sessionById(String id) {
    if (!_isSafeActiveWorkdayId(id)) return null;
    final value = _box == null ? _memoryRecords[id] : _box.get(id);
    if (value is ActiveWorkdaySessionRecord) {
      return value.hasValidIdentity ? value : null;
    }
    if (value is Map) {
      final parsed = ActiveWorkdaySessionRecord.fromMap(value);
      return parsed.hasValidIdentity ? parsed : null;
    }
    return null;
  }

  Future<ActiveWorkdaySessionRecord> startDay({
    required String vehicleId,
    required String vehicleLabel,
    required String workProfileId,
    required int startOdometer,
    int? startOdometerTenths,
    DateTime? startedAt,
  }) => _enqueue(() async {
    final existing = activeSession;
    if (existing != null) return existing;
    final exactStartTenths = startOdometerTenths ?? startOdometer * 10;
    if (startOdometer < 0 ||
        exactStartTenths < 0 ||
        exactStartTenths ~/ 10 != startOdometer) {
      throw ArgumentError.value(
        startOdometer,
        'startOdometer',
        'Active day starting odometer cannot be negative.',
      );
    }
    await _ensureStorageForWrite();
    final now = startedAt ?? DateTime.now();
    if (_isUnreasonablyFutureWorkdayTime(now)) {
      throw ArgumentError.value(
        now,
        'startedAt',
        'Active day start time cannot be in the future.',
      );
    }
    final sessionId = _newId('workday');
    final initialContext = ActiveWorkdayContextSegment(
      id: _newId('context'),
      vehicleId: vehicleId,
      vehicleLabel: vehicleLabel,
      workProfileId: workProfileId,
      startedAt: now,
      startOdometer: startOdometer,
      startOdometerTenths: exactStartTenths,
    );
    final startedEvent = ActiveWorkdayEvent(
      id: _newId('event'),
      type: ActiveWorkdayEventType.started,
      occurredAt: now,
      odometerReading: startOdometer,
      label: 'Workday started',
      contextSegmentId: initialContext.id,
    );
    final session = ActiveWorkdaySessionRecord(
      id: sessionId,
      vehicleId: vehicleId,
      vehicleLabel: vehicleLabel,
      workProfileId: workProfileId,
      startedAt: now,
      startOdometer: startOdometer,
      startOdometerTenths: exactStartTenths,
      status: ActiveWorkdayStatus.active,
      events: [startedEvent],
      contextSegments: [initialContext],
    );
    await _saveSession(session);
    await _setActiveSessionId(sessionId);
    notifyListeners();
    return session;
  });

  Future<ActiveWorkdaySessionRecord?> addEvent({
    required ActiveWorkdayEventType type,
    required int odometerReading,
    String? note,
    String? sourceType,
    String? sourceId,
    DateTime? occurredAt,
  }) => _enqueue(() async {
    final session = activeSession;
    if (session == null) return null;
    final contextSegment = session.currentContextSegment;
    if (odometerReading < contextSegment.startOdometer) {
      throw ArgumentError.value(
        odometerReading,
        'odometerReading',
        'Event odometer cannot be below the active context starting odometer.',
      );
    }
    final latestOdometer = session.latestOdometerForContext(contextSegment.id);
    if (odometerReading < latestOdometer) {
      throw ArgumentError.value(
        odometerReading,
        'odometerReading',
        'Event odometer cannot be below an earlier event in this context.',
      );
    }
    await _ensureStorageForWrite();
    final now = occurredAt ?? DateTime.now();
    if (now.isBefore(session.startedAt)) {
      throw ArgumentError.value(
        now,
        'occurredAt',
        'Event time cannot be before the active day start time.',
      );
    }
    if (_isUnreasonablyFutureWorkdayTime(now)) {
      throw ArgumentError.value(
        now,
        'occurredAt',
        'Event time cannot be in the future.',
      );
    }
    if (!_isSafeOptionalActiveWorkdayReference(sourceType)) {
      throw ArgumentError.value(
        sourceType,
        'sourceType',
        'Dashboard event source types must be safe reference tokens.',
      );
    }
    if (!_isSafeOptionalActiveWorkdayReference(sourceId)) {
      throw ArgumentError.value(
        sourceId,
        'sourceId',
        'Dashboard event source ids must be safe reference tokens.',
      );
    }
    final event = ActiveWorkdayEvent(
      id: _newId('event'),
      type: type,
      occurredAt: now,
      odometerReading: odometerReading,
      label: _labelForEvent(type),
      note: note,
      sourceType: sourceType,
      sourceId: sourceId,
      contextSegmentId: contextSegment.id,
    );
    final status = switch (type) {
      ActiveWorkdayEventType.paused => ActiveWorkdayStatus.paused,
      ActiveWorkdayEventType.resumed => ActiveWorkdayStatus.active,
      ActiveWorkdayEventType.ended => ActiveWorkdayStatus.ended,
      _ => session.status,
    };
    final updated = session.copyWith(
      status: status,
      events: [...session.events, event],
      contextSegments: type == ActiveWorkdayEventType.ended
          ? [
              ...session.resolvedContextSegments.take(
                session.resolvedContextSegments.length - 1,
              ),
              contextSegment.close(endedAt: now, endOdometer: odometerReading),
            ]
          : session.contextSegments,
      endedAt: type == ActiveWorkdayEventType.ended ? now : null,
      endOdometer: type == ActiveWorkdayEventType.ended
          ? odometerReading
          : null,
    );
    await _saveSession(updated);
    if (type == ActiveWorkdayEventType.ended) {
      await _setActiveSessionId(null);
    }
    notifyListeners();
    return updated;
  });

  /// Preserves an End Day discrepancy for review without ending the workday
  /// or changing canonical odometer history.
  Future<ActiveWorkdaySessionRecord?> requestOdometerReview({
    required int enteredOdometer,
    int? enteredOdometerTenths,
    required OdometerCorrectionReason reason,
    DateTime? createdAt,
  }) => _enqueue(() async {
    final session = activeSession;
    if (session == null || session.status == ActiveWorkdayStatus.ended) {
      return null;
    }
    final context = session.currentContextSegment;
    final startingOdometer = context.startOdometer;
    final startingOdometerTenths = context.effectiveStartOdometerTenths;
    final exactEnteredTenths = enteredOdometerTenths ?? enteredOdometer * 10;
    if (enteredOdometer < 0 ||
        exactEnteredTenths ~/ 10 != enteredOdometer ||
        exactEnteredTenths >= startingOdometerTenths) {
      throw ArgumentError.value(
        enteredOdometer,
        'enteredOdometer',
        'A workday odometer review requires a reading below its active starting odometer.',
      );
    }
    await _ensureStorageForWrite();
    final created = createdAt ?? DateTime.now();
    if (created.isBefore(session.startedAt) ||
        _isUnreasonablyFutureWorkdayTime(created)) {
      throw ArgumentError.value(
        created,
        'createdAt',
        'Invalid odometer review time.',
      );
    }
    final duplicate = session.odometerReviews.any(
      (review) =>
          review.startingOdometer == startingOdometer &&
          review.effectiveEnteredOdometerTenths == exactEnteredTenths &&
          review.reason == reason,
    );
    // Reopening the End Day sheet or receiving a repeated callback must not
    // create more audit evidence for the same unresolved reading.
    if (duplicate) return session;
    final review = ActiveWorkdayOdometerReview(
      id: _newId('odometer_review'),
      createdAt: created,
      startingOdometer: startingOdometer,
      startingOdometerTenths: startingOdometerTenths,
      enteredOdometer: enteredOdometer,
      enteredOdometerTenths: exactEnteredTenths,
      reason: reason,
    );
    final updated = session.copyWith(
      odometerReviews: [...session.odometerReviews, review],
    );
    await _saveSession(updated);
    notifyListeners();
    return updated;
  });

  /// Records a user-confirmed context boundary without rewriting prior events.
  ///
  /// The caller must stop/review any GPS trip before changing vehicles. This
  /// store owns only durable workday attribution and per-vehicle odometers.
  Future<ActiveWorkdaySessionRecord?> handoffContext({
    required String vehicleId,
    required String vehicleLabel,
    required String workProfileId,
    required int endingOdometer,
    required int startingOdometer,
    DateTime? occurredAt,
  }) => _enqueue(() async {
    final session = activeSession;
    if (session == null || session.status == ActiveWorkdayStatus.ended) {
      return null;
    }
    if (!_isSafeActiveWorkdayId(vehicleId) ||
        !_isSafeActiveWorkdayId(workProfileId) ||
        vehicleLabel.trim().isEmpty ||
        vehicleLabel.length > 120 ||
        endingOdometer < 0 ||
        startingOdometer < 0) {
      throw ArgumentError('Workday context handoff has invalid input.');
    }
    final now = occurredAt ?? DateTime.now();
    if (now.isBefore(session.startedAt) ||
        _isUnreasonablyFutureWorkdayTime(now)) {
      throw ArgumentError.value(
        now,
        'occurredAt',
        'Invalid context handoff time.',
      );
    }
    final current = session.currentContextSegment;
    if (current.matchesContext(
      vehicleId: vehicleId,
      workProfileId: workProfileId,
    )) {
      return session;
    }
    if (current.vehicleId == vehicleId && endingOdometer != startingOdometer) {
      throw ArgumentError.value(
        startingOdometer,
        'startingOdometer',
        'A work-profile handoff in the same vehicle must keep one odometer boundary.',
      );
    }
    await _ensureStorageForWrite();
    final closed = current.close(endedAt: now, endOdometer: endingOdometer);
    final next = ActiveWorkdayContextSegment(
      id: _newId('context'),
      vehicleId: vehicleId,
      vehicleLabel: vehicleLabel,
      workProfileId: workProfileId,
      startedAt: now,
      startOdometer: startingOdometer,
    );
    final boundary = ActiveWorkdayEvent(
      id: _newId('event'),
      type: ActiveWorkdayEventType.contextChanged,
      occurredAt: now,
      odometerReading: startingOdometer,
      label: _labelForEvent(ActiveWorkdayEventType.contextChanged),
      note:
          '${current.vehicleLabel} / ${current.workProfileId} → '
          '$vehicleLabel / $workProfileId',
      contextSegmentId: next.id,
    );
    final segments = [
      ...session.resolvedContextSegments.take(
        session.resolvedContextSegments.length - 1,
      ),
      closed,
      next,
    ];
    final updated = session.copyWith(
      events: [...session.events, boundary],
      contextSegments: segments,
    );
    await _saveSession(updated);
    notifyListeners();
    return updated;
  });

  Future<void> clear() => _enqueue(() async {
    _memoryRecords.clear();
    _memoryActiveSessionId = null;
    await _box?.clear();
    notifyListeners();
  });

  String? get _activeSessionId {
    if (_box == null) return _memoryActiveSessionId;
    final value = _box.get(activeSessionKey);
    return _isSafeActiveWorkdayIdValue(value) ? value as String : null;
  }

  Future<void> _setActiveSessionId(String? id) async {
    final safeId = id == null || _isSafeActiveWorkdayId(id) ? id : null;
    if (_box == null) {
      _memoryActiveSessionId = safeId;
    } else if (safeId == null) {
      await _box.delete(activeSessionKey);
    } else {
      await _box.put(activeSessionKey, safeId);
    }
  }

  Future<void> _saveSession(ActiveWorkdaySessionRecord session) async {
    if (!_isSafeActiveWorkdayId(session.id)) {
      throw ArgumentError.value(
        session.id,
        'session.id',
        'Active workday sessions require a non-empty safe id.',
      );
    }
    if (!_isSafeActiveWorkdayId(session.vehicleId)) {
      throw ArgumentError.value(
        session.vehicleId,
        'session.vehicleId',
        'Active workday sessions require a non-empty safe vehicle id.',
      );
    }
    if (!_isSafeActiveWorkdayId(session.workProfileId)) {
      throw ArgumentError.value(
        session.workProfileId,
        'session.workProfileId',
        'Active workday sessions require a non-empty safe work profile id.',
      );
    }
    final unsafeEventIndex = session.events.indexWhere(
      (event) => !_isSafeActiveWorkdayId(event.id),
    );
    if (unsafeEventIndex >= 0) {
      throw ArgumentError.value(
        session.events[unsafeEventIndex].id,
        'session.events[$unsafeEventIndex].id',
        'Active workday events require non-empty safe ids.',
      );
    }
    final unsafeSegmentIndex = session.resolvedContextSegments.indexWhere(
      (segment) =>
          !_isSafeActiveWorkdayId(segment.id) ||
          !_isSafeActiveWorkdayId(segment.vehicleId) ||
          !_isSafeActiveWorkdayId(segment.workProfileId),
    );
    if (unsafeSegmentIndex >= 0) {
      throw ArgumentError.value(
        session.resolvedContextSegments[unsafeSegmentIndex].id,
        'session.contextSegments[$unsafeSegmentIndex]',
        'Active workday context segments require safe ids.',
      );
    }
    if (_box == null) {
      _memoryRecords[session.id] = session;
    } else {
      await _box.put(session.id, session.toMap());
    }
  }

  Future<void> _ensureStorageForWrite() async {
    final check = _storageCheck;
    if (check == null) return;
    final storage = await check();
    if (!storage.hasEnoughSpace) throw StateError(storage.blockingMessage());
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final next = _writeTail.then((_) => operation());
    _writeTail = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }

  static Future<AppStorageCheck> _defaultStorageCheck() =>
      AppStorageGuard.check(AppStoragePurpose.dashboardRecord);
}

class ActiveWorkdayScope extends InheritedNotifier<ActiveWorkdayController> {
  const ActiveWorkdayScope({
    super.key,
    required ActiveWorkdayController controller,
    required super.child,
  }) : super(notifier: controller);

  static ActiveWorkdayController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<ActiveWorkdayScope>();
    assert(scope != null, 'ActiveWorkdayScope is missing above this context.');
    return scope!.notifier!;
  }

  static ActiveWorkdayController? maybeOf(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<ActiveWorkdayScope>();
    return scope?.notifier;
  }
}

ActiveWorkdayStatus _statusFromName(String? name) {
  return ActiveWorkdayStatus.values.firstWhere(
    (status) => status.name == name,
    orElse: () => ActiveWorkdayStatus.active,
  );
}

bool _hasKnownStatusName(String? name) =>
    ActiveWorkdayStatus.values.any((status) => status.name == name);

ActiveWorkdayEventType _eventTypeFromName(String? name) {
  return ActiveWorkdayEventType.values.firstWhere(
    (type) => type.name == name,
    orElse: () => ActiveWorkdayEventType.note,
  );
}

bool _hasKnownEventTypeName(String? name) =>
    ActiveWorkdayEventType.values.any((type) => type.name == name);

String _labelForEvent(ActiveWorkdayEventType type) {
  return switch (type) {
    ActiveWorkdayEventType.started => 'Workday started',
    ActiveWorkdayEventType.paused => 'Day paused',
    ActiveWorkdayEventType.resumed => 'Day resumed',
    ActiveWorkdayEventType.contextChanged => 'Workday context changed',
    ActiveWorkdayEventType.ended => 'Day ended',
    ActiveWorkdayEventType.stop => 'Stop logged',
    ActiveWorkdayEventType.pickup => 'Pickup logged',
    ActiveWorkdayEventType.dropOff => 'Drop-off logged',
    ActiveWorkdayEventType.fuel => 'Fuel expense opened',
    ActiveWorkdayEventType.expense => 'Expense entry opened',
    ActiveWorkdayEventType.note => 'Workday note',
  };
}

String _newId(String prefix) {
  return '${prefix}_${DateTime.now().microsecondsSinceEpoch}';
}

DateTime _fallbackWorkdayTimestamp() =>
    DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

String? _stringValue(Object? value) => value is String ? value : null;

bool _isSafeActiveWorkdayId(String value) {
  return _isSafeActiveWorkdayIdValue(value);
}

bool _isSafeActiveWorkdayIdValue(Object? value) {
  if (value is! String) return false;
  final clean = value.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), ' ').trim();
  return clean == value && clean.isNotEmpty && clean.length <= 160;
}

bool _isSafeOptionalActiveWorkdayReference(Object? value) =>
    value == null ||
    (_isSafeActiveWorkdayIdValue(value) &&
        RegExp(r'^[A-Za-z0-9_.-]+$').hasMatch(value as String));

int? _safeOdometer(Object? value) {
  if (value is! num || !value.isFinite) return null;
  final rounded = value.round();
  return rounded < 0 ? 0 : rounded;
}

int? _safeOdometerTenths(Object? value) {
  if (value is int && value >= 0) return value;
  if (value is num && value.isFinite && value == value.round() && value >= 0) {
    return value.toInt();
  }
  return null;
}

bool _isUnreasonablyFutureWorkdayTime(DateTime value) {
  return value.toUtc().isAfter(
    DateTime.now().toUtc().add(const Duration(minutes: 5)),
  );
}

String _safeText(
  Object? value, {
  required String fallback,
  required int maxLength,
}) {
  final clean = '${value ?? ''}'
      .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), ' ')
      .trim();
  if (clean.isEmpty) return fallback;
  return clean.length > maxLength ? clean.substring(0, maxLength) : clean;
}

String? _optionalSafeText(Object? value, {required int maxLength}) {
  final clean = _safeText(value, fallback: '', maxLength: maxLength);
  return clean.isEmpty ? null : clean;
}
