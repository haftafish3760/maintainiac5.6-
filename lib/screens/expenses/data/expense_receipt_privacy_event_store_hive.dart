part of 'expense_receipt_privacy_event_store.dart';

class PrivacySafeReceiptEventStore {
  PrivacySafeReceiptEventStore._(this._box);

  static const boxName = 'privacy_safe_receipt_events';
  static const maxStoredEvents = 250;

  final Box<dynamic> _box;
  Future<void> _writeTail = Future<void>.value();

  static Future<PrivacySafeReceiptEventStore> create() async {
    final box = await Hive.openBox<dynamic>(boxName);
    return PrivacySafeReceiptEventStore._(box);
  }

  List<PrivacySafeReceiptEventRecord> get records {
    final loaded = <PrivacySafeReceiptEventRecord>[];
    for (final value in _box.values) {
      final record = PrivacySafeReceiptEventRecord.fromStored(value);
      if (!record.isEmpty) loaded.add(record);
    }
    loaded.sort((a, b) => a.queuedAtUtc.compareTo(b.queuedAtUtc));
    return List.unmodifiable(loaded);
  }

  List<PrivacySafeReceiptEventRecord> get pendingUploadRecords {
    return List.unmodifiable(records.where((record) => record.isPendingUpload));
  }

  ReceiptPrivacyEventHealthSnapshot buildHealthSnapshot({DateTime? nowUtc}) {
    return ReceiptPrivacyEventHealthSnapshot.fromRecords(
      records,
      generatedAtUtc: nowUtc,
    );
  }

  Future<PrivacySafeReceiptEventRecord> enqueue(
    PrivacySafeReceiptEvent event, {
    DateTime? queuedAtUtc,
  }) => _enqueue(() async {
    final queuedAt = (queuedAtUtc ?? DateTime.now().toUtc()).toUtc();
    final record = PrivacySafeReceiptEventRecord(
      id: _eventIdFor(queuedAt),
      queuedAtUtc: queuedAt,
      payload: ReceiptPrivacyEventPolicy.sanitize(event),
    );
    await _box.put(record.id, record.toMap());
    await _trimOldestIfNeeded();
    return record;
  });

  List<Map<String, Object?>> pendingUploadPayloads({int limit = 50}) {
    final cappedLimit = limit.clamp(0, maxStoredEvents).toInt();
    return [
      for (final record in pendingUploadRecords.take(cappedLimit))
        Map<String, Object?>.unmodifiable({
          'eventId': record.id,
          'queuedAtUtc': record.queuedAtUtc.toUtc().toIso8601String(),
          'payload': ReceiptPrivacyEventPolicy.sanitizeMap(record.payload),
        }),
    ];
  }

  Future<void> markUploaded(Iterable<String> eventIds, {DateTime? nowUtc}) =>
      _enqueue(() async {
        final uploadedAt = (nowUtc ?? DateTime.now().toUtc()).toUtc();
        for (final id in eventIds) {
          final record = PrivacySafeReceiptEventRecord.fromStored(_box.get(id));
          if (record.isEmpty) continue;
          await _box.put(
            id,
            PrivacySafeReceiptEventRecord(
              id: record.id,
              queuedAtUtc: record.queuedAtUtc,
              uploadedAtUtc: uploadedAt,
              payload: record.payload,
            ).toMap(),
          );
        }
      });

  Future<void> clearUploaded() => _enqueue(() async {
    for (final record in records) {
      if (record.uploadedAtUtc != null) {
        await _box.delete(record.id);
      }
    }
  });

  Future<void> clearAll() => _enqueue(() async {
    await _box.clear();
  });

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

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final next = _writeTail.then((_) => operation());
    _writeTail = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }
}
