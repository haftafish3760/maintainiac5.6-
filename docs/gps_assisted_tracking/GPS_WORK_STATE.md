# GPS Work State

- Current phase: 16 — platform event isolation and real-device evidence hardening
- Current pass: 386
- Current objective: prevent delayed native motion callbacks and first-fix startup races across Android and iOS
- Relevant files: `lib/shared/trip_tracking/`, `lib/screens/dashboard/`,
  `android/app/src/main/`, `ios/Runner/`, `test/trip_tracking_*.dart`,
  `docs/gps_assisted_tracking/GPS_REAL_DEVICE_TEST_PROTOCOL.md`
- Latest stable commit: `843ea421a` (Android GPS permission revocation)
- Latest validation result: native contract test, Android Kotlin compilation, and unsigned iOS device build green
- Unresolved blockers: real Android/iOS route, battery, lifecycle, and long-session evidence not yet collected
- Next action: continue Android/iOS lifecycle and acquisition hardening; collect authorized physical-device evidence
