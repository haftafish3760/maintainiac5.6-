import 'package:hive_flutter/hive_flutter.dart';

import 'expense_export_models.dart';
import 'expense_ledger_models.dart';
import 'expense_ledger_store.dart';
import 'expense_screen_telemetry_firestore_bridge.dart';

class ExpenseTelemetrySummaryScheduleResult {
  const ExpenseTelemetrySummaryScheduleResult({
    required this.status,
    this.queuedPath,
    this.nextAllowedAtUtc,
    this.ocrContractQueued = false,
    this.ocrContractSource = 'none',
    this.ocrContractSkippedReason = '',
  });

  final ExpenseTelemetrySummaryScheduleStatus status;
  final String? queuedPath;
  final DateTime? nextAllowedAtUtc;
  final bool ocrContractQueued;
  final String ocrContractSource;
  final String ocrContractSkippedReason;
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
    Map<String, Object?>? commandCenterOcrContract,
    bool includeLedgerOcrContract = true,
    Duration ocrContractLookback = const Duration(days: 90),
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

    final ocrContractBuild = await _resolveOcrContract(
      nowUtc: now,
      explicitContract: commandCenterOcrContract,
      includeLedgerOcrContract: includeLedgerOcrContract,
      lookback: ocrContractLookback,
    );
    final result = await _bridge.queueHealthSummary(
      orgId: cleanOrgId,
      summaryId: summaryId,
      nowUtc: now,
      commandCenterOcrContract: ocrContractBuild.contract,
    );
    await _box.put(key, now.toIso8601String());
    return ExpenseTelemetrySummaryScheduleResult(
      status: ExpenseTelemetrySummaryScheduleStatus.queued,
      queuedPath: result.queuedDocument.path,
      ocrContractQueued: ocrContractBuild.contract != null,
      ocrContractSource: ocrContractBuild.source,
      ocrContractSkippedReason: ocrContractBuild.skippedReason,
    );
  }

  static Future<_ScheduledOcrContractBuild> _resolveOcrContract({
    required DateTime nowUtc,
    required Map<String, Object?>? explicitContract,
    required bool includeLedgerOcrContract,
    required Duration lookback,
  }) async {
    if (explicitContract != null) {
      return _ScheduledOcrContractBuild(
        contract: explicitContract,
        source: 'explicit',
      );
    }
    if (!includeLedgerOcrContract) {
      return const _ScheduledOcrContractBuild(
        source: 'none',
        skippedReason: 'ledger_ocr_contract_disabled',
      );
    }
    try {
      final ledger = await ExpenseLedgerController.create();
      final end = DateTime(nowUtc.year, nowUtc.month, nowUtc.day);
      final safeLookback = lookback.isNegative ? Duration.zero : lookback;
      final start = DateTime(
        end.year,
        end.month,
        end.day,
      ).subtract(safeLookback);
      final snapshot = buildExpenseExportSnapshot(
        receipts: ledger.storedReceipts,
        range: ExpenseDateRange(start: start, end: end),
        categoryFilter: ExpenseExportCategoryFilter.all,
        source: ExpenseExportSource.localDevice,
        destination: ExpenseExportDestination.share,
        exportedAt: nowUtc,
      );
      return _ScheduledOcrContractBuild(
        contract: snapshot.commandCenterOcrContract,
        source: 'rolling_local_ledger',
      );
    } catch (_) {
      return const _ScheduledOcrContractBuild(
        source: 'none',
        skippedReason: 'ledger_ocr_contract_unavailable',
      );
    }
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

class _ScheduledOcrContractBuild {
  const _ScheduledOcrContractBuild({
    this.contract,
    required this.source,
    this.skippedReason = '',
  });

  final Map<String, Object?>? contract;
  final String source;
  final String skippedReason;
}
