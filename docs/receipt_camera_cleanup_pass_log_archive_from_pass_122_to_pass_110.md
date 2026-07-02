# Receipt Camera Cleanup Pass Log Archive

Archived pass entries from `receipt_camera_cleanup_pass_log.md`. This file covers physical log order from pass 122 to pass 110.

## Pass 122 - 04:16:00 EDT to 04:17:41 EDT

Scope:
- Added a noisy home-center material fixture to the pure Dart QA runner's
  `noisy` pack.
- The new fixture covers OCR letter/number swaps such as `H0ME DEP0T`,
  `C0PPER`, `9O`, comma-as-decimal money, and `T0TAL`.
- Asserted exact merchant/date/total, material line subtotals, material line
  families, business/personal totals, and downstream inventory-material
  readiness count buckets.
- Updated the focused noisy-pack contract from two to three fixtures.

Verification:
- `flutter test test/receipt_qa_runner_contract_test.dart -r compact` passed.
- `dart analyze` over the touched noisy fixture file and contract test passed
  with no issues.
- `dart run tool/maintainiac_source_audit.dart` passed over the touched files.
- `git diff --check` passed.
- Touched files remain under 500 lines:
  `receipt_qa_fixtures_fuel.dart` 167 lines and
  `receipt_qa_runner_contract_test.dart` 249 lines.

Known follow-up:
- Add a noisy material truncation fixture for compact amount/tender rows, then
  continue expanding pack-specific coverage without growing any one file past
  the source-size guardrail.
## Pass 121 - 04:13:10 EDT to 04:15:32 EDT

Scope:
- Split the monolithic pure Dart receipt QA fixture file into pack-specific
  part files:
  `receipt_qa_fixtures_fuel.dart`,
  `receipt_qa_fixtures_adjustment_retail.dart`,
  `receipt_qa_fixtures_maintenance.dart`, and
  `receipt_qa_fixtures_long_receipt.dart`.
- Reduced `receipt_qa_fixtures.dart` from 391 lines to an 8-line aggregator.
- Kept fixture ordering and behavior unchanged.

Verification:
- `flutter test test/receipt_qa_runner_contract_test.dart -r compact` passed.
- `dart analyze` over the QA runner, fixture aggregator, fixture pack files,
  and contract test passed with no issues.
- `dart run tool/maintainiac_source_audit.dart` passed over the touched QA
  fixture scope.
- `git diff --check` passed.
- Touched files remain under 500 lines:
  `receipt_qa_runner.dart` 310 lines,
  `receipt_qa_fixtures.dart` 8 lines,
  `receipt_qa_fixtures_fuel.dart` 137 lines,
  `receipt_qa_fixtures_adjustment_retail.dart` 103 lines,
  `receipt_qa_fixtures_maintenance.dart` 88 lines,
  `receipt_qa_fixtures_long_receipt.dart` 75 lines, and
  `receipt_qa_runner_contract_test.dart` 248 lines.

Known follow-up:
- Continue adding pack-specific samples and diagnostic checks now that fixture
  growth is isolated by receipt type.
## Pass 120 - 04:08:54 EDT to 04:12:51 EDT

Scope:
- Added expected parser downstream readiness count support to the pure Dart
  receipt QA fixture model.
- The review/admin scorer now emits `downstream_readiness_counts_matched`,
  comparing selected expected diagnostic buckets against
  `parserDownstreamReadinessCounts`.
- Added representative readiness count expectations for fuel, noisy OCR fuel,
  adjustment/review, retail review, maintenance/vehicle-cost, and material
  long-receipt fixtures.

Failure fixed during this pass:
- The first focused contract run failed on the Quick Lube maintenance fixture.
- A temporary diagnostics probe showed the first Quick Lube line is currently
  `Uncategorized` and needs review, while the other two lines are vehicle-ready.
  Updated the expected bucket from `vehicle_cost_needs_review` to
  `category_family_uncategorized_needs_review`.

Verification:
- `flutter test test/receipt_qa_runner_contract_test.dart -r compact` failed
  once, was corrected, then passed on rerun.
- `dart analyze` over the QA runner, fixture file, review scoring part, and
  contract test passed with no issues.
- `dart run tool/maintainiac_source_audit.dart` passed over the touched QA
  runner scope.
- `git diff --check` passed.
- Touched files remain under 500 lines:
  `receipt_qa_runner.dart` 306 lines,
  `receipt_qa_fixtures.dart` 391 lines,
  `receipt_qa_scoring_review.dart` 103 lines, and
  `receipt_qa_runner_contract_test.dart` 248 lines.

Known follow-up:
- The fixture file is now 391 lines, so split fixture packs before adding more
  samples or diagnostic expectations.
## Pass 119 - 04:04:13 EDT to 04:08:25 EDT

Scope:
- Added expected parser downstream readiness status and downstream readiness
  summary support to the pure Dart receipt QA fixture model.
- The review/admin scorer now emits `downstream_readiness_status_matched` and
  `downstream_readiness_summary_matched`, backed by production parser
  diagnostics.
- Added readiness expectations for stable fuel, noisy OCR fuel, retail,
  adjustment, maintenance, and completed long-receipt bottom fixtures.

Failure fixed during this pass:
- The first focused contract run failed on the CVS adjustment fixture, the
  Walmart retail baseline, and the bottom-only long-receipt section.
- A temporary parser probe showed the production statuses were intentionally
  `expense_lines_need_review` for those samples: CVS and Walmart each have a
  review line, and the bottom-only long-receipt section lacks header/date
  context. Updated those fixture expectations to assert the review state.

Verification:
- `flutter test test/receipt_qa_runner_contract_test.dart -r compact` failed
  once, was corrected, then passed on rerun.
- `dart analyze` over the QA runner, fixture file, review scoring part, and
  contract test passed with no issues.
- `dart run tool/maintainiac_source_audit.dart` passed over the touched QA
  runner scope.
- `git diff --check` passed.
- Touched files remain under 500 lines:
  `receipt_qa_runner.dart` 304 lines,
  `receipt_qa_fixtures.dart` 334 lines,
  `receipt_qa_scoring_review.dart` 80 lines, and
  `receipt_qa_runner_contract_test.dart` 247 lines.

Known follow-up:
- Add exact parser downstream readiness count expectations for the most
  important buckets, such as `vehicle_cost_ready`, `inventory_material_ready`,
  `line_needs_review`, and privacy-safe tender exclusion signals.
## Pass 118 - 04:02:22 EDT to 04:03:45 EDT

Scope:
- Split business/personal allocation and parser review/admin scoring out of
  `receipt_qa_scoring.dart` into `receipt_qa_scoring_review.dart`.
- Added the new review scoring part to `receipt_qa_runner.dart`.
- Kept behavior unchanged while reducing the main scorer from 406 lines to 375
  lines before adding more review/admin diagnostics.

Verification:
- `flutter test test/receipt_qa_runner_contract_test.dart -r compact` passed.
- `dart analyze` over the QA runner, scorer, review scoring part, and contract
  test passed with no issues.
- `dart run tool/maintainiac_source_audit.dart` passed over the touched QA
  runner scope.
- `git diff --check` passed.
- Touched files remain under 500 lines:
  `receipt_qa_runner.dart` 300 lines,
  `receipt_qa_scoring.dart` 375 lines,
  `receipt_qa_scoring_review.dart` 54 lines, and
  `receipt_qa_runner_contract_test.dart` 245 lines.

Known follow-up:
- Continue adding review/admin diagnostic expectations now that the scoring
  surface has room again.
## Pass 117 - 03:59:07 EDT to 04:02:02 EDT

Scope:
- Added expected parser review-line count support to the pure Dart receipt QA
  fixture model.
- The scorer now emits `review_line_count_matched` in the `privacy_admin`
  dimension, backed by `parsed.diagnostics.reviewLineCount`.
- Added clean-review expectations for stable fuel and Take 5 maintenance
  fixtures.
- Added explicit one-review-line expectations for the CVS coupon/discount
  fixture and the Quick Lube baseline fixture so admin/review state is asserted
  instead of implied.

Failure fixed during this pass:
- The first focused contract run failed because the CVS adjustment fixture and
  Quick Lube baseline had one parser-review line each, not zero.
- Updated those two fixture expectations to require one review line, preserving
  the QA signal instead of weakening the check.

Verification:
- `flutter test test/receipt_qa_runner_contract_test.dart -r compact` failed
  once, was fixed, then passed on rerun.
- `dart analyze` over the QA runner, fixture file, scoring part, and contract
  test passed with no issues.
- `dart run tool/maintainiac_source_audit.dart` passed over the touched QA
  runner scope.
- `git diff --check` passed.
- Touched files remain under 500 lines:
  `receipt_qa_runner.dart` 299 lines,
  `receipt_qa_fixtures.dart` 314 lines,
  `receipt_qa_scoring.dart` 406 lines, and
  `receipt_qa_runner_contract_test.dart` 245 lines.

Known follow-up:
- Split review/admin scoring out of `receipt_qa_scoring.dart` before adding
  more diagnostic expectations, because the scorer is now at 406 lines.
## Pass 116 - 03:56:55 EDT to 03:58:40 EDT

Scope:
- Added expected business and personal total support to the pure Dart receipt
  QA fixture model.
- The scorer now emits `business_total_matched` and
  `personal_total_matched` checks in the `business_personal` dimension.
- Added exact business/personal total expectations to complete fuel, noisy OCR,
  adjustment, retail, maintenance, and bottom-section long-receipt fixtures.
- Left top/middle long-receipt continuation fixtures without exact allocation
  totals because they intentionally represent incomplete receipt sections.

Verification:
- `flutter test test/receipt_qa_runner_contract_test.dart -r compact` passed.
- `dart analyze` over the QA runner, fixture file, scoring part, and contract
  test passed with no issues.
- `dart run tool/maintainiac_source_audit.dart` passed over the touched QA
  runner scope.
- `git diff --check` passed.
- Touched files remain under 500 lines:
  `receipt_qa_runner.dart` 297 lines,
  `receipt_qa_fixtures.dart` 309 lines,
  `receipt_qa_scoring.dart` 395 lines, and
  `receipt_qa_runner_contract_test.dart` 244 lines.

Known follow-up:
- Add parser review/admin diagnostic expectations next, then split the scorer
  again before it gets too close to the 500-line limit.
## Pass 115 - 03:52:19 EDT to 03:56:14 EDT

Scope:
- Added exact maintenance hint expectations to the pure Dart receipt QA fixture
  model: service type, oil weight, service odometer, due odometer, mileage
  interval, and month interval.
- The scorer now emits maintenance checks for service type, oil weight, service
  odometer, due odometer, mileage interval, and month interval.
- Added exact maintenance expectations to the Quick Lube and Take 5 fixtures.
- Repaired production maintenance parsing so `NEXT SERVICE 92,500 MILES`
  extracts the due odometer, not only longer phrases like `next service due`.
- Added direct parser coverage for the shorter due-odometer phrase in
  `expense_receipt_parser_materials_maintenance_test.dart`.

Failure fixed during this pass:
- The first focused run failed with
  `production_parser_maintenance_due_odometer_mismatch` on the Quick Lube
  baseline fixture.
- The failure traced to `_maintenanceDueOdometerFor` missing the common
  `next service <miles>` wording. The regex now accepts that phrase.

Verification:
- `flutter test test/expense_receipt_parser_materials_maintenance_test.dart
  test/receipt_qa_runner_contract_test.dart -r compact` failed once, was fixed,
  then passed on rerun.
- `dart analyze` over the touched maintenance parser, parser test, QA runner,
  fixture, scorer, and contract test files passed with no issues.
- `dart run tool/maintainiac_source_audit.dart` passed over the touched receipt
  scope.
- `git diff --check` passed.
- Touched files remain under 500 lines:
  `expense_receipt_maintenance_parser.dart` 138 lines,
  `expense_receipt_parser_materials_maintenance_test.dart` 270 lines,
  `receipt_qa_runner.dart` 293 lines,
  `receipt_qa_fixtures.dart` 289 lines,
  `receipt_qa_scoring.dart` 373 lines, and
  `receipt_qa_runner_contract_test.dart` 242 lines.

Known follow-up:
- Add QA checks for business/personal allocation modes and review/admin
  diagnostics next, so parsed line totals do not merely reconcile globally but
  remain usable for the user-facing review workflow.
## Pass 114 - 03:50:12 EDT to 03:51:53 EDT

Scope:
- Split receipt QA scoring matcher/helper functions out of
  `receipt_qa_scoring.dart` into `receipt_qa_scoring_matchers.dart`.
- Added the new matcher part to `receipt_qa_runner.dart`.
- Kept scoring behavior unchanged while reducing the main scorer from 360 lines
  to 300 lines before adding the next QA family.

Verification:
- `flutter test test/receipt_qa_runner_contract_test.dart -r compact` passed.
- `dart analyze` over the QA runner, scorer, matcher part, and contract test
  passed with no issues.
- `dart run tool/maintainiac_source_audit.dart` passed over the touched QA
  runner scope.
- `git diff --check` passed.
- Touched files remain under 500 lines:
  `receipt_qa_runner.dart` 281 lines,
  `receipt_qa_scoring.dart` 300 lines,
  `receipt_qa_scoring_matchers.dart` 61 lines, and
  `receipt_qa_runner_contract_test.dart` 236 lines.

Known follow-up:
- Add exact maintenance interval checks now that scorer helpers have room to
  grow without crowding the main scoring file.
## Pass 113 - 03:44:36 EDT to 03:49:36 EDT

Scope:
- Added exact fuel-detail expectations to the pure Dart receipt QA fixture
  model: quantity, unit price, fuel type, fuel unit, and odometer.
- The scorer now emits `fuel_quantity_matched`, `fuel_unit_price_matched`,
  `fuel_type_matched`, `fuel_unit_matched`, and `fuel_odometer_matched` checks
  against the first parsed production fuel line.
- Added fuel detail expectations to stable fuel and noisy OCR fuel fixtures,
  including Pilot odometer extraction.
- Repaired production OCR numeric normalization so decimal fuel quantities and
  amounts like `1O.OOO`, `35.OO`, and `37.1O` normalize before parser handoff.
- Added a direct parser regression inside
  `expense_receipt_parser_math_review_test.dart` for the decimal-`O` fuel
  quantity case.

Failure fixed during this pass:
- The first focused QA contract run failed because the noisy Shell fixture did
  not match expected fuel quantity or unit price.
- The failure traced to OCR normalization handling `O` beside digits, but not
  inside decimal numeric tokens. Added `_normalizeOcrNumericLetters` to convert
  only numeric-looking OCR tokens that contain both digits and `O/o`, avoiding
  word-level changes such as `OIL`.

Verification:
- `flutter test test/expense_receipt_parser_math_review_test.dart
  test/receipt_qa_runner_contract_test.dart -r compact` passed after the
  parser normalization fix.
- `dart analyze` over the touched parser, QA runner, fixture, scoring, and
  contract test files passed with no issues.
- `dart run tool/maintainiac_source_audit.dart` passed over the touched receipt
  scope.
- `git diff --check` passed.
- Touched files remain under 500 lines:
  `expense_receipt_parser_merchant_totals_logic.dart` 332 lines,
  `expense_receipt_parser_math_review_test.dart` 392 lines,
  `receipt_qa_runner.dart` 280 lines,
  `receipt_qa_fixtures.dart` 280 lines,
  `receipt_qa_scoring.dart` 360 lines, and
  `receipt_qa_runner_contract_test.dart` 236 lines.

Known follow-up:
- Split the growing receipt QA scorer before adding maintenance interval exact
  checks, because `receipt_qa_scoring.dart` is still under the limit but now
  carries several independent scoring families.
## Pass 112 - 03:41:38 EDT to 03:43:56 EDT

Scope:
- Added expected negative-line count, receipt-adjustment count, and
  reconciliation expectations to the pure Dart receipt QA fixture model.
- The scorer now emits `negative_line_count_matched`,
  `adjustment_line_count_matched`, and `reconciliation_expectation_met` checks
  backed by production parser diagnostics.
- Strengthened the Pilot fuel discount fixture so it now asserts two parsed
  rows, the fuel subtotal, the rewards discount subtotal, one negative line,
  one adjustment line, and reconciled totals.
- Added a dedicated `adjustment` fixture pack with a CVS coupon/store-discount
  receipt and focused pack coverage in the contract test.

Verification:
- `flutter test test/receipt_qa_runner_contract_test.dart -r compact` passed.
- `dart analyze` over the QA runner, fixture file, scoring part, and contract
  test passed with no issues.
- `dart run tool/maintainiac_source_audit.dart` passed over the touched QA
  runner scope.
- `git diff --check` passed.
- Touched files remain under 500 lines:
  `receipt_qa_runner.dart` 270 lines,
  `receipt_qa_fixtures.dart` 264 lines,
  `receipt_qa_scoring.dart` 308 lines, and
  `receipt_qa_runner_contract_test.dart` 231 lines.

Known follow-up:
- Add exact fuel detail expectations for quantity, unit price, fuel type, and
  odometer so the QA runner catches fuel-specific regressions beyond category
  and total math.
## Pass 111 - 03:37:36 EDT to 03:40:58 EDT

Scope:
- Added `expectedLineFamilies` support to the pure Dart receipt QA fixture
  model.
- The scorer now emits `line_families_matched` checks and
  `production_parser_line_families_mismatch` issues when stable receipt lines
  drift into the wrong parser expense family.
- Added family expectations for stable fuel, noisy OCR fuel, maintenance, and
  long-receipt material rows.
- Strengthened the QA runner contract so line-family scoring must remain
  present in the JSON check list.

Failure fixed during this pass:
- The first focused contract run failed with
  `production_parser_line_families_mismatch` in the fuel pack.
- The brittle expectation was on the Pilot fixture, whose purpose includes a
  rewards/discount row. Removed that single family expectation until discounts
  have an explicit QA model instead of pretending the fixture has one stable
  fuel-only row.

Verification:
- `flutter test test/receipt_qa_runner_contract_test.dart -r compact` failed
  once, was fixed, then passed on rerun.
- `dart analyze` over the QA runner, fixture file, scoring part, and contract
  test passed with no issues.
- `dart run tool/maintainiac_source_audit.dart` passed over the touched QA
  runner scope.
- `git diff --check` passed.
- Touched files remain under 500 lines:
  `receipt_qa_runner.dart` 264 lines,
  `receipt_qa_fixtures.dart` 227 lines,
  `receipt_qa_scoring.dart` 272 lines, and
  `receipt_qa_runner_contract_test.dart` 214 lines.

Known follow-up:
- Add an explicit discount/adjustment-line QA model so receipts with rewards,
  coupons, and negative line items can be asserted without weakening true fuel
  or material family checks.
## Pass 110 - 03:35:05 EDT to 03:37:01 EDT

Scope:
- Added `expectedLineSubtotals` support to the pure Dart receipt QA fixture
  model.
- The scorer now emits `line_subtotals_matched` checks and
  `production_parser_line_subtotals_mismatch` issues when parsed receipt line
  amounts drift from stable fixture expectations.
- Added line-subtotal expectations to retail, maintenance, and long-receipt
  fixtures where each expected line amount is explicit in the fixture text.
- Strengthened the QA runner contract so per-line amount scoring must remain
  present in the JSON check list.

Verification:
- `flutter test test/receipt_qa_runner_contract_test.dart -r compact` passed.
- `dart analyze` over the QA runner, fixture file, scoring part, and contract
  test passed with no issues.
- `dart run tool/maintainiac_source_audit.dart` passed over the touched QA
  runner scope.
- `git diff --check` passed.
- Touched files remain under 500 lines:
  `receipt_qa_runner.dart` 262 lines,
  `receipt_qa_fixtures.dart` 215 lines,
  `receipt_qa_scoring.dart` 248 lines, and
  `receipt_qa_runner_contract_test.dart` 213 lines.

Known follow-up:
- Add fixture coverage for line-family/category expectations so maintenance,
  fuel, supplies, and retail rows cannot silently drift into the wrong expense
  bucket.
