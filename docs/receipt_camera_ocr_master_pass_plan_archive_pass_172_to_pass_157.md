# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 172: OCR Summary Firestore Alignment Batch

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 172: OCR Summary Firestore Alignment Batch

Status: completed.

Goal:
- Keep Firestore receipt backup OCR summaries aligned with the local
  telemetry/export health shape while preserving privacy boundaries.

Completed:
- Added the safe OCR `source` token to nested Firestore
  `commandCenterSummary` payloads.
- Kept raw OCR text, local proof paths, imported text, and raw line text out of
  backup documents.
- Added Firestore document regression coverage proving the nested Command 1
  OCR summary includes source plus primary issue/action.

Verification:
- `flutter analyze lib/screens/expenses/data/expense_firestore_documents.dart test/expense_firestore_documents_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart test/expense_ocr_failure_diagnostics_test.dart test/receipt_camera_result_test.dart`
- `git diff --check`

Known external blocker:
- Firestore/export tests that import the broader expense ledger still cannot
  load while unrelated work-supplies generated catalog files are missing.

Next camera-only focus:
- Add a recovery contract around saved OCR summaries so draft resume, saved
  receipt detail, export, and Firestore backup stay consistent.

### Receipt Camera Reopen Pass 171: OCR Failure Summary Export Alignment Batch

Status: completed.

Goal:
- Keep local export manifests aligned with the OCR health data Command 1 will
  need, without embedding raw OCR text or receipt images.

Completed:
- Added `ocrSourceCounts` and `ocrTopSource` to expense export manifests.
- Added `ocrTopPrimaryAction` so exported OCR health summaries include both
  the top issue and the next action.
- Reused saved per-receipt OCR review metadata instead of adding private
  receipt content to exports.
- Added export manifest regression coverage for OCR source and action fields.

Verification:
- `flutter test test/expense_export_test.dart test/expense_screen_telemetry_test.dart test/expense_ocr_failure_diagnostics_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_export_models.dart test/expense_export_test.dart`

Known external blocker:
- The wider receipt/expense sweep is still blocked by unrelated work-supplies
  catalog compile errors in `lib/screens/work_supplies/data`.

Next camera-only focus:
- Align Firestore OCR command summaries with the export/telemetry summary
  shape so backup mirrors and Command 1 dashboards read the same health facts.

### Receipt Camera Reopen Pass 170: OCR Failure Stage Summary Batch

Status: completed.

Goal:
- Let Command 1 separate OCR failures by pipeline stage so app health can show
  whether problems happen before OCR starts, during photo OCR, during PDF OCR,
  or after attachment read before parser handoff.

Completed:
- Added `ocrFailureStageCounts` to expense telemetry health snapshots.
- Added `topOcrFailureStage` and `topOcrFailureStageLabel` to the Command 1
  expense telemetry map.
- Extended OCR summary coverage to prove photo/PDF stage counts are separated
  and unrelated save failures do not pollute OCR stage health.

Verification:
- `flutter test test/expense_screen_telemetry_test.dart test/expense_ocr_failure_diagnostics_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart`

Known external blocker:
- The broader receipt/expense sweep currently fails in the unrelated
  work-supplies/inventory catalog area because
  `lib/screens/work_supplies/data/work_supply_catalog_sizes.dart` is missing
  and search helpers are duplicated. This pass does not modify that area.

Next camera-only focus:
- Align OCR failure summary fields with export/backup payloads so local-first
  diagnostics and Command 1 data remain consistent.

### Receipt Camera Reopen Pass 169: OCR Failure Source Action Drilldown Batch

Status: completed.

Goal:
- Make the OCR source summary actionable so Command 1 can show different
  investigation paths for photo, PDF, imported text, missing source, and
  unknown-source OCR failures.

Completed:
- Added `topOcrFailureSourceAction` to the Command 1 expense telemetry map.
- Added photo-source guidance that points to receipt camera focus, exposure,
  crop coverage, long-receipt section order, and decode failures.
- Added PDF-source guidance for safety checks, file size, rendering, page
  extraction, and PDF-to-image conversion.
- Kept the source action derived from aggregate safe source tokens only.

Verification:
- `flutter test test/expense_screen_telemetry_test.dart test/expense_ocr_failure_diagnostics_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart`

Next camera-only focus:
- Add OCR failure stage summaries so Command 1 can separate before-read,
  photo-read, PDF-read, and post-read/parser-handoff failure clusters.

### Receipt Camera Reopen Pass 168: OCR Failure Source Metadata Coverage Batch

Status: completed.

Goal:
- Let Command 1 separate receipt OCR failure patterns by safe OCR source
  without storing receipt images, receipt text, customer data, or vendor names.

Completed:
- Added `ocrFailureSourceCounts` to expense telemetry health snapshots.
- Added `topOcrFailureSource` for the dominant source behind OCR failures.
- Derived source counts from privacy-safe diagnostic evidence such as
  `source_photo` and `source_pdf`.
- Added regression coverage proving OCR source counts include photo/PDF OCR
  failures and ignore unrelated save failures.

Verification:
- `flutter test test/expense_screen_telemetry_test.dart test/expense_ocr_failure_diagnostics_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart`

Next camera-only focus:
- Add source-aware Command 1 drilldown actions so photo OCR failures, PDF OCR
  failures, and unknown-source failures point to different investigation paths.

### Receipt Camera Reopen Pass 167: OCR Failure Cause Action Coverage Batch

Status: completed.

Goal:
- Make every receipt OCR failure cause that reaches Command 1 produce a
  specific, plain next action instead of vague generic OCR guidance.

Completed:
- Added explicit Command 1 actions for possible missing receipt sections,
  receipt photo overlap, duplicate receipt text, and unknown OCR failures.
- Split overlap guidance from duplicate-text guidance so long-receipt stitch
  problems and duplicate suppression problems are easier to distinguish.
- Added regression coverage for every OCR failure cause emitted by
  `ExpenseOcrFailureDiagnostics`.
- Verified OCR action guidance remains privacy-safe and does not require raw
  receipt text, images, vendor names, or customer content.

Verification:
- `flutter test test/expense_screen_telemetry_test.dart test/expense_ocr_failure_diagnostics_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart`

Next camera-only focus:
- Carry OCR source metadata into failure telemetry summaries so Command 1 can
  separate photo/PDF/pasted-text failure patterns without private content.

### Receipt Camera Reopen Pass 166: OCR Failure Telemetry Command Summary Batch

Status: completed.

Goal:
- Give Command 1 a direct OCR failure cause summary instead of forcing it to
  infer OCR health from the full expense failure list.

Completed:
- Added `ocrFailureCauseCounts` to expense telemetry health snapshots.
- Added `topOcrFailureCause` for the leading OCR problem on the current
  telemetry window.
- Exposed both fields in the Command 1 map while keeping the payload
  privacy-safe and receipt-content-free.
- Added regression coverage proving OCR cause counts include receipt OCR
  failures and ignore unrelated save/parser failures.

Verification:
- `flutter test test/expense_screen_telemetry_test.dart test/expense_ocr_failure_diagnostics_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/expense_screen_telemetry_test.dart`

Next camera-only focus:
- Make sure every OCR failure cause that can reach Command 1 has a plain,
  specific, non-vague recommended action.

### Receipt Camera Reopen Pass 165: Receipt OCR Failure Diagnostics Regression Batch

Status: completed.

Goal:
- Lock OCR failure diagnostics to the shared warning-priority stack so the
  app records the exact failed stage even when raw warning text arrives in a
  less useful order.

Completed:
- Added regression coverage proving PDF read failures outrank duplicate-text
  review warnings for confirmed OCR failure diagnostics.
- Added regression coverage proving photo read failures outrank review-only
  photo quality and duplicate-text warnings.
- Verified diagnostics evidence keeps privacy-safe command-center facts:
  warning kind, OCR source, severity, read count, and skipped count only.
- Kept the app on the existing ML Kit OCR plus Maintainiac parser architecture;
  this pass does not build OCR from scratch or add maintenance parsing.

Verification:
- `flutter test test/expense_ocr_failure_diagnostics_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_ocr_failure_diagnostics.dart test/expense_ocr_failure_diagnostics_test.dart`

Next camera-only focus:
- Carry the exact OCR failure cause into telemetry/Command 1 summaries so
  abandoned or failed receipt sessions can show the actual failed stage.

### Receipt Camera Reopen Pass 164: Receipt OCR Health Summary Tests Batch

Status: completed.

Goal:
- Add direct coverage for compact OCR health summary helpers so local saved
  records, exports, Firestore summaries, and Command 1-ready data stay aligned.

Completed:
- Added a focused privacy-safe Command 1 OCR summary test.
- Added healthy OCR summary default coverage.
- Added empty OCR review summary default coverage.
- Verified the compact summary does not expose raw receipt text.
- Re-ran export and Firestore summary tests to keep the summary contract
  aligned across local-first and backup surfaces.

Verification:
- `flutter test test/expense_draft_store_test.dart test/expense_export_test.dart test/expense_firestore_documents_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_receipt_ocr_review.dart lib/screens/expenses/data/expense_export_models.dart lib/screens/expenses/data/expense_firestore_documents.dart test/expense_draft_store_test.dart test/expense_export_test.dart test/expense_firestore_documents_test.dart`

Next camera-only focus:
- Add regression coverage proving OCR failure diagnostics use the same
  prioritized warning stack as review, save, export, and Command 1 summaries.

### Receipt Camera Reopen Pass 163: Receipt Export Manifest OCR Health Batch

Status: completed.

Goal:
- Add aggregate OCR health data to expense export manifests so export packages
  summarize receipt OCR review burden without exposing receipt contents.

Completed:
- Added total OCR warning counts to export manifests.
- Added blocking, partial, and review warning bucket counts to export manifests.
- Added primary OCR warning kind counts to export manifests.
- Added top primary OCR issue to export manifests.
- Added export and end-to-end regression tests proving OCR health aggregates and
  new CSV columns are present without raw OCR text.

Verification:
- `flutter test test/expense_export_test.dart test/receipt_end_to_end_regression_matrix_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_export_models.dart test/expense_export_test.dart test/receipt_end_to_end_regression_matrix_test.dart`

Next camera-only focus:
- Add focused tests around the compact OCR health summary helpers so local
  saved records, exports, Firestore summaries, and Command 1-ready telemetry
  stay aligned as the receipt system grows.

### Receipt Camera Reopen Pass 162: OCR Warning Export Summary Batch

Status: completed.

Goal:
- Add privacy-safe primary OCR issue/action fields to receipt export rows so
  user exports and admin-safe summaries agree on OCR health without embedding
  raw receipt text.

Completed:
- Added `ocr_primary_warning_kind`, `ocr_primary_issue`, and
  `ocr_primary_action` columns to receipt export CSV rows.
- Wired those columns to the same compact OCR summary helpers used by saved
  receipt detail and Firestore backup summaries.
- Added export tests proving primary warning kind, issue, and action appear in
  receipt exports while existing OCR count/status fields remain intact.

Verification:
- `flutter test test/expense_export_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_export_models.dart lib/screens/expenses/data/expense_receipt_ocr_review.dart test/expense_export_test.dart`

Next camera-only focus:
- Add aggregate OCR health data to the export manifest so export packages show
  how many receipts need OCR review and which primary warning kinds are most
  common without exposing receipt content.

### Receipt Camera Reopen Pass 161: OCR Primary Warning Command Summary Batch

Status: completed.

Goal:
- Add a compact privacy-safe OCR warning summary for Command 1/admin health
  views and saved receipt detail views.

Completed:
- Added `commandCenterPrimaryIssue`, `commandCenterPrimaryAction`, and
  `commandCenterSummary` to saved expense OCR review records.
- Added OCR command center summary data to Firestore receipt backup summaries.
- Kept summary data free of raw receipt text, item descriptions, customer names,
  addresses, or other private content.
- Updated saved receipt detail UI to show the primary issue/action from the
  compact summary.
- Added tests proving saved detail, local draft/ledger persistence, and
  Firestore backup summaries carry the privacy-safe primary OCR issue/action.

Verification:
- `flutter test test/expense_receipt_detail_ocr_review_test.dart test/expense_firestore_documents_test.dart test/expense_draft_store_test.dart test/expense_ledger_store_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_receipt_ocr_review.dart lib/screens/expenses/data/expense_firestore_documents.dart lib/screens/expenses/calendar/expense_receipt_detail_info.dart test/expense_receipt_detail_ocr_review_test.dart test/expense_firestore_documents_test.dart test/expense_draft_store_test.dart test/expense_ledger_store_test.dart`

Next camera-only focus:
- Add the same primary OCR issue/action to export summary rows so user exports
  and admin-safe summaries agree on OCR health without including private text.

### Receipt Camera Reopen Pass 160: OCR Warning Diagnostics Alignment Batch

Status: completed.

Goal:
- Carry the prioritized primary OCR warning through diagnostics, saved expense
  OCR review records, and Firestore backup summaries.

Completed:
- Added primary warning kind, label, target label, and target instruction to
  `ReceiptOcrDiagnostics`.
- Added the same primary warning fields to `ExpenseReceiptOcrReview` with
  backward-compatible map loading.
- Preserved old warning kind/label lists while making `primaryWarningLabel`
  prefer the prioritized primary warning when available.
- Updated OCR failure diagnostics to use `ReceiptOcrResult.prioritizedWarnings`
  instead of a separate priority list.
- Added primary warning fields to Firestore expense receipt backup summaries.
- Preserved machine-readable warning kind casing while storing human-readable
  primary warning labels/instructions for Command 1.
- Added tests proving draft, ledger, OCR diagnostics, and Firestore backup
  summaries retain the prioritized primary warning data.

Verification:
- `flutter test test/receipt_camera_result_test.dart test/expense_draft_store_test.dart test/expense_ledger_store_test.dart test/expense_firestore_documents_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/data/expense_receipt_ocr_review.dart lib/screens/expenses/data/expense_ocr_failure_diagnostics.dart lib/screens/expenses/data/expense_firestore_documents.dart test/receipt_camera_result_test.dart test/expense_draft_store_test.dart test/expense_ledger_store_test.dart test/expense_firestore_documents_test.dart`

Next camera-only focus:
- Add a compact primary OCR warning summary helper for Command 1/admin health
  views so the app can expose success/failure/primary-warning data without
  private receipt content.

### Receipt Camera Reopen Pass 159: Review Warning Save-Gate Alignment Batch

Status: completed.

Goal:
- Make the save readiness dialog use the same prioritized OCR warning logic and
  plain-language review guidance as the visible filled receipt review.

Completed:
- Replaced the old manual blocking/partial/review warning loop in
  `_primaryOcrWarningMessage` with `ReceiptOcrWarning.compareByPriority`.
- Added warning review instructions to save-gate detail copy.
- Added warning target labels and target instructions to save-gate detail copy.
- Added a count for remaining OCR warnings so the save dialog does not hide the
  rest of the warning stack.
- Added source guards proving the save gate uses warning priority and target
  guidance instead of the old manual loop.

Verification:
- `flutter test test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_save_actions.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_result_test.dart`

Next camera-only focus:
- Align diagnostics and Command 1 summary data with the prioritized warning
  stack so admin health views can show the most important OCR issue first.

### Receipt Camera Reopen Pass 158: OCR Warning Priority Stack Batch

Status: completed.

Goal:
- Prioritize multiple OCR warnings so the most important blocker or review item
  is shown first without losing the remaining warning stack.

Completed:
- Added `prioritizedWarnings` to OCR results while preserving original
  `structuredWarnings` ordering for diagnostics compatibility.
- Added warning priority ranks based on severity and warning kind.
- Updated `primaryWarning` to use the prioritized stack.
- Updated the visible OCR review row to sort warnings by priority before
  selecting the lead warning.
- Added visible secondary review targets with `Next checks` copy for the next
  two warnings.
- Added behavior tests proving blockers outrank ordinary review warnings while
  raw structured warning order stays intact.
- Added source guards proving the review UI consumes the priority stack.

Verification:
- `flutter test test/receipt_camera_result_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/receipt_camera_result_test.dart test/expense_receipt_assisted_review_flow_test.dart`

Next camera-only focus:
- Align save-gate checks with the prioritized warning stack so blocking and
  partial OCR issues produce the same plain-language guidance in the save path.

### Receipt Camera Reopen Pass 157: Receipt Review Line Warning Targeting Batch

Status: completed.

Goal:
- Map OCR warning kinds to the exact receipt area the user should check first
  so the filled receipt review is not vague.

Completed:
- Added `reviewTargetLabel` to OCR warnings for attachment, photo clarity,
  saved proof, long receipt overlap, missing section, PDF safety, PDF size,
  PDF readability, manual entry, photo proof, photo read, PDF read, and unknown
  warning areas.
- Added `reviewTargetInstruction` with plain-language next checks for each OCR
  warning kind.
- Surfaced the target label and instruction in the visible filled receipt review
  OCR row.
- Broadened photo-quality warning classification so alternate warning wording
  still routes to photo-proof review.
- Added behavior tests for overlap, missing-section, and photo-quality warning
  targeting.
- Added source guards proving the visible review consumes warning target labels
  and instructions.

Verification:
- `flutter test test/receipt_camera_result_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/receipt_camera_result_test.dart test/expense_receipt_assisted_review_flow_test.dart`

Next camera-only focus:
- Prioritize multiple OCR warnings into a review stack so the user sees the
  most important blocker/check first without losing the rest.
