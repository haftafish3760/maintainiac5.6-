# Expense Command Center OCR Contract

This document is the handoff contract for Command 1 and any admin health
surface that consumes expense receipt OCR status. It describes the safe summary
payload produced by `ExpenseExportSnapshot.commandCenterOcrContract`.

Command 1 may use this contract to answer operational questions such as:

- how many receipt reads were saved
- how many saved reads were clean
- how many need review
- which OCR warning kind is most common
- which recovery action is most common
- which recovery target is most common
- what the top safe issue/action wording should be

Command 1 must not use this contract to inspect private receipt content.

## Current Contract

- `schema`: `expense_ocr_recovery_summary_v1`
- `privacyScope`: `summary_only_no_receipt_content`
- `contentPolicy`: `no_receipt_images_no_raw_ocr_text_no_item_descriptions`

The payload is a summary-only OCR health object. It is safe for an admin health
dashboard because it contains counts, rates, safe warning categories, and safe
recovery tokens. It does not contain the receipt image, raw OCR text, merchant
name, receipt address, customer data, phone number, email, notes, item
descriptions, proof file path, receipt number, transaction number, invoice
number, auth code, barcode, or line-item private content.

## Allowed Fields

Command 1 may read only these fields:

- `schema`
- `privacyScope`
- `contentPolicy`
- `rangeStart`
- `rangeEnd`
- `categoryFilter`
- `source`
- `destination`
- `receiptCount`
- `receiptsWithOcrReview`
- `receiptsNeedingOcrReview`
- `ocrReadsSaved`
- `ocrCleanReadCount`
- `ocrReadStatus`
- `ocrReadSummary`
- `ocrWarningCount`
- `ocrBlockingWarningCount`
- `ocrPartialWarningCount`
- `ocrReviewWarningCount`
- `ocrSourceCounts`
- `ocrTopSource`
- `ocrPrimaryWarningKindCounts`
- `ocrRecoveryActionCounts`
- `ocrRecoveryTargetCounts`
- `ocrTopCheck`
- `ocrTopPrimaryIssue`
- `ocrTopPrimaryAction`
- `ocrTopRecoveryAction`
- `ocrTopRecoveryTarget`

Any additional field is a contract change and must be rejected until it has a
privacy review, a code update, and a regression test.

## Field Meanings

- `receiptCount`: receipts included in the selected export/recap range.
- `receiptsWithOcrReview`: receipts that have OCR review metadata saved.
- `receiptsNeedingOcrReview`: receipts whose saved OCR review still needs human
  review.
- `ocrReadsSaved`: saved OCR review records in this payload.
- `ocrCleanReadCount`: saved OCR reads that do not need review.
- `ocrReadStatus`: short status label for Command 1 cards.
- `ocrReadSummary`: short operational summary for Command 1 drill-downs.
- `ocrWarningCount`: total OCR warning count.
- `ocrBlockingWarningCount`: count of blocking OCR warnings.
- `ocrPartialWarningCount`: count of partial OCR warnings.
- `ocrReviewWarningCount`: count of review-level OCR warnings.
- `ocrSourceCounts`: safe source-token counts, such as photo or PDF.
- `ocrTopSource`: most common safe OCR source token.
- `ocrPrimaryWarningKindCounts`: safe OCR warning-kind counts.
- `ocrRecoveryActionCounts`: safe recovery action token counts.
- `ocrRecoveryTargetCounts`: safe recovery target token counts.
- `ocrTopCheck`: safe plain-language issue summary for the top warning.
- `ocrTopPrimaryIssue`: safe plain-language primary issue.
- `ocrTopPrimaryAction`: safe plain-language primary action.
- `ocrTopRecoveryAction`: most common safe recovery action token.
- `ocrTopRecoveryTarget`: most common safe recovery target token.

## Forbidden Content

Command 1 must never display or upload these through this contract:

- receipt image bytes or image paths
- raw OCR text
- imported/pasted receipt text
- item descriptions
- merchant/store names
- receipt addresses
- customer names
- phone numbers
- email addresses
- user notes
- local file paths
- proof file names
- transaction/auth/invoice/terminal numbers
- exact private receipt values embedded in text

If Command 1 needs to show a user their own receipt content, it must come from
the user-facing app with that user's permission and normal account access. Admin
health surfaces only get summary health.

## Required Guard Before Use

Before Command 1 displays, uploads, or stores this payload, call:

```dart
ExpenseExportSnapshot.commandCenterOcrContractFindingsFor(contract)
```

The result must be empty. If it is not empty, Command 1 must reject the payload
and record a privacy-safe diagnostic that names the finding type, not the
private value.

The same check is available from an export snapshot:

```dart
snapshot.commandCenterOcrContractPrivacyFindings
```

## Firestore Summary Bridge

The Command 1 OCR contract is uploaded only as an optional nested object inside
the existing expense telemetry summary document:

```text
orgs/{orgId}/expenseTelemetrySummaries/{summaryId}
```

The field name is:

```text
commandCenterOcrContract
```

This keeps OCR health aligned with the cost-safe telemetry shape:

- one pending summary document per org/summary id
- `uploadShape`: `single_summary_document`
- `rawEventUploadCount`: `0`
- no per-receipt Command 1 documents
- no Firestore read per receipt
- no receipt images, raw OCR text, item descriptions, merchant details, notes,
  phone numbers, emails, proof paths, or exact private receipt values

## Firestore Write Budget

Receipt camera, OCR, parser, and expense diagnostics are local-first telemetry.
The app may record many local events while a user scans, retries, edits,
stitches, reviews, saves, syncs, or exports receipts, but those events must not
be uploaded as individual Firestore documents for Command 1.

The default scheduled summary interval is 15 minutes. That is at most 96
scheduled expense telemetry summary writes per org per day before retries or
manual force-queue actions. The working safety target is 20,000 Firestore writes
per day across the project, so receipt diagnostics must stay summarized and
throttled instead of becoming per-capture, per-failure, per-retry, per-line, or
per-receipt writes.
Guard phrase: 96 scheduled expense telemetry summary writes per org per day,
20,000 Firestore writes per day, and no per-capture, per-failure, per-retry, per-line, or per-receipt writes.

`ExpenseTelemetryFirestoreBridge.queueHealthSummary` must use
`enqueueReplacingPendingForPath`, so repeated summary queues for the same
`orgs/{orgId}/expenseTelemetrySummaries/{summaryId}` path replace the pending
draft instead of stacking duplicate writes. A high-volume local telemetry burst
should still queue one bounded Firestore summary with `rawEventUploadCount: 0`.
Guard phrase: replace the pending draft for the same summary path.

Command 1 should read the summary health fields from that one document for
camera/OCR health. It should not need separate read paths for raw receipt
events, receipt images, raw OCR text, parsed line text, or private receipt
diagnostics.

The bridge must call `commandCenterOcrContractFindingsFor` before queueing. If
the findings list is not empty, the upload must fail locally and the app should
record only a privacy-safe diagnostic about the finding category.

The current bridge is:

```dart
ExpenseTelemetryFirestoreBridge.queueHealthSummary(
  orgId: orgId,
  commandCenterOcrContract: snapshot.commandCenterOcrContract,
)
```

The Firestore document builder also accepts the contract directly:

```dart
MaintainiacFirestoreDocumentBuilder.expenseTelemetrySummaryDocument(
  orgId: orgId,
  snapshot: telemetrySnapshot,
  commandCenterOcrContract: snapshot.commandCenterOcrContract,
)
```

The summary builder sanitizes the local Command Center telemetry map before it
is queued for Firestore. Any new top-level field added to
`ExpenseTelemetryHealthSnapshot.toCommandCenterMap()` must either survive into
`expenseTelemetrySummaries/{summaryId}` or be intentionally excluded with a
documented reason. The guard test
`keeps every Command Center telemetry field in Firestore summary` compares the
local telemetry map keys with the final Firestore summary document so OCR,
parser, recovery, sync, export, and scheduler metrics cannot silently disappear
from Command 1.

## Expense Telemetry Summary Fields

Command 1 may read these top-level fields from the same
`expenseTelemetrySummaries/{summaryId}` document for expense receipt health.
These are operational health fields only; they do not include receipt content.

Envelope and context:

- `schema`
- `generatedAtUtc`
- `healthLabel`
- `totalEventCount`
- `pendingUploadCount`
- `uploadedEventCount`
- `eventCounts`
- `platformCounts`
- `deviceTierCounts`
- `storageModeCounts`
- `planStatusCounts`
- `connectionStatusCounts`

Expense screen flow health:

- `screenOpenCount`
- `averageTimeSpentSeconds`
- `addExpenseStartedCount`
- `addExpenseCompletedCount`
- `addExpenseAbandonedCount`
- `addExpenseCompletionRate`
- `addExpenseAbandonmentRate`
- `validationErrorCount`
- `saveFailureCount`

Receipt image, OCR, parser, and app-filled review health:

- `imageAttachSuccessCount`
- `imageAttachFailureCount`
- `imageAttachFailureRate`
- `ocrStartedCount`
- `ocrCompletedCount`
- `ocrFailedCount`
- `ocrSuccessRate`
- `parserStartedCount`
- `parserCompletedCount`
- `parserNeedsReviewCount`
- `parserFailedCount`
- `parserSuccessRate`
- `parserReviewRate`
- `parserFailureRate`
- `ocrCorrectionOpenedCount`
- `appFilledReceiptLineConfirmedCount`
- `appFilledReceiptLineCorrectedCount`
- `appFilledReceiptLineCorrectionRate`
- `userCorrectionCount`

Cloud, sync, scheduler, and export health:

- `cloudBackupSuccessCount`
- `cloudBackupFailureCount`
- `cloudBackupFailureRate`
- `syncPendingCount`
- `syncedCount`
- `syncFailedCount`
- `syncFailureRate`
- `expenseSummaryQueuedCount`
- `expenseSummaryOcrContractQueuedCount`
- `expenseSummaryOcrContractSkippedCount`
- `expenseSummaryOcrContractSourceCounts`
- `topExpenseSummaryOcrContractSource`
- `expenseSummaryOcrContractSkippedReasonCounts`
- `topExpenseSummaryOcrContractSkippedReason`
- `exportStartedCount`
- `exportCompletedCount`
- `exportBlockedCount`
- `exportFailedCount`
- `exportCompletionRate`
- `exportFailureRate`

OCR failure drill-down health:

- `ocrFailureCauseCounts`
- `topOcrFailureCause`
- `ocrFailureSourceCounts`
- `topOcrFailureSource`
- `topOcrFailureSourceAction`
- `ocrFailureStageCounts`
- `topOcrFailureStage`
- `topOcrFailureStageLabel`
- `failureBreakdowns`
- `recentFailureDetails`

These fields are guarded by the expected schema snapshot in
`test/maintainiac_firestore_documents_test.dart`. If one is added, removed, or
renamed, the code, docs, Firestore sanitizer, and Command 1 contract must be
updated together.

## Firestore Metadata Boundary

These Firestore document wrapper fields are not part of
`ExpenseTelemetryHealthSnapshot.toCommandCenterMap()` and must not be added to
`test/helpers/expense_telemetry_schema_expectations.dart`:

- `summaryId`
- `summaryScope`
- `uploadShape`
- `rawEventUploadCount`
- `commandCenterOcrContract`

`MaintainiacFirestoreDocumentBuilder.expenseTelemetrySummaryDocument()` adds
those fields after sanitizing the local telemetry map. This keeps the local
Command Center schema focused on expense health while the Firestore builder owns
upload routing, cost shape, raw-event suppression, and the optional nested OCR
contract.

## Expense Telemetry Schema Change Checklist

When changing any Command 1-visible expense telemetry field, update all of
these pieces in the same pass:

1. `ExpenseTelemetryHealthSnapshot.toCommandCenterMap()` computes the field
   from local, privacy-safe telemetry only.
2. `MaintainiacFirestoreDocumentBuilder.expenseTelemetrySummaryDocument()`
   keeps the field inside the existing
   `orgs/{orgId}/expenseTelemetrySummaries/{summaryId}` document.
3. `_sanitizeExpenseTelemetryMap` explicitly allowlists the field and sanitizes
   the value as a count, rate, safe token, safe token map, or safe failure
   breakdown.
4. `test/helpers/expense_telemetry_schema_expectations.dart` includes the field
   when Command 1 should read it.
5. `keeps every Command Center telemetry field in Firestore summary` proves the
   field survives the final Firestore summary document.
6. `docs/expense_command_center_ocr_contract.md` explains what the field means.
7. `docs/firebase_sync_schema_spec.md` still describes the one-document
   Firestore shape and cost boundary.
8. Doc guard tests continue to require the field and the one-summary-document
   rule.

Do not create a new per-event, per-receipt, per-failure, or separate admin
collection to expose the field to Command 1. If the field cannot fit safely in
the summary document, it needs a separate privacy/cost design pass before it is
added.

## Expense Telemetry Sanitizer Rules

The Firestore summary sanitizer accepts only these value shapes for expense
telemetry:

- `int` counts must be zero or greater.
- `double` rates and averages must be finite and zero or greater; they are
  rounded to four decimal places before upload.
- timestamp strings such as `generatedAtUtc` and `queuedAtUtc` must parse into
  safe ISO timestamps.
- token strings are normalized into safe lowercase token text.
- fields ending in `Label`, plus `recommendedAction` and `actionSummary`, are
  normalized as short readable text, not raw receipt text.
- failure machine-token fields are for grouping, filtering, and action routing;
  they are not user-facing copy.
- visible drill-down text fields are for Command 1 display and must not contain
  raw snake-case diagnostic tokens.
- count maps keep only entries whose values are nonnegative integers; map keys
  are normalized as safe tokens.
- lists such as `failureBreakdowns` and `recentFailureDetails` keep only nested
  maps, and each nested map is sanitized with the same allowlist.

Unsupported scalar values, negative scalar counts, negative rates, `NaN`, and
infinite rates must throw before the Firestore summary is queued. The sanitizer
must not preserve raw receipt text, merchant names, item descriptions, proof
paths, or exact private receipt values as readable admin text.

## Expense Failure Drill-Down Caps

The local telemetry snapshot can keep more failure history than Firestore sends
to Command 1. `expenseTelemetrySummaryDocument()` caps Firestore drill-downs so
the summary remains one bounded document:

- `failureBreakdowns` defaults to 20 entries and is hard-clamped to 50 entries.
- `recentFailureDetails` defaults to 50 entries and is hard-clamped to 100
  entries.
- Callers may pass `0` for either cap to queue an ultra-lean summary without
  drill-down arrays.

Command 1 should treat these arrays as top failure samples and recent failure
samples, not as raw event history. Full local diagnostics stay local unless a
separate privacy/cost design explicitly allows a different upload shape.

## Expense Failure Drill-Down Object Schemas

`failureBreakdowns` is the grouped failure view Command 1 uses when the owner
taps a failure-rate card. Each object must keep this stable, privacy-safe shape:

- `featureArea`
- `featureLabel`
- `workflowStep`
- `workflowStepLabel`
- `failedAt`
- `failedAtLabel`
- `confirmedCause`
- `causeLabel`
- `causeStatus`
- `causeStatusLabel`
- `evidence`
- `evidenceLabel`
- `missingEvidence`
- `missingEvidenceLabel`
- `recommendedAction`
- `actionSummary`
- `ocrFailureSource`
- `ocrFailureSourceAction`
- `count`
- `retryCount`
- `abandonedCount`
- `platformCounts`
- `deviceTierCounts`
- `appVersionCounts`

`recentFailureDetails` is the recent safe sample view Command 1 uses to answer
"what exactly failed?" without exposing receipt content. Each object must keep
this stable shape:

- `eventId`
- `queuedAtUtc`
- `event`
- `featureArea`
- `featureLabel`
- `workflowStep`
- `workflowStepLabel`
- `failedAt`
- `failedAtLabel`
- `confirmedCause`
- `causeLabel`
- `causeStatus`
- `causeStatusLabel`
- `evidence`
- `evidenceLabel`
- `missingEvidence`
- `missingEvidenceLabel`
- `recommendedAction`
- `actionSummary`
- `ocrFailureSource`
- `ocrFailureSourceAction`
- `retryCount`
- `abandoned`
- `platform`
- `deviceTier`
- `appVersion`

Both shapes must include `missingEvidence` as `none` when no evidence is
missing, so Command 1 never has to guess whether the field is absent or healthy.
Both shapes must include `actionSummary`, a short plain-language explanation of
the failed workflow and next safe check. It must be display-ready, bounded, and
must not require Command 1 to read private evidence.
Firestore drift guards must prove `actionSummary` remains readable text after
summary sanitization instead of becoming a lowercase token, and that it still
scrubs store names, exact totals, auth numbers, receipt numbers, and source
tokens. The phrase "source tokens" is intentional here so doc guards can prove
this privacy boundary stays documented.
Both shapes must not carry raw private receipt content. Neither object may
include `payload`, `metadata`, `receiptText`, `rawOcrText`, `merchantName`,
`itemDescription`, `proofPath`, `orgId`, `userId`, or other private receipt
values.
For OCR-step failures, `ocrFailureSource` and `ocrFailureSourceAction` give the
same safe bucket/action context used by the top-level OCR source summary. They
must use only the safe source buckets and bounded action tokens described below.
For non-OCR failures, `ocrFailureSource` must use `not_ocr` so Command 1 does
not send you chasing camera focus, PDF rendering, or OCR source setup when the
failed workflow was parser, save, sync, or another non-OCR step. The `none`
source bucket is reserved for OCR-step failures where OCR started without a
usable photo, PDF, or imported text source.
Regression coverage must stress OCR and non-OCR drill-down rows together with
poisoned source labels, store names, exact totals, auth codes, transaction
numbers, invoice numbers, and barcode-like values.

Failure diagnostic machine-token fields such as `failedAt`, `confirmedCause`,
`evidence`, `missingEvidence`, `topOcrFailureCause`, `topOcrFailureStage`, and
`ocrFailureSourceAction` may remain lowercase token strings for grouping,
filtering, and action routing. They must scrub common private receipt hints
before upload. Known merchant names, common receipt locations, money-like
values, receipt/auth/transaction-length numbers, note/name fragments, and exact
private receipt references should be replaced with safe placeholders such as
`merchant`, `location`, `amount`, `number`, or `private_reference`. Command 1
needs to know the failure category, not the customer's store, location, total,
receipt number, auth code, barcode, phone number, or note text.
The phrases known merchant names, money-like values, and
receipt/auth/transaction-length numbers are intentionally documented in
lowercase too so contract guards keep that private-content boundary visible.

Visible drill-down fields such as `failedAtLabel`, `causeLabel`,
`evidenceLabel`, `missingEvidenceLabel`, `recommendedAction`, and
`actionSummary` are display text. They must remain readable, bounded, and free of raw snake-case diagnostic tokens. If Command 1 needs a button or filter from one of the machine tokens, it should map the token to its own UI copy instead of displaying the token directly.

The redaction guard must cover tokenized fuel, retail, and auto-service
diagnostics such as Shell, Walmart, Home Depot, Jiffy Lube, UPC/barcode-like
numbers, auth codes, terminal numbers, transaction numbers, invoice numbers, and
underscore-separated totals such as `45_67` or `109_23`.
It must also cover regional and contractor-facing receipt names that are likely
to appear in OCR recovery hints, including Pilot/Flying J, Love's, Casey's,
Kwik Trip, Tractor Supply, Harbor Freight, Valvoline, Take 5, and Firestone.

The Firestore redaction boundary lives behind
`_ExpenseTelemetryFirestoreRedactor`. That helper owns which failure token
fields and count-map fields receive private receipt hint redaction. Normal
operational tokens such as `platform`, `deviceTier`, `appVersion`,
`topOcrFailureSource`, and `appVersionCounts` should stay useful and must not be
over-redacted just because failure-specific fields need extra protection.

OCR failure source fields are isolated before Firestore sanitization. Source
evidence may only produce the safe buckets `photo`, `pdf`, `importedtext`,
`mixed`, `none`, or `unknown`. Unrecognized `source_*` labels must become
`unknown` so merchant names, file names, user notes, receipt text, and other
private labels cannot leak through `ocrFailureSourceCounts` or
`topOcrFailureSource`.
Nested drill-down source fields may use the same safe source buckets plus
`not_ocr` for parser, save, sync, and other non-OCR workflow failures.
Every allowed source bucket must also produce a useful
`topOcrFailureSourceAction`: photo points to camera focus, exposure, crop
coverage, long-receipt section order, and image decoding; PDF points to safety,
file size, rendering, page extraction, and PDF-to-image conversion; imported
text points to pasted/imported text cleanup; mixed points to source selection,
section order, duplicate suppression, and stitched-photo fallback; none points
to missing proof; unknown points to safe source tagging without exposing raw
receipt evidence.
The final Firestore summary sanitizer must preserve enough of that action token
for Command 1 to route the owner to the right investigation path while still
keeping the token bounded and free of store names, exact totals, receipt
numbers, file names, and user-entered notes.
Source-action regression coverage must include edge aliases such as
`source_camera`, `source_image`, `source_document`, `source_pasted_text`,
`source_combined`, `source_missing`, malformed private source labels, and
non-OCR drill-down rows so action strings stay useful after Firestore
tokenization.

The current redacted token fields are `failedAt`, `confirmedCause`, `evidence`,
`missingEvidence`, `topOcrFailureCause`, and `topOcrFailureStage`. The current
redacted count-map fields are `ocrFailureCauseCounts`, `ocrFailureStageCounts`,
and `expenseSummaryOcrContractSkippedReasonCounts`. Adding another
Command 1-visible failure token or failure count-map field requires updating the
helper, this contract, and the regression tests in the same pass.

## Scheduled Summary Upload

Routine expense telemetry scheduling uses the same one-document Firestore shape.
`ExpenseTelemetrySummaryScheduler.queueIfDue` builds a rolling local-ledger OCR
contract from saved expense receipts and passes it to the bridge before the
pending upload is queued.

```dart
ExpenseTelemetrySummaryScheduler.queueIfDue(
  orgId: orgId,
  includeLedgerOcrContract: true,
)
```

The scheduled OCR contract uses a rolling 90-day local receipt window by
default. It summarizes OCR recovery status only; it must not upload receipt
images, raw OCR text, merchant names, item descriptions, local proof paths, or
per-receipt diagnostics to Command 1. If a caller needs to queue a basic expense
health summary without OCR health, it can set `includeLedgerOcrContract` to
`false`.

When the scheduler queues a summary document, `ExpenseScreenTelemetryRecorder`
records one local `syncPending` trace so future diagnostics can tell whether OCR
health was attached. That trace is local telemetry only and uses this safe
metadata shape:

- `syncState`: `expense_summary_queued`
- `summaryStatus`: `queued`
- `ocrContractQueued`: boolean
- `ocrContractSource`: `rolling_local_ledger`, `explicit`, or `none`
- `ocrContractSkippedReason`: optional safe token

The recorder trace must not store the Firestore path, org id, receipt image,
raw OCR text, merchant/store names, item descriptions, local proof paths, or
private receipt values. Throttled scheduler checks should not create trace
events because normal expense activity could otherwise generate noisy local
telemetry during the throttle window.

The scheduled trace is also summarized into the same Firestore expense telemetry
summary document. Command 1 should read these aggregate fields from
`orgs/{orgId}/expenseTelemetrySummaries/{summaryId}`:

- `expenseSummaryQueuedCount`
- `expenseSummaryOcrContractQueuedCount`
- `expenseSummaryOcrContractSkippedCount`
- `expenseSummaryOcrContractSourceCounts`
- `topExpenseSummaryOcrContractSource`
- `expenseSummaryOcrContractSkippedReasonCounts`
- `topExpenseSummaryOcrContractSkippedReason`

These are counts and safe tokens only. They must stay in the existing summary
document and must not become a separate scheduler-trace collection, per-receipt
OCR collection, or per-event Command 1 read path.

## Rejected Examples

These are examples of payload changes that must be rejected:

- adding `merchantName`
- adding `receiptImagePath`
- adding `rawOcrText`
- adding `itemDescriptions`
- adding recovery tokens such as `private_store_total_3_24`
- adding OCR source keys that look like local paths
- adding top issue/action text that contains store names or exact private
  receipt totals

## Command 1 UI Guidance

Use these fields for health cards and drill-downs:

- Card title: Expense OCR Health
- Main number: `ocrReadStatus`
- Secondary line: `ocrReadSummary`
- Drill-down buckets: warning counts, source counts, recovery action counts,
  and recovery target counts

The UI should explain what failed in plain language using safe categories. It
must not guess the cause. If the contract only says review is needed, Command 1
should say review is needed and show the safe top check, not invent a cause.

## Update Checklist

When this contract changes:

1. Update `ExpenseExportSnapshot.commandCenterOcrAllowedKeys`.
2. Update `commandCenterOcrContract`.
3. Update `commandCenterOcrContractFindingsFor` if a new value shape is needed.
4. Update this document.
5. Add or update regression tests that prove private receipt content cannot
   enter the contract.
6. Run focused export/OCR tests and `git diff --check`.
