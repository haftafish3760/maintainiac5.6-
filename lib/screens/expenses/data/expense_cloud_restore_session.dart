import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'expense_cloud_restore_storage_plan.dart';

enum ExpenseCloudRestoreSessionState {
  prepared,
  transferring,
  paused,
  failed,
  cancelled,
  completed;

  static ExpenseCloudRestoreSessionState fromName(String? value) {
    return switch (value?.trim()) {
      'transferring' => ExpenseCloudRestoreSessionState.transferring,
      'paused' => ExpenseCloudRestoreSessionState.paused,
      'failed' => ExpenseCloudRestoreSessionState.failed,
      'cancelled' => ExpenseCloudRestoreSessionState.cancelled,
      'completed' => ExpenseCloudRestoreSessionState.completed,
      _ => ExpenseCloudRestoreSessionState.prepared,
    };
  }
}

/// Durable, device-local restore progress. It contains only an opaque server
/// request ID; authorization tokens and proof paths must never be persisted
/// here. A transfer coordinator re-authorizes with the server when resuming.
class ExpenseCloudRestoreSession {
  const ExpenseCloudRestoreSession({
    required this.id,
    required this.requestId,
    required this.mode,
    required this.state,
    required this.createdAt,
    required this.updatedAt,
    required this.expectedDownloadBytes,
    required this.completedDownloadBytes,
    required this.totalRecords,
    required this.completedRecords,
    this.failureReason,
  });

  factory ExpenseCloudRestoreSession.fromMap(Map<dynamic, dynamic> map) {
    return ExpenseCloudRestoreSession(
      id: _text(map['id']),
      requestId: _text(map['requestId']),
      mode: _mode(map['mode']),
      state: ExpenseCloudRestoreSessionState.fromName(_text(map['state'])),
      createdAt: _date(map['createdAt']) ?? DateTime.now().toUtc(),
      updatedAt: _date(map['updatedAt']) ?? DateTime.now().toUtc(),
      expectedDownloadBytes: _nonNegative(map['expectedDownloadBytes']),
      completedDownloadBytes: _nonNegative(map['completedDownloadBytes']),
      totalRecords: _nonNegative(map['totalRecords']),
      completedRecords: _nonNegative(map['completedRecords']),
      failureReason: _nullableText(map['failureReason']),
    );
  }

  final String id;
  final String requestId;
  final ExpenseCloudRestoreMode mode;
  final ExpenseCloudRestoreSessionState state;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int expectedDownloadBytes;
  final int completedDownloadBytes;
  final int totalRecords;
  final int completedRecords;
  final String? failureReason;

  bool get canResume =>
      state == ExpenseCloudRestoreSessionState.paused ||
      state == ExpenseCloudRestoreSessionState.failed;
  bool get isTerminal =>
      state == ExpenseCloudRestoreSessionState.cancelled ||
      state == ExpenseCloudRestoreSessionState.completed;

  Map<String, Object?> toMap() => {
    'id': id,
    'requestId': requestId,
    'mode': mode.name,
    'state': state.name,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'expectedDownloadBytes': expectedDownloadBytes,
    'completedDownloadBytes': completedDownloadBytes,
    'totalRecords': totalRecords,
    'completedRecords': completedRecords,
    'failureReason': failureReason,
  };
}

/// Persists resumable restore state before a transfer begins. The caller owns
/// server authorization and all network work; this store only records safe
/// local progress and never overwrites a terminal session.
class ExpenseCloudRestoreSessionStore extends ChangeNotifier {
  ExpenseCloudRestoreSessionStore._(this._box);

  static const boxName = 'expense_cloud_restore_sessions_v1';

  static Future<ExpenseCloudRestoreSessionStore> create() async {
    return ExpenseCloudRestoreSessionStore._(
      await Hive.openBox<dynamic>(boxName),
    );
  }

  final Box<dynamic> _box;
  Future<void> _writeTail = Future<void>.value();

  ExpenseCloudRestoreSession? sessionById(String id) {
    final value = _box.get(id.trim());
    return value is Map ? ExpenseCloudRestoreSession.fromMap(value) : null;
  }

  Future<void> savePrepared({
    required String id,
    required String requestId,
    required ExpenseCloudRestoreStoragePlan plan,
    required int totalRecords,
    DateTime? nowUtc,
  }) => _enqueue(() async {
    final sessionId = _required(id, 'Restore session ID');
    final safeRequestId = _required(requestId, 'Restore request ID');
    if (!plan.canStart) {
      throw StateError('Restore storage requirements are not satisfied.');
    }
    final existing = sessionById(sessionId);
    if (existing?.isTerminal ?? false) {
      throw StateError('This restore session is already finished.');
    }
    if (existing != null && existing.requestId != safeRequestId) {
      throw StateError('This restore session belongs to another request.');
    }
    final now = (nowUtc ?? DateTime.now().toUtc()).toUtc();
    await _write(
      ExpenseCloudRestoreSession(
        id: sessionId,
        requestId: safeRequestId,
        mode: plan.mode,
        state: ExpenseCloudRestoreSessionState.prepared,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
        expectedDownloadBytes: plan.knownDownloadBytes,
        completedDownloadBytes: existing?.completedDownloadBytes ?? 0,
        totalRecords: totalRecords < 0 ? 0 : totalRecords,
        completedRecords: existing?.completedRecords ?? 0,
      ),
    );
  });

  Future<void> updateProgress({
    required String id,
    required int completedDownloadBytes,
    required int completedRecords,
    DateTime? nowUtc,
  }) => _enqueue(() async {
    final current = _active(id);
    final now = (nowUtc ?? DateTime.now().toUtc()).toUtc();
    await _write(
      ExpenseCloudRestoreSession(
        id: current.id,
        requestId: current.requestId,
        mode: current.mode,
        state: ExpenseCloudRestoreSessionState.transferring,
        createdAt: current.createdAt,
        updatedAt: now,
        expectedDownloadBytes: current.expectedDownloadBytes,
        completedDownloadBytes: _maxBounded(
          current.completedDownloadBytes,
          completedDownloadBytes,
          current.expectedDownloadBytes,
        ),
        totalRecords: current.totalRecords,
        completedRecords: _maxBounded(
          current.completedRecords,
          completedRecords,
          current.totalRecords,
        ),
      ),
    );
  });

  Future<void> pause(String id, {DateTime? nowUtc}) => _enqueue(
    () => _changeState(
      id,
      ExpenseCloudRestoreSessionState.paused,
      nowUtc: nowUtc,
    ),
  );

  Future<void> fail(String id, String reason, {DateTime? nowUtc}) => _enqueue(
    () => _changeState(
      id,
      ExpenseCloudRestoreSessionState.failed,
      failureReason: _required(reason, 'Restore failure reason'),
      nowUtc: nowUtc,
    ),
  );

  Future<void> cancel(String id, {DateTime? nowUtc}) => _enqueue(
    () => _changeState(
      id,
      ExpenseCloudRestoreSessionState.cancelled,
      nowUtc: nowUtc,
    ),
  );

  Future<void> complete(String id, {DateTime? nowUtc}) => _enqueue(() async {
    final current = _active(id);
    await _write(
      ExpenseCloudRestoreSession(
        id: current.id,
        requestId: current.requestId,
        mode: current.mode,
        state: ExpenseCloudRestoreSessionState.completed,
        createdAt: current.createdAt,
        updatedAt: (nowUtc ?? DateTime.now().toUtc()).toUtc(),
        expectedDownloadBytes: current.expectedDownloadBytes,
        completedDownloadBytes: current.expectedDownloadBytes,
        totalRecords: current.totalRecords,
        completedRecords: current.totalRecords,
      ),
    );
  });

  Future<void> _changeState(
    String id,
    ExpenseCloudRestoreSessionState state, {
    String? failureReason,
    DateTime? nowUtc,
  }) async {
    final current = _active(id);
    await _write(
      ExpenseCloudRestoreSession(
        id: current.id,
        requestId: current.requestId,
        mode: current.mode,
        state: state,
        createdAt: current.createdAt,
        updatedAt: (nowUtc ?? DateTime.now().toUtc()).toUtc(),
        expectedDownloadBytes: current.expectedDownloadBytes,
        completedDownloadBytes: current.completedDownloadBytes,
        totalRecords: current.totalRecords,
        completedRecords: current.completedRecords,
        failureReason: failureReason,
      ),
    );
  }

  ExpenseCloudRestoreSession _active(String id) {
    final session = sessionById(_required(id, 'Restore session ID'));
    if (session == null) {
      throw StateError('Restore session was not found.');
    }
    if (session.isTerminal) {
      throw StateError('This restore session is already finished.');
    }
    return session;
  }

  Future<void> _write(ExpenseCloudRestoreSession session) async {
    await _box.put(session.id, session.toMap());
    notifyListeners();
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final next = _writeTail.then((_) => operation());
    _writeTail = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }
}

String _required(String value, String name) {
  final clean = value.trim();
  if (clean.isEmpty) throw StateError('$name is required.');
  return clean;
}

int _nonNegative(Object? value) => value is int && value > 0 ? value : 0;
int _bounded(int value, int maximum) =>
    value.clamp(0, maximum < 0 ? 0 : maximum);
int _maxBounded(int current, int incoming, int maximum) =>
    _bounded(current > incoming ? current : incoming, maximum);
String _text(Object? value) => value is String ? value.trim() : '';
String? _nullableText(Object? value) {
  final text = _text(value);
  return text.isEmpty ? null : text;
}

DateTime? _date(Object? value) =>
    value is String ? DateTime.tryParse(value)?.toUtc() : null;
ExpenseCloudRestoreMode _mode(Object? value) => switch (_text(value)) {
  'full' => ExpenseCloudRestoreMode.full,
  'smart' => ExpenseCloudRestoreMode.smart,
  _ => ExpenseCloudRestoreMode.recordsOnly,
};
