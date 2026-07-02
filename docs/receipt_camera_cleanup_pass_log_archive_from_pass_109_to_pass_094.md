# Receipt Camera Cleanup Pass Log Archive

Archived pass entries from `receipt_camera_cleanup_pass_log.md`. This file covers physical log order from pass 109 to pass 094.

## Pass 109 - 03:31:58 EDT to 03:34:30 EDT

Scope:
- Added exact subtotal scoring to the pure Dart receipt QA fixture model.
- The scorer now emits `subtotal_value_matched` checks and
  `production_parser_subtotal_value_mismatch` issues when stable fixtures parse
  the wrong subtotal.
- Added subtotal expectations to stable fuel, retail, maintenance, and
  long-receipt section fixtures.
- Strengthened the QA runner contract so subtotal scoring must remain present
  in the JSON check list.

Verification:
- `flutter test test/receipt_qa_runner_contract_test.dart -r compact` passed.
- `dart analyze` over the QA runner, fixture file, scoring part, and contract
  test passed with no issues.
- `dart run tool/maintainiac_source_audit.dart` passed over the touched QA
  runner scope.
- `git diff --check` passed.
- Touched files remain under 500 lines:
  `receipt_qa_runner.dart` 260 lines,
  `receipt_qa_fixtures.dart` 208 lines,
  `receipt_qa_scoring.dart` 224 lines, and
  `receipt_qa_runner_contract_test.dart` 212 lines.

Known follow-up:
- Continue adding exact field expectations for stable fixtures, then expand
  the fixture matrix toward blur, glare, crop, multi-photo order, and
  maintenance interval edge cases without letting the QA runner exceed the
  source-size guardrail.
## Pass 108 - 03:29:43 EDT to 03:31:22 EDT

Scope:
- Added `expectedLineCount` support to the pure Dart receipt QA fixture model.
- The scorer now emits `line_count_matched` checks and
  `production_parser_line_count_mismatch` issues when stable fixtures drop or
  invent parsed receipt lines.
- Added expected line counts to stable retail, maintenance, and long-receipt
  fixtures.
- Updated the QA runner contract so the JSON check list must include
  `line_count_matched`.

Verification:
- `flutter test test/receipt_qa_runner_contract_test.dart -r compact` passed.
- `dart analyze` over the QA runner, fixture file, scoring part, and contract
  test passed with no issues.
- `dart run tool/maintainiac_source_audit.dart` passed over the touched QA
  runner scope.
- `git diff --check` passed.
- Touched files remain under 500 lines:
  `receipt_qa_runner.dart` 258 lines,
  `receipt_qa_fixtures.dart` 202 lines,
  `receipt_qa_scoring.dart` 213 lines, and
  `receipt_qa_runner_contract_test.dart` 211 lines.

Known follow-up:
- Continue adding exact field expectations, but keep them tied to stable
  fixtures so failures identify real parser regressions rather than bad samples.
## Pass 107 - 03:26:35 EDT to 03:29:07 EDT

Scope:
- Split receipt QA scoring logic out of `tool/receipt_qa_runner.dart` into
  `tool/receipt_qa_scoring.dart`.
- Kept the CLI/report/fixture model in the runner while moving fixture scoring,
  merchant/fuel matching, allocation reconciliation, date formatting, and
  money-near-match helpers into the scoring part.
- This prevents the QA runner from drifting toward the 500-line ceiling after
  Pass 106 added field-value scoring.

Verification:
- `flutter test test/receipt_qa_runner_contract_test.dart -r compact` passed.
- `dart analyze` over the QA runner, fixture file, scoring part, and contract
  test passed with no issues.
- `dart run tool/maintainiac_source_audit.dart` passed over the touched QA
  runner scope.
- `git diff --check` passed.
- Touched files remain under 500 lines:
  `receipt_qa_runner.dart` 256 lines,
  `receipt_qa_fixtures.dart` 195 lines,
  `receipt_qa_scoring.dart` 202 lines, and
  `receipt_qa_runner_contract_test.dart` 210 lines.

Known follow-up:
- Continue adding field-level scoring in `receipt_qa_scoring.dart` now that the
  runner shell has room again.
## Pass 106 - 03:21:54 EDT to 03:25:55 EDT

Scope:
- Added the first compact per-field scoring layer to
  `tool/receipt_qa_runner.dart`.
- Fixtures can now declare expected date, tax, and total values; the runner adds
  `date_value_matched`, `tax_value_matched`, and `total_value_matched`
  production-parser checks and issue codes for mismatches.
- Added expected date/tax/total values to stable fuel, retail, and maintenance
  fixtures.
- Updated the QA runner contract so the JSON check list must include the new
  field-value checks.

Verification:
- First `flutter test test/receipt_qa_runner_contract_test.dart -r compact`
  run failed because two fixture expected dates were wrong:
  the Target retail fixture was marked `2026-06-12` instead of `2026-07-01`,
  and the Take 5 maintenance fixture was marked `2026-07-01` instead of
  `2026-06-12`.
- Corrected those fixture expectations and reran
  `flutter test test/receipt_qa_runner_contract_test.dart -r compact`; it
  passed.
- `dart analyze` over the QA runner, fixture file, and contract test passed
  with no issues.
- `dart run tool/maintainiac_source_audit.dart` passed over the touched QA
  runner scope.
- `git diff --check` passed.
- Touched files remain under 500 lines:
  `receipt_qa_runner.dart` 456 lines,
  `receipt_qa_fixtures.dart` 195 lines, and
  `receipt_qa_runner_contract_test.dart` 210 lines.

Known follow-up:
- `receipt_qa_runner.dart` is now close enough to 500 lines that the next
  meaningful runner expansion should split scoring helpers out before adding
  more fields.
## Pass 105 - 03:19:51 EDT to 03:21:28 EDT

Scope:
- Added a second retail QA fixture:
  `retail tax total with tender row`.
- The new fixture covers multiple retail line items, subtotal, tax, total, and
  a tender/auth row that must not break line-item parsing.
- Added a focused `--pack=retail` QA runner contract proving retail-only runs
  report only retail fixtures, include both retail cases, keep the retail pack
  score above `.90`, and return no fixture issues.

Verification:
- `flutter test test/receipt_qa_runner_contract_test.dart -r compact` passed.
- `dart analyze` over the QA runner, fixture file, and contract test passed
  with no issues.
- `dart run tool/maintainiac_source_audit.dart` passed over the touched QA
  runner scope.
- `git diff --check` passed.
- Touched files remain under 500 lines:
  `receipt_qa_runner.dart` 406 lines,
  `receipt_qa_fixtures.dart` 186 lines, and
  `receipt_qa_runner_contract_test.dart` 198 lines.

Known follow-up:
- Begin adding per-field expected values so the QA runner can score exact totals,
  taxes, dates, and line counts instead of only readiness checks.
## Pass 104 - 03:18:56 EDT to 03:19:18 EDT

Scope:
- Updated `docs/receipt_camera_world_class_qa_standard.md` so the Current Local
  Runner section matches the active QA runner fixture packs and contracts.
- The doc now names fuel, noisy OCR, retail, maintenance, and long-receipt
  packs; describes the newer noisy, maintenance-interval, and top/middle/bottom
  long-receipt coverage; and lists the focused pack contracts currently guarded
  by `test/receipt_qa_runner_contract_test.dart`.

Verification:
- `dart run tool/maintainiac_source_audit.dart` passed over the related QA
  runner Dart files.
- `git diff --check` passed.
- `rg` confirmed the updated QA-standard wording is present.
- Touched/reference files remain under 500 lines:
  `receipt_camera_world_class_qa_standard.md` 131 lines,
  `receipt_qa_runner.dart` 406 lines,
  `receipt_qa_fixtures.dart` 166 lines, and
  `receipt_qa_runner_contract_test.dart` 187 lines.

Known follow-up:
- Continue turning the written QA standard into executable checks before
  broadening native camera changes.
## Pass 103 - 03:16:49 EDT to 03:18:31 EDT

Scope:
- Refactored repeated focused-pack assertions in
  `test/receipt_qa_runner_contract_test.dart` into `_expectFocusedPack`.
- Preserved the same long-receipt, maintenance, fuel, noisy, and unknown-pack
  contract coverage while making future fixture-pack additions smaller.
- Reduced the QA runner contract test from 245 lines to 187 lines, keeping the
  file comfortably below the 500-line cap.

Verification:
- `flutter test test/receipt_qa_runner_contract_test.dart -r compact` passed.
- `dart analyze` over the QA runner, fixture file, and contract test passed
  with no issues.
- `dart run tool/maintainiac_source_audit.dart` passed over the touched QA
  runner scope.
- `git diff --check` passed.
- Touched files remain under 500 lines:
  `receipt_qa_runner.dart` 406 lines,
  `receipt_qa_fixtures.dart` 166 lines, and
  `receipt_qa_runner_contract_test.dart` 187 lines.

Known follow-up:
- Continue adding fixture families without letting contract tests grow into the
  kind of oversized file this cleanup is meant to prevent.
## Pass 102 - 03:15:07 EDT to 03:16:28 EDT

Scope:
- Added a second noisy OCR QA fixture:
  `noisy fuel subtotal tax and total`.
- The fixture covers OCR-confused `O`/`0` numeric characters, noisy subtotal,
  tax, and total labels, and still expects fuel quantity and tax readiness.
- Added a focused `--pack=noisy` QA runner contract proving noisy-only runs
  report only noisy fixtures, include both noisy cases, keep the noisy pack
  score above `.90`, and return no fixture issues.

Verification:
- `flutter test test/receipt_qa_runner_contract_test.dart -r compact` passed.
- `dart analyze` over the QA runner, fixture file, and contract test passed
  with no issues.
- `dart run tool/maintainiac_source_audit.dart` passed over the touched QA
  runner scope.
- `git diff --check` passed.
- Touched files remain under 500 lines:
  `receipt_qa_runner.dart` 406 lines,
  `receipt_qa_fixtures.dart` 166 lines, and
  `receipt_qa_runner_contract_test.dart` 245 lines.

Known follow-up:
- Add additional noisy OCR cases for skewed retail and maintenance receipts as
  those parser expectations are hardened.
## Pass 101 - 03:13:18 EDT to 03:14:38 EDT

Scope:
- Added a focused `--pack=fuel` QA runner contract.
- The new contract proves fuel-only runs report only fuel fixtures, include both
  the diesel baseline and split-row tender receipt, keep the fuel pack score
  above `.90`, and return no fixture issues.
- This gives future fuel/gas/diesel OCR/parser work a narrow verified QA target
  instead of always needing the all-pack runner.

Verification:
- `flutter test test/receipt_qa_runner_contract_test.dart -r compact` passed.
- `dart analyze` over the QA runner, fixture file, and contract test passed
  with no issues.
- `dart run tool/maintainiac_source_audit.dart` passed over the touched QA
  runner scope.
- `git diff --check` passed.
- Touched files remain under 500 lines:
  `receipt_qa_runner.dart` 406 lines,
  `receipt_qa_fixtures.dart` 151 lines, and
  `receipt_qa_runner_contract_test.dart` 208 lines.

Known follow-up:
- Add focused pack contracts for retail/noisy once those packs gain multiple
  meaningful fixtures.
## Pass 100 - 03:11:32 EDT to 03:12:47 EDT

Scope:
- Added a focused `--pack=maintenance` QA runner contract.
- The new contract proves maintenance-only runs report only maintenance
  fixtures, include both oil-change fixtures, keep the maintenance pack score
  above `.90`, and return no fixture issues.
- This gives future maintenance OCR/parser work a narrow verified QA target
  instead of always needing the all-pack runner.

Verification:
- `flutter test test/receipt_qa_runner_contract_test.dart -r compact` passed.
- `dart analyze` over the QA runner, fixture file, and contract test passed
  with no issues.
- `dart run tool/maintainiac_source_audit.dart` passed over the touched QA
  runner scope.
- `git diff --check` passed.
- Touched files remain under 500 lines:
  `receipt_qa_runner.dart` 406 lines,
  `receipt_qa_fixtures.dart` 151 lines, and
  `receipt_qa_runner_contract_test.dart` 171 lines.

Known follow-up:
- Add focused pack contracts for other high-value fixture families as they gain
  multiple meaningful cases.
## Pass 099 - 03:09:52 EDT to 03:10:21 EDT

Scope:
- Tightened `tool/receipt_quality_gate.sh` so the full receipt quality gate now
  runs `test/receipt_qa_runner_contract_test.dart`.
- This pins the shell gate to the hardened QA runner behavior: pack scores,
  supported pack reporting, focused-pack scoping, and unknown-pack blockers.
- Updated `docs/receipt_camera_world_class_qa_standard.md` so the written QA
  standard matches the current runner contract.

Verification:
- `flutter test test/receipt_qa_runner_contract_test.dart -r compact` passed.
- `bash -n tool/receipt_quality_gate.sh` passed.
- `dart analyze` over the QA runner, fixture file, and contract test passed
  with no issues.
- `dart run tool/maintainiac_source_audit.dart` passed over the touched Dart QA
  runner scope.
- `git diff --check` passed.
- Line counts remain under 500 for touched source/test/script files:
  `receipt_quality_gate.sh` 18 lines,
  `receipt_camera_world_class_qa_standard.md` 126 lines,
  `receipt_qa_runner.dart` 406 lines,
  `receipt_qa_fixtures.dart` 151 lines, and
  `receipt_qa_runner_contract_test.dart` 134 lines.

Known follow-up:
- The full `bash tool/receipt_quality_gate.sh` was not rerun in this pass
  because it includes the Android compile gate; run it after the next native
  camera edit or before handoff.
## Pass 098 - 03:07:59 EDT to 03:09:27 EDT

Scope:
- Hardened the pure Dart receipt QA runner against false-green empty pack runs.
- Added `availablePacks` to the JSON report so focused runs expose the supported
  fixture packs.
- Unknown `--pack=` values now create a blocker even when `--fail-under=0`,
  preventing a zero-fixture QA run from succeeding.
- Added contract coverage proving all-pack output reports available packs,
  long-receipt focused output remains scoped, and an unknown pack exits nonzero
  with a useful blocker.

Verification:
- `flutter test test/receipt_qa_runner_contract_test.dart -r compact` passed.
- `dart analyze` over the QA runner, fixture file, and contract test passed
  with no issues.
- `dart run tool/maintainiac_source_audit.dart` passed over the touched QA
  runner scope.
- `git diff --check` passed.
- Touched files remain under 500 lines:
  `receipt_qa_runner.dart` 406 lines,
  `receipt_qa_fixtures.dart` 151 lines, and
  `receipt_qa_runner_contract_test.dart` 134 lines.

Known follow-up:
- Keep focused pack runs available for rate-efficient work, but use all-pack QA
  whenever shared parser/scoring logic changes.
## Pass 097 - 03:06:13 EDT to 03:07:20 EDT

Scope:
- Added a QA runner contract for `--pack=long_receipt` so focused receipt-family
  QA can be trusted during future cleanup passes.
- The new contract proves the runner reports only long-receipt fixtures, returns
  only the `long_receipt` pack score, keeps the pack score above `.90`, and
  keeps every fixture issue-free.
- This gives future passes a narrower, rate-friendlier QA option when only one
  receipt family changes.

Verification:
- `flutter test test/receipt_qa_runner_contract_test.dart -r compact` passed.
- `dart analyze` over the QA runner, fixture file, and contract test passed
  with no issues.
- `dart run tool/maintainiac_source_audit.dart` passed over the touched QA
  runner scope.
- `git diff --check` passed.
- Touched files remain under 500 lines:
  `receipt_qa_runner.dart` 393 lines,
  `receipt_qa_fixtures.dart` 151 lines, and
  `receipt_qa_runner_contract_test.dart` 108 lines.

Known follow-up:
- Use `--pack=...` focused QA while adding more receipt-family fixtures and
  reserve the all-pack gate for changes that affect shared scoring/parser logic.
## Pass 096 - 03:03:50 EDT to 03:05:51 EDT

Scope:
- Added a long-receipt middle-section QA fixture for a continued receipt section
  with readable line items but no bottom total yet.
- Updated the QA runner contract to require
  `middle section overlap still needs bottom total`, so top, middle, and bottom
  long-receipt sections are all visible in the pure Dart QA gate.

Verification:
- First run of `flutter test test/receipt_qa_runner_contract_test.dart
  -r compact` failed because the new middle-section fixture incorrectly
  required a date. That is valid for top sections but not for many middle
  captures.
- Fixed the fixture by setting `expectDate: false` for the middle-section case.
- Rerun of `flutter test test/receipt_qa_runner_contract_test.dart -r compact`
  passed.
- `dart analyze` over the QA runner, fixture file, and contract test passed
  with no issues.
- `dart run tool/maintainiac_source_audit.dart` passed over the touched QA
  runner scope.
- `git diff --check` passed.
- Touched files remain under 500 lines:
  `receipt_qa_runner.dart` 393 lines,
  `receipt_qa_fixtures.dart` 151 lines, and
  `receipt_qa_runner_contract_test.dart` 80 lines.

Known follow-up:
- Continue tying long-receipt camera section guidance to parser/OCR handoff
  evidence, especially around repeated overlap lines and missing-bottom prompts.
## Pass 095 - 03:02:45 EDT to 03:03:25 EDT

Scope:
- Added a practical maintenance OCR/parser QA fixture for an oil-change receipt
  with odometer, oil weight, next-service due mileage, interval wording, tax,
  and total.
- Updated the QA runner contract to require the new
  `oil change odometer due interval` fixture, keeping maintenance support
  visible in the pure Dart gate.

Verification:
- `flutter test test/receipt_qa_runner_contract_test.dart -r compact` passed.
- `dart analyze` over the QA runner, fixture file, and contract test passed
  with no issues.
- `dart run tool/maintainiac_source_audit.dart` passed over the touched QA
  runner scope.
- `git diff --check` passed.
- Touched files remain under 500 lines:
  `receipt_qa_runner.dart` 393 lines,
  `receipt_qa_fixtures.dart` 134 lines, and
  `receipt_qa_runner_contract_test.dart` 79 lines.

Known follow-up:
- Add more fixture families for blurry/noisy OCR and long-receipt continuation
  once the next parser/camera guard is ready.
## Pass 094 - 03:01:24 EDT to 03:02:18 EDT

Scope:
- Strengthened the pure Dart receipt QA runner by adding `packScores` to the
  JSON report.
- The QA contract now verifies every expected receipt pack is present:
  `fuel`, `noisy`, `retail`, `maintenance`, and `long_receipt`.
- The contract also requires every pack score to stay at or above the current
  `.90` quality floor, so weak receipt families cannot hide behind the overall
  average.

Verification:
- `flutter test test/receipt_qa_runner_contract_test.dart -r compact` passed.
- `dart analyze tool/receipt_qa_runner.dart
  test/receipt_qa_runner_contract_test.dart` passed with no issues.
- `dart run tool/maintainiac_source_audit.dart` passed over the QA runner,
  fixture, and contract-test files.
- `git diff --check` passed.
- Touched files remain under 500 lines:
  `receipt_qa_runner.dart` 393 lines,
  `receipt_qa_fixtures.dart` 114 lines, and
  `receipt_qa_runner_contract_test.dart` 78 lines.

Known follow-up:
- Continue adding real fixture families and source-specific gates so OCR/parser
  quality can be measured by workflow, not only by a blended score.
