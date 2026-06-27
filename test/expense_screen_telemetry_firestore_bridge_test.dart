import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/expenses/data/expense_screen_telemetry.dart';
import 'package:maintaniac/screens/expenses/data/expense_screen_telemetry_firestore_bridge.dart';
import 'package:maintaniac/screens/expenses/data/expense_screen_telemetry_summary_scheduler.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_schema.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_upload_queue.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'expense_telemetry_firestore_bridge_test_',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  test('queues one privacy-safe expense health summary document', () async {
    final telemetry = await ExpenseTelemetryStore.create();
    final queue = await MaintainiacFirestoreUploadQueueStore.create();
    await telemetry.enqueue(
      const ExpenseTelemetryEvent(type: ExpenseTelemetryEventType.screenOpened),
      queuedAtUtc: DateTime.utc(2026, 6, 24, 12),
    );
    await telemetry.enqueue(
      const ExpenseTelemetryEvent(
        type: ExpenseTelemetryEventType.saveFailure,
        failureKind: 'ledger_save_failed',
        diagnostic: ExpenseFailureDiagnostic(
          workflowStep: ExpenseWorkflowStep.saveExpense,
          failedAt: 'ledger_save_receipt',
          confirmedCause: 'cause_not_confirmed_ledger_save_failed',
          causeStatus: ExpenseFailureCauseStatus.notConfirmed,
          evidence: 'ledger_save_threw_exception',
          missingEvidence: 'exception_type_and_hive_box_state',
        ),
      ),
      queuedAtUtc: DateTime.utc(2026, 6, 24, 12, 1),
    );

    final result = await ExpenseTelemetryFirestoreBridge(
      telemetryStore: telemetry,
      queueStore: queue,
    ).queueHealthSummary(orgId: 'ORG-1', nowUtc: DateTime.utc(2026, 6, 24, 13));

    expect(result.snapshot.totalEventCount, 2);
    expect(queue.pendingRecords, hasLength(1));
    expect(
      queue.pendingRecords.single.path,
      'orgs/ORG-1/${MaintainiacFirestoreSchema.orgExpenseTelemetrySummaries}/latest',
    );
    expect(
      queue.pendingRecords.single.data['schema'],
      'expense_telemetry_summary_v1',
    );
    expect(queue.pendingRecords.single.data['rawEventUploadCount'], 0);
    expect(queue.pendingRecords.single.data['saveFailureCount'], 1);
    expect(
      queue.pendingRecords.single.data.toString(),
      contains('cause_not_confirmed_ledger_save_failed'),
    );
    expect(
      queue.pendingRecords.single.data.toString().toLowerCase(),
      isNot(contains('receipt text')),
    );
  });

  test(
    'throttles repeated summary queueing and replaces pending summary',
    () async {
      final telemetry = await ExpenseTelemetryStore.create();
      final queue = await MaintainiacFirestoreUploadQueueStore.create();
      await telemetry.enqueue(
        const ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.screenOpened,
        ),
        queuedAtUtc: DateTime.utc(2026, 6, 24, 12),
      );

      final scheduler = await ExpenseTelemetrySummaryScheduler.create(
        minInterval: const Duration(minutes: 15),
      );
      final first = await scheduler.queueIfDue(
        orgId: 'ORG-1',
        nowUtc: DateTime.utc(2026, 6, 24, 13),
      );
      final second = await scheduler.queueIfDue(
        orgId: 'ORG-1',
        nowUtc: DateTime.utc(2026, 6, 24, 13, 5),
      );
      final forced = await scheduler.queueIfDue(
        orgId: 'ORG-1',
        nowUtc: DateTime.utc(2026, 6, 24, 13, 6),
        force: true,
      );

      expect(first.status, ExpenseTelemetrySummaryScheduleStatus.queued);
      expect(second.status, ExpenseTelemetrySummaryScheduleStatus.throttled);
      expect(forced.status, ExpenseTelemetrySummaryScheduleStatus.queued);
      expect(queue.pendingRecords, hasLength(1));
      expect(
        queue.pendingRecords.single.path,
        'orgs/ORG-1/${MaintainiacFirestoreSchema.orgExpenseTelemetrySummaries}/latest',
      );
      expect(
        queue.pendingRecords.single.queuedAtUtc,
        DateTime.utc(2026, 6, 24, 13, 6),
      );
    },
  );
}
