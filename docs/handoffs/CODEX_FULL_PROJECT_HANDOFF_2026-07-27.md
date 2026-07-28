# Maintainiac 5.7 Active: Full Codex Handoff

Date: 2026-07-27 EDT

Workspace: `/Users/rbbie/Documents/Maintainiac_5.7_Active`

This document is for the next Codex model working in this exact checkout. It is intended to prevent repeated discovery, accidental publishing of unrelated work, unsafe device actions, and unsupported claims about GPS readiness.

## 1. Owner Requirements and Non-Negotiable Rules

1. Work only in `Maintainiac_5.7_Active`. Do not touch any 5.6 checkout.
2. Preserve unrelated dirty work. This checkout intentionally contains broad unfinished work in receipt capture, device capabilities, Jobs/work supplies, contractor dashboard, and documentation.
3. Do not delete, reset, clean, revert, move, or overwrite unrelated files.
4. Do not create a branch, worktree, or repository unless the owner explicitly asks for it.
5. Do not commit, push, install, launch, or modify a physical device unless the owner explicitly approves the concrete action. Prior authorization approved building and installing the current debug APK on the S24 only. It did not authorize creating a real workday or real trip record.
6. Do not change Firebase, Firestore, remote backup, or durable-storage behavior for trip tracking without separate explicit approval. Trip tracking is local-first; Firebase is not part of the GPS solution.
7. Confirmed vehicle odometer is canonical, user-owned, and app-wide. GPS is advisory only. GPS may update a live projected display while driving but may never silently overwrite confirmed odometer.
8. GPS, maps, OCR, Bluetooth, cloud services, or AI must not become a source of official mileage truth.
9. A green Dart test or deterministic replay is not proof of Android field accuracy. Never claim 90-95% field reliability until controlled real-device evidence exists.
10. Do not perform real Start Day, real trip, real odometer confirmation, or permission/settings changes on the owner's phone without direct approval.
11. Treat raw location as sensitive. New diagnostics and field evidence must not export coordinates, route geometry, addresses, precise timestamps, or secrets.
12. Production files should stay under 500 lines and retain responsibility-based names. Do not collapse dashboard work into the Jobs system.

## 2. What Maintainiac Does

Maintainiac is a Flutter mobile app for gig drivers and contractors. The current codebase includes, among other work in progress:

- Gig Driver and Contractor dashboard/workday surfaces.
- Start Day / active-workday workflow tied to an active vehicle.
- Shared vehicle and canonical global odometer state.
- GPS-assisted trip tracking that proposes a live mileage projection and a review record, while retaining confirmed odometer authority.
- Expense and receipt-capture/OCR workflows.
- Maintenance receipt parsing.
- Jobs, work supplies/materials, estimates, and contractor business views.
- Shared device-capability reporting.

The app is not ready to be described as commercially field-proven for GPS. It has strong synthetic and source-level coverage, but real S24 evidence is still absent.

## 3. GPS Product Contract

### Odometer authority

- A manual confirmed odometer entry is the official number everywhere in the app.
- Every active-vehicle screen consumes the same underlying odometer record, although each screen owns its own vehicle-row UI and screen-specific menu.
- GPS only supplies a live estimated/projection display. It cannot save, confirm, replace, or roll back confirmed mileage.
- GPS distance is presented for review at trip completion. The driver confirms the actual odometer separately.
- Signal gaps, walking, poor accuracy, or recovery events cannot manufacture missing mileage or an official stop.

### GPS lifecycle contract

- Start Day can start native GPS assistance only when GPS assistance is opted in and Android prerequisites allow it.
- Dashboard must not call the state `LIVE GPS` merely because Start Day is active or a native start command was sent.
- Android emits `starting` before Fused Location registration is confirmed.
- Android emits `tracking` only after `FusedLocationProviderClient.requestLocationUpdates(...)` succeeds.
- Dashboard status is:
  - `GPS OFF` when active workday has GPS assistance disabled.
  - `GPS STARTING` while provider registration is pending.
  - `GPS ACQUIRING` after provider registration but before a usable initial fix.
  - `LIVE GPS` only with provider-registration evidence and usable live state.
  - `GPS DEGRADED` or `GPS RECOVERY` for safe non-live conditions.
- Start/recovery state must not silently claim that the physical provider request is active.

### Android constraints

- Android cannot silently grant itself location permissions or turn system Location Services on.
- Background collection requires Android background-location permission.
- Activity Recognition is optional for base GPS mileage but required to test walking-assisted stop evidence.
- Android foreground-service location permission and manifest service type are present in the current app.

## 4. Dashboard Work Completed in This GPS Pass

This handoff covers GPS-linked dashboard work only. Do not assume unrelated contractor dashboard changes are part of this GPS commit scope.

1. The dashboard reads `nativeProviderRegistered`, not simply a local `nativeTracking` flag, before labeling GPS as live.
2. Dashboard state policy renders `GPS STARTING`, `GPS ACQUIRING`, `LIVE GPS`, `GPS DEGRADED`, `GPS RECOVERY`, and `GPS OFF` correctly for the GPS-linked active vehicle display.
3. The Start Day / active-workday integration binds one native GPS trip to the active work context and does not let GPS change the confirmed odometer.
4. A provider restart or event-stream reconnect now returns to `GPS STARTING` until Android confirms registration again.

Files directly changed for this behavior:

- `lib/screens/dashboard/dashboard.dart`
- `lib/screens/dashboard/data/dashboard_trip_tracking_summary.dart`
- `lib/shared/trip_tracking/trip_tracking_dashboard_live_status_policy.dart`
- `test/active_workday_gps_start_integration_test.dart`
- `test/dashboard_round_start_gps_integration_test.dart`
- `test/trip_tracking_dashboard_live_status_policy_test.dart`

Do not include unrelated modified contractor dashboard files in a GPS-only commit without owner approval.

## 5. GPS Native and Controller Hardening Completed

### Android foreground service

Files:

- `android/app/src/main/kotlin/com/maintainiac/TripTrackingForegroundService.kt`
- `android/app/src/main/kotlin/com/maintainiac/TripTrackingNativeBridge.kt`

Implemented behavior:

1. Added distinct static state for `isStarting`, `isRunning`, and `isCollectorActive`.
2. Emits native status `starting` before registering the Fused Location callback.
3. Emits native status `tracking` only inside the successful provider-registration callback.
4. Registration failure clears pending state and stops the service instead of pretending tracking is live.
5. A sampling/cadence update arriving while registration is pending is treated as a replacement request rather than an invalid request that stops the service. This repaired a race that could produce an active workday without a provider request.
6. Replacing a provider request clears `isRunning` before replacing the callback, so late callbacks from an old request cannot cross a collection boundary.
7. Event-channel reconnect truthfulness was repaired: when `isStarting` is true but registration is not complete, `onListen` emits `starting`, not `tracking`.
8. The native bridge still uses collector-active state for duplicate-start prevention, but it no longer uses that broader state to falsely label the event stream as live.
9. Service retains `START_REDELIVER_INTENT` for Android service restart, preserves sampling/sensor consent in the redelivered intent, and refuses a null/redelivery request that lacks driver-approved parameters.
10. Existing safeguards remain: location service/permission checks, background-permission revocation handling, battery cutoff, activity recognition opt-out, epoch protection for old activity callbacks, and rejection of malformed/late native location metadata.

### Dart controller

Files:

- `lib/shared/trip_tracking/trip_tracking_controller.dart`
- `lib/shared/trip_tracking/trip_tracking_controller_native_collection.dart`
- `lib/shared/trip_tracking/trip_tracking_controller_native_events.dart`
- `lib/shared/trip_tracking/trip_tracking_controller_native_lifecycle.dart`
- `lib/shared/trip_tracking/trip_tracking_controller_session_lifecycle.dart`
- `lib/shared/trip_tracking/trip_tracking_platform_events.dart`

Implemented behavior:

1. Added `nativeProviderRegistered` state separate from generic native collector ownership.
2. New start initially sets platform state to `awaiting_provider_registration`, then `awaiting_initial_fix` only after Android confirms `tracking`.
3. Controller accepts native `starting` events.
4. A `starting` event clears `nativeProviderRegistered`; a later `tracking` event restores it. This is required for a reconfiguration or event-stream reconnect.
5. Early native event races are retained in pending-start state rather than lost before controller start finalizes.
6. Recovery and stop/lifecycle cleanup clear provider-registration evidence.
7. No state-only event can create accepted meters, live GPS mileage, or a confirmed odometer mutation.

## 6. GPS Test and QA Work Completed

### New or expanded tests

- `test/trip_tracking_commercial_workday_replay_test.dart`
  - Driving, stop, walking, resume, urban-canyon quality loss, signal loss, recovery, and canonical odometer safety.
- `test/trip_tracking_field_failure_replay_test.dart`
  - Garage exit/no hidden distance bridging, downtown queue behavior, and separation of delivery walking evidence.
- `test/trip_tracking_native_provider_registration_contract_test.dart`
  - Source contract for native `starting`, success-gated `tracking`, safe sampling replacement during registration, and reconnect truthfulness.
- `test/trip_tracking_provider_registration_state_test.dart`
  - Controller-level `starting -> tracking -> starting -> tracking` sequence. It proves that status ordering alone leaves accepted meters at zero and confirmed/live odometer unchanged until actual samples are accepted.
- `test/trip_tracking_long_session_recovery_test.dart`
  - Twelve-hour recovery without duplicate distance.
- `test/trip_tracking_controller_recovery_integrity_test.dart`
  - Forged audit quarantine, valid multi-day recovery, and orphan native collector handling.
- `test/trip_tracking_paused_ingestion_test.dart`
  - Paused sessions reject late callbacks without mileage mutation.
- `test/trip_tracking_atomic_session_start_test.dart`
  - Prevents duplicate sessions across memory/Hive/controller races.
- `test/trip_tracking_heartbeat_watchdog_policy_test.dart`
  - Stale/interrupted heartbeat decisions stay mileage-safe.
- `test/trip_tracking_fuzz_test.dart`
  - Expanded hostile seeded samples from 128 to 512 and mixed-motion samples from 64 to 256.

### Field evidence integrity

Files:

- `test/support/trip_tracking_qa/trip_tracking_field_evidence.dart`
- `test/support/trip_tracking_qa/trip_tracking_benchmark_reporter.dart`
- `test/trip_tracking_field_evidence_test.dart`
- `test/trip_tracking_benchmark_reporter_test.dart`
- `docs/gps_assisted_tracking/GPS_FIELD_EVIDENCE_TEMPLATE.json`

Field evidence is coordinate-minimized and now records:

- `providerRequestObserved`
- `backgroundCollectionObserved`
- `recoveryAfterBackgroundObserved`

It rejects incoherent evidence, including background collection without a provider request and recovery without both provider and background evidence. Aggregate reporting includes observation counts and rates. This does not certify production accuracy by itself.

### Main GPS QA command

`./tool/trip_tracking_commercial_workday_qa.sh`

This now runs the commercial replay, field failure replay, fuzz/simulation, active-workday GPS integration, dashboard behavior, live odometer behavior, native provider contract, provider-registration controller state sequence, device policy, field-evidence integrity, long-session recovery, recovery integrity, paused ingestion, atomic start, heartbeat watchdog, and 100 simulation iterations.

Most recent result before this handoff:

`COMMERCIAL_WORKDAY_QA_PASS`

Other verified commands from this pass:

```text
flutter build apk --debug
  -> Built build/app/outputs/flutter-apk/app-debug.apk

flutter test test/trip_tracking_provider_registration_state_test.dart \
  test/trip_tracking_native_provider_registration_contract_test.dart
  -> All tests passed

flutter test test/trip_tracking_field_evidence_test.dart \
  test/trip_tracking_benchmark_reporter_test.dart \
  test/trip_tracking_field_trial_summary_test.dart
  -> All tests passed
```

Earlier bounded replay evidence:

- 27 fixed production-engine scenarios x 1000 iterations = 27,000 executions.
- Synthetic P95 percentage error: `0.0001`.
- Synthetic stationary drift: `0`.
- Synthetic true-positive stops: `6`; false positives: `0`; false negatives: `0`.
- These are deterministic replay results only. They are not a real-device accuracy percentage and must continue to report `realDeviceAccuracyProven=false`.

## 7. S24 Device State and Field-Test Situation

The owner uses an S24 Ultra as the Maintainiac test device. The S25 is for the ChatGPT mobile app and must not receive a Maintainiac install unless explicitly requested.

Known S24 details from the last successful read-only ADB check:

- Model: Samsung Galaxy S24 Ultra, `SM-S928U`.
- Previously reachable wireless serial: `192.168.1.135:39219`.
- Location Services: enabled (`location_mode=3`).
- Fine/coarse location: granted.
- `FOREGROUND_SERVICE_LOCATION`: granted.
- `ACCESS_BACKGROUND_LOCATION`: not granted.
- `ACTIVITY_RECOGNITION`: not granted.
- No active Mainteniac trip service or current provider request at that time.
- Historical Android dumps showed Mainteniac had previously requested high-accuracy location at a two-second cadence, but historical dumps are not evidence of a current live request.

The debug APK was installed successfully on the S24 with:

```text
adb -s 192.168.1.135:39219 install -r \
  build/app/outputs/flutter-apk/app-debug.apk
```

No app launch, Start Day, real trip, user trip record, or odometer action was performed as part of that install.

The S24 was later first `offline` and then absent from `adb devices -l`. Reconnect it through USB or wireless debugging before attempting field work.

### Device scripts created

- `tool/trip_tracking_s24_readiness.sh <serial> [--expect-active]`
  - Read-only prerequisite check: app installed, Location Services, foreground location, background location, activity recognition, service state, and current provider request.
  - It deliberately excludes Samsung historical provider records before deciding a current request is active.
- `tool/trip_tracking_s24_runtime_probe.sh <serial> [--expect-active]`
  - Read-only active-session probe: current permission state, foreground service, current provider request, and notification presence.
  - Does not launch the app, alter settings, clear logs, read coordinates, or create storage records.
  - `--expect-active` fails if expected collection is not observed.

Both scripts passed `bash -n`. The runtime probe could not run once the S24 went offline; it did not mutate the device.

## 8. Required Field Validation Before Any Accuracy Claim

Do not claim commercial field readiness until each is completed and recorded with coordinate-minimized evidence.

1. Reconnect S24 ADB and verify it is a `device`, not `offline`.
2. Have the owner enable Mainteniac background location in Android settings.
3. Have the owner enable Activity Recognition if walking-assisted stop testing is included.
4. Run `trip_tracking_s24_readiness.sh` before starting an owner-approved controlled test.
5. The owner, not Codex, starts a dedicated test session. Do not create a normal workday or alter a real customer trip without specific approval.
6. Immediately run `trip_tracking_s24_runtime_probe.sh <serial> --expect-active` and retain only its coordinate-free output.
7. Drive an approved reference route with independently observed odometer delta. Include open sky, a stop, resumed driving, an app background/lock interval, and a controlled recovery observation.
8. Do not bridge any GPS signal gap in the measurement. Observe whether the app marks degraded/recovery safely.
9. At completion, use the normal review flow. Manual confirmed odometer stays authoritative; do not accept GPS merely to make a test pass.
10. Record coordinate-minimized field evidence: odometer miles, filtered GPS miles, expected/detected/matched walking stops, provider observed, background observed, and recovery observed.
11. Repeat across enough representative S24 runs before estimating a reliability percentage. One successful drive cannot establish 90-95% dependability.

## 9. Current Git State and Publishing Boundary

Current branch:

```text
codex/receipt-manual-screen-rebuild-20260726
```

At the last check, it was six commits ahead of its upstream:

```text
83523a59 2026-07-27 EDT - repair receipt draft deletion flow
176f1a61 2026-07-27 EDT - constrain receipt drafts sheet
7ec54c61 2026-07-27 EDT - place receipt style near form start
b66525dd 2026-07-27 EDT - add ask each time receipt style
6399bb88 2026-07-27 EDT - honor receipt style routing
2b66ecf5 2026-07-27 EDT - polish manual receipt flow hierarchy
```

The working tree is heavily dirty with both modified and untracked files. GPS/dashboard changes are not committed. The owner asked to push GPS and dashboard work, but a direct push from this branch would also publish the six unrelated receipt commits above.

Do not push until the owner chooses one of these explicit options:

1. Push all seven commits after creating a scoped GPS/dashboard commit on the current branch, knowingly publishing the six receipt commits too.
2. Authorize an isolated branch/worktree/cherry-pick procedure that publishes only GPS/dashboard work.

No GPS/dashboard files were staged, committed, or pushed before this handoff.

### Intended GPS/dashboard-only commit scope if the owner approves it

Modified files:

- `android/app/src/main/kotlin/com/maintainiac/TripTrackingForegroundService.kt`
- `android/app/src/main/kotlin/com/maintainiac/TripTrackingNativeBridge.kt`
- `docs/gps_assisted_tracking/GPS_FIELD_EVIDENCE_TEMPLATE.json`
- `lib/screens/dashboard/dashboard.dart`
- `lib/screens/dashboard/data/dashboard_trip_tracking_summary.dart`
- `lib/shared/trip_tracking/trip_tracking_controller.dart`
- `lib/shared/trip_tracking/trip_tracking_controller_native_collection.dart`
- `lib/shared/trip_tracking/trip_tracking_controller_native_events.dart`
- `lib/shared/trip_tracking/trip_tracking_controller_native_lifecycle.dart`
- `lib/shared/trip_tracking/trip_tracking_controller_session_lifecycle.dart`
- `lib/shared/trip_tracking/trip_tracking_dashboard_live_status_policy.dart`
- `lib/shared/trip_tracking/trip_tracking_platform_events.dart`
- `test/active_workday_gps_start_integration_test.dart`
- `test/dashboard_round_start_gps_integration_test.dart`
- `test/support/trip_tracking_qa/trip_tracking_benchmark_reporter.dart`
- `test/support/trip_tracking_qa/trip_tracking_field_evidence.dart`
- `test/trip_tracking_benchmark_reporter_test.dart`
- `test/trip_tracking_dashboard_live_status_policy_test.dart`
- `test/trip_tracking_field_evidence_test.dart`
- `test/trip_tracking_fuzz_test.dart`

Untracked GPS files to include in that scoped commit:

- `test/trip_tracking_commercial_workday_replay_test.dart`
- `test/trip_tracking_field_failure_replay_test.dart`
- `test/trip_tracking_native_provider_registration_contract_test.dart`
- `test/trip_tracking_provider_registration_state_test.dart`
- `tool/trip_tracking_commercial_workday_qa.sh`
- `tool/trip_tracking_s24_readiness.sh`
- `tool/trip_tracking_s24_runtime_probe.sh`

Before staging after owner approval, run an explicit scoped `git diff --stat` and stage only the approved files. Do not use `git add .`.

## 10. Unrelated Dirty Work That Must Be Preserved

The tree also contains dirty work outside GPS/dashboard, including:

- Receipt camera/OCR/manual receipt flow on Android, iOS, Dart, docs, tests, and receipt QA scripts.
- Device capability model/parser/native bridge work.
- Contractor dashboard, Jobs, work supply, weekly expenses/payments, and estimate screens.
- Maintenance receipt parsing.
- `PROJECT_RULES.md`, assorted screen notes, and Custom GPT bridge documents.
- `CUSTOM_GPT_BRIDGE_WRITE_PROBE.md`.

Do not assume any of these are disposable. Do not include them in a GPS commit unless the owner explicitly expands scope.

## 11. Existing Goal Status

The GPS hardening goal was marked `blocked`, not complete. The block is the repeated external dependency on a connected/authorized S24 and background location permission. The software checkpoint is green, but full objective completion requires real driving, stop-detection, background survival, and recovery evidence.

When the owner reconnects the S24 and grants the necessary test permission, resume the existing goal or create a new explicitly owner-approved field-test goal. Do not redefine passing synthetic tests as completion.

## 12. Recommended Next Model Sequence

1. Read this handoff first.
2. Confirm the current checkout path and current `git status --short --branch`.
3. If asked to publish GPS/dashboard work, stop and obtain the owner's choice about publishing the six prior receipt commits versus authorizing an isolated branch/worktree procedure.
4. If S24 field work is authorized, verify ADB connection and run the readiness script before touching the app.
5. Do not start a real workday. Ask for approval for a dedicated controlled test session if required.
6. Run the runtime probe while the owner-approved test session is active.
7. Collect multiple field runs and compare only coordinate-minimized evidence.
8. Report actual observed distance error, provider/background/recovery rates, and stop precision/recall. State confidence intervals or uncertainty; do not infer 90-95% reliability from a small sample.
9. Keep confirmed odometer protection intact throughout.
10. Only after enough physical evidence should a commercial readiness claim be considered. It has not been earned yet.
