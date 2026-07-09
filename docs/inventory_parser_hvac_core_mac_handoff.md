# HVAC Core Mac Validation Handoff

Generated: 2026-07-09 13:01 EDT

## Scope

Validate Maintainiac HVAC Core inventory/parser readiness on Mac. This is
inventory/parser QA only. Do not touch OCR, camera, expenses, UI, PDF, or
unrelated modules while following this handoff.

## Source

- Repository: `https://github.com/haftafish3760/maintainiac5.6-.git`
- Branch: `codex/inventory-parser-backup-20260702-2056`
- Commit: `72412be`
- Commit label:
  `QA testing 2026-07-09 12:59 EDT: cache plumbing receipt text and pin PEH roadmap snapshot`

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

- en-US:
  `build/parser_qa_generated_run_samples/hvac/residential/core/en-US/reports/latest_generated_fixture_run.json`
  - Checked: `6`
  - Failures: `0`
  - Parser calls: `16`
  - Sample pass rate: `1.0000`
- es-US:
  `build/parser_qa_pipeline/pass3021-peh-core-baby-5/hvac/residential/core/es-US/reports/latest_generated_fixture_run.json`
  - Checked: `5`
  - Failures: `0`
  - Parser calls: `5`
  - Sample pass rate: `1.0000`

## Current Windows Limitation

The HVAC readiness audit artifact is present and clean, but the measured
generated pass-rate evidence is still only sample-sized on this branch and is
not yet broad enough to support a serious `0.90-0.95` release claim.

Also, direct `dart run` refresh attempts on this Windows box currently hit the
same environment-level FFI/build-hook compiler crash seen in other bounded
parser tools. Treat that as a Windows environment issue unless a narrower
parser failure proves otherwise.

## Mac Validation Commands

Run from the repo root on the Mac after checking out commit `72412be`.

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
