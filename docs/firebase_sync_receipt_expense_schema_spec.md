# Firebase Receipt Expense And OCR Sync Schema Spec

This document extends `firebase_sync_schema_spec.md` with receipt, proof, expense, and OCR Command Center telemetry sync contracts.

## Receipt Records

```text
orgs/{orgId}/receipts/{receiptId}
```

Fields:

- `source`: `manualWithReceipt`, `manualWithoutReceipt`, `photoAssist`, `pdfImport`
- `merchantName`
- `receiptDate`
- `businessUse`
- `destinationMode`
- `proofStoragePaths`
- `subtotal`
- `taxTotal`
- `total`
- `createdAt`
- `updatedAt`
- `createdByUid`
- `deviceId`

```text
orgs/{orgId}/receipts/{receiptId}/lines/{lineId}
```

Fields:

- `lineNumber`
- `rawReceiptText`
- `displayName`
- `kind`: `inventory`, `expense`, `personal`, `ignored`
- `itemId`
- `canonicalKey`
- `expenseCategoryId`
- `quantity`
- `unitsPerPackage`
- `purchaseType`
- `unit`
- `subtotal`
- `taxRate`
- `confidence`
- `confidenceLevel`: `good`, `okay`, `poor`
- `reviewStatus`: `confirmed`, `needsReview`
- `businessUse`
- `businessPercent`
- `locationId`
- `storageDetail`
- `vehicleId`
- `jobId`
- `invoiceProofMode`
- `proofCrop`
- `createdAt`
- `updatedAt`

## Receipt Proof Storage

Cloud Storage paths:

```text
orgs/{orgId}/receipts/{receiptId}/proofs/source/{proofId}.jpg
orgs/{orgId}/receipts/{receiptId}/proofs/optimized/{proofId}.jpg
orgs/{orgId}/receipts/{receiptId}/proofs/pdf/{proofId}.pdf
```

Rules:

- Upload only if the user enables hosted backup/sync.
- Local-only users keep proof locally/export manually.
- Optimized versions may sync without source originals if user settings choose space saving.
- Proof files must never be deleted silently.

## Expenses, Jobs, And Invoices

These modules need their own full specs later, but inventory/receipt schema must already leave hooks:

- `expenseCategoryId`
- `jobId`
- `invoiceId`
- `invoiceLineId`
- `receiptLineId`
- `vehicleId`
- `businessUse`
- `businessPercent`

Invoices should reference receipt line ids, not only whole receipt ids, so customer proof can show only relevant lines.

Expense receipt backups use one Firestore document per receipt:

```text
orgs/{orgId}/expenses/{expenseId}
```

The expense document embeds bounded receipt lines and stores money values in
cents. It can include the user's private merchant, receipt number, notes,
categories, and line descriptions because this is the user's own backed-up
record behind org membership rules. It must not include raw OCR text, imported
receipt text, local device file paths, proof image bytes, PDF bytes, VINs,
license plates, passenger data, or patient data. Receipt proof files use Cloud
Storage and Firestore keeps only proof pointers, hashes, sizes, and storage
state.

Expense recap settings use one member-scoped settings document:

```text
orgs/{orgId}/settings/expenses_{uid}
```

Default recap behavior is show every tile. User-hidden recap tiles are stored
as `hiddenRecapTiles` so a restored device can reproduce the user's recap
layout without reading multiple settings documents.

Expense OCR health for Command 1 is not a per-receipt admin collection. When
available, the privacy-safe OCR contract is embedded as
`commandCenterOcrContract` in the existing summary document:

```text
orgs/{orgId}/expenseTelemetrySummaries/{summaryId}
```

The summary document keeps `uploadShape` set to `single_summary_document` and
`rawEventUploadCount` set to `0`. The OCR contract must pass
`ExpenseExportSnapshot.commandCenterOcrContractFindingsFor` before queueing.
If that audit reports any findings, the app must reject the summary upload
instead of sending private receipt content to Command 1.

Receipt camera, OCR, parser, and expense diagnostics are local-first telemetry.
Local Hive can keep detailed events for debugging, but Command 1 Firestore
health must use summarized documents. The default 15-minute scheduler interval
allows at most 96 scheduled expense telemetry summary writes per org per day
before retries or manual force-queue actions. The working safety target is
20,000 Firestore writes per day across the project, so receipt diagnostics must
not become per-capture, per-failure, per-retry, per-line, or per-receipt writes.
`ExpenseTelemetryFirestoreBridge.queueHealthSummary` must replace the pending
draft for the same summary path instead of stacking duplicate writes. High-volume
local camera/OCR telemetry bursts must still queue one bounded Firestore summary
with `rawEventUploadCount: 0`.
Guard phrase: 96 scheduled expense telemetry summary writes per org per day,
20,000 Firestore writes per day, and no per-capture, per-failure, per-retry, per-line, or per-receipt writes.

The expense telemetry summary builder sanitizes the local Command Center
health map before Firestore queueing. Any new top-level field added to
`ExpenseTelemetryHealthSnapshot.toCommandCenterMap()` must be reviewed against
the Firestore summary sanitizer. If Command 1 needs that field, it must remain
in `orgs/{orgId}/expenseTelemetrySummaries/{summaryId}` and must be covered by
the parity regression named `keeps every Command Center telemetry field in Firestore summary`.
Fields must not be moved into per-event, per-receipt, or
separate admin collections just to make them visible.

Telemetry schema changes must follow the expense telemetry schema change checklist
in `docs/expense_command_center_ocr_contract.md`: compute locally,
allowlist and sanitize in `_sanitizeExpenseTelemetryMap`, keep the field in
`expenseTelemetrySummaries/{summaryId}`, update
`test/helpers/expense_telemetry_schema_expectations.dart`, update docs, and
keep the parity and doc guard tests passing.

Firestore wrapper metadata such as `summaryId`, `summaryScope`, `uploadShape`,
`rawEventUploadCount`, and `commandCenterOcrContract` is added by the Firestore
document builder, not by `ExpenseTelemetryHealthSnapshot.toCommandCenterMap()`.
Those metadata keys must stay out of the local Command Center telemetry schema
helper.

The summary sanitizer accepts only nonnegative counts, finite nonnegative
rates, safe tokens, short readable labels, nonnegative count maps, and sanitized
nested failure maps. It must reject negative scalar counts, negative rates,
`NaN`, infinite rates, and unsupported scalar values before queueing the
Firestore summary.

Failure drill-down arrays are bounded inside the same summary document:
`failureBreakdowns` defaults to 20 entries with a hard cap of 50, and
`recentFailureDetails` defaults to 50 entries with a hard cap of 100. These
arrays are samples for Command 1, not raw event history. Nested failure objects
must follow the documented `Expense Failure Drill-Down Object Schemas`, including
`missingEvidence` as `none` when nothing is missing. Nested failure objects must
include `actionSummary` as a bounded plain-language explanation of the failed
workflow and next safe check without requiring Command 1 to read private
evidence. Firestore drift guards must prove `actionSummary` stays readable after
summary sanitization instead of becoming a lowercase token, while still
scrubbing store names, exact totals, auth numbers, receipt numbers, and source
tokens. The phrase "source tokens" is intentional here so doc guards can prove
this privacy boundary stays documented. Nested failure objects must not carry raw private receipt content,
including `payload`, `metadata`,
`receiptText`, `rawOcrText`, `merchantName`, `itemDescription`, `proofPath`,
`orgId`, `userId`, or other private receipt values.
Nested OCR failure objects include `ocrFailureSource` and
`ocrFailureSourceAction` so Command 1 drill-downs can show the safe source
bucket and repair path without rereading raw evidence. Non-OCR failures must use
`ocrFailureSource` as `not_ocr` so parser/save/sync drill-down rows do not look
like camera, PDF, or OCR-source problems. The `none` bucket is reserved for
OCR-step failures that started without a usable photo, PDF, or imported text
source.
Firestore regression coverage must stress OCR and non-OCR drill-down rows
together with poisoned source labels, store names, exact totals, auth codes,
transaction numbers, invoice numbers, and barcode-like values.
Failure diagnostic machine-token fields must also scrub common private receipt
hints before the summary is queued for Command 1. Known merchant names become `merchant`,
common receipt locations become `location`, money-like values become `amount`,
receipt/auth/transaction-length numbers can become `number`, and
note/name/receipt-number style references can become `private_reference`.
Machine-token fields such as `failedAt`, `confirmedCause`, `evidence`,
`missingEvidence`, `topOcrFailureCause`, `topOcrFailureStage`, and
`ocrFailureSourceAction` are for grouping, filtering, and action routing; they
are not display copy.
Visible drill-down fields such as `failedAtLabel`, `causeLabel`,
`evidenceLabel`, `missingEvidenceLabel`, `recommendedAction`, and
`actionSummary` must stay readable, bounded, and free of raw snake-case tokens.
In Command 1 wording, this means free of raw snake-case diagnostic tokens.
Command 1 should map machine tokens to UI copy instead of showing them directly.
The Firestore guard must include fuel, retail, and auto-service stress examples
such as Shell, Walmart, Home Depot, Jiffy Lube, UPC/barcode-like numbers, auth
codes, terminal numbers, transaction numbers, invoice numbers, and
underscore-separated totals such as `45_67` or `109_23`.
It also guards regional fuel, truck stop, contractor retail, and auto-service
examples such as Pilot/Flying J, Love's, Casey's, Kwik Trip, Tractor Supply,
Harbor Freight, Valvoline, Take 5, and Firestone.
The helper boundary is `_ExpenseTelemetryFirestoreRedactor`; it owns redaction
for failure token fields and failure count-map fields while preserving normal
operational tokens such as `platform`, `deviceTier`, `appVersion`,
`topOcrFailureSource`, and `appVersionCounts`.
OCR failure source fields are source-isolated before Firestore upload:
`ocrFailureSourceCounts` and `topOcrFailureSource` may only contain `photo`,
`pdf`, `importedtext`, `mixed`, `none`, or `unknown`. Unknown `source_*` labels
must stay `unknown`, not merchant names, file names, user notes, receipt text, or
private evidence labels.
Nested drill-down source fields may contain those same safe buckets plus
`not_ocr` for parser, save, sync, and other non-OCR workflow failures.
Each allowed source bucket must have a matching `topOcrFailureSourceAction`
that tells Command 1 what to inspect next: camera focus/exposure/crop/order for
photo, safety/size/render/page extraction for PDF, imported text cleanup for
`importedtext`, source selection/order/duplicate suppression for `mixed`,
missing proof for `none`, and safe source tagging for `unknown`.
The final Firestore sanitizer must keep those source-action tokens bounded and
actionable without preserving store names, exact totals, receipt numbers, file
names, or user-entered notes.
Source-action regression coverage must include edge aliases such as
`source_camera`, `source_image`, `source_document`, `source_pasted_text`,
`source_combined`, `source_missing`, malformed private source labels, and
non-OCR drill-down rows so action strings stay useful after Firestore
tokenization.
The redacted token fields are `failedAt`, `confirmedCause`, `evidence`,
`missingEvidence`, `topOcrFailureCause`, and `topOcrFailureStage`. The redacted
count-map fields are `ocrFailureCauseCounts`, `ocrFailureStageCounts`,
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
`stitchPairDiagnosticCounts`.

Scheduled expense telemetry uploads use
`ExpenseTelemetrySummaryScheduler.queueIfDue` to build the same
`commandCenterOcrContract` from a rolling local-ledger receipt window before
queueing the summary document. The scheduler must keep
`includeLedgerOcrContract` available so a non-OCR health summary can be queued
without attaching receipt OCR health.

When a summary is queued, `ExpenseScreenTelemetryRecorder` may add one local
`syncPending` trace with `syncState: expense_summary_queued`,
`summaryStatus`, `ocrContractQueued`, `ocrContractSource`, and optional
`ocrContractSkippedReason`. That trace must not contain the Firestore path,
org id, receipt images, raw OCR text, merchant names, item descriptions, or
private receipt values. Throttled scheduler checks must not create trace
events.

The Firestore summary document also includes aggregate scheduled OCR trace
metrics: `expenseSummaryQueuedCount`,
`expenseSummaryOcrContractQueuedCount`,
`expenseSummaryOcrContractSkippedCount`,
`expenseSummaryOcrContractSourceCounts`,
`topExpenseSummaryOcrContractSource`,
`expenseSummaryOcrContractSkippedReasonCounts`, and
`topExpenseSummaryOcrContractSkippedReason`. These fields are safe counts and
tokens only. They must remain in
`orgs/{orgId}/expenseTelemetrySummaries/{summaryId}`. These metrics must not create a separate scheduler trace collection. They also must not create a per-event Command 1 read path.
