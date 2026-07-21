# GPS Work State

- Current phase: 16 — source-boundary refactoring and real-device evidence hardening
- Current pass: 1198
- Current objective: source-boundary hardening complete; replay/simulation and real-device evidence are required before further accuracy claims
- Relevant files: `lib/shared/trip_tracking/`, `android/app/src/main/`,
  `ios/Runner/`, `test/trip_tracking_*.dart`,
  `docs/gps_assisted_tracking/GPS_REAL_DEVICE_TEST_PROTOCOL.md`
- Latest stable commit: `cdde880dd` (require review cue for recovered stop)
- Latest validation result: engine (94), controller (173), and native contract
  (20) targeted regressions green; shared GPS analyzer gate green; Android
  Kotlin and generic iOS device builds green
- Unresolved blockers: the remaining reliability and accuracy evidence requires
  the intentionally deferred replay/simulation work and real Android/iOS route,
  battery, lifecycle, and long-session runs
- Next action: resume with the approved simulation/replay plan or collected
  sanitized field runs; do not claim real-world accuracy before then
