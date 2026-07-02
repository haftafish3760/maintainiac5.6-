# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 934: Low-Storage Offline Brain Guardrail

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 934: Low-Storage Offline Brain Guardrail

Status: complete.

What changed:
- Added explicit receipt-brain risk checks that separate required base camera
  size from full offline OCR/parser intelligence size.
- Added `receiptBrainFullOfflineExceedsBaseGuardrail`,
  `receiptBrainFullOfflineMustStayOptional`, and
  `receiptBrainLowStorageDownloadRiskCode` diagnostics so the app can say when
  full offline receipt intelligence is too large to require.
- Added a user-facing low-storage warning that explains the required base
  receipt size separately from optional full-offline receipt intelligence.
- Allowed the new risk/warning keys through native capture staging diagnostics
  without exposing receipt text, prices, vendors, addresses, item names, or raw
  private content.
- Strengthened policy/settings/native tests so low-storage users remain on the
  lean base flow, cloud assist stays optional, and large full-offline packs stay
  explicit user-choice downloads.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_assistance_policy_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_assistance_policy_test.dart`
- `flutter test test/receipt_assistance_policy_test.dart -r compact`
- `flutter test test/receipt_capture_settings_store_test.dart -r compact`
- `flutter test test/receipt_native_camera_contract_test.dart -r compact`
- `flutter test test/receipt_camera_result_test.dart -r compact`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is rolling these low-storage footprint
  risk codes into accepted receipt health counts so Command One can show whether
  users are hitting base-safe, optional-pack-deferred, or too-large-full-offline
  paths without seeing any receipt content.

### Receipt Camera Reopen Pass 935: Low-Storage Risk Health Handoff

Status: complete.

What changed:
- Rolled low-storage receipt-brain footprint risk into accepted receipt reader
  and receipt-details handoff counts.
- Added counts for full-offline-over-guardrail, full-offline-must-stay-optional,
  and low-storage download risk codes.
- Added a prioritized low-storage risk outcome so health can distinguish
  blocked required base, too-large full offline on low storage, large optional
  full offline, deferred optional brain, and base-only safe paths.
- Carried the new risk counts into privacy-safe receipt handoff metadata so
  Command One can report install/download risk without receipt text, vendor
  names, prices, addresses, item descriptions, or raw private content.
- Strengthened receipt result and assisted-flow source guards so these footprint
  health signals survive photo review and receipt-details routing.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart test/receipt_camera_help_flow_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/receipt_camera_result_test.dart test/receipt_camera_help_flow_test.dart test/expense_receipt_assisted_review_flow_test.dart -r compact`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is connecting the low-storage risk
  outcome to local OCR/parser route diagnostics so health can show whether a
  poor receipt result came from photo quality, OCR readability, parser scope, or
  optional-pack/download limits.

### Receipt Camera Reopen Pass 936: Parser Storage-Limit Cause Classification

Status: complete.

What changed:
- Added privacy-safe receipt-brain storage/download risk counts to
  `ExpenseReceiptParseDiagnostics`.
- Added parser limit outcomes for blocked required base, full offline receipt
  brain too large/optional-only, optional parser pack deferred for storage, and
  user-choice optional receipt brain.
- Added exact parser failure causes for optional parser packs deferred by
  storage and oversized full-offline receipt intelligence.
- Added those causes to OCR/parser review cause codes so parser health can
  separate photo/OCR/readability failures from parser-scope and optional-pack
  limits.
- Strengthened parser failure tests so readable receipts that need a stronger
  optional parser pack are diagnosed as storage/pack guardrail cases instead of
  vague OCR or parser failures.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_parser_failure_diagnostics.dart test/expense_parser_failure_diagnostics_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_parser_failure_diagnostics.dart test/expense_parser_failure_diagnostics_test.dart`
- `flutter test test/expense_parser_failure_diagnostics_test.dart -r compact`
- `flutter test test/expense_receipt_parser_test.dart -r compact`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is wiring accepted photo-review
  footprint metadata into the OCR/read parser handoff when the user enters
  assisted receipt review, so the new parser storage-limit causes can be
  populated automatically instead of only being available as a diagnostics
  contract.

### Receipt Camera Reopen Pass 937: Accepted Review Footprint Parser Handoff

Status: complete.

What changed:
- Stored the accepted photo-review receipt-brain low-storage/download risk
  counts on the expense receipt entry state.
- Applied those counts to `ExpenseReceiptParseDiagnostics` immediately after
  OCR parsing succeeds and before the assisted receipt review screen consumes
  the parse result.
- Added the same privacy-safe counts to receipt parser telemetry metadata so
  health/admin views can separate photo quality failures from optional
  offline-brain storage limits without seeing receipt content.
- Strengthened the assisted receipt flow source guard so future changes cannot
  drop the accepted-photo footprint handoff silently.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart -r compact`
- `flutter test test/expense_parser_failure_diagnostics_test.dart -r compact`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_parser_failure_diagnostics.dart test/expense_receipt_assisted_review_flow_test.dart test/expense_parser_failure_diagnostics_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is using these parser footprint
  outcomes in the user-facing receipt review/help copy and command health
  summaries so low-storage users are guided toward optional packs or cloud
  assist without blocking basic receipt capture.

### Receipt Camera Reopen Pass 938: Low-Storage Review Guidance

Status: complete.

What changed:
- Added user-facing parser footprint labels/actions for required-base review,
  full offline receipt brain optional-only, optional parser packs deferred for
  storage, and optional receipt brain user choice.
- Surfaced those labels in the assisted receipt review chip row with a compact
  storage icon, using the existing review surface instead of adding another
  blocking panel.
- Updated assisted review detail copy so a no-line or limited-parser result can
  explain that the saved proof/core fields are still usable even when a
  stronger local receipt brain is deferred.
- Strengthened parser and assisted-flow tests so the receipt review UI cannot
  silently lose the low-storage/offline-brain guidance.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_parser_failure_diagnostics_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_parser_failure_diagnostics_test.dart -r compact`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart -r compact`
- `flutter analyze lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_parser_failure_diagnostics_test.dart test/expense_receipt_assisted_review_flow_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is command-health metadata: roll the
  receipt-brain parser limit outcome into expense telemetry health snapshots so
  Command1 can show whether failures are caused by photo quality, OCR
  readability, parser scope, or optional-pack/storage limits.

### Receipt Camera Reopen Pass 939: Command Health Footprint Outcomes

Status: complete.

What changed:
- Added `receiptBrainParserLimitOutcome` and the three privacy-safe receipt
  brain footprint count maps to parser telemetry metadata.
- Aggregated receipt-brain parser limit outcomes into expense health snapshots
  alongside existing parser category, pack pressure, OCR source, and routing
  health.
- Added Command1 map fields for receipt-brain parser limit counts and top
  low-storage download risk, without exposing receipt text, merchant names, or
  private line details.
- Strengthened telemetry schema and health snapshot tests so these new fields
  stay allowlisted and content-free.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart test/helpers/expense_telemetry_schema_expectations.dart`
- `flutter test test/expense_screen_telemetry_test.dart -r compact`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/expense_screen_telemetry_test.dart test/helpers/expense_telemetry_schema_expectations.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is package-size enforcement: add a
  receipt build footprint manifest/check so required camera/OCR code stays lean
  and heavy receipt intelligence remains optional/downloadable instead of
  silently inflating the base app.

### Receipt Camera Reopen Pass 940: Required Base Footprint Release Check

Status: complete.

What changed:
- Added `ReceiptRequiredBaseFootprintReleaseCheck`, a single local contract
  that turns the receipt-brain footprint summary into release status:
  `ready`, `review`, or `blocked`.
- The check reports privacy-safe blocking and review reason codes for oversized
  required base installs, parser packs accidentally bundled into the required
  base, optional packs attached to first install, and full offline receipt
  intelligence that must remain optional.
- Spread the release-check diagnostics into the existing receipt-brain
  footprint diagnostics so camera capture, OCR/parser handoff, and command
  health can all use one source of truth.
- Strengthened footprint tests for low-storage ready base capture, high-capacity
  optional full offline review, and oversized required-base block cases.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart test/receipt_assistance_policy_test.dart`
- `flutter test test/receipt_assistance_policy_test.dart -r compact`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart test/receipt_assistance_policy_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is passing the release-check status
  through accepted photo review/telemetry so Command1 can alert if a future
  receipt build drifts from lean-base capture into a blocked required install.

### Receipt Camera Reopen Pass 941: Footprint Release Check Handoff

Status: complete.

What changed:
- Added accepted-photo result counts for required-base footprint release
  status, can-ship state, review state, blocking reasons, and review reasons.
- Included those counts in receipt reader/details handoff metadata so the
  camera-to-OCR flow carries the same required-base install guardrail as the
  policy layer.
- Allowlisted the release-check diagnostics through native capture staging so
  native camera results cannot lose the package-size guardrail before review.
- Strengthened result and assisted-flow source tests so the release-check status
  stays visible in privacy-safe handoff metadata.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_camera_result_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/receipt_camera_result_test.dart -r compact`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart -r compact`
- `flutter test test/receipt_native_camera_contract_test.dart -r compact`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_camera_result_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_native_camera_contract_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is rolling required-base footprint
  release status into expense telemetry health snapshots so Command1 can flag
  package-size drift as a release blocker before it reaches users.

### Receipt Camera Reopen Pass 942: Command Health Required-Base Footprint

Status: complete.

What changed:
- Allowed required-base footprint release-check metadata through expense
  telemetry sanitization.
- Aggregated required-base footprint status, can-ship counts, review counts,
  blocking reasons, and review reasons into expense health snapshots.
- Added Command1 map fields for top required-base footprint status, top blocking
  reason, and top review reason.
- Strengthened the Command1 summary test and schema expectations so package-size
  drift remains visible without receipt content or private user data.

Validation:
- `dart format lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart test/helpers/expense_telemetry_schema_expectations.dart`
- `flutter test test/expense_screen_telemetry_test.dart -r compact`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart test/helpers/expense_telemetry_schema_expectations.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is local OCR/parser evidence quality:
  make the parser diagnostics distinguish image-readability issues from
  missing vendor/category patterns more sharply for long receipts and
  low-storage local-only setups.

### Receipt Camera Reopen Pass 943: Local Parser Evidence Quality

Status: complete.

What changed:
- Added a privacy-safe local parser evidence outcome to receipt parse
  diagnostics so Command1 and future review screens can tell the difference
  between OCR/photo readability failure, readable text with weak local parser
  patterns, optional parser pack limits, storage-limited receipt-brain packs,
  and locally ready parser evidence.
- Added human-readable summary and action labels for each evidence outcome so
  failures can point to the right fix without exposing receipt text.
- Included the local parser evidence outcome in parser failure evidence strings
  so telemetry can answer whether the next improvement belongs in capture/OCR
  prep, local merchant/total/line parser rules, optional parser packs, or
  low-storage package guardrails.
- Strengthened parser diagnostics tests for no-usable-fields readability
  failure, optional detail pack routing, deferred/offline receipt-brain storage
  limits, and totals-found/no-safe-lines parser-pattern gaps.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_parser_failure_diagnostics.dart test/expense_parser_failure_diagnostics_test.dart`
- `flutter test test/expense_parser_failure_diagnostics_test.dart -r compact`
- `flutter analyze lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_parser_failure_diagnostics.dart test/expense_parser_failure_diagnostics_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is feeding the local parser evidence
  outcome into expense telemetry health snapshots so Command1 can summarize
  whether recent receipt failures are camera/OCR readability problems or local
  parser-pattern/pack problems.

### Receipt Camera Reopen Pass 944: Command Health Local Parser Evidence

Status: complete.

What changed:
- Allowlisted privacy-safe local parser evidence metadata through expense
  telemetry:
  `localParserEvidenceOutcome` and `localParserEvidenceOutcomeCounts`.
- Aggregated local parser evidence outcomes in expense health snapshots so
  Command1 can summarize whether receipt failures are OCR/readability-limited,
  local-parser-pattern-limited, optional-pack-limited, storage-limited, or
  locally ready.
- Added `topLocalParserEvidenceOutcome` and command-center map output so the
  admin app can show the dominant receipt-brain bottleneck without receipt
  images, receipt text, merchant details, or line-item content.
- Strengthened the parser health telemetry test with ready local parsing,
  storage-limited optional receipt brain, and OCR/readability-limited failure
  examples.

Validation:
- `dart format lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart test/helpers/expense_telemetry_schema_expectations.dart`
- `flutter test test/expense_screen_telemetry_test.dart -r compact`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart test/helpers/expense_telemetry_schema_expectations.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is adding a camera/OCR acceptance gate
  that keeps OCR extraction using the strongest accepted source image while
  keeping stored/cloud backup images on the lean data-saving path.

### Receipt Camera Reopen Pass 945: OCR Source Before Saved Proof Contract

Status: complete.

What changed:
- Added an explicit prepared-image storage contract so the receipt pipeline can
  report whether OCR reads the prepared receipt source before the smaller saved
  proof copy is kept.
- Added privacy-safe storage/OCR diagnostics to prepared receipt images:
  OCR storage policy code, prepared-source-before-saved-proof flag, saved-proof
  fallback flag, data saver level, separate-copy flag, quality score
  relationship, enhanced-source flag, and scanner decision codes.
- Passed that contract into receipt photo review preparation diagnostics so
  later OCR/parser handoff can prove it is reading the OCR source rather than
  the compressed stored proof copy.
- Strengthened data-saver tests so the OCR source remains separate from the
  saved proof copy, the saved proof remains smaller/equal on disk, and the
  diagnostics remain free of file paths and receipt text.
- Updated stale test wording from backup-image language to saved-proof language
  to match the current user-facing copy.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_image_processor.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_image_data_saver_test.dart`
- `flutter test test/receipt_image_data_saver_test.dart -r compact`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_image_processor.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_image_data_saver_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is exposing the OCR/source-before-saved
  proof contract in accepted-photo handoff counts so receipt review and
  Command1 can detect if a future flow accidentally OCRs the compressed proof.

### Receipt Camera Reopen Pass 946: OCR Storage Policy Handoff Counts

Status: complete.

What changed:
- Added accepted-photo result counters for OCR storage policy diagnostics from
  preparation reports:
  `ocrStoragePolicyCounts`,
  `ocrUsesPreparedSourceBeforeSavedProofCounts`, and
  `ocrUsesSavedProofFallbackCounts`.
- Added `ocrStoragePolicyOutcome` so accepted photo review can report whether
  OCR is using the prepared clear source before the saved proof or falling back
  to the saved proof for review.
- Added OCR storage-policy counts into receipt reader/details handoff counts
  with privacy-safe keys such as
  `ocr_storage_policy_ocr_clear_source_before_saved_proof_copy`.
- Added the same counts/outcome to privacy-safe receipt handoff metadata so
  later telemetry can catch compressed-proof OCR regressions without receipt
  text or file paths.
- Strengthened receipt camera result tests for the new handoff counts,
  outcome, and metadata.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart`
- `flutter test test/receipt_camera_result_test.dart -r compact`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is allowing the OCR storage-policy
  handoff metadata through expense telemetry and Command1 health summaries.

### Receipt Camera Reopen Pass 947: Command Health OCR Storage Policy

Status: complete.

What changed:
- Allowlisted OCR storage-policy handoff metadata in expense telemetry:
  `ocrStoragePolicyCounts`, `ocrStoragePolicyOutcome`,
  `ocrUsesPreparedSourceBeforeSavedProofCounts`, and
  `ocrUsesSavedProofFallbackCounts`.
- Aggregated OCR storage-policy counts across OCR and parser events so
  Command1 can detect whether receipt OCR is reading the prepared source before
  saved proof or falling back to the saved proof.
- Added health snapshot fields and Command1 map fields for the OCR storage
  policy counts and top outcomes.
- Strengthened expense telemetry tests with two source-first examples and one
  saved-proof fallback example, all without receipt text, merchant content, or
  file paths.

Validation:
- `dart format lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart test/helpers/expense_telemetry_schema_expectations.dart`
- `flutter test test/expense_screen_telemetry_test.dart -r compact`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart test/helpers/expense_telemetry_schema_expectations.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is tightening the user-facing camera
  guidance around low-storage devices so heavy receipt brain packs stay
  optional while capture and basic local receipt reading remain available.

### Receipt Camera Reopen Pass 948: Local-First Low-Storage Receipt Readiness

Status: complete.

What changed:
- Added local-first readiness gates to `ReceiptBrainFootprintSummary` so the
  receipt system can prove the required base app still supports native receipt
  capture, manual receipt entry, and basic local receipt reading without pulling
  heavyweight parser/OCR packs into the install.
- Added readiness and action codes for the important footprint cases:
  blocked capture, missing basic reader, optional pack attached to base,
  parser pack forced into the base, lean local mode with optional packs
  deferred, optional offline pack available, and base-only local receipt flow.
- Added user-facing low-storage guidance that explains the base app works
  locally first, optional offline packs are chosen later, and assist/cloud
  fallback must not block taking or saving a receipt.
- Exposed the readiness fields through privacy-safe diagnostics and the native
  capture staging allowlist without receipt text, file paths, merchant names,
  or device identifiers.
- Strengthened receipt assistance policy tests so cramped/low-storage devices
  keep capture and basic local receipt reading available while heavy receipt
  brain packs stay optional.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_assistance_policy_test.dart`
- `flutter test test/receipt_assistance_policy_test.dart -r compact`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_assistance_policy_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_assistance_policy_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is carrying the local-first readiness
  codes into accepted-photo handoff counts and Command1 health so the admin app
  can see whether low-storage phones are protected without seeing private
  receipt content.
