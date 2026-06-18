import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';

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
  });

  final String id;
  final ActiveWorkdayEventType type;
  final DateTime occurredAt;
  final int odometerReading;
  final String label;
  final String? note;
  final String? sourceType;
  final String? sourceId;

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
      'odometerReading': odometerReading,
      'label': label,
      'note': note,
      'sourceType': sourceType,
      'sourceId': sourceId,
    };
  }

  factory ActiveWorkdayEvent.fromMap(Map<dynamic, dynamic> map) {
    return ActiveWorkdayEvent(
      id: (map['id'] as String?) ?? _newId('event'),
      type: _eventTypeFromName(map['type'] as String?),
      occurredAt:
          DateTime.tryParse((map['occurredAt'] as String?) ?? '') ??
          DateTime.now(),
      odometerReading: (map['odometerReading'] as num?)?.round() ?? 0,
      label: (map['label'] as String?) ?? 'Workday event',
      note: map['note'] as String?,
      sourceType: map['sourceType'] as String?,
      sourceId: map['sourceId'] as String?,
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

  bool get isActive => status != ActiveWorkdayStatus.ended;

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
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      vehicleLabel: vehicleLabel ?? this.vehicleLabel,
      workProfileId: workProfileId ?? this.workProfileId,
      startedAt: startedAt ?? this.startedAt,
      startOdometer: startOdometer ?? this.startOdometer,
      status: status ?? this.status,
      events: events ?? this.events,
      endedAt: clearEndedAt ? null : endedAt ?? this.endedAt,
      endOdometer: clearEndOdometer ? null : endOdometer ?? this.endOdometer,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'vehicleLabel': vehicleLabel,
      'workProfileId': workProfileId,
      'startedAt': startedAt.toIso8601String(),
      'startOdometer': startOdometer,
      'status': status.name,
      'events': events.map((event) => event.toMap()).toList(),
      'endedAt': endedAt?.toIso8601String(),
      'endOdometer': endOdometer,
    };
  }

  factory ActiveWorkdaySessionRecord.fromMap(Map<dynamic, dynamic> map) {
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

    return ActiveWorkdaySessionRecord(
      id: (map['id'] as String?) ?? _newId('workday'),
      vehicleId: (map['vehicleId'] as String?) ?? 'default_vehicle',
      vehicleLabel: (map['vehicleLabel'] as String?) ?? 'Active vehicle',
      workProfileId: (map['workProfileId'] as String?) ?? 'default_work',
      startedAt:
          DateTime.tryParse((map['startedAt'] as String?) ?? '') ??
          DateTime.now(),
      startOdometer: (map['startOdometer'] as num?)?.round() ?? 0,
      status: _statusFromName(map['status'] as String?),
      events: events,
      endedAt: DateTime.tryParse((map['endedAt'] as String?) ?? ''),
      endOdometer: (map['endOdometer'] as num?)?.round(),
    );
  }
}

class ActiveWorkdayController extends ChangeNotifier {
  ActiveWorkdayController._(this._box);
  ActiveWorkdayController.memory() : _box = null;

  static const boxName = 'active_workday_sessions';
  static const activeSessionKey = '__active_session_id__';

  final Box<dynamic>? _box;
  final _memoryRecords = <String, ActiveWorkdaySessionRecord>{};
  String? _memoryActiveSessionId;

  static Future<ActiveWorkdayController> create() async {
    final box = await Hive.openBox<dynamic>(boxName);
    return ActiveWorkdayController._(box);
  }

  ActiveWorkdaySessionRecord? get activeSession {
    final id = _activeSessionId;
    if (id == null) return null;
    final session = sessionById(id);
    if (session == null || !session.isActive) return null;
    return session;
  }

  List<ActiveWorkdaySessionRecord> get sessions {
    final source = _box == null ? _memoryRecords.values : _box.values;
    final records = <ActiveWorkdaySessionRecord>[];
    for (final value in source) {
      if (value is ActiveWorkdaySessionRecord) {
        records.add(value);
      } else if (value is Map && value['startedAt'] != null) {
        records.add(ActiveWorkdaySessionRecord.fromMap(value));
      }
    }
    records.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return records;
  }

  ActiveWorkdaySessionRecord? sessionById(String id) {
    final value = _box == null ? _memoryRecords[id] : _box.get(id);
    if (value is ActiveWorkdaySessionRecord) return value;
    if (value is Map) return ActiveWorkdaySessionRecord.fromMap(value);
    return null;
  }

  Future<ActiveWorkdaySessionRecord> startDay({
    required String vehicleId,
    required String vehicleLabel,
    required String workProfileId,
    required int startOdometer,
    DateTime? startedAt,
  }) async {
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
  }

  Future<ActiveWorkdaySessionRecord?> addEvent({
    required ActiveWorkdayEventType type,
    required int odometerReading,
    String? note,
    String? sourceType,
    String? sourceId,
    DateTime? occurredAt,
  }) async {
    final session = activeSession;
    if (session == null) return null;
    final now = occurredAt ?? DateTime.now();
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
  }

  Future<void> clear() async {
    _memoryRecords.clear();
    _memoryActiveSessionId = null;
    await _box?.clear();
    notifyListeners();
  }

  String? get _activeSessionId {
    if (_box == null) return _memoryActiveSessionId;
    return _box.get(activeSessionKey) as String?;
  }

  Future<void> _setActiveSessionId(String? id) async {
    if (_box == null) {
      _memoryActiveSessionId = id;
    } else if (id == null) {
      await _box.delete(activeSessionKey);
    } else {
      await _box.put(activeSessionKey, id);
    }
  }

  Future<void> _saveSession(ActiveWorkdaySessionRecord session) async {
    if (_box == null) {
      _memoryRecords[session.id] = session;
    } else {
      await _box.put(session.id, session.toMap());
    }
  }
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
