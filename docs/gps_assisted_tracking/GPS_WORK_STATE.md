# GPS Work State

- Current phase: 15 — platform battery, capability, and recovery hardening
- Current pass: 285
- Current objective: make Android fused GPS recovery safe across delayed callbacks and foreground-service restart without weakening local-first review controls
- Relevant files: `lib/shared/trip_tracking/`, `lib/screens/dashboard/`,
  `android/app/src/main/`, `ios/Runner/`, `test/trip_tracking_*.dart`,
  `docs/gps_assisted_tracking/GPS_REAL_DEVICE_TEST_PROTOCOL.md`
- Latest stable commit: `efd091bbd` (dashboard live-health visibility and Android fused location acquisition)
- Latest validation result: active-workday GPS/odometer widget and contract tests, native permission contract, controller regression suite, focused static analysis, and Android debug build green
- Unresolved blockers: real Android/iOS route, battery, lifecycle, and long-session evidence not yet collected
- Next action: verify Android fused-acquisition lifecycle behavior with authorized real-device evidence; continue hardening iOS-supported recovery and dashboard health handling while keeping calibration acceptance fail-neutral until persistence is deliberately designed
