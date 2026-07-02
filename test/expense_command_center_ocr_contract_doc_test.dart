import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_export_models.dart';

import 'helpers/expense_telemetry_schema_expectations.dart';

void main() {
  test('Command Center OCR handoff doc mirrors the active contract', () {
    final doc = File(
      'docs/expense_command_center_ocr_contract.md',
    ).readAsStringSync();

    expect(doc, contains(ExpenseExportSnapshot.commandCenterOcrContractSchema));
    expect(doc, contains(ExpenseExportSnapshot.commandCenterOcrPrivacyScope));
    expect(doc, contains(ExpenseExportSnapshot.commandCenterOcrContentPolicy));

    for (final key in ExpenseExportSnapshot.commandCenterOcrAllowedKeys) {
      expect(doc, contains('`$key`'), reason: 'Missing field doc for $key');
    }
    for (final key in expectedExpenseTelemetryCommandCenterKeys) {
      expect(
        doc,
        contains('`$key`'),
        reason: 'Missing expense telemetry summary field doc for $key',
      );
    }

    for (final forbidden in const [
      'receipt image bytes',
      'raw OCR text',
      'item descriptions',
      'merchant/store names',
      'phone numbers',
      'email addresses',
      'local file paths',
      'transaction/auth/invoice/terminal numbers',
      'commandCenterOcrContractFindingsFor',
    ]) {
      expect(doc, contains(forbidden));
    }

    for (final firestoreContract in const [
      'orgs/{orgId}/expenseTelemetrySummaries/{summaryId}',
      'commandCenterOcrContract',
      'uploadShape',
      'single_summary_document',
      'rawEventUploadCount',
      'no per-receipt Command 1 documents',
      'no Firestore read per receipt',
      'Firestore Write Budget',
      'local-first telemetry',
      '15 minutes',
      '96 scheduled expense telemetry summary writes per org per day',
      '20,000 Firestore writes per day',
      'per-capture, per-failure, per-retry, per-line, or per-receipt writes',
      'enqueueReplacingPendingForPath',
      'replace the pending draft',
      'one bounded Firestore summary',
      'camera/OCR health',
      'ExpenseTelemetryFirestoreBridge.queueHealthSummary',
      'ExpenseTelemetrySummaryScheduler.queueIfDue',
      'ExpenseScreenTelemetryRecorder',
      'ExpenseTelemetryHealthSnapshot.toCommandCenterMap',
      'MaintainiacFirestoreDocumentBuilder.expenseTelemetrySummaryDocument',
      'includeLedgerOcrContract',
      'rolling 90-day local receipt window',
      'keeps every Command Center telemetry field in Firestore summary',
      'cannot silently disappear',
      'Expense Telemetry Summary Fields',
      'screenOpenCount',
      'averageTimeSpentSeconds',
      'addExpenseCompletionRate',
      'imageAttachFailureRate',
      'ocrSuccessRate',
      'parserSuccessRate',
      'parserReviewRate',
      'appFilledReceiptLineCorrectionRate',
      'cloudBackupFailureRate',
      'syncFailureRate',
      'exportFailureRate',
      'ocrFailureCauseCounts',
      'topOcrFailureSourceAction',
      'failureBreakdowns',
      'recentFailureDetails',
      'expected schema snapshot',
      'Firestore Metadata Boundary',
      'summaryId',
      'summaryScope',
      'commandCenterOcrContract',
      'must not be added to',
      'Local OCR remains available on the device',
      'Optional Google OCR',
      'cloud inventory matching',
      'must be an explicit user choice',
      'must not make',
      'basic receipt capture, local OCR, local review, or manual entry cloud-only',
      'CameraX/AVFoundation bridge',
      'not device-identifying data',
      'focus, exposure, missing receipt sections, overlap/stitch problems',
      'Expense Telemetry Schema Change Checklist',
      'test/helpers/expense_telemetry_schema_expectations.dart',
      '_sanitizeExpenseTelemetryMap',
      'Do not create a new per-event, per-receipt, per-failure, or separate admin',
      'Expense Telemetry Sanitizer Rules',
      'int` counts must be zero or greater',
      'double` rates and averages must be finite',
      'rounded to four decimal places',
      'count maps keep only entries whose values are nonnegative integers',
      'Unsupported scalar values, negative scalar counts, negative rates, `NaN`, and',
      'Expense Failure Drill-Down Caps',
      'failureBreakdowns` defaults to 20 entries',
      'hard-clamped to 50 entries',
      'recentFailureDetails` defaults to 50 entries',
      'hard-clamped to 100',
      'Expense Failure Drill-Down Object Schemas',
      'grouped failure view',
      'recent safe sample view',
      'Both shapes must include `missingEvidence` as `none`',
      'must not carry raw private receipt content',
      'Failure diagnostic machine-token fields',
      'grouping, filtering, and action routing',
      '`ocrFailureSourceAction`',
      'common receipt locations',
      '`location`',
      '`private_reference`',
      'Visible drill-down fields',
      '`failedAtLabel`',
      '`causeLabel`',
      '`evidenceLabel`',
      '`missingEvidenceLabel`',
      'free of raw snake-case diagnostic tokens',
      'map the token to its own UI copy',
      'known merchant names',
      'money-like values',
      'receipt/auth/transaction-length numbers',
      'tokenized fuel, retail, and auto-service',
      'Shell, Walmart, Home Depot, Jiffy Lube',
      'Pilot/Flying J',
      'Love\'s',
      'Casey\'s',
      'Kwik Trip',
      'Tractor Supply',
      'Harbor Freight',
      'Valvoline',
      'Take 5',
      'Firestone',
      'UPC/barcode-like',
      'underscore-separated totals',
      '`45_67`',
      '`109_23`',
      '_ExpenseTelemetryFirestoreRedactor',
      'failure token',
      'count-map fields',
      '`topOcrFailureSource`',
      '`appVersionCounts`',
      'over-redacted',
      'OCR failure source fields are isolated',
      '`photo`, `pdf`, `importedtext`',
      '`mixed`, `none`, or `unknown`',
      'Unrecognized `source_*` labels',
      '`ocrFailureSourceCounts`',
      'Every allowed source bucket',
      '`topOcrFailureSourceAction`',
      'camera focus, exposure, crop',
      'PDF-to-image conversion',
      'pasted/imported text cleanup',
      'stitched-photo fallback',
      'safe source tagging',
      'final Firestore summary sanitizer',
      'right investigation path',
      '`actionSummary`',
      'readable text',
      'lowercase token',
      'auth numbers',
      'receipt numbers',
      'source tokens',
      'store names, exact totals',
      '`source_camera`',
      '`source_image`',
      '`source_document`',
      '`source_pasted_text`',
      '`source_combined`',
      '`source_missing`',
      'malformed private source labels',
      'non-OCR drill-down rows',
      'tokenization',
      'poisoned source labels',
      'barcode-like values',
      '`merchant`',
      '`amount`',
      '`number`',
      'ultra-lean summary',
      'syncState',
      'expense_summary_queued',
      'summaryStatus',
      'ocrContractQueued',
      'ocrContractSource',
      'ocrContractSkippedReason',
      'expenseSummaryQueuedCount',
      'expenseSummaryOcrContractQueuedCount',
      'expenseSummaryOcrContractSkippedCount',
      'expenseSummaryOcrContractSourceCounts',
      'topExpenseSummaryOcrContractSource',
      'expenseSummaryOcrContractSkippedReasonCounts',
      'topExpenseSummaryOcrContractSkippedReason',
      'must not become a separate scheduler-trace collection',
      'Throttled scheduler checks should not create trace',
    ]) {
      expect(doc, contains(firestoreContract));
    }
  });

  test('documents every nested expense failure drill-down field', () {
    final doc = File(
      'docs/expense_command_center_ocr_contract.md',
    ).readAsStringSync();

    for (final key in expectedExpenseTelemetryFailureBreakdownKeys) {
      expect(
        doc,
        contains('`$key`'),
        reason: 'failureBreakdowns must document `$key`.',
      );
    }
    for (final key in expectedExpenseTelemetryRecentFailureDetailKeys) {
      expect(
        doc,
        contains('`$key`'),
        reason: 'recentFailureDetails must document `$key`.',
      );
    }
    for (final key in expectedExpenseTelemetryRedactedTokenFields) {
      expect(
        doc,
        contains('`$key`'),
        reason: 'Redacted failure token field `$key` must be documented.',
      );
    }
    for (final key in expectedExpenseTelemetryRedactedMapFields) {
      expect(
        doc,
        contains('`$key`'),
        reason: 'Redacted failure map field `$key` must be documented.',
      );
    }
    for (final privateKey in [
      'payload',
      'metadata',
      'receiptText',
      'rawOcrText',
      'merchantName',
      'itemDescription',
      'proofPath',
      'orgId',
      'userId',
    ]) {
      expect(doc, contains('`$privateKey`'));
    }
  });
}
