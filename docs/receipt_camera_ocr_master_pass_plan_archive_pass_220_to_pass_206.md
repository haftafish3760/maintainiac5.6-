# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 220: OCR Recovery Telemetry Schema Change Checklist Batch

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 220: OCR Recovery Telemetry Schema Change Checklist Batch

Status: completed.

Goal:
- Add a practical change checklist for future Command 1-visible expense
  telemetry fields so OCR, parser, sync, scheduler, export, Firestore, docs,
  and privacy guards move together.

Completed:
- Added an `Expense Telemetry Schema Change Checklist` section to
  `docs/expense_command_center_ocr_contract.md`.
- Documented the required update path for new telemetry fields:
  `ExpenseTelemetryHealthSnapshot.toCommandCenterMap`,
  `MaintainiacFirestoreDocumentBuilder.expenseTelemetrySummaryDocument`,
  `_sanitizeExpenseTelemetryMap`,
  `test/helpers/expense_telemetry_schema_expectations.dart`, the Firestore
  parity regression, the OCR contract doc, the Firebase sync schema spec, and
  doc guard tests.
- Added the rule that new Command 1 telemetry fields must not create
  per-event, per-receipt, per-failure, or separate admin collections just to be
  visible.
- Updated `docs/firebase_sync_schema_spec.md` to point schema changes back to
  the checklist while preserving the one-summary-document Firestore shape.
- Extended the OCR contract doc guard and Firebase data model guard to require
  the checklist, schema helper, sanitizer, and no-extra-collection rule.

Verification:
- `dart format test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter analyze test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart test/maintainiac_firestore_documents_test.dart test/helpers/expense_telemetry_schema_expectations.dart`
- `flutter test test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart test/maintainiac_firestore_documents_test.dart`

### Receipt Camera Reopen Pass 219: OCR Recovery Command Center Schema Documentation Batch

Status: completed.

Goal:
- Document the Command 1-visible expense telemetry summary schema from the
  guarded key snapshot so the Firestore summary contract is readable, tested,
  and kept in sync with code.

Completed:
- Added an `Expense Telemetry Summary Fields` section to
  `docs/expense_command_center_ocr_contract.md`.
- Documented the one-summary-document telemetry groups for envelope/context,
  expense screen flow health, image/OCR/parser/app-filled review health,
  cloud/sync/scheduler/export health, and OCR failure drill-down health.
- Moved the expected Command Center expense telemetry key set into
  `test/helpers/expense_telemetry_schema_expectations.dart` so schema snapshot
  checks and documentation guards share one source of truth.
- Updated `test/maintainiac_firestore_documents_test.dart` to use the shared
  schema expectation helper.
- Extended `test/expense_command_center_ocr_contract_doc_test.dart` so every
  expected expense telemetry key must be documented in the OCR/Command Center
  handoff contract.

Verification:
- `dart format test/helpers/expense_telemetry_schema_expectations.dart test/maintainiac_firestore_documents_test.dart test/expense_command_center_ocr_contract_doc_test.dart`
- `flutter analyze test/helpers/expense_telemetry_schema_expectations.dart test/maintainiac_firestore_documents_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter test test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart test/maintainiac_firestore_documents_test.dart`

### Receipt Camera Reopen Pass 218: OCR Recovery Summary Schema Snapshot Batch

Status: completed.

Goal:
- Add a schema snapshot for the expense Command Center telemetry map so field
  removals, renames, and undocumented additions are caught alongside Firestore
  sanitizer drift.

Completed:
- Added `_expectedExpenseTelemetryCommandCenterKeys` to the Firestore document
  test suite.
- Extended `keeps every Command Center telemetry field in Firestore summary`
  so the rich `ExpenseTelemetryHealthSnapshot.toCommandCenterMap()` output must
  match the expected schema key set.
- Kept the existing Firestore parity check, conditional-key stress check, and
  privacy checks in the same regression so Command 1-visible expense receipt
  health changes must update code, docs, and tests together.

Verification:
- `dart format test/maintainiac_firestore_documents_test.dart`
- `flutter analyze test/maintainiac_firestore_documents_test.dart lib/shared/firebase/maintainiac_firestore_documents.dart lib/screens/expenses/data/expense_screen_telemetry.dart`
- `flutter test test/maintainiac_firestore_documents_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`

### Receipt Camera Reopen Pass 217: OCR Recovery Firestore Allowlist Drift Stress Batch

Status: completed.

Goal:
- Make the Firestore summary parity regression harder to accidentally weaken by
  proving the rich fixture exercises the conditional OCR, parser, and scheduler
  telemetry keys that only appear when real failure/recovery evidence exists.

Completed:
- Strengthened `keeps every Command Center telemetry field in Firestore summary`
  with an explicit conditional-key fixture check.
- Required the parity fixture to produce and preserve
  `topExpenseSummaryOcrContractSource`,
  `topExpenseSummaryOcrContractSkippedReason`, `topOcrFailureCause`,
  `topOcrFailureSource`, `topOcrFailureSourceAction`, `topOcrFailureStage`,
  and `topOcrFailureStageLabel`.
- Added value checks for those top conditional fields so source, skipped
  reason, OCR failure cause, OCR source, recommended action, and OCR stage
  labels stay deterministic across the Firestore summary boundary.
- Preserved the single-document summary shape and privacy checks from the
  previous parity guard.

Verification:
- `dart format test/maintainiac_firestore_documents_test.dart`
- `flutter analyze test/maintainiac_firestore_documents_test.dart lib/shared/firebase/maintainiac_firestore_documents.dart lib/screens/expenses/data/expense_screen_telemetry.dart`
- `flutter test test/maintainiac_firestore_documents_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`

### Receipt Camera Reopen Pass 216: OCR Recovery Firestore Allowlist Documentation Batch

Status: completed.

Goal:
- Document the Firestore allowlist parity rule so future OCR, parser, sync,
  export, and Command 1 telemetry metrics cannot be added locally while
  silently disappearing from the one-document Firestore summary.

Completed:
- Updated `docs/expense_command_center_ocr_contract.md` to state that every
  new top-level field from
  `ExpenseTelemetryHealthSnapshot.toCommandCenterMap()` must either survive
  into `expenseTelemetrySummaries/{summaryId}` or be intentionally excluded
  with a documented reason.
- Documented the parity regression
  `keeps every Command Center telemetry field in Firestore summary` as the
  guard that compares local Command Center telemetry keys with the final
  Firestore summary document.
- Updated `docs/firebase_sync_schema_spec.md` so the Firebase cost model keeps
  those fields in the existing one-summary-document path and forbids moving
  them into per-event, per-receipt, or separate admin collections just to make
  them visible.
- Extended the OCR contract doc guard and Firestore data model guard so the
  allowlist parity rule remains documented.

Verification:
- `dart format test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter analyze test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart test/maintainiac_firestore_documents_test.dart`
- `flutter test test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart test/maintainiac_firestore_documents_test.dart`

### Receipt Camera Reopen Pass 215: OCR Recovery Firestore Allowlist Guard Batch

Status: completed.

Goal:
- Prevent future expense telemetry fields from being computed for Command 1
  locally and then silently dropped by the Firestore summary sanitizer.

Completed:
- Added a broad Firestore parity regression that builds a rich
  `ExpenseTelemetryHealthSnapshot` covering screen usage, add/abandon,
  validation, image attach, OCR, parser, app-filled line review, user
  correction, cloud backup, scheduled OCR contract queue traces, sync, export,
  and failure drill-down metrics.
- Compared every top-level key emitted by
  `ExpenseTelemetryHealthSnapshot.toCommandCenterMap()` against the generated
  `expenseTelemetrySummaries/{summaryId}` document.
- Kept the assertion key-based instead of value-based where the Firestore
  builder intentionally overrides summary document metadata such as `schema`.
- Preserved the privacy guard expectation that summary output does not expose
  raw receipt text or the org id inside the summary data.

Verification:
- `dart format test/maintainiac_firestore_documents_test.dart`
- `flutter analyze test/maintainiac_firestore_documents_test.dart lib/shared/firebase/maintainiac_firestore_documents.dart lib/screens/expenses/data/expense_screen_telemetry.dart`
- `flutter test test/maintainiac_firestore_documents_test.dart test/expense_screen_telemetry_test.dart`

### Receipt Camera Reopen Pass 214: OCR Recovery Parser Metrics Firestore Allowlist Audit Batch

Status: completed.

Goal:
- Audit the expense telemetry Command Center map against the Firestore summary
  sanitizer so parser/OCR recovery metrics are not computed locally and then
  silently dropped before Command 1 can read them.

Completed:
- Compared `ExpenseTelemetryHealthSnapshot.toCommandCenterMap` fields against
  `_sanitizeExpenseTelemetryMap`.
- Added missing parser fields to the Firestore summary allowlist:
  `parserStartedCount`, `parserCompletedCount`, `parserNeedsReviewCount`,
  `parserFailedCount`, `parserSuccessRate`, `parserReviewRate`, and
  `parserFailureRate`.
- Added missing app-filled receipt review fields:
  `appFilledReceiptLineConfirmedCount`,
  `appFilledReceiptLineCorrectedCount`, and
  `appFilledReceiptLineCorrectionRate`.
- Added missing OCR failure drill-down fields:
  `ocrFailureCauseCounts`, `topOcrFailureCause`, `ocrFailureSourceCounts`,
  `topOcrFailureSource`, `topOcrFailureSourceAction`,
  `ocrFailureStageCounts`, `topOcrFailureStage`, and
  `topOcrFailureStageLabel`.
- Added a Firestore document regression proving parser metrics, app-filled
  correction metrics, OCR failure buckets, OCR source buckets, and OCR stage
  buckets survive sanitization.

Verification:
- `dart format lib/shared/firebase/maintainiac_firestore_documents.dart test/maintainiac_firestore_documents_test.dart`
- `flutter analyze lib/shared/firebase/maintainiac_firestore_documents.dart test/maintainiac_firestore_documents_test.dart lib/screens/expenses/data/expense_screen_telemetry.dart`
- `flutter test test/maintainiac_firestore_documents_test.dart test/expense_screen_telemetry_test.dart test/expense_screen_telemetry_firestore_bridge_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 213: OCR Recovery Firestore Trace Metrics Documentation Batch

Status: completed.

Goal:
- Document the Firestore-visible scheduled OCR summary trace metrics so future
  Command 1 and sync work knows those fields belong in the existing
  `expenseTelemetrySummaries/{summaryId}` document and must not become a
  separate read-heavy trace collection.

Completed:
- Updated `docs/expense_command_center_ocr_contract.md` with the Firestore
  aggregate scheduler trace metric field list.
- Documented `expenseSummaryQueuedCount`,
  `expenseSummaryOcrContractQueuedCount`,
  `expenseSummaryOcrContractSkippedCount`,
  `expenseSummaryOcrContractSourceCounts`,
  `topExpenseSummaryOcrContractSource`,
  `expenseSummaryOcrContractSkippedReasonCounts`, and
  `topExpenseSummaryOcrContractSkippedReason`.
- Documented that these are safe counts/tokens only and must remain in the
  existing summary document.
- Updated `docs/firebase_sync_schema_spec.md` with the same Firestore metric
  contract and the no-separate-scheduler-trace rule.
- Extended doc guard tests so the Firestore scheduler trace metric contract
  remains documented.

Verification:
- `dart format test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter analyze test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter test test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 212: OCR Recovery Firestore Summary Trace Metrics Batch

Status: completed.

Goal:
- Carry the scheduled OCR summary trace metrics added in Pass 211 through the
  Firestore expense telemetry summary document so Command 1 can read them from
  the existing one-document summary path.

Completed:
- Added the scheduled OCR summary trace metric fields to the Firestore expense
  telemetry summary sanitizer allowlist.
- Preserved the one-summary-document upload shape and `rawEventUploadCount: 0`.
- Added Firestore document builder coverage proving
  `expenseSummaryQueuedCount`, OCR contract queued/skipped counts, source
  buckets, top source, skipped-reason buckets, and top skipped reason survive
  sanitization.
- Added bridge queue coverage proving the real pending Firestore summary
  document includes scheduled OCR summary trace metrics.
- Confirmed the queued document still avoids receipt text and private org/path
  leakage in the new scheduler trace metric path.

Verification:
- `dart format lib/shared/firebase/maintainiac_firestore_documents.dart test/maintainiac_firestore_documents_test.dart test/expense_screen_telemetry_firestore_bridge_test.dart`
- `flutter analyze lib/shared/firebase/maintainiac_firestore_documents.dart test/maintainiac_firestore_documents_test.dart test/expense_screen_telemetry_firestore_bridge_test.dart lib/screens/expenses/data/expense_screen_telemetry.dart`
- `flutter test test/maintainiac_firestore_documents_test.dart test/expense_screen_telemetry_firestore_bridge_test.dart test/expense_screen_telemetry_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 211: OCR Recovery Telemetry Summary Trace Metrics Batch

Status: completed.

Goal:
- Promote the scheduled OCR summary queue trace from raw telemetry into
  Command 1-ready aggregate metrics so the admin side can see whether expense
  OCR health summaries are being queued and whether the OCR contract was
  attached or skipped.

Completed:
- Added `expenseSummaryQueuedCount` to the expense telemetry health snapshot.
- Added `expenseSummaryOcrContractQueuedCount` and
  `expenseSummaryOcrContractSkippedCount`.
- Added source buckets through `expenseSummaryOcrContractSourceCounts` and
  `topExpenseSummaryOcrContractSource`.
- Added skipped-reason buckets through
  `expenseSummaryOcrContractSkippedReasonCounts` and
  `topExpenseSummaryOcrContractSkippedReason`.
- Exposed all new scheduler trace metrics through `toCommandCenterMap`.
- Added a regression test proving unrelated sync-pending events are not counted
  as expense OCR summary queue traces and private receipt content is not
  surfaced.

Verification:
- `dart format lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart lib/screens/expenses/data/expense_screen_telemetry_recorder.dart`
- `flutter test test/expense_screen_telemetry_test.dart test/expense_screen_telemetry_firestore_bridge_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 210: OCR Recovery Scheduler Trace Documentation Batch

Status: completed.

Goal:
- Document the privacy-safe local recorder trace created after scheduled OCR
  health summary queueing so future sync, Command 1, and diagnostics work knows
  exactly what can and cannot be recorded.

Completed:
- Updated `docs/expense_command_center_ocr_contract.md` with the scheduler
  recorder trace contract.
- Documented the safe trace metadata fields: `syncState`,
  `expense_summary_queued`, `summaryStatus`, `ocrContractQueued`,
  `ocrContractSource`, and optional `ocrContractSkippedReason`.
- Documented that the trace must not store Firestore path, org id, receipt
  image, raw OCR text, merchant/store names, item descriptions, proof paths, or
  private receipt values.
- Documented that throttled scheduler checks should not create trace events.
- Updated `docs/firebase_sync_schema_spec.md` with the same scheduled trace
  rule.
- Extended doc guard tests so the scheduler trace contract stays documented.

Verification:
- `dart format test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter analyze test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter test test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 209: OCR Recovery Scheduler Recorder Trace Batch

Status: completed.

Goal:
- Record a privacy-safe local telemetry trace when the expense summary
  scheduler queues a Command 1 OCR health summary, so later diagnostics can
  tell whether the OCR contract was attached without exposing receipt content
  or spamming throttled scheduler checks.

Completed:
- Added safe telemetry metadata keys for scheduled summary status and OCR
  contract queue status.
- Updated `ExpenseScreenTelemetryRecorder` so successful scheduled summary
  queueing records a local `syncPending` trace.
- The recorder trace stores only safe tokens: `expense_summary_queued`,
  `summaryStatus`, `ocrContractQueued`, `ocrContractSource`, and optional
  `ocrContractSkippedReason`.
- The recorder deliberately does not store the Firestore path or org id in the
  trace event.
- The recorder ignores throttled scheduler checks so ordinary expense events do
  not create noisy trace records during the throttle window.
- Added regression tests proving the recorder stores the queued OCR summary
  trace without receipt content and stores nothing for throttled checks.

Verification:
- `dart format lib/screens/expenses/data/expense_screen_telemetry.dart lib/screens/expenses/data/expense_screen_telemetry_recorder.dart test/expense_screen_telemetry_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart lib/screens/expenses/data/expense_screen_telemetry_recorder.dart lib/screens/expenses/data/expense_screen_telemetry_summary_scheduler.dart test/expense_screen_telemetry_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart test/expense_screen_telemetry_firestore_bridge_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 208: OCR Recovery Scheduler Failure Safety Batch

Status: completed.

Goal:
- Make scheduled expense OCR health uploads observable enough that the app can
  tell whether the scheduler attached the OCR contract, where the contract came
  from, or why it was intentionally skipped.

Completed:
- Extended `ExpenseTelemetrySummaryScheduleResult` with
  `ocrContractQueued`, `ocrContractSource`, and
  `ocrContractSkippedReason`.
- Added an internal scheduled OCR contract resolver that distinguishes explicit
  contracts, rolling local-ledger contracts, deliberate disabled state, and
  unavailable ledger state.
- Preserved the existing throttling behavior and single-summary-document queue
  behavior.
- Extended scheduler tests so rolling local-ledger OCR uploads report
  `ocrContractQueued: true` and `ocrContractSource: rolling_local_ledger`.
- Extended scheduler tests so disabled OCR contract uploads report
  `ocrContractQueued: false`, `ocrContractSource: none`, and
  `ocrContractSkippedReason: ledger_ocr_contract_disabled`.

Verification:
- `dart format lib/screens/expenses/data/expense_screen_telemetry_summary_scheduler.dart test/expense_screen_telemetry_firestore_bridge_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry_summary_scheduler.dart test/expense_screen_telemetry_firestore_bridge_test.dart`
- `flutter test test/expense_screen_telemetry_firestore_bridge_test.dart test/maintainiac_firestore_documents_test.dart test/expense_export_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 207: OCR Recovery Scheduled Upload Documentation Batch

Status: completed.

Goal:
- Document the scheduled OCR health upload path so future Command 1, sync, and
  telemetry work keeps OCR health in the one cost-safe expense summary document
  and understands that the scheduler builds the OCR contract from the rolling
  local ledger.

Completed:
- Updated `docs/expense_command_center_ocr_contract.md` with a scheduled
  summary upload section.
- Documented `ExpenseTelemetrySummaryScheduler.queueIfDue`, the rolling 90-day
  local receipt window, and the `includeLedgerOcrContract` switch.
- Updated `docs/firebase_sync_schema_spec.md` so the Firestore data model
  records the scheduled OCR contract behavior.
- Extended the Command Center OCR contract doc guard to require scheduler,
  rolling-window, and `includeLedgerOcrContract` language.
- Extended the Firestore data model guard so Firebase docs cannot forget the
  scheduler path.

Verification:
- `dart format test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter analyze test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart lib/screens/expenses/data/expense_screen_telemetry_summary_scheduler.dart`
- `flutter test test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 206: OCR Recovery Summary Scheduler Bridge Batch

Status: completed.

Goal:
- Carry the expense OCR Command Center contract through the scheduled telemetry
  summary path so routine background health uploads can include OCR recovery
  health from saved receipts without creating per-receipt admin documents or
  exposing private receipt content.

Completed:
- Extended `ExpenseTelemetrySummaryScheduler.queueIfDue` with an optional
  `commandCenterOcrContract` override for future callers and tests.
- Added automatic rolling ledger OCR contract generation from the local expense
  ledger for scheduled summary uploads.
- Kept the contract inside the existing single
  `expenseTelemetrySummaries/{summaryId}` upload document.
- Added an `includeLedgerOcrContract` switch so non-OCR summary runs can
  deliberately skip the ledger contract.
- Added scheduler regression coverage proving the queued scheduled document
  contains OCR health counts, passes the Firestore OCR contract guard, and does
  not upload private line descriptions.
- Added regression coverage proving the scheduler can skip the OCR contract
  when requested.

Verification:
- `dart format lib/screens/expenses/data/expense_screen_telemetry_summary_scheduler.dart test/expense_screen_telemetry_firestore_bridge_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry_summary_scheduler.dart test/expense_screen_telemetry_firestore_bridge_test.dart lib/screens/expenses/data/expense_screen_telemetry_firestore_bridge.dart lib/shared/firebase/maintainiac_firestore_documents.dart`
- `flutter test test/expense_screen_telemetry_firestore_bridge_test.dart test/maintainiac_firestore_documents_test.dart test/expense_export_test.dart`
- `git diff --check`
