# Firebase, Firestore, Storage, And Cloud Sync Living Handoff

## Current Status

`PRESENT / VERIFIED SUBSET / NEEDS RECONCILIATION`. Central auth, organization,
Firestore schema/documents, upload queue/store/policy, hosted usage limits,
abuse controls, feature bridges, rules, indexes, and emulator tests exist.

## Implemented Evidence

- Central owner: `lib/shared/firebase/`
- Rules/config: `firebase.json`, `firestore.rules`, `firestore.indexes.json`,
  and `storage.rules`
- Expense cloud code: files matching `cloud`, `firestore`, or `firebase` under
  `lib/screens/expenses/data/`
- Guidance: `docs/firebase_sync_schema_spec.md` and
  `docs/firebase_production_deploy_checklist.md`

## Boundaries And Remaining

- Preserve central Firebase ownership during all feature merges. Never import a
  whole feature branch merely to recover Firebase files.
- `VERIFIED SUBSET`: local rules/queue/emulator evidence exists; it is not proof
  of deployed production Firebase, complete proof lifecycle, or device migration.
- `NEEDS RECONCILIATION`: restore, proof upload, Storage emulator coverage,
  schemas, migrations, conflicts, quotas, and protected-path source differences.

## Rolling Log

- 2026-07-22: Created with local evidence separated from production readiness.
