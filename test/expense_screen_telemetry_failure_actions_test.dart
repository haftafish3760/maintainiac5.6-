import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_screen_telemetry.dart';

import 'helpers/expense_screen_telemetry_harness.dart';

void main() {
  installExpenseTelemetryHiveLifecycle('expense_screen_telemetry_test_');

  test('builds confirmed cause failure breakdowns for Command 1', () async {
    final store = await ExpenseTelemetryStore.create();
    final context = expenseTelemetryContextFixture();

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
    expect(
      snapshot.failureBreakdowns.first.actionSummary,
      contains('Receipt OCR failed from no readable text'),
    );
    expect(snapshot.failureBreakdowns.first.ocrFailureSource, 'unknown');
    expect(
      snapshot.failureBreakdowns.first.ocrFailureSourceAction,
      contains('source tagging'),
    );
    expect(snapshot.failureBreakdowns.first.causeStatus, 'confirmed');
    expect(snapshot.failureBreakdowns.first.retryCount, 2);
    expect(snapshot.failureBreakdowns.first.abandonedCount, 1);
    expect(snapshot.recentFailureDetails, hasLength(2));
    expect(snapshot.recentFailureDetails.first.causeLabel, isNotEmpty);
    final recentOcrFailure = snapshot.recentFailureDetails.firstWhere(
      (failure) => failure.workflowStep == ExpenseWorkflowStep.receiptOcr.name,
    );
    expect(recentOcrFailure.ocrFailureSource, 'unknown');
    expect(recentOcrFailure.ocrFailureSourceAction, contains('source tagging'));
    final saveFailure = snapshot.failureBreakdowns.firstWhere(
      (failure) => failure.workflowStep == ExpenseWorkflowStep.saveExpense.name,
    );
    expect(saveFailure.ocrFailureSource, 'not_ocr');
    expect(saveFailure.ocrFailureSourceAction, contains('non-OCR failure'));
    expect(saveFailure.actionSummary, contains('Save expense failed'));
    expect(saveFailure.actionSummary, contains('cause is not confirmed yet'));
    expect(saveFailure.actionSummary, contains('exception type'));
    final recentSaveFailure = snapshot.recentFailureDetails.firstWhere(
      (failure) => failure.workflowStep == ExpenseWorkflowStep.saveExpense.name,
    );
    expect(recentSaveFailure.ocrFailureSource, 'not_ocr');
    expect(
      recentSaveFailure.ocrFailureSourceAction,
      contains('failure workflow'),
    );
    expect(recentSaveFailure.actionSummary, contains('Save expense failed'));
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
    final context = expenseTelemetryContextFixture();

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

  test('summarizes OCR failure causes separately for Command 1', () async {
    final store = await ExpenseTelemetryStore.create();
    final context = expenseTelemetryContextFixture();

    await store.enqueue(
      ExpenseTelemetryEvent(
        type: ExpenseTelemetryEventType.ocrFailed,
        context: context,
        failureKind: 'receipt_photo_read_failed',
        diagnostic: const ExpenseFailureDiagnostic(
          workflowStep: ExpenseWorkflowStep.receiptOcr,
          failedAt: 'during_photo_ocr_read',
          confirmedCause: 'receipt_photo_read_failed',
          causeStatus: ExpenseFailureCauseStatus.confirmed,
          evidence: 'warning_photoReadFailure_severity_blocked_source_photo',
        ),
      ),
    );
    await store.enqueue(
      ExpenseTelemetryEvent(
        type: ExpenseTelemetryEventType.ocrFailed,
        context: context,
        failureKind: 'receipt_photo_read_failed',
        diagnostic: const ExpenseFailureDiagnostic(
          workflowStep: ExpenseWorkflowStep.receiptOcr,
          failedAt: 'during_photo_ocr_read',
          confirmedCause: 'receipt_photo_read_failed',
          causeStatus: ExpenseFailureCauseStatus.confirmed,
          evidence: 'warning_photoReadFailure_severity_blocked_source_photo',
        ),
      ),
    );
    await store.enqueue(
      ExpenseTelemetryEvent(
        type: ExpenseTelemetryEventType.ocrFailed,
        context: context,
        failureKind: 'pdf_read_failed',
        diagnostic: const ExpenseFailureDiagnostic(
          workflowStep: ExpenseWorkflowStep.receiptOcr,
          failedAt: 'during_pdf_ocr_read',
          confirmedCause: 'pdf_read_failed',
          causeStatus: ExpenseFailureCauseStatus.confirmed,
          evidence: 'warning_pdfReadFailure_severity_blocked_source_pdf',
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
          confirmedCause: 'ledger_save_failed',
          causeStatus: ExpenseFailureCauseStatus.confirmed,
          evidence: 'ledger_save_failed',
        ),
      ),
    );

    final snapshot = store.buildHealthSnapshot(
      nowUtc: DateTime.utc(2026, 6, 24, 13),
    );
    final map = snapshot.toCommandCenterMap();

    expect(snapshot.ocrFailureCauseCounts, {
      'receipt_photo_read_failed': 2,
      'pdf_read_failed': 1,
    });
    expect(snapshot.topOcrFailureCause, 'receipt_photo_read_failed');
    expect(map['ocrFailureCauseCounts'], snapshot.ocrFailureCauseCounts);
    expect(map['topOcrFailureCause'], 'receipt_photo_read_failed');
    expect(snapshot.ocrFailureSourceCounts, {'photo': 2, 'pdf': 1});
    expect(snapshot.topOcrFailureSource, 'photo');
    expect(map['ocrFailureSourceCounts'], snapshot.ocrFailureSourceCounts);
    expect(map['topOcrFailureSource'], 'photo');
    expect(map['topOcrFailureSourceAction'], contains('camera focus'));
    expect(map['topOcrFailureSourceAction'], contains('exposure'));
    expect(snapshot.ocrFailureStageCounts, {
      'during_photo_ocr_read': 2,
      'during_pdf_ocr_read': 1,
    });
    expect(snapshot.topOcrFailureStage, 'during_photo_ocr_read');
    expect(map['ocrFailureStageCounts'], snapshot.ocrFailureStageCounts);
    expect(map['topOcrFailureStage'], 'during_photo_ocr_read');
    expect(map['topOcrFailureStageLabel'], 'During photo OCR read');
    expect(
      snapshot.ocrFailureCauseCounts,
      isNot(containsPair('ledger_save_failed', 1)),
    );
    expect(snapshot.ocrFailureSourceCounts, isNot(containsPair('unknown', 1)));
  });
}
