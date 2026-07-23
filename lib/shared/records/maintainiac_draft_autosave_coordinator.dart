import 'dart:async';

import 'maintainiac_record_lifecycle.dart';

class MaintainiacDraftAutosaveCoordinator {
  MaintainiacDraftAutosaveCoordinator({
    required MaintainiacRecordDraftStore store,
    this.debounce = const Duration(milliseconds: 300),
  }) : _store = store {
    if (debounce.isNegative || debounce > const Duration(seconds: 5)) {
      throw ArgumentError.value(debounce, 'debounce');
    }
  }

  final MaintainiacRecordDraftStore _store;
  final Duration debounce;
  final _pending = <String, _PendingDraft>{};
  bool _disposed = false;

  /// Coalesces rapid typing into a local checkpoint. Discrete selections and
  /// lifecycle transitions should use [checkpointNow] or [flushAll].
  Future<MaintainiacRecordDraft> schedule({
    required String module,
    required String id,
    required Map<String, dynamic> payload,
    DateTime? now,
  }) {
    _ensureActive();
    final key = _key(module, id);
    final completion = Completer<MaintainiacRecordDraft>();
    final existing = _pending[key];
    final pending = existing ?? _PendingDraft(module: module, id: id);
    pending
      ..timer?.cancel()
      ..payload = _copyPayload(payload)
      ..requestedAt = now
      ..completions.add(completion);
    _pending[key] = pending;
    if (debounce == Duration.zero) {
      _triggerScheduledWrite(key, pending);
    } else {
      pending.timer = Timer(
        debounce,
        () => _triggerScheduledWrite(key, pending),
      );
    }
    return completion.future;
  }

  Future<MaintainiacRecordDraft> checkpointNow({
    required String module,
    required String id,
    required Map<String, dynamic> payload,
    DateTime? now,
  }) async {
    _ensureActive();
    final key = _key(module, id);
    final pending = _pending[key];
    if (pending != null) {
      pending
        ..timer?.cancel()
        ..payload = _copyPayload(payload)
        ..requestedAt = now;
      return _write(key, pending);
    }
    return _store.save(module: module, id: id, payload: payload, now: now);
  }

  Future<MaintainiacRecordDraft?> flush(String module, String id) async {
    _ensureActive();
    final key = _key(module, id);
    final pending = _pending[key];
    if (pending == null) return _store.draftFor(module, id);
    return _write(key, pending);
  }

  Future<void> flushAll() async {
    _ensureActive();
    final entries = _pending.entries.toList(growable: false);
    for (final entry in entries) {
      await _write(entry.key, entry.value);
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    await flushAll();
    _disposed = true;
  }

  Future<MaintainiacRecordDraft> _write(String key, _PendingDraft pending) {
    final inFlight = pending.writeFuture;
    if (inFlight != null) return inFlight;
    if (!identical(_pending[key], pending)) {
      final stored = _store.draftFor(pending.module, pending.id);
      if (stored != null) return Future.value(stored);
      return Future.error(StateError('Draft checkpoint was superseded.'));
    }
    final write = _performWrite(key, pending);
    pending.writeFuture = write;
    return write;
  }

  void _triggerScheduledWrite(String key, _PendingDraft pending) {
    unawaited(
      _write(
        key,
        pending,
      ).then<void>((_) {}, onError: (Object error, StackTrace stackTrace) {}),
    );
  }

  Future<MaintainiacRecordDraft> _performWrite(
    String key,
    _PendingDraft pending,
  ) async {
    pending.timer?.cancel();
    _pending.remove(key);
    try {
      final saved = await _store.save(
        module: pending.module,
        id: pending.id,
        payload: pending.payload,
        now: pending.requestedAt,
      );
      for (final completion in pending.completions) {
        if (!completion.isCompleted) completion.complete(saved);
      }
      return saved;
    } catch (error, stackTrace) {
      for (final completion in pending.completions) {
        if (!completion.isCompleted) {
          completion.completeError(error, stackTrace);
        }
      }
      rethrow;
    }
  }

  void _ensureActive() {
    if (_disposed) throw StateError('Draft autosave coordinator is disposed.');
  }

  static String _key(String module, String id) => '$module:$id';
}

class _PendingDraft {
  _PendingDraft({required this.module, required this.id});

  final String module;
  final String id;
  Map<String, dynamic> payload = const {};
  DateTime? requestedAt;
  Timer? timer;
  Future<MaintainiacRecordDraft>? writeFuture;
  final completions = <Completer<MaintainiacRecordDraft>>[];
}

Map<String, dynamic> _copyPayload(Map<String, dynamic> payload) => {
  for (final entry in payload.entries) entry.key: _copyValue(entry.value),
};

Object? _copyValue(Object? value) {
  if (value is Map) {
    return {
      for (final entry in value.entries)
        entry.key.toString(): _copyValue(entry.value),
    };
  }
  if (value is List) return value.map(_copyValue).toList(growable: false);
  return value;
}
