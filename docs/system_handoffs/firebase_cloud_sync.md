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
- Build-safe options owner:
  `lib/shared/firebase/maintainiac_firebase_options.dart`
- Local configuration template: `config/firebase_dart_defines.example.json`

## Boundaries And Remaining

- Preserve central Firebase ownership during all feature merges. Never import a
  whole feature branch merely to recover Firebase files.
- `VERIFIED SUBSET`: local rules/queue/emulator evidence exists; it is not proof
  of deployed production Firebase, complete proof lifecycle, or device migration.
- `NEEDS RECONCILIATION`: restore, proof upload, Storage emulator coverage,
  schemas, migrations, conflicts, quotas, and protected-path source differences.
- `VERIFIED SUBSET`: the Receipt OCR repository's older Expense backup queue,
  direct sink, proof transport, and deletion queue were compared to the newer
  centralized queue, secure proof grant/finalization/reference, restore, and
  tombstone owners; the focused cross-system persistence batch passed 124 tests.
- `VERIFIED SUBSET`: a clean Git checkout no longer requires ignored Firebase
  credentials to analyze or compile. Mobile Firebase accepts either the
  required `MAINTAINIAC_FIREBASE_*` values supplied with
  `--dart-define-from-file` or the existing machine-local native configuration.
  Android's Google Services plugin is applied only when a local
  `google-services.json` exists. Xcode conditionally copies the ignored local
  iOS plist when present rather than treating it as a mandatory project
  resource. When neither configuration source exists, the existing local-first
  app starts with hosted Firebase disabled. This is transfer/build safety, not
  deployed Firebase readiness.

## Rolling Log

- 2026-07-22: Created with local evidence separated from production readiness.
- 2026-07-22: Recorded semantic supersession of the Receipt OCR repository's
  parallel cloud owners; no production deployment claim was made.
- 2026-07-22: Removed the clean-checkout dependency on ignored Firebase files,
  added compile-time build options and an example configuration, retained the
  existing native-config path, and kept secrets as machine-local inputs only.
