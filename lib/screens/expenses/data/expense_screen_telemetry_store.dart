part of 'expense_screen_telemetry.dart';

class ExpenseTelemetryStore {
  ExpenseTelemetryStore._(this._box);

  static const boxName = 'expense_screen_telemetry_events';
  static const maxStoredEvents = 500;

  final Box<dynamic> _box;

  static Future<ExpenseTelemetryStore> create() async {
    final box = await Hive.openBox<dynamic>(boxName);
    return ExpenseTelemetryStore._(box);
  }

  List<ExpenseTelemetryRecord> get records {
    final loaded = <ExpenseTelemetryRecord>[];
    for (final value in _box.values) {
      final record = ExpenseTelemetryRecord.fromStored(value);
      if (!record.isEmpty) loaded.add(record);
    }
    loaded.sort((a, b) => a.queuedAtUtc.compareTo(b.queuedAtUtc));
    return List.unmodifiable(loaded);
  }

  List<ExpenseTelemetryRecord> get pendingUploadRecords {
    return List.unmodifiable(records.where((record) => record.isPendingUpload));
  }

  ExpenseTelemetryHealthSnapshot buildHealthSnapshot({DateTime? nowUtc}) {
    return ExpenseTelemetryHealthSnapshot.fromRecords(
      records,
      generatedAtUtc: nowUtc,
    );
  }

  Future<ExpenseTelemetryRecord> enqueue(
    ExpenseTelemetryEvent event, {
    DateTime? queuedAtUtc,
  }) async {
    final queuedAt = (queuedAtUtc ?? DateTime.now().toUtc()).toUtc();
    final record = ExpenseTelemetryRecord(
      id: _eventIdFor(queuedAt),
      queuedAtUtc: queuedAt,
      payload: ExpenseTelemetryPolicy.sanitize(event),
    );
    await _box.put(record.id, record.toMap());
    await _trimOldestIfNeeded();
    return record;
  }

  List<Map<String, Object?>> pendingUploadPayloads({int limit = 50}) {
    final cappedLimit = limit.clamp(0, maxStoredEvents).toInt();
    return [
      for (final record in pendingUploadRecords.take(cappedLimit))
        Map<String, Object?>.unmodifiable({
          'eventId': record.id,
          'queuedAtUtc': record.queuedAtUtc.toUtc().toIso8601String(),
          'payload': ExpenseTelemetryPolicy.sanitizeMap(record.payload),
        }),
    ];
  }

  Future<void> markUploaded(
    Iterable<String> eventIds, {
    DateTime? nowUtc,
  }) async {
    final uploadedAt = (nowUtc ?? DateTime.now().toUtc()).toUtc();
    for (final id in eventIds) {
      final record = ExpenseTelemetryRecord.fromStored(_box.get(id));
      if (record.isEmpty) continue;
      await _box.put(
        id,
        ExpenseTelemetryRecord(
          id: record.id,
          queuedAtUtc: record.queuedAtUtc,
          uploadedAtUtc: uploadedAt,
          payload: record.payload,
        ).toMap(),
      );
    }
  }

  Future<void> clearUploaded() async {
    for (final record in records) {
      if (record.uploadedAtUtc != null) {
        await _box.delete(record.id);
      }
    }
  }

  Future<void> clearAll() => _box.clear();

  Future<void> _trimOldestIfNeeded() async {
    final extraCount = records.length - maxStoredEvents;
    if (extraCount <= 0) return;
    for (final record in records.take(extraCount)) {
      await _box.delete(record.id);
    }
  }

  String _eventIdFor(DateTime queuedAtUtc) {
    final base = queuedAtUtc.microsecondsSinceEpoch.toString();
    var id = base;
    var suffix = 1;
    while (_box.containsKey(id)) {
      id = '$base-$suffix';
      suffix += 1;
    }
    return id;
  }
}
