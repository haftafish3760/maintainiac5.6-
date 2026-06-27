import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/expenses/data/expense_screen_telemetry.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'expense_screen_telemetry_test_',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  test('queues privacy-safe expense screen events locally first', () async {
    final store = await ExpenseTelemetryStore.create();
    final context = _context();

    await store.enqueue(
      ExpenseTelemetryEvent(
        type: ExpenseTelemetryEventType.screenOpened,
        context: context,
      ),
      queuedAtUtc: DateTime.utc(2026, 6, 24, 12),
    );
    await store.enqueue(
      ExpenseTelemetryEvent(
        type: ExpenseTelemetryEventType.addExpenseStarted,
        context: context,
        metadata: const {'entryMode': 'receipt'},
      ),
      queuedAtUtc: DateTime.utc(2026, 6, 24, 12, 1),
    );
    await store.enqueue(
      ExpenseTelemetryEvent(
        type: ExpenseTelemetryEventType.addExpenseCompleted,
        context: context,
        metadata: const {'saveDestination': 'local_first'},
      ),
      queuedAtUtc: DateTime.utc(2026, 6, 24, 12, 2),
    );

    expect(store.records, hasLength(3));
    expect(store.pendingUploadRecords, hasLength(3));
    expect(store.pendingUploadPayloads(), hasLength(3));
    expect(
      store.pendingUploadPayloads().first['payload'],
      containsPair('platform', 'android'),
    );
  });

  test(
    'rejects receipt text and private user content before storage',
    () async {
      final store = await ExpenseTelemetryStore.create();

      expect(
        () => ExpenseTelemetryPolicy.sanitizeMap({
          'event': ExpenseTelemetryEventType.receiptExpenseCreated.name,
          'receiptText': 'LOWES COPPER PIPE TOTAL 99.99',
        }),
        throwsArgumentError,
      );
      expect(
        () => ExpenseTelemetryPolicy.sanitize(
          ExpenseTelemetryEvent(
            type: ExpenseTelemetryEventType.validationError,
            metadata: const {'notes': 'Customer asked me to hide this'},
          ),
        ),
        throwsArgumentError,
      );
      expect(
        store.enqueue(
          const ExpenseTelemetryEvent(
            type: ExpenseTelemetryEventType.saveFailure,
            failureKind: 'PRIVATE STORE 99.99',
          ),
        ),
        throwsArgumentError,
      );
    },
  );

  test(
    'builds command center summary without private receipt details',
    () async {
      final store = await ExpenseTelemetryStore.create();
      final context = _context();

      await store.enqueue(
        ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.screenOpened,
          context: context,
        ),
      );
      await store.enqueue(
        ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.timeSpentOnScreen,
          context: context,
          durationMs: 120000,
        ),
      );
      await store.enqueue(
        ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.addExpenseStarted,
          context: context,
        ),
      );
      await store.enqueue(
        ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.addExpenseAbandoned,
          context: context,
        ),
      );
      await store.enqueue(
        ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.ocrStarted,
          context: context,
        ),
      );
      await store.enqueue(
        ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.ocrFailed,
          context: context,
          failureKind: 'no_readable_text',
          diagnostic: const ExpenseFailureDiagnostic(
            workflowStep: ExpenseWorkflowStep.receiptOcr,
            failedAt: 'after_attachment_read_before_parser',
            confirmedCause: 'no_readable_text',
            causeStatus: ExpenseFailureCauseStatus.confirmed,
            evidence: 'ocr_zero_lines',
            missingEvidence: 'none',
          ),
        ),
      );
      await store.enqueue(
        ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.userCorrectedVendor,
          context: context,
        ),
      );
      await store.enqueue(
        ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.cloudBackupFailure,
          context: context,
          failureKind: 'quota_limit',
        ),
      );
      await store.enqueue(
        ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.syncFailed,
          context: context,
          failureKind: 'offline',
        ),
      );

      final snapshot = store.buildHealthSnapshot(
        nowUtc: DateTime.utc(2026, 6, 24, 13),
      );
      final map = snapshot.toCommandCenterMap();
      final encoded = map.toString().toLowerCase();

      expect(map['schema'], 'expense_screen_telemetry_health_v1');
      expect(snapshot.screenOpenCount, 1);
      expect(snapshot.averageTimeSpentSeconds, 120);
      expect(snapshot.addExpenseAbandonmentRate, 1);
      expect(snapshot.ocrSuccessRate, 0);
      expect(snapshot.userCorrectionCount, 1);
      expect(snapshot.cloudBackupFailureRate, 1);
      expect(snapshot.syncFailureRate, 1);
      expect(snapshot.failureBreakdowns, isNotEmpty);
      expect(
        snapshot.failureBreakdowns.map((failure) => failure.confirmedCause),
        contains('no_readable_text'),
      );
      expect(snapshot.healthLabel, 'needs_attention');
      expect(encoded, isNot(contains('lowes')));
      expect(encoded, isNot(contains('customer')));
      expect(encoded, isNot(contains('99.99')));
    },
  );

  test('builds confirmed cause failure breakdowns for Command 1', () async {
    final store = await ExpenseTelemetryStore.create();
    final context = _context();

    await store.enqueue(
      ExpenseTelemetryEvent(
        type: ExpenseTelemetryEventType.ocrFailed,
        context: context,
        failureKind: 'no_readable_text',
        diagnostic: const ExpenseFailureDiagnostic(
          workflowStep: ExpenseWorkflowStep.receiptOcr,
          failedAt: 'after_attachment_read_before_parser',
          confirmedCause: 'no_readable_text',
          causeStatus: ExpenseFailureCauseStatus.confirmed,
          evidence: 'ocr_severity_blocked',
          missingEvidence: 'none',
          retryCount: 2,
          abandoned: true,
        ),
      ),
    );
    await store.enqueue(
      ExpenseTelemetryEvent(
        type: ExpenseTelemetryEventType.saveFailure,
        context: context,
        failureKind: 'ledger_save_failed',
        diagnostic: const ExpenseFailureDiagnostic(
          workflowStep: ExpenseWorkflowStep.saveExpense,
          failedAt: 'ledger_save_receipt',
          confirmedCause: 'cause_not_confirmed_ledger_save_failed',
          causeStatus: ExpenseFailureCauseStatus.notConfirmed,
          evidence: 'ledger_save_threw_exception',
          missingEvidence: 'exception_type_and_hive_box_state',
        ),
      ),
    );

    final snapshot = store.buildHealthSnapshot(
      nowUtc: DateTime.utc(2026, 6, 24, 13),
    );
    final map = snapshot.toCommandCenterMap();
    final failures = map['failureBreakdowns'] as List<Object?>;

    expect(snapshot.failureBreakdowns, hasLength(2));
    expect(snapshot.failureBreakdowns.first.confirmedCause, 'no_readable_text');
    expect(snapshot.failureBreakdowns.first.featureLabel, 'Expenses');
    expect(snapshot.failureBreakdowns.first.workflowStepLabel, 'Receipt OCR');
    expect(
      snapshot.failureBreakdowns.first.failedAtLabel,
      'After attachment read before parser',
    );
    expect(snapshot.failureBreakdowns.first.causeLabel, 'No readable text');
    expect(
      snapshot.failureBreakdowns.first.causeStatusLabel,
      'Confirmed cause',
    );
    expect(
      snapshot.failureBreakdowns.first.recommendedAction,
      contains('blank'),
    );
    expect(snapshot.failureBreakdowns.first.causeStatus, 'confirmed');
    expect(snapshot.failureBreakdowns.first.retryCount, 2);
    expect(snapshot.failureBreakdowns.first.abandonedCount, 1);
    expect(snapshot.recentFailureDetails, hasLength(2));
    expect(snapshot.recentFailureDetails.first.causeLabel, isNotEmpty);
    expect(
      snapshot.recentFailureDetails.first.missingEvidenceLabel,
      isNotEmpty,
    );
    expect(
      failures.toString(),
      contains('after_attachment_read_before_parser'),
    );
    expect(failures.toString(), contains('exception_type_and_hive_box_state'));
  });

  test('gives Command 1 cause-specific receipt OCR actions', () async {
    final store = await ExpenseTelemetryStore.create();
    final context = _context();

    await store.enqueue(
      ExpenseTelemetryEvent(
        type: ExpenseTelemetryEventType.ocrFailed,
        context: context,
        failureKind: 'receipt_photo_quality_needs_review',
        diagnostic: const ExpenseFailureDiagnostic(
          workflowStep: ExpenseWorkflowStep.receiptOcr,
          failedAt: 'during_photo_ocr_read',
          confirmedCause: 'receipt_photo_quality_needs_review',
          causeStatus: ExpenseFailureCauseStatus.confirmed,
          evidence: 'warning_photo_quality',
          missingEvidence: 'none',
        ),
      ),
    );

    final snapshot = store.buildHealthSnapshot(
      nowUtc: DateTime.utc(2026, 6, 24, 13),
    );

    expect(
      snapshot.failureBreakdowns.single.causeLabel,
      'Receipt photo quality needs review',
    );
    expect(
      snapshot.failureBreakdowns.single.recommendedAction,
      contains('retake'),
    );
    expect(
      snapshot.recentFailureDetails.single.recommendedAction,
      contains('focus'),
    );
  });

  test('tracks parser review and failure rates for Command 1', () async {
    final store = await ExpenseTelemetryStore.create();
    final context = _context();

    await store.enqueue(
      ExpenseTelemetryEvent(
        type: ExpenseTelemetryEventType.parserStarted,
        context: context,
      ),
    );
    await store.enqueue(
      ExpenseTelemetryEvent(
        type: ExpenseTelemetryEventType.parserNeedsReview,
        context: context,
        failureKind: 'receipt_line_total_mismatch',
        diagnostic: const ExpenseFailureDiagnostic(
          workflowStep: ExpenseWorkflowStep.receiptParser,
          failedAt: 'receipt_line_reconciliation',
          confirmedCause: 'receipt_line_total_mismatch',
          causeStatus: ExpenseFailureCauseStatus.confirmed,
          evidence: 'lines_8_review_2_reconciled_false',
          missingEvidence: 'none',
        ),
      ),
    );
    await store.enqueue(
      ExpenseTelemetryEvent(
        type: ExpenseTelemetryEventType.parserStarted,
        context: context,
      ),
    );
    await store.enqueue(
      ExpenseTelemetryEvent(
        type: ExpenseTelemetryEventType.parserFailed,
        context: context,
        failureKind: 'receipt_parser_no_usable_fields',
        diagnostic: const ExpenseFailureDiagnostic(
          workflowStep: ExpenseWorkflowStep.receiptParser,
          failedAt: 'after_ocr_text_before_receipt_fields',
          confirmedCause: 'receipt_parser_no_usable_fields',
          causeStatus: ExpenseFailureCauseStatus.confirmed,
          evidence: 'quality_poor_lines_0',
          missingEvidence: 'none',
        ),
      ),
    );

    final snapshot = store.buildHealthSnapshot(
      nowUtc: DateTime.utc(2026, 6, 24, 13),
    );
    final map = snapshot.toCommandCenterMap();

    expect(snapshot.parserStartedCount, 2);
    expect(snapshot.parserNeedsReviewCount, 1);
    expect(snapshot.parserFailedCount, 1);
    expect(snapshot.parserSuccessRate, 0);
    expect(snapshot.parserReviewRate, .5);
    expect(snapshot.parserFailureRate, .5);
    expect(map['parserFailureRate'], .5);
    expect(
      snapshot.failureBreakdowns.map((failure) => failure.confirmedCause),
      containsAll([
        'receipt_line_total_mismatch',
        'receipt_parser_no_usable_fields',
      ]),
    );
    expect(snapshot.failureBreakdowns.first.recommendedAction, isNotEmpty);
  });

  test(
    'tracks export completion, blocked exports, and export failure causes',
    () async {
      final store = await ExpenseTelemetryStore.create();
      final context = _context();

      await store.enqueue(
        ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.exportStarted,
          context: context,
          metadata: const {
            'exportDestination': 'share',
            'lineCount': 12,
            'receiptCount': 4,
          },
        ),
      );
      await store.enqueue(
        ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.exportBlocked,
          context: context,
          failureKind: 'monthly_export_limit_used',
          diagnostic: const ExpenseFailureDiagnostic(
            workflowStep: ExpenseWorkflowStep.export,
            failedAt: 'before_export_file_write',
            confirmedCause: 'monthly_export_limit_used',
            causeStatus: ExpenseFailureCauseStatus.confirmed,
            evidence: 'export_store_can_run_export_false',
            missingEvidence: 'none',
          ),
          metadata: const {
            'exportDestination': 'share',
            'lineCount': 12,
            'receiptCount': 4,
          },
        ),
      );
      await store.enqueue(
        ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.exportFailed,
          context: context,
          failureKind: 'export_handoff_not_completed',
          diagnostic: const ExpenseFailureDiagnostic(
            workflowStep: ExpenseWorkflowStep.export,
            failedAt: 'export_handoff',
            confirmedCause: 'export_handoff_not_completed',
            causeStatus: ExpenseFailureCauseStatus.confirmed,
            evidence: 'handoff_result_completed_false',
            missingEvidence: 'none',
            abandoned: true,
          ),
        ),
      );

      final snapshot = store.buildHealthSnapshot(
        nowUtc: DateTime.utc(2026, 6, 24, 13),
      );

      expect(snapshot.exportStartedCount, 1);
      expect(snapshot.exportBlockedCount, 1);
      expect(snapshot.exportFailedCount, 1);
      expect(snapshot.exportFailureRate, 1);
      expect(
        snapshot.failureBreakdowns.map((failure) => failure.confirmedCause),
        containsAll([
          'monthly_export_limit_used',
          'export_handoff_not_completed',
        ]),
      );
    },
  );

  test(
    'aggregates calendar receipt action failures by unconfirmed cause',
    () async {
      final store = await ExpenseTelemetryStore.create();
      final context = _context();

      await store.enqueue(
        ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.saveFailure,
          context: context,
          failureKind: 'calendar_delete_receipt_failed',
          diagnostic: const ExpenseFailureDiagnostic(
            workflowStep: ExpenseWorkflowStep.deleteExpense,
            failedAt: 'calendar_delete_receipt',
            confirmedCause:
                'cause_not_confirmed_calendar_delete_receipt_failed',
            causeStatus: ExpenseFailureCauseStatus.notConfirmed,
            evidence: 'delete_receipt_threw_exception',
            missingEvidence: 'exception_type_and_hive_box_state',
          ),
        ),
      );
      await store.enqueue(
        ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.saveFailure,
          context: context,
          failureKind: 'calendar_edit_line_failed',
          diagnostic: const ExpenseFailureDiagnostic(
            workflowStep: ExpenseWorkflowStep.calendarEdit,
            failedAt: 'calendar_receipt_line_save',
            confirmedCause: 'cause_not_confirmed_calendar_edit_line_failed',
            causeStatus: ExpenseFailureCauseStatus.notConfirmed,
            evidence: 'calendar_line_save_threw_exception',
            missingEvidence: 'exception_type_and_receipt_line_state',
          ),
        ),
      );
      await store.enqueue(
        ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.saveFailure,
          context: context,
          failureKind: 'calendar_copy_line_failed',
          diagnostic: const ExpenseFailureDiagnostic(
            workflowStep: ExpenseWorkflowStep.calendarEdit,
            failedAt: 'calendar_receipt_line_copy',
            confirmedCause: 'cause_not_confirmed_calendar_copy_line_failed',
            causeStatus: ExpenseFailureCauseStatus.notConfirmed,
            evidence: 'calendar_line_copy_threw_exception',
            missingEvidence: 'exception_type_and_receipt_line_state',
          ),
        ),
      );
      await store.enqueue(
        ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.saveFailure,
          context: context,
          failureKind: 'calendar_delete_line_failed',
          diagnostic: const ExpenseFailureDiagnostic(
            workflowStep: ExpenseWorkflowStep.deleteExpense,
            failedAt: 'calendar_receipt_line_delete',
            confirmedCause: 'cause_not_confirmed_calendar_delete_line_failed',
            causeStatus: ExpenseFailureCauseStatus.notConfirmed,
            evidence: 'delete_line_threw_exception',
            missingEvidence: 'exception_type_and_receipt_line_state',
          ),
        ),
      );

      final snapshot = store.buildHealthSnapshot(
        nowUtc: DateTime.utc(2026, 6, 24, 13),
      );

      expect(snapshot.saveFailureCount, 4);
      expect(snapshot.failureBreakdowns, hasLength(4));
      expect(
        snapshot.failureBreakdowns.map((failure) => failure.workflowStep),
        containsAll(['calendarEdit', 'deleteExpense']),
      );
      expect(
        snapshot.failureBreakdowns.map((failure) => failure.confirmedCause),
        containsAll([
          'cause_not_confirmed_calendar_delete_receipt_failed',
          'cause_not_confirmed_calendar_edit_line_failed',
          'cause_not_confirmed_calendar_copy_line_failed',
          'cause_not_confirmed_calendar_delete_line_failed',
        ]),
      );
    },
  );

  test('shows where receipt entry was abandoned', () async {
    final store = await ExpenseTelemetryStore.create();
    final context = _context();

    await store.enqueue(
      ExpenseTelemetryEvent(
        type: ExpenseTelemetryEventType.addExpenseAbandoned,
        context: context,
        diagnostic: const ExpenseFailureDiagnostic(
          workflowStep: ExpenseWorkflowStep.receiptAttachment,
          failedAt: 'before_receipt_attachment',
          confirmedCause: 'user_left_before_receipt_attachment',
          causeStatus: ExpenseFailureCauseStatus.confirmed,
          evidence: 'no_receipt_proof_or_imported_text',
          missingEvidence: 'none',
          abandoned: true,
        ),
      ),
    );

    final snapshot = store.buildHealthSnapshot(
      nowUtc: DateTime.utc(2026, 6, 24, 13),
    );

    expect(snapshot.addExpenseAbandonedCount, 1);
    expect(snapshot.failureBreakdowns.single.workflowStep, 'receiptAttachment');
    expect(
      snapshot.failureBreakdowns.single.confirmedCause,
      'user_left_before_receipt_attachment',
    );
    expect(snapshot.failureBreakdowns.single.abandonedCount, 1);
  });

  test('rejects private content in diagnostic fields', () {
    expect(
      () => ExpenseTelemetryPolicy.sanitize(
        ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.ocrFailed,
          diagnostic: const ExpenseFailureDiagnostic(
            workflowStep: ExpenseWorkflowStep.receiptOcr,
            failedAt: 'after_attachment',
            confirmedCause: 'LOWES 123 PRIVATE RECEIPT',
            causeStatus: ExpenseFailureCauseStatus.confirmed,
            evidence: 'ocr_result',
          ),
        ),
      ),
      throwsArgumentError,
    );
  });

  test('marks uploaded events and clears only uploaded telemetry', () async {
    final store = await ExpenseTelemetryStore.create();
    final first = await store.enqueue(
      const ExpenseTelemetryEvent(type: ExpenseTelemetryEventType.screenOpened),
      queuedAtUtc: DateTime.utc(2026, 6, 24, 12),
    );
    await store.enqueue(
      const ExpenseTelemetryEvent(type: ExpenseTelemetryEventType.screenClosed),
      queuedAtUtc: DateTime.utc(2026, 6, 24, 12, 5),
    );

    await store.markUploaded([first.id], nowUtc: DateTime.utc(2026, 6, 24, 13));
    expect(store.records, hasLength(2));
    expect(
      store.pendingUploadRecords.map((record) => record.id),
      isNot(contains(first.id)),
    );

    await store.clearUploaded();
    expect(store.records, hasLength(1));
    expect(store.records.single.uploadedAtUtc, isNull);
  });
}

ExpenseTelemetryContext _context() {
  return const ExpenseTelemetryContext(
    appVersion: '0.6.9',
    platform: 'android',
    deviceTier: 'heavy',
    profileType: 'contractor',
    storageMode: ExpenseTelemetryStorageMode.low,
    planStatus: ExpenseTelemetryPlanStatus.free,
    connectionStatus: ExpenseTelemetryConnectionStatus.online,
  );
}
