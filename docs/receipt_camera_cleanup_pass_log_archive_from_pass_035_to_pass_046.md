# Receipt Camera Cleanup Pass Log Archive

Archived pass entries from `receipt_camera_cleanup_pass_log.md`. This file covers physical log order from pass 035 to pass 046.

## Pass 035 - 22:56:51 EDT to 22:59:25 EDT

Scope:
- Split `test/expense_receipt_assisted_review_flow_test.dart` from 2,130 lines
  into six behavior-focused source-contract tests:
  classification/attachment flow, parser guidance actions, overlap/native
  diagnostics, handoff/install metadata, recovery/no-line state, and save
  guardrails.
- Added shared source loader
  `test/helpers/expense_receipt_assisted_review_source_fixture.dart` so the
  split tests reuse the same source-reading setup instead of duplicating 100+
  lines per file.

Verification:
- `dart format test/expense_receipt_assisted_review*.dart
  test/helpers/expense_receipt_assisted_review_source_fixture.dart` completed
  cleanly.
- `dart analyze test/expense_receipt_assisted_review*.dart
  test/helpers/expense_receipt_assisted_review_source_fixture.dart` passed with
  no issues.
- `dart run tool/maintainiac_source_audit.dart` over the same seven files
  passed with `maxLines=500`.
- `flutter test` over the six split assisted-review source-contract tests
  passed 6 tests.

Intermediate failures fixed:
- Analyzer caught split-boundary misses where `ocrService` and `telemetry`
  source reads were still inline and a few `totals` aliases were unused.
- Moved those source reads into the shared fixture and removed unused aliases
  before the final analyzer/test run.

Line counts:
- `test/expense_receipt_assisted_review_flow_test.dart`: 246 lines.
- `test/expense_receipt_assisted_review_parser_guidance_test.dart`: 314 lines.
- `test/expense_receipt_assisted_review_overlap_native_test.dart`: 482 lines.
- `test/expense_receipt_assisted_review_handoff_test.dart`: 245 lines.
- `test/expense_receipt_assisted_review_recovery_state_test.dart`: 324 lines.
- `test/expense_receipt_assisted_review_save_guardrails_test.dart`: 369 lines.
- `test/helpers/expense_receipt_assisted_review_source_fixture.dart`: 245 lines.

Known follow-up:
- Continue with the next oversized OCR/camera expense target, likely
  `test/expense_parser_failure_diagnostics_test.dart` or receipt assistance
  policy coverage.
- Native Android Kotlin compile remains blocked until Java is available on this
  Mac.
## Pass 036 - 23:00:40 EDT to 23:06:10 EDT

Scope:
- Split `test/expense_parser_failure_diagnostics_test.dart` from 653 lines into
  three focused diagnostics tests: core parser failure causes, OCR handoff
  causes, and optional receipt-brain/storage guardrail causes.
- Fixed production OCR compile misses that the focused Flutter tests exposed:
  `expense_ledger_models.dart` now imports the OCR contract parent library for
  its OCR review part, and `receipt_ocr_service_helpers.dart` has the scanner
  preparation risk classifier inside its own library scope.

Verification:
- `dart format` over the three diagnostics tests and the two production files
  completed cleanly.
- `dart analyze lib/screens/expenses/data/expense_ledger_models.dart
  lib/shared/widgets/receipt_capture/receipt_ocr_service.dart
  test/expense_parser_failure_diagnostics*.dart` passed with no issues.
- `dart run tool/maintainiac_source_audit.dart` over the touched production and
  diagnostics files passed with `maxLines=500`.
- `flutter test` over the three split diagnostics files passed 14 tests.

Intermediate failures fixed:
- Analyzer caught missing imports for `ReceiptDeviceCapability`,
  `ReceiptOcrResult`, and `ReceiptOcrSourceHandoffSummary` while the split was
  being tightened; corrected imports to use the parent OCR contract/policy
  libraries.
- Flutter compile then exposed pre-existing production OCR misses:
  `ReceiptOcrDiagnostics`, `ReceiptOcrWarning`,
  `ReceiptOcrReviewSeverity`, and `_isScannerPreparationRiskToken` were not
  visible from their use sites. Fixed those before rerunning tests.

Line counts:
- `test/expense_parser_failure_diagnostics_test.dart`: 198 lines.
- `test/expense_parser_failure_diagnostics_ocr_handoff_test.dart`: 294 lines.
- `test/expense_parser_failure_diagnostics_optional_brain_test.dart`: 176
  lines.
- `lib/screens/expenses/data/expense_ledger_models.dart`: 60 lines.
- `lib/shared/widgets/receipt_capture/receipt_ocr_service_helpers.dart`: 70
  lines.

Known follow-up:
- Continue with the next in-scope oversized expense/OCR target. Current scan
  still shows `lib/screens/expenses/calendar/expense_receipt_detail_info.dart`
  at 924 lines, `lib/screens/expenses/reports/expense_recap_models.dart` at 670
  lines, `lib/screens/expenses/reports/expense_recap_screen.dart` at 642 lines,
  `test/expense_draft_store_test.dart` at 636 lines, and
  `test/expense_ledger_store_test.dart` at 622 lines.
- Native Android Kotlin compile remains blocked until Java is available on this
  Mac.
## Pass 037 - 23:06:41 EDT to 23:11:07 EDT

Scope:
- Split `lib/screens/expenses/calendar/expense_receipt_detail_info.dart` from
  924 lines into three focused receipt detail parts: info/allocation,
  OCR-review details, and proof-preview/viewer UI.
- Updated `expense_calendar.dart` to include the two new receipt detail parts.
- Fixed another production OCR contract import miss in
  `expense_receipt_item_memory_store.dart`, replacing the OCR service import
  with the OCR contract import needed for `ReceiptOcrResult`.
- Updated `test/expense_receipt_detail_ocr_review_test.dart` source-contract
  assertions to read the new split files while keeping the proof-viewer and
  recovery-label checks.

Verification:
- `dart format` over the split calendar files, memory store, and updated widget
  test completed cleanly.
- `dart analyze` over the same touched files passed with no issues.
- `dart run tool/maintainiac_source_audit.dart` over the same touched files
  passed with `maxLines=500`.
- `flutter test test/expense_receipt_detail_ocr_review_test.dart -r compact`
  passed 4 tests.

Intermediate failures fixed:
- The first focused widget test run exposed a compile miss:
  `expense_receipt_item_memory_store.dart` could not see `ReceiptOcrResult`.
  Fixed by importing the OCR contract parent library.
- After the split, the source-contract test still expected proof-viewer code in
  the old `expense_receipt_detail_info.dart`; updated it to assert against
  `expense_receipt_detail_proof_preview.dart` and
  `expense_receipt_detail_ocr_review.dart` instead.

Line counts:
- `lib/screens/expenses/calendar/expense_receipt_detail_info.dart`: 316 lines.
- `lib/screens/expenses/calendar/expense_receipt_detail_ocr_review.dart`: 273
  lines.
- `lib/screens/expenses/calendar/expense_receipt_detail_proof_preview.dart`:
  337 lines.
- `lib/screens/expenses/data/expense_receipt_item_memory_store.dart`: 449
  lines.
- `test/expense_receipt_detail_ocr_review_test.dart`: 344 lines.

Known follow-up:
- Continue with the next in-scope oversized expense/OCR target. Current scan
  still shows `lib/screens/expenses/reports/expense_recap_models.dart` at 670
  lines, `lib/screens/expenses/reports/expense_recap_screen.dart` at 642 lines,
  `test/expense_draft_store_test.dart` at 636 lines, and
  `test/expense_ledger_store_test.dart` at 622 lines.
- Native Android Kotlin compile remains blocked until Java is available on this
  Mac.
## Pass 038 - 23:11:51 EDT to 23:14:26 EDT

Scope:
- Split `test/expense_draft_store_test.dart` from 636 lines into two focused
  tests: draft/OCR-review metadata persistence and receipt proof recovery
  cleanup.
- Kept the Hive/temp-directory setup in each test file so recovery tests remain
  isolated from OCR metadata tests.

Verification:
- `dart format test/expense_draft_store_test.dart
  test/expense_draft_store_proof_recovery_test.dart` completed cleanly.
- `dart analyze` over both draft-store test files passed with no issues.
- `dart run tool/maintainiac_source_audit.dart` over both files passed with
  `maxLines=500`.
- `flutter test test/expense_draft_store_test.dart
  test/expense_draft_store_proof_recovery_test.dart -r compact` passed 14
  tests.

Intermediate failures fixed:
- No analyzer or Flutter failures after the split.

Line counts:
- `test/expense_draft_store_test.dart`: 348 lines.
- `test/expense_draft_store_proof_recovery_test.dart`: 310 lines.

Known follow-up:
- Continue with the next in-scope oversized expense target. Current scan still
  shows `lib/screens/expenses/reports/expense_recap_models.dart` at 670 lines,
  `lib/screens/expenses/reports/expense_recap_screen.dart` at 642 lines, and
  `test/expense_ledger_store_test.dart` at 622 lines.
- Native Android Kotlin compile remains blocked until Java is available on this
  Mac.
## Pass 039 - 23:14:51 EDT to 23:17:16 EDT

Scope:
- Split `test/expense_ledger_store_test.dart` from 622 lines into general
  ledger summary/edit behavior and receipt metadata/OCR/duplicate behavior.

Verification:
- `dart format test/expense_ledger_store_test.dart
  test/expense_ledger_store_receipt_metadata_test.dart` completed cleanly.
- `dart analyze` over both ledger-store test files passed with no issues.
- `dart run tool/maintainiac_source_audit.dart` over both files passed with
  `maxLines=500`.
- `flutter test test/expense_ledger_store_test.dart
  test/expense_ledger_store_receipt_metadata_test.dart -r compact` passed 10
  tests.

Intermediate failures fixed:
- No analyzer or Flutter failures after the split.

Line counts:
- `test/expense_ledger_store_test.dart`: 285 lines.
- `test/expense_ledger_store_receipt_metadata_test.dart`: 346 lines.

Known follow-up:
- Continue with the next in-scope oversized expense target. Current scan still
  shows `lib/screens/expenses/reports/expense_recap_models.dart` at 670 lines
  and `lib/screens/expenses/reports/expense_recap_screen.dart` at 642 lines.
- Native Android Kotlin compile remains blocked until Java is available on this
  Mac.
## Pass 040 - 23:17:35 EDT to 23:19:46 EDT

Scope:
- Split `lib/screens/expenses/reports/expense_recap_models.dart` from 670 lines
  by moving recap tile definitions and report formatting helpers into
  `expense_recap_tile_definitions.dart`.

Verification:
- `dart format lib/screens/expenses/reports/expense_recap_models.dart
  lib/screens/expenses/reports/expense_recap_tile_definitions.dart` completed
  cleanly.
- `dart analyze` over both recap model files passed with no issues.
- `dart run tool/maintainiac_source_audit.dart` over both files passed with
  `maxLines=500`.
- `flutter test test/expense_recap_models_test.dart -r compact` passed 3 tests.

Intermediate failures fixed:
- No analyzer or Flutter failures after the split.

Line counts:
- `lib/screens/expenses/reports/expense_recap_models.dart`: 394 lines.
- `lib/screens/expenses/reports/expense_recap_tile_definitions.dart`: 278
  lines.

Known follow-up:
- Run a targeted oversized scan for `lib/screens/expenses` and `test/expense*`
  to avoid missing any expense files hidden below broader inventory/generated
  files.
- Native Android Kotlin compile remains blocked until Java is available on this
  Mac.
## Pass 041 - 23:20:04 EDT to 23:22:18 EDT

Scope:
- Split `lib/screens/expenses/reports/expense_recap_screen.dart` from 642 lines
  into the screen shell, range controls, and recap tile/panel widgets.

Verification:
- `dart format` over the three recap screen files completed cleanly.
- `dart analyze` over the three recap screen files passed with no issues.
- `dart run tool/maintainiac_source_audit.dart` over the three recap screen
  files passed with `maxLines=500`.
- `flutter test test/expense_recap_models_test.dart -r compact` passed 3
  tests.

Intermediate failures fixed:
- No analyzer or Flutter failures after the split.

Line counts:
- `lib/screens/expenses/reports/expense_recap_screen.dart`: 110 lines.
- `lib/screens/expenses/reports/expense_recap_range_panel.dart`: 129 lines.
- `lib/screens/expenses/reports/expense_recap_tile_panels.dart`: 408 lines.

Known follow-up:
- Continue with the remaining targeted expense oversized app file,
  `lib/screens/expenses/calendar/expense_day_summary_sections.dart`.
- Native Android Kotlin compile remains blocked until Java is available on this
  Mac.
## Pass 042 - 23:22:18 EDT to 23:24:38 EDT

Scope:
- Split `lib/screens/expenses/calendar/expense_day_summary_sections.dart` from
  536 lines by moving the vehicle/receipt recap panel and row helpers into
  `expense_day_summary_recap_panels.dart`.
- Updated `expense_calendar.dart` to include the new part.
- Updated `test/expense_receipt_detail_ocr_review_test.dart` source-contract
  assertions to read the new recap panel part while keeping the same UI label
  checks.

Verification:
- `dart format` over the calendar summary split and updated test completed
  cleanly.
- `dart analyze` over the same files passed with no issues.
- `dart run tool/maintainiac_source_audit.dart` over the same files passed with
  `maxLines=500`.
- `flutter test test/expense_receipt_detail_ocr_review_test.dart -r compact`
  passed 4 tests after the source-contract test was updated for the split.

Intermediate failures fixed:
- The first widget test run passed behavior but failed a source-contract
  assertion because `Receipt Read Status`, `Read Summary`, and `Top Check` had
  moved from `expense_day_summary_sections.dart` to
  `expense_day_summary_recap_panels.dart`. Updated the test to assert against
  the new file and reran successfully.

Line counts:
- `lib/screens/expenses/calendar/expense_day_summary_sections.dart`: 328 lines.
- `lib/screens/expenses/calendar/expense_day_summary_recap_panels.dart`: 209
  lines.
- `test/expense_receipt_detail_ocr_review_test.dart`: 347 lines.

Known follow-up:
- At 23:24:38 EDT, targeted scan over `lib/screens/expenses` and `test`
  showed no remaining oversized `lib/screens/expenses` files. Remaining
  over-500 results in that targeted scan were broader/non-current-lane files:
  `test/maintainiac_firestore_documents_test.dart` at 2,046 lines,
  `test/work_supply_catalog_test.dart` at 593 lines,
  `test/global_odometer_test.dart` at 502 lines, and
  `test/expense_export_test.dart` at 502 lines.
- Native Android Kotlin compile remains blocked until Java is available on this
  Mac.
## Pass 043 - 23:25:27 EDT to 23:26:40 EDT

Scope:
- Split `test/expense_export_test.dart` from 502 lines into export
  snapshot/privacy coverage and export store/file-writer coverage.
- Kept Command Center OCR contract privacy assertions in the main export test
  and moved monthly export usage plus file output checks to
  `test/expense_export_store_writer_test.dart`.

Verification:
- `dart format test/expense_export_test.dart
  test/expense_export_store_writer_test.dart` completed cleanly.
- `dart analyze` over both export test files passed with no issues.
- `dart run tool/maintainiac_source_audit.dart` over both export test files
  passed with `maxLines=500`.
- `flutter test test/expense_export_test.dart
  test/expense_export_store_writer_test.dart -r compact` passed 6 tests.

Intermediate failures fixed:
- No analyzer or Flutter failures after the split.

Line counts:
- `test/expense_export_test.dart`: 391 lines.
- `test/expense_export_store_writer_test.dart`: 136 lines.

Known follow-up:
- Run the receipt QA runner/quality gate next to move from line cleanup into
  hard guardrail verification.
- Targeted oversized scan now shows no `lib/screens/expenses` files over 500
  lines and no `test/expense_*` files over 500 lines. Remaining over-500 files
  in the broader receipt/expense/test scan are outside the immediate expense
  export/OCR lane: `test/maintainiac_firestore_documents_test.dart`,
  `test/work_supply_catalog_test.dart`, and `test/global_odometer_test.dart`.
- Native Android Kotlin compile remains blocked until Java is available on this
  Mac.
## Pass 044 - 23:26:40 EDT to 23:27:35 EDT

Scope:
- Ran the pure Dart receipt QA runner and full receipt quality gate after the
  oversized expense/OCR cleanup.
- Verified Java availability for the Android native compile gate.

Verification:
- `dart analyze tool/maintainiac_source_audit.dart tool/receipt_qa_runner.dart`
  passed with no issues.
- `dart run tool/receipt_qa_runner.dart --fail-under=0.90` passed with 5
  fixtures at 100.0%.
- `dart run tool/receipt_qa_runner.dart --fail-under=0.90 --json` passed when
  rerun by itself with all dimension scores at 1.0 and no blockers.
- `bash tool/receipt_quality_gate.sh` passed end to end:
  source audit over 334 receipt-scoped files, QA runner at 100.0%, and focused
  Flutter receipt tests passing 22 tests.
- `java -version` now reports OpenJDK 17.0.17, so the previous Android-native
  compile blocker is no longer present.

Intermediate failures fixed:
- A parallel `dart run` JSON QA invocation hit a native-asset install-name race
  while another `dart run` was building hooks. Reran the JSON QA command by
  itself and it passed.

Known follow-up:
- Run the Android native build/compile gate now that Java is available.
- Remaining over-500 files in the broader scan are
  `test/maintainiac_firestore_documents_test.dart`,
  `test/work_supply_catalog_test.dart`, and `test/global_odometer_test.dart`.
## Pass 045 - 23:27:35 EDT to 23:33:13 EDT

Scope:
- Ran the Android native compile gate now that Java is available, then repaired
  the Kotlin source errors it exposed.
- Kept the repair source-only after the usage-limit concern, with no repeated
  Gradle loop.

Verification:
- `flutter build apk --debug` reached `:app:compileDebugKotlin` and failed.
  This is a real native Android compile failure, not a Flutter analyzer issue.
- Lightweight source scan after repair found no remaining
  `this::...isInitialized` checks in Android receipt camera extension files.
- `git diff --check` passed after removing the extra blank line at EOF in
  `test/helpers/receipt_parse_accuracy_harness.dart`.
- Line counts for the touched Android receipt camera files are all at or under
  500 lines.
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
  PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH" ./gradlew
  :app:compileDebugKotlin` passed. The Android receipt camera Kotlin compile
  errors from the failed Flutter build are repaired.

Intermediate failures fixed:
- Restored the missing `ReceiptCameraActivity.iconButton(...)` function header
  in `ReceiptCameraDiagnosticsLabels.kt`.
- Removed the dangling duplicate `iconButton` fragment from
  `ReceiptCameraReviewSettings.kt`.
- Replaced extension-side `this::lateinitField.isInitialized` calls with a
  shared safe accessor helper so Kotlin no longer tries to access private
  backing fields from extension files.
- Qualified receipt camera companion extras and Android activity result
  constants in native close/result paths.
- Removed the extra blank line at EOF reported by `git diff --check`.

Known follow-up:
- Persist or document the Homebrew OpenJDK 17 `JAVA_HOME` setting so future
  Gradle runs do not fail Java discovery before compile starts.
- Full `flutter build apk --debug` still needs a later end-to-end pass if a
  packaged debug APK is required, but the focused Android Kotlin compile gate is
  now green.
## Pass 046 - 23:33:13 EDT to 23:36:38 EDT

Scope:
- Closed the QA gap where `tool/receipt_quality_gate.sh` could pass without
  proving the Android native receipt-camera Kotlin code still compiled.
- Added a repeatable Android receipt camera compile gate that pins this Mac's
  Homebrew OpenJDK 17 when `JAVA_HOME` is missing.

Verification:
- `tool/android_receipt_camera_compile_gate.sh` already passed the focused
  Android `:app:compileDebugKotlin` gate during Pass 045.
- `tool/receipt_quality_gate.sh` now runs the Android compile gate between the
  pure Dart receipt QA runner and the focused Flutter receipt tests.
- `bash -n tool/receipt_quality_gate.sh
  tool/android_receipt_camera_compile_gate.sh` passed.
- `dart run tool/maintainiac_source_audit.dart --include-tests` passed over
  551 receipt-scoped source/test files, all at or under 500 lines.
- `bash tool/receipt_quality_gate.sh` passed end to end after the Android gate
  wiring: tool analyzer, receipt source audit over 334 files, receipt QA runner
  at 100.0%, Android `:app:compileDebugKotlin`, and 22 focused Flutter receipt
  tests.

Known follow-up:
- Keep broad app-level analyzer/build verification separate from this receipt
  gate; this gate now proves the receipt camera/OCR lane it names.
