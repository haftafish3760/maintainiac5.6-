# GPS Trip Tracking, Trip Log, And Odometer Living Handoff

## Current Status

`CONSOLIDATED / VERIFIED SUBSET / FIELD QA PENDING`. Controller, engine, session
recovery, native lifecycle, advisory models, trip review, GPS policies,
settings, Dashboard summary, Mapbox assistance, and global odometer exist.

## Implemented Evidence

- Runtime: `lib/shared/trip_tracking/`
- Odometer: `lib/shared/odometer/` and `lib/shared/state/global_odometer.dart`
- Settings/opt-in: `lib/screens/settings/trip_tracking_settings_screen.dart`
- Dashboard integration: `lib/screens/dashboard/data/dashboard_trip_tracking_summary.dart`
- Requirements: `screen_notes/mileage_vehicle_bluetooth.txt`

## Product Boundaries

- GPS is opt-in and advisory. User-confirmed odometer/trip truth remains
  canonical. Mapbox assistance must not become silent truth.

## Verified / Remaining

- `VERIFIED CONSOLIDATION`: all 24 commits unique to the July 20 Trip Tracking
  source were reviewed in chronological capability batches and semantically
  merged or superseded. The separate July 21 trip head `a0cb57c1` is already an
  ancestor of 5.7. See `docs/consolidation_reports/Maintainiac_5.6_Trip_Tracking.md`.
- Validation recorded by checkpoint `e25ba5ba`: clean Dart/Swift checks,
  Android Kotlin compile, 195 controller tests, 64 store/recovery tests, 20
  Bluetooth/automatic-start tests, 12 native capability tests, 2 snapshot
  corruption tests, and 13 state-machine/contract tests.
- `FIELD QA PENDING`: source safeguards and targeted gates are not
  field-route, battery, lifecycle, replay, fuzzing, or commercial accuracy proof.
- Final targeted tests, platform builds, and explicitly authorized device proof
  remain required.
- `VERIFIED SUBSET`: cloud review-state application now rejects lower revisions,
  preserves genuinely newer revisions, and assigns a new local revision when a
  same-revision cloud record legitimately changes state. The full Firebase
  bridge suite passed 61 tests; the settings suite passed 5 tests, including
  the required tire-setup review before motion-activity settings continue.

## Rolling Log

- 2026-07-22: Created with the evidence boundary stated explicitly.
- 2026-07-22: Verified from Git that Trip Tracking semantic consolidation was
  completed in `e25ba5ba`; changed status from reconciliation pending to field
  QA pending.
- 2026-07-22: Repaired same-revision cloud review transitions without allowing
  stale evidence to overwrite newer local state; 66 focused tests passed.
- 2026-07-23: Product owner clarified that Start Day and all stop/fuel/expense
  day entries must stay odometer-first and manual-first. GPS and Bluetooth are
  optional assistance only; AI/OpenAI integration must attach to completed
  manual records rather than replacing them.
- 2026-07-23: Product owner clarified first-use GPS setup behavior: when GPS
  onboarding was skipped or incomplete, Start Day must still ask for the
  physical odometer first, then offer a clear opt-in setup flow. Device
  capability, battery level, charging state, and selected accuracy mode should
  drive sampling policy. Low-battery protection must be understandable and must
  not block a plugged-in, opted-in user with an arbitrary recharge gate.
