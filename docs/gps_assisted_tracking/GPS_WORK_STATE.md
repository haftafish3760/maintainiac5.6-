# GPS Work State

- Current phase: 17 — deterministic replay expansion and real-device evidence
  hardening
- Current pass: 266 in the current continuation
- Current objective: harden native permission, location-service, and lifecycle
  races while preserving the real-device evidence boundary
- Relevant files: `lib/shared/trip_tracking/`, `android/app/src/main/`,
  `ios/Runner/`, `test/trip_tracking_*.dart`,
  `docs/gps_assisted_tracking/GPS_REAL_DEVICE_TEST_PROTOCOL.md`
- Previous stable checkpoint: `999be77d` (explicit Android
  background-location settings handoff)
- Latest validation result: Android and iOS native collectors now distinguish
  foreground, background, and location-service authorization loss during
  startup, active collection, recovery, motion-consent withdrawal, and adaptive
  sampling updates. Update races pause locally without deadlocking their own
  serialized event queue or accepting later queued samples. The
  21-case/21,000-run deterministic corpus, synthetic twelve-hour recovery run,
  bundled trip gate, focused analyzer, and Android debug build are green
- Unresolved blockers: real Android/iOS route, battery, lifecycle, background,
  and long-session runs remain required before any real-world accuracy claim
- Next action: continue lifecycle/recovery replay expansion, then convert
  sanitized field defects into deterministic regressions
