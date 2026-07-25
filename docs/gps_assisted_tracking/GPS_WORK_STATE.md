# GPS Work State

- Current phase: 17 — deterministic replay expansion and real-device evidence
  hardening
- Current pass: 515 in the current continuation
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
- Recovery now defers rather than clears an in-flight GPS sample when the
  durable lifecycle cannot accept trusted location. Paused evidence survives
  restart without becoming distance, and a null replay result can no longer
  silently discard the pending checkpoint
- An explicit resume now validates and replays that deferred checkpoint before
  native collection begins. Unsafe or unavailable evidence returns the session
  to its prior user/system pause, while a successful replay clears only the
  transient sample and leaves the confirmed odometer unchanged
- GPS-derived lifecycle changes now evaluate both runtime and contract state
  machines before committing. An unexpected illegal transition rolls the
  mutable engine back, records the controlled rejection through the existing
  diagnostic boundary, preserves the pending sample, and cannot reach the
  odometer projection as an uncaught assertion
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
- The lower-odometer review now leads with the mileage difference and prior
  reading, uses neutral professional wording, wraps every meaningful sentence
  without ellipses, and remains scrollable at enlarged text sizes. Focused
  widget coverage passes at 1.0x and 2.0x text, and the S25 Ultra renders the
  complete review without overflow or rendering exceptions
- Unresolved blockers: real Android/iOS route, battery, lifecycle, background,
  and long-session runs remain required before any real-world accuracy claim
- Next action: continue lifecycle/recovery replay expansion, then convert
  sanitized field defects into deterministic regressions

## 2026-07-24 production-wiring and reboot-recovery checkpoint

- The primary round `START` workflow now creates the canonical workday and,
  only when the driver has completed GPS setup and opted in, starts the single
  scoped native GPS session for that vehicle and work profile. Existing active
  workdays are never silently restarted.
- The Android foreground service notification code and iOS Core Location
  delegate were extracted into focused native components. The affected
  production files are below 500 physical lines with no tracking-policy change.
- Android records whether native collection was active. After a device reboot
  or unexpected native shutdown it preserves the local trip as
  `paused_by_system`, creates no new mileage, does not restart GPS, and offers a
  notification that opens Maintainiac for review or explicit resume.
- The expanded trip gate reports `TRIP_QA_PASS`; Android debug and iOS
  simulator builds pass. Focused recovery coverage proves the reboot marker
  creates one system-pause signal gap and remains idempotent.
- No production record, route point, trip session, test, or application file
  was deleted during this checkpoint.
- The connected S24 Ultra still contains an older build signed with a different
  certificate. Android correctly rejected an in-place replacement. Current
  device UI and route behavior therefore remain unverified until the owner
  explicitly authorizes uninstalling that copy or supplies a compatible signed
  build.
- The round start workflow now handles device location being unavailable
  without cancelling the workday or leaving a phantom GPS session. It explains
  that manual mileage remains available and preserves the confirmed odometer.
- Widget coverage now waits for the durable native lifecycle boundary instead
  of treating a native start callback as completion. This exposed and repaired
  an isolation defect where unrelated in-memory trip stores shared a static
  write queue; real Hive stores retain their shared serialization boundary.
- A dedicated store regression proves that a blocked write in one independent
  memory store cannot stall another store. The focused dashboard/store bundle
  passes 60 tests and the complete trip gate again reports `TRIP_QA_PASS`.
- UI-tree inspection confirms the S24 currently runs the stale July 23 build
  containing the removed Oak Street placeholder and mock advertisement. The
  installed certificate SHA-256 is
  `07514c99ae4c99945cbcab4dfb2ccf8b9658f4787dfef733a5b32a07c37fa0f3`;
  the current Mac debug build uses
  `bde55b812494eb3c0451c9011b53feda5be6fe9546f48555915c2c5f766c4189`.
  No device data was removed or changed while confirming this blocker.
- The live active-workday dashboard no longer calculates every timer tick from
  `DateTime.now()`. It establishes a restart-safe baseline from the durable
  workday record, then advances through a monotonic runtime clock so manual
  clock rollback, time-zone changes, and daylight-saving transitions cannot
  move the displayed duration backward or invent elapsed time.
- Pause and resume changes preserve one monotonic elapsed boundary. A process
  restart deliberately rebuilds from the durable wall-time record because
  platform monotonic clocks do not survive process or device restart.
- Focused elapsed-clock and dashboard wiring coverage passes eight tests,
  including wall-clock rollback, pause/resume, recovered baseline, opted-in GPS
  start, GPS-unavailable manual fallback, and confirmed stop handoff.
- Controller disposal is now serialized behind any in-flight native
  start/update. A disposal that lands while the platform start call is pending
  can no longer detach its event listener and then leave a foreground GPS
  collector running without a Dart consumer.
- The disposal/start race has a deterministic gated regression proving one
  native stop, a detached listener, a provider that is no longer running, and
  a durable `PAUSED_BY_SYSTEM` checkpoint with the
  `controller_disposed_system_pause` audit reason.
- iOS plugin teardown now calls the same complete native-stop boundary used by
  an explicit GPS stop and then detaches the Core Location delegate. Replacing
  a Flutter engine/plugin can no longer leave Core Location or Core Motion
  running after its Dart persistence owner disappears.
- All 23 native permission/lifecycle contract tests pass after that change.
  The iOS simulator debug target compiles successfully; Xcode still reports the
  pre-existing Google ML Kit arm64 simulator-support warning.
- Both native command bridges now reject a second explicit collector start with
  `trip_tracking_native_already_running`, preserving the existing collector for
  recovery instead of silently assigning it to another local session.
- Android also treats a redelivered service start as idempotent. It emits the
  current tracking status without replacing the active location callback,
  resetting the collector boundary, or creating duplicate distance.
- The new native error is recoverable, sanitized for user display, and cannot
  override the global confirmed odometer. Thirty-one focused native/error
  contract tests pass, as do targeted analysis and Android/iOS debug builds.
- Dart, Android, and iOS now enforce the same 1–100 meter native displacement
  boundary. Invalid or extreme recommendations are normalized before crossing
  the platform channel, so saved diagnostics match actual device sampling.
- Active-workday live odometer labels now listen to both the global odometer
  projection and the native tracking controller. They show the collector as
  live, starting, or paused from actual lifecycle state rather than inferring
  it from wall-clock age.
- The status color and accessibility text follow that same state. Clock jumps
  cannot falsely mark a running collector paused, and a real pause redraws
  immediately without waiting for another GPS sample or unrelated UI rebuild.
- Ending a workday from an active GPS trip can no longer bypass a dismissed
  GPS odometer review by opening a second generic ending-odometer form. The
  workday remains open and the durable completion-pending review stays
  reachable until the driver confirms or deliberately handles it.
- Android evaluates the foreground-notification Pause action before its
  duplicate-start guard. A notification tap therefore records a durable
  user-pause and retires native collection; it cannot be mistaken for a
  redelivered start request.
- Active and completion-pending records now preserve every valid GPS advisory,
  lifecycle transition audit, and permission-history entry. Long or
  interruption-heavy trips no longer silently discard older evidence at the
  serialization or recovery boundary.
- Session and completed-review regressions cover 40 advisories, 36 ordered
  transition audits, and 30 permission changes across a full map round trip.
  Existing ownership, ordering, timeline, and malformed-entry validation still
  rejects evidence that does not belong to the trip.
- Initial-fix recovery history is no longer reduced to the latest eight
  assessments. Every valid coordinate-free quality assessment now survives
  engine recovery, while malformed entries and raw coordinates remain excluded.
- Atomic session creation now removes its own durable reservation when the
  first write fails validation. A failed start cannot leave a phantom
  unfinished trip that blocks the next valid start; cleanup remains
  identity-scoped and cannot remove another session's evidence.
- Memory and Hive regressions prove a rejected start leaves no active session,
  unreadable marker, or pending write, and that the next valid start succeeds.
- Production startup now opens and injects the optional compact local
  route-point store, current trip settings, and device-local calendar key into
  the canonical tracking controller. Explicitly opted-in map-route history can
  therefore persist in the real app rather than existing only in tests.
- Failure to open optional route storage does not block GPS assistance or
  manual mileage. A non-persisting adapter returns the explicit
  `local_route_storage_unavailable` status while retaining the invariant that
  route points cannot change the confirmed odometer or upload to Firestore.
- Route-storage status changes now notify the UI immediately. When opted-in
  route history is unavailable, fails, has an invalid day boundary, or reaches
  its daily limit, GPS settings show a professional non-blocking notice that
  confirmed odometer mileage and GPS assistance continue normally.
- Withdrawing the main GPS-assisted tracking opt-in now immediately stops the
  native collector through the serialized lifecycle boundary and preserves the
  session as a user pause. It never changes confirmed mileage, cancels the
  trip, or deletes evidence.
- Restoring the opt-in does not silently restart collection. A deterministic
  regression proves repeated opt-out is idempotent and the driver must still
  explicitly start or resume GPS assistance.
- Active changes to the selected accuracy preset, adaptive sampling, battery
  protection, and withdrawals of background or motion access now pass through
  one serialized runtime-settings boundary. The native request and recoverable
  session checkpoint are updated together without changing odometer mileage.
- Enabling new background or motion access remains deferred to a separately
  authorized start. A rejected or unpersistable live update stops native
  collection into a recoverable system pause instead of continuing with an
  ambiguous configuration.
- A temporarily unavailable capability probe after process recovery cannot
  block those live reductions. The controller uses its persisted conservative
  capability baseline to apply the requested cadence and privacy settings.
- Production startup now injects a local, coordinate-free TripLog proposal
  inbox into the canonical tracking controller. Completing a trip persists one
  de-duplicated proposal per review and marks the review submitted only after
  that local handoff succeeds.
- Pending proposals from earlier launches are retried during startup. The inbox
  preserves the newest review revision, isolates malformed records, and has no
  authority to alter the global odometer or finalize a TripLog record.
- Driver odometer confirmation refreshes that coordinate-free proposal with
  the newest locally authoritative review revision. The handoff can preserve
  the user's confirmed value, but it still reports that it cannot confirm
  mileage or finalize TripLog on the user's behalf.
- A failed local TripLog handoff is now visible in the active-day GPS panel.
  The driver can retry it directly; success removes the warning, while failure
  keeps the completed review local and retryable without changing mileage.
- Startup proposal recovery now runs through the controller's guarded review
  reader. It retries every pending proposal, but an unreadable or malformed
  review store returns a controlled storage warning instead of crashing app
  startup or discarding evidence.
- GPS settings are now separated into clearly labeled Core tracking, Maps and
  route history, Battery protection, Tracking behavior and stops, Odometer
  review and calibration, and conditional Vehicle recognition sections. The
  underlying opt-ins and odometer authority are unchanged.
- Invalid, future-dated, and out-of-order GPS callbacks now persist their
  coordinate-free rejection diagnostics before returning. Those samples still
  contribute zero distance, but provider-quality evidence survives process
  death and can no longer disappear from the completed-trip audit.
- The active-day panel now evaluates the persisted signal-quality action and
  explains reduced, poor, interrupted, or unsafe GPS evidence to the driver.
  Every message keeps GPS advisory and identifies the confirmed odometer as
  official mileage.
- Unsafe provider evidence now applies the policy's recoverable system pause
  instead of merely displaying it. Native GPS stops after the rejection
  diagnostics commit, the trip remains active and reviewable, accepted
  distance stays unchanged, and the driver can explicitly resume later.
- If that diagnostic checkpoint write fails, the in-memory rejection is rolled
  back and trusted collection fails safely. A later successful local sample
  clears only this matching storage warning; unrelated storage failures remain
  visible.
- Resuming after an unsafe-signal pause now starts a fresh live collection
  quality epoch. Historical rejection diagnostics remain in the durable trip
  audit, while only samples received since the explicit resume can trigger a
  new automatic safety pause. This prevents old provider failures from
  permanently trapping a recoverable trip in an unsafe state.
- A ten-hour, 3,601-sample deterministic replay now passes through the real
  controller and session store. The recoverable checkpoint remains bounded
  instead of retaining the raw location stream, transient pending evidence is
  cleared, completion produces an unconfirmed review, and the global confirmed
  odometer remains unchanged. This is local resource evidence only; it does
  not replace a ten-hour native-device field run.
- The deterministic benchmark corpus now includes a realistic tunnel/garage
  signal-loss interval. The engine rejects the missing continuity exactly once,
  never bridges the unobserved route, resumes later accepted samples, and does
  not manufacture a stop review. This remains synthetic regression evidence,
  not a field-accuracy claim.
- A maximum bounded simulation run now replays 24,000 production-engine cases
  deterministically. Safe reports expose true-positive, false-positive, and
  false-negative stop counts directly while continuing to deny any claim of
  real-device accuracy.
- The complete dashboard GPS start, pause, resume, live-odometer, and stop flow
  now passes at 200% text scaling. Quick-action labels wrap to two lines without
  ellipses and the grid grows with the platform text scaler, eliminating the
  nine reproduced RenderFlex overflows.
- Six recorded lifecycle-fuzz seeds now exercise 720 competing native start,
  stop, app pause/resume, and heartbeat operations. Native commands remain
  serialized, one trip identity and monotonic revision history survive every
  race, and no unaccepted GPS event changes distance or the confirmed odometer.
- The app root now supervises an active native collector every 30 seconds while
  the app is foregrounded. Checks cannot overlap, stop when the app is disposed,
  and reuse the existing serialized heartbeat recovery path; background
  survival remains owned by the Android/iOS native collector rather than an
  unreliable Dart background timer. The focused heartbeat tests, app smoke
  test, analyzer, and complete trip-tracking QA gate are green.
- The post-hardening trip production scope analyzes cleanly and the current
  Android debug APK builds successfully. Installation remains intentionally
  withheld because the connected S24 contains active local records under a
  different signing certificate.
- The complete 18-state commercial lifecycle contract now has executable
  all-pairs coverage. Every one of the 324 possible transitions is checked
  against its immutable allowlist, legal transitions return normally, illegal
  transitions produce controlled errors, and safe diagnostic summaries cannot
  report a forbidden transition as accepted.
- Recovery validation now verifies every persisted transition audit against
  both the runtime and commercial contract state machines. A record claiming
  that an illegal transition was accepted, that a legal transition was
  rejected, or that runtime and contract legality disagree is quarantined
  without rewriting or deleting the source evidence.
- Transition recovery also requires strictly increasing sequence and revision
  ordering plus a continuous runtime and contract-state chain. Individually
  legal events can no longer be combined into an impossible history and
  silently presented as trustworthy audit evidence.
- The canonical controller restore path now uses that structural validation;
  it is no longer limited to checking identity, timestamps, and a broad
  lifecycle enum. Forged transition evidence is preserved in quarantine before
  it can become active recovery state.
- Local trip recovery deliberately has no fixed 18-hour expiration. A
  structurally valid four-day trip remains recoverable but paused, native GPS
  does not restart automatically, and the confirmed odometer remains
  unchanged. Future-dated and malformed checkpoints still fail closed.
- If the platform reports a running native collector but no readable local
  session can own it, startup now stops that collector instead of leaving an
  orphan service that blocks every future Start. Corrupt local evidence keeps
  its recovery diagnostic, stop/probe failures remain actionable, and the
  cleanup creates neither a trip nor mileage. Recovery re-probes the platform
  after stop: a collector that ignores stop is reported as failed, and a
  collector whose stopped state cannot be verified is reported as unverified
  instead of falsely claiming successful cleanup.
- The contractor dashboard now exposes a direct, opt-in `Start GPS` action
  alongside `Open Workday`; it uses the existing setup/permission flow and
  never bypasses user consent. A regression also closes a lifecycle race where
  a deferred unsafe-signal pause could issue a second native stop while the
  user was already ending the trip.
- A stale Firebase account panel that was no longer part of the GPS settings
  screen remained syntactically declared as a Dart `part`, causing scoped
  settings analysis to fail. It is now a preserved standalone private library;
  it remains unreachable, and GPS settings still do not own or expose Firebase
  configuration.
- Automatic-start assistance is not release-ready: the bounded detector and
  safety evaluator exist, but production has no pre-trip native observation
  source and exposes no misleading toggle. Manual start and explicit
  dashboard GPS start remain the supported workflows until background
  monitoring and false-start behavior receive an owner-approved design and
  physical-device evidence.
