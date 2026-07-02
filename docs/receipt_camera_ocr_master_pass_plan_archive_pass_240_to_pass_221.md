# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 240: OCR Recovery Telemetry Drilldown Action Explainability Batch

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 240: OCR Recovery Telemetry Drilldown Action Explainability Batch

Status: completed.

Goal:
- Make failure drill-down action fields easier for Command 1 to explain in
  plain language without needing private evidence, while keeping every action
  bounded, source-safe, and tied to the failed workflow.

Completed:
- Added `actionSummary` to grouped `failureBreakdowns` and recent
  `recentFailureDetails`.
- Built action summaries from safe workflow labels, confirmed cause status,
  missing evidence labels, source bucket context, and the existing recommended
  action.
- Preserved unconfirmed-cause behavior by asking for missing evidence before
  claiming the app knows the fix.
- Kept `actionSummary` readable through the Firestore sanitizer while bounded
  and private-content safe.
- Updated schema helpers, OCR Command Center docs, and Firebase sync schema so
  Command 1 can rely on the new field.

Verification:
- `dart format lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`

### Receipt Camera Reopen Pass 241: OCR Recovery Telemetry Drilldown Explainability Firestore Drift Guard Batch

Status: completed.

Goal:
- Add Firestore drift guards around `actionSummary` so future schema,
  allowlist, sanitizer, docs, and tests cannot diverge or accidentally tokenize
  the plain-language explanation.

Completed:
- Added a Firestore-facing drift guard proving `actionSummary` remains readable
  after summary sanitization instead of becoming a lowercase token.
- Proved `actionSummary` still scrubs store names, exact totals, auth numbers,
  receipt numbers, and source tokens.
- Proved confirmed OCR failures keep a useful next-check summary and
  unconfirmed failures ask for missing evidence before claiming the app knows
  the fix.
- Extended redaction helper contract tests so `actionSummary` must stay in the
  readable text sanitizer path.
- Updated OCR Command Center and Firebase sync docs to spell out the readable
  text boundary.

Verification:
- `dart format test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 242: OCR Recovery Telemetry Drilldown Explainability Cause Matrix Batch

Status: completed.

Goal:
- Build matrix coverage for `actionSummary` across confirmed OCR, parser,
  attachment, save, sync, export, and unconfirmed failure causes so every major
  receipt/expense workflow gets a useful Command 1 explanation.

Completed:
- Added local telemetry matrix coverage for `actionSummary` across OCR,
  parser, receipt attachment, save, sync, cloud backup, export, line review, and
  unconfirmed failure rows.
- Proved each summary names the failed workflow, gives the safe context to
  check next, and includes the expected next-step hint.
- Proved unconfirmed failures ask for missing evidence instead of pretending the
  app knows the fix.
- Proved local summaries stay display-friendly and do not expose raw token
  underscores.

Verification:
- `dart format test/expense_screen_telemetry_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 243: OCR Recovery Telemetry Drilldown Explainability Firestore Cause Matrix Batch

Status: completed.

Goal:
- Mirror the `actionSummary` cause matrix through the Firestore summary builder
  so Command 1 receives the same useful explanations after sanitizer and upload
  boundaries.

Completed:
- Added Firestore-facing matrix coverage for `actionSummary` across OCR,
  parser, receipt attachment, save, sync, cloud backup, export, line review, and
  unconfirmed failure rows.
- Proved grouped `failureBreakdowns` and recent `recentFailureDetails` both
  preserve the safe workflow, context, and next-step hints that Command 1 needs
  after upload.
- Proved uploaded summaries stay readable, bounded to the Firestore readable
  text limit, and avoid raw snake-case diagnostic internals.
- Proved private merchant, exact amount, auth, barcode, receipt, and poisoned
  cause hints do not survive into the Firestore summary document.

Verification:
- `dart format test/expense_telemetry_redaction_contract_guard_test.dart`
- `flutter test test/expense_telemetry_redaction_contract_guard_test.dart --plain-name "keeps action summaries useful across Firestore failure cause matrix" -r expanded`

### Receipt Camera Reopen Pass 244: OCR Recovery Telemetry Drilldown Explainability Privacy Fixture Batch

Status: completed.

Goal:
- Stress `actionSummary` with private merchant, receipt, auth, barcode, amount,
  and user-note evidence across mixed workflows so no private clue survives
  local or Firestore drill-down summaries.

Completed:
- Added a local privacy-safe failure phrase helper for `actionSummary` and
  unconfirmed `recommendedAction` text so private diagnostic values are scrubbed
  before Firestore upload.
- Redacted known merchants, exact amounts, long receipt/auth/barcode numbers,
  emails, phone numbers, and user-note/name style private references from
  summary text.
- Added a privacy fixture test proving local and Firestore grouped/recent
  summaries stay readable while hiding merchant, customer/name, auth, receipt,
  barcode, phone, amount, and raw source tokens.
- Kept safe generic language such as `merchant`, `amount`, and
  `private reference` so Command 1 remains useful without exposing private
  receipt content.

Verification:
- `dart format lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_telemetry_redaction_contract_guard_test.dart`
- `flutter test test/expense_telemetry_redaction_contract_guard_test.dart --plain-name "protects action summaries from private fixture hints locally and in Firestore" -r expanded`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`

### Receipt Camera Reopen Pass 245: OCR Recovery Telemetry Drilldown Explainability Length Budget Batch

Status: completed.

Goal:
- Keep `actionSummary` useful under Firestore readable-text limits by proving
  the failed workflow, safe context, and next action survive truncation for
  long receipt, OCR, parser, and sync diagnostic inputs.

Completed:
- Compact `actionSummary` cause, missing-evidence, and next-action phrases at
  the source so local summaries are born inside the Firestore readable text
  budget instead of depending on upload-time truncation.
- Shortened the non-OCR source context while preserving the plain-language
  phrase Command 1 needs: `the failed workflow`.
- Tightened the local action summary matrix from a 260-character ceiling to the
  180-character Firestore readable-text budget.
- Verified Firestore grouped and recent failure rows still preserve workflow,
  safe context, and next-step hints after the compact wording.

Verification:
- `dart format lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart --plain-name "covers action summaries across major failure workflows" -r expanded`
- `flutter test test/expense_telemetry_redaction_contract_guard_test.dart --plain-name "keeps action summaries useful across Firestore failure cause matrix" -r expanded`
- `flutter test test/expense_telemetry_redaction_contract_guard_test.dart --plain-name "protects action summaries from private fixture hints locally and in Firestore" -r expanded`

### Receipt Camera Reopen Pass 246: OCR Recovery Telemetry Drilldown Evidence Label Privacy Budget Batch

Status: completed.

Goal:
- Apply the same privacy and length discipline to visible evidence labels so
  Command 1 can explain what proof is missing without exposing receipt content
  or oversized diagnostic text.

Completed:
- Routed local `evidenceLabel` and `missingEvidenceLabel` through the same
  privacy-safe compact phrase builder used by `actionSummary`.
- Hardened local redaction for note/name/call phrases, known merchant names,
  receipt-number references, auth/barcode/order style identifiers, emails,
  phone numbers, exact amounts, and long numeric receipt hints.
- Expanded the local-plus-Firestore privacy fixture so summaries,
  recommended actions, evidence labels, and missing-evidence labels are all
  checked together.
- Proved visible labels stay non-empty, avoid raw snake-case tokens, and remain
  bounded while still using safe generic words such as `merchant`, `amount`,
  and `private reference`.

Verification:
- `dart format lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_telemetry_redaction_contract_guard_test.dart`
- `flutter test test/expense_telemetry_redaction_contract_guard_test.dart --plain-name "protects action summaries from private fixture hints locally and in Firestore" -r expanded`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`

### Receipt Camera Reopen Pass 247: OCR Recovery Telemetry Drilldown Confirmed Cause Label Privacy Batch

Status: completed.

Goal:
- Apply privacy-safe readable labels to confirmed cause and failure-stage labels
  so Command 1 drill-down rows never expose private receipt hints through label
  fields while still showing a useful cause category.

Completed:
- Routed local `failedAtLabel`, `causeLabel`, and
  `topOcrFailureStageLabel` through a privacy-safe diagnostic label helper.
- Kept the stored machine tokens unchanged for grouping and counts while
  making the visible labels safe for Command 1 drill-down surfaces.
- Preserved display acronyms such as `OCR`, `PDF`, and `Hive` after privacy
  cleanup so labels stay readable.
- Extended the local-plus-Firestore privacy fixture so cause labels, failure
  stage labels, and the top OCR stage label are checked alongside summaries,
  recommended actions, evidence labels, and missing-evidence labels.
- Added common receipt location redaction so city/address hints in diagnostic
  labels become generic `location` text.

Verification:
- `dart format lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_telemetry_redaction_contract_guard_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart --plain-name "builds confirmed cause failure breakdowns for Command 1" -r expanded`
- `flutter test test/expense_screen_telemetry_test.dart --plain-name "tracks export completion, blocked exports, and export failure causes" -r expanded`
- `flutter test test/expense_telemetry_redaction_contract_guard_test.dart --plain-name "protects action summaries from private fixture hints locally and in Firestore" -r expanded`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`

### Receipt Camera Reopen Pass 248: OCR Recovery Telemetry Drilldown Raw Token Boundary Batch

Status: completed.

Goal:
- Verify which raw diagnostic token fields are intentionally stored for machine
  grouping and which visible fields must remain readable, so future Command 1
  work does not accidentally show raw receipt-derived tokens to the user.

Completed:
- Added a Firestore drill-down boundary test that separates machine-token
  fields from human-visible fields.
- Proved `failedAt`, `confirmedCause`, `evidence`, `missingEvidence`, and
  `ocrFailureSourceAction` remain machine-safe tokens for grouping, filtering,
  and action routing.
- Proved visible fields such as `failedAtLabel`, `causeLabel`,
  `evidenceLabel`, `missingEvidenceLabel`, `recommendedAction`, and
  `actionSummary` do not expose raw token underscores.
- Aligned the Firestore telemetry redactor with the local privacy helper for
  known locations, note/name references, receipt-number phrases, and
  private-reference tokens.
- Fixed over-redaction so normal workflow labels such as `Receipt OCR` and
  `Receipt parser` remain readable instead of becoming private-reference text.

Verification:
- `dart format lib/shared/firebase/maintainiac_firestore_documents.dart test/expense_telemetry_redaction_contract_guard_test.dart`
- `flutter test test/expense_telemetry_redaction_contract_guard_test.dart --plain-name "keeps machine tokens out of visible Firestore drill-down text" -r expanded`
- `flutter test test/expense_telemetry_redaction_contract_guard_test.dart --plain-name "isolates OCR source labels from private evidence strings" -r expanded`
- `flutter test test/expense_telemetry_redaction_contract_guard_test.dart --plain-name "keeps action summaries useful across Firestore failure cause matrix" -r expanded`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`

### Receipt Camera Reopen Pass 249: OCR Recovery Telemetry Drift Guard Documentation Batch

Status: completed.

Goal:
- Update Command 1 OCR telemetry docs and schema guards so the machine-token
  versus visible-text boundary is explicit, testable, and hard to accidentally
  undo during future receipt-camera work.

Completed:
- Updated `docs/expense_command_center_ocr_contract.md` so Command 1 OCR and
  expense telemetry docs explicitly separate machine-token fields from visible
  drill-down text.
- Updated `docs/firebase_sync_schema_spec.md` so Firestore redaction rules
  describe merchant, location, amount, number, and private-reference
  placeholders before a summary can be queued.
- Extended documentation guard tests so both the OCR Command 1 contract and the
  Firebase sync schema keep the machine-token, visible-label, redaction, and
  private-content boundaries documented together.
- Preserved the single summary document direction for Command 1 telemetry so
  camera/OCR health stays visible without uploading raw receipt content.

Verification:
- `flutter test test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 250: OCR Recovery Telemetry Write Budget Contract Batch

Status: completed.

Goal:
- Lock the Firebase/Firestore write-budget boundary for receipt camera, OCR,
  parser, and expense diagnostics so raw local events are summarized before
  cloud upload and Command 1 can read camera health without creating one
  Firestore write per capture, failure, retry, receipt, or OCR event.

Completed:
- Added `ExpenseTelemetryFirestoreWriteBudget` with the 20,000-write safety
  target, single-summary upload shape, zero raw-event upload count, and a helper
  that estimates scheduled summary writes per day from the scheduler interval.
- Added a high-volume bridge regression proving 240 local receipt/camera events
  still queue one replacement Firestore summary document for the same
  `expenseTelemetrySummaries/latest` path.
- Proved the queued summary keeps `rawEventUploadCount` at `0`, preserves
  camera/OCR failure counts, caps recent failure samples at 50, and replaces the
  pending draft on repeated queue attempts.
- Documented the write-budget contract in the Command 1 OCR handoff doc and the
  Firebase sync schema so diagnostics stay local-first and summarized before
  Firestore upload.
- Extended doc guards to require the 15-minute / 96 scheduled writes per org per
  day / 20,000 writes per day safety language and the no per-capture,
  per-failure, per-retry, per-line, or per-receipt write rule.

Verification:
- `dart format lib/screens/expenses/data/expense_screen_telemetry_firestore_bridge.dart test/expense_screen_telemetry_firestore_bridge_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter test test/expense_screen_telemetry_firestore_bridge_test.dart`
- `flutter test test/expense_screen_telemetry_firestore_bridge_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart lib/screens/expenses/data/expense_screen_telemetry_firestore_bridge.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart test/expense_screen_telemetry_firestore_bridge_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart test/expense_screen_telemetry_firestore_bridge_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 251: Camera Health Command 1 Visibility Batch

Status: planned.

Goal:
- Make the next Command 1-facing camera health layer explicit: capture success
  rate, capture failure rate, back/exit failures, focus/exposure warnings,
  long-receipt section issues, stitching fallback rate, OCR handoff success,
  and safe drill-down paths, all without private receipt content.

### Receipt Camera Reopen Pass 224: OCR Recovery Telemetry Firestore Metadata Boundary Batch

Status: completed.

Goal:
- Lock the boundary between the local Command Center expense telemetry schema
  and the Firestore document wrapper metadata so receipt health fields, upload
  shape fields, and the optional OCR contract do not blur together.

Completed:
- Added `Firestore summary metadata stays outside local telemetry schema`.
- Proved `summaryId`, `summaryScope`, `uploadShape`, `rawEventUploadCount`,
  and `commandCenterOcrContract` are absent from
  `ExpenseTelemetryHealthSnapshot.toCommandCenterMap()`.
- Proved those same Firestore wrapper fields are present in the generated
  expense telemetry summary document.
- Proved `summaryId` is path-token sanitized before storage and that the raw
  unsanitized summary id does not survive in document data.
- Added a `Firestore Metadata Boundary` section to
  `docs/expense_command_center_ocr_contract.md`.
- Updated `docs/firebase_sync_schema_spec.md` and doc guard tests so Firestore
  wrapper metadata stays out of the local Command Center telemetry schema
  helper.

Verification:
- `dart format test/maintainiac_firestore_documents_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter analyze test/maintainiac_firestore_documents_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart test/helpers/expense_telemetry_schema_expectations.dart`
- `flutter test test/maintainiac_firestore_documents_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`

### Receipt Camera Reopen Pass 223: OCR Recovery Telemetry Sanitizer Schema Helper Guard Batch

Status: completed.

Goal:
- Protect the shared expected expense telemetry schema helper from drifting into
  Firestore-only document metadata or losing critical Command 1 receipt health
  keys.

Completed:
- Added `expense telemetry schema helper stays scoped to Command Center map`.
- Proved `expectedExpenseTelemetryCommandCenterKeys` has no duplicate entries.
- Proved Firestore document metadata keys such as `summaryId`,
  `summaryScope`, `uploadShape`, `rawEventUploadCount`, and
  `commandCenterOcrContract` are not part of the local Command Center telemetry
  schema helper.
- Proved the helper still contains critical receipt/OCR health keys such as
  `ocrSuccessRate`, `parserFailureRate`, `topOcrFailureSourceAction`,
  `failureBreakdowns`, and `recentFailureDetails`.

Verification:
- `dart format test/maintainiac_firestore_documents_test.dart`
- `flutter analyze test/maintainiac_firestore_documents_test.dart test/helpers/expense_telemetry_schema_expectations.dart`
- `flutter test test/maintainiac_firestore_documents_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`

### Receipt Camera Reopen Pass 222: OCR Recovery Telemetry Sanitizer Documentation Batch

Status: completed.

Goal:
- Document the expense telemetry sanitizer value rules so future Command 1,
  Firestore, OCR, parser, and receipt telemetry changes know which value shapes
  are allowed in the one-document summary.

Completed:
- Added an `Expense Telemetry Sanitizer Rules` section to
  `docs/expense_command_center_ocr_contract.md`.
- Documented that nonnegative counts, finite nonnegative rates, safe timestamp
  strings, safe tokens, readable labels, nonnegative count maps, and sanitized
  nested failure maps are the allowed Firestore summary value shapes.
- Documented that unsupported scalar values, negative scalar counts, negative
  rates, `NaN`, and infinite rates must throw before the Firestore summary is
  queued.
- Updated `docs/firebase_sync_schema_spec.md` with the same sanitizer boundary.
- Extended OCR contract and Firestore data model doc guards so the sanitizer
  rules remain documented.

Verification:
- `dart format test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter analyze test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart test/maintainiac_firestore_documents_test.dart test/helpers/expense_telemetry_schema_expectations.dart`
- `flutter test test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart test/maintainiac_firestore_documents_test.dart`

### Receipt Camera Reopen Pass 221: OCR Recovery Telemetry Sanitizer Type Guard Batch

Status: completed.

Goal:
- Add direct Firestore document-builder coverage for the expense telemetry
  sanitizer so invalid scalar values are rejected and map/label values are
  safely normalized before Command 1 can read them.

Completed:
- Added `rejects invalid expense telemetry scalar values before Firestore`.
- Proved negative scalar counts fail before an expense telemetry summary can be
  queued to Firestore.
- Proved negative derived rates fail before an expense telemetry summary can be
  queued to Firestore.
- Added `sanitizes expense telemetry maps and drill-down labels`.
- Proved count-map keys are tokenized, negative map counts are removed, OCR
  source drill-down keys are tokenized, readable stage labels are normalized,
  and private-looking free text/amounts do not survive as plain receipt text.
- Added a test-only `_expenseTelemetrySnapshotForSanitizer` fixture so sanitizer
  edge cases can be exercised through the public Firestore summary builder
  instead of exposing private sanitizer helpers.

Verification:
- `dart format test/maintainiac_firestore_documents_test.dart`
- `flutter analyze test/maintainiac_firestore_documents_test.dart lib/shared/firebase/maintainiac_firestore_documents.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/helpers/expense_telemetry_schema_expectations.dart`
- `flutter test test/maintainiac_firestore_documents_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
