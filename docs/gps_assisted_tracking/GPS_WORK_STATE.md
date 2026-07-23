# GPS Work State

- Current phase: 17 — deterministic replay expansion and real-device evidence
  hardening
- Current pass: 504 in the current continuation
- Current objective: harden durable recovery evidence and deterministic
  classification while preserving the real-device evidence boundary
- Relevant files: `lib/shared/trip_tracking/`, `android/app/src/main/`,
  `ios/Runner/`, `test/trip_tracking_*.dart`,
  `docs/gps_assisted_tracking/GPS_REAL_DEVICE_TEST_PROTOCOL.md`
- Previous stable checkpoint: `b87b3030` (degraded lifecycle recovery)
- Latest validation result: Android and iOS native collectors now distinguish
  foreground, background, and location-service authorization loss during
  startup, active collection, recovery, motion-consent withdrawal, and adaptive
  sampling updates. Update races pause locally without deadlocking their own
  serialized event queue or accepting later queued samples. Process recovery
  now retains the actionable background-permission, foreground-service,
  location-service, or critical-battery cause instead of collapsing each into
  a generic pause. Heartbeat reconciliation now has direct controller coverage
  for healthy, stale, interrupted, killed-collector, and lifecycle-resume
  paths. Initial-fix storage failure now stops GPS without overwriting the
  actionable local-storage error, and degraded tracking can now transition
  legally into a user or system pause. Native collection startup and heartbeat
  lifecycle coverage now exercise every collection line and more than 93% of
  the native-lifecycle controller. High-accuracy selection is verified through
  the native three-second request and durable recovery state. Approximate-only
  location now remains advisory, records no trusted distance, reports low
  confidence, keeps the local trip recoverable, and can resume trusted sampling
  after precise access returns; legacy reduced-accuracy callbacks can no longer
  stop the collector or expose raw native errors. The S25 Ultra
  also completed the work-profile add/back regression without an error or app
  crash and was returned to the ready-to-track dashboard. The
  21-case/21,000-run deterministic corpus, synthetic twelve-hour recovery run,
  bundled trip gate, focused analyzer, Android debug build, and generic iOS
  no-codesign build are green
- Every one of the 18 canonical contract lifecycle states now exposes one
  tested behavior contract covering its definition, persistence requirement,
  recovery behavior, user-visible behavior, diagnostic event, legal entries,
  legal exits, and forbidden exits. The transition matrix independently
  verifies every runtime and contract-state pair and every rejection reason;
  state-machine line coverage is 97.4%, with only private constructors
  intentionally unreachable
- Approximate-only permission, its zero-trusted-distance initial fix, and its
  low-confidence state now survive process recovery without becoming mileage;
  a later explicit return to precise access can resume validated sampling
- Unavailable GPS and terminal lifecycle states now take precedence over stale
  degraded/recovering markers, so trusted GPS is stopped and unusable evidence
  is never mislabeled as usable. Driver-pattern review selection remains
  bounded while deterministically retaining the newest evidence from unsorted
  input
- Active and completion-review recovery now reject duplicate, foreign,
  sensitive, inverted, or future-dated advisory evidence. Manual events and
  transition audits cannot advance beyond the durable session/review
  checkpoint, preventing wall-clock anomalies or malformed records from
  rewriting newer recovery state
- Cancelled and stopping recovery now have direct regression coverage proving
  that a mismatched saved review cannot erase or replace either the terminal
  checkpoint or its conflicting evidence. Recovery fails closed for explicit
  repair while the confirmed odometer remains unchanged
- Review cleanup now requires exact locally persisted engine, advisory, manual
  event, transition-audit, battery, permission, ancestry, calibration, and
  recovery evidence. A same-ID review with altered GPS distance or provenance
  can no longer clear the recoverable session checkpoint. Its GPS-assisted
  ending estimate must also reproduce from the preserved accepted distance and
  calibration multiplier; that estimate remains advisory and never changes the
  confirmed odometer. Terminal finish time and tracking-profile identity must
  also match the checkpoint
- Initial-session creation races, initial checkpoint write failure,
  recovery-count checkpoint failure, and optional pending-sample read failure
  now have direct controller regressions proving that no duplicate session,
  phantom odometer lock, or erased durable checkpoint is produced
- Concurrent start attempts through one memory store, two Hive-backed store
  instances, and multiple controllers now prove that only one durable session
  can win and the loser returns a controlled active-trip result
- Split-child creation now converts unavailable parent-review or pending-review
  storage into a controlled local-storage failure before creating a session or
  live odometer projection
- Dashboard-facing review, calibration, and driver-pattern reads now fail
  safely when local review storage is unavailable instead of throwing through
  the UI; they surface a controlled storage error and retain durable evidence
- Completion-draft, TripLog proposal retry, odometer-review evaluation, and
  odometer-confirmation reads now use the same controlled storage boundary, so
  unavailable review storage cannot escape as an uncaught user-action failure
- Calibration refresh, same-weekday mileage anomaly checks, and calibration
  evidence signatures also use that boundary; storage loss cannot crash those
  dashboard-facing advisory calculations or change confirmed odometer truth
- A successful local-review read now clears only its own matching transient
  storage warning, preventing a recovered device from displaying a stale error
  while leaving unrelated failures intact
- Incoming GPS samples now stop before engine or odometer mutation when their
  pending or accepted checkpoint cannot be saved. Native collection enters a
  recoverable system pause, direct ingestion returns a controlled result, and
  a later successful durable sample clears only the matching transient warning
- Paused, review, and terminal sessions now reject late GPS callbacks before
  pending storage, engine mutation, or live odometer projection. Direct system
  pause and recovered user-pause regressions preserve the exact durable
  revision and confirmed odometer until an explicit resume
- Failure to clear an already-durable pending sample no longer loses the
  accepted decision or throws through the event stream. The checkpoint remains
  authoritative, cleanup stays explicit, and recovery cannot double-count it
- A transient activity-evidence storage warning now clears only after a later
  activity checkpoint is durably saved. Walking assistance remains disabled
  for the failed evidence and cannot influence a later GPS sample
- Completion-draft and stop-review retries now clear only their matching
  storage warning after the replacement review is durable. Failed attempts
  remain retryable without changing mileage or losing the pending stop choice
- A successful driver-event retry now clears only its matching event-write
  failure. It cannot erase an unrelated review-storage warning, and duplicate
  command IDs remain idempotent across the failed and successful attempts
- Starting a new durable session no longer erases an unrelated review-history
  storage warning. The warning remains until that exact history boundary reads
  successfully, while start-owned transient failures still clear on retry
- Bluetooth vehicle identity lookup now falls back to explicit manual choice
  when its local link store is unavailable. It cannot switch vehicles, expose
  the opaque device identifier, or affect odometer truth; a later successful
  link read clears only that Bluetooth storage warning
- Automatic-start assistance now distinguishes an unknown local recovery state
  from ordinary movement evidence. It suppresses the suggestion, surfaces a
  controlled local-storage warning, and becomes eligible again only after the
  unfinished-session check succeeds
- Bluetooth vehicle switching now surfaces the same explicit safe fallback
  when unfinished-trip storage cannot be read. It remains blocked until that
  session boundary recovers rather than guessing that a vehicle switch is safe
- Terminal review-write and checkpoint-cleanup faults retain their source
  checkpoint, retry idempotently, and never fabricate a replacement review.
  Malformed terminal evidence fails closed for explicit repair
- The memory adapter now crosses the same serialization and normalization
  boundary as Hive instead of retaining a more permissive object graph. This
  exposed and repaired completion-pending contract restoration, explicit
  historical finish/cancel transition timing, sampling-ceiling normalization,
  and loss of auxiliary recovery evidence when transition audits were bounded
- Battery, permission, and transition evidence are validated at write,
  serialization, and recovery boundaries. Future evidence cannot advance a
  checkpoint, while genuine wall-clock rollback evidence remains preserved
- Recovery reason/source codes and user-confirmed mileage adjustments now
  reject duplicate identities, impossible future ordering, and token or
  coordinate-like private text instead of silently persisting it
- Permission loss now wins races with stale active supervision from every
  recoverable tracking state. It enters the preserved permission-required
  lifecycle, stops trusted collection, blocks replay and backup authority, and
  cannot be discarded as an illegal native transition
- Native provider degradation and pause callbacks now retain their validated
  local lifecycle when the supervisor snapshot is stale. Stream failure or
  closure during native startup is also captured before the start completes,
  forcing cleanup without leaving a phantom collector or duplicate session
- The trip-side Bluetooth vehicle-hint coordinator and capability-stream
  binding are now serialized, idempotent across duplicate callbacks, and
  failure-safe. They can identify or suggest a linked vehicle but cannot change
  mileage or replace an active/unfinished trip. Native approved-device
  observation remains owned by the shared device-capabilities adapter
- The rebuilt Android app is installed on the S25 Ultra. Dashboard Settings
  opens the GPS controls successfully, the active device setting is verified as
  `High accuracy (3 sec)`, and the phone was returned to the Dashboard without
  changing any non-Maintainiac setting
- The S25 Ultra has location services enabled, but Maintainiac location,
  background-location, notification, and activity-recognition permissions
  remain denied. This correctly preserves opt-in; the owner must grant the
  desired permissions in the app before a real route can collect GPS evidence
- The complete 1,800-plus-test trip-domain gate, Android debug build, and
  generic iOS no-codesign build pass after these changes. The current Android
  build is installed and resumed on the S25 Ultra without a Maintainiac crash
- Unresolved blockers: real Android/iOS route, battery, lifecycle, background,
  and long-session runs remain required before any real-world accuracy claim
- Next action: continue lifecycle/recovery replay expansion, then convert
  sanitized field defects into deterministic regressions
