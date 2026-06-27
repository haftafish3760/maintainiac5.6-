import 'package:hive_flutter/hive_flutter.dart';

import 'expense_screen_telemetry_firestore_bridge.dart';

class ExpenseTelemetrySummaryScheduleResult {
  const ExpenseTelemetrySummaryScheduleResult({
    required this.status,
    this.queuedPath,
    this.nextAllowedAtUtc,
  });

  final ExpenseTelemetrySummaryScheduleStatus status;
  final String? queuedPath;
  final DateTime? nextAllowedAtUtc;
}

enum ExpenseTelemetrySummaryScheduleStatus { skipped, throttled, queued }

class ExpenseTelemetrySummaryScheduler {
  ExpenseTelemetrySummaryScheduler._({
    required Box<dynamic> box,
    required ExpenseTelemetryFirestoreBridge bridge,
    required Duration minInterval,
  }) : _box = box,
       _bridge = bridge,
       _minInterval = minInterval;

  static const boxName = 'expense_telemetry_summary_schedule_v1';
  static const defaultMinInterval = Duration(minutes: 15);

  final Box<dynamic> _box;
  final ExpenseTelemetryFirestoreBridge _bridge;
  final Duration _minInterval;

  static Future<ExpenseTelemetrySummaryScheduler> create({
    Duration minInterval = defaultMinInterval,
  }) async {
    return ExpenseTelemetrySummaryScheduler._(
      box: await Hive.openBox<dynamic>(boxName),
      bridge: await ExpenseTelemetryFirestoreBridge.create(),
      minInterval: minInterval,
    );
  }

  Future<ExpenseTelemetrySummaryScheduleResult> queueIfDue({
    required String orgId,
    String summaryId = 'latest',
    DateTime? nowUtc,
    bool force = false,
  }) async {
    final cleanOrgId = _safeOrgId(orgId);
    if (cleanOrgId.isEmpty) {
      return const ExpenseTelemetrySummaryScheduleResult(
        status: ExpenseTelemetrySummaryScheduleStatus.skipped,
      );
    }
    final now = (nowUtc ?? DateTime.now().toUtc()).toUtc();
    final key = _keyFor(cleanOrgId, summaryId);
    final lastQueuedAt = DateTime.tryParse(_box.get(key)?.toString() ?? '');
    if (!force && lastQueuedAt != null) {
      final nextAllowedAt = lastQueuedAt.toUtc().add(_minInterval);
      if (now.isBefore(nextAllowedAt)) {
        return ExpenseTelemetrySummaryScheduleResult(
          status: ExpenseTelemetrySummaryScheduleStatus.throttled,
          nextAllowedAtUtc: nextAllowedAt,
        );
      }
    }

    final result = await _bridge.queueHealthSummary(
      orgId: cleanOrgId,
      summaryId: summaryId,
      nowUtc: now,
    );
    await _box.put(key, now.toIso8601String());
    return ExpenseTelemetrySummaryScheduleResult(
      status: ExpenseTelemetrySummaryScheduleStatus.queued,
      queuedPath: result.queuedDocument.path,
    );
  }

  static String _keyFor(String orgId, String summaryId) {
    return '${_safeOrgId(orgId)}:${_safeOrgId(summaryId)}';
  }

  static String _safeOrgId(String value) {
    return value
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9_.-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
}
