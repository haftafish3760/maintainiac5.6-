# PEH Core Mac Measurement Expansion Plan

Generated: 2026-07-09 13:34 EDT

## Purpose

This plan defines the next measured Mac-side validation wave for Maintainiac
PEH Core inventory/parser QA. It exists so Electrical and HVAC move from
smoke-sized generated evidence to a more defensible measured floor without
guesswork or ad hoc report locations.

## Scope

- Repo: `C:\Users\rjenk\Documents\Mainteniac 5.6`
- Branch: `codex/inventory-parser-backup-20260702-2056`
- Commit baseline: `5082b8c`
- Area: inventory/catalog/parser/QA only
- Do not touch: OCR, camera, stitching, expenses, UI, PDF, or unrelated
  modules

## Required Preconditions

Run these first on the Mac:

```bash
dart format --set-exit-if-changed \
  tool/work_supply_parser_qa_run_generated_fixtures.dart \
  tool/work_supply_parser_qa_generated_run_status.dart \
  tool/work_supply_electrical_core_readiness_audit.dart \
  tool/work_supply_hvac_core_readiness_audit.dart \
  test/work_supply_parser_qa_run_generated_fixtures_test.dart \
  test/work_supply_electrical_core_readiness_audit_test.dart \
  test/work_supply_hvac_core_readiness_audit_test.dart
```

```bash
dart analyze \
  tool/work_supply_parser_qa_run_generated_fixtures.dart \
  tool/work_supply_parser_qa_generated_run_status.dart \
  tool/work_supply_electrical_core_readiness_audit.dart \
  tool/work_supply_hvac_core_readiness_audit.dart \
  test/work_supply_parser_qa_run_generated_fixtures_test.dart \
  test/work_supply_electrical_core_readiness_audit_test.dart \
  test/work_supply_hvac_core_readiness_audit_test.dart
```

## Plumbing Runtime Confirmation

Keep Plumbing as the stronger baseline before growing the other two trades.

```bash
flutter test test/work_supply_plumbing_receipt_parser_test.dart \
  --plain-name "plumbing receipt parser handles Menards PVC sanitary tee line"
```

Expected result:

- focused Menards sanitary-tee test completes in reasonable time on Mac

## Electrical Measurement Wave

Run exactly these two commands:

```bash
dart run tool/work_supply_parser_qa_run_generated_fixtures.dart \
  --fixture build/parser_qa_generated/work_supply_parser/electrical/residential/core/en-US/generated_fixtures.json \
  --max-cases 25 \
  --chunk-size 25 \
  --min-pass-rate 0.90 \
  --timeout-ms 900000 \
  --stale-report-timeout-ms 240000 \
  --report-dir build/parser_qa_pipeline/mac_peh_core_measurement_25/electrical/residential/core/en-US/reports
```

```bash
dart run tool/work_supply_parser_qa_run_generated_fixtures.dart \
  --fixture build/parser_qa_generated/work_supply_parser/electrical/residential/core/es-US/generated_fixtures.json \
  --max-cases 25 \
  --chunk-size 25 \
  --min-pass-rate 0.90 \
  --timeout-ms 900000 \
  --stale-report-timeout-ms 240000 \
  --report-dir build/parser_qa_pipeline/mac_peh_core_measurement_25/electrical/residential/core/es-US/reports
```

Then roll them up:

```bash
dart run tool/work_supply_parser_qa_generated_run_status.dart \
  --report-root build/parser_qa_pipeline/mac_peh_core_measurement_25 \
  --trades electrical \
  --scopes residential \
  --tiers core \
  --locales en-US,es-US \
  --require-complete \
  --min-checked-per-cell 25 \
  --min-pass-rate 0.90 \
  --output build/parser_qa_pipeline/mac_electrical_core_generated_run_status_25.json
```

Electrical minimum pass criteria:

- expected cells: `2`
- present cells: `2`
- missing cells: `0`
- failed cells: `0`
- unsafe cells: `0`
- underMinCheckedCells: `0`
- underMinPassRateCells: `0`
- checkedTotal: `50`
- rollup pass rate: at least `0.9000`
- measured pass-rate floor preserved by each aggregate run

## HVAC Measurement Wave

Run exactly these two commands:

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

Then roll them up:

```bash
dart run tool/work_supply_parser_qa_generated_run_status.dart \
  --report-root build/parser_qa_pipeline/mac_peh_core_measurement_25 \
  --trades hvac \
  --scopes residential \
  --tiers core \
  --locales en-US,es-US \
  --require-complete \
  --min-checked-per-cell 25 \
  --min-pass-rate 0.90 \
  --output build/parser_qa_pipeline/mac_hvac_core_generated_run_status_25.json
```

HVAC minimum pass criteria:

- expected cells: `2`
- present cells: `2`
- missing cells: `0`
- failed cells: `0`
- unsafe cells: `0`
- underMinCheckedCells: `0`
- underMinPassRateCells: `0`
- checkedTotal: `50`
- rollup pass rate: at least `0.9000`
- measured pass-rate floor preserved by each aggregate run

## Result Interpretation

- If Plumbing focused runtime proof fails on Mac, fix that before claiming
  stronger Plumbing readiness.
- If Electrical or HVAC measured rollups fail, do not broaden the wave.
  Diagnose the smallest failing locale report first.
- If both Electrical and HVAC 25-per-locale waves pass, update:
  - `docs/inventory_parser_peh_core_windows_evidence_rollup.md`
  - `docs/inventory_parser_electrical_core_mac_handoff.md`
  - `docs/inventory_parser_hvac_core_mac_handoff.md`

## Why This Plan Exists

The current Windows branch already proves:

- Plumbing has stronger measured evidence.
- Electrical and HVAC have clean readiness audits.
- Electrical and HVAC only have smoke-sized measured samples so far.

This plan is the shortest professional path from that state to stronger,
measured, trade-specific proof without drifting into unrelated work.
