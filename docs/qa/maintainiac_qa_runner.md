# Maintainiac QA Runner

`tool/maintainiac_qa_runner.dart` is the fast, Dart-only first gate for the
Maintainiac QA backbone. It validates shared QA contracts without launching
Flutter, device code, live Firebase, OCR, camera, or full parser sweeps.

## Purpose

Use this runner to catch broken QA metadata before stacking more work:

- parser consumer contracts
- inventory and expense parser QA breadth
- release gate metadata
- security, privacy, scope, and source-of-truth contracts
- sync and financial contract registries
- performance budgets
- surgical selector coverage and changed-file routing

This runner is not the final release gate. It is the fast tripwire before
deeper focused Flutter tests, parser corpus tests, device tests, and release
quality gates.

## Common Commands

Run every fast contract group:

```powershell
dart run tool\maintainiac_qa_runner.dart --group all --strict
```

Run one focused group:

```powershell
dart run tool\maintainiac_qa_runner.dart --group inventory --strict
```

Find exact tests for a changed file:

```powershell
dart run tool\maintainiac_qa_runner.dart --changed tool/maintainiac_qa_runner.dart --commands-only --strict
```

Emit bounded JSON for automation:

```powershell
dart run tool\maintainiac_qa_runner.dart --group security --json --strict
```

## Validation Ladder

Use these layers in order:

1. Fast Dart runner for contract and metadata sanity.
2. Surgical Flutter tests for the exact changed behavior.
3. Parser/corpus tests for generated fixture and catalog behavior.
4. Device or integration tests only at feature milestones.
5. Full release gate before handoff or release candidate.

If any layer fails, fix the failure before adding more code.

## Boundaries

- Do not use this runner to touch OCR or camera implementation.
- Do not use live Firebase from this runner.
- Do not auto-save parser/OCR suggestions.
- Hive/local remains source of truth; Firestore is mirror/backup only.
- User-confirmed data outranks parser, OCR, sync, and automation suggestions.
