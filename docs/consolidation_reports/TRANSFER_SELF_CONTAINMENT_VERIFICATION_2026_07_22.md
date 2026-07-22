# Maintainiac 5.7 transfer self-containment verification — 2026-07-22

## Verified Git source

- GitHub branch: `codex/maintainiac-5.7-consolidation-20260722`
- Verified commit: `739907fdf4ca2b099ce392d405e61498f204da6e`
- Verification used a fresh single-branch clone under `/tmp`, not the existing
  Documents checkout.
- The clone began clean and contained none of the ignored Mac-local Firebase
  files: `lib/firebase_options.dart`, Android `google-services.json`, or the iOS
  `GoogleService-Info.plist`.

## Tracked transfer inputs

- All 14 assets declared through `assets/generated_trade_icons/` exist and are
  tracked.
- `pubspec.yaml` and `pubspec.lock` are tracked.
- Android has 54 tracked project/native files; iOS has 71.
- `.firebaserc`, `firebase.json`, `firestore.rules`,
  `firestore.indexes.json`, `storage.rules`, and six Cloud Functions files are
  tracked.
- A secret-free Firebase build-definition template is tracked at
  `config/firebase_dart_defines.example.json`; the populated local file remains
  ignored.

## Clean-clone gates

- `flutter pub get`: passed.
- Full `flutter analyze`: no issues.
- Bounded transfer contract batch: **24 tests passed**. It covered Firebase
  configuration/secrets, device text scaling, the accessibility inventory,
  duplicate scanning, Document Engine ownership, and export privacy.
- `flutter build apk --debug`: passed without Firebase credentials.
- `flutter build ios --debug --no-codesign`: passed without Firebase
  credentials and produced `Runner.app`.
- No app was installed or launched on a physical device.

## Durable storage and Firebase preservation

- No Hive/local record, upload queue, durable mirror, restore owner, Firebase
  rule, index, Storage rule, or Cloud Function was deleted or rewritten by the
  transfer configuration work.
- With no hosted configuration, Firebase initialization fails closed and the
  existing local-first app continues without enabling its cloud mirrors.
- Existing native configuration remains supported: the Mac-local Android build
  passed with its ignored JSON present, and the iOS build's conditionally copied
  plist matched the ignored source byte-for-byte.
- Compile-time `MAINTAINIAC_FIREBASE_*` definitions provide a second safe
  configuration path without committing credentials.
- This proves build/configuration preservation, not deployed Firebase readiness
  or live cloud-data behavior.

## Accessibility inventory

- The script-driven scan covered 1,411 production Dart files.
- It recorded 612 candidates in 135 files and zero global text-scale overrides.
- Work Supplies is included with 76 candidates.
- Candidates are deferred screen-level review work; no unfinished screen was
  mechanically rewritten.

## Duplicate result

- Final production files scanned: 1,610.
- Exact duplicate file groups: zero.
- Repeated block groups: 220, unchanged from the 5.6 baseline count.
- The final transfer additions introduced no additional repeated group.

## Remaining external proof

Physical-device smoke testing remains intentionally unperformed. It requires
the product owner's explicit approval and is separate from transfer integrity.
