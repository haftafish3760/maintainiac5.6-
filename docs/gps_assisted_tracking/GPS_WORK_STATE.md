# GPS Work State

- Current phase: 16 — platform event isolation and real-device evidence hardening
- Current pass: 458
- Current objective: fail closed when legacy recovery cannot prove motion-sensor withdrawal
- Relevant files: `lib/shared/trip_tracking/`, `lib/screens/dashboard/`,
  `android/app/src/main/`, `ios/Runner/`, `test/trip_tracking_*.dart`,
  `docs/gps_assisted_tracking/GPS_REAL_DEVICE_TEST_PROTOCOL.md`
- Latest stable commit: `994e2ff29` (recovered sampling limits)
- Latest validation result: targeted legacy motion-withdrawal regression and affected static analysis green
- Unresolved blockers: real Android/iOS route, battery, lifecycle, and long-session evidence not yet collected
- Next action: continue cross-platform lifecycle and acquisition hardening; collect authorized physical-device evidence
