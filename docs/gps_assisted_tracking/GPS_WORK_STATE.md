# GPS Work State

- Current phase: 16 — platform event isolation and real-device evidence hardening
- Current pass: 451
- Current objective: isolate delayed native provider callbacks across Android and iOS trip-session boundaries
- Relevant files: `lib/shared/trip_tracking/`, `lib/screens/dashboard/`,
  `android/app/src/main/`, `ios/Runner/`, `test/trip_tracking_*.dart`,
  `docs/gps_assisted_tracking/GPS_REAL_DEVICE_TEST_PROTOCOL.md`
- Latest stable commit: `9674fae8d` (retired Android location callback isolation)
- Latest validation result: native callback contract green; Android Kotlin and unsigned iOS device builds green
- Unresolved blockers: real Android/iOS route, battery, lifecycle, and long-session evidence not yet collected
- Next action: continue cross-platform lifecycle and acquisition hardening; collect authorized physical-device evidence
