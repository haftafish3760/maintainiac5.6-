# Firebase Production Deploy Checklist

This checklist is mandatory before any live Firebase deploy or live Firebase
test.

## Hard Stops

- Do not deploy without explicit owner approval.
- Do not deploy from a dirty, unknown working tree.
- Do not deploy while `.firebaserc` points only at the demo emulator project.
- Do not enable Firestore test mode.
- Do not seed production.
- Do not run load tests against production.
- Do not run AI, OCR, export, Storage, or sync stress tests against production.
- Do not add service account JSON files to the repo.

## Required Before Live Deploy

- Confirm Firestore database location is `NAM7`.
- Confirm Google Cloud budget alerts are configured.
- Confirm App Check enforcement plan is ready.
- Confirm Firebase Auth providers are Google and Apple only.
- Confirm Email/Password, Email Link, Phone, and Anonymous auth are disabled.
- Run `bash tool/run_firebase_emulator_tests.sh`.
- Run focused Flutter security tests.
- Run `flutter analyze`.
- Run a debug build.
- Review `firestore.rules`.
- Review `storage.rules`.
- Review `firestore.indexes.json`.

## Forbidden Data Check

Confirm no model, seed, or migration introduces:

- VINs.
- License plates or tag numbers.
- Passenger names, phone numbers, or addresses.
- Patient names, phone numbers, addresses, dates of birth, medical record
  numbers, diagnosis, appointment reason, or health details.

## Live Smoke Test Limits

Live smoke tests require a written cap before starting:

- Maximum Firestore reads.
- Maximum Firestore writes.
- Maximum Storage bytes.
- Maximum Function invocations.
- Maximum test duration.
- Manual stop command.
- Rollback plan.

Budget alerts are warning lights, not a kill switch.
