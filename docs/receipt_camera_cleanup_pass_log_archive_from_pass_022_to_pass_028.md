# Receipt Camera Cleanup Pass Log Archive

Archived pass entries from `receipt_camera_cleanup_pass_log.md`. This file covers physical log order from pass 022 to pass 028.

## Pass 022 - 2026-07-01 21:20:29 EDT to 21:39:06 EDT

Scope:
- Finish the receipt capture flow split so the shared native camera/OCR flow is
  no longer trapped in an oversized file.
- Repair exposed receipt review helper split issues without adding Flutter
  camera work.
- Restore source-contract tests so they follow the new split owners instead of
  reading stale monolith locations.

Changes:
- Split `lib/shared/widgets/receipt_capture/receipt_capture_flow.dart` from
  1799 lines to 435 lines.
- Added focused flow parts:
  `receipt_capture_flow_models.dart`,
  `receipt_capture_flow_recovery.dart`,
  `receipt_capture_flow_helpers.dart`,
  `receipt_capture_flow_handoff_signals.dart`, and
  `receipt_capture_flow_native_signals.dart`.
- Moved interrupted native capture recovery, continuation guide diagnostics,
  handoff signals, native UI/close/capture source signals, and option/result
  models into those split owners.
- Removed the malformed duplicate
  `receipt_capture_review_result_health_helpers.dart` part.
- Added `receipt_capture_review_result_settings_health.dart` for native receipt
  settings health codes.
- Fixed stale helper-call signatures in review warning, handoff storage, and
  native brain signal model splits so they call the top-level count helpers
  with the review result argument.
- Updated `test/receipt_capture_flow_shareability_test.dart` to read the new
  split owners for flow, model, and expense-entry source-contract checks.

Verification:
- `dart analyze test/receipt_capture_flow_shareability_test.dart
  lib/shared/widgets/receipt_capture/receipt_capture_flow.dart
  lib/shared/widgets/receipt_capture/receipt_capture_models.dart` passed.
- `dart run tool/maintainiac_source_audit.dart
  lib/shared/widgets/receipt_capture/receipt_capture_flow.dart
  lib/shared/widgets/receipt_capture/receipt_capture_flow_models.dart
  lib/shared/widgets/receipt_capture/receipt_capture_flow_recovery.dart
  lib/shared/widgets/receipt_capture/receipt_capture_flow_helpers.dart
  lib/shared/widgets/receipt_capture/receipt_capture_flow_handoff_signals.dart
  lib/shared/widgets/receipt_capture/receipt_capture_flow_native_signals.dart
  lib/shared/widgets/receipt_capture/receipt_capture_review_result_helpers.dart
  lib/shared/widgets/receipt_capture/receipt_capture_review_result_helper_health_codes.dart
  lib/shared/widgets/receipt_capture/receipt_capture_review_result_settings_health.dart`
  passed with `maxLines=500`.
- `flutter test test/receipt_capture_flow_shareability_test.dart
  test/receipt_camera_result_test.dart -r compact` passed 56 tests.

Intermediate failures fixed:
- The first focused Flutter run failed because source-contract tests still read
  only old monolith files after the split. The tests were updated to include the
  new recovery, helper, handoff, native signal, model helper, and expense OCR
  action split owners.
- The split exposed stale helper-call signatures where review-result helper
  functions had been moved from extension members to top-level helpers. Those
  calls were corrected before moving on.
- The split also exposed a malformed duplicate health helper part. It was
  removed and replaced with a valid settings-health split.

Line counts:
- `receipt_capture_flow.dart`: 435 lines.
- `receipt_capture_flow_models.dart`: 235 lines.
- `receipt_capture_flow_recovery.dart`: 289 lines.
- `receipt_capture_flow_helpers.dart`: 176 lines.
- `receipt_capture_flow_handoff_signals.dart`: 453 lines.
- `receipt_capture_flow_native_signals.dart`: 197 lines.
- `receipt_capture_review_result_helpers.dart`: 24 lines.
- `receipt_capture_review_result_helper_health_codes.dart`: 474 lines.
- `receipt_capture_review_result_settings_health.dart`: 41 lines.

Known follow-up:
- `test/receipt_capture_flow_shareability_test.dart` is still oversized and
  should be split in a later pass, even though the production source audit scope
  is now green.
- Continue moving Flutter-bound OCR/parser production logic into pure Dart so
  the QA runner can test the real implementation instead of reporting the known
  blocker.
## Pass 023 - 2026-07-01 21:39:52 EDT to 21:40:52 EDT

Scope:
- Bring the camera/OCR source-contract test harness under the 500-line file
  rule without weakening coverage.

Changes:
- Split handoff, privacy, OCR-source, expense-entry, and next/review label
  source-contract checks out of
  `test/receipt_capture_flow_shareability_test.dart`.
- Added `test/receipt_capture_flow_handoff_contract_test.dart` with a
  behavior-specific name rather than a numbered scratch file.
- Left `test/receipt_capture_flow_shareability_test.dart` focused on barrel,
  continuation guide, module neutrality, accepted native recovery cleanup, and
  interrupted recovery checks.

Verification:
- `dart analyze test/receipt_capture_flow_shareability_test.dart
  test/receipt_capture_flow_handoff_contract_test.dart` passed.
- `dart run tool/maintainiac_source_audit.dart
  test/receipt_capture_flow_shareability_test.dart
  test/receipt_capture_flow_handoff_contract_test.dart` passed with
  `maxLines=500`.
- `flutter test test/receipt_capture_flow_shareability_test.dart
  test/receipt_capture_flow_handoff_contract_test.dart
  test/receipt_camera_result_test.dart -r compact` passed 56 tests.

Line counts:
- `test/receipt_capture_flow_shareability_test.dart`: 438 lines.
- `test/receipt_capture_flow_handoff_contract_test.dart`: 376 lines.

Known follow-up:
- Other receipt/camera/OCR tests remain oversized and need the same style of
  behavior-named splits.
## Pass 024 - 2026-07-01 21:41:16 EDT to 21:42:54 EDT

Scope:
- Continue reducing oversized camera/OCR tests under the 500-line file rule.
- Avoid a careless split of `receipt_camera_result_test.dart` because its first
  test contains a very large inline diagnostic fixture that needs planned
  fixture extraction.

Changes:
- Split coverage-decision and native camera contract checks out of
  `test/receipt_camera_quality_guidance_test.dart`.
- Added `test/receipt_camera_coverage_decision_test.dart`.
- Updated source-contract reads after the split so they include the concrete
  part files now owning the asserted behavior:
  `receipt_image_processor_quality_helpers.dart` and
  `receipt_native_camera_settings.dart`.
- Corrected the readable-but-weak-bands expectation to assert the actual
  non-retake action code and label:
  `check_readability_or_add_closer_photo` and
  `Check readability or add a closer photo`.

Verification:
- `dart analyze test/receipt_camera_quality_guidance_test.dart
  test/receipt_camera_coverage_decision_test.dart` passed.
- `dart run tool/maintainiac_source_audit.dart
  test/receipt_camera_quality_guidance_test.dart
  test/receipt_camera_coverage_decision_test.dart` passed with `maxLines=500`.
- `flutter test test/receipt_camera_quality_guidance_test.dart
  test/receipt_camera_coverage_decision_test.dart -r compact` passed 13 tests.

Intermediate failures fixed:
- The first post-split Flutter run failed because two source-contract tests
  still read only the part-owner barrel files. The concrete part files were
  added to the reads.
- The test then exposed an outdated expectation that a readable-but-weak text
  band case must contain `Next`. The current product contract says the photo is
  not a forced retake, but still asks the user to check readability or add a
  closer photo. The test now asserts that explicit contract.

Line counts:
- `test/receipt_camera_quality_guidance_test.dart`: 399 lines.
- `test/receipt_camera_coverage_decision_test.dart`: 151 lines.

Known follow-up:
- Plan a fixture extraction for `test/receipt_camera_result_test.dart`; the
  first test is too large to split cleanly without moving its inline diagnostic
  payload into named helper/fixture files.
## Pass 025 - 2026-07-01 21:43:16 EDT to 21:45:13 EDT

Scope:
- Bring the receipt stitching test under the 500-line file rule while keeping
  its synthetic image coverage intact.

Changes:
- Extracted synthetic receipt image construction helpers from
  `test/receipt_stitching_test.dart`.
- Added `test/helpers/receipt_stitching_image_helpers.dart`.
- Renamed the moved helpers with descriptive public test-helper names:
  `receiptStitchingSection`, `blankDarkReceiptPhotoSection`,
  `copyReceiptStitchingOverlap`, `scaleReceiptStitchingShot`,
  `rotateReceiptStitchingShot`, and `writeTempReceiptStitchingImage`.

Verification:
- `dart analyze test/receipt_stitching_test.dart
  test/helpers/receipt_stitching_image_helpers.dart` passed.
- `dart run tool/maintainiac_source_audit.dart
  test/receipt_stitching_test.dart
  test/helpers/receipt_stitching_image_helpers.dart` passed with
  `maxLines=500`.
- `flutter test test/receipt_stitching_test.dart -r compact` passed 13 tests.

Line counts:
- `test/receipt_stitching_test.dart`: 393 lines.
- `test/helpers/receipt_stitching_image_helpers.dart`: 142 lines.

Known follow-up:
- Consider reducing stitching test runtime later; the focused test takes about
  one minute because it generates and processes synthetic receipt images.
## Pass 026 - 2026-07-01 21:46:11 EDT to 21:52:41 EDT

Scope:
- Continue camera/OCR cleanup by splitting another oversized source-contract
  test under the 500-line rule.
- Avoid rushing `test/receipt_camera_result_test.dart` because its first test
  has a very large inline diagnostic fixture and hundreds of assertions that
  need a planned fixture/assertion extraction.

Changes:
- Split long-receipt/photo-review guidance coverage out of
  `test/receipt_camera_help_flow_test.dart`.
- Added `test/receipt_camera_long_receipt_guidance_test.dart`.
- Split reviewed-photo OCR source handoff coverage out of
  `test/receipt_camera_help_flow_test.dart`.
- Added `test/receipt_camera_ocr_source_handoff_test.dart`.
- Added shared source-reader helpers in
  `test/helpers/receipt_camera_source_readers.dart`.
- Updated the split tests to read the actual implementation part files for
  receipt assistance policy, expense receipt handoff/telemetry, capture result
  brain signals, capture flow handoff signals, and the receipt read handoff
  panel instead of reading only barrel/shell files.

Verification:
- `dart analyze test/receipt_camera_help_flow_test.dart
  test/receipt_camera_long_receipt_guidance_test.dart
  test/receipt_camera_ocr_source_handoff_test.dart
  test/helpers/receipt_camera_source_readers.dart` passed.
- `dart run tool/maintainiac_source_audit.dart
  test/receipt_camera_help_flow_test.dart
  test/receipt_camera_long_receipt_guidance_test.dart
  test/receipt_camera_ocr_source_handoff_test.dart
  test/helpers/receipt_camera_source_readers.dart` passed with `maxLines=500`.
- `flutter test test/receipt_camera_help_flow_test.dart
  test/receipt_camera_long_receipt_guidance_test.dart
  test/receipt_camera_ocr_source_handoff_test.dart -r compact` passed 3 tests.

Intermediate failures fixed:
- The first analyzer run after the split failed because moved assertions still
  referenced `reviewScreen`, `contextControls`, and `commonControls` without
  reading those sources in the new long-receipt guidance test.
- Several focused Flutter runs failed because post-split source-contract tests
  were still reading only shell/barrel files. The reads were expanded to the
  exact part files that now own the asserted behavior instead of weakening the
  contracts.

Line counts:
- `test/receipt_camera_help_flow_test.dart`: 283 lines.
- `test/receipt_camera_long_receipt_guidance_test.dart`: 291 lines.
- `test/receipt_camera_ocr_source_handoff_test.dart`: 352 lines.
- `test/helpers/receipt_camera_source_readers.dart`: 44 lines.

Known follow-up:
- Plan a careful fixture/assertion extraction for
  `test/receipt_camera_result_test.dart`; the first test is too large for a
  safe quick split.
## Pass 027 - 2026-07-01 21:53:13 EDT to 21:56:28 EDT

Scope:
- Split the oversized native camera contract test under the 500-line rule.
- Preserve native Android/iOS camera, device capability, storage safety,
  previous-section guide, and no-stock-camera contracts.

Changes:
- Split `test/receipt_native_camera_contract_test.dart` from 1,891 lines into
  focused native camera contract tests:
  `receipt_native_camera_session_limits_test.dart`,
  `receipt_native_camera_service_basics_test.dart`,
  `receipt_native_camera_previous_section_channel_test.dart`,
  `receipt_native_camera_result_rejection_test.dart`,
  `receipt_native_camera_storage_contract_test.dart`, and
  `receipt_native_camera_privacy_diagnostics_test.dart`.
- Extracted the very large previous-section guide channel/diagnostic assertion
  blocks into named helpers:
  `receipt_native_camera_previous_section_channel_expectations.dart` and
  `receipt_native_camera_previous_section_diagnostics_expectations.dart`.
- Added the missing split imports for receipt assistance policy enums, device
  capability, parser depth, and camera workload/resolution tiers.

Verification:
- `dart analyze test/receipt_native_camera_contract_test.dart
  test/receipt_native_camera_session_limits_test.dart
  test/receipt_native_camera_service_basics_test.dart
  test/receipt_native_camera_previous_section_channel_test.dart
  test/receipt_native_camera_result_rejection_test.dart
  test/receipt_native_camera_storage_contract_test.dart
  test/receipt_native_camera_privacy_diagnostics_test.dart
  test/helpers/receipt_native_camera_previous_section_channel_expectations.dart
  test/helpers/receipt_native_camera_previous_section_diagnostics_expectations.dart`
  passed.
- `dart run tool/maintainiac_source_audit.dart
  test/receipt_native_camera_contract_test.dart
  test/receipt_native_camera_session_limits_test.dart
  test/receipt_native_camera_service_basics_test.dart
  test/receipt_native_camera_previous_section_channel_test.dart
  test/receipt_native_camera_result_rejection_test.dart
  test/receipt_native_camera_storage_contract_test.dart
  test/receipt_native_camera_privacy_diagnostics_test.dart
  test/helpers/receipt_native_camera_previous_section_channel_expectations.dart
  test/helpers/receipt_native_camera_previous_section_diagnostics_expectations.dart`
  passed with `maxLines=500`.
- `flutter test test/receipt_native_camera_contract_test.dart
  test/receipt_native_camera_session_limits_test.dart
  test/receipt_native_camera_service_basics_test.dart
  test/receipt_native_camera_previous_section_channel_test.dart
  test/receipt_native_camera_result_rejection_test.dart
  test/receipt_native_camera_storage_contract_test.dart
  test/receipt_native_camera_privacy_diagnostics_test.dart -r compact` passed
  20 tests.

Intermediate failures fixed:
- Analyzer initially failed because split files were missing imports for
  `ReceiptDeviceCapability`, `ReceiptParserDepth`,
  `ReceiptCameraResolutionTier`, and `ReceiptCameraWorkloadTier`.
- The first Flutter command incorrectly included helper files directly, which
  failed because helper files do not define `main()`. The corrected command ran
  only the seven real test files and passed.

Line counts:
- `test/receipt_native_camera_contract_test.dart`: 415 lines.
- `test/receipt_native_camera_session_limits_test.dart`: 182 lines.
- `test/receipt_native_camera_service_basics_test.dart`: 101 lines.
- `test/receipt_native_camera_previous_section_channel_test.dart`: 64 lines.
- `test/receipt_native_camera_result_rejection_test.dart`: 235 lines.
- `test/receipt_native_camera_storage_contract_test.dart`: 284 lines.
- `test/receipt_native_camera_privacy_diagnostics_test.dart`: 175 lines.
- `test/helpers/receipt_native_camera_previous_section_channel_expectations.dart`:
  248 lines.
- `test/helpers/receipt_native_camera_previous_section_diagnostics_expectations.dart`:
  241 lines.

Known follow-up:
- Continue reducing the remaining oversized OCR/camera tests. The largest
  camera-specific candidates are still `test/receipt_ocr_service_test.dart`,
  `test/receipt_camera_result_test.dart`,
  `test/receipt_native_capture_staging_test.dart`, and
  `test/receipt_camera_capture_layout_test.dart`.
## Pass 028 - 2026-07-01 21:57:32 EDT to 22:02:38 EDT

Scope:
- Split the oversized native capture staging/recovery test under the 500-line
  rule while preserving recovery, privacy, manifest, Hive-index, and cleanup
  coverage.

Changes:
- Split `test/receipt_native_capture_staging_test.dart` from 2,448 lines into
  focused staging/recovery tests:
  `receipt_native_capture_recovery_record_test.dart`,
  `receipt_native_capture_staging_cleanup_test.dart`,
  `receipt_native_capture_recovery_index_test.dart`, and
  `receipt_native_capture_old_cleanup_test.dart`.
- Extracted the large accepted-native-capture fixture and assertions into named
  helpers:
  `receipt_native_capture_staging_fixture.dart`,
  `receipt_native_capture_staging_basic_expectations.dart`,
  `receipt_native_capture_staging_signal_expectations.dart`,
  `receipt_native_capture_staging_manifest_expectations.dart`, and
  `receipt_native_capture_staging_index_expectations.dart`.
- Added `receipt_native_capture_staging_harness.dart` so tests that stage files
  still use the same temp path-provider and Hive isolation without repeating
  setup code in every file.

Verification:
- `dart analyze test/receipt_native_capture_staging_test.dart
  test/receipt_native_capture_recovery_record_test.dart
  test/receipt_native_capture_staging_cleanup_test.dart
  test/receipt_native_capture_recovery_index_test.dart
  test/receipt_native_capture_old_cleanup_test.dart
  test/helpers/receipt_native_capture_staging_harness.dart
  test/helpers/receipt_native_capture_staging_fixture.dart
  test/helpers/receipt_native_capture_staging_basic_expectations.dart
  test/helpers/receipt_native_capture_staging_signal_expectations.dart
  test/helpers/receipt_native_capture_staging_manifest_expectations.dart
  test/helpers/receipt_native_capture_staging_index_expectations.dart` passed.
- `dart run tool/maintainiac_source_audit.dart
  test/receipt_native_capture_staging_test.dart
  test/receipt_native_capture_recovery_record_test.dart
  test/receipt_native_capture_staging_cleanup_test.dart
  test/receipt_native_capture_recovery_index_test.dart
  test/receipt_native_capture_old_cleanup_test.dart
  test/helpers/receipt_native_capture_staging_harness.dart
  test/helpers/receipt_native_capture_staging_fixture.dart
  test/helpers/receipt_native_capture_staging_basic_expectations.dart
  test/helpers/receipt_native_capture_staging_signal_expectations.dart
  test/helpers/receipt_native_capture_staging_manifest_expectations.dart
  test/helpers/receipt_native_capture_staging_index_expectations.dart` passed
  with `maxLines=500`.
- `flutter test test/receipt_native_capture_staging_test.dart
  test/receipt_native_capture_recovery_record_test.dart
  test/receipt_native_capture_staging_cleanup_test.dart
  test/receipt_native_capture_recovery_index_test.dart
  test/receipt_native_capture_old_cleanup_test.dart -r compact` passed 17
  tests.

Intermediate failures fixed:
- The first mechanical extraction command was rejected before file changes
  because the command text contained a NUL placeholder.
- The first generated helper pass had syntax issues in the fixture and basic
  expectation helper, and the cleanup test split missed one closing `});`.
- Analyzer then caught nullable diagnostics-map access, a stale `source.path`
  reference after fixture extraction, a missing `flutter_test` import for
  `TestDefaultBinaryMessengerBinding`, and one wrong/unused recovery-record
  import. All were fixed before Flutter verification.

Line counts:
- `test/receipt_native_capture_staging_test.dart`: 159 lines.
- `test/receipt_native_capture_recovery_record_test.dart`: 147 lines.
- `test/receipt_native_capture_staging_cleanup_test.dart`: 231 lines.
- `test/receipt_native_capture_recovery_index_test.dart`: 255 lines.
- `test/receipt_native_capture_old_cleanup_test.dart`: 173 lines.
- `test/helpers/receipt_native_capture_staging_harness.dart`: 36 lines.
- `test/helpers/receipt_native_capture_staging_fixture.dart`: 195 lines.
- `test/helpers/receipt_native_capture_staging_basic_expectations.dart`: 111
  lines.
- `test/helpers/receipt_native_capture_staging_signal_expectations.dart`: 96
  lines.
- `test/helpers/receipt_native_capture_staging_manifest_expectations.dart`: 421
  lines.
- `test/helpers/receipt_native_capture_staging_index_expectations.dart`: 296
  lines.

Known follow-up:
- Continue reducing the remaining oversized OCR/camera tests, especially
  `test/receipt_ocr_service_test.dart`, `test/receipt_camera_result_test.dart`,
  and `test/receipt_camera_capture_layout_test.dart`.
