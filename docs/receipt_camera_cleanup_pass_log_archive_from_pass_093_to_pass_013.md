# Receipt Camera Cleanup Pass Log Archive

Archived pass entries from `receipt_camera_cleanup_pass_log.md`. This file covers physical log order from pass 093 to pass 013.

## Pass 093 - 03:00:12 EDT to 03:00:59 EDT

Scope:
- Tightened admin diagnostic OCR failure evidence so `target_...` values are
  reduced to a controlled safe bucket list before telemetry metadata is emitted.
- Unknown or private-looking target evidence now becomes `target_unknown`
  instead of preserving arbitrary merchant, order, user, or receipt hints.
- Added a regression test with private receipt target evidence proving the admin
  metadata keeps useful warning/source buckets while dropping private target
  clues.

Verification:
- `flutter test test/expense_admin_diagnostic_contract_test.dart -r compact`
  passed.
- `dart analyze` over the admin diagnostic contract/test and telemetry policy
  files passed with no issues.
- `dart run tool/maintainiac_source_audit.dart` passed over the touched admin
  diagnostic/telemetry scope.
- `git diff --check` passed.
- Touched files remain under 500 lines:
  `expense_admin_diagnostic_contract.dart` 197 lines,
  `expense_admin_diagnostic_contract_test.dart` 213 lines,
  `expense_screen_telemetry.dart` 12 lines,
  `expense_screen_telemetry_policy.dart` 484 lines, and
  `expense_screen_telemetry_policy_keys.dart` 28 lines.

Known follow-up:
- Continue hardening admin diagnostic artifact flow so redacted quality-preview
  evidence can help diagnose OCR failures without uploading raw receipt data.
## Pass 092 - 02:58:48 EDT to 02:59:22 EDT

Scope:
- Strengthened the photo-review lifecycle guard for retaking a receipt section.
- The guard now proves retake captures the target photo path before async camera
  work, recomputes the current target index after the picker returns, replaces
  that slot with the first retaken image, and inserts any extra retaken images
  immediately after the selected section.
- This protects long-receipt middle-section retakes from silently scrambling
  photo order or downstream OCR-source order.

Verification:
- `flutter test test/receipt_photo_review_async_lifecycle_test.dart -r compact`
  passed.
- `dart analyze` over the touched lifecycle test and review action source files
  passed with no issues.
- `dart run tool/maintainiac_source_audit.dart` passed over the touched review
  lifecycle scope.
- `git diff --check` passed.
- Touched files remain under 500 lines:
  `receipt_photo_review_async_lifecycle_test.dart` 381 lines,
  `receipt_photo_review_capture_actions.dart` 347 lines,
  `receipt_photo_review_save_actions.dart` 286 lines, and
  `receipt_photo_review_image_edit_actions.dart` 241 lines.

Known follow-up:
- Continue adding executable guards for original-image OCR handoff and admin
  diagnostic evidence so camera failures are debuggable without private user
  data.
## Pass 091 - 02:57:37 EDT to 02:58:24 EDT

Scope:
- Tightened the long-receipt review context controls so the retake action uses
  the selected receipt section number, matching the order-mode controls.
- The contextual review row now shows labels such as `Retake Section 2` instead
  of a vague `Retake` action when multiple receipt photos are being reviewed.
- Added a source guard so both the context controls and order controls continue
  using `_ReceiptPhotoSectionLabels.retakeLabel`.

Verification:
- `flutter test test/receipt_photo_section_labels_test.dart -r compact` passed.
- `dart analyze` over the touched context controls, section labels, and label
  test passed with no issues.
- `dart run tool/maintainiac_source_audit.dart` passed over the touched
  review-label scope.
- `git diff --check` passed.
- Touched files remain under 500 lines:
  `receipt_photo_review_context_controls.dart` 212 lines,
  `receipt_photo_review_section_labels.dart` 102 lines, and
  `receipt_photo_section_labels_test.dart` 56 lines.

Known follow-up:
- Continue guarding retake insertion/order behavior, especially replacement of
  a middle photo and preservation of original OCR-source ordering.
## Pass 090 - 02:53 EDT to 02:56:53 EDT

Scope:
- Added downstream Dart stitch-preview coverage proving
  `ReceiptImageProcessor.stitchReceiptPhotosForOcr` honors
  `maxOutputPixels` before writing a stitched OCR artifact.
- The new receipt-stitching fixture asserts oversized pixel output falls back
  with `output_too_large`, preserves the original section paths for OCR, reports
  attempted output dimensions/pixels, and does not create a stitched file.
- Continued keeping stitching fixtures in
  `test/helpers/receipt_stitching_image_helpers.dart` so the test file stays
  below the 500-line source cap.

Verification:
- `flutter test test/receipt_stitching_test.dart -r compact` passed.
- `dart analyze test/receipt_stitching_test.dart
  lib/shared/widgets/receipt_capture/receipt_image_processor.dart` passed.
- `dart run tool/maintainiac_source_audit.dart` passed over the touched
  receipt-stitching test/helper/source scope.
- `git diff --check` passed.
- Touched files remain under 500 lines:
  `receipt_stitching_test.dart` 425 lines,
  `receipt_stitching_image_helpers.dart` 142 lines,
  `receipt_image_processor.dart` 371 lines,
  `receipt_image_processor_stitch_api.dart` 170 lines, and
  `receipt_image_processor_stitch_helpers.dart` 279 lines.

Known follow-up:
- Continue tightening the long-receipt review path so UI retakes, section
  ordering, and original-image OCR handoff stay guarded by executable tests.
## Pass 089 - 02:52 EDT to 02:53:22 EDT

Scope:
- Added native bridge source guards proving Android and iOS read stitch output
  caps from launch arguments before reporting them in diagnostics.
- Android coverage now checks `maxStitchOutputPixels` and
  `maxStitchOutputHeight` are read from `Intent` extras with safe non-negative
  coercion.
- iOS coverage now checks the same values are read from Flutter arguments with
  safe non-negative coercion.

Verification:
- `flutter test test/receipt_native_android_bridge_analysis_exposure_test.dart
  test/receipt_native_ios_bridge_settings_close_test.dart -r compact` passed.
- `dart analyze` over the two touched bridge tests and source-reader helpers
  passed.
- `dart run tool/maintainiac_source_audit.dart` passed over the touched
  native-bridge test/source scope.
- `git diff --check` passed.
- Touched files remain under 500 lines:
  `receipt_native_android_bridge_analysis_exposure_test.dart` 412 lines,
  `receipt_native_ios_bridge_settings_close_test.dart` 422 lines,
  `ReceiptCameraSessionArguments.kt` 197 lines, and
  `ReceiptCameraViewControllerSessionArguments.swift` 135 lines.

Known follow-up:
- Continue tightening native result diagnostics and Dart stitch preview tests so
  downstream review honors these caps for generated previews/results.
## Pass 088 - 02:51 EDT to 02:52:07 EDT

Scope:
- Strengthened native camera storage/channel coverage so stitch output caps are
  verified at the launch-argument layer, not only on the Dart capability model.
- Added explicit assertions that maximum-storage sessions send stitch limits to
  native code.
- Added an older-phone channel test proving native launch arguments receive:
  light device tier, four-section cap, disabled auto-capture, light workload,
  6 MB local-photo cap, 9 MP stitch cap, 14k stitch-height cap, cloud OCR
  optional status, and original-first OCR policy.

Verification:
- `flutter test test/receipt_native_camera_storage_contract_test.dart
  -r compact` passed.
- `dart analyze test/receipt_native_camera_storage_contract_test.dart
  lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart
  lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart` passed.
- `dart run tool/maintainiac_source_audit.dart` passed over the touched native
  camera storage-contract scope.
- `git diff --check` passed.
- Touched files remain under 500 lines:
  `receipt_native_camera_storage_contract_test.dart` 352 lines,
  `receipt_native_camera_service.dart` 401 lines, and
  `receipt_native_camera_session_config.dart` 350 lines.

Known follow-up:
- Add equivalent assertion coverage in Android/iOS source-reader tests that the
  native implementations consume `maxStitchOutputPixels` and
  `maxStitchOutputHeight` when producing stitched previews/results.
## Pass 087 - 02:49 EDT to 02:50:42 EDT

Scope:
- Added `ExpenseAdminDiagnosticArtifact.fromOcrFailure` so admin diagnostic
  metadata can join OCR failure cause, failure stage, compact safe evidence,
  quality buckets, device tier, OS bucket, app version bucket, storage bucket,
  and redacted-image-preview eligibility.
- Added metadata policy keys for the admin confirmed cause, failed-at stage,
  and compact evidence token.
- Extended `expense_admin_diagnostic_contract_test.dart` with a snapshot-style
  OCR failure case that starts from `ExpenseOcrFailureDiagnostics`, builds the
  admin artifact, and proves the metadata has useful failure/device/quality
  evidence without raw receipt text, private prices, or attachment ids.

Verification:
- `flutter test test/expense_admin_diagnostic_contract_test.dart -r compact`
  passed.
- `dart analyze lib/screens/expenses/data/expense_admin_diagnostic_contract.dart
  lib/screens/expenses/data/expense_ocr_failure_diagnostics.dart
  lib/screens/expenses/data/expense_screen_telemetry.dart
  test/expense_admin_diagnostic_contract_test.dart` passed.
- `dart run tool/maintainiac_source_audit.dart` passed over the touched admin,
  OCR failure, telemetry policy, policy-key, and test files.
- `git diff --check` passed.
- Touched files remain under 500 lines:
  `expense_admin_diagnostic_contract.dart` 177 lines,
  `expense_ocr_failure_diagnostics.dart` 159 lines,
  `expense_screen_telemetry_policy.dart` 484 lines,
  `expense_screen_telemetry_policy_keys.dart` 28 lines, and
  `expense_admin_diagnostic_contract_test.dart` 179 lines.

Intermediate failures fixed:
- The first admin snapshot test failed because raw OCR diagnostic evidence was
  too long for telemetry token policy. Fixed by bucketizing evidence into a
  compact `warning_*_source_*_target_*` token.
- The next test failed because it blocked the word `private`, which appears in
  the safe `redacted_private_regions` policy token. Fixed the assertion to block
  actual receipt content instead.

Known follow-up:
- Add fixture-backed redacted image-preview generation/cropping tests when the
  image redaction implementation lands.
## Pass 086 - 02:46 EDT to 02:48:49 EDT

Scope:
- Strengthened admin diagnostic artifacts with privacy-safe device context:
  device tier, OS family, OS version bucket, app version bucket, and storage
  safety bucket.
- Extended telemetry metadata policy to allow those admin diagnostic buckets
  while explicitly blocking raw `deviceId`, `rawDeviceId`, `deviceModel`, and
  `rawDeviceModel` keys.
- Split the telemetry sensitive-key denylist into
  `expense_screen_telemetry_policy_keys.dart` so the main telemetry policy part
  stays below the 500-line source cap.

Verification:
- `flutter test test/expense_admin_diagnostic_contract_test.dart -r compact`
  passed.
- `dart analyze lib/screens/expenses/data/expense_admin_diagnostic_contract.dart
  lib/screens/expenses/data/expense_screen_telemetry.dart
  test/expense_admin_diagnostic_contract_test.dart` passed.
- `dart run tool/maintainiac_source_audit.dart` passed over the touched admin
  diagnostic, telemetry policy, policy-key, and test files.
- `git diff --check` passed.
- Touched files remain under 500 lines:
  `expense_admin_diagnostic_contract.dart` 108 lines,
  `expense_screen_telemetry.dart` 12 lines,
  `expense_screen_telemetry_policy.dart` 481 lines,
  `expense_screen_telemetry_policy_keys.dart` 28 lines, and
  `expense_admin_diagnostic_contract_test.dart` 126 lines.

Intermediate failure fixed:
- The first source audit failed because adding admin device-context keys pushed
  `expense_screen_telemetry_policy.dart` to 506 lines. Fixed by moving the
  telemetry sensitive-key denylist into its own part file.

Known follow-up:
- Add admin diagnostic snapshot fixtures that join OCR failure cause, safe
  device context, quality buckets, and redacted image-preview eligibility.
## Pass 085 - 02:44 EDT to 02:46:26 EDT

Scope:
- Added `test/receipt_qa_runner_contract_test.dart` to protect the pure Dart
  receipt QA runner contract.
- The new test executes `dart run tool/receipt_qa_runner.dart
  --fail-under=0.90 --json` and verifies the JSON report includes required
  dimensions, key long-receipt and maintenance fixtures, no blockers, and 90%+
  scores for the runner, every fixture, and every dimension.
- Updated `docs/receipt_camera_world_class_qa_standard.md` so it reflects the
  current runner state: production parser scoring is active through pure Dart
  entry points, and the remaining work is fixture expansion and stricter
  scoring rather than an intentional runner blocker.

Verification:
- `flutter test test/receipt_qa_runner_contract_test.dart -r compact` passed.
- `dart run tool/receipt_qa_runner.dart --fail-under=0.90 --json` passed with
  seven fixtures, all required dimensions at 100%, and no blockers.
- `dart run tool/receipt_qa_runner.dart --pack=long_receipt --fail-under=0.90
  --json` passed with the two long-receipt continuation fixtures.
- `dart analyze test/receipt_qa_runner_contract_test.dart
  tool/receipt_qa_runner.dart tool/receipt_qa_fixtures.dart` passed.
- `dart run tool/maintainiac_source_audit.dart` passed over the touched runner,
  fixture, test, and QA-standard doc scope.
- `git diff --check` passed.
- Touched files remain under 500 lines:
  `receipt_qa_runner_contract_test.dart` 70 lines,
  `receipt_qa_runner.dart` 377 lines,
  `receipt_qa_fixtures.dart` 114 lines, and
  `receipt_camera_world_class_qa_standard.md` 123 lines.

Known follow-up:
- Expand runner fixtures into versioned external packs, add per-field
  false-positive/privacy scoring, and add admin diagnostic snapshots.
## Pass 084 - 02:39 EDT to 02:44:12 EDT

Scope:
- Confirmed the receipt-scoped source audit now has zero files over the
  500-line cap.
- Added a focused fixture QA guard in
  `receipt_image_ocr_source_guard_test.dart` proving OCR source preparation
  preserves the original-quality receipt image bytes when scanner cleanup is
  disabled.
- Kept the new test in a descriptive standalone file instead of pushing
  `receipt_image_data_saver_test.dart` over the file-size rule.

Verification:
- `flutter test test/receipt_image_data_saver_test.dart
  test/receipt_image_ocr_source_guard_test.dart -r compact` passed.
- Focused rerun of
  `flutter test test/receipt_image_ocr_source_guard_test.dart -r compact`
  passed after import cleanup.
- `dart analyze test/receipt_image_data_saver_test.dart
  test/receipt_image_ocr_source_guard_test.dart` passed with no issues.
- `dart run tool/maintainiac_source_audit.dart` passed over the touched image
  QA and receipt image processor scope.
- `git diff --check` passed.
- Touched test/source files remain under 500 lines:
  `receipt_image_data_saver_test.dart` 453 lines and
  `receipt_image_ocr_source_guard_test.dart` 64 lines.

Intermediate failures fixed:
- The first source audit failed because the new QA case made
  `receipt_image_data_saver_test.dart` 508 lines. Fixed by moving the new guard
  into `receipt_image_ocr_source_guard_test.dart`.
- The first analyze rerun reported an unused import in the new guard test.
  Removed the import and reran analyze cleanly.

Known follow-up:
- Continue adding fixture-driven QA for multi-photo long receipt coverage,
  bottom-edge/total continuation signals, and native dirty-lens/glare handoff.
## Pass 083 - 02:34:28 EDT to 02:38:59 EDT

Scope:
- Split captured-photo quality sampling out of
  `ReceiptCameraViewControllerPhotoQuality.swift` into
  `ReceiptCameraViewControllerPhotoQualitySampling.swift`.
- Wired the new Swift source file into `ios/Runner.xcodeproj/project.pbxproj`
  so the iOS Runner target compiles it.
- Kept the native receipt camera quality behavior unchanged while reducing the
  photo-quality controller file to a smaller ownership boundary.

Verification:
- Focused Flutter bridge tests passed:
  `test/receipt_native_ios_bridge_test.dart`,
  `test/receipt_native_ios_bridge_analysis_exposure_test.dart`,
  `test/receipt_native_ios_bridge_long_receipt_quality_test.dart`,
  `test/receipt_native_ios_bridge_settings_close_test.dart`, and
  `test/receipt_camera_native_bridge_layout_test.dart`.
- `plutil -lint ios/Runner.xcodeproj/project.pbxproj` passed.
- A Ruby project reference check confirmed the sampling file is present in the
  Xcode sources list.
- Direct `xcodebuild -project ios/Runner.xcodeproj ...` failed with
  `Module 'device_info_plus' not found`, which is the wrong build entry for the
  Flutter iOS plugin graph.
- Correct workspace build passed:
  `xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration
  Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator'
  CODE_SIGNING_ALLOWED=NO build`.
- Touched source files remain under 500 lines:
  `ReceiptCameraViewControllerPhotoQuality.swift` 303 lines and
  `ReceiptCameraViewControllerPhotoQualitySampling.swift` 114 lines.
- `dart run tool/maintainiac_source_audit.dart` passed over the touched
  Swift/project/test scope.
- `git diff --check` passed.

Known follow-up:
- Continue splitting the next oversized receipt camera/OCR file, then add
  deeper fixture coverage for native photo-quality heuristics.
## Pass 012 - 2026-07-01 20:06:01 EDT

Scope:
- Started persistent pass tracking after eleven earlier cleanup/QA passes were
  already completed in this thread.
- Verified the latest small split in `expense_receipt_save_actions.dart`.
- Repaired split-aware assisted-review test coverage after moving code into
  smaller part files.

Changes in this pass:
- Added `expense_receipt_save_readiness_dialog.dart`.
- Moved the save-readiness dialog and `_ReceiptSaveReadinessIssue` model out of
  `expense_receipt_save_actions.dart`.
- Registered the new part in `expense_receipt_entry_screen.dart`.
- Wired explicit OCR and parser item-family summary labels into
  `expense_receipt_parse_review.dart`.
- Updated `expense_receipt_assisted_review_flow_test.dart` to read split receipt
  units instead of only the old monolithic files:
  - OCR service plus `receipt_ocr_*.dart` parts.
  - Photo preview controls plus quality recovery part.
  - Expense receipt save actions plus save-readiness dialog part.

Verification:
- `dart analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart`
  passed.
- `dart analyze
  test/expense_receipt_assisted_review_flow_test.dart
  lib/screens/expenses/entry/expense_receipt_entry_screen.dart` passed.
- `dart run tool/maintainiac_source_audit.dart
  lib/screens/expenses/entry/expense_receipt_save_actions.dart
  lib/screens/expenses/entry/expense_receipt_save_readiness_dialog.dart` passed.
- `flutter test test/expense_receipt_assisted_review_flow_test.dart -r compact`
  passed at 2026-07-01 20:08:12 EDT.

Intermediate failures fixed:
- The assisted-review test initially failed because it expected
  `ocrItemExpenseFamilySummaryLabel` and
  `parserItemExpenseFamilySummaryLabel` in `expense_receipt_parse_review.dart`.
- After that fix, it failed because split OCR diagnostics lived in
  `receipt_ocr_*.dart` parts while the test read only `receipt_ocr_service.dart`.
- After that fix, it failed because preview recovery controls lived in
  `receipt_photo_review_quality_recovery.dart` while the test read only
  `receipt_photo_review_preview_controls.dart`.
- After that fix, it failed because the save-readiness dialog lived in
  `expense_receipt_save_readiness_dialog.dart` while the test read only
  `expense_receipt_save_actions.dart`.
## Pass 013 - 2026-07-01 20:08:54 EDT

Scope:
- Refreshed the receipt production source audit after Pass 012.
- Confirmed the current focused receipt QA bundle after split-aware test repair.
- Split `expense_receipt_line_models.dart` below the 500-line cap.

Verification:
- `dart run tool/maintainiac_source_audit.dart` failed as expected because 27
  receipt-scope production files still exceed 500 lines.
- `flutter test
  test/receipt_native_camera_contract_test.dart
  test/receipt_ocr_service_test.dart
  test/receipt_processing_contract_test.dart
  test/expense_receipt_assisted_review_flow_test.dart -r compact` passed.
- `dart analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart`
  passed after the line-model split.
- `dart run tool/maintainiac_source_audit.dart
  lib/screens/expenses/entry/expense_receipt_line_models.dart
  lib/screens/expenses/entry/expense_receipt_line_review_actions.dart
  lib/screens/expenses/entry/expense_receipt_line_support.dart` passed.
- `flutter test
  test/expense_receipt_line_record_test.dart
  test/expense_receipt_assisted_review_flow_test.dart -r compact` passed.

Remaining audit count:
- 26 receipt-scope production files exceed 500 lines as of
  2026-07-01 20:10:47 EDT.

Changes:
- Added `expense_receipt_line_support.dart` for line-use enum, formatting,
  parsing, category names, and stock units.
- Added `expense_receipt_line_review_actions.dart` for parser-review line
  actions.
- Reduced `expense_receipt_line_models.dart` to 448 lines.
