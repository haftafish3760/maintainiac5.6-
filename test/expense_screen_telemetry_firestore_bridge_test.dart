import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/expenses/data/expense_export_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_store.dart';
import 'package:maintaniac/screens/expenses/data/expense_screen_telemetry.dart';
import 'package:maintaniac/screens/expenses/data/expense_screen_telemetry_firestore_bridge.dart';
import 'package:maintaniac/screens/expenses/data/expense_screen_telemetry_summary_scheduler.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_documents.dart';
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
        type: ExpenseTelemetryEventType.syncPending,
        metadata: {
          'syncState': 'expense_summary_queued',
          'summaryStatus': 'queued',
          'ocrContractQueued': true,
          'ocrContractSource': 'rolling_local_ledger',
        },
      ),
      queuedAtUtc: DateTime.utc(2026, 6, 24, 12, 30),
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

    expect(result.snapshot.totalEventCount, 3);
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
    expect(queue.pendingRecords.single.data['expenseSummaryQueuedCount'], 1);
    expect(
      queue.pendingRecords.single.data['expenseSummaryOcrContractQueuedCount'],
      1,
    );
    expect(
      queue.pendingRecords.single.data['expenseSummaryOcrContractSourceCounts'],
      {'rolling_local_ledger': 1},
    );
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
    'summarizes high-volume receipt telemetry into one bounded Firestore write',
    () async {
      final telemetry = await ExpenseTelemetryStore.create();
      final queue = await MaintainiacFirestoreUploadQueueStore.create();

      for (var i = 0; i < 240; i++) {
        await telemetry.enqueue(
          ExpenseTelemetryEvent(
            type: i.isEven
                ? ExpenseTelemetryEventType.ocrFailed
                : ExpenseTelemetryEventType.imageAttachFailure,
            failureKind: i.isEven ? 'no_readable_text' : 'camera_focus_failed',
            diagnostic: ExpenseFailureDiagnostic(
              workflowStep: i.isEven
                  ? ExpenseWorkflowStep.receiptOcr
                  : ExpenseWorkflowStep.receiptAttachment,
              failedAt: i.isEven
                  ? 'after_attachment_read_before_parser'
                  : 'before_photo_saved',
              confirmedCause: i.isEven
                  ? 'no_readable_text'
                  : 'camera_focus_or_exposure_failed',
              causeStatus: ExpenseFailureCauseStatus.confirmed,
              evidence: i.isEven
                  ? 'ocr_severity_blocked_source_photo'
                  : 'camera_quality_gate_failed_source_photo',
              missingEvidence: 'none',
              retryCount: i % 4,
              abandoned: i % 5 == 0,
            ),
          ),
          queuedAtUtc: DateTime.utc(2026, 6, 24, 12, i),
        );
      }

      final bridge = ExpenseTelemetryFirestoreBridge(
        telemetryStore: telemetry,
        queueStore: queue,
      );
      final first = await bridge.queueHealthSummary(
        orgId: 'ORG-1',
        nowUtc: DateTime.utc(2026, 6, 24, 16),
      );
      final second = await bridge.queueHealthSummary(
        orgId: 'ORG-1',
        nowUtc: DateTime.utc(2026, 6, 24, 16, 5),
      );

      expect(first.snapshot.totalEventCount, 240);
      expect(second.snapshot.totalEventCount, 240);
      expect(queue.pendingRecords, hasLength(1));
      final queued = queue.pendingRecords.single;
      expect(
        queued.path,
        'orgs/ORG-1/${MaintainiacFirestoreSchema.orgExpenseTelemetrySummaries}/latest',
      );
      expect(queued.queuedAtUtc, DateTime.utc(2026, 6, 24, 16, 5));
      expect(
        queued.data['uploadShape'],
        ExpenseTelemetryFirestoreWriteBudget.uploadShape,
      );
      expect(
        queued.data['rawEventUploadCount'],
        ExpenseTelemetryFirestoreWriteBudget.rawEventUploadCount,
      );
      expect(queued.data['ocrFailedCount'], 120);
      expect(queued.data['imageAttachFailureCount'], 120);
      expect(queued.data['failureBreakdowns'], hasLength(2));
      expect(queued.data['recentFailureDetails'], hasLength(50));
      expect(
        ExpenseTelemetryFirestoreWriteBudget.estimatedScheduledSummaryWritesPerDay(
          ExpenseTelemetrySummaryScheduler.defaultMinInterval,
        ),
        96,
      );
      expect(
        ExpenseTelemetryFirestoreWriteBudget.dailyFirestoreWriteSafetyTarget,
        20000,
      );
      expect(
        queued.data.toString().toLowerCase(),
        isNot(contains('receipt text')),
      );
      expect(queued.data.toString().toLowerCase(), isNot(contains('customer')));
    },
  );

  test('queues OCR contract inside the same expense health document', () async {
    final telemetry = await ExpenseTelemetryStore.create();
    final queue = await MaintainiacFirestoreUploadQueueStore.create();
    await telemetry.enqueue(
      const ExpenseTelemetryEvent(type: ExpenseTelemetryEventType.ocrCompleted),
      queuedAtUtc: DateTime.utc(2026, 6, 24, 12),
    );
    final ocrContract = ExpenseExportSnapshot(
      exportedAt: DateTime.utc(2026, 6, 24, 13),
      range: ExpenseDateRange(
        start: DateTime(2026, 6, 1),
        end: DateTime(2026, 6, 30),
      ),
      categoryFilter: ExpenseExportCategoryFilter.all,
      receipts: [
        ExpenseReceiptRecord(
          id: 'EXP-ocr-queue',
          receiptDate: DateTime(2026, 6, 24),
          ocrReview: const ExpenseReceiptOcrReview(
            severity: 'good',
            source: 'photo',
            attachmentsRead: 1,
            parserLineCount: 2,
          ),
          lines: const [
            ExpenseReceiptLineRecord(
              id: 'LINE-ocr-queue',
              description: 'Receipt line',
              category: 'Supplies',
              use: ExpenseLineUse.business,
              quantity: 1,
              unitsPerPackage: 1,
              unit: 'each',
              subtotal: 12,
            ),
          ],
        ),
      ],
    ).commandCenterOcrContract;

    await ExpenseTelemetryFirestoreBridge(
      telemetryStore: telemetry,
      queueStore: queue,
    ).queueHealthSummary(
      orgId: 'ORG-1',
      nowUtc: DateTime.utc(2026, 6, 24, 13),
      commandCenterOcrContract: ocrContract,
    );

    expect(queue.pendingRecords, hasLength(1));
    final queuedData = queue.pendingRecords.single.data;
    expect(queuedData['uploadShape'], 'single_summary_document');
    expect(queuedData['rawEventUploadCount'], 0);
    final embedded =
        queuedData['commandCenterOcrContract'] as Map<String, Object?>;
    expect(embedded['ocrReadsSaved'], 1);
    expect(embedded['ocrCleanReadCount'], 1);
    expect(embedded['ocrReadStatus'], 'All reads saved');
    expect(embedded['ocrSourceCounts'], {'photo': 1});
    final queuedRecord = queue.pendingRecords.single;
    expect(
      MaintainiacFirestoreDocumentBuilder.expenseTelemetrySummaryOcrContractFindingsFor(
        MaintainiacFirestoreDocumentDraft(
          path: queuedRecord.path,
          data: queuedRecord.data,
        ),
      ),
      isEmpty,
    );
    expect(
      queuedData.toString().toLowerCase(),
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
