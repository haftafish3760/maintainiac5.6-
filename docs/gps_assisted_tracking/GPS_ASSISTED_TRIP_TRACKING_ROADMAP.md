# GPS-Assisted Trip Tracking Roadmap

## Mission and boundaries

Build a local-first, cross-platform GPS-Assisted Trip Tracking system for
Maintainiac. It assists TripLog and the global odometer; it never silently
creates confirmed business records, overwrites confirmed odometer readings, or
depends on network access during an active trip.

In scope: shared Dart tracking intelligence, Android and iOS adapters,
TripLog/dashboard integration, local Hive persistence, optional later sync
boundaries, simulation, benchmarking, diagnostics, and real-device test tools.

Out of scope: maps, navigation, route optimization, OCR, receipt parsing,
inventory, invoices, and unrelated dashboard redesign.

## Delivery rules

1. One coherent subsystem change at a time; repair every introduced failure
   before continuing.
2. Hive is the immediate source of truth. Firestore is a later mirror only.
3. Confirmed odometer readings and confirmed TripLog records are authoritative.
4. Android and iOS share domain contracts, not false lifecycle assumptions.
5. GPS findings are advisory until a user confirms, corrects, or dismisses them.
6. Every discovered defect receives a deterministic regression when practical.
7. Validate affected scope continuously; run phase validation about every ten
   implementation passes and before every stable checkpoint.
8. Push only coherent green checkpoints, normally no more than twice hourly.

## Phase 0 — controlled baseline

- Inventory only GPS, dashboard/active-workday, odometer, TripLog, Hive,
  Firestore boundary, Android, iOS, and existing QA files.
- Record Flutter/Dart, Android SDK/Gradle/Kotlin, iOS target/Xcode/Swift,
  package choices, current branch/commit, dirty files, and pre-existing faults.
- Classify code as reusable, incomplete, duplicate, unsafe, obsolete, or
  missing.
- Establish a green targeted baseline without altering OCR, inventory, or
  generic QA infrastructure.

Gate: baseline findings and relevant-file index recorded; no new failures.

## Phase 1 — domain architecture and versioning

- Consolidate one shared tracking domain boundary around normalized samples,
  settings, session state, validation, filtering, distance, motion, health,
  diagnostics, persistence, and TripLog assistance.
- Version persisted session/sample/event/algorithm records from the start.
- Define explicit session, motion, health, acquisition, and recovery states;
  reject illegal transitions and make legal transitions idempotent.
- Preserve existing sound abstractions; remove only proven duplicate GPS code.

Gate: domain contracts are small, serializable, migration-tolerant, and covered
by model/state-transition tests.

## Phase 2 — authoritative settings

- Create one settings model with global defaults and profile overrides.
- Support High Accuracy (3s), Enhanced (8s), Balanced (15s), Battery Saver
  (30s), Extreme Optimized (60s), and validated custom values.
- Centralize all units and thresholds: accuracy, age, displacement, stationary
  radius, movement/stop confirmation, gaps, jump/speed/acceleration limits,
  batching, retention, diagnostics, and platform overrides.
- Persist settings locally and make every algorithm run record its threshold and
  algorithm version.

Gate: boundary-value and serialization tests pass; no magic thresholds remain in
tracking flow code.

## Phase 3 — permissions, capabilities, and privacy

- Implement structured capability results, not vague booleans.
- Android: services state, coarse/precise/background permissions, notification
  permission, foreground-service constraints, battery restrictions, and runtime
  revocation.
- iOS: service state, authorization level, full/reduced accuracy, background
  capability, authorization changes, scene lifecycle, and supported relaunch
  behavior.
- Keep manual mileage workflows available for every denied/degraded state.
- Never collect prohibited identity, passenger, patient, VIN, or plate data.

Gate: Android/iOS contract tests and native manifest/plist checks pass.

## Phase 4 — native acquisition adapters

- Keep native code responsible only for obtaining and normalizing platform data.
- Implement duplicate-subscription prevention, foreground/background behavior,
  stream error/termination detection, permission changes, bounded recovery, and
  clean stop/restart handling.
- Preserve platform metadata where available: timestamps, accuracy, speed,
  bearing, source, mock/reduced-accuracy indication, and lifecycle state.
- Use platform channels/background facilities only where each platform supports
  them; never claim parity unsupported by iOS or Android.

Gate: native adapters compile for available targets and pass contract/lifecycle
tests.

## Phase 5 — durable sample ingestion

- Normalize each sample with identity, timestamps, source metadata, schema and
  processing versions.
- Add a bounded, ordered per-session local ingestion queue with idempotency,
  backpressure, poison-record isolation, checkpoints, bounded retry, and dropped
  sample metrics.
- Avoid a massive Hive day object rewrite for every raw point; retain bounded raw
  and filtered records according to settings.
- Never make active tracking wait for Firestore.

Gate: queue ordering, crash checkpoint, duplicate, malformed record, and
backpressure regressions pass.

## Phase 6 — validation and filtering pipeline

- Classify each sample as accepted full/reduced, continuity-only, deferred, or
  rejected with a machine-readable reason.
- Validate structural, temporal, accuracy, kinematic, and contextual evidence.
- Handle malformed coordinates, stale/future/reversed/duplicate time,
  reduced accuracy, impossible jumps, speed/heading contradictions, clock
  changes, gaps, and provider degradation.
- Implement only benchmark-proven filters: accuracy weighting, stationary
  clustering, outlier/velocity/heading checks, adaptive smoothing, and gap-aware
  recovery. Keep all stages deterministic and versioned.

Gate: deterministic replay and adversarial regression corpus passes.

## Phase 7 — distance and odometer reconciliation

- Maintain raw, validated, filtered, estimated-gap, unresolved, confirmed
  TripLog, and confirmed-odometer distance separately.
- Use incremental geodesic calculations with reproducible full recalculation.
- Treat gaps conservatively: retain evidence, separately mark defensible
  estimates, lower confidence, and never fabricate route detail.
- At confirmation, compare odometer delta to GPS categories and surface material
  discrepancies without silently selecting GPS over the odometer.

Gate: drift, jump, outage, recovery, antimeridian/polar, rounding, and
reconciliation tests pass.

## Phase 8 — motion and stop state machine

- Confirm movement from repeated credible evidence, not one noisy point.
- Model unknown, stationary, movement candidate, moving, stop candidate,
  stopped, signal unavailable, and recovering states.
- Distinguish traffic lights, congestion, drive-through queues, fuel/delivery
  stops, parking, signal loss, trip completion, and workday completion as far as
  evidence permits.
- Walking evidence may generate a review-only possible-stop cue; it never
  creates a confirmed stop automatically.

Gate: transition matrix, long-light, stop-and-go, low-speed equipment, and
walking regressions pass.

## Phase 9 — TripLog assistance bridge

- Produce durable advisory events: movement/trip start, probable stop/end,
  resumed movement, signal loss/recovery, interruption, discrepancy, and review
  required.
- Include identity, evidence window, confidence category, suggested action,
  disposition, and confirmed TripLog reference where applicable.
- Support confirm/reject/correct/classify/merge/split/dismiss without repeated
  nagging after a rejection.
- Preserve Start Day, pickup, drop-off, manual trip, pause/resume, End Day, and
  manual odometer workflows.

Gate: bridge tests prove GPS does not mutate Recap or confirmed TripLog history
without the required workflow.

## Phase 10 — recovery, health, and diagnostics

- Recover conservatively from navigation, backgrounding, lock, process/service
  recreation, temporary signal loss, malformed checkpoints, app upgrade, and
  supported platform relaunch paths.
- Restore queues and state safely, record interruptions, reacquire stable fixes,
  avoid route fabrication, and flag uncertainty for review.
- Measure permission/service state, freshness, accuracy, rejection ratios,
  gaps, heartbeat, queue health, persistence failures, platform restrictions,
  confidence category, and distance health.
- Keep production diagnostics coordinate-minimal and export only deliberately.

Gate: recovery/interruption/permission-revocation tests pass with structured
health states.

## Phase 11 — simulation, fuzzing, and benchmarks

- Expand the production-pipeline replay harness with versioned deterministic
  fixtures and seeds.
- Cover city/highway/rural, stop-and-go, long lights, delivery/fuel/parking,
  tunnels, canyons, weak/reduced accuracy, long gaps, lifecycle interruption,
  permission loss, battery saver, service recreation, 8–12 hour sessions, and
  corrections.
- Add bounded deterministic fuzzing for malformed/oscillating/extreme samples,
  irregular time, queue interruption, corrupt recovery data, and lifecycle
  races.
- Report separate distance error, drift, event precision/recall, recovery,
  latency, queue, memory, sample ratio, and measurable battery proxies. Do not
  make unsupported accuracy claims.

Gate: seeded fuzz suite, long-session suite, and benchmark reporter are green.

## Phase 12 — real-device validation and final hardening

- Prepare Android/iOS test-record templates and import/comparison tools so
  opt-in device traces can become sanitized regression fixtures.
- Record device/OS/app/version, preset, battery, known odometer start/end,
  route type, foreground/background/lock time, stops, interruptions, health,
  GPS categories, confirmed distance, and corrections.
- Run formatting, full GPS static analysis, full relevant shared tests, Android
  build/tests, iOS build/tests available on this Mac, simulation/fuzz/long-run
  suites, diff review, and concise limitations documentation.
- State clearly which real-device claims remain unproven.

Gate: all available validation is green, stable checkpoints are committed, and
the final report distinguishes implemented evidence from external validation.

## Checkpoint cadence

- Each pass changes one coherent GPS seam and runs its smallest relevant check.
- Every ten implementation passes, run format, affected analysis, relevant
  integration tests, and an affected build where practical.
- Commit/push only after a coherent green checkpoint; never mix OCR, inventory,
  parser, receipt-camera, or unrelated user changes into GPS commits.
