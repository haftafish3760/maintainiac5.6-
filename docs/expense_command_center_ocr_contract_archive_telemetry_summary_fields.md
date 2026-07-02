# Expense Command Center OCR Contract Archive - Telemetry Summary Fields

Archived from `docs/expense_command_center_ocr_contract.md`.

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
- `parserCategoryCounts`
- `parserNeedsReviewCategoryCounts`
- `parserFailedCategoryCounts`
- `parserFieldConfidenceCounts`
- `parserCategoryHealthCounts`
- `parserRequiredFieldStatusCounts`
- `parserDownstreamReadinessStatusCounts`
- `parserDownstreamReadinessCounts`
- `ocrParserTaskCounts`
- `ocrFieldReadinessCounts`
- `ocrSourceHandoffStatusCounts`
- `ocrSourceHandoffSignalCounts`
- `ocrSourceStitchSignalCounts`
- `ocrSourceScannerDecisionCounts`
- `ocrSourcePhotoQualityRiskCounts`
- `clientProofRedactionStatusCounts`
- `clientProofVisibilityCounts`
- `receiptSelectedLinePurposeCounts`
- `receiptSelectedLineCountTotal`
- `receiptExcludedLineCountTotal`
- `receiptClientProofReviewLineCountTotal`
- `receiptRedactedLineCountTotal`
- `clientProofRedactionPlanStatusCounts`
- `clientProofVisibleLineCountTotal`
- `clientProofHiddenLineCountTotal`
- `clientProofPlanReviewLineCountTotal`
- `topParserCategory`
- `topParserNeedsReviewCategory`
- `topParserFailedCategory`
- `topParserCategoryHealth`
- `topParserRequiredFieldStatus`
- `topParserDownstreamReadinessStatus`
- `topParserDownstreamReadiness`
- `topOcrParserTask`
- `topOcrFieldReadiness`
- `topOcrSourceHandoffStatus`
- `topOcrSourceHandoffSignal`
- `topOcrSourceStitchSignal`
- `topOcrSourceScannerDecision`
- `topOcrSourcePhotoQualityRisk`
- `topClientProofRedactionStatus`
- `topClientProofVisibility`
- `topReceiptSelectedLinePurpose`
- `topClientProofRedactionPlanStatus`
- `receiptPhotoCoverageStatusCounts`
- `receiptPhotoCoverageReasonCounts`
- `receiptPhotoCoverageNeedsMoreCount`
- `receiptPhotoCoverageNeedsMoreRate`
- `topReceiptPhotoCoverageStatus`
- `topReceiptPhotoCoverageReason`
- `savedPhotoWarningCounts`
- `savedPhotoWarningSeverityCounts`
- `savedPhotoWarningActionCounts`
- `savedPhotoParserRiskCounts`
- `savedPhotoQualityWarningCount`
- `savedPhotoQualityWarningRate`
- `savedPhotoCriticalWarningCount`
- `savedPhotoCriticalWarningRate`
- `topSavedPhotoWarningCause`

Additional safe top-level drill-down fields exposed by the expense telemetry
summary document:

- `nativePreCaptureExposureAbortCount`
- `nativeZoomGestureStartCount`
- `nativeZoomChangeCount`
- `nativeZoomUnavailableCount`
- `topNativeReceiptCameraSurfaceActual`
- `topNativeReceiptCameraSurfaceVerification`
- `topNativeCameraIdentity`
- `topNativePreCaptureExposureAbortReason`
- `topNativeZoomStatus`
- `topNativeBackDispatchPath`
- `nativeCaptureSourcePolicyCounts`
- `topNativeCaptureSourcePolicy`
- `topOcrStoragePolicy`
- `topOcrUsesPreparedSourceBeforeSavedProof`
- `topOcrUsesSavedProofFallback`
- `topReceiptBrainLocalFirstReadiness`
- `topReceiptBrainLocalFirstReadinessAction`
- `topReceiptBrainFirstInstallBoundary`
- `topReceiptBrainFirstInstallBoundaryAction`
- `topReceiptInstallRecommendedDistribution`
- `topReceiptInstallLowStorageImpact`
- `topReceiptLocalOnlyAcceptanceStatus`
- `topReceiptLocalOnlyAcceptanceAction`
- `topNativeLocalOnlyCapturePolicy`
- `localReceiptParserKeptLocalCount`
- `localReceiptParserOptionalPackOfferCount`
- `topParserCategoryReviewAction`
- `topParserPackPressureStatus`
- `topReceiptBrainParserLimitOutcome`
- `topReceiptBrainLowStorageDownloadRisk`
- `topReceiptRequiredBaseFootprintStatus`
- `topReceiptRequiredBaseFootprintBlockingReason`
- `topReceiptRequiredBaseFootprintReviewReason`
- `topParserReviewRootCause`
- `topLocalReceiptParserRouting`
- `topLocalParserEvidenceOutcome`
- `topOcrSourceCaptureSourceSignal`
- `topOcrSourceQualityReviewStatus`
- `topOcrSourceQualityReviewAction`
- `topSavedPhotoWarning`
- `topSavedPhotoWarningSeverity`
- `topSavedPhotoWarningActionCode`
- `topSavedPhotoWarningAction`
- `topSavedPhotoParserRisk`
- `preCaptureExposureDecisionCounts`
- `preCaptureExposureDecisionBuckets`
- `preCaptureExposureAdjustmentCount`
- `preCaptureExposureAdjustmentRate`
- `topPreCaptureExposureDecision`
- `autoExposureDecisionCounts`
- `autoExposureDecisionBuckets`
- `autoExposureBrightnessCounts`
- `autoExposureBrightnessBuckets`
- `autoExposureCandidateCounts`
- `autoExposureCandidateBuckets`
- `exposureAssistStatusCounts`
- `exposureAssistStatuses`
- `autoExposureCandidateFrameCount`
- `manualBrightnessChangeCount`
- `topAutoExposureDecision`
- `topAutoExposureBrightness`
- `topAutoExposureCandidate`
- `topExposureAssistStatus`
- `acceptedPhotoQualityOutcomeCounts`
- `topAcceptedPhotoQualityOutcome`
- `capturedPhotoBrightnessCounts`
- `capturedPhotoSharpnessCounts`
- `capturedPhotoExposureMismatchCounts`
- `capturedPhotoQualitySignalCounts`
- `capturedPhotoBottomBrightnessCounts`
- `capturedPhotoBottomEdgeScoreCounts`
- `capturedPhotoVerticalQualitySignalCounts`
- `topCapturedPhotoBrightness`
- `topCapturedPhotoSharpness`
- `topCapturedPhotoExposureMismatch`
- `topCapturedPhotoQualitySignal`
- `topCapturedPhotoBottomBrightness`
- `topCapturedPhotoBottomEdgeScore`
- `topCapturedPhotoVerticalQualitySignal`
- `nativeCameraEngineCounts`
- `nativeSettingsContractVersionCounts`
- `nativeControlContractVersionCounts`
- `receiptCloudAssistPlanCounts`
- `receiptLocalOcrModeCounts`
- `receiptParserDepthCounts`
- `receiptParserPackCodeCounts`
- `receiptOptionalLocalParserPackCodeCounts`
- `receiptCloudFallbackParserPackCodeCounts`
- `receiptParserPackAccuracyBandCounts`
- `receiptEstimatedOptionalLocalPackBytesTotal`
- `receiptEstimatedOptionalLocalPackBytesMax`
- `receiptCloudOcrOptionalCount`
- `receiptCloudInventoryOptionalCount`
- `topReceiptParserPackDisclosureLabel`
- `nativeDevicePolicyCounts`
- `nativeCameraWorkloadTierCounts`
- `nativeCameraResolutionTierCounts`
- `nativeRecoveryResumeStatusCounts`
- `nativeRecoveryFreshnessCounts`
- `nativeRecoveryStorageStatusCounts`
- `nativeRecoveryRecoveredPhotoCount`
- `nativeRecoveryMultipleSectionCount`
- `nativeTapFocusControlExpectedCount`
- `nativePinchZoomControlExpectedCount`
- `nativeExposureSliderControlExpectedCount`
- `nativeExposureResetControlExpectedCount`
- `nativeSettingsControlExpectedCount`
- `nativeBackControlExpectedCount`
- `nativeTorchControlExpectedCount`
- `nativeSettingsOpenCount`
- `topNativeCameraEngine`
- `topNativeSettingsContractVersion`
- `topNativeControlContractVersion`
- `topReceiptCloudAssistPlan`
- `topReceiptLocalOcrMode`
- `topReceiptParserDepth`
- `topReceiptParserPackCode`
- `topReceiptOptionalLocalParserPackCode`
- `topReceiptCloudFallbackParserPackCode`
- `topReceiptParserPackAccuracyBand`
- `topNativeDevicePolicy`
- `topNativeCameraWorkloadTier`
- `topNativeCameraResolutionTier`
- `topNativeRecoveryResumeStatus`
- `topNativeRecoveryFreshness`
- `topNativeRecoveryStorageStatus`
- `topNativeRecoveryAction`
- `capabilityPolicyCodeCounts`
- `topCapabilityPolicyCode`
- `stitchStatusCounts`
- `stitchFallbackReasonCounts`
- `stitchConfidenceBucketCounts`
- `stitchPairDiagnosticCounts`
- `topStitchStatus`
- `topStitchFallbackReason`
- `topStitchConfidenceBucket`
- `topStitchPairDiagnostic`
- `ocrCorrectionOpenedCount`
- `appFilledReceiptLineConfirmedCount`
- `appFilledReceiptLineCorrectedCount`
- `appFilledReceiptLineCorrectionRate`
- `userCorrectionCount`

Local OCR remains available on the device for receipt capture. Optional Google OCR
or cloud inventory matching must be an explicit user choice and must not make
basic receipt capture, local OCR, local review, or manual entry cloud-only.
Command 1 may show only summary tokens for this split, such as
`receiptCloudAssistPlanCounts`, `receiptLocalOcrModeCounts`,
`receiptParserDepthCounts`, `receiptCloudOcrOptionalCount`, and
`receiptCloudInventoryOptionalCount`.
It must not show receipt images, OCR text, store names, item details, device
serials, or private inventory content.

Native camera settings and control contract fields are operational compatibility
signals. `nativeCameraEngineCounts`, `nativeSettingsContractVersionCounts`, and
`nativeControlContractVersionCounts` show which CameraX/AVFoundation bridge,
settings-contract version, and visible-control contract produced receipt
captures. They are safe version/count tokens, not device-identifying data.
The native control expected/open counts show whether tap focus, pinch zoom,
exposure slider/reset, settings, back, and torch controls were expected for the
session and whether settings were opened. Photo brightness, sharpness,
bottom-edge, exposure, quality, and stitch fields are bucketed diagnostics so
Command 1 can explain whether capture failures are coming from focus, exposure, missing receipt sections, overlap/stitch problems, or unsupported device capability
without uploading private receipt content.

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

Detailed failure drill-down object schemas and later reference sections were moved to a secondary archive to keep this archive under the 500-line file limit.

- Archive: `docs/expense_command_center_ocr_contract_archive_failure_drilldown_schemas.md`.
