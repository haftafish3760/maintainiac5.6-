# GPS Work State

- Current phase: 15 — platform battery, capability, and recovery hardening
- Current pass: 307
- Current objective: keep Android capability reporting aligned with Fused Location system-service availability
- Relevant files: `lib/shared/trip_tracking/`, `lib/screens/dashboard/`,
  `android/app/src/main/`, `ios/Runner/`, `test/trip_tracking_*.dart`,
  `docs/gps_assisted_tracking/GPS_REAL_DEVICE_TEST_PROTOCOL.md`
- Latest stable commit: `84b510d55` (GPS replay metrics and iOS callback hardening)
- Latest validation result: Android native permission/controller regressions and Android debug build green
- Unresolved blockers: real Android/iOS route, battery, lifecycle, and long-session evidence not yet collected
- Next action: extend distance-ground-truth replay coverage, then continue Android/iOS lifecycle and acquisition hardening
