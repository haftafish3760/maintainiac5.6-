# GPS-Assisted Trip Tracking Real-Device Protocol

## Purpose and safety boundary

Simulations, source contracts, and builds do not establish field accuracy. This
protocol supplies the physical evidence needed before any production claim. It
tests mileage capture only; it does not authorize route collection, maps,
address lookup, employee surveillance, or live-location features.

Run only with a consenting tester in a safe driving environment. Never operate
the app while driving. A passenger should operate the device when interaction
is required, or perform each interaction while safely parked.

## Pre-run setup

1. While parked, select the intended vehicle and work profile and record the
   physical starting odometer.
2. Explicitly opt in to GPS assistance. For a high-accuracy trial, select
   **High accuracy (3 sec)** before starting; do not silently change a driver's
   saved preset.
3. Explicitly opt in to activity recognition only when the run is intended to
   evaluate walking-assisted stop evidence. Maps and route-history saving may
   remain off and are not required for GPS assistance.
4. Complete the in-app location, notification, and background-location
   preflight as requested by the selected mode. Do not grant permissions with
   ADB or outside the user-directed flow.

## Run record

Create one coordinate-minimized record for every Android and iOS run. Record:

- Device model, OS version, app build/commit, profile, and sampling preset.
- Starting and ending physical odometer; confirmed odometer delta; app GPS
  distance; any user review/correction; and the agreed tolerance for that run.
- Foreground, locked-background, and total duration; battery start/end; and
  any thermal/battery-saver state.
- Permission state, precise/approximate state, background setting, signal
  interruptions, expected stops, detected advisories, health/error state, and
  recovery result after relaunch.
- Backup state (off/private/org), organization-sharing consent state, and only
  summary-upload outcome. Do not retain coordinates, screenshots containing
  locations, route polylines, addresses, or raw native GPS logs.

For the importable comparison subset, copy
`GPS_FIELD_EVIDENCE_TEMPLATE.json` once per run and replace only its listed
values. The importer intentionally accepts only platform, confirmed odometer
miles, filtered GPS miles, and aggregate walking-stop counts; keep the richer
run record separate and coordinate-free.

Use a private, deliberately approved fixture only if a route is essential to
investigate a defect. Remove personal locations before promoting it to a
regression fixture and record only expected distance, stop, gap, and health
outcomes.

## Required scenario matrix

### 1. Basic driving and stationary drift

1. Start a road-vehicle trip while parked; confirm the live odometer does not
   advance before credible movement.
2. Drive an urban route with several traffic lights without exiting the
   vehicle. Confirm traffic stops do not become walking/stop advisories.
3. Stop parked for several minutes before ending. Confirm GPS jitter does not
   create additional mileage.
4. Finish into review. Confirm the permanent odometer remains unchanged until
   the user explicitly accepts the reviewed mileage.

### 2. Walking, stops, and resumption

1. Drive, park, walk away from the vehicle, return, then resume driving.
2. Confirm on-foot movement is excluded only after sustained, credible walking
   evidence; a single noisy activity signal must not remove vehicle miles.
3. Confirm advisories are review-only and can be acknowledged without changing
   accepted GPS distance.

### 3. Signal loss, bad GPS, and restart recovery

1. Run highway driving with a safe tunnel or other deliberate signal-loss
   interval. Confirm the app never bridges the gap into fabricated distance.
2. Toggle location services off while parked, then restore them. Confirm the
   trip becomes recoverable, native collection stops, and no crash occurs.
3. Force-close/relaunch during an active trip. Confirm the durable local
   session restores its live projection and does not duplicate the final
   sample or a review record.
4. End a trip immediately after resuming from a gap. Confirm final queued GPS
   events are included once and the review remains locally available.

### 4. Permission and app lifecycle boundaries

1. Deny precise location, then retry after granting it. Confirm no looping
   permission prompts and no empty trip/odometer lock remains after failure.
   On Android 11 or newer, confirm background mode explains that “Allow all
   the time” must be chosen manually, opens only Maintainiac's app-settings
   page after explicit confirmation, and returns safely when dismissed. Also
   verify the same user-directed permission preflight is available from GPS
   settings before a trip is created.
2. With foreground-only tracking, lock/background the app. Confirm native GPS
   stops and the local trip remains recoverable.
3. With explicit background tracking enabled and platform approval granted,
   run a locked-screen segment. Confirm tracking behavior, visible platform
   indicator/notification where required, and battery impact are recorded.
4. Revoke permission while tracking. Confirm resources are released, the UI
   presents a recoverable error, and a later retry is possible after consent.
   Test precise-location and background-location withdrawal separately on
   Android and iOS; the native collector must identify the correct permission
   loss even while Flutter is background-suspended. Relaunch before retrying
   and confirm recovery still identifies background permission separately from
   base location or foreground-service restrictions.

### 5. Profiles, battery, and odometer reconciliation

1. Run low-speed lawn-equipment/work-site movement with its designated
   profile. Confirm it remains measurable without silently forcing precision
   mode.
2. Run at least two hours of locked-background tracking with each battery
   preset on representative hardware. Record battery delta and any sampling
   tier changes; do not claim a universal battery result from one phone.
   After a critical-battery pause, relaunch once and confirm the battery cause
   remains visible instead of becoming a generic recovery message.
3. Compare every reviewed run with the physical odometer. Investigate a result
   outside the documented route-specific tolerance; never silently rewrite GPS
   or confirmed odometer truth to make a report look better.

### 6. Local-first backup and organization-consent checks

1. With backup off, finish a trip offline. Confirm the review survives app
   restart and no cloud write is attempted.
2. Enable private backup, then restore connectivity. Confirm only the reviewed
   mileage summary retries; confirm no coordinate-like data appears in the
   queued document.
3. In an organization context with organization sharing off, confirm the same
   summary uses the personal path. Enable explicit organization sharing only
   for a separate consenting run; verify the organization record has no
   location data and can be viewed only under the consented summary rules.
4. Revoke backup or organization-sharing consent while a write is pending.
   Confirm unsent matching records are cancelled locally, private pending
   records are not removed by organization revocation, and local reviews stay.

## Acceptance and defect handling

- A run is evidence, not an automatic pass. Mark each scenario pass, fail,
  blocked, or inconclusive and attach only the coordinate-minimized run record.
- Any fabricated gap mileage, duplicate distance, missing local review,
  unconsented organization visibility, unexpected location field, crash,
  permission loop, or unrecoverable odometer lock is a release-blocking defect.
- Turn a reproduced defect into a deterministic test before changing code.
  Re-run the relevant simulator/controller/Firebase test group and record the
  commit that fixes it.
- Do not call the system production-certified or legally compliant solely from
  this protocol. Field evidence, product policy, deployment configuration, and
  jurisdiction-specific review remain separate release responsibilities.
