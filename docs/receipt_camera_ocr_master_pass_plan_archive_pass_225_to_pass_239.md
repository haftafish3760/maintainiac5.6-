# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 225: OCR Recovery Telemetry Failure Detail Cap Guard Batch

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 225: OCR Recovery Telemetry Failure Detail Cap Guard Batch

Status: completed.

Goal:
- Keep Command 1 OCR/parser failure drill-downs useful but bounded inside the
  single Firestore summary document so failure diagnostics do not become raw
  event history or an unbounded upload.

Completed:
- Added `maxRecentFailureDetails` to
  `MaintainiacFirestoreDocumentBuilder.expenseTelemetrySummaryDocument`.
- Capped `failureBreakdowns` at the existing default of 20 with a hard clamp of
  50.
- Capped `recentFailureDetails` at a default of 50 with a hard clamp of 100.
- Preserved caller control so either cap can be set to `0` for ultra-lean
  summaries.
- Added `caps expense telemetry failure drill-downs for Firestore` to prove the
  default cap, hard clamp, zero cap, and privacy-safe output behavior.
- Documented the failure drill-down caps in
  `docs/expense_command_center_ocr_contract.md` and
  `docs/firebase_sync_schema_spec.md`.
- Extended doc guards so the cap limits remain documented.

Verification:
- `dart format lib/shared/firebase/maintainiac_firestore_documents.dart test/maintainiac_firestore_documents_test.dart`
- `dart format test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter analyze lib/shared/firebase/maintainiac_firestore_documents.dart test/maintainiac_firestore_documents_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter test test/maintainiac_firestore_documents_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`

### Receipt Camera Reopen Pass 226: OCR Recovery Telemetry Failure Detail Schema Guard Batch

Status: completed.

Goal:
- Keep the nested Command 1 failure drill-down objects stable so an OCR/parser
  failure card can always show exactly what failed, where it failed, why it
  failed, and what action to take without exposing private receipt content.

Completed:
- Added shared expected key sets for `failureBreakdowns` and
  `recentFailureDetails`.
- Made `missingEvidence` always present as `none` when no evidence is missing,
  preventing Command 1 from having to guess whether a missing field means
  "healthy" or "not uploaded."
- Added a Firestore regression that checks nested failure object schemas and
  blocks private keys such as `payload`, `metadata`, `receiptText`,
  `rawOcrText`, `merchantName`, `itemDescription`, `proofPath`, `orgId`, and
  `userId`.
- Documented both nested object schemas in the OCR Command Center contract.
- Extended doc guards so the nested failure schemas, `missingEvidence` rule, and
  raw-private-content boundary remain documented.

Verification:
- `dart format lib/screens/expenses/data/expense_screen_telemetry.dart test/helpers/expense_telemetry_schema_expectations.dart test/maintainiac_firestore_documents_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/helpers/expense_telemetry_schema_expectations.dart test/maintainiac_firestore_documents_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter test test/maintainiac_firestore_documents_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`

### Receipt Camera Reopen Pass 227: OCR Recovery Telemetry Failure Detail Privacy Guard Batch

Status: completed.

Goal:
- Add deeper privacy regression coverage around nested failure drill-down text so
  safe labels stay useful while raw OCR text, raw receipt values, and private
  user-entered strings remain blocked from Command 1 summaries.

Completed:
- Added Firestore-side redaction for private receipt hints inside failure
  diagnostic token fields such as `failedAt`, `confirmedCause`, `evidence`,
  `missingEvidence`, `topOcrFailureCause`, and `topOcrFailureStage`.
- Redacted known merchant names to `merchant`, money-like values to `amount`,
  and receipt/auth/transaction-length numbers to `number` before Command 1
  summary upload.
- Added `scrubs private receipt hints from failure drill-down text` to prove
  nested failure summaries do not upload Lowe's/amount/receipt/auth details.
- Documented the nested failure redaction rule in
  `docs/expense_command_center_ocr_contract.md` and
  `docs/firebase_sync_schema_spec.md`.
- Extended doc guards so the merchant/amount/number privacy placeholders remain
  part of the Firestore mirror contract.

Verification:
- `dart format lib/shared/firebase/maintainiac_firestore_documents.dart test/maintainiac_firestore_documents_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter analyze lib/shared/firebase/maintainiac_firestore_documents.dart test/maintainiac_firestore_documents_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter test test/maintainiac_firestore_documents_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`

### Receipt Camera Reopen Pass 228: OCR Recovery Telemetry Failure Detail Redaction Stress Batch

Status: completed.

Goal:
- Stress the failure-detail redaction boundary with multiple vendor, fuel,
  automotive, receipt-number, barcode-like, and currency-like diagnostic inputs
  so Command 1 gets useful categories while private receipt references stay out
  of the Firestore summary.

Completed:
- Added `stress scrubs fuel auto barcode and currency failure hints`.
- Covered tokenized Shell, Walmart, Home Depot, Jiffy Lube, totals, UPC/barcode
  values, auth codes, terminal numbers, transaction numbers, invoice numbers,
  and receipt/order-like numbers.
- Confirmed the local telemetry policy blocks raw currency symbols before
  summary generation, while Firestore redaction protects tokenized receipt-like
  values that can pass local telemetry.
- Documented the stress coverage in both OCR Command Center and Firebase sync
  specs.
- Extended doc guards so fuel, retail, auto-service, barcode-like, and
  underscore-separated total redaction examples remain part of the contract.

Verification:
- `dart format test/maintainiac_firestore_documents_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter analyze lib/shared/firebase/maintainiac_firestore_documents.dart test/maintainiac_firestore_documents_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter test test/maintainiac_firestore_documents_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`

### Receipt Camera Reopen Pass 229: OCR Recovery Telemetry Failure Detail Redaction Helper Boundary Batch

Status: completed.

Goal:
- Pull the Firestore failure-detail redaction rules behind a clearer helper
  boundary with focused coverage so future camera/OCR passes can reuse or extend
  redaction without scattering privacy logic across the document builder.

Completed:
- Moved Command 1 / Firestore receipt-hint redaction behind
  `_ExpenseTelemetryFirestoreRedactor`.
- Split redaction responsibility into readable text cleanup, failure token field
  cleanup, and failure count-map key cleanup.
- Reused the helper for safe OCR contract readable text and expense telemetry
  failure drill-downs.
- Added `keeps redaction scoped to failure detail fields` to prove failure
  details redact merchant/amount/number hints while normal operational tokens
  such as platform, device tier, app version, OCR source, and app-version counts
  remain useful.
- Documented the helper boundary in OCR Command Center and Firebase sync specs.
- Extended doc guards so the helper boundary and no-over-redaction rule stay in
  the contract.

Verification:
- `dart format lib/shared/firebase/maintainiac_firestore_documents.dart test/maintainiac_firestore_documents_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter analyze lib/shared/firebase/maintainiac_firestore_documents.dart test/maintainiac_firestore_documents_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter test test/maintainiac_firestore_documents_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`

### Receipt Camera Reopen Pass 230: OCR Recovery Telemetry Redaction Contract Drift Guard Batch

Status: completed.

Goal:
- Add contract-drift coverage that compares the documented Firestore redaction
  boundary with the active helper fields so future OCR/camera telemetry fields
  cannot be added without either redaction or explicit documentation.

Completed:
- Added shared expected redaction token/map field sets to
  `test/helpers/expense_telemetry_schema_expectations.dart`.
- Added `keeps Firestore redaction helper fields aligned with contract` to guard
  `_ExpenseTelemetryFirestoreRedactor` against silent field-list drift.
- Added isolated `test/expense_telemetry_redaction_contract_guard_test.dart`
  so the redaction contract can still be verified when unrelated module imports
  are temporarily broken.
- Extended the OCR Command Center doc test so every redacted token and map field
  must be named in the contract.
- Documented the active redacted token fields and redacted count-map fields in
  both the OCR Command Center contract and Firebase sync spec.
- Extended Firestore schema guards so the sync spec must keep the redaction
  helper boundary and active field lists documented.

Verification:
- `dart format test/helpers/expense_telemetry_schema_expectations.dart test/maintainiac_firestore_documents_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart test/expense_telemetry_redaction_contract_guard_test.dart`
- `flutter analyze lib/shared/firebase/maintainiac_firestore_documents.dart test/helpers/expense_telemetry_schema_expectations.dart test/maintainiac_firestore_documents_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart test/expense_telemetry_redaction_contract_guard_test.dart`
- `flutter test test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `git diff --check`

Note:
- `flutter test test/maintainiac_firestore_documents_test.dart ...` is currently
  blocked by an unrelated compile error in
  `lib/screens/work_supplies/data/work_supply_receipt_parser_terms.dart`, where
  the const map key `taping knife` is duplicated.

### Receipt Camera Reopen Pass 231: OCR Recovery Telemetry Redaction Vendor Expansion Batch

Status: completed.

Goal:
- Expand the known merchant redaction list and regression coverage for more
  regional fuel, retail, and auto-service vendors likely to appear in receipt
  OCR/parser diagnostics.

Completed:
- Expanded the Firestore failure-diagnostic merchant redaction pattern to cover
  more regional fuel, truck stop, contractor retail, and auto-service names
  while avoiding broad numeric-only or two-letter matches that could erase useful
  operational tokens.
- Added isolated runtime coverage that builds a real expense telemetry summary
  document and proves regional vendor hints, totals, receipt numbers, barcodes,
  auth codes, transaction ids, and invoice numbers do not survive in Command
  1-visible failure drill-downs.
- Updated the OCR Command Center and Firebase sync specs so the expanded
  redaction guard stays part of the contract.
- Extended doc guards so Pilot/Flying J, Love's, Casey's, Kwik Trip, Tractor
  Supply, Harbor Freight, Valvoline, Take 5, and Firestone remain documented
  examples.

Verification:
- `dart format lib/shared/firebase/maintainiac_firestore_documents.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter analyze lib/shared/firebase/maintainiac_firestore_documents.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter test test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 232: OCR Recovery Telemetry Redaction Source Isolation Batch

Status: completed.

Goal:
- Continue hardening receipt/OCR diagnostic privacy by isolating source labels
  that can safely explain OCR failure origin from labels that might contain
  receipt text, vendor names, file paths, or user-entered content.

Completed:
- Changed OCR failure source extraction so evidence can only produce allowlisted
  source buckets: `photo`, `pdf`, `importedtext`, `mixed`, `none`, or
  `unknown`.
- Made unrecognized `source_*` labels fall back to `unknown`, preventing
  merchant names, user notes, file labels, receipt text, and other private
  evidence labels from becoming `ocrFailureSourceCounts` or
  `topOcrFailureSource`.
- Added local telemetry coverage proving known source synonyms are preserved
  while private-looking source labels become `unknown`.
- Added Firestore summary coverage proving poisoned source labels do not reach
  Command 1 and failure-detail evidence is still redacted.
- Documented the OCR source-isolation rule in the Command Center OCR contract
  and Firebase sync schema.

Verification:
- `dart format lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 233: OCR Recovery Telemetry Source Action Coverage Batch

Status: completed.

Goal:
- Ensure every allowed OCR source bucket has a clear Command 1 recovery action
  so the admin dashboard can explain what to fix without guessing or exposing
  private receipt content.

Completed:
- Added dedicated Command 1 recovery actions for `mixed` and `unknown` OCR
  source buckets instead of letting them fall through to generic guidance.
- Kept existing source-specific actions for `photo`, `pdf`, `importedtext`, and
  `none`.
- Added regression coverage proving all allowed source buckets produce a clear
  `topOcrFailureSourceAction` and that private source labels do not appear in
  the action text.
- Documented the source-action contract in the Command Center OCR contract and
  Firebase sync schema.
- Extended doc guards so the action coverage requirement stays tied to the safe
  source buckets.

Verification:
- `dart format lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 234: OCR Recovery Telemetry Source Action Firestore Guard Batch

Status: completed.

Goal:
- Prove the source-action guidance survives the final Firestore summary
  sanitizer for each allowed OCR source bucket without leaking private receipt
  evidence.

Completed:
- Added isolated Firestore-builder coverage for every allowed OCR source bucket:
  `photo`, `pdf`, `importedtext`, `mixed`, `none`, and `unknown`.
- Proved `topOcrFailureSource` survives the final Firestore summary document.
- Proved `topOcrFailureSourceAction` remains bounded, sanitizer-safe, and still
  useful enough for Command 1 to route the owner to the right investigation
  path.
- Proved source-action Firestore summaries do not preserve private vendor names
  or exact receipt totals from the source evidence.
- Documented the final Firestore sanitizer actionability requirement in the OCR
  Command Center contract and Firebase sync schema.

Verification:
- `dart format test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter analyze test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart`
- `flutter test test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 235: OCR Recovery Telemetry Failure Detail Source Action Drilldown Batch

Status: completed.

Goal:
- Make failure drill-down samples carry enough source-action context for Command
  1 to explain the next repair path on a specific OCR failure group without
  exposing private receipt content.

Completed:
- Added `ocrFailureSource` and `ocrFailureSourceAction` to grouped
  `failureBreakdowns`.
- Added the same fields to recent `recentFailureDetails` samples.
- Kept the values derived from safe OCR source buckets instead of raw evidence.
- Initially kept non-OCR failures on `ocrFailureSource: none`; Pass 237 later
  split those rows into `not_ocr` so `none` can stay reserved for OCR failures
  that started without a usable source.
- Updated Firestore nested-map allowlists and shared schema expectations so the
  new fields survive the one-summary-document Command 1 path.
- Documented the new drill-down source/action fields in the OCR Command Center
  contract and Firebase sync schema.

Verification:
- `dart format lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 236: OCR Recovery Telemetry Drilldown Source Privacy Stress Batch

Status: completed.

Goal:
- Stress drill-down source/action fields with mixed OCR and non-OCR failures,
  poisoned source labels, totals, auth codes, and store names to prove Command 1
  gets repair context without private receipt content.

Completed:
- Added a mixed Firestore stress test that combines photo OCR, PDF OCR,
  poisoned OCR source labels, user-note source labels, parser failures, and save
  failures in one summary document.
- Proved both grouped `failureBreakdowns` and recent `recentFailureDetails`
  keep safe `ocrFailureSource` / `ocrFailureSourceAction` context.
- Proved non-OCR parser/save failures stay out of raw OCR source labels; Pass
  237 later tightened their explicit bucket to `not_ocr`.
- Proved store names, exact totals, auth codes, terminal ids, invoice numbers,
  transaction numbers, and barcode-like values do not survive in the final
  Command 1-visible payload.
- Documented the mixed OCR/non-OCR drill-down stress requirement in the OCR
  Command Center contract and Firebase sync schema.

Verification:
- `dart format test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter analyze test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart`
- `flutter test test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 237: OCR Recovery Telemetry Drilldown Non-OCR Source Semantics Batch

Status: completed.

Goal:
- Give non-OCR failure drill-down rows a clearer non-OCR-safe source/action label
  for parser/save/sync failures without confusing Command 1 or exposing private
  receipt content.

Completed:
- Changed non-OCR drill-down rows from `ocrFailureSource: none` to
  `ocrFailureSource: not_ocr`.
- Kept `none` reserved for actual OCR-step failures where OCR started without a
  usable photo, PDF, or imported text source.
- Added a `not_ocr` source action that points Command 1 to workflow, confirmed
  cause, evidence summary, and recommended action instead of camera/PDF OCR
  repair paths.
- Updated local telemetry and Firestore redaction guard coverage so grouped and
  recent failure rows preserve the clearer non-OCR semantics.
- Updated the OCR Command Center contract and Firebase sync schema with the
  `not_ocr` boundary.

Verification:
- `dart format lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 238: OCR Recovery Telemetry Drilldown Source Schema Drift Guard Batch

Status: completed.

Goal:
- Add explicit drift guards so future changes to OCR source buckets, source
  actions, docs, Firestore sanitizer allowlists, and Command 1 drill-down fields
  have to move together.

Completed:
- Centralized expected OCR source buckets in the telemetry schema expectation
  helper.
- Split the six top-level OCR source buckets from the seven drill-down buckets
  that also include `not_ocr`.
- Added a Firestore drift guard that builds every safe OCR source bucket plus a
  non-OCR failure and proves local telemetry, Firestore summary maps, grouped
  failure drill-downs, and recent failure drill-downs stay aligned.
- Updated the OCR Command Center contract and Firebase sync schema to document
  that nested drill-down source fields may use `not_ocr` while top-level OCR
  source counts may not.

Verification:
- `dart format test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 239: OCR Recovery Telemetry Source Action Redaction Edge Matrix Batch

Status: completed.

Goal:
- Stress source-action redaction against edge labels, mixed source hints,
  malformed source tokens, and long action strings so Command 1 keeps useful
  guidance without leaking private receipt clues.

Completed:
- Added a Firestore-facing source-action edge matrix covering `source_camera`,
  `source_image`, `source_document`, `source_pasted_text`, `source_combined`,
  `source_missing`, malformed private source labels, and non-OCR drill-down
  rows.
- Proved each source bucket keeps a useful bounded action after Firestore
  tokenization.
- Proved source actions and drill-down rows do not leak store names, exact
  totals, auth numbers, receipt numbers, barcode-like numbers, or user-note
  source labels.
- Updated the OCR Command Center contract and Firebase sync schema to require
  source-action edge coverage.
- Extended doc guards so those edge aliases remain documented.

Verification:
- `dart format test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart test/expense_telemetry_redaction_contract_guard_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/firestore_data_model_guard_test.dart`
- `git diff --check`
