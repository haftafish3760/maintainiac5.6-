# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 205: OCR Recovery Firestore Contract Guard Batch

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 205: OCR Recovery Firestore Contract Guard Batch

Status: completed.

Goal:
- Add a reusable Firestore summary document audit for the expense OCR Command
  Center contract so the actual queued document cannot drift into unsafe paths,
  per-receipt upload shapes, raw event uploads, forbidden private fields, or an
  unsafe nested OCR contract.

Completed:
- Added `expenseTelemetrySummaryOcrContractFindingsFor` to
  `MaintainiacFirestoreDocumentBuilder`.
- The new guard validates the final Firestore draft path, upload shape,
  `rawEventUploadCount`, forbidden private top-level keys, nested OCR contract
  safety, and forbidden OCR-contract upload-shape/raw-event fields.
- Extended Firestore document tests to prove a clean summary has no findings.
- Added a crafted unsafe draft regression that flags a receipt-diagnostics path,
  per-receipt upload shape, raw event upload count, raw OCR text, merchant name,
  and private issue text.
- Extended the expense telemetry bridge queue test so the actual pending upload
  document also passes the Firestore OCR contract guard.

Verification:
- `dart format lib/shared/firebase/maintainiac_firestore_documents.dart test/maintainiac_firestore_documents_test.dart test/expense_screen_telemetry_firestore_bridge_test.dart`
- `flutter analyze lib/shared/firebase/maintainiac_firestore_documents.dart test/maintainiac_firestore_documents_test.dart test/expense_screen_telemetry_firestore_bridge_test.dart`
- `flutter test test/maintainiac_firestore_documents_test.dart test/expense_screen_telemetry_firestore_bridge_test.dart test/expense_export_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 204: OCR Recovery Firestore Contract Documentation Batch

Status: completed.

Goal:
- Document the Firestore handoff shape for the expense OCR Command Center
  contract so future dashboard/sync work keeps OCR health in one privacy-safe
  summary document instead of drifting into per-receipt admin reads/writes.

Completed:
- Expanded `docs/expense_command_center_ocr_contract.md` with the Firestore
  summary bridge path, nested field name, cost-safe upload shape, privacy guard,
  bridge API, and document-builder API.
- Updated `docs/expense_screen_full_design.md` to state that expense OCR
  Command Center health belongs in
  `orgs/{orgId}/expenseTelemetrySummaries/{summaryId}` as
  `commandCenterOcrContract`.
- Updated `docs/firebase_sync_schema_spec.md` to forbid a per-receipt admin OCR
  health collection and require `commandCenterOcrContractFindingsFor` before
  queueing.
- Extended doc guard tests so the OCR contract doc and Firebase specs must keep
  the one-summary-document path, `single_summary_document`, and privacy audit
  language.

Verification:
- `dart format test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter analyze test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter test test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart test/maintainiac_firestore_documents_test.dart test/expense_screen_telemetry_firestore_bridge_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 203: OCR Recovery Firestore Summary Bridge Batch

Status: completed.

Goal:
- Carry the privacy-safe OCR recovery contract into the existing expense
  telemetry Firestore summary path without creating per-receipt admin uploads,
  leaking receipt content, or increasing Firestore reads/writes beyond the
  single summary document pattern.

Completed:
- Extended `ExpenseTelemetryFirestoreBridge.queueHealthSummary` with an
  optional `commandCenterOcrContract` argument.
- Extended `MaintainiacFirestoreDocumentBuilder.expenseTelemetrySummaryDocument`
  to embed a sanitized OCR contract inside the same
  `expenseTelemetrySummaries/{summaryId}` document when provided.
- Reused `ExpenseExportSnapshot.commandCenterOcrContractFindingsFor` before
  Firestore queueing so unsafe contracts are rejected instead of uploaded.
- Preserved the existing `uploadShape: single_summary_document` and
  `rawEventUploadCount: 0` behavior.
- Added regression coverage for the document builder, unsafe contract rejection,
  and the actual upload queue bridge.

Verification:
- `dart format lib/shared/firebase/maintainiac_firestore_documents.dart lib/screens/expenses/data/expense_screen_telemetry_firestore_bridge.dart test/maintainiac_firestore_documents_test.dart test/expense_screen_telemetry_firestore_bridge_test.dart`
- `flutter analyze lib/shared/firebase/maintainiac_firestore_documents.dart lib/screens/expenses/data/expense_screen_telemetry_firestore_bridge.dart test/maintainiac_firestore_documents_test.dart test/expense_screen_telemetry_firestore_bridge_test.dart`
- `flutter test test/maintainiac_firestore_documents_test.dart test/expense_screen_telemetry_firestore_bridge_test.dart test/expense_export_test.dart test/expense_command_center_ocr_contract_doc_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 202: OCR Recovery Command Center Handoff Documentation Batch

Status: completed.

Goal:
- Document the Command 1/admin OCR recovery contract so future dashboard work
  can consume receipt OCR health without guessing, drifting, or exposing private
  receipt content.

Completed:
- Added `docs/expense_command_center_ocr_contract.md` as the handoff source for
  the expense OCR Command Center contract.
- Documented the current schema, privacy scope, content policy, allowed fields,
  field meanings, forbidden content, required privacy guard, rejected examples,
  Command 1 UI guidance, and update checklist.
- Added a documentation guard test proving the handoff doc names the active
  Dart schema/privacy constants, every allowed contract field, and the forbidden
  content categories that must remain out of Command 1.

Verification:
- `dart format test/expense_command_center_ocr_contract_doc_test.dart test/expense_export_test.dart lib/screens/expenses/data/expense_export_models.dart`
- `flutter analyze lib/screens/expenses/data/expense_export_models.dart test/expense_command_center_ocr_contract_doc_test.dart test/expense_export_test.dart`
- `flutter test test/expense_command_center_ocr_contract_doc_test.dart test/expense_export_test.dart test/expense_ledger_store_test.dart test/expense_draft_store_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 201: OCR Recovery Command Center Privacy Regression Batch

Status: completed.

Goal:
- Add a defensive privacy audit around the Command Center OCR contract so future
  export/admin changes cannot quietly add receipt images, raw OCR text, item
  descriptions, merchant details, proof paths, phone numbers, emails, or private
  receipt values to the admin-facing OCR health payload.

Completed:
- Added an explicit allowlist of Command Center OCR contract keys.
- Added a privacy-finding audit for the OCR contract that flags unexpected keys,
  missing required keys, private-looking string values, unsafe map keys,
  negative/invalid numbers, lists, and unsupported values.
- Exposed the audit through `commandCenterOcrContractPrivacyFindings` and a
  static `commandCenterOcrContractFindingsFor` helper so tests and future
  Command 1 wiring can verify payloads before upload/display.
- Added regression coverage proving the current contract is clean and a crafted
  unsafe payload containing merchant/private-store text, line-item-like text,
  local proof paths, and private recovery tokens is rejected.

Verification:
- `dart format lib/screens/expenses/data/expense_export_models.dart test/expense_export_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_export_models.dart test/expense_export_test.dart`
- `flutter test test/expense_export_test.dart test/expense_ledger_store_test.dart test/expense_draft_store_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 200: OCR Recovery Command Center Contract Batch

Status: completed.

Goal:
- Formalize the privacy-safe OCR recovery payload that Command 1/admin
  surfaces can consume without needing receipt images, raw OCR text, item
  descriptions, merchant details, notes, or private receipt content.

Completed:
- Added a named `commandCenterOcrContract` export payload with explicit schema,
  privacy scope, and content policy markers.
- Included the operational OCR fields Command 1 needs for expense health:
  saved reads, clean reads, review counts, warning counts, source counts,
  recovery action counts, recovery target counts, top check, and top safe
  issue/action.
- Embedded the contract into the expense export manifest while keeping the
  existing manifest OCR fields for compatibility.
- Added regression coverage proving the contract exposes OCR health aggregates
  and does not leak private store tokens, line-item descriptions, or false
  recovery action tokens from healthy reads.

Verification:
- `dart format lib/screens/expenses/data/expense_export_models.dart test/expense_export_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_export_models.dart test/expense_export_test.dart`
- `flutter test test/expense_export_test.dart test/expense_ledger_store_test.dart test/expense_draft_store_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 199: OCR Recovery Recap Export Handoff Batch

Status: completed.

Goal:
- Carry the same privacy-safe OCR read recap concepts into expense export
  manifests so exported records keep operational OCR health context without
  embedding raw receipt content.

Completed:
- Added manifest fields for `ocrReadStatus`, `ocrReadSummary`,
  `ocrReadsSaved`, `ocrCleanReadCount`, and `ocrTopCheck`.
- Built export recap summaries from existing sanitized OCR review issue/action
  surfaces, not raw OCR text, receipt images, item descriptions, or private
  merchant details.
- Expanded export coverage with both a receipt needing review and a clean OCR
  read so the manifest proves saved reads, clean reads, review count, and top
  check.
- Fixed healthy saved OCR reads so they no longer backfill false recovery
  actions such as retaking a photo just because the OCR source was `photo`.
- Added regression coverage proving clean OCR reads do not add recovery action
  tokens to manifest aggregates.

Verification:
- `dart format lib/screens/expenses/data/expense_receipt_ocr_review.dart lib/screens/expenses/data/expense_export_models.dart test/expense_export_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_receipt_ocr_review.dart lib/screens/expenses/data/expense_export_models.dart test/expense_export_test.dart`
- `flutter test test/expense_export_test.dart test/expense_ledger_store_test.dart test/expense_receipt_detail_ocr_review_test.dart test/expense_draft_store_test.dart`

### Receipt Camera Reopen Pass 198: OCR Recovery Range Recap Batch

Status: completed.

Goal:
- Extend receipt OCR recovery recap from the selected day to the active expense
  recap range so the user can see receipt read health across week, month,
  90-day, and year-to-date views.

Completed:
- Added range-based OCR recap construction from the ledger and selected
  `ExpenseDateRange`.
- Reused the same privacy-safe read status and recovery hint rules for day and
  range summaries.
- Added `Receipt Reads` rows to the expense recap panel: status, reads saved,
  needs review, read summary, and top check.
- Hardened recap row layout so long read-summary text cannot overflow the
  screen.
- Expanded widget coverage to switch from Daily to Weekly and verify the range
  recap includes receipts outside the selected day while staying privacy-safe.

Verification:
- `dart format lib/screens/expenses/calendar/expense_calendar_models.dart lib/screens/expenses/calendar/expense_day_screen.dart lib/screens/expenses/calendar/expense_day_summary_sections.dart test/expense_receipt_detail_ocr_review_test.dart`
- `flutter analyze lib/screens/expenses/calendar/expense_calendar_models.dart lib/screens/expenses/calendar/expense_day_screen.dart lib/screens/expenses/calendar/expense_day_summary_sections.dart test/expense_receipt_detail_ocr_review_test.dart`
- `flutter test test/expense_receipt_detail_ocr_review_test.dart test/expense_ledger_store_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 197: OCR Recovery Day Recap Batch

Status: completed.

Goal:
- Add a day-level receipt read health recap to the expense calendar so OCR
  review problems are visible before the user opens individual saved receipts.

Completed:
- Added `_CalendarOcrDayRecap` to summarize selected-day receipt OCR health
  from existing calendar receipt entries.
- Counted total receipts, saved receipt reads, reads needing review, clean
  reads, and the top safe recovery hint for the day.
- Added a compact `Receipt read health` panel under the calendar day controls.
- Kept the recap privacy-safe by using already-sanitized calendar OCR status
  and recovery hint labels instead of raw OCR text, receipt images, merchant
  OCR content, totals, or internal recovery tokens.
- Expanded widget/static coverage for the day recap and calendar OCR summary
  path.

Verification:
- `dart format lib/screens/expenses/calendar/expense_calendar_models.dart lib/screens/expenses/calendar/expense_day_screen.dart lib/screens/expenses/calendar/expense_day_summary_sections.dart test/expense_receipt_detail_ocr_review_test.dart`
- `flutter analyze lib/screens/expenses/calendar/expense_calendar_models.dart lib/screens/expenses/calendar/expense_day_screen.dart lib/screens/expenses/calendar/expense_day_summary_sections.dart test/expense_receipt_detail_ocr_review_test.dart`
- `flutter test test/expense_receipt_detail_ocr_review_test.dart test/expense_ledger_store_test.dart`

### Receipt Camera Reopen Pass 196: OCR Recovery Calendar Summary Batch

Status: completed.

Goal:
- Surface saved receipt OCR health from the expense calendar day entries so the
  user can spot receipts needing read review without opening each saved receipt.

Completed:
- Added privacy-safe OCR status and recovery hint fields to the calendar
  receipt data model.
- Added a compact one-line OCR summary to calendar day receipt cards when OCR
  metadata exists, such as `Read needs review: Check long receipt overlap`.
- Derived the recovery hint from the same safe Command Center issue text used
  elsewhere, avoiding raw OCR text, receipt images, private values, and internal
  recovery tokens.
- Added widget coverage proving the calendar day entry shows the safe summary
  and does not leak recovery tokens or receipt content.

Verification:
- `dart format lib/screens/expenses/calendar/expense_calendar_models.dart lib/screens/expenses/calendar/expense_day_entries.dart test/expense_receipt_detail_ocr_review_test.dart`
- `flutter analyze lib/screens/expenses/calendar/expense_calendar_models.dart lib/screens/expenses/calendar/expense_day_entries.dart test/expense_receipt_detail_ocr_review_test.dart`
- `flutter analyze lib/screens/expenses/calendar/expense_calendar_models.dart lib/screens/expenses/calendar/expense_day_entries.dart test/expense_receipt_detail_ocr_review_test.dart lib/screens/expenses/data/expense_ledger_store.dart test/expense_ledger_store_test.dart`
- `flutter test test/expense_receipt_detail_ocr_review_test.dart test/expense_ledger_store_test.dart`

### Receipt Camera Reopen Pass 195: OCR Recovery Saved Receipt Regression Batch

Status: completed.

Goal:
- Prove saved expense receipts keep OCR recovery detail after local persistence
  and expose privacy-safe aggregate recovery counts for future health surfaces.

Completed:
- Added saved receipt OCR review helpers on `ExpenseLedgerController` for
  receipts needing OCR review, recovery action counts, recovery target counts,
  top recovery action, and top recovery target.
- Built those aggregate counts from the sanitized `commandCenterSummary` so
  raw receipt content and unsafe recovery tokens cannot leak into app health
  surfaces.
- Expanded the saved receipt OCR metadata regression to verify recovery action,
  recovery target, recovery summary, Command Center summary fields, and ledger
  aggregate counts.
- Added a privacy regression where an unsafe recovery action is stored locally
  but does not appear in aggregate recovery counts.

Verification:
- `dart format lib/screens/expenses/data/expense_ledger_store.dart test/expense_ledger_store_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_ledger_store.dart test/expense_ledger_store_test.dart lib/screens/expenses/data/expense_receipt_ocr_review.dart`
- `flutter test test/expense_ledger_store_test.dart test/expense_draft_store_test.dart test/expense_export_test.dart test/expense_receipt_detail_ocr_review_test.dart`

### Receipt Camera Reopen Pass 194: OCR Recovery Detail Screen Batch

Status: completed.

Goal:
- Show saved receipt OCR recovery context on the receipt detail screen in plain
  language, without exposing raw OCR text, receipt images, or developer tokens.

Completed:
- Added a compact OCR recovery detail block to the saved receipt OCR review
  panel.
- Converted persisted recovery action and target tokens into user-facing labels
  such as `Check overlap` and `Long receipt overlap`.
- Kept the existing warning, issue, action, and chip summary intact so saved
  receipt details still explain what happened and what to check.
- Updated saved receipt detail widget coverage to verify the recovery labels
  appear and raw recovery tokens do not leak into the UI.

Verification:
- `dart format lib/screens/expenses/calendar/expense_receipt_detail_info.dart test/expense_receipt_detail_ocr_review_test.dart`
- `flutter analyze lib/screens/expenses/calendar/expense_receipt_detail_info.dart test/expense_receipt_detail_ocr_review_test.dart`
- `flutter test test/expense_receipt_detail_ocr_review_test.dart test/expense_draft_store_test.dart test/expense_export_test.dart`

### Receipt Camera Reopen Pass 193: OCR Recovery Export Summary Batch

Status: completed.

Goal:
- Carry privacy-safe OCR recovery action/target data into expense exports so
  exported receipt records and manifests keep operational recovery context
  without embedding receipt images or raw OCR text.

Completed:
- Added `ocr_recovery_action` and `ocr_recovery_target` columns to the receipt
  export CSV.
- Populated those columns from the sanitized `ExpenseReceiptOcrReview`
  Command Center summary fields.
- Added `ocrRecoveryActionCounts`, `ocrRecoveryTargetCounts`,
  `ocrTopRecoveryAction`, and `ocrTopRecoveryTarget` to the export manifest.
- Kept export recovery data token-based and privacy-safe.
- Updated export regression coverage for CSV headers, CSV values, manifest
  counts, and top recovery action/target fields.

Verification:
- `dart format lib/screens/expenses/data/expense_export_models.dart test/expense_export_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_export_models.dart test/expense_export_test.dart lib/screens/expenses/data/expense_receipt_ocr_review.dart`
- `flutter test test/expense_export_test.dart test/expense_draft_store_test.dart test/expense_ocr_failure_diagnostics_test.dart`

### Receipt Camera Reopen Pass 192: OCR Recovery Detail Persistence Batch

Status: completed.

Goal:
- Persist privacy-safe OCR recovery details with receipt OCR review snapshots so
  drafts, saved receipts, backups, exports, and future Command Center views can
  keep the user's next-step context without storing private receipt content.

Completed:
- Added `recoveryAction`, `recoveryTarget`, and `recoverySummary` to
  `ExpenseReceiptOcrReview`.
- `fromDiagnostics` now derives recovery details from the primary OCR warning
  kind and source.
- `fromMap` now backfills recovery details for older saved drafts/receipts that
  do not yet have the new fields.
- Command Center summaries now include sanitized recovery action/target tokens.
- Added a whitelist-based recovery token guard so arbitrary snake_case strings
  cannot leak into Command Center summary fields.
- Firestore receipt backups now include recovery action, recovery target, and a
  safe recovery summary using the sanitized Command Center action text.
- Updated draft and Firestore backup tests for recovery persistence, backfill,
  sanitizing, and privacy-safe summaries.

Verification:
- `dart format lib/screens/expenses/data/expense_receipt_ocr_review.dart lib/screens/expenses/data/expense_firestore_documents.dart test/expense_draft_store_test.dart test/expense_firestore_documents_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_receipt_ocr_review.dart lib/screens/expenses/data/expense_firestore_documents.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_draft_store_test.dart test/expense_firestore_documents_test.dart`
- `flutter test test/expense_draft_store_test.dart test/expense_receipt_assisted_review_flow_test.dart test/expense_ocr_failure_diagnostics_test.dart`

Note:
- `flutter test test/expense_firestore_documents_test.dart` is currently blocked
  by unrelated work-supplies catalog compile errors involving duplicate
  `_variants` declarations and invalid spreads in fencing/masonry catalog files.
  The focused analyzer covering the Firestore document builder passed.

### Receipt Camera Reopen Pass 191: OCR Recovery Summary Surface Batch

Status: completed.

Goal:
- Surface a plain next-step recovery summary in the OCR review area so users can
  tell what to do after OCR trouble without reading developer-style diagnostics.

Completed:
- Added a `Next step:` sentence to the OCR review detail area.
- The next-step summary changes by OCR warning kind and receipt source:
  missing proof, no readable text, skipped sources, duplicate/overlap,
  missing sections, PDF safety/size/readability, plugin unavailable, photo
  quality, photo read failure, PDF read failure, and unknown OCR warnings.
- Generic no-warning/no-readable-text failures now fall back to the source type:
  photo, PDF, saved text, mixed sources, or no proof.
- Kept the recovery text privacy-safe and action-oriented: retake, add a
  missing section, scan with photos, paste cleaner text, attach safe proof, or
  continue by hand.
- Updated the assisted receipt review guard to preserve the recovery helper and
  representative recovery copy.

Verification:
- `dart format lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart test/expense_ocr_failure_diagnostics_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`

### Receipt Camera Reopen Pass 190: OCR Recovery Telemetry Shape Batch

Status: completed.

Goal:
- Give the expense OCR failure diagnostics privacy-safe recovery labels that can
  later power Command Center counts without exposing receipt text, images,
  vendor names, totals, addresses, or customer content.

Completed:
- Extended OCR failure diagnostic evidence with `recovery_*` and `target_*`
  tokens.
- Added source-specific fallback recovery actions for generic/no-warning OCR
  failures: photo, PDF, saved text, mixed sources, and missing proof.
- Added warning-specific recovery actions for missing sections, overlap,
  unsafe/large/unreadable PDFs, photo quality, photo read failures, PDF read
  failures, plugin unavailable, and unknown OCR warnings.
- Kept the evidence shape compact and non-content: warning kind, severity,
  source, read/skipped counts, recovery action, and recovery target only.
- Added focused diagnostic tests for photo quality, PDF safety, generic
  no-readable-text, missing sections, prioritized PDF/photo read failures, and
  source-specific fallback recovery.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart lib/screens/expenses/data/expense_ocr_failure_diagnostics.dart test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_attachment_panel_actions_test.dart test/expense_ocr_failure_diagnostics_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart lib/screens/expenses/data/expense_ocr_failure_diagnostics.dart test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_attachment_panel_actions_test.dart test/expense_ocr_failure_diagnostics_test.dart`
- `flutter test test/expense_ocr_failure_diagnostics_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart test/receipt_camera_result_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_attachment_panel_actions_test.dart`
