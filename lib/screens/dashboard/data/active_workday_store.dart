import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../shared/storage/app_storage_guard.dart';

typedef ActiveWorkdayStorageCheck = Future<AppStorageCheck> Function();

enum ActiveWorkdayStatus { active, paused, ended }

enum ActiveWorkdayEventType {
  started,
  paused,
  resumed,
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
    };
  }

  factory ActiveWorkdayEvent.fromMap(Map<dynamic, dynamic> map) {
    final rawId = map['id'];
    return ActiveWorkdayEvent(
      id: _safeText(rawId, fallback: _newId('event'), maxLength: 160),
      type: _eventTypeFromName(map['type'] as String?),
      occurredAt:
          DateTime.tryParse((map['occurredAt'] as String?) ?? '') ??
          _fallbackWorkdayTimestamp(),
      odometerReading: _safeOdometer(map['odometerReading']) ?? 0,
      label: _safeText(map['label'], fallback: 'Workday event', maxLength: 80),
      note: _optionalSafeText(map['note'], maxLength: 240),
      sourceType: _optionalSafeText(map['sourceType'], maxLength: 80),
      sourceId: _optionalSafeText(map['sourceId'], maxLength: 160),
      hasValidIdentity: rawId == null || _isSafeActiveWorkdayIdValue(rawId),
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
    required this.status,
    required this.events,
    this.endedAt,
    this.endOdometer,
    this.hasValidIdentity = true,
  });

  final String id;
  final String vehicleId;
  final String vehicleLabel;
  final String workProfileId;
  final DateTime startedAt;
  final int startOdometer;
  final ActiveWorkdayStatus status;
  final List<ActiveWorkdayEvent> events;
  final DateTime? endedAt;
  final int? endOdometer;
  final bool hasValidIdentity;

  bool get isActive => status != ActiveWorkdayStatus.ended;
  bool get isPaused => status == ActiveWorkdayStatus.paused;

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
    ActiveWorkdayStatus? status,
    List<ActiveWorkdayEvent>? events,
    DateTime? endedAt,
    int? endOdometer,
    bool clearEndedAt = false,
    bool clearEndOdometer = false,
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
      status: status ?? this.status,
      events: events ?? this.events,
      endedAt: clearEndedAt ? null : endedAt ?? this.endedAt,
      endOdometer: clearEndOdometer ? null : endOdometer ?? this.endOdometer,
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
      'status': status.name,
      'events': events.map((event) => event.toMap()).toList(),
      'endedAt': endedAt?.toIso8601String(),
      'endOdometer': _safeOdometer(endOdometer),
    };
  }

  factory ActiveWorkdaySessionRecord.fromMap(Map<dynamic, dynamic> map) {
    final rawId = map['id'];
    final rawVehicleId = map['vehicleId'];
    final rawWorkProfileId = map['workProfileId'];
    final rawEvents = map['events'];
    final events = <ActiveWorkdayEvent>[];
    if (rawEvents is Iterable) {
      for (final event in rawEvents) {
        if (event is ActiveWorkdayEvent) {
          events.add(event);
        } else if (event is Map) {
          events.add(ActiveWorkdayEvent.fromMap(event));
        }
      }
    }
    final startedAt =
        DateTime.tryParse((map['startedAt'] as String?) ?? '') ??
        _fallbackWorkdayTimestamp();
    final endOdometer = _safeOdometer(map['endOdometer']);
    final endedAt = DateTime.tryParse((map['endedAt'] as String?) ?? '');
    final status = _statusFromName(map['status'] as String?);
    final hasEndedEvent = events.any(
      (event) => event.type == ActiveWorkdayEventType.ended,
    );
    final hasCoherentEndedState =
        status == ActiveWorkdayStatus.ended &&
        endedAt != null &&
        !endedAt.isBefore(startedAt) &&
        endOdometer != null &&
        endOdometer >= (_safeOdometer(map['startOdometer']) ?? 0) &&
        hasEndedEvent;
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
      startOdometer: _safeOdometer(map['startOdometer']) ?? 0,
      status: recoveredStatus,
      events: events,
      endedAt: hasCoherentEndedState ? endedAt : null,
      endOdometer: hasCoherentEndedState ? endOdometer : null,
      hasValidIdentity:
          _isSafeActiveWorkdayIdValue(rawId) &&
          _isSafeActiveWorkdayIdValue(rawVehicleId) &&
          _isSafeActiveWorkdayIdValue(rawWorkProfileId) &&
          events.every((event) => event.hasValidIdentity),
    );
  }
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
    DateTime? startedAt,
  }) => _enqueue(() async {
    final existing = activeSession;
    if (existing != null) return existing;
    await _ensureStorageForWrite();
    final now = startedAt ?? DateTime.now();
    final sessionId = _newId('workday');
    final startedEvent = ActiveWorkdayEvent(
      id: _newId('event'),
      type: ActiveWorkdayEventType.started,
      occurredAt: now,
      odometerReading: startOdometer,
      label: 'Workday started',
    );
    final session = ActiveWorkdaySessionRecord(
      id: sessionId,
      vehicleId: vehicleId,
      vehicleLabel: vehicleLabel,
      workProfileId: workProfileId,
      startedAt: now,
      startOdometer: startOdometer,
      status: ActiveWorkdayStatus.active,
      events: [startedEvent],
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
    if (odometerReading < session.startOdometer) {
      throw ArgumentError.value(
        odometerReading,
        'odometerReading',
        'Event odometer cannot be below the active day starting odometer.',
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
    final event = ActiveWorkdayEvent(
      id: _newId('event'),
      type: type,
      occurredAt: now,
      odometerReading: odometerReading,
      label: _labelForEvent(type),
      note: note,
      sourceType: sourceType,
      sourceId: sourceId,
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

  Future<void> clear() => _enqueue(() async {
    _memoryRecords.clear();
    _memoryActiveSessionId = null;
    await _box?.clear();
    notifyListeners();
  });

  String? get _activeSessionId {
    if (_box == null) return _memoryActiveSessionId;
    return _box.get(activeSessionKey) as String?;
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

ActiveWorkdayEventType _eventTypeFromName(String? name) {
  return ActiveWorkdayEventType.values.firstWhere(
    (type) => type.name == name,
    orElse: () => ActiveWorkdayEventType.note,
  );
}

String _labelForEvent(ActiveWorkdayEventType type) {
  return switch (type) {
    ActiveWorkdayEventType.started => 'Workday started',
    ActiveWorkdayEventType.paused => 'Day paused',
    ActiveWorkdayEventType.resumed => 'Day resumed',
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

bool _isSafeActiveWorkdayId(String value) {
  return _isSafeActiveWorkdayIdValue(value);
}

bool _isSafeActiveWorkdayIdValue(Object? value) {
  if (value is! String) return false;
  final clean = value.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), ' ').trim();
  return clean == value && clean.isNotEmpty && clean.length <= 160;
}

int? _safeOdometer(Object? value) {
  if (value is! num || !value.isFinite) return null;
  final rounded = value.round();
  return rounded < 0 ? 0 : rounded;
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
