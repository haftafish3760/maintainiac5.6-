# GPS-Assisted Trip Tracking Completion Roadmap

## Current readiness

- Source-level hardening: approximately 75% complete.
- Readiness for meaningful live-road testing: approximately 55-60% complete.
- Proven real-world accuracy: not yet measured. No percentage claim is justified
  until route evidence is collected on real Android and iOS devices.

## Architecture decisions now fixed

1. Confirmed odometer readings are the global mileage truth. GPS can estimate,
   compare, warn, and propose a value; it never silently changes confirmed
   odometer or TripLog history.
2. GPS tracking, TripLog, and every other feature write locally first. The
   shared durable-storage system owns cloud transport, batching, retry,
   conflict handling, authentication integration, rules/functions, and cost
   monitoring. Feature modules do not write directly to Firestore.
3. A feature supplies a bounded, versioned backup package to durable storage;
   durable storage combines eligible changed data across the app into one user
   document/package per allowed sync window. The current free-user target is a
   maximum of six cloud sync windows per day, subject to the final durable-
   storage design and Firestore document-size limits.
4. Raw one-second GPS points are never a default Firestore sync payload.
   Active GPS tracking remains fully functional without network access.
5. Walking is supporting evidence for a real stop. It cannot silently create a
   confirmed stop, trip, workday ending, or business classification.
6. The adaptive mileage-sanity system is opt-in, advisory, explainable, and
   never blocks a user from entering a legitimate reading.

## Detailed remaining GPS and odometer-hardening roadmap

### Phase A — complete tracker correctness before simulation

1. Audit the remaining GPS-only paths for duplicate ownership and ensure one
   authoritative state transition for session start, pause, resume, degraded
   operation, recovery, and completion.
2. Finish source-level contracts for location-provider loss, approximate or
   reduced accuracy, stale callback delivery, background restriction, device
   restart, corrupted local checkpoint, duplicate start attempts, and repeated
   stop attempts.
3. Harden battery behavior: selected cadence, adaptive movement/stationary
   modes, charger state where platform support exists, and clear user-visible
   low-battery safeguards. A low battery must never silently change tracking
   policy; user settings and consent control the result.
4. Finish notification/permission contracts so GPS can ask for and respect
   only its own necessary notification behavior while coexisting with the
   application's broader notification preferences.
5. Confirm profile behavior for normal driving, delivery/contractor stops,
   rideshare/vehicle-only stops, and low-speed equipment. Do not make a single
   stop threshold pretend to suit every use case.
6. Add targeted regressions for every defect found during this phase. Validate
   only affected tests and platform builds after bundled changes.
7. Automatic-start assistance remains deliberately unavailable in production.
   Its settings model and multi-observation detector exist, but no approved
   pre-trip native observation source or user-facing toggle is wired. Do not
   expose the toggle until background monitoring, permission disclosure,
   battery cost, candidate-session recovery, and real-device false-start rates
   are designed and measured without creating a second tracking engine.

### Phase B — odometer reconciliation and adaptive sanity assistance

1. Preserve the existing authoritative sequence: starting confirmed odometer,
   GPS-assisted live estimate, ending user-confirmed odometer, then a
   discrepancy/review record. No automatic correction.
2. Establish an opt-in baseline model that stores only the minimum needed
   per-vehicle, per-day-of-week history: confirmed daily miles, confidence,
   sample count, and a robust range rather than a brittle single average.
3. Use robust statistics: ignore or down-weight first-time days, manually
   marked exceptional days, obvious entry mistakes, GPS-degraded sessions, and
   sparse history. Do not warn from one or two days of data.
4. Detect suspicious entries conservatively: ending odometer below start,
   zero/near-zero delta after meaningful tracked movement, implausibly large
   delta compared with the user's established range, and unusually consistent
   GPS-versus-odometer discrepancy.
5. Explain why a review is suggested and provide safe choices: confirm as
   entered, correct it, mark as exceptional/out-of-town, or dismiss. A warning
   must never prevent legitimate long-distance work.
6. Track recurring GPS-to-odometer differences only as an advisory calibration
   signal. Oversize/undersize tires, uncalibrated gearing, sensor faults, and
   poor GPS are possible explanations; neither source is silently “fixed.”
7. Keep this model independent of jobs initially. Add a narrow optional job/
   worksite context adapter later, after the jobs contract exists, so a new
   work area can start a new baseline without corrupting historic patterns.

### Phase C — settings, user control, and device capability integration

1. Provide explicit GPS controls for enablement, accuracy/cadence preset,
   adaptive sampling, stop-assistance behavior, low-battery behavior, and
   diagnostics/privacy level.
2. Ask for location, activity/motion, and notification permissions only when
   the feature that needs each permission is enabled; handle denial, revocation,
   approximate location, and unsupported hardware safely.
3. Integrate the shared device-capability layer so cheap, older, restricted,
   and flagship devices receive supported behavior rather than assumptions.
4. Keep manual start/end mileage and manual TripLog workflows usable when
   location, motion, notifications, network, or capability support is absent.

### Phase D — pre-simulation verification

1. Run focused model, controller, engine, platform-contract, recovery, and
   permission regressions after coherent implementation bundles.
2. Run Android debug and iOS device builds at meaningful platform boundaries;
   do not use emulators or the everyday phone as a QA target.
3. Review local persistence boundaries, privacy-safe diagnostics, bounded
   queues, duplicate-session protections, and algorithm-version behavior.
4. Resolve all introduced failures before beginning the deferred simulation
   phase.

## Completed foundation and hardening

1. Shared Flutter trip-tracking domain exists, including tracking sessions,
   sample processing, distance handling, motion state, stop assistance,
   recovery, diagnostics, and TripLog-facing boundaries.
2. GPS remains advisory: confirmed odometer and confirmed TripLog history stay
   authoritative; GPS cannot silently overwrite either.
3. Android foreground acquisition, permission/capability handling, activity
   recognition assistance, collector lifecycle, stale callback isolation, and
   restart safeguards have been implemented and hardened.
4. iOS Core Location/Core Motion handling, location-service availability,
   reduced/degraded evidence, stale callback isolation, and safe session
   teardown have been implemented and hardened.
5. Native samples are screened for malformed metadata, invalid coordinates,
   future timestamps, fractional/invalid activity confidence, weak speed
   quality, and pre-session motion evidence.
6. Monotonic timing, timestamp ordering, clock-epoch recovery, stale samples,
   impossible acceleration, speed-quality evidence, and sampling-cadence
   safeguards are covered by deterministic regressions.
7. Stop assistance distinguishes walking evidence from vehicle-only stops;
   traffic-light and low-speed-equipment false-positive protections are in
   place. A detected stop remains advisory rather than a silently confirmed
   business event.
8. Permission changes, disabled services, native startup/update failures,
   recovery snapshots, consent persistence, durable motion evidence, and
   live-odometer projection failures fail safely and retain actionable,
   privacy-safe diagnostics.
9. Targeted tests, analyzer checks, Android debug compilation, and iOS device
   compilation have passed. The current bundled GPS gate passes more than
   1,700 tests; this remains source/build evidence rather than a real-route
   accuracy claim.
10. A coordinate-minimized field-evidence schema and real-device protocol have
    been prepared. They record mileage, walking-stop counts, conditions, and
    health without routinely exporting raw route coordinates.

## Remaining implementation and validation roadmap

### Phase E — deterministic simulation, replay, and fuzzing

1. Review remaining source paths for one active authoritative implementation
   of session recovery, queue boundaries, provider degradation, and motion
   transitions; remove or contain only GPS-scoped duplication if found.
2. Finish targeted adversarial contracts for lifecycle races, provider changes,
   unusual but physically possible motion, and recovery continuity.
3. Validate every new source change with the smallest affected tests, analyzer,
   and platform build necessary; add a permanent regression for each defect.

### Phase F — benchmark and tune

1. Run and expand the existing production-pipeline replay framework, not a
   parallel fake implementation.
2. Cover city/highway/rural driving, long lights, delivery/fuel stops,
   walking/resumption, parking, tunnels, urban canyon drift, stale/duplicate/
   out-of-order points, signal gaps, clock changes, permission revocation,
   backgrounding, and recovery.
3. Run bounded deterministic fuzzing for malformed samples, extreme timing,
   oscillation, queue interruption, corrupt recovery state, and repeated
   start/stop requests. Record seeds for every failure.
4. Run long-session replay and memory/queue-growth checks.

### Phase G — real-device field testing

1. Produce separate measurements for mileage error, stationary drift,
   movement/stop precision and recall, missed/false session rate, recovery
   success, processing latency, and confidence/review rates.
2. Compare filter and cadence variants only when the benchmark corpus shows a
   measurable improvement; version any accepted algorithm change.
3. Do not call 90-95% accuracy achieved unless the measured corpus and real
   routes support that statement.

### Phase H — release decision

1. Build an Android and iOS test matrix using the existing real-device
   protocol.
2. Start with ordinary driving, repeated pull-over/walk/resume stops,
   traffic-light controls, locked-background operation, and known odometer
   comparisons.
3. Expand to tunnels/garages, poor GPS, permission changes, long stationary
   time, long workdays, lawn-care/low-speed equipment, and recovery after
   interruption.
4. Convert every reproducible field defect into a sanitized deterministic
   fixture and regression before tuning behavior.

### Phase I — Firebase design and integration (requires a separate cost decision)

1. Define the free and paid retention limits, what data may leave the device,
   and whether route geometry is ever eligible for backup.
2. Keep active tracking and immediate writes local-first. Never upload a GPS
   document per second or make tracking depend on Firestore availability.
3. Design bounded sync records, retention/deletion behavior, security rules,
   offline retry, cost monitoring, and emulator-backed rules tests before
   enabling production sync.
4. Implement only the agreed design, then measure reads, writes, storage,
   indexes, listeners, and egress with realistic user-day workloads.

### Phase J — Mapbox integration (after GPS evidence and Firebase policy)

1. Define which users receive map history, map retention, route precision,
   stop markers, privacy controls, and whether map data is local-only or
   eligible for backup.
2. Start with rendering an already-confirmed local trip path and stop markers;
   do not let mapping own trip distance, odometer, or stop truth.
3. Add route replay, history filtering, error/offline states, and optional
   downloadable regions only after the base map has real-device evidence.
4. Treat turn-by-turn navigation and route optimization as separate projects,
   not prerequisites for GPS-assisted trip tracking.

## Explicitly deferred or out of scope

- Dashboard UI, global odometer UI workflow, vehicle/Bluetooth selection,
  durable-storage implementation, Mapbox/maps,
  navigation/route optimization, fleet tracking, OCR, inventory, receipts,
  invoices, and unrelated modules.
- Deterministic simulation/replay is now active and covers a bounded
  production-pipeline corpus. A ten-hour controller/store replay now proves
  bounded coordinate-free recovery state and preserved odometer authority.
  The benchmark corpus also covers a plausible tunnel/garage no-fix interval
  and verifies that recovery resumes without counting the hidden route or
  suggesting a false stop.
  A 1,000-iteration run now executes 24,000 deterministic case replays and
  reports explicit stop confusion counts without elevating synthetic evidence
  into a field-accuracy claim.
  Recorded lifecycle seeds also cover competing native start, stop, app
  pause/resume, and heartbeat operations while proving serialized native
  commands and one session identity. Native real-device long-session/field
  routes and field-derived defect seeds remain incomplete.
- Startup recovery now detects a native collector with no readable owning
  session, requests stop, and verifies the stopped state before reporting
  success. Stop refusal and failed verification remain controlled,
  user-actionable recovery states and never create mileage.
- Contractor-day GPS controls are now discoverable from the dashboard through
  an explicit optional `Start GPS` action. Deferred signal-safety cleanup
  yields to an in-progress user stop so native collection is stopped once.
- Foreground runtime supervision now probes the expected native collector at a
  bounded interval through the existing heartbeat policy. A silently killed
  collector therefore becomes a preserved degraded/interrupted trip instead of
  waiting indefinitely for another provider event; no distance, stop, or
  odometer value is fabricated during the gap.
- Active-workday GPS controls now complete their full start-to-review regression
  at 200% accessibility text scaling. Quick-action wording remains visible
  without ellipses, and the dynamic grid removes the reproduced overflow.
