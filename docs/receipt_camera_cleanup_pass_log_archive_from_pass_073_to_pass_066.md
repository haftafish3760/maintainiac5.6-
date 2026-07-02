# Receipt Camera Cleanup Pass Log Archive

Archived pass entries from `receipt_camera_cleanup_pass_log.md`. This file covers physical log order from pass 073 to pass 066.

## Pass 073 - 02:08:27 EDT to 02:08:48 EDT

Scope:
- Verified the photo-review alignment action split from the current worktree.
- Kept the split in place:
  `receipt_photo_review_capture_actions.dart` owns capture flow and
  `receipt_photo_review_alignment_actions.dart` owns the long-receipt alignment
  guide sheet.
- Fixed stale source-contract readers so tests inspect the full current part
  graph after the recent photo-review and assistance-policy splits.

Verification:
- Focused Flutter tests passed after reader repair:
  `test/receipt_camera_long_receipt_guidance_test.dart`,
  `test/receipt_native_shell_recovery_contract_test.dart`,
  `test/receipt_camera_ocr_source_handoff_test.dart`,
  `test/receipt_photo_review_quality_handoff_test.dart`, and
  `test/receipt_photo_review_controls_layout_test.dart`.
- `dart analyze` over the touched photo-review/test files passed with no
  issues.
- Touched source files remain under 500 lines:
  `receipt_photo_review_screen.dart` 280 lines,
  `receipt_photo_review_capture_actions.dart` 347 lines, and
  `receipt_photo_review_alignment_actions.dart` 87 lines.
- `dart run tool/maintainiac_source_audit.dart` passed over the touched
  photo-review/test files.
- `git diff --check` passed.

Known follow-up:
- Continue with the next production receipt/camera file near the line limit, or
  add fixture validation for native photo-quality heuristics.
## Pass 072 - 02:05:40 EDT to 02:07:41 EDT

Scope:
- Split the long-receipt alignment guide bottom sheet out of
  `receipt_photo_review_capture_actions.dart` into
  `receipt_photo_review_alignment_actions.dart`.
- Added the new part to `receipt_photo_review_screen.dart`.
- Updated receipt camera source-reader helpers so source-contract tests inspect
  the new alignment action part.
- Updated `test/receipt_camera_long_receipt_guidance_test.dart` to read
  `receipt_assistance_policy.dart` with its parts, preserving coverage after
  the earlier device-capability camera split.

Verification:
- `dart format` completed cleanly for the touched photo-review and test files.
- First focused test run exposed a stale source reader for assistance policy
  stitch limits; the test helper was fixed before moving on.
- Focused Flutter tests then passed:
  `test/receipt_camera_long_receipt_guidance_test.dart`,
  `test/receipt_native_shell_recovery_contract_test.dart`,
  `test/receipt_camera_ocr_source_handoff_test.dart`,
  `test/receipt_photo_review_quality_handoff_test.dart`, and
  `test/receipt_photo_review_controls_layout_test.dart`.
- `dart analyze` over the touched photo-review/test files passed with no
  issues.
- Touched source files remain under 500 lines:
  `receipt_photo_review_screen.dart` 280 lines,
  `receipt_photo_review_capture_actions.dart` 347 lines, and
  `receipt_photo_review_alignment_actions.dart` 87 lines.
- `dart run tool/maintainiac_source_audit.dart` passed over the touched
  photo-review/test files.
- `git diff --check` passed.

Known follow-up:
- Continue with the next production receipt/camera file near the line limit, or
  add fixture validation for native photo-quality heuristics.
## Pass 071 - 02:03:33 EDT to 02:05:14 EDT

Scope:
- Split the instance OCR read workflow out of `receipt_capture_flow.dart` into
  `receipt_capture_flow_ocr_helpers.dart`.
- Preserved the public static helper API
  `ReceiptCaptureFlow.readTextFromReviewResult` and
  `ReceiptCaptureFlow.attachmentsFromReviewResult` on the main class.
- Left the permission, native capture, staging, recovery, review, and accepted
  handoff transaction in `receipt_capture_flow.dart` intact.

Verification:
- `dart format` completed cleanly for the touched receipt capture flow files.
- Focused Flutter tests passed:
  `test/receipt_camera_result_stitch_scanner_test.dart`,
  `test/receipt_camera_result_native_close_settings_test.dart`,
  `test/receipt_camera_result_recovery_handoff_test.dart`, and
  `test/receipt_camera_result_native_ui_health_test.dart`.
- `dart analyze` over the two touched flow files passed with no issues.
- Touched source files remain under 500 lines:
  `receipt_capture_flow.dart` 407 lines and
  `receipt_capture_flow_ocr_helpers.dart` 33 lines.
- `dart run tool/maintainiac_source_audit.dart` passed over the two touched
  source files.
- `git diff --check` passed.

Known follow-up:
- Continue with the next production receipt/camera file near the line limit, or
  add fixture validation for native photo-quality heuristics.
## Pass 070 - 02:00:34 EDT to 02:02:29 EDT

Scope:
- Split long-receipt missing-bottom/totals evidence, ghost-slice alignment, and
  completion-confirmation helpers out of `receipt_ocr_source_handoff_review.dart`
  into `receipt_ocr_source_handoff_long_receipt.dart`.
- Added the new part to `receipt_ocr_contract.dart`.
- Kept the privacy-safe OCR source handoff contract unchanged while isolating
  the long-receipt evidence rules for easier audit.

Verification:
- `dart format` completed cleanly for the touched OCR source handoff files.
- Focused Flutter tests passed:
  `test/receipt_ocr_service_source_handoff_test.dart`,
  `test/receipt_ocr_service_long_receipt_diagnostics_test.dart`,
  `test/receipt_camera_result_completion_coverage_test.dart`,
  `test/receipt_camera_result_coverage_totals_test.dart`, and
  `test/receipt_camera_ocr_source_handoff_test.dart`.
- `dart analyze` over the touched OCR contract/source handoff files passed with
  no issues.
- Touched source files remain under 500 lines:
  `receipt_ocr_contract.dart` 24 lines,
  `receipt_ocr_source_handoff_review.dart` 265 lines, and
  `receipt_ocr_source_handoff_long_receipt.dart` 181 lines.
- `dart run tool/maintainiac_source_audit.dart` passed over the three touched
  source files.
- `git diff --check` passed.

Known follow-up:
- Continue with the next production receipt/camera file near the line limit, or
  add fixture validation for native photo-quality heuristics.
## Pass 069 - 01:57:55 EDT to 02:00:02 EDT

Scope:
- Split Android live receipt framing, edge confidence, perspective readiness,
  and frame-guide drawing out of `ReceiptCameraAnalysis.kt` into
  `ReceiptCameraFraming.kt`.
- Kept the native live analysis flow unchanged while isolating the edge
  detection/receipt visibility behavior in a purpose-specific Kotlin file.

Verification:
- Focused Flutter source-contract tests passed:
  `test/receipt_native_android_bridge_settings_quality_test.dart`,
  `test/receipt_native_android_bridge_close_controls_test.dart`, and
  `test/receipt_native_android_bridge_analysis_exposure_test.dart`.
- `tool/android_receipt_camera_compile_gate.sh` passed; Gradle completed
  `:app:compileDebugKotlin` successfully.
- Touched source files remain under 500 lines:
  `ReceiptCameraAnalysis.kt` 251 lines and `ReceiptCameraFraming.kt` 204 lines.
- `dart run tool/maintainiac_source_audit.dart` passed over the two touched
  Kotlin files.
- `git diff --check` passed.

Known follow-up:
- Continue with the next production receipt/camera file near the line limit, or
  add fixture validation for native photo-quality heuristics.
## Pass 068 - 01:55:16 EDT to 01:57:29 EDT

Scope:
- Split fallback capture and document-scanner backup handling out of
  `receipt_attachment_camera_actions.dart` into
  `receipt_attachment_camera_fallback_actions.dart`.
- Added the new part to `receipt_attachment_panel.dart`.
- Updated the receipt camera source-reader helper and source-contract test so
  it continues inspecting the full native-first camera path after the split.
- Kept the primary Maintainiac native camera path ahead of every stock
  camera/document-scanner fallback.

Verification:
- `dart format` completed cleanly for the touched attachment camera files and
  test files.
- First focused test run exposed a stale source-contract substring boundary in
  `test/receipt_camera_capture_layout_test.dart`; the app source was not moved
  forward until that was fixed.
- Focused Flutter tests then passed:
  `test/receipt_camera_capture_layout_test.dart`,
  `test/receipt_native_android_bridge_capture_flow_test.dart`,
  `test/receipt_capture_flow_handoff_contract_test.dart`, and
  `test/receipt_attachment_panel_actions_test.dart`.
- `dart analyze` over the touched source/test files passed with no issues.
- Touched source files remain under 500 lines:
  `receipt_attachment_camera_actions.dart` 278 lines,
  `receipt_attachment_camera_fallback_actions.dart` 175 lines, and
  `receipt_camera_capture_layout_source_readers.dart` 175 lines.
- `dart run tool/maintainiac_source_audit.dart` passed over the touched
  receipt camera/test-helper files.
- `git diff --check` passed.

Known follow-up:
- Continue with the next production receipt/camera file near the line limit, or
  add fixture validation for native photo-quality heuristics.
## Pass 067 - 01:53:21 EDT to 01:54:52 EDT

Scope:
- Removed duplicated OCR diagnostics label/getter logic from
  `receipt_ocr_diagnostics.dart`.
- Kept the existing `ReceiptOcrDiagnosticsLabels` extension in
  `receipt_ocr_diagnostics_labels.dart` as the single owner for OCR/admin
  summary labels.
- Reduced the core diagnostics model from 451 lines to 310 lines while keeping
  the public diagnostic getters available through the existing part extension.

Verification:
- `dart format` completed cleanly for the touched OCR diagnostics files.
- Focused Flutter tests passed:
  `test/receipt_ocr_service_test.dart`,
  `test/receipt_ocr_service_parser_diagnostics_summary_test.dart`,
  `test/receipt_ocr_service_totals_coverage_test.dart`,
  `test/receipt_ocr_service_read_warnings_test.dart`,
  `test/receipt_ocr_service_source_handoff_test.dart`, and
  `test/receipt_ocr_service_long_receipt_diagnostics_test.dart`.
- `dart analyze` over `receipt_ocr_contract.dart`,
  `receipt_ocr_diagnostics.dart`, and `receipt_ocr_diagnostics_labels.dart`
  passed with no issues.
- Touched source files remain under 500 lines:
  `receipt_ocr_diagnostics.dart` 310 lines and
  `receipt_ocr_diagnostics_labels.dart` 144 lines.
- `dart run tool/maintainiac_source_audit.dart` passed over the two touched
  diagnostics source files.
- `git diff --check` passed.

Known follow-up:
- Continue with the next production receipt/camera file near the line limit, or
  add fixture validation for native photo-quality heuristics.
## Pass 066 - 01:51:02 EDT to 01:52:50 EDT

Scope:
- Split receipt continuation, completion, and coverage-decision handoff signals
  out of `receipt_capture_flow_handoff_signals.dart` into
  `receipt_capture_flow_continuation_signals.dart`.
- Added the new part to `receipt_capture_flow.dart`.
- Kept OCR source handoff behavior unchanged while isolating the long-receipt
  continuation contract from the general OCR-source diagnostics.

Verification:
- `dart format` completed cleanly for the touched receipt capture flow files.
- Focused Flutter tests passed:
  `test/receipt_native_camera_previous_section_channel_test.dart`,
  `test/receipt_camera_result_stitch_scanner_test.dart`,
  `test/receipt_camera_result_completion_coverage_test.dart`,
  `test/receipt_camera_result_recovery_handoff_test.dart`, and
  `test/receipt_privacy_event_capture_handoff_test.dart`.
- `dart analyze` over the three touched files passed with no issues.
- Touched source files remain under 500 lines:
  `receipt_capture_flow.dart` 436 lines,
  `receipt_capture_flow_handoff_signals.dart` 304 lines, and
  `receipt_capture_flow_continuation_signals.dart` 150 lines.
- `dart run tool/maintainiac_source_audit.dart` passed over the three touched
  files.
- `git diff --check` passed.

Known follow-up:
- Continue with the next production receipt/camera file near the line limit, or
  add fixture validation for native photo-quality heuristics.
