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

- private object keys including `payload`, `metadata`, `receiptText`,
  `rawOcrText`, `merchantName`, `itemDescription`, `proofPath`, `orgId`,
  and `userId`
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

## Firestore Failure Redaction Boundary

`_ExpenseTelemetryFirestoreRedactor` owns private receipt hint scrubbing for
failure token fields, failure count-map fields, and readable drill-down fields
such as `actionSummary`.

OCR failure source buckets for summary fields are: `photo`, `pdf`, `importedtext`, `mixed`, `none`, `unknown`.
Nested drill-down rows may also use `not_ocr` for parser, save, sync, export,
and other non-OCR failures.

Redacted token fields: `failedAt`, `confirmedCause`, `evidence`, `missingEvidence`, `topOcrFailureCause`, `topOcrFailureStage`.

Redacted count-map fields: `ocrFailureCauseCounts`, `ocrFailureStageCounts`, `expenseSummaryOcrContractSkippedReasonCounts`, `parserCategoryCounts`, `parserNeedsReviewCategoryCounts`, `parserFailedCategoryCounts`, `parserFieldConfidenceCounts`, `parserCategoryHealthCounts`, `parserCategoryReviewActionCounts`, `parserPackPressureStatusCounts`, `receiptBrainParserLimitOutcomeCounts`, `receiptBrainLowStorageDownloadRiskCounts`, `receiptBrainFullOfflineMustStayOptionalCounts`, `receiptBrainFullOfflineExceedsBaseGuardrailCounts`, `receiptBrainBaseLocalReadingAvailableCounts`, `receiptBrainBaseWorksWithoutCloudAssistCounts`, `receiptBrainLocalFirstReadinessCounts`, `receiptBrainLocalFirstReadinessActionCounts`, `receiptBrainLocalFirstReadinessSummaryCounts`, `receiptBrainFirstInstallBoundaryCounts`, `receiptBrainFirstInstallBoundaryActionCounts`, `receiptBrainFirstInstallCanRunLowStorageCounts`, `receiptBrainFirstInstallRequiresBaseCapabilityCounts`, `receiptBrainFirstInstallBoundarySummaryCounts`, `receiptInstallRequiredSegmentCounts`, `receiptInstallFullOfflineSegmentCounts`, `receiptInstallLowStorageImpactCounts`, `receiptInstallRecommendedDistributionCounts`, `receiptInstallCameraShellParserFreeCounts`, `receiptInstallBaseUsefulOnTinyPhonesCounts`, `receiptInstallOptionalPacksRequireConsentCounts`, `receiptLocalOnlyAcceptanceStatusCounts`, `receiptLocalOnlyAcceptanceActionCounts`, `receiptLocalOnlyBaseFlowCanRunCounts`, `receiptLocalOnlyBlocksLowStorageCounts`, `receiptLocalOnlyEvidenceCounts`, `nativeLocalOnlyCapturePolicyCounts`, `nativeLocalOnlyBaseFlowCanRunCounts`, `nativeLocalOnlyHeavyPacksMayBlockCaptureCounts`, `nativeLocalOnlyCloudAssistMayBlockCaptureCounts`, `receiptRequiredBaseFootprintStatusCounts`, `receiptRequiredBaseFootprintCanShipCounts`, `receiptRequiredBaseFootprintReviewCounts`, `receiptRequiredBaseFootprintBlockingReasonCounts`, `receiptRequiredBaseFootprintReviewReasonCounts`, `ocrStoragePolicyCounts`, `ocrUsesPreparedSourceBeforeSavedProofCounts`, `ocrUsesSavedProofFallbackCounts`, `parserRequiredFieldStatusCounts`, `parserDownstreamReadinessStatusCounts`, `parserDownstreamReadinessCounts`, `parserReviewRootCauseCounts`, `localReceiptParserRoutingCounts`, `localParserEvidenceOutcomeCounts`, `ocrParserTaskCounts`, `ocrFieldReadinessCounts`, `ocrSourceHandoffStatusCounts`, `ocrSourceHandoffSignalCounts`, `ocrSourceStitchSignalCounts`, `ocrSourceScannerDecisionCounts`, `ocrSourceCaptureSourceSignalCounts`, `ocrSourcePhotoQualityRiskCounts`, `ocrSourceQualityReviewStatusCounts`, `ocrSourceQualityReviewActionCounts`, `savedPhotoWarningCounts`, `savedPhotoWarningCauseCounts`, `savedPhotoWarningSeverityCounts`, `savedPhotoWarningActionCounts`, `savedPhotoParserRiskCounts`, `preCaptureExposureDecisionBuckets`, `preCaptureExposureDecisionCounts`, `autoExposureDecisionBuckets`, `autoExposureDecisionCounts`, `autoExposureBrightnessBuckets`, `autoExposureBrightnessCounts`, `autoExposureCandidateBuckets`, `autoExposureCandidateCounts`, `exposureAssistStatuses`, `exposureAssistStatusCounts`, `acceptedPhotoQualityOutcomeCounts`, `capturedPhotoBrightnessCounts`, `capturedPhotoSharpnessCounts`, `capturedPhotoExposureMismatchCounts`, `capturedPhotoQualitySignalCounts`, `capturedPhotoBottomBrightnessCounts`, `capturedPhotoBottomEdgeScoreCounts`, `capturedPhotoVerticalQualitySignalCounts`, `nativeCameraEngineCounts`, `nativeReceiptCameraSurfaceActualCounts`, `nativeReceiptCameraSurfaceVerificationCounts`, `nativeCameraIdentityCounts`, `nativeSettingsContractVersionCounts`, `nativeControlContractVersionCounts`, `nativePreCaptureExposureAbortReasonCounts`, `nativeZoomStatusCounts`, `nativeBackDispatchPathCounts`, `receiptCloudAssistPlanCounts`, `receiptLocalOcrModeCounts`, `receiptParserDepthCounts`, `nativeDevicePolicyCounts`, `nativeCameraWorkloadTierCounts`, `nativeCameraResolutionTierCounts`, `nativeRecoveryResumeStatusCounts`, `nativeRecoveryFreshnessCounts`, `nativeRecoveryStorageStatusCounts`, `capabilityPolicyCodeCounts`, `stitchStatusCounts`, `stitchFallbackReasonCounts`, `stitchConfidenceBucketCounts`, `stitchPairDiagnosticCounts`.

Operational fields such as `platform`, `deviceTier`, `appVersion`,
`topOcrFailureSource`, and `appVersionCounts` are not part of the redacted
field sets.

## Expense Telemetry Summary Fields

Detailed telemetry summary fields, schemas, drill-down caps, scheduled upload notes, examples, UI guidance, and checklist were archived to keep the active contract under the 500-line file limit.

- Archive: `docs/expense_command_center_ocr_contract_archive_telemetry_summary_fields.md`.
- Active nested failure drill-down keys remain part of this contract:
  `featureArea`, `featureLabel`, `workflowStep`, `workflowStepLabel`,
  `failedAt`, `failedAtLabel`, `confirmedCause`, `causeLabel`, `causeStatus`,
  `causeStatusLabel`, `evidence`, `evidenceLabel`, `missingEvidence`,
  `missingEvidenceLabel`, `recommendedAction`, `actionSummary`,
  `ocrFailureSource`, `ocrFailureSourceAction`, `count`, `retryCount`,
  `abandonedCount`, `platformCounts`, `deviceTierCounts`, `appVersionCounts`,
  `eventId`, `queuedAtUtc`, `event`, `abandoned`, `platform`, `deviceTier`,
  and `appVersion`.
