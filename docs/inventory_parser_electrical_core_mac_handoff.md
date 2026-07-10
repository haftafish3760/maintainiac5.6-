# Electrical Core Mac Validation Handoff

Generated: 2026-07-09 10:35 PM EDT

## Scope

Validate Maintainiac Electrical Core inventory/parser readiness on Mac. This is
inventory/parser QA only. Do not touch OCR, camera, expenses, UI, PDF, or
unrelated modules while following this handoff.

## Source

- Repository: `https://github.com/haftafish3760/maintainiac5.6-.git`
- Branch: `codex/inventory-parser-backup-20260702-2056`
- Commit: `4427f5a`
- Commit label:
  `Reusable parsing QA 2026-07-09 10:35 PM EDT: sync reusable handoff to hvac-only wave`

Cross-check the live reusable handoff packet before running anything on Mac:

- `dart run tool/reusable_parsing_qa_handoff_summary.dart --root .`
- expected:
  - `handoffClean=true`
  - `windowsExecutionCommit=4427f5a`
  - `totalRemainingChecked=38`
  - `nextTradesByRemainingGap=["hvac"]`

## Windows Evidence Already Completed

- Electrical Core readiness audit JSON exists:
  `build/parser_qa_curation/electrical_core/latest_electrical_core_readiness_audit.json`
- Audit summary currently reports:
  - Core rows: `1902`
  - Release-ready items: `1902`
  - Metadata-ready candidates: `1902`
  - Needs-work items: `0`
  - Critical items: `0`
  - Readiness floor: `100`
  - Readiness average: `100`
  - Ready for Mac validation: `true`

Family coverage already recorded in the current readiness audit includes:

- Wire and cable
- Boxes and covers
- Devices and controls
- Service equipment and disconnects
- Breakers and panels
- Conduit and fittings
- Connectors and consumables
- Grounding and bonding
- Lighting and alarms

Measured generated sample evidence already on disk:

- rollup status:
  `build/parser_qa_pipeline/electrical_core_generated_run_status_samples.json`
  - Checked total: `12`
  - Failures: `0`
  - Parser calls: `12`
  - Measured pass rate: `1.0000`
  - Under minimum checked cells: `0`
  - Under minimum pass-rate cells: `0`
- en-US:
  `build/parser_qa_generated_run_samples/electrical/residential/core/en-US/reports/latest_generated_fixture_run.json`
  - Checked: `6`
  - Failures: `0`
  - Parser calls: `6`
  - Sample pass rate: `1.0000`
- es-US:
  `build/parser_qa_generated_run_samples/electrical/residential/core/es-US/reports/latest_generated_fixture_run.json`
  - Checked: `6`
  - Failures: `0`
  - Parser calls: `6`
  - Sample pass rate: `1.0000`

## Current Windows Limitation

The Electrical readiness audit artifact is present and clean, but the measured
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
  - Electrical already meets the current checked-case target on Windows and is
    excluded from the narrowed active Mac wave.

## Mac Validation Commands

Run from the repo root on the Mac after checking out commit `4427f5a`.

## Current Active Mac Wave

Electrical is already satisfied at the current Windows checkpoint. The live PEH
Mac wave is now intentionally narrowed to HVAC only, so do not rerun the
Electrical 25-case Mac wave unless a later checkpoint reopens Electrical in the
measurement gap.

```bash
dart format --set-exit-if-changed \
  tool/work_supply_electrical_core_readiness_audit.dart \
  test/work_supply_electrical_core_readiness_audit_test.dart
```

```bash
dart analyze \
  tool/work_supply_electrical_core_readiness_audit.dart \
  test/work_supply_electrical_core_readiness_audit_test.dart
```

```bash
flutter test test/work_supply_electrical_core_readiness_audit_test.dart
```

## Mac Follow-Through

After the audit test is green on Mac, stop unless a later checkpoint reopens
Electrical in the measurement gap. Electrical is already satisfied at the
current Windows checkpoint and is intentionally excluded from the narrowed
active Mac wave.

Do not rerun the Electrical 25-case Mac wave unless the live handoff summary
shows Electrical back inside `nextTradesByRemainingGap`.

Canonical plan:

- `docs/inventory_parser_peh_core_mac_measurement_plan.md`

## Pass Criteria

- Analyzer has no issues for the touched Electrical audit files.
- Electrical Core readiness audit test passes.
- Generated readiness JSON still reports `1902/1902` release-ready,
  `0` needs-work, `0` critical, and `readyForMacValidation=true`.
- No production services are used.
- No Firebase writes are allowed.
- No OCR, camera, expenses, UI, PDF, or unrelated modules are edited.

## If Mac Validation Fails

- Do not broaden the run first.
- Capture the exact command, exit code, and artifact path.
- Separate platform/setup failures from parser/catalog failures.
- Add a regression before marking any confirmed parser bug fixed.
