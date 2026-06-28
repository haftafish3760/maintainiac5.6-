import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/expenses/data/expense_screen_telemetry.dart';
import 'package:maintaniac/screens/expenses/data/expense_screen_telemetry_recorder.dart';
import 'package:maintaniac/screens/expenses/data/expense_screen_telemetry_summary_scheduler.dart';

import 'helpers/expense_telemetry_schema_expectations.dart';

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
    'records scheduled OCR summary queue trace without receipt content',
    () async {
      final store = await ExpenseTelemetryStore.create();

      await ExpenseScreenTelemetryRecorder.recordSummaryScheduleTrace(
        const ExpenseTelemetrySummaryScheduleResult(
          status: ExpenseTelemetrySummaryScheduleStatus.queued,
          queuedPath: 'orgs/ORG-1/expenseTelemetrySummaries/latest',
          ocrContractQueued: true,
          ocrContractSource: 'rolling_local_ledger',
        ),
      );

      expect(store.records, hasLength(1));
      final payload = store.records.single.payload;
      final metadata = payload['metadata'] as Map<String, Object?>;
      expect(payload['event'], ExpenseTelemetryEventType.syncPending.name);
      expect(metadata['syncState'], 'expense_summary_queued');
      expect(metadata['summaryStatus'], 'queued');
      expect(metadata['ocrContractQueued'], isTrue);
      expect(metadata['ocrContractSource'], 'rolling_local_ledger');
      expect(metadata.containsKey('queuedPath'), isFalse);
      expect(payload.toString().toLowerCase(), isNot(contains('receipt text')));
      expect(payload.toString(), isNot(contains('ORG-1')));
    },
  );

  test(
    'does not record scheduled summary trace for throttled checks',
    () async {
      final store = await ExpenseTelemetryStore.create();

      await ExpenseScreenTelemetryRecorder.recordSummaryScheduleTrace(
        ExpenseTelemetrySummaryScheduleResult(
          status: ExpenseTelemetrySummaryScheduleStatus.throttled,
          nextAllowedAtUtc: DateTime.utc(2026, 6, 24, 13, 15),
        ),
      );

      expect(store.records, isEmpty);
    },
  );

  test('summarizes scheduled OCR summary queue traces for Command 1', () async {
    final store = await ExpenseTelemetryStore.create();

    await store.enqueue(
      const ExpenseTelemetryEvent(
        type: ExpenseTelemetryEventType.syncPending,
        metadata: {
          'syncState': 'expense_summary_queued',
          'summaryStatus': 'queued',
          'ocrContractQueued': true,
          'ocrContractSource': 'rolling_local_ledger',
        },
      ),
      queuedAtUtc: DateTime.utc(2026, 6, 24, 12),
    );
    await store.enqueue(
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
      queuedAtUtc: DateTime.utc(2026, 6, 24, 12, 1),
    );
    await store.enqueue(
      const ExpenseTelemetryEvent(
        type: ExpenseTelemetryEventType.syncPending,
        metadata: {'syncState': 'unrelated_sync_queue'},
      ),
      queuedAtUtc: DateTime.utc(2026, 6, 24, 12, 2),
    );

    final snapshot = store.buildHealthSnapshot(
      nowUtc: DateTime.utc(2026, 6, 24, 13),
    );
    final map = snapshot.toCommandCenterMap();
    final encoded = map.toString().toLowerCase();

    expect(snapshot.syncPendingCount, 3);
    expect(snapshot.expenseSummaryQueuedCount, 2);
    expect(snapshot.expenseSummaryOcrContractQueuedCount, 1);
    expect(snapshot.expenseSummaryOcrContractSkippedCount, 1);
    expect(snapshot.expenseSummaryOcrContractSourceCounts, {
      'rolling_local_ledger': 1,
      'none': 1,
    });
    expect(snapshot.topExpenseSummaryOcrContractSource, 'none');
    expect(snapshot.expenseSummaryOcrContractSkippedReasonCounts, {
      'ledger_ocr_contract_disabled': 1,
    });
    expect(
      snapshot.topExpenseSummaryOcrContractSkippedReason,
      'ledger_ocr_contract_disabled',
    );
    expect(map['expenseSummaryQueuedCount'], 2);
    expect(map['expenseSummaryOcrContractQueuedCount'], 1);
    expect(map['expenseSummaryOcrContractSkippedCount'], 1);
    expect(encoded, isNot(contains('lowes')));
    expect(encoded, isNot(contains('receipt text')));
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

  test('allows only content-free receipt camera health metadata', () {
    final sanitized = ExpenseTelemetryPolicy.sanitize(
      ExpenseTelemetryEvent(
        type: ExpenseTelemetryEventType.ocrStarted,
        metadata: const {
          'source': 'expenses',
          'captureFlow': 'receipt_photo_review',
          'savedProofCount': 2,
          'ocrSourceCount': 1,
          'captureDiagnosticsCount': 2,
          'capturedPhotoMegapixelBuckets': {'high_9mp_to_18mp': 1},
          'capturedPhotoByteBuckets': {'normal_1mb_to_3mb': 1},
          'capturedPhotoBrightnessBuckets': {'captured_dim': 1},
          'capturedPhotoSharpnessBuckets': {'captured_sharp': 1},
          'capturedPhotoQualitySignals': {'review_before_saving': 1},
          'capturedPhotoExposureMismatches': {'live_ok_capture_dim': 1},
          'capturedPhotoWidthMax': 3024,
          'capturedPhotoHeightMax': 4032,
          'brightnessBuckets': {'normal': 1, 'dark': 1},
          'readabilitySignalBuckets': {'readable': 1},
          'autoExposureDecisionBuckets': {'waiting_for_receipt_target': 1},
          'autoExposureBrightnessBuckets': {'dark_assisted': 1},
          'autoExposureCandidateBuckets': {'brighten': 1},
          'autoExposureCandidateFrameTotal': 2,
          'exposureAssistStatuses': {'auto_adjusted': 1},
          'framingConfidenceBuckets': {'usable': 2},
          'perspectiveReadinessBuckets': {
            'perspective_ready_safe_bounds': 1,
            'perspective_skipped_cut_off_risk': 1,
          },
          'focusStatusBuckets': {'requested': 1},
          'autoCaptureStatusBuckets': {'manual_only': 1},
          'closeActionBuckets': {'done_returned_captured_sections': 1},
          'pendingCloseAfterCaptureCount': 1,
          'closeResultDeliveredCount': 1,
          'autoCaptureAllowedCount': 1,
          'autoCaptureCurrentlyAllowedCount': 1,
          'storageSafetyLevelBuckets': {'maximum': 1},
          'storageSafetyReasonBuckets': {'tight_storage_tiny_proofs': 1},
          'storageConstrainedCount': 1,
          'photoEditActions': {'manual_crop': 1, 'manual_rotate': 1},
          'userEditedPhotoCount': 2,
          'edgeDetectionEnabledCount': 2,
          'tapFocusTotal': 3,
          'scannerCleanupUsedCount': 1,
          'cleanupActionCount': 3,
          'cleanupActions': ['auto_orient', 'scanner_cleanup'],
          'stitchStatus': 'stitched',
          'stitchFallbackReason': 'stitched',
          'stitchConfidenceBucket': 'high',
        },
      ),
    );

    final metadata = sanitized['metadata'] as Map<String, Object?>;
    expect(metadata['captureFlow'], 'receipt_photo_review');
    expect(metadata['capturedPhotoMegapixelBuckets'], {'high_9mp_to_18mp': 1});
    expect(metadata['capturedPhotoByteBuckets'], {'normal_1mb_to_3mb': 1});
    expect(metadata['capturedPhotoBrightnessBuckets'], {'captured_dim': 1});
    expect(metadata['capturedPhotoSharpnessBuckets'], {'captured_sharp': 1});
    expect(metadata['capturedPhotoQualitySignals'], {
      'review_before_saving': 1,
    });
    expect(metadata['capturedPhotoExposureMismatches'], {
      'live_ok_capture_dim': 1,
    });
    expect(metadata['capturedPhotoWidthMax'], 3024);
    expect(metadata['capturedPhotoHeightMax'], 4032);
    expect(metadata['photoEditActions'], {
      'manual_crop': 1,
      'manual_rotate': 1,
    });
    expect(metadata['autoExposureDecisionBuckets'], {
      'waiting_for_receipt_target': 1,
    });
    expect(metadata['autoExposureBrightnessBuckets'], {'dark_assisted': 1});
    expect(metadata['autoExposureCandidateBuckets'], {'brighten': 1});
    expect(metadata['autoExposureCandidateFrameTotal'], 2);
    expect(metadata['cleanupActions'], ['auto_orient', 'scanner_cleanup']);
    expect(metadata['userEditedPhotoCount'], 2);
    expect(metadata['closeActionBuckets'], {
      'done_returned_captured_sections': 1,
    });
    expect(metadata['pendingCloseAfterCaptureCount'], 1);
    expect(metadata['perspectiveReadinessBuckets'], {
      'perspective_ready_safe_bounds': 1,
      'perspective_skipped_cut_off_risk': 1,
    });
    expect(metadata['closeResultDeliveredCount'], 1);
    expect(metadata['autoCaptureAllowedCount'], 1);
    expect(metadata['autoCaptureCurrentlyAllowedCount'], 1);
    expect(metadata['storageSafetyLevelBuckets'], {'maximum': 1});
    expect(metadata['storageSafetyReasonBuckets'], {
      'tight_storage_tiny_proofs': 1,
    });
    expect(metadata['storageConstrainedCount'], 1);

    expect(
      () => ExpenseTelemetryPolicy.sanitize(
        ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.ocrStarted,
          metadata: const {
            'cleanupActions': ['scanner cleanup with spaces'],
          },
        ),
      ),
      throwsArgumentError,
    );
    expect(
      () => ExpenseTelemetryPolicy.sanitize(
        ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.ocrStarted,
          metadata: const {'storeName': 'LOWES'},
        ),
      ),
      throwsArgumentError,
    );
  });

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

  test('summarizes OCR failure causes separately for Command 1', () async {
    final store = await ExpenseTelemetryStore.create();
    final context = _context();

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

  test(
    'summarizes parser category health for Command 1 without receipt content',
    () async {
      final store = await ExpenseTelemetryStore.create();
      final context = _context();

      await store.enqueue(
        ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.parserCompleted,
          context: context,
          categoryGroup: 'fuel',
          metadata: const {
            'source': 'expenses',
            'parserDepth': 'inventoryMatching',
            'lineCount': 3,
            'parsedCategoryBuckets': {'fuel': 2, 'materials': 1},
            'parserFieldConfidenceBuckets': {
              'merchant_good': 1,
              'total_good': 1,
            },
            'parseQualityBucket': 'high',
            'parserLineReviewCount': 0,
            'subtotalReconciliationStatus': 'matched',
            'taxMathStatus': 'matched',
          },
        ),
      );
      await store.enqueue(
        ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.parserNeedsReview,
          context: context,
          categoryGroup: 'groceries',
          metadata: const {
            'source': 'expenses',
            'parserDepth': 'inventoryMatching',
            'lineCount': 4,
            'parsedCategoryBuckets': {'groceries': 3, 'fuel': 1},
            'reviewCategoryBuckets': {'groceries': 2},
            'parserFieldConfidenceBuckets': {
              'tax_review': 1,
              'total_review': 1,
            },
            'parseQualityBucket': 'medium',
            'parserLineReviewCount': 2,
            'subtotalReconciliationStatus': 'needs_review',
            'taxMathStatus': 'needs_review',
          },
        ),
      );
      await store.enqueue(
        ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.parserFailed,
          context: context,
          categoryGroup: 'maintenance',
          failureKind: 'receipt_parser_no_usable_fields',
          diagnostic: const ExpenseFailureDiagnostic(
            workflowStep: ExpenseWorkflowStep.receiptParser,
            failedAt: 'parser_after_ocr',
            confirmedCause: 'receipt_parser_no_usable_fields',
            causeStatus: ExpenseFailureCauseStatus.confirmed,
            evidence: 'no_fields_detected',
          ),
          metadata: const {
            'source': 'expenses',
            'parserDepth': 'inventoryMatching',
            'lineCount': 0,
            'parsedCategoryBuckets': {'maintenance': 1},
            'parseQualityBucket': 'very_low',
          },
        ),
      );

      final snapshot = store.buildHealthSnapshot(
        nowUtc: DateTime.utc(2026, 6, 24, 13),
      );
      final map = snapshot.toCommandCenterMap();
      final encoded = map.toString().toLowerCase();

      expect(snapshot.parserCategoryCounts, {
        'fuel': 3,
        'materials': 1,
        'groceries': 3,
      });
      expect(snapshot.parserNeedsReviewCategoryCounts, {'groceries': 2});
      expect(snapshot.parserFailedCategoryCounts, {'maintenance': 1});
      expect(snapshot.parserFieldConfidenceCounts, {
        'merchant_good': 1,
        'total_good': 1,
        'tax_review': 1,
        'total_review': 1,
      });
      expect(map['parserCategoryCounts'], snapshot.parserCategoryCounts);
      expect(
        map['parserNeedsReviewCategoryCounts'],
        snapshot.parserNeedsReviewCategoryCounts,
      );
      expect(map['parserFailedCategoryCounts'], {'maintenance': 1});
      expect(map['topParserCategory'], 'fuel');
      expect(map['topParserNeedsReviewCategory'], 'groceries');
      expect(map['topParserFailedCategory'], 'maintenance');
      expect(encoded, isNot(contains('lowes')));
      expect(encoded, isNot(contains('receipttext')));
      expect(encoded, isNot(contains('merchantname')));
    },
  );

  test('keeps OCR failure source buckets allowlisted', () async {
    final store = await ExpenseTelemetryStore.create();
    final context = _context();

    final evidenceCases = [
      'warning_blurry_source_photo_total_3_24',
      'warning_pdf_source_document_total_4_25',
      'warning_text_source_pasted_text_total_5_26',
      'warning_mixed_source_combined_total_6_27',
      'warning_missing_source_missing_total_7_28',
      'warning_private_source_lowes_total_8_29',
      'warning_private_source_private_store_total_9_30',
      'warning_private_source_users_notes_total_10_31',
    ];
    for (var index = 0; index < evidenceCases.length; index += 1) {
      final evidence = evidenceCases[index];
      await store.enqueue(
        ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.ocrFailed,
          context: context,
          failureKind: 'receipt_photo_read_failed_$index',
          diagnostic: ExpenseFailureDiagnostic(
            workflowStep: ExpenseWorkflowStep.receiptOcr,
            failedAt: 'during_ocr_read_$index',
            confirmedCause: 'receipt_photo_read_failed_$index',
            causeStatus: ExpenseFailureCauseStatus.confirmed,
            evidence: evidence,
          ),
        ),
      );
    }

    final snapshot = store.buildHealthSnapshot(
      nowUtc: DateTime.utc(2026, 6, 28, 14),
    );

    expect(snapshot.ocrFailureSourceCounts, {
      'photo': 1,
      'pdf': 1,
      'importedtext': 1,
      'mixed': 1,
      'none': 1,
      'unknown': 3,
    });
    expect(
      snapshot.ocrFailureSourceCounts.keys.toSet(),
      expectedExpenseTelemetryOcrFailureSourceBuckets,
    );
    expect(snapshot.ocrFailureSourceCounts, isNot(contains('lowes')));
    expect(snapshot.ocrFailureSourceCounts, isNot(contains('private_store')));
    expect(snapshot.ocrFailureSourceCounts, isNot(contains('users_notes')));
    expect(
      snapshot.toCommandCenterMap()['topOcrFailureSourceAction'],
      contains('source tagging'),
    );
  });

  test('gives every OCR failure source bucket a clear action', () async {
    const cases = {
      'photo': (
        evidence: 'warning_blurry_source_photo_total_3_24',
        actionHint: 'camera focus',
      ),
      'pdf': (
        evidence: 'warning_pdf_source_pdf_total_4_25',
        actionHint: 'PDF safety checks',
      ),
      'importedtext': (
        evidence: 'warning_text_source_imported_text_total_5_26',
        actionHint: 'pasted/imported receipt text cleanup',
      ),
      'mixed': (
        evidence: 'warning_mixed_source_mixed_total_6_27',
        actionHint: 'mixed receipt sources',
      ),
      'none': (
        evidence: 'warning_missing_source_none_total_7_28',
        actionHint: 'without a usable receipt photo',
      ),
      'unknown': (
        evidence: 'warning_private_source_lowes_total_8_29',
        actionHint: 'source tagging',
      ),
    };
    expect(cases.keys.toSet(), expectedExpenseTelemetryOcrFailureSourceBuckets);

    for (final entry in cases.entries) {
      final snapshot = ExpenseTelemetryHealthSnapshot.fromRecords([
        ExpenseTelemetryRecord(
          id: 'evt-source-action-${entry.key}',
          queuedAtUtc: DateTime.utc(2026, 6, 28, 17),
          payload: Map.unmodifiable({
            'event': ExpenseTelemetryEventType.ocrFailed.name,
            'workflowStep': ExpenseWorkflowStep.receiptOcr.name,
            'failedAt': 'during_ocr_read',
            'confirmedCause': 'receipt_photo_read_failed',
            'causeStatus': ExpenseFailureCauseStatus.confirmed.name,
            'evidence': entry.value.evidence,
            'platform': 'android',
            'deviceTier': 'high',
            'appVersion': '5.6.0',
          }),
        ),
      ], generatedAtUtc: DateTime.utc(2026, 6, 28, 17, 1));
      final map = snapshot.toCommandCenterMap();

      expect(map['topOcrFailureSource'], entry.key);
      expect(
        map['topOcrFailureSourceAction'],
        contains(entry.value.actionHint),
      );
      expect(
        map['topOcrFailureSourceAction'].toString().toLowerCase(),
        isNot(contains('lowes')),
      );
    }
  });

  test('covers every OCR failure cause with specific Command 1 action', () {
    const ocrCauses = <String, String>{
      'pdf_safety_blocked': 'safe copy',
      'pdf_too_large': 'smaller file',
      'pdf_unreadable': 'file validity',
      'pdf_read_failed': 'PDF rendering',
      'ocr_plugin_unavailable': 'OCR plugin',
      'receipt_photo_read_failed': 'image decoding',
      'receipt_photo_quality_needs_review': 'better focus',
      'missing_receipt_attachment': 'attach',
      'receipt_source_skipped': 'skipped attachment',
      'possible_missing_receipt_section': 'missing middle receipt section',
      'receipt_photo_overlap': 'stitch overlap area',
      'duplicate_receipt_text': 'duplicate suppression',
      'no_readable_text': 'blank',
      'ocr_unknown_failure': 'warning diagnostics',
    };

    for (final entry in ocrCauses.entries) {
      final action = ExpenseTelemetryHealthSnapshot.fromRecords([
        ExpenseTelemetryRecord(
          id: 'evt_${entry.key}',
          queuedAtUtc: DateTime.utc(2026, 6, 24, 12),
          payload: ExpenseTelemetryPolicy.sanitize(
            ExpenseTelemetryEvent(
              type: ExpenseTelemetryEventType.ocrFailed,
              context: _context(),
              failureKind: entry.key,
              diagnostic: ExpenseFailureDiagnostic(
                workflowStep: ExpenseWorkflowStep.receiptOcr,
                failedAt: 'during_receipt_ocr',
                confirmedCause: entry.key,
                causeStatus: ExpenseFailureCauseStatus.confirmed,
                evidence: 'warning_${entry.key}',
              ),
            ),
          ),
        ),
      ]).failureBreakdowns.single.recommendedAction;

      expect(
        action,
        contains(entry.value),
        reason: '${entry.key} should have a specific Command 1 action.',
      );
      expect(
        action,
        isNot(contains('Review receipt image quality, OCR source limits')),
        reason: '${entry.key} should not fall back to generic OCR guidance.',
      );
    }
  });

  test('covers action summaries across major failure workflows', () {
    const cases = [
      (
        id: 'ocr',
        event: 'ocrFailed',
        workflowStep: 'receiptOcr',
        confirmedCause: 'receipt_photo_read_failed',
        causeStatus: 'confirmed',
        evidence: 'source_photo_warning',
        missingEvidence: 'none',
        expectedWorkflow: 'Receipt OCR failed',
        expectedContext: 'photo capture or image readability',
        expectedNextStep: 'image decoding',
      ),
      (
        id: 'parser',
        event: 'parserFailed',
        workflowStep: 'receiptParser',
        confirmedCause: 'receipt_parser_no_usable_fields',
        causeStatus: 'confirmed',
        evidence: 'source_photo_parser_empty',
        missingEvidence: 'none',
        expectedWorkflow: 'Receipt parser failed',
        expectedContext: 'the failed workflow',
        expectedNextStep: 'parser rules',
      ),
      (
        id: 'attachment',
        event: 'imageAttachFailure',
        workflowStep: 'receiptAttachment',
        confirmedCause: 'receipt_attachment_copy_failed',
        causeStatus: 'confirmed',
        evidence: 'attachment_temp_file_missing',
        missingEvidence: 'none',
        expectedWorkflow: 'Receipt attachment failed',
        expectedContext: 'the failed workflow',
        expectedNextStep: 'receipt proof capture',
      ),
      (
        id: 'save',
        event: 'saveFailure',
        workflowStep: 'saveExpense',
        confirmedCause: 'ledger_save_failed',
        causeStatus: 'confirmed',
        evidence: 'ledger_save_exception',
        missingEvidence: 'none',
        expectedWorkflow: 'Save expense failed',
        expectedContext: 'the failed workflow',
        expectedNextStep: 'Hive state',
      ),
      (
        id: 'sync',
        event: 'syncFailed',
        workflowStep: 'sync',
        confirmedCause: 'hosted_sync_queue_failed',
        causeStatus: 'confirmed',
        evidence: 'sync_retry_limit',
        missingEvidence: 'none',
        expectedWorkflow: 'Sync failed',
        expectedContext: 'the failed workflow',
        expectedNextStep: 'hosted sync handoff',
      ),
      (
        id: 'cloud',
        event: 'cloudBackupFailure',
        workflowStep: 'cloudBackup',
        confirmedCause: 'cloud_backup_upload_failed',
        causeStatus: 'confirmed',
        evidence: 'cloud_upload_retry_limit',
        missingEvidence: 'none',
        expectedWorkflow: 'Cloud backup failed',
        expectedContext: 'the failed workflow',
        expectedNextStep: 'local queue state',
      ),
      (
        id: 'export',
        event: 'exportFailed',
        workflowStep: 'export',
        confirmedCause: 'expense_export_file_write_failed',
        causeStatus: 'confirmed',
        evidence: 'export_file_write_failed',
        missingEvidence: 'none',
        expectedWorkflow: 'Export failed',
        expectedContext: 'the failed workflow',
        expectedNextStep: 'file creation',
      ),
      (
        id: 'line_review',
        event: 'validationError',
        workflowStep: 'lineReview',
        confirmedCause: 'receipt_lines_need_review',
        causeStatus: 'confirmed',
        evidence: 'line_review_required',
        missingEvidence: 'none',
        expectedWorkflow: 'Line review failed',
        expectedContext: 'the failed workflow',
        expectedNextStep: 'low-confidence line classification',
      ),
      (
        id: 'unconfirmed',
        event: 'saveFailure',
        workflowStep: 'saveExpense',
        confirmedCause: 'cause_not_confirmed_ledger_save_failed',
        causeStatus: 'notConfirmed',
        evidence: 'ledger_save_exception',
        missingEvidence: 'exception_type_and_hive_box_state',
        expectedWorkflow: 'Save expense failed',
        expectedContext: 'cause is not confirmed yet',
        expectedNextStep: 'exception type and hive box state',
      ),
    ];

    final snapshot = ExpenseTelemetryHealthSnapshot.fromRecords([
      for (final entry in cases)
        ExpenseTelemetryRecord(
          id: 'evt_action_summary_${entry.id}',
          queuedAtUtc: DateTime.utc(2026, 6, 28, 23),
          payload: Map.unmodifiable({
            'event': entry.event,
            'workflowStep': entry.workflowStep,
            'failedAt': 'during_${entry.id}',
            'confirmedCause': entry.confirmedCause,
            'causeStatus': entry.causeStatus,
            'evidence': entry.evidence,
            'missingEvidence': entry.missingEvidence,
            'retryCount': 1,
            'platform': 'android',
            'deviceTier': 'high',
            'appVersion': '5.6.0',
          }),
        ),
    ], generatedAtUtc: DateTime.utc(2026, 6, 28, 23, 5));

    expect(snapshot.failureBreakdowns, hasLength(cases.length));
    for (final entry in cases) {
      final failure = snapshot.failureBreakdowns.singleWhere(
        (failure) => failure.confirmedCause == entry.confirmedCause,
      );
      expect(failure.actionSummary, contains(entry.expectedWorkflow));
      expect(failure.actionSummary, contains(entry.expectedContext));
      expect(failure.actionSummary, contains(entry.expectedNextStep));
      expect(failure.actionSummary, isNot(contains('_')));
      expect(failure.actionSummary.length, lessThanOrEqualTo(180));
    }
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
    'summarizes app-filled receipt line confirmation and correction rates',
    () {
      final context = _context();
      final snapshot = ExpenseTelemetryHealthSnapshot.fromRecords([
        ExpenseTelemetryRecord(
          id: 'evt_confirmed',
          queuedAtUtc: DateTime.utc(2026, 6, 24, 12),
          payload: ExpenseTelemetryPolicy.sanitize(
            ExpenseTelemetryEvent(
              type: ExpenseTelemetryEventType.appFilledReceiptLineConfirmed,
              context: context,
              categoryGroup: 'Fuel',
              metadata: const {
                'source': 'expenses',
                'lineUse': 'business',
                'parserConfidenceBucket': 'high',
              },
            ),
          ),
        ),
        ExpenseTelemetryRecord(
          id: 'evt_corrected',
          queuedAtUtc: DateTime.utc(2026, 6, 24, 12, 1),
          payload: ExpenseTelemetryPolicy.sanitize(
            ExpenseTelemetryEvent(
              type: ExpenseTelemetryEventType.appFilledReceiptLineCorrected,
              context: context,
              categoryGroup: 'Materials',
              metadata: const {
                'source': 'expenses',
                'lineUse': 'split',
                'parserConfidenceBucket': 'low',
              },
            ),
          ),
        ),
      ]);
      final map = snapshot.toCommandCenterMap();
      final encoded = map.toString().toLowerCase();

      expect(snapshot.appFilledReceiptLineConfirmedCount, 1);
      expect(snapshot.appFilledReceiptLineCorrectedCount, 1);
      expect(snapshot.appFilledReceiptLineCorrectionRate, .5);
      expect(snapshot.userCorrectionCount, 1);
      expect(map['appFilledReceiptLineConfirmedCount'], 1);
      expect(map['appFilledReceiptLineCorrectedCount'], 1);
      expect(map['appFilledReceiptLineCorrectionRate'], .5);
      expect(encoded, isNot(contains('lowes')));
      expect(encoded, isNot(contains('customer')));
      expect(encoded, isNot(contains('receipt text')));
    },
  );

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
