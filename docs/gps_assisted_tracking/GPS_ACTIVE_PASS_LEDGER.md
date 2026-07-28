<!--
Contains the concise active ledger for the current GPS commercial-hardening run.
Owns pass status, inspected evidence, failures, repairs, tests, and next actions.
Does not replace product requirements, source code, test logs, or field evidence.
Consumed by the active engineer to avoid repeated repository discovery.
All GPS, Bluetooth, and map evidence remains advisory until explicit review.
-->

# GPS Active Pass Ledger

Updated: 2026-07-28 EDT

## Repository checkpoint

- Checkout: `/Users/rbbie/Documents/Maintainiac_5.7_Active`
- Branch: `codex/receipt-manual-screen-rebuild-20260726`
- Revision: `c7b89705e15dc67dea989075abc2b2d296b8947f`
- Upstream: `origin/codex/receipt-manual-screen-rebuild-20260726`
- Ahead/behind: `0/0`
- Worktrees observed: one, the current checkout
- Staged: 0
- Unstaged: 0
- Untracked before this directive: 0
- Current intentional untracked files:
  - `docs/gps_assisted_tracking/GPS_COMMERCIAL_GRADE_MASTER_DIRECTIVE.md`
  - `docs/gps_assisted_tracking/GPS_ACTIVE_PASS_LEDGER.md`
- Unrelated changes: none currently reported; future unrelated work remains owner-owned

## Authoritative owners

- Production bootstrap: `lib/main.dart`, `main()`
- Session coordinator: `lib/shared/trip_tracking/trip_tracking_controller.dart`, `TripTrackingController`
- Durable active session/recovery: `trip_tracking_session_store.dart`, `TripTrackingSessionStore`
- Distance and motion: `trip_tracking_engine.dart`, `TripTrackingEngine`
- Stop classification: `trip_stop_classification.dart`, `TripStopClassifier`
- Route evidence: `trip_tracking_route_point_store.dart`, `TripTrackingRoutePointStore`
- Provider startup/readiness: `trip_tracking_controller_native_collection.dart` and `trip_tracking_controller_native_events.dart`
- Heartbeat/degraded state: `trip_tracking_controller_native_lifecycle.dart`, `checkNativeHeartbeat`
- Android provider: `TripTrackingForegroundService.kt` and `TripTrackingNativeBridge.kt`
- iOS provider: `ios/Runner/TripTrackingNativeBridge.swift`
- Bluetooth observation: shared `DeviceCapabilityService` plus Android `DeviceCapabilityEvents`
- Bluetooth associations: `trip_tracking_bluetooth.dart`, `TripTrackingBluetoothVehicleLinkStore`
- Bluetooth matching/start decision: `trip_tracking_bluetooth_coordinator.dart`
- Bluetooth stream binding: `trip_tracking_bluetooth_binding.dart`
- TripLog handoff: `trip_tracking_trip_log_proposal.dart` and its store
- Complete trip gate: `tool/trip_tracking_qa_gate.sh --all`
- Commercial replay: `tool/trip_tracking_commercial_workday_qa.sh`
- Existing simulator: `tool/trip_tracking_simulation_runner.dart`
- Existing fixed corpus: `test/support/trip_tracking_qa/trip_tracking_benchmark_corpus.dart`
- Existing audit: `tool/trip_tracking_expert_audit.sh`

## Inspected evidence and answered questions

- Git metadata: current branch/upstream are aligned; no branch or worktree was created.
- Retained complete-gate log: eight named failures existed at revision `4f06b8e1`.
- Current targeted reproduction: the same eight failures exist at `c7b89705`.
- `main.dart`: constructs the GPS controller but never constructs `TripTrackingBluetoothBinding`.
- Bluetooth production references: zero constructor calls outside the binding definition.
- Bluetooth association production writes: no non-test caller currently saves an approved link.
- Provider startup: successful native command sets `nativeTracking`, but provider truth stays false until native status `tracking`.
- Android service: `isCollectorActive` intentionally covers both registering and running states.
- Existing simulator: rebuilds the same 27 deterministic fixtures up to 1,000 times; it is a repeatability benchmark, not a 100,000-scenario generator.
- Existing fuzz tests: seeded hostile and mixed-motion inputs provide useful engine coverage but do not cover the complete lifecycle/Bluetooth state space.

## Original failure list (repaired)

Retained reproduction log: `/tmp/maintainiac_pass1_eight_failures.log`

1. Low-battery override retry expects immediate `tracking`; actual is `awaiting_provider_registration`.
2. Unavailable low-power capability expects immediate `tracking`; actual is `awaiting_provider_registration`.
3. Plugged-in low battery expects `tracking`; actual is `odometer_projection_invalid`.
4. Heartbeat exactly at freshness boundary expects active; actual is degraded.
5. Malformed native payload expects immediate `tracking`; actual is `awaiting_provider_registration`.
6. Native idle status expects immediate `tracking`; actual is `awaiting_provider_registration`.
7. Native source contract expects the old `isRunning` guard; implementation now uses `isCollectorActive`.
8. Native source ordering assertion searches for the obsolete guard and fails.

## Proven root causes

- Failures 1, 2, 5, and 6 used obsolete test setup that never emitted the now-required provider-registration status.
- Failures 7 and 8 asserted the obsolete `isRunning` guard; `isCollectorActive` correctly suppresses starts while registering and running.
- Failure 3 supplied a six-minute-old cached point, so stale-evidence rejection correctly prevented the projected odometer update.
- Failure 4 crossed the 45-second initial-fix deadline without first supplying a valid fix, so degraded state was correct before heartbeat freshness was evaluated.

## Current pass

- PASS 6
- Objective: wire approved Bluetooth observations into the production lifecycle exactly once
- State: passed
- Source changes: production construction/injection, root lifecycle start/resume/dispose, authoritative decision delegation
- Test changes: coordinator resolver regression and production source-contract coverage
- Regression cases added: authoritative device-resolution delegation and production lifecycle wiring
- Focused Bluetooth tests: 18 passed, exit 0
- Focused analysis: exit 0
- Complete trip gate: `TRIP_QA_PASS`, exit 0 after repairing its obsolete root-widget constructor assertion
- Retained logs:
  - `/tmp/maintainiac_pass6_bluetooth.log`
  - `/tmp/maintainiac_pass6_analyze.log`
  - `/tmp/maintainiac_pass6_complete_gate_rerun.log`
- Result: Android-capable approved observations now reach the existing coordinator; retries are idempotent and disposal is owned by the root lifecycle
- Limitation: no production UI yet creates a user-approved device link; automatic start remains fail-closed because no real paid entitlement owner exists

## Completed passes

| Pass | Result | Objective | Evidence |
| --- | --- | --- | --- |
| 1 | PASSED | Verify checkpoint, owners, failures, wiring, and harness | Eight failures reproduced; production Bluetooth missing |
| 2 | PASSED | Provider registration and collector-state contracts | Focused and adjacent tests exit 0 |
| 3 | PASSED | Charging and live projection boundary | Focused and adjacent battery tests exit 0 |
| 4 | PASSED | Heartbeat freshness after valid initial fix | Heartbeat family and original eight exit 0 |
| 5 | PASSED | Complete trip-domain gate | `TRIP_QA_PASS`, exit 0 |
| 6 | PASSED | Production Bluetooth lifecycle wiring | 18 focused tests and analysis exit 0 |

## Safest repair order

1. Reconcile provider-registration and Android source contracts.
2. Repair charging/odometer projection boundary.
3. Repair heartbeat freshness/degraded boundary.
4. Run the complete trip gate until green.
5. Wire Bluetooth bootstrap and approved-association UI/runtime path.
6. Establish permanent regression corpus and scalable stress harness.
7. Run 100,000 scenarios, same-seed repeat, and different-seed run.
8. Run Android build/readiness, then physical S24 validation.
9. Run physical iPhone build/readiness after the owner reports it powered on.

## Next smallest justified action

Add the user-reviewable Bluetooth association path without exposing opaque identifiers or silently changing an active trip.
