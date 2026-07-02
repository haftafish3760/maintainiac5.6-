# Receipt Camera Cleanup Pass Log Archive

Archived pass entries from `receipt_camera_cleanup_pass_log.md`. This file covers physical log order from pass 126 to pass 123.

## Pass 126 - 04:30:42 EDT to 04:33:14 EDT

Scope:
- Split long copy/regex lines in five parser/privacy files:
  `expense_receipt_parse_diagnostics_ocr.dart`,
  `expense_receipt_parser_description_cleanup_logic.dart`,
  `expense_receipt_parser_merchant_totals_logic.dart`,
  `expense_receipt_parser_support_models.dart`, and
  `expense_screen_telemetry_privacy_patterns.dart`.
- Reduced the broad receipt-scope long-line diagnostic backlog from 21 files to
  16 files.

Verification:
- `dart run tool/maintainiac_source_audit.dart` over the five touched files
  with `--max-line-length=220` passed.
- `dart analyze` over the five touched files passed with no issues.
- `flutter test test/receipt_qa_runner_contract_test.dart -r compact` passed.
- `git diff --check` passed.
- Touched files remain under 500 lines and under 220 characters per line:
  `expense_receipt_parse_diagnostics_ocr.dart` 400 lines,
  `expense_receipt_parser_description_cleanup_logic.dart` 267 lines,
  `expense_receipt_parser_merchant_totals_logic.dart` 342 lines,
  `expense_receipt_parser_support_models.dart` 164 lines, and
  `expense_screen_telemetry_privacy_patterns.dart` 80 lines.

Known follow-up:
- Continue reducing the remaining 16-file long-line backlog, with the telemetry
  snapshot builder kept separate because it requires a structural split.
## Pass 125 - 04:26:49 EDT to 04:30:24 EDT

Scope:
- Split oversized receipt parser/category regex literals into adjacent raw
  strings without changing token behavior.
- Cleaned long lines in:
  `expense_receipt_category_keywords.dart`,
  `expense_receipt_parser_category_match_logic.dart`, and
  `expense_receipt_parser_field_confidence_logic.dart`.
- Reduced the broad receipt-scope long-line diagnostic backlog from 24 files to
  21 files.

Failure fixed during this pass:
- The first long-line audit still failed because several older regex literals
  in the touched files remained over 220 characters. Those were split and the
  focused long-line audit now passes.

Verification:
- `dart run tool/maintainiac_source_audit.dart` over the three touched parser
  files with `--max-line-length=220` passed.
- `dart analyze` over the three touched parser files passed with no issues.
- `flutter test test/receipt_qa_runner_contract_test.dart -r compact` passed.
- `git diff --check` passed.
- Touched files remain under 500 lines and under 220 characters per line:
  `expense_receipt_category_keywords.dart` 183 lines,
  `expense_receipt_parser_category_match_logic.dart` 324 lines, and
  `expense_receipt_parser_field_confidence_logic.dart` 410 lines.

Known follow-up:
- Continue reducing the 21-file long-line backlog, then decide when to promote
  `--max-line-length=220` from diagnostic mode into a required gate.
## Pass 124 - 04:25:17 EDT to 04:26:30 EDT

Scope:
- Added an optional `--max-line-length=` diagnostic to
  `tool/maintainiac_source_audit.dart`.
- Kept the existing 500-line source-size gate unchanged by default so current
  pass/fail behavior does not shift without intent.
- Used the new diagnostic to identify receipt-scope files that are under 500
  lines but still contain oversized single-line blocks.

Verification:
- `dart run tool/maintainiac_source_audit.dart --include-tests` passed across
  582 receipt-scope source/test files with no file over 500 lines.
- `dart run tool/maintainiac_source_audit.dart --include-tests
  --max-line-length=220` intentionally failed and reported 24 long-line cleanup
  targets, led by `expense_screen_telemetry_health_snapshot.dart` at 63,597
  characters on one line.
- `dart analyze tool/maintainiac_source_audit.dart` passed with no issues.
- `git diff --check` passed.
- Touched QA-tool file remains under 500 lines:
  `maintainiac_source_audit.dart` 218 lines.

Known follow-up:
- Refactor the long-line telemetry snapshot builder carefully; formatting it
  directly would produce a 3,078-line file, so it needs helper extraction rather
  than a blind format pass.
## Pass 123 - 04:18:11 EDT to 04:25:00 EDT

Scope:
- Added a truncated home-center material fixture to the pure Dart QA runner's
  `noisy` pack.
- The new fixture covers compact rows and OCR damage such as `AM0UNT PAID`,
  `46.O7`, hyphenated short dates, and abbreviated screw rows (`SCRW`).
- Tightened the receipt text quality contract so noisy amount-paid totals and
  `MM-DD-YY` dates count as valid OCR evidence.
- Improved material classification for hardware-store screw abbreviations so
  `25PK #8 X 1-1/4 WD SCRW` routes to materials instead of Uncategorized.
- Updated the noisy-pack contract from three to four fixtures and widened the
  all-pack contract timeout so the full QA runner can finish rather than fail
  at Flutter's default 30-second test timeout.

Failures fixed during this pass:
- First focused run failed the new truncated material fixture at `0.739` score
  because the text-quality layer did not recognize noisy date/total evidence
  and the parser misclassified the screw row.
- Second focused run proved the fixture was fixed, then exposed a harness
  timeout in the all-pack contract test. The timeout is now explicit at two
  minutes for that full-pack process run.

Verification:
- `dart run tool/receipt_qa_runner.dart --pack=all --fail-under=0 --json`
  reported 14 fixtures, score `1.0`, no blockers, and no low-scoring fixtures.
- `flutter test test/receipt_qa_runner_contract_test.dart -r compact` passed.
- `dart analyze` over the touched parser/text-quality/fixture/test files
  passed with no issues.
- `dart run tool/maintainiac_source_audit.dart` passed over the touched files.
- `git diff --check` passed.
- Touched files remain under 500 lines:
  `receipt_text_quality_contract.dart` 149 lines,
  `expense_receipt_category_keywords.dart` 142 lines,
  `expense_receipt_parser_category_match_logic.dart` 319 lines,
  `receipt_qa_fixtures_fuel.dart` 198 lines, and
  `receipt_qa_runner_contract_test.dart` 251 lines.

Known follow-up:
- Continue adding noisy material/maintenance receipt fixtures while keeping
  pack files under the source-size guardrail.
