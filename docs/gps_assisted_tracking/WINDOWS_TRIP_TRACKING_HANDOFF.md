# GPS-Assisted Trip Tracking: Windows Continuation Handoff

## What this handoff is for

This is the current implementation and QA state for Maintainiac’s GPS-assisted mileage and trip-tracking system. Continue work in this lane only:

- Local-first trip capture and recovery.
- GPS-quality and mileage-accounting hardening.
- Live odometer projection in the UI.
- Privacy-safe, opt-in Firebase backup of reviewed mileage summaries.
- Consent boundaries for possible organization/fleet use.
- Android-focused testing while working from Windows.

Do **not** add maps, routes, address lookup, trip optimization, employer live tracking, Google Maps, or any other mapping feature. Those are intentionally deferred.

Do **not** describe this as complete, production-ready, legally certified, or world-class merely because tests pass. The user wants a top-tier commercial-grade system, and physical-device route verification remains a later explicit step.

## Core product rules

1. The device is the source of truth for an active trip.
2. GPS is assisted mileage capture, not a surveillance system.
3. A trip must be reviewed before it becomes a permanent odometer record.
4. Firebase is a backup mirror, never required to start, continue, finish, or review a trip.
5. Firebase never receives coordinates, routes, raw samples, addresses, stop locations, activity evidence, or live location.
6. Organization sharing is not implied by a company/account context. It requires its own explicit user opt-in.
7. Foreground-only tracking stops when the app backgrounds. Background tracking requires an explicit setting and the platform’s extra permission.
8. Do not weaken filtering just to make simulated miles larger. Rejected GPS data is preferable to fabricated mileage.

## Important source locations

### Trip engine and controller

- `lib/shared/trip_tracking/trip_tracking_engine.dart`
  - The deterministic mileage brain. It decides whether a location sample is credible and whether it adds distance.
  - Handles accuracy, mock locations, time ordering, speed plausibility, drift, gaps, walking transitions, and state changes.

- `lib/shared/trip_tracking/trip_tracking_controller.dart`
  - Owns one active trip, serializes GPS/native events, persists recovery state, controls native collection, projects the live odometer, and finishes into a review record.
  - Native lifecycle operations and ingestion operations use queues to avoid race conditions.
  - `finishForReview` drains pending native events before its durable review handoff.
  - `restore` rejects malformed local sessions and clears them rather than repeatedly reviving bad state.
  - Storage failures are non-destructive: an initial checkpoint failure releases the new live projection, while review-save or discard failures preserve the existing recoverable trip and live projection for retry. Native collection does not start until its lifecycle checkpoint saves.

- `lib/shared/trip_tracking/trip_tracking_models.dart`
  - Location, motion, diagnostics, snapshots, and decision models.
  - Persisted/native location payloads are validated before they reach recovery/engine code.

- `lib/shared/trip_tracking/trip_tracking_policy.dart`
  - Sampling recommendations and GPS hardening thresholds.

### Local storage and odometer

- `lib/shared/trip_tracking/trip_tracking_session_store.dart`
  - Durable active-session, pending-sample, and reviewed-trip records.
  - Active sessions support crash recovery. Reviews are durable before active recovery state is cleared.

- `lib/shared/state/global_odometer.dart`
  - Confirmed odometer is audit truth.
  - Active trips use a separate live projection so the UI changes immediately without prematurely writing a permanent reading.
  - Switching odometer vehicles is blocked while a live GPS projection exists.

- `lib/shared/odometer/odometer_entry_sheet.dart`
  - Finishing a GPS trip opens a physical-odometer confirmation flow. It compares the entered reading with filtered GPS mileage without pre-filling or overwriting the confirmed odometer; a material difference is a visible review warning.
  - If the user cancels, the dashboard retains a `REVIEW LATEST GPS TRIP` path to reopen the local review rather than losing the comparison workflow.

- `lib/shared/odometer/global_odometer_header.dart`
  - Compatibility export for older callers. The one canonical implementation is `lib/shared/widgets/global_odometer_header.dart`, which uses the global controller so the projected odometer updates across the app.

### Firebase backup and privacy

- `lib/shared/trip_tracking/trip_tracking_firebase_bridge.dart`
  - Local review records are queued to Firebase only when backup consent is enabled.
  - Auth/account/organization binding prevents a pending record from being redirected after account or organization changes.
  - Private backup and organization sharing are separate concepts.
  - `withdrawBackupConsent()` cancels unsent backup records but preserves local review records.
  - `withdrawOrganizationSharingConsent()` cancels unsent organization records, including legacy unscoped organization queue records.

- `lib/shared/firebase/maintainiac_firestore_documents.dart`
  - Builds the only allowed cloud shape: `trip_tracking_review_v1` mileage summary documents.
  - Its document shape is intentionally coordinate-free.

- `lib/shared/firebase/maintainiac_firestore_upload_store.dart`
  - Persistent generic Firestore upload queue. Failed writes remain retryable across restart.
  - The queue validates the shared trip-summary contract before persistence, so a malformed mileage draft with coordinates, unknown fields, or mismatched organization consent is rejected locally as well as by Firestore rules.

- `firestore.rules`
  - Rules allowlist the mileage summary fields. Do not replace this allowlist with a loose denylist.
  - Organization records must be bound to their organization path and carry `organizationSharingConsent: true`.
  - Elevated organization reads require that consent field; the record creator may still read their own record. This safely hides old or consent-withheld records from fleet views.
  - Reviewed mileage summaries are immutable cloud audit records. The original creator can only replay an exact document after an interrupted upload; organization roles cannot modify employee mileage.
  - Rules reject location-like data and unknown fields.

### Settings and app wiring

- `lib/screens/settings/trip_tracking_settings_screen.dart`
  - User-facing GPS, background tracking, private Firebase backup, and separate organization-sharing settings.

- `lib/shared/trip_tracking/trip_tracking_settings_store.dart`
  - Persistent settings. `organizationMileageSharingEnabled` is default false.

- `lib/main.dart`
  - Creates the controller/mirror, restores local trip state, and reacts to consent changes.
  - Do not silently turn organization sharing on because cloud backup is on.

- `lib/app/maintaniac_app.dart`
  - Observes app lifecycle. If the app is paused/detached and background tracking is not allowed, it stops native GPS collection.

## Native implementation

### Android

- `android/app/src/main/kotlin/com/maintainiac/TripTrackingNativeBridge.kt`
  - Requests authorization in stages and starts/stops the foreground service.
  - Foreground-service launch denial, including Android background-launch policy denial, must return `trip_tracking_foreground_service_denied` to Dart rather than crash.

- `android/app/src/main/kotlin/com/maintainiac/TripTrackingForegroundService.kt`
  - Owns Android location updates and the visible foreground notification.
  - Stops itself and emits errors on permission revocation, disabled/unavailable GPS, service denial, and location-registration failure.

- `android/app/src/main/AndroidManifest.xml`
  - Declares fine/coarse/background location, foreground-service location, activity recognition, optional notification visibility, and the location foreground service.

- Android 13+ notification visibility
  - The authorization flow requests `POST_NOTIFICATIONS` after location approval so the ongoing tracking indicator can appear in the notification drawer.
  - Notification denial does not block GPS tracking; the foreground service and app still handle that state safely.

### iOS

- `ios/Runner/TripTrackingNativeBridge.swift`
  - Requests foreground location before escalating to background location.
  - Emits a recoverable error and stops collection if authorization is revoked while tracking.
  - Applies sampling tiers rather than hardcoding one highest-accuracy mode.

- `ios/Runner/Info.plist`
  - Contains the location/motion purpose text and background location mode.

## Privacy and consent behavior already implemented

### Private Firebase backup

- Default: off.
- When off: reviewed trips stay local-only.
- When enabled: only reviewed mileage summaries may be queued.
- When later turned off: unsent cloud queue entries are discarded; the local review remains available.
- A Firebase outage does not lose the review or block finishing a trip.

### Organization sharing

- Default: off, even when the active operational context has an organization/company.
- With private backup on but organization sharing off: new backup uses `users/{uid}/mileageRecords/...`, not `orgs/{orgId}/mileageRecords/...`.
- Organization sharing must be explicitly enabled before a newly finished review can use the organization path.
- Turning organization sharing off clears unsent organization queue entries, including older queue entries created before scope binding existed.
- Turning it off must not remove an explicitly personal pending backup; that regression is covered in `test/trip_tracking_firebase_bridge_test.dart`.
- Existing uploaded records are not silently deleted; do not promise remote deletion without an explicit, designed data-retention and authorization workflow.

### Data forbidden from cloud mileage records

- latitude/longitude/coordinates
- accuracy, speed, bearing, altitude, timestamps used as raw evidence
- routes, polylines, route summaries, geohashes
- addresses/place IDs/stop addresses
- raw samples and live location
- walking/activity evidence

If someone proposes adding a field to a mileage cloud document, first ask whether it can reveal a route, place, or movement pattern. Add an explicit test and update the Firestore allowlist only if the new field is demonstrably safe and needed.

## High-value QA evidence already run

Focused tests have repeatedly passed throughout the work. The current useful gates are:

```powershell
# GPS controller, recovery, native lifecycle, and live odometer behavior
flutter test test/trip_tracking_controller_test.dart test/trip_tracking_session_store_test.dart

# Engine edge cases and deterministic fuzzing
flutter test test/trip_tracking_engine_test.dart test/trip_tracking_fuzz_test.dart

# Firebase consent, queue/retry, and private-vs-organization scope
flutter test test/trip_tracking_firebase_bridge_test.dart test/maintainiac_firestore_upload_queue_test.dart

# Settings and global odometer UI behavior
flutter test test/trip_tracking_settings_store_test.dart test/trip_tracking_settings_screen_test.dart test/global_odometer_header_test.dart

# Native source/lifecycle contract checks
flutter test test/trip_tracking_native_permission_contract_test.dart

# Android compilation gate
flutter build apk --debug
```

Firebase rules were tested with the local emulator on the Mac:

```sh
cd firebase_emulator_tests
env JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' PATH='/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin:/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin' npm run test:emulator
```

That rules suite passed 25 tests after the mileage allowlist/org-path changes. Expected `PERMISSION_DENIED` logs inside that suite are negative-rule assertions, not failures.

## Known environment constraints and what not to do

- Do not run iOS/Xcode builds unless the user explicitly asks. The generated `build/ios` output was removed on request because it consumed about 945 MB.
- Do not delete source, Pods, iOS project files, or unrelated dirty work.
- Do not use `git reset --hard`, `git checkout --`, or broad cleanup commands.
- The unrelated `test/maintainiac_firestore_documents_test.dart` was observed hanging in the Work Supplies catalog portion. It is not a trip-tracking signal. Do not use that hanging test as proof for or against trip work; avoid changing that unrelated lane under this handoff.
- Do not add maps or address resolution.
- Do not assume an employer can see a person’s location. No fleet live-location system is in scope.

## Suggested next work on Windows

1. Run the focused Android/controller/engine/Firebase gates above after pulling this commit.
2. If an Android emulator is available, run staged manual checks:
   - Start a foreground-only trip; background the app; verify native collection stops and trip remains recoverable.
   - Enable background mode; grant/deny location as appropriate; verify denial produces a clear recoverable state rather than a crash/loop.
   - Disable GPS or revoke location during an active trip; verify error, native stop, recoverable local trip, and no fake extra miles.
   - Simulate a normal driving route with jitter, a GPS outage, and a return; verify no implausible jump becomes mileage.
3. Expand deterministic simulations only when they test a distinct failure mode. Keep them small and reproducible; do not produce huge pass logs or broad file rereads.
4. Keep local review durability ahead of any cloud action. A failure in Firebase must never discard a local review or alter the confirmed odometer.
5. Preserve explicit consent: never fallback from private backup to organization sharing, and never fallback from signed-out auth to a stale account ID.

## Physical-device testing status

The code and simulations have substantial coverage, but this is **not** physical-route validated yet. A real-device protocol should be run only when the user explicitly says they are ready. It should cover a known measured route, foreground/background transitions, permission changes, app force-close/relaunch recovery, GPS outage, and review/odometer confirmation. Do not initiate a live route merely because a phone is connected.
