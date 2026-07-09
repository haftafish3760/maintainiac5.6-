# Electrical Core Mac Validation Handoff

Generated: 2026-07-09 13:01 EDT

## Scope

Validate Maintainiac Electrical Core inventory/parser readiness on Mac. This is
inventory/parser QA only. Do not touch OCR, camera, expenses, UI, PDF, or
unrelated modules while following this handoff.

## Source

- Repository: `https://github.com/haftafish3760/maintainiac5.6-.git`
- Branch: `codex/inventory-parser-backup-20260702-2056`
- Commit: `72412be`
- Commit label:
  `QA testing 2026-07-09 12:59 EDT: cache plumbing receipt text and pin PEH roadmap snapshot`

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

## Current Windows Limitation

The Electrical readiness audit artifact is present and clean, but the measured
generated pass-rate artifact is not yet rolled up on this branch the way
Plumbing is.

Also, direct `dart run` refresh attempts on this Windows box currently hit the
same environment-level FFI/build-hook compiler crash seen in other bounded
parser tools. Treat that as a Windows environment issue unless a narrower
parser failure proves otherwise.

## Mac Validation Commands

Run from the repo root on the Mac after checking out commit `72412be`.

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

After the audit test is green on Mac, the next Mac-side task is to generate or
validate the measured Electrical Core generated-fixture status layer before any
`90-95%` accuracy claim is attached to Electrical.

Do not treat the readiness audit alone as the final accuracy proof.

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
