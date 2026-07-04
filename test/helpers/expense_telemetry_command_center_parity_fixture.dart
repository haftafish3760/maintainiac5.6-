import 'package:maintaniac/screens/expenses/data/expense_screen_telemetry.dart';

import 'expense_telemetry_command_center_ocr_started_metadata.dart';

ExpenseTelemetryHealthSnapshot
buildExpenseTelemetryCommandCenterParitySnapshot() {
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
      ExpenseTelemetryEvent(
        type: ExpenseTelemetryEventType.ocrStarted,
        context: context,
        metadata: buildExpenseTelemetryCommandCenterOcrStartedMetadata(),
      ),
    ),
    record(
      'evt_ocr_completed',
      const ExpenseTelemetryEvent(
        type: ExpenseTelemetryEventType.ocrCompleted,
        context: context,
        metadata: {
          'ocrSourceHandoffStatus': 'ready_for_parser',
          'ocrSourceHandoffSignalCounts': {'native_photo_source': 1},
          'ocrSourceStitchSignalCounts': {'stitched_source': 1},
          'ocrSourceScannerDecisionCounts': {'scanner_cleanup_applied': 1},
          'ocrSourceCaptureSourceSignalCounts': {'native_original_image': 1},
          'ocrSourcePhotoQualityRiskCounts': {'photo_quality_review': 1},
          'ocrSourceQualityReviewStatus': 'quality_review_passed',
          'ocrSourceQualityReviewAction': 'continue_to_parser',
          'clientProofRedactionStatus': 'ready_for_client_proof',
          'clientProofVisibilityCounts': {'business_lines_visible': 1},
          'selectedReceiptLinePurpose': 'client_proof',
          'selectedReceiptLineCount': 2,
          'excludedReceiptLineCount': 1,
          'clientProofReviewLineCount': 1,
          'redactedReceiptLineCount': 1,
          'clientProofRedactionPlanStatus': 'review_required',
          'clientProofVisibleLineCount': 2,
          'clientProofHiddenLineCount': 1,
          'clientProofPlanReviewLineCount': 1,
          'clientProofLayoutRedactionStatus': 'review_required',
          'clientProofLayoutVisibleLineCount': 2,
          'clientProofLayoutHiddenLineCount': 1,
          'clientProofLayoutIgnoredLineCount': 1,
          'clientProofLayoutProtectedTypeCount': 1,
          'clientProofLayoutKeepsMerchantContext': true,
          'clientProofLayoutKeepsTotalsContext': true,
        },
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
        metadata: {
          'parsedCategoryBuckets': {'fuel': 1},
          'parserFieldConfidenceBuckets': {'high': 1},
          'parserCategoryHealthCounts': {'category_fuel_ready': 1},
          'parserCategoryReviewActionCode': 'accept_parser_suggestion',
          'parserPackPressureStatus': 'core_pack_sufficient',
          'receiptBrainParserLimitOutcome': 'core_parser_enough',
          'receiptBrainLowStorageDownloadRiskCounts': {'low_risk': 1},
          'receiptBrainFullOfflineMustStayOptionalCounts': {
            'full_offline_optional': 1,
          },
          'receiptBrainFullOfflineExceedsBaseGuardrailCounts': {
            'kept_out_of_base': 1,
          },
          'parserRequiredFieldStatusCounts': {'vendor_ready': 1},
          'parserDownstreamReadinessStatus': 'expense_lines_ready',
          'parserDownstreamReadinessCounts': {
            'parser_downstream_expense_lines_ready': 1,
          },
          'parserReviewRootCauseCode': 'none',
          'localReceiptParserRoutingCode': 'fuel_simple_local',
          'localReceiptParserKeptLocalCount': 1,
          'localReceiptParserOptionalPackOfferCount': 0,
          'localParserEvidenceOutcomeCounts': {'local_parser_ready': 1},
          'ocrParserTaskCounts': {'vendor_candidate': 1},
          'ocrFieldReadinessCounts': {'vendor_ready': 1},
        },
      ),
    ),
    record(
      'evt_parser_review',
      const ExpenseTelemetryEvent(
        type: ExpenseTelemetryEventType.parserNeedsReview,
        context: context,
        metadata: {
          'parsedCategoryBuckets': {'materials': 1},
          'reviewCategoryBuckets': {'materials': 1},
          'parserFieldConfidenceBuckets': {'medium': 1},
          'parserCategoryHealthCounts': {'category_materials_needs_review': 1},
          'parserRequiredFieldStatusCounts': {'total_needs_review': 1},
          'parserReviewRootCauseCode': 'total_needs_review',
          'ocrParserTaskCounts': {'total_review_required': 1},
          'ocrFieldReadinessCounts': {'total_needs_review': 1},
        },
      ),
    ),
    record(
      'evt_parser_failed',
      const ExpenseTelemetryEvent(
        type: ExpenseTelemetryEventType.parserFailed,
        context: context,
        failureKind: 'total_mismatch',
        metadata: {
          'parsedCategoryBuckets': {'maintenance': 1},
          'parserCategoryHealthCounts': {'category_maintenance_failed': 1},
          'parserRequiredFieldStatusCounts': {'vendor_missing': 1},
          'ocrParserTaskCounts': {'vendor_missing': 1},
          'ocrFieldReadinessCounts': {'vendor_missing': 1},
        },
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

  return snapshot;
}
