# GPS Work State

- Current phase: 17 — deterministic replay expansion and real-device evidence
  hardening
- Current pass: 436 in the current continuation
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
- The complete 1,800-plus-test trip-domain gate, Android debug build, and
  generic iOS no-codesign build pass after these changes. The current Android
  build is installed and resumed on the S25 Ultra without a Maintainiac crash
- Unresolved blockers: real Android/iOS route, battery, lifecycle, background,
  and long-session runs remain required before any real-world accuracy claim
- Next action: continue lifecycle/recovery replay expansion, then convert
  sanitized field defects into deterministic regressions
