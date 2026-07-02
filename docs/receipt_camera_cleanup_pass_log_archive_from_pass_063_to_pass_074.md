# Receipt Camera Cleanup Pass Log Archive

Archived pass entries from `receipt_camera_cleanup_pass_log.md`. This file covers physical log order from pass 063 to pass 074.

## Pass 063 - 01:44:19 EDT to 01:45:57 EDT

Scope:
- Split generic diagnostic helper utilities out of
  `receipt_capture_review_result_helper_health_codes.dart` into
  `receipt_capture_review_result_helper_diagnostics.dart`.
- Added the new part to `receipt_capture_models.dart`.
- Kept native camera/admin health-code behavior unchanged while giving the
  health-code file room for future diagnostics.

Verification:
- `dart format` completed cleanly for the touched receipt capture model files.
- `dart analyze` over the touched model/helper files passed with no issues.
- Focused Flutter tests passed:
  `test/receipt_camera_result_native_ui_health_test.dart`,
  `test/receipt_camera_result_frozen_metadata_counts_test.dart`,
  `test/receipt_camera_result_frozen_handoff_counts_test.dart`, and
  `test/receipt_photo_review_quality_handoff_test.dart`.
- Touched source files remain under 500 lines:
  `receipt_capture_review_result_helper_health_codes.dart` 404 lines,
  `receipt_capture_review_result_helper_diagnostics.dart` 71 lines, and
  `receipt_capture_models.dart` 187 lines.
- `dart run tool/maintainiac_source_audit.dart` passed over the three touched
  files.
- `git diff --check` passed.

Known follow-up:
- Continue with the next production receipt/camera diagnostic file near the line
  limit, or add fixture validation for the dirty-lens/photo-quality heuristics.
## Pass 064 - 01:47:27 EDT to 01:49:40 EDT

Scope:
- Split iOS native receipt camera session argument parsing out of
  `ReceiptCameraViewControllerLayout.swift` into
  `ReceiptCameraViewControllerSessionArguments.swift`.
- Registered the new Swift file in `ios/Runner.xcodeproj/project.pbxproj` so it
  is included in the Runner target.
- Kept the existing session settings, long-receipt ghost guide arguments,
  analysis cadence bounds, and device/storage policy defaults behaviorally
  unchanged.

Verification:
- Focused Flutter tests passed:
  `test/receipt_native_ios_bridge_long_receipt_quality_test.dart`,
  `test/receipt_camera_capture_layout_test.dart`, and
  `test/receipt_native_camera_session_limits_test.dart`.
- Touched source files remain under 500 lines:
  `ReceiptCameraViewControllerLayout.swift` 332 lines and
  `ReceiptCameraViewControllerSessionArguments.swift` 135 lines.
- `dart run tool/maintainiac_source_audit.dart` passed over the two touched
  Swift source files.
- `git diff --check` passed.
- `plutil -lint ios/Runner.xcodeproj/project.pbxproj` passed.

Known follow-up:
- Continue with the next production receipt/camera file near the line limit, or
  add the next native camera QA fixture for photo-quality heuristics.
## Pass 065 - 01:49:40 EDT to 01:51:02 EDT

Scope:
- Split camera workload, stitch limits, and camera runtime profile helpers out
  of `receipt_assistance_policy_device_capability.dart` into
  `receipt_assistance_policy_device_capability_camera.dart`.
- Added the new part to `receipt_assistance_policy.dart`.
- Kept public capability behavior unchanged while making the device capability
  file easier to extend for phone-tier/storage guardrails.

Verification:
- `dart format` completed cleanly for the touched receipt assistance policy
  files.
- Focused Flutter tests passed:
  `test/receipt_assistance_policy_test.dart`,
  `test/receipt_assistance_policy_diagnostics_test.dart`,
  `test/receipt_native_camera_contract_test.dart`, and
  `test/receipt_native_camera_session_limits_test.dart`.
- `dart analyze` over the three touched files passed with no issues.
- Touched source files remain under 500 lines:
  `receipt_assistance_policy.dart` 21 lines,
  `receipt_assistance_policy_device_capability.dart` 376 lines, and
  `receipt_assistance_policy_device_capability_camera.dart` 81 lines.
- `dart run tool/maintainiac_source_audit.dart` passed over the three touched
  files.
- `git diff --check` passed.

Known follow-up:
- Continue with the next production receipt/camera file near the line limit, or
  add fixture validation for native photo-quality heuristics.
## Pass 082 - 02:31:17 EDT to 02:33:54 EDT

Scope:
- Split native control/readiness, native capture latency, native capture review
  transition, and receipt-review opening health codes out of
  `receipt_capture_review_result_helper_health_codes.dart` into
  `receipt_capture_review_result_helper_control_health_codes.dart`.
- Kept exposure, close, preview parity, capture-source policy, and accepted
  photo quality outcome helpers in the original health-code file.
- Preserved native camera/admin health metadata behavior while reducing the
  central helper file size.

Verification:
- `dart format` completed cleanly for the touched model/helper/test files.
- First focused Flutter run failed because source-contract readers in
  `test/receipt_capture_flow_shareability_test.dart` missed newly split helper
  parts. Fixed the missing control-health part reader and the existing missing
  continuation-signal reader.
- Focused Flutter tests then passed:
  `test/receipt_camera_result_native_ui_health_test.dart`,
  `test/receipt_camera_result_native_close_settings_test.dart`,
  `test/receipt_camera_result_native_quality_test.dart`,
  `test/receipt_camera_result_completion_coverage_test.dart`,
  `test/receipt_capture_flow_shareability_test.dart`, and
  `test/receipt_native_ghost_warning_contract_test.dart`.
- `dart analyze` over the touched source/test files passed with no issues.
- Touched files remain under 500 lines:
  `receipt_capture_models.dart` 190 lines,
  `receipt_capture_review_result_helper_health_codes.dart` 216 lines,
  `receipt_capture_review_result_helper_control_health_codes.dart` 189 lines,
  `receipt_camera_result_native_ui_health_test.dart` 414 lines,
  `receipt_camera_result_native_close_settings_test.dart` 410 lines,
  `receipt_camera_result_native_quality_test.dart` 339 lines,
  `receipt_camera_result_completion_coverage_test.dart` 307 lines,
  `receipt_capture_flow_shareability_test.dart` 447 lines, and
  `receipt_native_ghost_warning_contract_test.dart` 209 lines.
- `dart run tool/maintainiac_source_audit.dart` passed over the touched native
  health source/test files.
- `git diff --check` passed.

Known follow-up:
- Continue with the next production receipt/camera file near the line limit,
  especially native iOS/Android photo-quality files or add fixture validation
  for native photo-quality heuristics.
## Pass 081 - 02:29:01 EDT to 02:30:28 EDT

Scope:
- Split OCR-source attachment construction out of `receipt_capture_flow.dart`
  into `receipt_capture_flow_attachment_helpers.dart`.
- Preserved the public `ReceiptCaptureFlow.attachmentsFromReviewResult` API so
  expenses, materials, maintenance, and shared callers keep the same entry
  point.
- Kept OCR source document signals and risk flags wired into staged attachment
  metadata for downstream parser/admin diagnostics.

Verification:
- `dart format` completed cleanly for the touched flow files and focused test.
- First focused Flutter run failed because
  `test/receipt_capture_flow_handoff_contract_test.dart` still read only
  `receipt_capture_flow.dart` and missed the new attachment helper part.
- Fixed that stale source-reader boundary, then reran the same focused Flutter
  bundle successfully:
  `test/receipt_camera_result_stitch_scanner_test.dart`,
  `test/receipt_camera_result_native_close_settings_test.dart`,
  `test/receipt_camera_result_native_ui_health_test.dart`,
  `test/receipt_camera_result_recovery_handoff_test.dart`,
  `test/receipt_capture_flow_handoff_contract_test.dart`, and
  `test/receipt_camera_capture_layout_test.dart`.
- `dart analyze` over the touched source files and focused tests passed with
  no issues.
- Touched files remain under 500 lines:
  `receipt_capture_flow.dart` 392 lines,
  `receipt_capture_flow_attachment_helpers.dart` 24 lines,
  `receipt_camera_result_stitch_scanner_test.dart` 441 lines,
  `receipt_camera_result_native_close_settings_test.dart` 410 lines,
  `receipt_camera_result_native_ui_health_test.dart` 414 lines,
  `receipt_camera_result_recovery_handoff_test.dart` 381 lines,
  `receipt_capture_flow_handoff_contract_test.dart` 389 lines, and
  `receipt_camera_capture_layout_test.dart` 273 lines.
- `dart run tool/maintainiac_source_audit.dart` passed over the touched flow
  source/test files.
- `git diff --check` passed.

Known follow-up:
- Continue with the next production receipt/camera file near the line limit, or
  add fixture validation for native photo-quality heuristics.
## Pass 080 - 02:26:45 EDT to 02:28:29 EDT

Scope:
- Split final long-receipt stitch/OCR preparation helpers out of
  `receipt_photo_review_exit_actions.dart` into
  `receipt_photo_review_exit_stitch_actions.dart`.
- Kept exit-dialog, save-without-filling, and receipt review recovery copy in
  the original exit actions file.
- Updated shared source readers so save/exit contract tests still inspect the
  complete photo-review handoff path after the split.

Verification:
- `dart format` completed cleanly for the touched exit/stitch source and helper
  files.
- Focused Flutter tests passed:
  `test/receipt_photo_review_exit_completion_test.dart`,
  `test/receipt_camera_long_receipt_guidance_test.dart`,
  `test/receipt_native_shell_recovery_contract_test.dart`,
  `test/receipt_camera_result_stitch_scanner_test.dart`, and
  `test/receipt_photo_review_async_lifecycle_test.dart`.
- `dart analyze` over the touched source/helper files and focused tests passed
  with no issues.
- Touched files remain under 500 lines:
  `receipt_photo_review_screen.dart` 282 lines,
  `receipt_photo_review_exit_actions.dart` 283 lines,
  `receipt_photo_review_exit_stitch_actions.dart` 127 lines,
  `receipt_camera_capture_layout_source_readers.dart` 178 lines,
  `receipt_camera_source_readers.dart` 46 lines,
  `receipt_photo_review_exit_completion_test.dart` 359 lines,
  `receipt_camera_long_receipt_guidance_test.dart` 328 lines,
  `receipt_native_shell_recovery_contract_test.dart` 239 lines,
  `receipt_camera_result_stitch_scanner_test.dart` 441 lines, and
  `receipt_photo_review_async_lifecycle_test.dart` 363 lines.
- `dart run tool/maintainiac_source_audit.dart` passed over the touched
  exit/stitch source/test files.
- `git diff --check` passed.

Known follow-up:
- Continue with the next production receipt/camera file near the line limit, or
  add fixture validation for native photo-quality heuristics.
## Pass 079 - 02:23:47 EDT to 02:26:18 EDT

Scope:
- Split the long-receipt stitch readiness/status card out of
  `receipt_photo_review_stitch_controls.dart` into
  `receipt_photo_review_stitch_readiness.dart`.
- Kept manual pair selection, overlap slider controls, and pair guide chips in
  the original stitch controls file.
- Updated source-contract tests to read both stitch UI parts so the existing
  combined-receipt and fallback-readiness wording remains covered.

Verification:
- `dart format` completed cleanly for the touched stitch UI and test files.
- Focused Flutter tests passed:
  `test/receipt_camera_long_receipt_guidance_test.dart`,
  `test/receipt_photo_review_exit_completion_test.dart`,
  `test/receipt_camera_result_stitch_scanner_test.dart`,
  `test/receipt_photo_review_controls_layout_test.dart`, and
  `test/receipt_photo_review_async_lifecycle_test.dart`.
- `dart analyze` over the touched source files and focused tests passed with
  no issues.
- Touched files remain under 500 lines:
  `receipt_photo_review_screen.dart` 281 lines,
  `receipt_photo_review_stitch_controls.dart` 181 lines,
  `receipt_photo_review_stitch_readiness.dart` 227 lines,
  `receipt_camera_long_receipt_guidance_test.dart` 328 lines,
  `receipt_photo_review_exit_completion_test.dart` 359 lines,
  `receipt_camera_result_stitch_scanner_test.dart` 441 lines,
  `receipt_photo_review_controls_layout_test.dart` 337 lines, and
  `receipt_photo_review_async_lifecycle_test.dart` 363 lines.
- `dart run tool/maintainiac_source_audit.dart` passed over the touched stitch
  source/test files.
- `git diff --check` passed.

Known follow-up:
- Continue with the next production receipt/camera file near the line limit, or
  add fixture validation for native photo-quality heuristics.
## Pass 078 - 02:21:48 EDT to 02:23:13 EDT

Scope:
- Split user-facing coverage labels, ghost-guide contract labels, evidence
  labels, and completion dialog labels out of
  `receipt_photo_coverage_decision.dart` into
  `receipt_photo_coverage_decision_labels.dart`.
- Kept the receipt coverage decision factory and diagnostic parsing helpers in
  the original coverage decision file.
- Preserved the long-receipt contract where missing bottom edge plus missing
  subtotal/total evidence recommends another receipt section with a ghost
  overlap guide.

Verification:
- `dart format` completed cleanly for the touched model files.
- Focused Flutter tests passed:
  `test/receipt_camera_result_coverage_totals_test.dart`,
  `test/receipt_camera_result_completion_coverage_test.dart`,
  `test/receipt_photo_review_quality_handoff_test.dart`,
  `test/receipt_native_shell_recovery_contract_test.dart`, and
  `test/receipt_ocr_service_pdf_inspector_test.dart`.
- `dart analyze` over the touched source files and focused tests passed with
  no issues.
- Touched files remain under 500 lines:
  `receipt_capture_models.dart` 189 lines,
  `receipt_photo_coverage_decision.dart` 305 lines,
  `receipt_photo_coverage_decision_labels.dart` 105 lines,
  `receipt_camera_result_coverage_totals_test.dart` 432 lines,
  `receipt_camera_result_completion_coverage_test.dart` 307 lines,
  `receipt_native_shell_recovery_contract_test.dart` 239 lines, and
  `receipt_ocr_service_pdf_inspector_test.dart` 389 lines.
- `dart run tool/maintainiac_source_audit.dart` passed over the touched
  coverage source/test files.
- `git diff --check` passed.

Known follow-up:
- Continue with the next production receipt/camera file near the line limit, or
  add fixture validation for native photo-quality heuristics.
## Pass 077 - 02:18:05 EDT to 02:21:29 EDT

Scope:
- Split accepted-photo handoff route labels, next-screen labels, action labels,
  and privacy-safe OCR handoff evidence out of
  `receipt_capture_review_result_warnings.dart` into
  `receipt_capture_review_result_handoff_labels.dart`.
- Kept saved-photo warning counts, warning profiles, and accepted quality
  outcome counts in the warnings part.
- Updated older source-contract reads to include the new handoff-label part.

Verification:
- `dart format` completed cleanly for the touched model and test files.
- Focused Flutter tests passed:
  `test/receipt_camera_result_test.dart`,
  `test/receipt_camera_result_native_quality_test.dart`,
  `test/receipt_camera_result_native_close_settings_test.dart`,
  `test/receipt_camera_result_completion_coverage_test.dart`,
  `test/receipt_camera_result_stitch_scanner_test.dart`,
  `test/receipt_capture_flow_handoff_contract_test.dart`,
  `test/receipt_photo_review_quality_handoff_test.dart`, and
  `test/receipt_photo_review_exit_completion_test.dart`.
- `dart analyze` over the touched source files and focused tests passed with
  no issues.
- Touched files remain under 500 lines:
  `receipt_capture_models.dart` 188 lines,
  `receipt_capture_review_result_warnings.dart` 213 lines,
  `receipt_capture_review_result_handoff_labels.dart` 209 lines,
  `receipt_capture_flow_handoff_contract_test.dart` 386 lines,
  `receipt_photo_review_quality_handoff_test.dart` 263 lines, and
  `receipt_photo_review_exit_completion_test.dart` 355 lines.
- `dart run tool/maintainiac_source_audit.dart` passed over the touched
  receipt model/test files.
- `git diff --check` passed.

Known follow-up:
- Continue with the next production receipt/camera file near the line limit, or
  add fixture validation for native photo-quality heuristics.
## Pass 076 - 02:15:44 EDT to 02:17:47 EDT

Scope:
- Split shared-media receipt import conversion out of
  `incoming_receipt_share.dart` into `incoming_receipt_share_media.dart`.
- Kept async incoming-share staging, PDF inspection, storage checks, duplicate
  handling, and controller lifecycle in the main file.
- Preserved the public `receiptAttachmentsFromSharedMedia` helper while
  reducing the controller/storage file size.

Verification:
- `dart format` completed cleanly for the touched incoming-share files and
  focused test.
- Focused Flutter tests passed:
  `test/incoming_receipt_share_test.dart`,
  `test/incoming_receipt_share_pdf_hardening_test.dart`, and
  `test/receipt_pdf_torture_storage_test.dart`.
- `dart analyze` over the touched source files and focused tests passed with
  no issues.
- Touched files remain under 500 lines:
  `incoming_receipt_share.dart` 272 lines,
  `incoming_receipt_share_media.dart` 153 lines,
  `incoming_receipt_share_test.dart` 457 lines,
  `incoming_receipt_share_pdf_hardening_test.dart` 126 lines, and
  `receipt_pdf_torture_storage_test.dart` 382 lines.
- `dart run tool/maintainiac_source_audit.dart` passed over the touched
  incoming-share/PDF test files.
- `git diff --check` passed.

Known follow-up:
- Continue with the next production receipt/camera file near the line limit, or
  add fixture validation for native photo-quality heuristics.
## Pass 075 - 02:11:38 EDT to 02:15:17 EDT

Scope:
- Split computed data-saver receipt storage, parser-pack, and local-only
  readiness policy getters out of `receipt_capture_settings_store.dart` into
  `receipt_capture_settings_data_saver.dart`.
- Kept persistence methods in `ReceiptCaptureSettingsController`, including
  `setDefaultDataSaverLevel` and `useRecommendedDataSaverLevel`.
- Preserved the existing settings UI and tests without broad behavior changes.

Verification:
- `dart format` completed cleanly for the touched settings files and focused
  test.
- Focused Flutter tests passed:
  `test/receipt_capture_settings_store_test.dart`,
  `test/receipt_assistance_policy_test.dart`,
  `test/receipt_assistance_policy_diagnostics_test.dart`, and
  `test/receipt_camera_help_flow_test.dart`.
- `dart analyze` over the two touched settings source files and focused test
  passed with no issues.
- Touched files remain under 500 lines:
  `receipt_capture_settings_store.dart` 276 lines,
  `receipt_capture_settings_data_saver.dart` 155 lines, and
  `receipt_capture_settings_store_test.dart` 457 lines.
- `dart run tool/maintainiac_source_audit.dart` passed over the touched
  settings/test files.
- `git diff --check` passed.

Known follow-up:
- Continue with the next production receipt/camera file near the line limit, or
  add fixture validation for native photo-quality heuristics.
## Pass 074 - 02:08:27 EDT to 02:11:07 EDT

Scope:
- Split native camera policy math out of `receipt_native_camera_settings.dart`
  into `receipt_native_camera_settings_policy.dart`.
- Added the new part to `receipt_native_camera_contract.dart`.
- Kept `ReceiptNativeCameraSettings.sessionFor` as the owner of session
  construction while moving helper logic for storage safety, section limits,
  device policy labels, capability policy codes, and bounded ghost-slice
  fractions into the policy part.
- Updated native-camera source-contract readers so tests inspect the full
  current settings contract after the split.

Verification:
- `dart format` completed cleanly for the touched native camera settings and
  test files.
- Focused Flutter tests passed:
  `test/receipt_native_camera_contract_test.dart`,
  `test/receipt_native_camera_session_limits_test.dart`,
  `test/receipt_native_camera_storage_contract_test.dart`,
  `test/receipt_native_camera_previous_section_channel_test.dart`,
  `test/receipt_camera_coverage_decision_test.dart`, and
  `test/receipt_native_camera_privacy_diagnostics_test.dart`.
- `dart analyze` over the touched native camera/test files passed with no
  issues.
- Touched source files remain under 500 lines:
  `receipt_native_camera_contract.dart` 215 lines,
  `receipt_native_camera_settings.dart` 331 lines, and
  `receipt_native_camera_settings_policy.dart` 106 lines.
- `dart run tool/maintainiac_source_audit.dart` passed over the touched native
  camera/test files.
- `git diff --check` passed.

Known follow-up:
- Continue with the next production receipt/camera file near the line limit, or
  add fixture validation for native photo-quality heuristics.
