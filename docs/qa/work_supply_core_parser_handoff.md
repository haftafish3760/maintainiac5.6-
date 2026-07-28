# Core Receipt Parser Handoff

## Scope

This is a Work Supplies-only parser QA handoff for Plumbing, Electrical, and
HVAC items in the Core pack. Do not modify the shared receipt camera or OCR
capture pipeline as part of this work.

## Reproducible Stress Runner

Run this from the repository root:

```sh
dart --packages=.dart_tool/package_config.json \
  tool/work_supply_core_receipt_stress.dart \
  --per-trade=50 --seed=72726
```

The runner uses one Core catalog per trade and creates four synthetic receipt
forms: canonical catalog text, uppercase punctuation-stripped text, a catalog
alias, and a receipt pattern. It writes a generated report under `build/qa/`.

`exact_id` rows must resolve to the expected catalog ID. Bare aliases are
intentionally marked `review_required`; a different high-confidence item is a
safety problem, not a success.

## Recorded Baseline: 2026-07-27

The command above ran 150 total rows (50 per trade) in about three minutes on
the Mac Mini. The strict expected-ID subset scored 65 of 114 exact matches
(57.0%). Plumbing scored 28 of 38, Electrical 17 of 38, and HVAC 20 of 38.
Bare aliases produced 28 wrong-item matches from 36 rows.

Examples include a one-half-inch Push-Fit cap resolving to a one-inch cap, and
250-foot cable resolving to a 50-foot cable. This is not release-ready for
inventory or estimates.

## Required Repair Order

1. Turn each confirmed sibling collision into a deterministic regression fixture.
2. Reject or downgrade candidates that conflict with explicit size, pack count,
   length, color, finish, voltage, or product subtype evidence.
3. Re-run the focused fixture and existing trade parser tests after every fix.
4. Re-run the seeded stress command. Do not claim 90-95% real-receipt accuracy
   until there is a separately labeled realistic/field receipt corpus.
