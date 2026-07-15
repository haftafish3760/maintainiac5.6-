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
    final id = _required(_text(map['id']), 'Restore session ID');
    final requestId = _required(_text(map['requestId']), 'Restore request ID');
    final createdAt = _date(map['createdAt']);
    final updatedAt = _date(map['updatedAt']);
    if (createdAt == null ||
        updatedAt == null ||
        updatedAt.isBefore(createdAt)) {
      throw const FormatException('Restore session lifecycle is corrupt.');
    }
    final expectedDownloadBytes = _nonNegative(map['expectedDownloadBytes']);
    final completedDownloadBytes = _nonNegative(map['completedDownloadBytes']);
    final totalRecords = _nonNegative(map['totalRecords']);
    final completedRecords = _nonNegative(map['completedRecords']);
    if (completedDownloadBytes > expectedDownloadBytes ||
        completedRecords > totalRecords) {
      throw const FormatException('Restore session progress is corrupt.');
    }
    return ExpenseCloudRestoreSession(
      id: id,
      requestId: requestId,
      mode: _mode(map['mode']),
      state: _state(map['state']),
      createdAt: createdAt,
      updatedAt: updatedAt,
      expectedDownloadBytes: expectedDownloadBytes,
      completedDownloadBytes: completedDownloadBytes,
      totalRecords: totalRecords,
      completedRecords: completedRecords,
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
  bool get hasCompletedTransfer =>
      completedDownloadBytes >= expectedDownloadBytes &&
      completedRecords >= totalRecords;

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
    if (value is! Map) return null;
    try {
      return ExpenseCloudRestoreSession.fromMap(value);
    } on FormatException {
      return null;
    } on StateError {
      return null;
    }
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
        completedDownloadBytes: _bounded(
          existing?.completedDownloadBytes ?? 0,
          plan.knownDownloadBytes,
        ),
        totalRecords: totalRecords < 0 ? 0 : totalRecords,
        completedRecords: _bounded(
          existing?.completedRecords ?? 0,
          totalRecords < 0 ? 0 : totalRecords,
        ),
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
    if (!current.hasCompletedTransfer) {
      throw StateError('Restore transfer is not complete yet.');
    }
    await _write(
      ExpenseCloudRestoreSession(
        id: current.id,
        requestId: current.requestId,
        mode: current.mode,
        state: ExpenseCloudRestoreSessionState.completed,
        createdAt: current.createdAt,
        updatedAt: (nowUtc ?? DateTime.now().toUtc()).toUtc(),
        expectedDownloadBytes: current.expectedDownloadBytes,
        completedDownloadBytes: current.completedDownloadBytes,
        totalRecords: current.totalRecords,
        completedRecords: current.completedRecords,
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
  'recordsOnly' => ExpenseCloudRestoreMode.recordsOnly,
  _ => throw const FormatException('Restore session mode is corrupt.'),
};

ExpenseCloudRestoreSessionState _state(Object? value) {
  final name = _text(value);
  for (final state in ExpenseCloudRestoreSessionState.values) {
    if (state.name == name) return state;
  }
  throw const FormatException('Restore session state is corrupt.');
}
