import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_store.dart';
import 'package:maintaniac/screens/expenses/data/expense_screen_telemetry.dart';
import 'package:maintaniac/screens/expenses/data/expense_screen_telemetry_summary_scheduler.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_documents.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_schema.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_upload_queue.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'expense_telemetry_summary_scheduler_firestore_test_',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      await hiveDirectory.delete(recursive: true);
    }
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

  test(
    'scheduler queues rolling ledger OCR contract in the summary document',
    () async {
      final telemetry = await ExpenseTelemetryStore.create();
      final queue = await MaintainiacFirestoreUploadQueueStore.create();
      final ledger = await ExpenseLedgerController.create();
      await telemetry.enqueue(
        const ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.ocrCompleted,
        ),
        queuedAtUtc: DateTime.utc(2026, 6, 24, 12),
      );
      await ledger.saveReceipt(
        ExpenseReceiptRecord(
          id: 'EXP-scheduler-ocr',
          receiptDate: DateTime(2026, 6, 23),
          ocrReview: const ExpenseReceiptOcrReview(
            severity: 'review',
            source: 'photo',
            primaryWarningKind: 'sectionGap',
            primaryWarningTargetLabel: 'Check missing receipt section',
            primaryWarningTargetInstruction:
                'Add the missing middle photo if the receipt is incomplete.',
            recoveryAction: 'add_missing_section',
            recoveryTarget: 'receipt_sections',
            warningCount: 1,
            reviewWarningCount: 1,
          ),
          lines: const [
            ExpenseReceiptLineRecord(
              id: 'LINE-scheduler-ocr',
              description: 'Private line description must not upload',
              category: 'Supplies',
              use: ExpenseLineUse.business,
              quantity: 1,
              unitsPerPackage: 1,
              unit: 'each',
              subtotal: 12,
            ),
          ],
        ),
      );

      final scheduler = await ExpenseTelemetrySummaryScheduler.create(
        minInterval: const Duration(minutes: 15),
      );
      final result = await scheduler.queueIfDue(
        orgId: 'ORG-1',
        nowUtc: DateTime.utc(2026, 6, 24, 13),
      );

      expect(result.status, ExpenseTelemetrySummaryScheduleStatus.queued);
      expect(result.ocrContractQueued, isTrue);
      expect(result.ocrContractSource, 'rolling_local_ledger');
      expect(result.ocrContractSkippedReason, isEmpty);
      expect(queue.pendingRecords, hasLength(1));
      final queued = queue.pendingRecords.single;
      final embedded =
          queued.data['commandCenterOcrContract'] as Map<String, Object?>;
      expect(embedded['receiptCount'], 1);
      expect(embedded['receiptsNeedingOcrReview'], 1);
      expect(embedded['ocrRecoveryActionCounts'], {'add_missing_section': 1});
      expect(embedded['ocrRecoveryTargetCounts'], {'receipt_sections': 1});
      expect(
        MaintainiacFirestoreDocumentBuilder.expenseTelemetrySummaryOcrContractFindingsFor(
          MaintainiacFirestoreDocumentDraft(
            path: queued.path,
            data: queued.data,
          ),
        ),
        isEmpty,
      );
      expect(
        queued.data.toString().toLowerCase(),
        isNot(contains('private line description')),
      );
    },
  );

  test(
    'scheduler can skip ledger OCR contract for non-OCR summary runs',
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
      final result = await scheduler.queueIfDue(
        orgId: 'ORG-1',
        nowUtc: DateTime.utc(2026, 6, 24, 13),
        includeLedgerOcrContract: false,
      );

      expect(result.status, ExpenseTelemetrySummaryScheduleStatus.queued);
      expect(result.ocrContractQueued, isFalse);
      expect(result.ocrContractSource, 'none');
      expect(result.ocrContractSkippedReason, 'ledger_ocr_contract_disabled');
      expect(queue.pendingRecords, hasLength(1));
      expect(
        queue.pendingRecords.single.data.containsKey(
          'commandCenterOcrContract',
        ),
        isFalse,
      );
    },
  );
}
