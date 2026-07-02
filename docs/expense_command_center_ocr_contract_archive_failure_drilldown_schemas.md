# Expense Command Center OCR Contract Archive - Failure Drilldown Schemas

Archived from `docs/expense_command_center_ocr_contract_archive_telemetry_summary_fields.md` to keep each reference file under 500 lines.

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
`expenseSummaryOcrContractSkippedReasonCounts`, `parserCategoryCounts`,
`parserNeedsReviewCategoryCounts`, `parserFailedCategoryCounts`,
`parserFieldConfidenceCounts`, `parserCategoryHealthCounts`,
`parserCategoryReviewActionCounts`, `parserPackPressureStatusCounts`,
`receiptBrainParserLimitOutcomeCounts`,
`receiptBrainLowStorageDownloadRiskCounts`,
`receiptBrainFullOfflineMustStayOptionalCounts`,
`receiptBrainFullOfflineExceedsBaseGuardrailCounts`,
`receiptBrainBaseLocalReadingAvailableCounts`,
`receiptBrainBaseWorksWithoutCloudAssistCounts`,
`receiptBrainLocalFirstReadinessCounts`,
`receiptBrainLocalFirstReadinessActionCounts`,
`receiptBrainLocalFirstReadinessSummaryCounts`,
`receiptBrainFirstInstallBoundaryCounts`,
`receiptBrainFirstInstallBoundaryActionCounts`,
`receiptBrainFirstInstallCanRunLowStorageCounts`,
`receiptBrainFirstInstallRequiresBaseCapabilityCounts`,
`receiptBrainFirstInstallBoundarySummaryCounts`,
`receiptInstallRequiredSegmentCounts`,
`receiptInstallFullOfflineSegmentCounts`,
`receiptInstallLowStorageImpactCounts`,
`receiptInstallRecommendedDistributionCounts`,
`receiptInstallCameraShellParserFreeCounts`,
`receiptInstallBaseUsefulOnTinyPhonesCounts`,
`receiptInstallOptionalPacksRequireConsentCounts`,
`receiptLocalOnlyAcceptanceStatusCounts`,
`receiptLocalOnlyAcceptanceActionCounts`,
`receiptLocalOnlyBaseFlowCanRunCounts`,
`receiptLocalOnlyBlocksLowStorageCounts`,
`receiptLocalOnlyEvidenceCounts`, `nativeLocalOnlyCapturePolicyCounts`,
`nativeLocalOnlyBaseFlowCanRunCounts`,
`nativeLocalOnlyHeavyPacksMayBlockCaptureCounts`,
`nativeLocalOnlyCloudAssistMayBlockCaptureCounts`,
`receiptRequiredBaseFootprintStatusCounts`,
`receiptRequiredBaseFootprintCanShipCounts`,
`receiptRequiredBaseFootprintReviewCounts`,
`receiptRequiredBaseFootprintBlockingReasonCounts`,
`receiptRequiredBaseFootprintReviewReasonCounts`, `ocrStoragePolicyCounts`,
`ocrUsesPreparedSourceBeforeSavedProofCounts`,
`ocrUsesSavedProofFallbackCounts`, `parserRequiredFieldStatusCounts`,
`parserDownstreamReadinessStatusCounts`, `parserDownstreamReadinessCounts`,
`parserReviewRootCauseCounts`, `localReceiptParserRoutingCounts`,
`localParserEvidenceOutcomeCounts`, `ocrParserTaskCounts`,
`ocrFieldReadinessCounts`, `ocrSourceHandoffStatusCounts`,
`ocrSourceHandoffSignalCounts`, `ocrSourceStitchSignalCounts`,
`ocrSourceScannerDecisionCounts`, `ocrSourceCaptureSourceSignalCounts`,
`ocrSourcePhotoQualityRiskCounts`, `ocrSourceQualityReviewStatusCounts`,
`ocrSourceQualityReviewActionCounts`, `savedPhotoWarningCounts`,
`savedPhotoWarningCauseCounts`, `savedPhotoWarningSeverityCounts`,
`savedPhotoWarningActionCounts`, `savedPhotoParserRiskCounts`,
`preCaptureExposureDecisionBuckets`, `preCaptureExposureDecisionCounts`,
`autoExposureDecisionBuckets`, `autoExposureDecisionCounts`,
`autoExposureBrightnessBuckets`, `autoExposureBrightnessCounts`,
`autoExposureCandidateBuckets`, `autoExposureCandidateCounts`,
`exposureAssistStatuses`, `exposureAssistStatusCounts`,
`acceptedPhotoQualityOutcomeCounts`, `capturedPhotoBrightnessCounts`,
`capturedPhotoSharpnessCounts`, `capturedPhotoExposureMismatchCounts`,
`capturedPhotoQualitySignalCounts`, `capturedPhotoBottomBrightnessCounts`,
`capturedPhotoBottomEdgeScoreCounts`,
`capturedPhotoVerticalQualitySignalCounts`, `nativeCameraEngineCounts`,
`nativeReceiptCameraSurfaceActualCounts`,
`nativeReceiptCameraSurfaceVerificationCounts`, `nativeCameraIdentityCounts`,
`nativeSettingsContractVersionCounts`, `nativeControlContractVersionCounts`,
`nativePreCaptureExposureAbortReasonCounts`, `nativeZoomStatusCounts`,
`nativeBackDispatchPathCounts`, `receiptCloudAssistPlanCounts`,
`receiptLocalOcrModeCounts`, `receiptParserDepthCounts`,
`nativeDevicePolicyCounts`, `nativeCameraWorkloadTierCounts`,
`nativeCameraResolutionTierCounts`, `nativeRecoveryResumeStatusCounts`,
`nativeRecoveryFreshnessCounts`, `nativeRecoveryStorageStatusCounts`,
`capabilityPolicyCodeCounts`, `stitchStatusCounts`,
`stitchFallbackReasonCounts`, `stitchConfidenceBucketCounts`, and
`stitchPairDiagnosticCounts`. Adding another Command 1-visible failure token or
failure count-map field requires updating the helper, this contract, the
Firestore sync schema spec, and the regression tests in the same pass.

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
