# Receipt Camera Cleanup Pass Log Archive

Archived pass entries from `receipt_camera_cleanup_pass_log.md`. This file covers physical log order from pass 130 to pass 128.

## Pass 130 - 04:44:05 EDT to 04:44:11 EDT

Scope:
- Promoted the source audit's long-line check from optional diagnostic mode to
  the default gate with `maxLineLength=220`.
- Kept `--max-line-length=0` available when a caller intentionally needs to
  disable the long-line check.

Verification:
- `dart run tool/maintainiac_source_audit.dart --include-tests` passed across
  584 receipt-scope source/test files with `maxLineLength=220` by default.
- `dart run tool/maintainiac_source_audit.dart --include-tests
  --max-line-length=0` passed and confirmed the escape hatch still works.
- `dart analyze tool/maintainiac_source_audit.dart` passed with no issues.
- `git diff --check` passed.
- `maintainiac_source_audit.dart` remains under 500 lines at 219 lines.

Known follow-up:
- Keep using the default audit after receipt/camera/OCR edits so oversized
  files and hidden single-line bulk cannot come back quietly.
## Pass 129 - 04:39:08 EDT to 04:43:41 EDT

Scope:
- Structurally split `expense_screen_telemetry_health_snapshot.dart` into:
  `expense_screen_telemetry_health_snapshot.dart`,
  `expense_screen_telemetry_health_snapshot_builder.dart`, and
  `expense_screen_telemetry_health_snapshot_metrics.dart`.
- Moved the large `fromRecords` builder into a dedicated part file.
- Moved rate getters, health label, and command-center map export into a
  metrics extension part.
- Cleared the final receipt-scope long-line diagnostic offender without
  formatting the original file into a 3,078-line file.

Failures fixed during this pass:
- First split left the main snapshot at 600 lines and the builder with one
  extra closing brace. Analyzer caught the brace issue and the source audit
  caught the line-count issue.
- Main constructor fields were compacted and the extra builder brace was
  removed before moving on.

Verification:
- `dart run tool/maintainiac_source_audit.dart --include-tests
  --max-line-length=220` passed across 584 receipt-scope source/test files.
- `dart run tool/maintainiac_source_audit.dart --include-tests` passed.
- `dart analyze` over the telemetry library and the three split snapshot files
  passed with no issues.
- Telemetry-focused Flutter tests passed across command summary, camera health,
  Firestore bridge, parser rates, source bucket actions, and redaction guards.
- `git diff --check` passed.
- Split files remain under 500 lines and under 220 characters per line:
  `expense_screen_telemetry_health_snapshot.dart` 192 lines,
  `expense_screen_telemetry_health_snapshot_builder.dart` 410 lines, and
  `expense_screen_telemetry_health_snapshot_metrics.dart` 435 lines.

Known follow-up:
- Promote the long-line audit from optional diagnostic to the default source
  audit gate now that the receipt scope is clean.
## Pass 128 - 04:37:44 EDT to 04:38:50 EDT

Scope:
- Split long metadata/disclosure literals in five receipt telemetry and
  assistance-policy test files.
- Reduced the broad receipt-scope long-line diagnostic backlog from 6 files to
  1 file.

Verification:
- `dart run tool/maintainiac_source_audit.dart` over the five touched tests
  with `--max-line-length=220` passed.
- `dart analyze` over the five touched tests passed with no issues.
- `flutter test` over the five touched tests passed.
- `git diff --check` passed.
- Touched tests remain under 500 lines and under 220 characters per line:
  `expense_screen_telemetry_camera_health_test.dart` 388 lines,
  `expense_screen_telemetry_command_summary_test.dart` 221 lines,
  `receipt_assistance_policy_diagnostics_test.dart` 477 lines,
  `receipt_assistance_policy_install_strategy_test.dart` 245 lines, and
  `receipt_assistance_policy_test.dart` 488 lines.

Known follow-up:
- Only `expense_screen_telemetry_health_snapshot.dart` remains in the
  `--max-line-length=220` diagnostic backlog. It still needs a structural split
  because normal formatting expands it to 3,078 lines.
