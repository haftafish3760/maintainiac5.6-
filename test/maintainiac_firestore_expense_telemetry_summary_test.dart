import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_export_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_screen_telemetry.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_documents.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_schema.dart';

import 'helpers/expense_telemetry_schema_expectations.dart';

void main() {
  test('builds expense telemetry summary without raw event upload', () {
    final snapshot = ExpenseTelemetryHealthSnapshot.fromRecords([
      ExpenseTelemetryRecord(
        id: 'evt_1',
        queuedAtUtc: DateTime.utc(2026, 6, 24, 12),
        payload: ExpenseTelemetryPolicy.sanitize(
          const ExpenseTelemetryEvent(
            type: ExpenseTelemetryEventType.addExpenseStarted,
          ),
        ),
      ),
      ExpenseTelemetryRecord(
        id: 'evt_2',
        queuedAtUtc: DateTime.utc(2026, 6, 24, 12, 1),
        payload: ExpenseTelemetryPolicy.sanitize(
          const ExpenseTelemetryEvent(
            type: ExpenseTelemetryEventType.ocrFailed,
            failureKind: 'no_readable_text',
            diagnostic: ExpenseFailureDiagnostic(
              workflowStep: ExpenseWorkflowStep.receiptOcr,
              failedAt: 'after_attachment_read_before_parser',
              confirmedCause: 'no_readable_text',
              causeStatus: ExpenseFailureCauseStatus.confirmed,
              evidence: 'ocr_zero_lines',
              missingEvidence: 'none',
              abandoned: true,
            ),
          ),
        ),
      ),
    ], generatedAtUtc: DateTime.utc(2026, 6, 24, 13));

    final doc =
        MaintainiacFirestoreDocumentBuilder.expenseTelemetrySummaryDocument(
          orgId: 'ORG-1',
          summaryId: 'latest',
          snapshot: snapshot,
        );

    expect(
      doc.path,
      'orgs/ORG-1/${MaintainiacFirestoreSchema.orgExpenseTelemetrySummaries}/latest',
    );
    expect(doc.data['schema'], 'expense_telemetry_summary_v1');
    expect(doc.data['summaryScope'], 'expense_screen');
    expect(doc.data['uploadShape'], 'single_summary_document');
    expect(doc.data['rawEventUploadCount'], 0);
    expect(doc.data['ocrFailedCount'], 1);
    expect(doc.data['failureBreakdowns'], isA<List>());
    expect(
      (doc.data['failureBreakdowns'] as List).single.toString(),
      contains('no_readable_text'),
    );
    expect(
      (doc.data['failureBreakdowns'] as List).single.toString(),
      contains('No readable text'),
    );
    expect(doc.data['recentFailureDetails'], isA<List>());
    expect(
      (doc.data['recentFailureDetails'] as List).single.toString(),
      contains('Confirmed cause'),
    );
    expect(
      (doc.data['failureBreakdowns'] as List).single.toString(),
      contains('platformCounts'),
    );
    expect(
      (doc.data['failureBreakdowns'] as List).single.toString(),
      contains('deviceTierCounts'),
    );

    final encoded = doc.data.toString().toLowerCase();
    expect(encoded, isNot(contains('receipttext')));
    expect(encoded, isNot(contains('customer')));
    expect(encoded, isNot(contains('store name')));
  });

  test('embeds privacy-safe OCR contract in expense telemetry summary', () {
    final snapshot = ExpenseTelemetryHealthSnapshot.fromRecords([
      ExpenseTelemetryRecord(
        id: 'evt_ocr',
        queuedAtUtc: DateTime.utc(2026, 6, 24, 12),
        payload: ExpenseTelemetryPolicy.sanitize(
          const ExpenseTelemetryEvent(
            type: ExpenseTelemetryEventType.ocrCompleted,
          ),
        ),
      ),
    ], generatedAtUtc: DateTime.utc(2026, 6, 24, 13));
    final ocrContract = ExpenseExportSnapshot(
      exportedAt: DateTime.utc(2026, 6, 24, 13),
      range: ExpenseDateRange(
        start: DateTime(2026, 6, 1),
        end: DateTime(2026, 6, 30),
      ),
      categoryFilter: ExpenseExportCategoryFilter.all,
      receipts: [
        ExpenseReceiptRecord(
          id: 'EXP-ocr-contract',
          receiptDate: DateTime(2026, 6, 24),
          ocrReview: const ExpenseReceiptOcrReview(
            severity: 'review',
            source: 'photo',
            primaryWarningKind: 'sectionGap',
            primaryWarningTargetLabel: 'Check missing receipt section',
            primaryWarningTargetInstruction:
                'Check receipt photos from top to bottom and add the missing middle section if needed.',
            recoveryAction: 'add_missing_section',
            recoveryTarget: 'receipt_sections',
            warningCount: 1,
            reviewWarningCount: 1,
          ),
          lines: const [
            ExpenseReceiptLineRecord(
              id: 'LINE-ocr-contract',
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

    final doc =
        MaintainiacFirestoreDocumentBuilder.expenseTelemetrySummaryDocument(
          orgId: 'ORG-1',
          summaryId: 'latest',
          snapshot: snapshot,
          commandCenterOcrContract: ocrContract,
        );

    final embedded =
        doc.data['commandCenterOcrContract'] as Map<String, Object?>;
    expect(
      embedded['schema'],
      ExpenseExportSnapshot.commandCenterOcrContractSchema,
    );
    expect(
      embedded['privacyScope'],
      ExpenseExportSnapshot.commandCenterOcrPrivacyScope,
    );
    expect(embedded['uploadShape'], isNull);
    expect(embedded['receiptsNeedingOcrReview'], 1);
    expect(embedded['ocrRecoveryActionCounts'], {'add_missing_section': 1});
    expect(embedded['ocrRecoveryTargetCounts'], {'receipt_sections': 1});
    expect(doc.data['uploadShape'], 'single_summary_document');
    expect(
      MaintainiacFirestoreDocumentBuilder.expenseTelemetrySummaryOcrContractFindingsFor(
        doc,
      ),
      isEmpty,
    );

    final encoded = doc.data.toString().toLowerCase();
    expect(encoded, isNot(contains('private_store')));
    expect(encoded, isNot(contains('shop towels')));
    expect(encoded, isNot(contains('/tmp/receipt')));
  });

  test('keeps scheduler trace metrics in expense telemetry summary', () {
    final snapshot = ExpenseTelemetryHealthSnapshot.fromRecords([
      ExpenseTelemetryRecord(
        id: 'evt_summary_trace_included',
        queuedAtUtc: DateTime.utc(2026, 6, 24, 12),
        payload: ExpenseTelemetryPolicy.sanitize(
          const ExpenseTelemetryEvent(
            type: ExpenseTelemetryEventType.syncPending,
            metadata: {
              'syncState': 'expense_summary_queued',
              'summaryStatus': 'queued',
              'ocrContractQueued': true,
              'ocrContractSource': 'rolling_local_ledger',
            },
          ),
        ),
      ),
      ExpenseTelemetryRecord(
        id: 'evt_summary_trace_skipped',
        queuedAtUtc: DateTime.utc(2026, 6, 24, 12, 1),
        payload: ExpenseTelemetryPolicy.sanitize(
          const ExpenseTelemetryEvent(
            type: ExpenseTelemetryEventType.syncPending,
            metadata: {
              'syncState': 'expense_summary_queued',
              'summaryStatus': 'queued',
              'ocrContractQueued': false,
              'ocrContractSource': 'none',
              'ocrContractSkippedReason': 'ledger_ocr_contract_disabled',
            },
          ),
        ),
      ),
    ], generatedAtUtc: DateTime.utc(2026, 6, 24, 13));

    final doc =
        MaintainiacFirestoreDocumentBuilder.expenseTelemetrySummaryDocument(
          orgId: 'ORG-1',
          summaryId: 'latest',
          snapshot: snapshot,
        );

    expect(doc.data['expenseSummaryQueuedCount'], 2);
    expect(doc.data['expenseSummaryOcrContractQueuedCount'], 1);
    expect(doc.data['expenseSummaryOcrContractSkippedCount'], 1);
    expect(doc.data['expenseSummaryOcrContractSourceCounts'], {
      'rolling_local_ledger': 1,
      'none': 1,
    });
    expect(doc.data['topExpenseSummaryOcrContractSource'], 'none');
    expect(doc.data['expenseSummaryOcrContractSkippedReasonCounts'], {
      'ledger_ocr_contract_disabled': 1,
    });
    expect(
      doc.data['topExpenseSummaryOcrContractSkippedReason'],
      'ledger_ocr_contract_disabled',
    );
    expect(doc.data.toString(), isNot(contains('ORG-1')));
    expect(doc.data.toString().toLowerCase(), isNot(contains('receipt text')));
  });

  test('keeps parser and OCR failure metrics in expense telemetry summary', () {
    final snapshot = ExpenseTelemetryHealthSnapshot.fromRecords([
      ExpenseTelemetryRecord(
        id: 'evt_parser_started',
        queuedAtUtc: DateTime.utc(2026, 6, 24, 12),
        payload: ExpenseTelemetryPolicy.sanitize(
          const ExpenseTelemetryEvent(
            type: ExpenseTelemetryEventType.parserStarted,
          ),
        ),
      ),
      ExpenseTelemetryRecord(
        id: 'evt_parser_review',
        queuedAtUtc: DateTime.utc(2026, 6, 24, 12, 1),
        payload: ExpenseTelemetryPolicy.sanitize(
          const ExpenseTelemetryEvent(
            type: ExpenseTelemetryEventType.parserNeedsReview,
          ),
        ),
      ),
      ExpenseTelemetryRecord(
        id: 'evt_line_confirmed',
        queuedAtUtc: DateTime.utc(2026, 6, 24, 12, 2),
        payload: ExpenseTelemetryPolicy.sanitize(
          const ExpenseTelemetryEvent(
            type: ExpenseTelemetryEventType.appFilledReceiptLineConfirmed,
            categoryGroup: 'Fuel',
          ),
        ),
      ),
      ExpenseTelemetryRecord(
        id: 'evt_line_corrected',
        queuedAtUtc: DateTime.utc(2026, 6, 24, 12, 3),
        payload: ExpenseTelemetryPolicy.sanitize(
          const ExpenseTelemetryEvent(
            type: ExpenseTelemetryEventType.appFilledReceiptLineCorrected,
            categoryGroup: 'Materials',
          ),
        ),
      ),
      ExpenseTelemetryRecord(
        id: 'evt_ocr_failed',
        queuedAtUtc: DateTime.utc(2026, 6, 24, 12, 4),
        payload: ExpenseTelemetryPolicy.sanitize(
          const ExpenseTelemetryEvent(
            type: ExpenseTelemetryEventType.ocrFailed,
            failureKind: 'no_readable_text',
            diagnostic: ExpenseFailureDiagnostic(
              workflowStep: ExpenseWorkflowStep.receiptOcr,
              failedAt: 'after_attachment_read_before_parser',
              confirmedCause: 'no_readable_text',
              causeStatus: ExpenseFailureCauseStatus.confirmed,
              evidence: 'ocr_severity_blocked_source_photo',
              missingEvidence: 'none',
            ),
          ),
        ),
      ),
    ], generatedAtUtc: DateTime.utc(2026, 6, 24, 13));

    final doc =
        MaintainiacFirestoreDocumentBuilder.expenseTelemetrySummaryDocument(
          orgId: 'ORG-1',
          summaryId: 'latest',
          snapshot: snapshot,
        );

    expect(doc.data['parserStartedCount'], 1);
    expect(doc.data['parserNeedsReviewCount'], 1);
    expect(doc.data['parserReviewRate'], 1);
    expect(doc.data['appFilledReceiptLineConfirmedCount'], 1);
    expect(doc.data['appFilledReceiptLineCorrectedCount'], 1);
    expect(doc.data['appFilledReceiptLineCorrectionRate'], .5);
    expect(doc.data['ocrFailureCauseCounts'], {'no_readable_text': 1});
    expect(doc.data['topOcrFailureCause'], 'no_readable_text');
    expect(doc.data['ocrFailureSourceCounts'], {'photo': 1});
    expect(doc.data['topOcrFailureSource'], 'photo');
    expect(
      doc.data['topOcrFailureSourceAction'],
      'investigate_receipt_camera_focus_exposure_crop_coverage_long_rec',
    );
    expect(doc.data['ocrFailureStageCounts'], {
      'after_attachment_read_before_parser': 1,
    });
    expect(
      doc.data['topOcrFailureStage'],
      'after_attachment_read_before_parser',
    );
    expect(
      doc.data['topOcrFailureStageLabel'],
      'After attachment read before parser',
    );
    expect(doc.data.toString().toLowerCase(), isNot(contains('receipt text')));
  });

  test(
    'expense telemetry schema helper stays scoped to Command Center map',
    () {
      expect(
        expectedExpenseTelemetryCommandCenterKeys.length,
        expectedExpenseTelemetryCommandCenterKeys.toSet().length,
      );
      for (final firestoreOnlyKey in const {
        'summaryId',
        'summaryScope',
        'uploadShape',
        'rawEventUploadCount',
        'commandCenterOcrContract',
      }) {
        expect(
          expectedExpenseTelemetryCommandCenterKeys,
          isNot(contains(firestoreOnlyKey)),
          reason: '$firestoreOnlyKey is Firestore document metadata.',
        );
      }
      expect(
        expectedExpenseTelemetryCommandCenterKeys,
        containsAll({
          'schema',
          'healthLabel',
          'ocrSuccessRate',
          'parserFailureRate',
          'topOcrFailureSourceAction',
          'failureBreakdowns',
          'recentFailureDetails',
        }),
      );
    },
  );

  test('Firestore summary metadata stays outside local telemetry schema', () {
    final snapshot = ExpenseTelemetryHealthSnapshot.fromRecords(
      const [],
      generatedAtUtc: DateTime.utc(2026, 6, 24, 13),
    );
    final commandCenterMap = snapshot.toCommandCenterMap();
    final ocrContract = ExpenseExportSnapshot(
      exportedAt: DateTime.utc(2026, 6, 24, 13),
      range: ExpenseDateRange(
        start: DateTime(2026, 6, 1),
        end: DateTime(2026, 6, 30),
      ),
      categoryFilter: ExpenseExportCategoryFilter.all,
      receipts: const [],
    ).commandCenterOcrContract;
    final doc =
        MaintainiacFirestoreDocumentBuilder.expenseTelemetrySummaryDocument(
          orgId: 'ORG-1',
          summaryId: 'latest/private value',
          snapshot: snapshot,
          commandCenterOcrContract: ocrContract,
        );

    for (final firestoreOnlyKey in const {
      'summaryId',
      'summaryScope',
      'uploadShape',
      'rawEventUploadCount',
      'commandCenterOcrContract',
    }) {
      expect(commandCenterMap, isNot(contains(firestoreOnlyKey)));
      expect(doc.data, contains(firestoreOnlyKey));
    }
    expect(doc.data['summaryId'], 'latest_private_value');
    expect(doc.data['summaryScope'], 'expense_screen');
    expect(doc.data['uploadShape'], 'single_summary_document');
    expect(doc.data['rawEventUploadCount'], 0);
    expect(doc.data['commandCenterOcrContract'], isA<Map<String, Object?>>());
    expect(doc.data.toString(), isNot(contains('latest/private value')));
  });
}
