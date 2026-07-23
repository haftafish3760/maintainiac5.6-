# GPS Work State

- Current phase: 17 — deterministic replay expansion and real-device evidence
  hardening
- Current pass: 338 in the current continuation
- Current objective: harden native permission, location-service, and lifecycle
  races while preserving the real-device evidence boundary
- Relevant files: `lib/shared/trip_tracking/`, `android/app/src/main/`,
  `ios/Runner/`, `test/trip_tracking_*.dart`,
  `docs/gps_assisted_tracking/GPS_REAL_DEVICE_TEST_PROTOCOL.md`
- Previous stable checkpoint: `fef5ff53` (actionable native recovery causes)
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
  the native three-second request and durable recovery state. The S25 Ultra
  also completed the work-profile add/back regression without an error or app
  crash and was returned to the ready-to-track dashboard. The
  21-case/21,000-run deterministic corpus, synthetic twelve-hour recovery run,
  bundled trip gate, focused analyzer, and Android debug build are green
- Unresolved blockers: real Android/iOS route, battery, lifecycle, background,
  and long-session runs remain required before any real-world accuracy claim
- Next action: continue lifecycle/recovery replay expansion, then convert
  sanitized field defects into deterministic regressions
