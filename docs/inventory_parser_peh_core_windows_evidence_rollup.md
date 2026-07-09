# PEH Core Windows Evidence Rollup

Generated: 2026-07-09 14:32 EDT

## Scope

This rollup records the current Windows-side evidence for Maintainiac Plumbing,
Electrical, and HVAC Residential Core inventory/parser QA. It is inventory,
catalog, parser, and QA only.

It does not claim OCR readiness, camera readiness, UI readiness, or full
cross-platform release signoff.

## Source

- Branch: `codex/inventory-parser-backup-20260702-2056`
- Commit at rollup refresh: `f3876a9`

## Current Catalog Readiness

### Plumbing Core

- Readiness audit:
  `build/parser_qa_curation/plumbing_core/latest_plumbing_core_readiness_audit.json`
- Core rows: `1241`
- Release-ready rows: `1241`
- Needs-work rows: `0`
- Critical rows: `0`
- Ready for Mac validation: `true`

Measured generated evidence already recorded on Windows:

- Status file:
  `build/parser_qa_pipeline/plumbing_core_generated_run_status.json`
- Focused benchmark checked: `100`
- Failures: `0`
- Parser calls: `100`
- Measured pass rate: `1.0000`
- Under minimum checked cells: `0`
- Under minimum pass-rate cells: `0`

Current limitation:

- One focused Windows runtime bottleneck remains around the Menards PVC
  sanitary-tee rerun, so the final focused runtime proof is still better suited
  to Mac than this older Windows box.

### Electrical Core

- Readiness audit:
  `build/parser_qa_curation/electrical_core/latest_electrical_core_readiness_audit.json`
- Core rows: `1902`
- Release-ready rows: `1902`
- Needs-work rows: `0`
- Critical rows: `0`
- Ready for Mac validation: `true`

Measured generated sample evidence already present on disk:

- Rollup status:
  `build/parser_qa_pipeline/electrical_core_generated_run_status_samples.json`
  - Checked total: `12`
  - Failures: `0`
  - Parser calls: `12`
  - Measured pass rate: `1.0000`
  - Under minimum checked cells: `0`
  - Under minimum pass-rate cells: `0`
- en-US sample status:
  `build/parser_qa_generated_run_samples/electrical/residential/core/en-US/reports/latest_generated_fixture_run.json`
  - Checked: `6`
  - Failures: `0`
  - Parser calls: `6`
  - Sample pass rate: `1.0000`
- es-US sample status:
  `build/parser_qa_generated_run_samples/electrical/residential/core/es-US/reports/latest_generated_fixture_run.json`
  - Checked: `6`
  - Failures: `0`
  - Parser calls: `6`
  - Sample pass rate: `1.0000`

Current limitation:

- Electrical has measured sample evidence, but not yet a broad enough measured
  generated-status artifact on this branch to support a serious `0.90-0.95`
  release claim.

### HVAC Core

- Readiness audit:
  `build/parser_qa_curation/hvac_core/latest_hvac_core_readiness_audit.json`
- Core rows: `2695`
- Release-ready rows: `2695`
- Needs-work rows: `0`
- Critical rows: `0`
- Ready for Mac validation: `true`

Measured generated sample evidence already present on disk:

- Rollup status:
  `build/parser_qa_pipeline/hvac_core_generated_run_status_samples.json`
  - Checked total: `12`
  - Failures: `0`
  - Parser calls: `22`
  - Measured pass rate: `1.0000`
  - Under minimum checked cells: `0`
  - Under minimum pass-rate cells: `0`
- en-US sample status:
  `build/parser_qa_generated_run_samples/hvac/residential/core/en-US/reports/latest_generated_fixture_run.json`
  - Checked: `6`
  - Failures: `0`
  - Parser calls: `16`
  - Sample pass rate: `1.0000`
- es-US sample status:
  `build/parser_qa_generated_run_samples/hvac/residential/core/es-US/reports/latest_generated_fixture_run.json`
  - Checked: `6`
  - Failures: `0`
  - Parser calls: `6`
  - Sample pass rate: `1.0000`

Current limitation:

- HVAC has measured sample evidence, but not yet a broad enough measured
  generated-status artifact on this branch to support a serious `0.90-0.95`
  release claim.

## Windows Environment Constraint

Direct bounded `dart run` refresh attempts for parser/audit helper tools are
currently vulnerable to an environment-level FFI/build-hook compiler crash on
this Windows setup. Analyzer remains clean, but live regeneration of some
artifacts is currently more trustworthy on Mac than on this box.

Treat that as an environment constraint unless a narrower parser regression
proves otherwise.

## What This Proves Right Now

- Branch-level PEH checkpoint artifact:
  `build/parser_qa_pipeline/peh_core_windows_status_rollup.json`
  - missing trades: `0`
  - unsafe trades: `0`
  - failed trades: `0`
  - under-target trades: `2`
  - sample-sized trades: `2`
  - ready for Mac measurement wave: `true`
  - ready to claim `90-95%`: `false`
- All three PEH Core trades currently have clean Windows-side readiness audits.
- Plumbing has stronger measured Windows evidence than the other two trades.
- Electrical and HVAC already have clean measured sample rollups on disk.
- Electrical and HVAC still need broader measured generated-fixture validation
  before any professional `90-95%` accuracy claim is attached to them.

## Next Professional Steps

1. Use Mac to rerun the focused Plumbing runtime proof that still stalls on
   Windows.
2. Use Mac to expand Electrical Core measured generated validation beyond the
   current `6 + 6` sample (`12` checked total).
3. Use Mac to expand HVAC Core measured generated validation beyond the current
   `6 + 6` sample (`12` checked total).
4. After broader measured evidence exists for Electrical and HVAC, write branch
   level generated-status rollups for all PEH Core trades.

## Next Measurement Targets

These are the immediate minimum targets for the next round of Mac-side measured
validation so the branch moves toward a real `0.90-0.95` claim instead of
stopping at smoke-sized samples.

- Plumbing Core
  - Reconfirm the focused Menards sanitary-tee runtime proof on Mac.
  - Keep the existing `100`-case measured benchmark green.
- Electrical Core
  - Raise measured generated coverage from `12` total checked cases to at least
    `50` checked cases across `en-US` and `es-US`.
  - Enforce the reusable rollup gate with `--min-pass-rate 0.90`.
  - Maintain `0` failures and local-only safety flags.
- HVAC Core
  - Raise measured generated coverage from `12` total checked cases to at least
    `50` checked cases across `en-US` and `es-US`.
  - Enforce the reusable rollup gate with `--min-pass-rate 0.90`.
  - Maintain `0` failures and local-only safety flags.
- PEH rollup threshold
  - Do not describe Electrical or HVAC as `90-95%` ready until their measured
    generated evidence is materially larger than the current smoke-sized sample
    set and still clears the requested floor.
