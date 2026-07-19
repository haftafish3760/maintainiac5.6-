# GPS Work State

- Current phase: 15 — platform battery, capability, and recovery hardening
- Current pass: 321
- Current objective: detect Android precise-location revocation while the native foreground collector remains alive
- Relevant files: `lib/shared/trip_tracking/`, `lib/screens/dashboard/`,
  `android/app/src/main/`, `ios/Runner/`, `test/trip_tracking_*.dart`,
  `docs/gps_assisted_tracking/GPS_REAL_DEVICE_TEST_PROTOCOL.md`
- Latest stable commit: `2b10b3801` (commercial GPS acceleration replay)
- Latest validation result: Android native permission/controller regressions and Android debug build green
- Unresolved blockers: real Android/iOS route, battery, lifecycle, and long-session evidence not yet collected
- Next action: continue Android/iOS lifecycle and acquisition hardening
