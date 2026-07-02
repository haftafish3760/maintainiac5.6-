# Receipt Camera Cleanup Pass Log Archive

Archived pass entries from `receipt_camera_cleanup_pass_log.md`. This file covers physical log order from pass 047 to pass 062.

## Pass 047 - 23:36:38 EDT to 23:39:53 EDT

Scope:
- Strengthened `tool/receipt_qa_runner.dart` beyond the first 5 synthetic
  fixtures.
- Added explicit expected-date, expected-total, and expected-bottom-coverage
  fixture controls so incomplete receipt sections can be tested honestly.
- Added a business/personal allocation reconciliation dimension to catch line
  totals that drift after parsing.
- Added long-receipt fixtures for a top section missing bottom totals and a
  bottom section that has totals without repeating the receipt date.

Verification:
- `dart format tool/receipt_qa_runner.dart` completed cleanly.
- `tool/receipt_qa_runner.dart` is 488 lines, still under the 500-line rule.
- `dart analyze tool/receipt_qa_runner.dart
  tool/maintainiac_source_audit.dart` passed with no issues.
- `dart run tool/receipt_qa_runner.dart --fail-under=0.90 --json` passed with
  7 fixtures, 100.0% score, and 1.0 scores for capture, OCR text, production
  parser, business/personal, parser, privacy/admin, device/storage, and
  maintenance dimensions.
- `bash tool/receipt_quality_gate.sh` passed end to end with the 7-fixture QA
  runner, Android native Kotlin compile, and 22 focused Flutter receipt tests.

Known follow-up:
- Consider moving fixture definitions out of `tool/receipt_qa_runner.dart` if
  the pure Dart QA pack needs more than a few additional cases, because the
  runner is now close to the 500-line cap.
## Pass 048 - 23:39:53 EDT to 01:18:15 EDT

Scope:
- Split the pure Dart receipt QA fixtures out of
  `tool/receipt_qa_runner.dart` into `tool/receipt_qa_fixtures.dart` so the
  runner has room to grow without violating the 500-line file cap.
- Updated `tool/receipt_quality_gate.sh` so the analyzer explicitly covers the
  fixture file as well as the runner.

Verification:
- `dart format tool/receipt_qa_runner.dart tool/receipt_qa_fixtures.dart`
  completed cleanly.
- `tool/receipt_qa_runner.dart` is now 377 lines and
  `tool/receipt_qa_fixtures.dart` is 114 lines.
- `dart analyze tool/receipt_qa_runner.dart tool/receipt_qa_fixtures.dart
  tool/maintainiac_source_audit.dart` passed with no issues.
- `dart run tool/receipt_qa_runner.dart --fail-under=0.90` passed with 7
  fixtures at 100.0%.
- `bash tool/receipt_quality_gate.sh` passed after the split, including the
  7-fixture QA runner, Android native Kotlin compile, and 22 focused Flutter
  receipt tests.
- After adding the fixture file to the quality-gate analyzer list, lightweight
  verification passed: `bash -n`, targeted Dart analyzer, `git diff --check`,
  and line counts. The full Gradle/Flutter gate was not rerun again because no
  checked source behavior changed after the previous successful full gate.

Known follow-up:
- Keep expanding the fixture file rather than the runner when adding more
  receipt/OCR scenarios.
## Pass 049 - 01:18:15 EDT to 01:19:52 EDT

Scope:
- Tightened the long-receipt photo review retake contract so the order tool
  names the exact selected section instead of using only top/middle/bottom
  shorthand.
- Added a separate semantic retake label so compact icon buttons can stay short
  while assistive/accessibility text still says whether the selected section is
  top, middle, or bottom.

Verification:
- `dart format` completed cleanly for the touched receipt photo review files
  and the long-receipt guidance test.
- Touched files remain under 500 lines:
  `receipt_photo_review_section_labels.dart` 102,
  `receipt_photo_review_order_controls.dart` 291,
  `receipt_photo_review_context_controls.dart` 209, and
  `receipt_camera_long_receipt_guidance_test.dart` 296.
- `dart analyze` over the touched files passed with no issues.
- `flutter test test/receipt_camera_long_receipt_guidance_test.dart -r compact`
  passed.

Known follow-up:
- Add behavioral widget coverage for tapping retake on section 2/3/4 once the
  retake camera flow itself is the next cleanup target.
## Pass 050 - 01:19:52 EDT to 01:21:04 EDT

Scope:
- Added explicit long-receipt source-contract coverage for the retake-by-section
  flow.
- Protected the behavior that retake captures the selected target photo path
  before opening the camera, uses the previous section as the ghost guide when
  available, restores the selected index to the same slot, replaces that slot
  with the first new photo, and inserts any additional captured photos after the
  replaced section.

Verification:
- `dart format test/receipt_camera_long_receipt_guidance_test.dart` completed
  cleanly.
- `test/receipt_camera_long_receipt_guidance_test.dart` is 316 lines.
- `dart analyze test/receipt_camera_long_receipt_guidance_test.dart` passed
  with no issues.
- `flutter test test/receipt_camera_long_receipt_guidance_test.dart -r compact`
  passed.

Known follow-up:
- Add true widget/integration coverage for the retake flow when the camera
  picker can be injected or faked without launching native UI.
## Pass 051 - 01:21:04 EDT to 01:24:23 EDT

Scope:
- Added dirty-lens warning as a first-class native receipt camera setting and
  bridge argument.
- Added the `dirty_lens_warning` descriptor as an advanced receipt guidance
  toggle so the camera settings contract does not forget that this warning must
  be user-controllable.
- Propagated `dirtyLensWarningEnabled` from Dart settings through the native
  method-channel argument map into Android and iOS argument parsing.
- Included dirty-lens warnings in the Android and iOS receipt guidance warnings
  master switch.

Verification:
- `dart format` completed cleanly for the touched Dart test/source files.
- Touched source/test files remain under 500 lines; the targeted source audit
  passed over 15 files.
- `dart analyze` over the touched Dart sources and tests passed with no issues.
- Focused Flutter tests passed:
  `test/receipt_native_camera_contract_test.dart`,
  `test/receipt_native_camera_service_basics_test.dart`,
  `test/receipt_native_android_bridge_analysis_exposure_test.dart`,
  `test/receipt_native_ios_bridge_analysis_exposure_test.dart`,
  `test/receipt_native_android_bridge_settings_quality_test.dart`, and
  `test/receipt_native_ios_bridge_settings_close_test.dart`.
- `bash tool/android_receipt_camera_compile_gate.sh` passed after the Kotlin
  argument parsing changes.
- `git diff --check` passed.

Known follow-up:
- This pass adds the dirty-lens setting/transport contract. It does not yet add
  a real dirty-lens detection algorithm, threshold tuning, or user-facing
  warning copy from live frame analysis.
## Pass 052 - 01:24:23 EDT to 01:27:16 EDT

Scope:
- Fixed the dirty-lens warning routing gap in native live analysis setup. Android
  and iOS now keep video analysis enabled when dirty-lens is the only active
  receipt readability warning.
- Added a bounded live `dirty_lens_or_haze` readability signal on Android and
  iOS using the existing live luma grid, adequate brightness, low contrast, and
  steady-frame checks.
- Added user-facing native guidance copy for possible lens smudge/haze and made
  the guidance reset once the frame returns to a clear lighting state.
- Strengthened Android and iOS source-contract tests so dirty-lens analysis
  routing and guidance copy cannot silently disappear again.

Verification:
- `dart format` completed cleanly for the touched Dart tests.
- Touched source/test files remain under 500 lines; Android
  `ReceiptCameraAnalysis.kt` is 493 lines after the change.
- `flutter test test/receipt_native_android_bridge_analysis_exposure_test.dart
  test/receipt_native_ios_bridge_analysis_exposure_test.dart` passed.
- `bash tool/android_receipt_camera_compile_gate.sh` passed.
- `dart run tool/maintainiac_source_audit.dart` passed over the five touched
  files.
- `git diff --check` passed.

Known follow-up:
- The dirty-lens signal is intentionally a conservative live heuristic, not a
  calibrated ML-quality detector. It needs real-device fixture/photo validation
  before we treat it as tuned.
## Pass 053 - 01:27:40 EDT to 01:28:39 EDT

Scope:
- Carried the new `dirty_lens_or_haze` native readability signal into the Dart
  saved-photo review warning mapper.
- Added a `saved_photo_dirty_lens_or_haze` warning with privacy-safe review
  copy, action code, and OCR/parser risk code so hazy captures do not look clean
  to the receipt review layer.
- Guarded the warning so a captured photo with strong edge detail can clear the
  live dirty-lens warning instead of forcing unnecessary retakes.
- Added direct unit coverage for warning code, cause code, action code, and
  parser-risk handoff.

Verification:
- `dart format` completed cleanly for the touched Dart source/test files.
- Touched source/test files remain under 500 lines:
  `receipt_native_saved_photo_warning.dart` 360 lines and
  `receipt_camera_result_native_quality_test.dart` 339 lines.
- `flutter test test/receipt_camera_result_native_quality_test.dart` passed.
- `dart run tool/maintainiac_source_audit.dart` passed over the two touched
  files.
- `git diff --check` passed.

Known follow-up:
- This pass wires review/metadata behavior for the dirty-lens signal. Real
  threshold confidence still depends on fixture and real-device validation.
## Pass 054 - 01:29:00 EDT to 01:30:21 EDT

Scope:
- Split Android saved-photo quality signal helpers out of the maxed-out
  `ReceiptCameraPhotoQuality.kt` file into
  `ReceiptCameraPhotoQualitySignals.kt`.
- Kept behavior unchanged while reducing the original file from the 500-line
  ceiling to a safer size for future repairs.

Verification:
- Line counts after split:
  `ReceiptCameraPhotoQuality.kt` 365 lines and
  `ReceiptCameraPhotoQualitySignals.kt` 136 lines.
- `bash tool/android_receipt_camera_compile_gate.sh` passed.
- `dart run tool/maintainiac_source_audit.dart` passed over the two touched
  Android Kotlin files.
- `git diff --check` passed.

Known follow-up:
- The Android photo-quality file is now safe to extend later. The iOS photo
  quality file is 414 lines and should be watched before adding larger logic.
## Pass 055 - 01:30:21 EDT to 01:31:37 EDT

Scope:
- Split Android live-readability luma helpers out of
  `ReceiptCameraAnalysis.kt` into `ReceiptCameraLiveReadabilitySignals.kt`.
- Moved `sampleLiveLumaGrid`, `evaluateLiveMotion`, and `estimateShadowScore`
  without changing thresholds or behavior.
- Reduced the analysis file that was touched for dirty-lens work from 493 lines
  to a safer size for future camera repairs.

Verification:
- Line counts after split:
  `ReceiptCameraAnalysis.kt` 438 lines and
  `ReceiptCameraLiveReadabilitySignals.kt` 58 lines.
- `bash tool/android_receipt_camera_compile_gate.sh` passed.
- `dart run tool/maintainiac_source_audit.dart` passed over the two touched
  Android Kotlin files.
- `git diff --check` passed.

Known follow-up:
- `ReceiptCameraReviewSettings.kt` is still close to the 500-line ceiling at
  492 lines and should be split before adding more Android settings behavior.
## Pass 056 - 01:31:53 EDT to 01:32:49 EDT

Scope:
- Split Android receipt camera settings row/view helpers out of
  `ReceiptCameraReviewSettings.kt` into `ReceiptCameraSettingsViews.kt`.
- Moved `settingSwitch`, `settingSummary`, and `settingChoiceGroup` without
  changing settings behavior.
- Reduced the Android review/settings file that was sitting near the line limit
  from 492 lines to a safer size.

Verification:
- Line counts after split:
  `ReceiptCameraReviewSettings.kt` 385 lines and
  `ReceiptCameraSettingsViews.kt` 117 lines.
- `bash tool/android_receipt_camera_compile_gate.sh` passed.
- `dart run tool/maintainiac_source_audit.dart` passed over the two touched
  Android Kotlin files.
- `git diff --check` passed.

Known follow-up:
- Continue watching `ReceiptCameraControls.kt`, which is still near the line
  ceiling, before adding more Android control behavior.
## Pass 057 - 01:32:49 EDT to 01:34:43 EDT

Scope:
- Split Android exposure and brightness-assist controls out of
  `ReceiptCameraControls.kt` into `ReceiptCameraExposureControls.kt`.
- Moved exposure slider setup, manual brightness changes, auto brightness
  assist, brightness buckets, and exposure outcome helpers without changing
  behavior.
- Reduced the Android controls file from a near-limit 486 lines to a much safer
  size.

Verification:
- Line counts after split:
  `ReceiptCameraControls.kt` 259 lines and
  `ReceiptCameraExposureControls.kt` 228 lines.
- `bash tool/android_receipt_camera_compile_gate.sh` passed.
- `dart run tool/maintainiac_source_audit.dart` passed over the two touched
  Android Kotlin files.
- `git diff --check` passed.

Known follow-up:
- Continue with Dart-side receipt/OCR QA and real-device/fixture validation for
  the dirty-lens and photo-quality heuristics.
## Pass 058 - 01:34:43 EDT to 01:37:12 EDT

Scope:
- Split Dart photo-review crop controls out of
  `receipt_photo_review_crop_and_proof_controls.dart` into
  `receipt_photo_review_crop_controls.dart`.
- Added the new part to `receipt_photo_review_screen.dart`.
- Updated the source-contract test so proof-lane assertions still read the proof
  controls file while crop-mode assertions read the new crop controls file.

Verification:
- First targeted test run failed because the source-contract test still looked
  for crop widgets in the old file. That failure was fixed immediately before
  moving on.
- Final `dart analyze` over the touched photo-review files and test passed with
  no issues.
- Final `flutter test test/receipt_photo_review_controls_layout_test.dart`
  passed.
- Touched source/test files remain under 500 lines:
  `receipt_photo_review_crop_and_proof_controls.dart` 282 lines,
  `receipt_photo_review_crop_controls.dart` 201 lines, and
  `receipt_photo_review_controls_layout_test.dart` 337 lines.
- `dart run tool/maintainiac_source_audit.dart` passed over the four touched
  files.
- `git diff --check` passed.

Known follow-up:
- Continue reducing remaining near-limit Dart receipt/OCR files before adding
  large review, OCR-source, or admin diagnostics behavior.
## Pass 059 - 01:37:12 EDT to 01:39:35 EDT

Scope:
- Split client-proof/privacy redaction OCR handoff maps out of
  `receipt_ocr_parser_handoff_lines.dart` into
  `receipt_ocr_parser_handoff_proof.dart`.
- Added the new part to `receipt_ocr_contract.dart`.
- Kept behavior unchanged while separating general OCR line maps from
  privacy-safe client-proof contract maps.

Verification:
- `dart format` completed cleanly for the touched OCR contract files.
- `dart analyze` over the touched OCR contract files passed with no issues.
- Focused Flutter tests passed:
  `test/receipt_ocr_service_read_warnings_test.dart`,
  `test/expense_receipt_parser_direct_parity_test.dart`, and
  `test/expense_receipt_parser_ocr_handoff_test.dart`.
- Touched source files remain under 500 lines:
  `receipt_ocr_parser_handoff_lines.dart` 367 lines,
  `receipt_ocr_parser_handoff_proof.dart` 116 lines, and
  `receipt_ocr_contract.dart` 22 lines.
- `dart run tool/maintainiac_source_audit.dart` passed over the three touched
  files.
- `git diff --check` passed.

Known follow-up:
- Continue shrinking remaining near-limit OCR/storage files, especially
  `receipt_proof_storage.dart`, `receipt_ocr_service.dart`, and
  `receipt_ocr_parser_handoff_tasks.dart`, before adding larger behavior.
## Pass 060 - 01:39:35 EDT to 01:41:14 EDT

Scope:
- Split receipt proof storage helper and rollback logic out of
  `receipt_proof_storage.dart` into `receipt_proof_storage_helpers.dart`.
- Kept the public `ReceiptProofStorage` API unchanged while separating storage
  root, hash/length, rollback, validation, and low-storage helper logic.
- Reduced the near-limit proof storage file from 479 lines to a safer size for
  future original/proof image handling work.

Verification:
- `dart format` completed cleanly for the touched proof storage files.
- `dart analyze` over the touched proof storage files passed with no issues.
- Focused storage lifecycle tests passed:
  `test/receipt_proof_storage_lifecycle_test.dart`,
  `test/receipt_pdf_torture_storage_test.dart`, and
  `test/expense_draft_store_proof_recovery_test.dart`.
- The PDF fixture generator emitted repeated Helvetica font warnings during the
  tests, but the test process exited successfully.
- Touched source files remain under 500 lines:
  `receipt_proof_storage.dart` 318 lines and
  `receipt_proof_storage_helpers.dart` 156 lines.
- `dart run tool/maintainiac_source_audit.dart` passed over the two touched
  files.
- `git diff --check` passed.

Known follow-up:
- Continue with `receipt_ocr_service.dart` and
  `receipt_ocr_parser_handoff_tasks.dart`, which are still near the line limit
  and central to OCR/parser QA.
## Pass 061 - 01:41:14 EDT to 01:42:43 EDT

Scope:
- Split long-receipt OCR text combining and overlap dedupe logic out of
  `receipt_ocr_service.dart` into `receipt_ocr_service_text_combiner.dart`.
- Kept ML Kit photo OCR and PDF OCR behavior unchanged while isolating the
  multi-section parser text preparation logic.
- Reduced the local OCR service file from 464 lines to a safer size.

Verification:
- `dart format` completed cleanly for the touched OCR service files.
- `dart analyze` over the touched OCR service files passed with no issues.
- Focused Flutter tests passed:
  `test/receipt_ocr_service_read_warnings_test.dart`,
  `test/receipt_ocr_service_long_receipt_diagnostics_test.dart`,
  `test/receipt_ocr_service_source_handoff_test.dart`, and
  `test/receipt_ocr_service_test.dart`.
- Touched source files remain under 500 lines:
  `receipt_ocr_service.dart` 353 lines and
  `receipt_ocr_service_text_combiner.dart` 112 lines.
- `dart run tool/maintainiac_source_audit.dart` passed over the two touched
  files.
- `git diff --check` passed.

Known follow-up:
- `receipt_ocr_parser_handoff_tasks.dart` remains near the line limit and
  should be split before adding more parser handoff QA behavior.
## Pass 062 - 01:42:43 EDT to 01:44:19 EDT

Scope:
- Split the privacy-safe OCR parser handoff contract payload out of
  `receipt_ocr_parser_handoff_tasks.dart` into
  `receipt_ocr_parser_handoff_contract.dart`.
- Added the new part to `receipt_ocr_contract.dart`.
- Kept parser task/count behavior unchanged while separating the admin/privacy
  contract map from parser task computation.

Verification:
- `dart format` completed cleanly for the touched OCR contract files.
- `dart analyze` over the touched OCR contract files passed with no issues.
- Focused Flutter tests passed:
  `test/receipt_ocr_service_parser_handoff_structure_test.dart`,
  `test/receipt_ocr_service_parser_diagnostics_summary_test.dart`,
  `test/receipt_ocr_service_material_vendor_test.dart`, and
  `test/receipt_ocr_service_fuel_unknown_test.dart`.
- Touched source files remain under 500 lines:
  `receipt_ocr_parser_handoff_tasks.dart` 371 lines,
  `receipt_ocr_parser_handoff_contract.dart` 94 lines, and
  `receipt_ocr_contract.dart` 23 lines.
- `dart run tool/maintainiac_source_audit.dart` passed over the three touched
  files.
- `git diff --check` passed.

Known follow-up:
- Re-run the receipt scoped line-limit scan and continue with the next
  production OCR/camera file or QA guardrail gap.
