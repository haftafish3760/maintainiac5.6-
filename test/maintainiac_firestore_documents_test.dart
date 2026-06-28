import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_export_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_item_memory_store.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_privacy_event_store.dart';
import 'package:maintaniac/screens/expenses/data/expense_screen_telemetry.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog_health_event.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog_hosted_import_validator.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog_hosted_manifest.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_documents.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_schema.dart';

import 'helpers/expense_telemetry_schema_expectations.dart';

void main() {
  test(
    'builds hosted catalog pack and manifest documents without item docs',
    () {
      final manifest = buildWorkSupplyHostedCatalogManifest(
        generatedAt: DateTime.utc(2026, 6, 23, 12),
      );

      final pack = MaintainiacFirestoreDocumentBuilder.catalogPackDocument(
        manifest,
      );
      final manifestDoc =
          MaintainiacFirestoreDocumentBuilder.catalogManifestDocument(manifest);

      expect(
        pack.path,
        MaintainiacFirestoreSchema.catalogPackDocumentPath(manifest.packId),
      );
      expect(
        manifestDoc.path,
        MaintainiacFirestoreSchema.catalogPackManifestDocumentPath(
          manifest.packId,
          manifest.packVersion,
        ),
      );
      expect(pack.data['firestoreItemDocumentReadCount'], 0);
      expect(pack.data['deliveryMode'], 'manifest_storage_chunks');
      expect(manifestDoc.data['deliveryMode'], 'manifest_storage_chunks');
      expect(manifestDoc.data['chunks'], isA<List>());

      final encodedPack = pack.data.toString().toLowerCase();
      expect(encodedPack, isNot(contains('copper')));
      expect(encodedPack, isNot(contains('pvc')));
      expect(encodedPack, isNot(contains('aliases')));
    },
  );

  test('builds privacy-safe catalog health document', () {
    final manifest = buildWorkSupplyHostedCatalogManifest(
      generatedAt: DateTime.utc(2026, 6, 23, 12),
    );
    final validation = WorkSupplyHostedCatalogValidationResult(
      status: WorkSupplyHostedCatalogValidationStatus.ready,
      manifest: manifest,
      issues: const [],
      checkedChunkCount: manifest.chunkCount,
      checkedItemCount: manifest.itemCount,
    );
    final event = WorkSupplyCatalogHealthEvent.fromValidation(validation);
    final doc = MaintainiacFirestoreDocumentBuilder.catalogHealthDocument(
      event,
      generatedAtUtc: DateTime.utc(2026, 6, 23, 13),
    );

    expect(
      doc.path,
      startsWith('${MaintainiacFirestoreSchema.catalogHealth}/'),
    );
    expect(doc.data['schema'], 'catalog_health_event_v1');
    expect(doc.data['event'], 'catalogpackready');
    expect(doc.data['featureArea'], 'inventory_catalog');
    expect(doc.data['firestoreItemDocumentReadCount'], 0);

    final encoded = doc.data.toString().toLowerCase();
    expect(encoded, isNot(contains('items:')));
    expect(encoded, isNot(contains('aliases')));
    expect(encoded, isNot(contains('copper')));
  });

  test('builds receipt diagnostic and parser health documents safely', () {
    final parsed = parseExpenseReceiptText('''
PRIVATE SUPPLY STORE
06/12/2026
SECRET JOB MATERIAL 12.34
Subtotal 12.34
Tax 1.00
Total 13.34
''');
    final record = PrivacySafeReceiptEventRecord(
      id: 'evt_123',
      queuedAtUtc: DateTime.utc(2026, 6, 23, 14),
      payload: ReceiptPrivacyEventPolicy.sanitize(
        PrivacySafeReceiptEvent.fromParseResult(
          result: parsed,
          featureArea: 'materials inventory',
        ),
      ),
    );
    final diagnostic =
        MaintainiacFirestoreDocumentBuilder.receiptDiagnosticDocument(
          orgId: 'ORG-1',
          record: record,
        );
    final health = ReceiptPrivacyEventHealthSnapshot.fromRecords([record]);
    final parserHealth =
        MaintainiacFirestoreDocumentBuilder.parserHealthDocument(health);

    expect(
      diagnostic.path,
      'orgs/ORG-1/${MaintainiacFirestoreSchema.orgReceiptDiagnostics}/evt_123',
    );
    expect(diagnostic.data['schema'], 'receipt_diagnostic_event_v1');
    expect(parserHealth.path, 'parserHealth/receipt_parser_v1');
    expect(parserHealth.data['schema'], 'parser_health_snapshot_v1');
    expect(parserHealth.data['healthLabel'], isNot('no_data'));

    final encoded = {
      ...diagnostic.data,
      ...parserHealth.data,
    }.toString().toLowerCase();
    expect(encoded, isNot(contains('private supply')));
    expect(encoded, isNot(contains('secret job')));
    expect(encoded, isNot(contains('12.34')));
    expect(encoded, isNot(contains('13.34')));
  });

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

  test('keeps every Command Center telemetry field in Firestore summary', () {
    const context = ExpenseTelemetryContext(
      appVersion: '5.6.0',
      platform: 'android',
      deviceTier: 'high',
      profileType: 'single_vehicle',
      storageMode: ExpenseTelemetryStorageMode.normal,
      planStatus: ExpenseTelemetryPlanStatus.paid,
      connectionStatus: ExpenseTelemetryConnectionStatus.online,
    );
    var minuteOffset = 0;
    ExpenseTelemetryRecord record(
      String id,
      ExpenseTelemetryEvent event, {
      DateTime? uploadedAtUtc,
    }) {
      final queuedAtUtc = DateTime.utc(2026, 6, 24, 12, minuteOffset++);
      return ExpenseTelemetryRecord(
        id: id,
        queuedAtUtc: queuedAtUtc,
        uploadedAtUtc: uploadedAtUtc,
        payload: ExpenseTelemetryPolicy.sanitize(event),
      );
    }

    final snapshot = ExpenseTelemetryHealthSnapshot.fromRecords([
      record(
        'evt_screen_opened',
        const ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.screenOpened,
          context: context,
        ),
      ),
      record(
        'evt_time_spent',
        const ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.timeSpentOnScreen,
          context: context,
          durationMs: 42100,
        ),
        uploadedAtUtc: DateTime.utc(2026, 6, 24, 12, 59),
      ),
      record(
        'evt_add_started',
        const ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.addExpenseStarted,
          context: context,
        ),
      ),
      record(
        'evt_add_completed',
        const ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.addExpenseCompleted,
          context: context,
        ),
      ),
      record(
        'evt_add_abandoned',
        const ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.addExpenseAbandoned,
          context: context,
        ),
      ),
      record(
        'evt_validation',
        const ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.validationError,
          context: context,
          validationErrorKind: 'missing_total',
        ),
      ),
      record(
        'evt_save_failure',
        const ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.saveFailure,
          context: context,
          failureKind: 'local_write_failed',
          diagnostic: ExpenseFailureDiagnostic(
            workflowStep: ExpenseWorkflowStep.saveExpense,
            failedAt: 'before_local_commit',
            confirmedCause: 'local_write_failed',
            causeStatus: ExpenseFailureCauseStatus.confirmed,
            evidence: 'safe_exception_token',
            missingEvidence: 'none',
          ),
        ),
      ),
      record(
        'evt_image_success',
        const ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.imageAttachSuccess,
          context: context,
        ),
      ),
      record(
        'evt_image_failure',
        const ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.imageAttachFailure,
          context: context,
          failureKind: 'permission_denied',
        ),
      ),
      record(
        'evt_ocr_started',
        const ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.ocrStarted,
          context: context,
        ),
      ),
      record(
        'evt_ocr_completed',
        const ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.ocrCompleted,
          context: context,
        ),
      ),
      record(
        'evt_ocr_failed',
        const ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.ocrFailed,
          context: context,
          failureKind: 'no_readable_text',
          diagnostic: ExpenseFailureDiagnostic(
            workflowStep: ExpenseWorkflowStep.receiptOcr,
            failedAt: 'after_attachment_read_before_parser',
            confirmedCause: 'no_readable_text',
            causeStatus: ExpenseFailureCauseStatus.confirmed,
            evidence: 'ocr_severity_blocked_source_photo',
            missingEvidence: 'none',
            retryCount: 2,
            abandoned: true,
          ),
        ),
      ),
      record(
        'evt_parser_started',
        const ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.parserStarted,
          context: context,
        ),
      ),
      record(
        'evt_parser_completed',
        const ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.parserCompleted,
          context: context,
        ),
      ),
      record(
        'evt_parser_review',
        const ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.parserNeedsReview,
          context: context,
        ),
      ),
      record(
        'evt_parser_failed',
        const ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.parserFailed,
          context: context,
          failureKind: 'total_mismatch',
          diagnostic: ExpenseFailureDiagnostic(
            workflowStep: ExpenseWorkflowStep.receiptParser,
            failedAt: 'after_ocr_before_line_review',
            confirmedCause: 'total_mismatch',
            causeStatus: ExpenseFailureCauseStatus.confirmed,
            evidence: 'parser_total_check_failed',
            missingEvidence: 'none',
          ),
        ),
      ),
      record(
        'evt_correction_opened',
        const ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.ocrCorrectionOpened,
          context: context,
        ),
      ),
      record(
        'evt_line_confirmed',
        const ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.appFilledReceiptLineConfirmed,
          context: context,
          categoryGroup: 'fuel',
        ),
      ),
      record(
        'evt_line_corrected',
        const ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.appFilledReceiptLineCorrected,
          context: context,
          categoryGroup: 'materials',
        ),
      ),
      record(
        'evt_user_corrected_total',
        const ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.userCorrectedTotal,
          context: context,
        ),
      ),
      record(
        'evt_cloud_success',
        const ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.cloudBackupSuccess,
          context: context,
        ),
      ),
      record(
        'evt_cloud_failure',
        const ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.cloudBackupFailure,
          context: context,
          failureKind: 'network_timeout',
        ),
      ),
      record(
        'evt_summary_trace_included',
        const ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.syncPending,
          context: context,
          metadata: {
            'syncState': 'expense_summary_queued',
            'summaryStatus': 'queued',
            'ocrContractQueued': true,
            'ocrContractSource': 'rolling_local_ledger',
          },
        ),
      ),
      record(
        'evt_summary_trace_skipped',
        const ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.syncPending,
          context: context,
          metadata: {
            'syncState': 'expense_summary_queued',
            'summaryStatus': 'queued',
            'ocrContractQueued': false,
            'ocrContractSource': 'none',
            'ocrContractSkippedReason': 'ledger_ocr_contract_disabled',
          },
        ),
      ),
      record(
        'evt_synced',
        const ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.synced,
          context: context,
        ),
      ),
      record(
        'evt_sync_failed',
        const ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.syncFailed,
          context: context,
          failureKind: 'retry_limit_reached',
        ),
      ),
      record(
        'evt_export_started',
        const ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.exportStarted,
          context: context,
        ),
      ),
      record(
        'evt_export_completed',
        const ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.exportCompleted,
          context: context,
        ),
      ),
      record(
        'evt_export_blocked',
        const ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.exportBlocked,
          context: context,
        ),
      ),
      record(
        'evt_export_failed',
        const ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.exportFailed,
          context: context,
          failureKind: 'quota_exceeded',
        ),
      ),
    ], generatedAtUtc: DateTime.utc(2026, 6, 24, 13));

    final commandCenterMap = snapshot.toCommandCenterMap();
    final doc =
        MaintainiacFirestoreDocumentBuilder.expenseTelemetrySummaryDocument(
          orgId: 'ORG-1',
          summaryId: 'latest',
          snapshot: snapshot,
        );
    final missingKeys = [
      for (final key in commandCenterMap.keys)
        if (!doc.data.containsKey(key)) key,
    ];
    const criticalConditionalKeys = {
      'topExpenseSummaryOcrContractSource',
      'topExpenseSummaryOcrContractSkippedReason',
      'topOcrFailureCause',
      'topOcrFailureSource',
      'topOcrFailureSourceAction',
      'topOcrFailureStage',
      'topOcrFailureStageLabel',
    };

    expect(
      missingKeys,
      isEmpty,
      reason:
          'Firestore summary sanitizer must keep every top-level Command Center telemetry key.',
    );
    expect(
      commandCenterMap.keys.toSet(),
      expectedExpenseTelemetryCommandCenterKeys,
      reason:
          'Command Center expense telemetry schema changed. Update the Firestore sanitizer, docs, and Command 1 contract together.',
    );
    for (final key in criticalConditionalKeys) {
      expect(
        commandCenterMap,
        contains(key),
        reason: 'The rich parity fixture must exercise conditional key $key.',
      );
      expect(
        doc.data,
        contains(key),
        reason: 'Firestore summary must keep conditional telemetry key $key.',
      );
    }
    expect(doc.data['topExpenseSummaryOcrContractSource'], 'none');
    expect(
      doc.data['topExpenseSummaryOcrContractSkippedReason'],
      'ledger_ocr_contract_disabled',
    );
    expect(doc.data['topOcrFailureCause'], 'no_readable_text');
    expect(doc.data['topOcrFailureSource'], 'photo');
    expect(
      doc.data['topOcrFailureSourceAction'],
      'investigate_receipt_camera_focus_exposure_crop_coverage_long_rec',
    );
    expect(
      doc.data['topOcrFailureStage'],
      'after_attachment_read_before_parser',
    );
    expect(
      doc.data['topOcrFailureStageLabel'],
      'After attachment read before parser',
    );
    expect(doc.data['schema'], 'expense_telemetry_summary_v1');
    expect(doc.data['rawEventUploadCount'], 0);
    expect(doc.data.toString().toLowerCase(), isNot(contains('receipt text')));
    expect(doc.data.toString(), isNot(contains('ORG-1')));
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

  test('caps expense telemetry failure drill-downs for Firestore', () {
    final snapshot = _expenseTelemetryFailureSnapshot(60);

    final defaultDoc =
        MaintainiacFirestoreDocumentBuilder.expenseTelemetrySummaryDocument(
          orgId: 'ORG-1',
          summaryId: 'latest',
          snapshot: snapshot,
        );
    final expandedDoc =
        MaintainiacFirestoreDocumentBuilder.expenseTelemetrySummaryDocument(
          orgId: 'ORG-1',
          summaryId: 'expanded',
          snapshot: snapshot,
          maxFailureBreakdowns: 999,
          maxRecentFailureDetails: 999,
        );
    final leanDoc =
        MaintainiacFirestoreDocumentBuilder.expenseTelemetrySummaryDocument(
          orgId: 'ORG-1',
          summaryId: 'lean',
          snapshot: snapshot,
          maxFailureBreakdowns: 0,
          maxRecentFailureDetails: 0,
        );

    expect(defaultDoc.data['failureBreakdowns'], isA<List>());
    expect(defaultDoc.data['recentFailureDetails'], isA<List>());
    expect((defaultDoc.data['failureBreakdowns'] as List), hasLength(20));
    expect((defaultDoc.data['recentFailureDetails'] as List), hasLength(50));
    expect((expandedDoc.data['failureBreakdowns'] as List), hasLength(50));
    expect((expandedDoc.data['recentFailureDetails'] as List), hasLength(60));
    expect((leanDoc.data['failureBreakdowns'] as List), isEmpty);
    expect((leanDoc.data['recentFailureDetails'] as List), isEmpty);
    expect(defaultDoc.data.toString().toLowerCase(), isNot(contains('secret')));
  });

  test('keeps failure drill-down object schemas stable for Firestore', () {
    final snapshot = _expenseTelemetryFailureSnapshot(3);
    final doc =
        MaintainiacFirestoreDocumentBuilder.expenseTelemetrySummaryDocument(
          orgId: 'ORG-1',
          summaryId: 'latest',
          snapshot: snapshot,
        );

    final failureBreakdown =
        (doc.data['failureBreakdowns'] as List).first as Map<String, Object?>;
    final recentFailure =
        (doc.data['recentFailureDetails'] as List).first
            as Map<String, Object?>;
    const privateKeys = {
      'payload',
      'metadata',
      'receiptText',
      'rawOcrText',
      'merchantName',
      'itemDescription',
      'proofPath',
      'orgId',
      'userId',
    };

    expect(
      failureBreakdown.keys.toSet(),
      expectedExpenseTelemetryFailureBreakdownKeys,
    );
    expect(
      recentFailure.keys.toSet(),
      expectedExpenseTelemetryRecentFailureDetailKeys,
    );
    for (final privateKey in privateKeys) {
      expect(failureBreakdown, isNot(contains(privateKey)));
      expect(recentFailure, isNot(contains(privateKey)));
    }
    expect(failureBreakdown['missingEvidence'], 'none');
    expect(recentFailure['missingEvidence'], 'none');
  });

  test('scrubs private receipt hints from failure drill-down text', () {
    final snapshot = ExpenseTelemetryHealthSnapshot.fromRecords([
      ExpenseTelemetryRecord(
        id: 'evt-private-receipt-failure',
        queuedAtUtc: DateTime.utc(2026, 6, 24, 12),
        payload: ExpenseTelemetryPolicy.sanitizeMap({
          'event': 'ocrFailed',
          'workflowStep': 'receiptOcr',
          'failedAt': 'after_lowes_total_3.24_receipt_18854480',
          'confirmedCause': 'lowes_total_3.24_ocr_failed',
          'causeStatus': 'confirmed',
          'evidence': 'source_photo_lowes_receipt_18854480_total_3.24',
          'missingEvidence': 'auth_5715',
          'retryCount': 2,
          'abandoned': true,
          'platform': 'android',
          'deviceTier': 'high',
          'appVersion': '5.6.0',
        }),
      ),
    ], generatedAtUtc: DateTime.utc(2026, 6, 24, 13));

    final doc =
        MaintainiacFirestoreDocumentBuilder.expenseTelemetrySummaryDocument(
          orgId: 'ORG-1',
          summaryId: 'latest',
          snapshot: snapshot,
        );
    final failureBreakdown =
        (doc.data['failureBreakdowns'] as List).single as Map<String, Object?>;
    final recentFailure =
        (doc.data['recentFailureDetails'] as List).single
            as Map<String, Object?>;
    final serialized = doc.data.toString().toLowerCase();

    expect(serialized, isNot(contains('lowes')));
    expect(serialized, isNot(contains('lowe')));
    expect(serialized, isNot(contains('3.24')));
    expect(serialized, isNot(contains('18854480')));
    expect(serialized, isNot(contains('5715')));
    expect(failureBreakdown['confirmedCause'], contains('merchant'));
    expect(failureBreakdown['confirmedCause'], contains('amount'));
    expect(failureBreakdown['failedAt'], contains('number'));
    expect(failureBreakdown['evidence'], contains('merchant'));
    expect(failureBreakdown['missingEvidence'], 'auth_number');
    expect(recentFailure['causeLabel'], contains('merchant'));
    expect(recentFailure['causeLabel'], contains('amount'));
    expect(recentFailure['failedAtLabel'], contains('number'));
    expect(recentFailure['missingEvidenceLabel'], contains('number'));
  });

  test('stress scrubs fuel auto barcode and currency failure hints', () {
    final records = <ExpenseTelemetryRecord>[];
    final cases = [
      (
        event: 'ocrFailed',
        failedAt: 'shell_total_45_67_ticket_982334455',
        cause: 'shell_auth_998877_ocr_failed',
        evidence: 'source_photo_shell_barcode_036000291452_total_45_67',
        missing: 'terminal_123456',
      ),
      (
        event: 'parserFailed',
        failedAt: 'jiffy_lube_invoice_123456789_total_89.99',
        cause: 'jiffy_lube_oil_change_receipt_123456789',
        evidence: 'source_photo_jiffy_lube_card_5715_amount_89_99',
        missing: 'transaction_777888999',
      ),
      (
        event: 'imageAttachFailure',
        failedAt: 'walmart_receipt_545454_total_12_34',
        cause: 'walmart_barcode_123456789012_decode_failed',
        evidence: 'source_photo_walmart_upc_123456789012_total_12.34',
        missing: 'authcode_112233',
      ),
      (
        event: 'saveFailure',
        failedAt: 'home_depot_order_555666777_total_109_23',
        cause: 'home_depot_receipt_total_109_23_save_failed',
        evidence: 'source_photo_home_depot_receipt_555666777_total_109_23',
        missing: 'invoice_444555666',
      ),
    ];

    for (var index = 0; index < cases.length; index += 1) {
      final testCase = cases[index];
      records.add(
        ExpenseTelemetryRecord(
          id: 'evt-redaction-stress-$index',
          queuedAtUtc: DateTime.utc(2026, 6, 24, 12, index),
          payload: Map.unmodifiable({
            'event': testCase.event,
            'workflowStep': index.isEven ? 'receiptOcr' : 'receiptParser',
            'failedAt': testCase.failedAt,
            'confirmedCause': testCase.cause,
            'causeStatus': 'confirmed',
            'evidence': testCase.evidence,
            'missingEvidence': testCase.missing,
            'retryCount': index + 1,
            'platform': 'android',
            'deviceTier': index.isEven ? 'high' : 'low',
            'appVersion': '5.6.$index',
          }),
        ),
      );
    }

    final snapshot = ExpenseTelemetryHealthSnapshot.fromRecords(
      records,
      generatedAtUtc: DateTime.utc(2026, 6, 24, 13),
    );
    final doc =
        MaintainiacFirestoreDocumentBuilder.expenseTelemetrySummaryDocument(
          orgId: 'ORG-1',
          summaryId: 'latest',
          snapshot: snapshot,
          maxFailureBreakdowns: 20,
          maxRecentFailureDetails: 20,
        );
    final serialized = doc.data.toString().toLowerCase();

    for (final rawPrivateHint in const [
      'shell',
      'jiffy',
      'lube',
      'walmart',
      'home',
      'depot',
      '45.67',
      '45_67',
      '89.99',
      '89_99',
      '12.34',
      '12_34',
      '109.23',
      '109_23',
      '982334455',
      '998877',
      '036000291452',
      '123456789',
      '5715',
      '777888999',
      '545454',
      '123456789012',
      '112233',
      '555666777',
      '444555666',
    ]) {
      expect(serialized, isNot(contains(rawPrivateHint)));
    }
    expect(serialized, contains('merchant'));
    expect(serialized, contains('amount'));
    expect(serialized, contains('number'));
    expect((doc.data['failureBreakdowns'] as List), hasLength(cases.length));
    expect((doc.data['recentFailureDetails'] as List), hasLength(cases.length));
  });

  test('keeps redaction scoped to failure detail fields', () {
    final snapshot = ExpenseTelemetryHealthSnapshot.fromRecords([
      ExpenseTelemetryRecord(
        id: 'evt-redaction-boundary',
        queuedAtUtc: DateTime.utc(2026, 6, 24, 12),
        payload: ExpenseTelemetryPolicy.sanitizeMap({
          'event': 'ocrFailed',
          'workflowStep': 'receiptOcr',
          'failedAt': 'shell_total_45_67_ticket_982334455',
          'confirmedCause': 'shell_total_45_67_ocr_failed',
          'causeStatus': 'confirmed',
          'evidence': 'source_photo_shell_receipt_982334455_total_45_67',
          'missingEvidence': 'terminal_123456',
          'platform': 'android',
          'deviceTier': 'high',
          'appVersion': '5.6.0',
        }),
      ),
    ], generatedAtUtc: DateTime.utc(2026, 6, 24, 13));

    final doc =
        MaintainiacFirestoreDocumentBuilder.expenseTelemetrySummaryDocument(
          orgId: 'ORG-1',
          summaryId: 'latest',
          snapshot: snapshot,
        );
    final failureBreakdown =
        (doc.data['failureBreakdowns'] as List).single as Map<String, Object?>;

    expect(doc.data['platformCounts'], {'android': 1});
    expect(doc.data['deviceTierCounts'], {'high': 1});
    expect(doc.data['topOcrFailureSource'], 'photo');
    expect(failureBreakdown['appVersionCounts'], {'5_6_0': 1});
    expect(failureBreakdown['platformCounts'], {'android': 1});
    expect(
      failureBreakdown['confirmedCause'],
      'merchant_total_amount_ocr_failed',
    );
    expect(failureBreakdown['failedAt'], 'merchant_total_amount_ticket_number');
    expect(
      failureBreakdown['evidence'],
      'source_photo_merchant_receipt_number_total_amount',
    );
    expect(failureBreakdown['missingEvidence'], 'terminal_number');
  });

  test('keeps Firestore redaction helper fields aligned with contract', () {
    final source = File(
      'lib/shared/firebase/maintainiac_firestore_documents.dart',
    ).readAsStringSync();

    expect(source, contains('class _ExpenseTelemetryFirestoreRedactor'));
    expect(source, contains('privateReceiptHintTokenFields'));
    expect(source, contains('privateReceiptHintMapFields'));
    for (final field in expectedExpenseTelemetryRedactedTokenFields) {
      expect(
        source,
        contains("'$field'"),
        reason: 'Redacted token field `$field` must stay in the helper.',
      );
    }
    for (final field in expectedExpenseTelemetryRedactedMapFields) {
      expect(
        source,
        contains("'$field'"),
        reason: 'Redacted map field `$field` must stay in the helper.',
      );
    }
    for (final unredactedOperationalField in const {
      'platform',
      'deviceTier',
      'appVersion',
      'topOcrFailureSource',
      'appVersionCounts',
    }) {
      expect(
        expectedExpenseTelemetryRedactedTokenFields,
        isNot(contains(unredactedOperationalField)),
        reason: '`$unredactedOperationalField` should not be over-redacted.',
      );
      expect(
        expectedExpenseTelemetryRedactedMapFields,
        isNot(contains(unredactedOperationalField)),
        reason: '`$unredactedOperationalField` should not be over-redacted.',
      );
    }
  });

  test('rejects invalid expense telemetry scalar values before Firestore', () {
    final negativeCountSnapshot = _expenseTelemetrySnapshotForSanitizer(
      totalEventCount: -1,
    );
    final negativeRateSnapshot = _expenseTelemetrySnapshotForSanitizer(
      timeSpentEventCount: 1,
      totalTimeSpentMs: -1000,
    );

    expect(
      () => MaintainiacFirestoreDocumentBuilder.expenseTelemetrySummaryDocument(
        orgId: 'ORG-1',
        snapshot: negativeCountSnapshot,
      ),
      throwsA(
        isA<ArgumentError>().having(
          (error) => error.message,
          'message',
          contains('Counts must be positive'),
        ),
      ),
    );
    expect(
      () => MaintainiacFirestoreDocumentBuilder.expenseTelemetrySummaryDocument(
        orgId: 'ORG-1',
        snapshot: negativeRateSnapshot,
      ),
      throwsA(
        isA<ArgumentError>().having(
          (error) => error.message,
          'message',
          contains('Rates must be finite'),
        ),
      ),
    );
  });

  test('sanitizes expense telemetry maps and drill-down labels', () {
    final snapshot = _expenseTelemetrySnapshotForSanitizer(
      eventCounts: const {
        'Receipt Text Private Store Total 3.24': 2,
        'negative count': -1,
      },
      ocrFailureSourceCounts: const {
        'Photo Import Private Store': 3,
        'bad negative': -9,
      },
      topOcrFailureSource: 'Photo Import Private Store',
      topOcrFailureStage: 'after import before parser',
    );

    final doc =
        MaintainiacFirestoreDocumentBuilder.expenseTelemetrySummaryDocument(
          orgId: 'ORG-1',
          summaryId: 'latest',
          snapshot: snapshot,
        );

    expect(doc.data['eventCounts'], {
      'receipt_text_private_store_total_3_24': 2,
    });
    expect(doc.data['ocrFailureSourceCounts'], {
      'photo_import_private_store': 3,
    });
    expect(doc.data['topOcrFailureSource'], 'photo_import_private_store');
    expect(doc.data['topOcrFailureStageLabel'], 'After import before parser');
    expect(doc.data.toString(), isNot(contains('3.24')));
    expect(doc.data.toString().toLowerCase(), isNot(contains('private store')));
  });

  test('rejects unsafe OCR contract before Firestore queueing', () {
    final snapshot = ExpenseTelemetryHealthSnapshot.fromRecords(
      const [],
      generatedAtUtc: DateTime.utc(2026, 6, 24, 13),
    );
    final safeContract = ExpenseExportSnapshot(
      exportedAt: DateTime.utc(2026, 6, 24, 13),
      range: ExpenseDateRange(
        start: DateTime(2026, 6, 1),
        end: DateTime(2026, 6, 30),
      ),
      categoryFilter: ExpenseExportCategoryFilter.all,
      receipts: const [],
    ).commandCenterOcrContract;
    final unsafeContract = Map<String, Object?>.from(safeContract)
      ..['merchantName'] = 'Private Store'
      ..['ocrTopPrimaryIssue'] = 'Lowes total 3.24 needs review';

    expect(
      () => MaintainiacFirestoreDocumentBuilder.expenseTelemetrySummaryDocument(
        orgId: 'ORG-1',
        snapshot: snapshot,
        commandCenterOcrContract: unsafeContract,
      ),
      throwsArgumentError,
    );
  });

  test('detects unsafe OCR Firestore summary document drift', () {
    final snapshot = ExpenseTelemetryHealthSnapshot.fromRecords(
      const [],
      generatedAtUtc: DateTime.utc(2026, 6, 24, 13),
    );
    final safeContract = ExpenseExportSnapshot(
      exportedAt: DateTime.utc(2026, 6, 24, 13),
      range: ExpenseDateRange(
        start: DateTime(2026, 6, 1),
        end: DateTime(2026, 6, 30),
      ),
      categoryFilter: ExpenseExportCategoryFilter.all,
      receipts: const [],
    ).commandCenterOcrContract;
    final unsafeDraft = MaintainiacFirestoreDocumentDraft(
      path: 'orgs/ORG-1/receiptDiagnostics/event',
      data: {
        ...MaintainiacFirestoreDocumentBuilder.expenseTelemetrySummaryDocument(
          orgId: 'ORG-1',
          snapshot: snapshot,
          commandCenterOcrContract: safeContract,
        ).data,
        'uploadShape': 'per_receipt_documents',
        'rawEventUploadCount': 9,
        'rawOcrText': 'PRIVATE STORE TOTAL 3.24',
        'commandCenterOcrContract': {
          ...safeContract,
          'merchantName': 'Private Store',
          'ocrTopPrimaryIssue': 'Lowes total 3.24 needs review',
        },
      },
    );

    final findings =
        MaintainiacFirestoreDocumentBuilder.expenseTelemetrySummaryOcrContractFindingsFor(
          unsafeDraft,
        );

    expect(
      findings,
      contains('invalid_path:orgs/ORG-1/receiptDiagnostics/event'),
    );
    expect(findings, contains('invalid_upload_shape:per_receipt_documents'));
    expect(findings, contains('raw_event_upload_count:9'));
    expect(findings, contains('forbidden_top_level_key:rawOcrText'));
    expect(findings, contains('ocr_contract:unexpected_key:merchantName'));
    expect(findings, contains('ocr_contract:private_text:merchantName'));
    expect(findings, contains('ocr_contract:private_text:ocrTopPrimaryIssue'));
  });

  test('builds shared correction candidate with hashes, not receipt text', () {
    final memory = ExpenseReceiptItemMemory(
      id: 'local',
      merchantName: 'Private Hardware On Main Street',
      description: '1/2 COPPER ELBOW PRIVATE JOB 4.99',
      normalizedDescription: '1 2 copper elbow private job 4 99',
      rawReceiptText: '1/2 COPPER ELBOW PRIVATE JOB 4.99',
      correctedDescription: 'Copper elbow',
      category: 'Plumbing fittings',
      useName: ExpenseLineUse.business.name,
      unit: 'each',
      quantity: 1,
      unitsPerPackage: 1,
      subtotal: 4.99,
      unitPrice: 4.99,
      catalogItemId: 'plumbing:fittings:copper_elbow',
      catalogItemName: 'Copper elbow',
      catalogItemPath: 'Plumbing / Fittings / Copper',
      catalogMatchConfidence: .92,
      catalogMatchedTerms: const ['copper elbow'],
      parserConfidence: .88,
      parserReviewLabel: 'Good',
      parserReviewReason: 'catalog match',
      reviewAction: 'edited',
      seenCount: 4,
      firstSeenAt: DateTime.utc(2026, 6, 1),
      lastSeenAt: DateTime.utc(2026, 6, 20),
    );

    final doc =
        MaintainiacFirestoreDocumentBuilder.sharedCorrectionCandidateDocument(
          memory,
          submittedAtUtc: DateTime.utc(2026, 6, 23),
        );

    expect(
      doc.path,
      startsWith('${MaintainiacFirestoreSchema.sharedCorrectionCandidates}/'),
    );
    expect(doc.data['schema'], 'shared_correction_candidate_v1');
    expect(doc.data['merchantHash'], isA<String>());
    expect(doc.data['normalizedDescriptionHash'], isA<String>());
    expect(doc.data['rawReceiptTextHash'], isA<String>());
    expect(doc.data['catalogItemId'], 'plumbing:fittings:copper_elbow');
    expect(doc.data['seenCountBucket'], '4_9');
    expect(doc.data['firstSeenAgeBucket'], 'month');

    final encoded = doc.data.toString().toLowerCase();
    expect(encoded, isNot(contains('private hardware')));
    expect(encoded, isNot(contains('private job')));
    expect(encoded, isNot(contains('4.99')));
    expect(encoded, isNot(contains('copper elbow')));
    expect(encoded, isNot(contains('plumbing / fittings')));
  });
}

ExpenseTelemetryHealthSnapshot _expenseTelemetrySnapshotForSanitizer({
  int totalEventCount = 1,
  int timeSpentEventCount = 0,
  int totalTimeSpentMs = 0,
  Map<String, int> eventCounts = const {'screenOpened': 1},
  Map<String, int> ocrFailureSourceCounts = const {},
  String topOcrFailureSource = '',
  String topOcrFailureStage = '',
}) {
  return ExpenseTelemetryHealthSnapshot(
    generatedAtUtc: DateTime.utc(2026, 6, 24, 13),
    totalEventCount: totalEventCount,
    pendingUploadCount: 1,
    uploadedEventCount: 0,
    eventCounts: eventCounts,
    platformCounts: const {'android': 1},
    deviceTierCounts: const {'high': 1},
    storageModeCounts: const {'normal': 1},
    planStatusCounts: const {'paid': 1},
    connectionStatusCounts: const {'online': 1},
    screenOpenCount: 1,
    timeSpentEventCount: timeSpentEventCount,
    totalTimeSpentMs: totalTimeSpentMs,
    addExpenseStartedCount: 1,
    addExpenseCompletedCount: 1,
    addExpenseAbandonedCount: 0,
    validationErrorCount: 0,
    saveFailureCount: 0,
    imageAttachSuccessCount: 1,
    imageAttachFailureCount: 0,
    ocrStartedCount: 1,
    ocrCompletedCount: 1,
    ocrFailedCount: 0,
    parserStartedCount: 1,
    parserCompletedCount: 1,
    parserNeedsReviewCount: 0,
    parserFailedCount: 0,
    ocrCorrectionOpenedCount: 0,
    appFilledReceiptLineConfirmedCount: 1,
    appFilledReceiptLineCorrectedCount: 0,
    userCorrectionCount: 0,
    cloudBackupSuccessCount: 1,
    cloudBackupFailureCount: 0,
    syncPendingCount: 1,
    syncedCount: 1,
    syncFailedCount: 0,
    expenseSummaryQueuedCount: 1,
    expenseSummaryOcrContractQueuedCount: 1,
    expenseSummaryOcrContractSkippedCount: 0,
    expenseSummaryOcrContractSourceCounts: const {'rolling_local_ledger': 1},
    topExpenseSummaryOcrContractSource: 'rolling_local_ledger',
    expenseSummaryOcrContractSkippedReasonCounts: const {},
    topExpenseSummaryOcrContractSkippedReason: '',
    exportStartedCount: 1,
    exportCompletedCount: 1,
    exportBlockedCount: 0,
    exportFailedCount: 0,
    ocrFailureCauseCounts: const {},
    topOcrFailureCause: '',
    ocrFailureSourceCounts: ocrFailureSourceCounts,
    topOcrFailureSource: topOcrFailureSource,
    ocrFailureStageCounts: topOcrFailureStage.isEmpty
        ? const {}
        : {topOcrFailureStage: 1},
    topOcrFailureStage: topOcrFailureStage,
    failureBreakdowns: const [],
    recentFailureDetails: const [],
  );
}

ExpenseTelemetryHealthSnapshot _expenseTelemetryFailureSnapshot(int count) {
  final records = [
    for (var index = 0; index < count; index += 1)
      ExpenseTelemetryRecord(
        id: 'evt_failure_$index',
        queuedAtUtc: DateTime.utc(2026, 6, 24, 12, index),
        payload: ExpenseTelemetryPolicy.sanitize(
          ExpenseTelemetryEvent(
            type: ExpenseTelemetryEventType.ocrFailed,
            failureKind: 'receipt_failure_$index',
            diagnostic: ExpenseFailureDiagnostic(
              workflowStep: ExpenseWorkflowStep.receiptOcr,
              failedAt: 'after_capture_before_parser_$index',
              confirmedCause: 'receipt_failure_$index',
              causeStatus: ExpenseFailureCauseStatus.confirmed,
              evidence: 'ocr_severity_blocked_source_photo_$index',
              missingEvidence: 'none',
              retryCount: index % 3,
              abandoned: index.isOdd,
            ),
          ),
        ),
      ),
  ];
  return ExpenseTelemetryHealthSnapshot.fromRecords(
    records,
    generatedAtUtc: DateTime.utc(2026, 6, 24, 13),
  );
}
