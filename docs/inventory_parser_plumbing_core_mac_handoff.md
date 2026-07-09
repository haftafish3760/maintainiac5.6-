# Plumbing Core Mac Validation Handoff

Generated: 2026-07-09 11:55 EDT

## Scope

Validate Maintainiac Plumbing Core inventory/parser readiness on Mac. This is
inventory/parser QA only. Do not touch OCR, camera, expenses, UI, PDF, or
unrelated modules while following this handoff.

## Source

- Repository: `https://github.com/haftafish3760/maintainiac5.6-.git`
- Branch: `codex/inventory-parser-backup-20260702-2056`
- Commit: `5275746`
- Commit label:
  `QA testing 2026-07-09 14:51 EDT: add PEH core status checkpoint rollup`

## Windows Evidence Already Completed

- Generated fixture runner offset regression passed.
- Toilet/faucet shard 1 passed:
  `build/parser_qa_reports/generated_fixtures/toilet_faucet_80_shard1_rerun3_20260707_085222`
- Toilet/faucet shard 2 passed:
  `build/parser_qa_reports/generated_fixtures/toilet_faucet_80_shard2_corrected_20260707_094016`
- Toilet/faucet shard 3 passed:
  `build/parser_qa_reports/generated_fixtures/toilet_faucet_73_shard3_corrected_20260707_094538`
- Plumbing Core readiness audit passed:
  `build/parser_qa_curation/plumbing_core/latest_plumbing_core_readiness_audit.json`
- Plumbing Core generated benchmark status passed:
  `build/parser_qa_pipeline/plumbing_core_generated_run_status.json`
- Branch-level PEH checkpoint passed for Mac-wave readiness:
  `build/parser_qa_pipeline/peh_core_windows_status_rollup.json`
- Plumbing Core generated benchmark review-seed status passed:
  `build/parser_qa_pipeline/plumbing_core_generated_run_status_100_reviewseed_v5.json`

Final Windows readiness JSON:

- Core rows: `1241`
- Release-ready items: `1241`
- Metadata-ready candidates: `1241`
- Needs-work items: `0`
- Critical items: `0`
- Readiness floor: `100`
- Readiness average: `100`
- Ready for Mac validation: `true`

Generated benchmark evidence already present on Windows:

- Focused generated benchmark cell: `100` checked
- Failure count: `0`
- Parser calls: `100`
- Local-only safe: `true`
- Chunk status: complete with `0` non-zero exits and `0` timed-out chunks

## Current Windows Limitation

Windows deterministic evidence is strong, but one focused runtime bottleneck is
still worth validating on Mac:

- A focused `flutter test --no-pub` rerun for
  `plumbing receipt parser handles Menards PVC sanitary tee line`
  still hangs past the normal 2-minute Codex shell timeout on this older
  Windows box.
- The parser code now includes a dedicated cached fast path for
  `PVC/DWV sanitary tee` lines before the broader unscoped matcher chain.
- The Windows-side generated benchmark artifacts still show `100/100` passing,
  so this looks like a focused runtime/perf-validation problem rather than a
  known catalog-readiness failure.

## Mac Validation Commands

Run from the repo root on the Mac after checking out commit `5275746`.

```bash
dart format --set-exit-if-changed \
  tool/work_supply_plumbing_core_readiness_audit.dart \
  test/work_supply_plumbing_core_readiness_audit_test.dart \
  test/work_supply_parser_qa_run_generated_fixtures_test.dart \
  tool/work_supply_parser_qa_run_generated_fixtures.dart \
  lib/screens/work_supplies/data/work_supply_receipt_parser.dart \
  test/work_supply_plumbing_receipt_parser_test.dart
```

```bash
dart analyze \
  tool/work_supply_plumbing_core_readiness_audit.dart \
  test/work_supply_plumbing_core_readiness_audit_test.dart \
  tool/work_supply_parser_qa_run_generated_fixtures.dart \
  test/work_supply_parser_qa_run_generated_fixtures_test.dart \
  lib/screens/work_supplies/data/work_supply_receipt_parser.dart \
  test/work_supply_plumbing_receipt_parser_test.dart
```

```bash
flutter test test/work_supply_parser_qa_run_generated_fixtures_test.dart \
  --plain-name "generated fixture wrapper treats max cases as window length after offset"
```

```bash
flutter test test/work_supply_plumbing_core_readiness_audit_test.dart
```

```bash
flutter test test/work_supply_plumbing_receipt_parser_test.dart \
  --plain-name "plumbing receipt parser handles Menards PVC sanitary tee line"
```

## Optional Mac Parser Proof

Only run these if the Mac is available for heavier validation. These are not
needed to re-debug Windows logic unless they fail on Mac.

```bash
dart run tool/work_supply_parser_qa_run_generated_fixtures.dart \
  --fixture build/parser_qa_generated_family_toilet_faucet/work_supply_parser/plumbing/residential/core/en-US/generated_fixtures.json \
  --start-index 80 \
  --max-cases 80 \
  --chunk-size 80 \
  --timeout-ms 900000 \
  --stale-report-timeout-ms 240000 \
  --report-dir build/parser_qa_reports/generated_fixtures/mac_toilet_faucet_80_shard2
```

```bash
dart run tool/work_supply_parser_qa_run_generated_fixtures.dart \
  --fixture build/parser_qa_generated_family_toilet_faucet/work_supply_parser/plumbing/residential/core/en-US/generated_fixtures.json \
  --start-index 160 \
  --max-cases 73 \
  --chunk-size 73 \
  --timeout-ms 900000 \
  --stale-report-timeout-ms 240000 \
  --report-dir build/parser_qa_reports/generated_fixtures/mac_toilet_faucet_73_shard3
```

Canonical follow-through plan:

- `docs/inventory_parser_peh_core_mac_measurement_plan.md`

## Pass Criteria

- Analyzer has no issues for the touched QA/audit files.
- Runner offset regression passes.
- Runner minimum pass-rate regression passes.
- Plumbing Core readiness audit passes.
- Generated readiness JSON still reports `1241/1241` release-ready,
  `0` needs-work, `0` critical, and `readyForMacValidation=true`.
- Generated benchmark status still reports `100` checked, `0` failures, and
  `parserCalls=100`.
- The focused Menards sanitary-tee parser test passes in a reasonable runtime on
  Mac.
- No production services are used.
- No Firebase writes are allowed.
- No OCR, camera, expenses, UI, PDF, or unrelated modules are edited.

## If Mac Validation Fails

- Do not broaden the test run first.
- Capture the exact command, exit code, and report path.
- If the failure is parser behavior, rerun the smallest fixture ID or shard that
  reproduces it.
- If the failure is platform setup, fix setup separately from parser/catalog
  logic.
- Add a regression before marking any confirmed parser bug fixed.
