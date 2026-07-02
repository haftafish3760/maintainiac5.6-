# Receipt Camera Cleanup Pass Log Archive

Archived pass entries from `receipt_camera_cleanup_pass_log.md`. This file covers physical log order from pass 014 to pass 021.

## Pass 014 - 2026-07-01 20:12:27 EDT

Scope:
- Split `expense_ledger_store.dart` below the 500-line cap.

Changes:
- Added `expense_ledger_duplicate_helpers.dart`.
- Moved receipt duplicate/fingerprint helper functions and calendar ordering
  helpers out of `expense_ledger_store.dart`.
- Reduced `expense_ledger_store.dart` to 358 lines.

Verification:
- `dart analyze lib/screens/expenses/data/expense_ledger_store.dart` passed.
- `dart run tool/maintainiac_source_audit.dart
  lib/screens/expenses/data/expense_ledger_store.dart
  lib/screens/expenses/data/expense_ledger_duplicate_helpers.dart` passed.
- `flutter test test/expense_ledger_store_test.dart -r compact` passed.
## Pass 015 - 2026-07-01 20:16:33 EDT

Scope:
- Finished splitting `receipt_photo_review_controls.dart` below the 500-line
  cap by moving preview action tray behavior into its own part file.
- Repaired split-aware source tests that still read only the old monolithic
  receipt photo review controls file.

Changes:
- Added `receipt_photo_review_preview_action_tray.dart`.
- Registered the new part in `receipt_photo_review_screen.dart`.
- Reduced `receipt_photo_review_controls.dart` to 284 lines.
- Kept `receipt_photo_review_preview_action_tray.dart` at 339 lines.
- Updated `expense_receipt_assisted_review_flow_test.dart` to read the photo
  controls and preview action tray as one logical unit.
- Updated `receipt_camera_capture_layout_test.dart` to read split receipt photo
  controls and to point source assertions at the files that now own the moved
  behavior.

Verification:
- `dart analyze
  test/receipt_camera_capture_layout_test.dart
  test/expense_receipt_assisted_review_flow_test.dart
  lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart` passed.
- `dart run tool/maintainiac_source_audit.dart
  lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart
  lib/shared/widgets/receipt_capture/receipt_photo_review_preview_action_tray.dart`
  passed.
- `flutter test
  test/receipt_camera_capture_layout_test.dart
  test/expense_receipt_assisted_review_flow_test.dart -r compact` passed at
  2026-07-01 20:20:26 EDT.

Intermediate failures fixed:
- The assisted-review test initially failed because it expected
  `_ReceiptPreviewActionTray`, `Next`, and local-section-save copy inside
  `receipt_photo_review_controls.dart` after those strings moved to
  `receipt_photo_review_preview_action_tray.dart`.
- The camera layout test initially failed because preview tray warning and
  coverage-decision assertions still targeted the old controls file.
- One analyzer/test cycle failed because `qualityRecovery` was accidentally
  added to the wrong test scope; the variable was moved to the test that uses
  quality-recovery assertions.
- Additional stale assertions were retargeted after the split:
  `coverageDecision.shouldEmphasizeAddPhoto`, native saved-photo action
  ordering, bottom overlay color, and post-capture quality-score copy.

Remaining audit count:
- 24 receipt-scope production files exceed 500 lines as of
  2026-07-01 20:20:26 EDT.
## Pass 016 - 2026-07-01 20:20:57 EDT

Scope:
- Split the shared receipt capture settings sheet below the 500-line cap.
- Kept the split inside the existing settings part structure instead of adding
  throwaway numbered files.

Changes:
- Moved scanner/runtime settings widgets into
  `receipt_capture_runtime_settings.dart`.
- Kept expense review/default proof storage widgets in
  `receipt_capture_review_storage_settings.dart`.
- Reduced `receipt_capture_settings_sheet.dart` to 284 lines.
- Kept `receipt_capture_runtime_settings.dart` at 225 lines.
- Kept `receipt_capture_review_storage_settings.dart` at 391 lines.

Verification:
- `dart analyze
  lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart` passed.
- `dart analyze
  test/receipt_capture_settings_store_test.dart
  test/receipt_camera_help_flow_test.dart` passed.
- `dart run tool/maintainiac_source_audit.dart
  lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart
  lib/shared/widgets/receipt_capture/receipt_capture_runtime_settings.dart
  lib/shared/widgets/receipt_capture/receipt_capture_review_storage_settings.dart`
  passed.
- `flutter test
  test/receipt_capture_settings_store_test.dart
  test/receipt_camera_help_flow_test.dart -r compact` passed.

Remaining audit count:
- 23 receipt-scope production files exceed 500 lines as of
  2026-07-01 20:25:57 EDT.
## Pass 017 - 2026-07-01 20:26:21 EDT to 20:47:01 EDT

Scope:
- Split `expense_receipt_privacy_event.dart` below the 500-line cap.
- Repair the privacy/admin diagnostics Firestore sanitizer contract that was
  dropping current Command Center receipt telemetry fields.

Changes:
- Added `expense_receipt_privacy_event_serialization.dart` for
  `PrivacySafeReceiptEvent.toMap()`.
- Added `expense_receipt_privacy_event_helpers.dart` for the privacy event enum
  and helper functions.
- Reduced `expense_receipt_privacy_event.dart` to 497 lines.
- Kept `expense_receipt_privacy_event_serialization.dart` at 173 lines and
  `expense_receipt_privacy_event_helpers.dart` at 161 lines.
- Updated `maintainiac_firestore_documents.dart` so expense telemetry summaries
  preserve current receipt/OCR/admin diagnostics, including receipt brain
  readiness, local-only acceptance, parser routing, OCR source quality review,
  saved-photo warning cause, native camera identity/surface, native zoom, native
  back dispatch, and pre-capture exposure abort fields.
- Updated `expense_telemetry_schema_expectations.dart` and the Firestore
  telemetry parity fixture so the tests exercise those fields through the real
  aggregation paths.
- Tightened Firestore redaction stress coverage so user-derived nested payload
  values and count buckets are checked without treating app-owned schema keys as
  receipt text.

Verification:
- `dart analyze
  test/receipt_privacy_event_store_test.dart
  test/maintainiac_firestore_documents_test.dart
  test/maintainiac_firestore_upload_queue_test.dart
  lib/screens/expenses/data/expense_receipt_parser.dart
  lib/screens/expenses/data/expense_receipt_privacy_event_store.dart
  lib/shared/firebase/maintainiac_firestore_documents.dart` passed.
- `dart run tool/maintainiac_source_audit.dart
  lib/screens/expenses/data/expense_receipt_privacy_event.dart
  lib/screens/expenses/data/expense_receipt_privacy_event_serialization.dart
  lib/screens/expenses/data/expense_receipt_privacy_event_helpers.dart` passed.
- `flutter test
  test/receipt_privacy_event_store_test.dart
  test/maintainiac_firestore_documents_test.dart
  test/maintainiac_firestore_upload_queue_test.dart -r compact` passed
  37 tests.

Intermediate failures fixed:
- The first focused Flutter run failed because
  `_expenseTelemetrySnapshotForSanitizer` was stale and did not provide all
  required `ExpenseTelemetryHealthSnapshot` fields.
- After fixture repair, Firestore sanitizer tests failed because the production
  allowlist dropped many current Command Center telemetry keys.
- The redaction helper contract was stale for multiple privacy-sensitive map
  fields, including parser category, receipt brain, storage policy, OCR source,
  saved-photo warning cause, and native camera buckets.
- One privacy stress test failed on the app-owned schema key
  `receiptInstallCameraShellParserFreeCounts`; the test now scans payload values
  and nested count buckets while leaving root schema keys out of the private
  receipt text scan.
- The rich Firestore parity fixture initially did not exercise several
  conditional top fields. The fixture now includes representative safe metadata
  for saved-photo cause, native camera surface/identity, native exposure and
  zoom/back controls, receipt brain readiness, local-only acceptance, OCR
  storage policy, parser routing, parser pack pressure, local parser evidence,
  and OCR source quality review.

Known follow-up:
- `lib/shared/firebase/maintainiac_firestore_documents.dart` is still an
  oversized production file at 1042 lines and should be split in a later pass.

Remaining audit count:
- 17 receipt-scope production files exceed 500 lines as of
  2026-07-01 20:47:01 EDT.
## Pass 018 - 2026-07-01 20:47:40 EDT to 21:08:06 EDT

Scope:
- Split the shared receipt attachment panel below the 500-line cap.
- Repair focused camera/OCR source tests after the split so they validate the
  real part-file ownership instead of stale monolithic source strings.
- Fix a broken photo-review action split discovered by Flutter compilation.

Changes:
- Reduced `receipt_attachment_panel.dart` to 397 lines.
- Added `receipt_attachment_publish_helpers.dart` at 341 lines for attachment
  publication, clear/remove actions, file sizing, quality extraction, settings,
  and photo/document signal helpers.
- Added `receipt_attachment_recovery_actions.dart` at 126 lines for native
  capture recovery load/resume/dismiss actions.
- Added `receipt_attachment_status_widgets.dart` at 367 lines for interrupted
  capture, read status, and proof-removal UI.
- Restored the working save/continue flow into
  `receipt_photo_review_save_actions.dart` and removed the stale duplicate
  `receipt_photo_review_continue_actions.dart` part registration from
  `receipt_photo_review_screen.dart`.
- Fixed the extra closing brace left in `receipt_photo_review_exit_actions.dart`.
- Retargeted source-based tests to read the split helper files and current
  public split-safe helper names, including OCR-source handoff, native signal,
  and review-read helpers.

Verification:
- `dart analyze
  lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart
  lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart
  test/receipt_attachment_panel_actions_test.dart
  test/receipt_capture_flow_shareability_test.dart
  test/receipt_camera_help_flow_test.dart` passed.
- `flutter test
  test/receipt_attachment_panel_actions_test.dart
  test/receipt_capture_flow_shareability_test.dart
  test/receipt_capture_settings_store_test.dart
  test/receipt_camera_help_flow_test.dart -r compact` passed 27 tests.
- `dart run tool/maintainiac_source_audit.dart
  lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart
  lib/shared/widgets/receipt_capture/receipt_attachment_publish_helpers.dart
  lib/shared/widgets/receipt_capture/receipt_attachment_recovery_actions.dart
  lib/shared/widgets/receipt_capture/receipt_attachment_status_widgets.dart
  lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart
  lib/shared/widgets/receipt_capture/receipt_photo_review_exit_actions.dart`
  passed.

Intermediate failures fixed:
- Private extension methods moved into split parts were not callable from other
  parts; cross-part attachment helpers were made public where needed.
- Focused Flutter tests initially failed because they still expected methods and
  constants in the old monolithic files.
- Flutter compilation exposed a real broken split:
  `receipt_photo_review_save_actions.dart` was empty/broken and
  `receipt_photo_review_exit_actions.dart` had an extra closing brace.
- Source tests still expected stale private helper names such as
  `_photoDocumentSignalsFor`, `_qualityForOcrSourceIndex`, and
  `_savedPhotoWarningsForOcrSourceIndex`; tests now follow the current public
  helper names where the split requires them.
- Several source-test substring anchors referenced old method names such as
  `_takePhoto` and `_returnToReceiptImportOptions`; those were updated to the
  current `takeReceiptPhoto` and `returnToReceiptImportOptions` flow.

Known follow-up:
- `receipt_photo_review_screen.dart` is still oversized at 1335 lines and needs
  a dedicated split pass.
- `test/receipt_capture_flow_shareability_test.dart` and
  `test/receipt_camera_help_flow_test.dart` are also large source-test files,
  though the current production source audit does not count tests.

Remaining audit count:
- 14 receipt-scope production files exceed 500 lines as of
  2026-07-01 21:08:06 EDT.
## Pass 019 - 2026-07-01 21:08:42 EDT to 21:10:12 EDT

Scope:
- Verify and finish the `receipt_photo_review_screen.dart` split below the
  500-line cap.
- Retarget source tests after layout/surface constants moved out of the screen
  shell.

Changes:
- Confirmed `receipt_photo_review_screen.dart` is reduced to 272 lines.
- Confirmed new split files stay under the cap:
  `receipt_photo_review_surfaces.dart` at 389 lines,
  `receipt_photo_review_async_work.dart` at 363 lines, and
  `receipt_photo_review_stitch_preview_widgets.dart` at 321 lines.
- Updated `receipt_capture_flow_shareability_test.dart` so screen/layout source
  checks include `receipt_photo_review_surfaces.dart` for bottom-control height
  constants.

Verification:
- `dart analyze
  lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart
  test/receipt_capture_flow_shareability_test.dart
  test/receipt_camera_help_flow_test.dart` passed.
- `dart run tool/maintainiac_source_audit.dart
  lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart
  lib/shared/widgets/receipt_capture/receipt_photo_review_surfaces.dart
  lib/shared/widgets/receipt_capture/receipt_photo_review_async_work.dart
  lib/shared/widgets/receipt_capture/receipt_photo_review_stitch_preview_widgets.dart`
  passed after rerun. The first attempt hit a Dart native-assets toolchain
  null-check error, then the exact same audit command passed.
- `flutter test
  test/receipt_capture_flow_shareability_test.dart
  test/receipt_camera_help_flow_test.dart -r compact` passed 13 tests.

Intermediate failures fixed:
- `receipt_camera_help_flow_test.dart` briefly failed to compile because a
  source helper had a malformed newline join string; formatting/analyzer and the
  final focused Flutter run are now green.
- `receipt_capture_flow_shareability_test.dart` still expected review label and
  surface constants in the screen shell after the split. The test now reads the
  correct split owners.

Known follow-up:
- The source-test files themselves are oversized and should be split later, but
  the current production audit does not count tests.
- The next cleanup pass should target another production oversized receipt file,
  likely `receipt_capture_models.dart`, `receipt_capture_flow.dart`, or
  `receipt_image_processor.dart`.

Remaining audit count:
- 13 receipt-scope production files exceed 500 lines as of
  2026-07-01 21:10:12 EDT.
## Pass 020 - 2026-07-01 21:10:20 EDT to 21:14:42 EDT

Scope:
- Start converting receipt/OCR QA from guardrail checks into a product-grade
  quality standard.
- Upgrade the pure Dart receipt QA runner so it reports named quality
  dimensions instead of one vague score.

Changes:
- Added `docs/receipt_camera_world_class_qa_standard.md`.
- Defined benchmark behaviors, release gates, fixture packs, target scores, and
  next test work for capture, OCR text, parser readiness, maintenance receipt
  intelligence, admin diagnostics, privacy, Firebase, and device/storage safety.
- Updated `tool/receipt_qa_runner.dart` to report dimension scores for:
  capture, OCR text, parser, maintenance, privacy/admin, and device/storage.
- Added a maintenance receipt fixture covering oil type, oil filter, tire
  rotation, total/tax, and next-service mileage.
- Fixed the scoring model so optional dimensions do not count as passing when a
  fixture does not actually exercise that dimension.

Verification:
- `dart analyze tool/receipt_qa_runner.dart` passed.
- `dart run tool/receipt_qa_runner.dart --pack=maintenance --json` produced
  dimension scores and the maintenance fixture report.

Intentional blocker:
- `tool/receipt_qa_runner.dart` still exits non-zero because it correctly
  reports that production receipt parser/OCR logic is not yet pure-Dart-testable
  without Flutter. That blocker should stay red until line roles, amount
  recovery, parser handoff, and maintenance extraction are moved into pure Dart
  libraries.

Known follow-up:
- Add versioned external fixture files instead of hard-coded runner fixtures.
- Add exact/normalized/missed/false-positive/privacy-violation field scoring.
- Add admin diagnostic snapshot tests for privacy-safe failure reports.
- Add device-tier budgets for older phones, low storage, optional packs, and
  local/cloud assist policy.
## Pass 021 - 2026-07-01 21:15:18 EDT to 21:19:56 EDT

Scope:
- Move the first receipt text-quality checks out of the QA runner and into an
  app-owned pure Dart receipt contract.
- Keep the QA runner under the 500-line cap while making it less of a one-off
  script island.

Changes:
- Added `lib/shared/receipts/receipt_text_quality_contract.dart`.
- Added pure Dart signals for receipt lines, merchant/date/total detection,
  fuel quantity, tax, line-item amount readiness, maintenance service lines,
  maintenance interval lines, tender amount rows, and bottom-total coverage.
- Updated `tool/receipt_qa_runner.dart` to use the shared contract instead of
  private duplicated detector functions.
- Added `test/receipt_text_quality_contract_test.dart` for noisy fuel OCR,
  maintenance-service receipts, privacy/admin tender-row risk, and line-item
  false-positive guards.

Verification:
- `dart format
  lib/shared/receipts/receipt_text_quality_contract.dart
  tool/receipt_qa_runner.dart
  test/receipt_text_quality_contract_test.dart` passed.
- `dart analyze
  lib/shared/receipts/receipt_text_quality_contract.dart
  tool/receipt_qa_runner.dart
  test/receipt_text_quality_contract_test.dart` passed.
- `flutter test test/receipt_text_quality_contract_test.dart -r compact`
  passed 4 tests.
- `dart run tool/receipt_qa_runner.dart --pack=maintenance --json` produced a
  100% maintenance fixture score and still exited non-zero for the known
  intentional blocker that production parser/OCR code is not pure-Dart-ready.

Intermediate failures fixed:
- The first analyzer/test/runner attempt failed because the new files imported
  `package:maintainiac/...` instead of the actual package name
  `package:maintaniac/...`. The import was corrected and the exact focused
  analyzer/test checks passed afterward.

Line counts:
- `lib/shared/receipts/receipt_text_quality_contract.dart`: 147 lines.
- `tool/receipt_qa_runner.dart`: 377 lines.
- `test/receipt_text_quality_contract_test.dart`: 69 lines.

Known follow-up:
- Continue extracting real production parser/OCR line-role and amount recovery
  logic into pure Dart libraries so `tool/receipt_qa_runner.dart` can score the
  app implementation instead of stopping at the Flutter-bound blocker.
