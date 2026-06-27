# Firebase Emulator Security Tests

These tests are production-hostile by design. They must run only against the
local Firebase Emulator Suite.

## Safe Command

```sh
bash tool/run_firebase_emulator_tests.sh
```

The runner uses the local `openjdk@21` Homebrew keg when present because current
Firebase Tools requires JDK 21 or newer.

The runner uses:

```text
demo-maintainiac-rules-test
```

The test guard fails when:

- `.firebaserc` is not using the demo project.
- `FIRESTORE_EMULATOR_HOST` is not `127.0.0.1:8080`.
- `GCLOUD_PROJECT` points anywhere except the demo project.
- The Auth emulator host is set to a non-local target.

## Current Coverage

- User can read only their own `users/{uid}` document.
- Outsiders cannot read org data.
- Helpers cannot read owner financial summaries.
- Employee writes must use their own `createdByUid`.
- Invite reads are limited to owner/admin or the matching invite email.
- Upload grants and exports are server-created only.
- Account-abuse counters, IP-window counters, and review queues are server-only.
- Account creation contract blocks unsupported providers, missing App Check, bad
  install signals, and high-repeat account attempts.

## Hard Rules

- Do not deploy functions from this harness.
- Do not point this harness at production Firebase.
- Do not add production service account keys.
- Do not test AI, OCR, Storage uploads, exports, or live Cloud Functions here.
- Add new tests with mock users and mock documents only.
