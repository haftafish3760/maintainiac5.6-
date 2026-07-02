# Receipt Camera Cleanup Pass Log Archive - Pass 343

## Pass 343 - 11:10:02 EDT to 11:20:54 EDT

Scope:
- Added mixed business/personal line-use expectations to the pure Dart receipt
  QA runner and guarded them with the new `line_uses_matched` check.
- Added a Target mixed business/personal fixture covering nonzero business and
  personal allocation totals.
- Updated parser line creation to honor explicit personal/non-business line
  labels instead of forcing every parsed line to business use.
- Hardened downstream readiness diagnostics so status mismatches report actual
  status and line category/use/review state.
- Fixed retail/fuel readiness routing: generic mixed retail receipts stay
  expense-line ready, fuel receipts route to vehicle-cost readiness, plural
  snacks classify as meals, Target allows safety gear, and synthetic-oil
  maintenance lines no longer fall through as uncategorized review lines.

Failures fixed during this pass:
- The first QA runner failed the new mixed business/personal fixture at 91.7%.
- A widened retail rerun exposed stale vehicle-routing expectations and weak
  line diagnostics; added line-level mismatch evidence and fixed the parser
  category/readiness causes.
- Full QA then exposed stale fuel readiness expectations and a maintenance
  keyword gap; updated both and reran.

Verification:
- Passed `dart analyze` for the parser, QA runner, and focused parser test.
- Passed `dart run tool/receipt_qa_runner.dart --fail-under=0.95` at 100.0%
  across 15 fixtures.
- Passed focused Flutter parser/QA regressions, source audit, `bash
  tool/receipt_fast_guard_gate.sh`, and `git diff --check`.
- Footprint remains `total_receipt_camera_ocr_source` at 1.74 MB across 306
  files.
