# HVAC Core Mac Validation Handoff

Generated: 2026-07-09 11:05 PM EDT

## Scope

Validate Maintainiac HVAC Core inventory/parser readiness on Mac. This is
inventory/parser QA only. Do not touch OCR, camera, expenses, UI, PDF, or
unrelated modules while following this handoff.

## Source

- Repository: `https://github.com/haftafish3760/maintainiac5.6-.git`
- Branch: `codex/inventory-parser-backup-20260702-2056`
- Commit: `45ea266`
- Commit label:
  `Reusable parsing QA 2026-07-09 11:05 PM EDT: narrow reusable docs and PEH rollup to hvac gap`

Cross-check the live reusable handoff packet before running anything on Mac:

- `dart run tool/reusable_parsing_qa_handoff_summary.dart --root .`
- expected:
  - `handoffClean=true`
  - `windowsExecutionCommit=45ea266`
  - `totalRemainingChecked=38`
  - `nextTradesByRemainingGap=["hvac"]`

## Windows Evidence Already Completed

- HVAC Core readiness audit JSON exists:
  `build/parser_qa_curation/hvac_core/latest_hvac_core_readiness_audit.json`
- Audit summary currently reports:
  - Core rows: `2695`
  - Release-ready items: `2695`
  - Metadata-ready candidates: `2695`
  - Needs-work items: `0`
  - Critical items: `0`
  - Ready for Mac validation: `true`

Family coverage already recorded in the current readiness audit includes:

- Air filters
- Controls and electrical
- Condensate
- Tape, sealants, and duct repair
- Ignition and gas heat
- Motors and blower parts

Measured generated sample evidence already on disk:

- rollup status:
  `build/parser_qa_pipeline/hvac_core_generated_run_status_samples.json`
  - Checked total: `12`
  - Failures: `0`
  - Parser calls: `22`
  - Measured pass rate: `1.0000`
  - Under minimum checked cells: `0`
  - Under minimum pass-rate cells: `0`
- en-US:
  `build/parser_qa_generated_run_samples/hvac/residential/core/en-US/reports/latest_generated_fixture_run.json`
  - Checked: `6`
  - Failures: `0`
  - Parser calls: `16`
  - Sample pass rate: `1.0000`
- es-US:
  `build/parser_qa_generated_run_samples/hvac/residential/core/es-US/reports/latest_generated_fixture_run.json`
  - Checked: `6`
  - Failures: `0`
  - Parser calls: `6`
  - Sample pass rate: `1.0000`

## Current Windows Limitation

The HVAC readiness audit artifact is present and clean, but the measured
generated pass-rate evidence is still only sample-sized on this branch and is
not yet broad enough to support a serious `0.90-0.95` release claim.

Also, direct `dart run` refresh attempts on this Windows box currently hit the
same environment-level FFI/build-hook compiler crash seen in other bounded
parser tools. Treat that as a Windows environment issue unless a narrower
parser failure proves otherwise.

Branch-level PEH checkpoint status also exists:

- `build/parser_qa_pipeline/peh_core_windows_status_rollup.json`
  - ready for Mac measurement wave: `true`
  - ready to claim `90-95%`: `false`
  - HVAC remains sample-sized until the broader Mac wave clears.

## Mac Validation Commands

Run from the repo root on the Mac after checking out commit `45ea266`.

```bash
dart format --set-exit-if-changed \
  tool/work_supply_hvac_core_readiness_audit.dart \
  test/work_supply_hvac_core_readiness_audit_test.dart
```

```bash
dart analyze \
  tool/work_supply_hvac_core_readiness_audit.dart \
  test/work_supply_hvac_core_readiness_audit_test.dart
```

```bash
flutter test test/work_supply_hvac_core_readiness_audit_test.dart
```

## Mac Follow-Through

After the audit test is green on Mac, the next Mac-side task is to generate or
validate the measured HVAC Core generated-fixture status layer before any
`90-95%` accuracy claim is attached to HVAC.

Do not treat the readiness audit alone as the final accuracy proof.

Use these exact next-step commands to raise HVAC measured coverage from the
current `12` checked cases to at least `50` checked cases:

```bash
dart run tool/work_supply_parser_qa_run_generated_fixtures.dart \
  --fixture build/parser_qa_generated/work_supply_parser/hvac/residential/core/en-US/generated_fixtures.json \
  --max-cases 25 \
  --chunk-size 25 \
  --min-pass-rate 0.90 \
  --timeout-ms 900000 \
  --stale-report-timeout-ms 240000 \
  --report-dir build/parser_qa_pipeline/mac_peh_core_measurement_25/hvac/residential/core/en-US/reports
```

```bash
dart run tool/work_supply_parser_qa_run_generated_fixtures.dart \
  --fixture build/parser_qa_generated/work_supply_parser/hvac/residential/core/es-US/generated_fixtures.json \
  --max-cases 25 \
  --chunk-size 25 \
  --min-pass-rate 0.90 \
  --timeout-ms 900000 \
  --stale-report-timeout-ms 240000 \
  --report-dir build/parser_qa_pipeline/mac_peh_core_measurement_25/hvac/residential/core/es-US/reports
```

Expected minimum result from those two commands together:

- total checked: `50`
- total failures: `0`
- rollup gate: `generated_run_status --min-pass-rate 0.90`
- each aggregate pass rate: at least `0.9000`
- local-only safety flags all false

Canonical plan:

- `docs/inventory_parser_peh_core_mac_measurement_plan.md`

## Pass Criteria

- Analyzer has no issues for the touched HVAC audit files.
- HVAC Core readiness audit test passes.
- Generated readiness JSON still reports `2695/2695` release-ready,
  `0` needs-work, `0` critical, and `readyForMacValidation=true`.
- No production services are used.
- No Firebase writes are allowed.
- No OCR, camera, expenses, UI, PDF, or unrelated modules are edited.

## If Mac Validation Fails

- Do not broaden the run first.
- Capture the exact command, exit code, and artifact path.
- Separate platform/setup failures from parser/catalog failures.
- Add a regression before marking any confirmed parser bug fixed.
