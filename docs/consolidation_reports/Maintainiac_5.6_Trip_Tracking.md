# Consolidation report: Maintainiac_5.6_Trip_Tracking

- Applied: `True`
- Source remained unchanged: `true`

## Counts

- add: 2
- manual_merge: 144
- manual_review: 31
- skip_duplicate: 3961
- skip_generated: 152

## Protected-feature signals

- expenses_payments: 1325
- firebase_storage: 1467
- jobs_maintenance_calendar: 560
- mapbox_dashboard_profiles: 718
- pdf_invoices_estimates: 712
- receipt_ocr_camera: 2681
- trip_tracking: 555
- work_supplies_materials: 1342

## Manual review

- `.flutter-plugins-dependencies` — same target path has different content
- `android/app/src/main/kotlin/com/maintainiac/DeviceCapabilityBridge.kt` — same target path has different content
- `android/app/src/main/kotlin/com/maintainiac/TripTrackingActivityReceiver.kt` — same target path has different content
- `android/app/src/main/kotlin/com/maintainiac/TripTrackingNativeBridge.kt` — same target path has different content
- `docs/expense_release_one_blueprint.md` — same target path has different content
- `docs/receipt_real_device_test_script.md` — same target path has different content
- `docs/gps_assisted_tracking/GPS_WORK_STATE.md` — same target path has different content
- `ios/Podfile.lock` — same target path has different content
- `ios/Flutter/Generated.xcconfig` — same target path has different content
- `ios/Flutter/flutter_export_environment.sh` — same target path has different content
- `ios/Runner/DeviceCapabilityBridge.swift` — same target path has different content
- `ios/Runner/TripTrackingNativeBridge.swift` — same target path has different content
- `lib/main.dart` — same target path has different content
- `lib/screens/dashboard/vehicle_profile_detail.dart` — same target path has different content
- `lib/screens/dashboard/vehicle_profile_flow.dart` — same target path has different content
- `lib/screens/dashboard/vehicle_profile_widgets.dart` — same target path has different content
- `lib/screens/dashboard/vehicle_tire_configuration_selector.dart` — unique content requires ownership or overlap review
- `lib/screens/dashboard/vehicle_tire_setup_prompt.dart` — unique content requires ownership or overlap review
- `lib/screens/expenses/calendar/expense_calendar.dart` — same target path has different content
- `lib/screens/expenses/calendar/expense_calendar_actions.dart` — same target path has different content
- `lib/screens/expenses/calendar/expense_receipt_detail_screen.dart` — same target path has different content
- `lib/screens/expenses/data/expense_ledger_summary.dart` — same target path has different content
- `lib/screens/expenses/data/expense_receipt_record.dart` — same target path has different content
- `lib/screens/expenses/data/expense_receipt_record_serialization.dart` — same target path has different content
- `lib/screens/expenses/entry/expense_receipt_category_picker.dart` — same target path has different content
- `lib/screens/expenses/entry/expense_receipt_category_picker_widgets.dart` — same target path has different content
- `lib/screens/expenses/entry/expense_receipt_entry_core_helpers.dart` — same target path has different content
- `lib/screens/expenses/entry/expense_receipt_line_editor_derived_fields.dart` — same target path has different content
- `lib/screens/expenses/home/expenses_home_period.dart` — same target path has different content
- `lib/screens/expenses/reports/expense_recap_models.dart` — same target path has different content
- `lib/screens/expenses/settings/expense_settings_switch_panels.dart` — same target path has different content
- `lib/screens/maintenance/maintenance_item_detail_calculations.dart` — same target path has different content
- `lib/screens/maintenance/maintenance_item_detail_screen.dart` — same target path has different content
- `lib/screens/maintenance/maintenance_log_service_screen.dart` — same target path has different content
- `lib/screens/settings/trip_tracking_settings_screen.dart` — same target path has different content
- `lib/screens/work_supplies/data/work_supply_parsed_receipt_bridge.dart` — same target path has different content
- `lib/screens/work_supplies/data/work_supply_receipt_parser.dart` — same target path has different content
- `lib/screens/work_supplies/data/work_supply_receipt_parser_trade_scores_landscaping.dart` — same target path has different content
- `lib/screens/work_supplies/data/work_supply_receipt_parser_trade_scores_masonry_concrete.dart` — same target path has different content
- `lib/screens/work_supplies/data/inventory_parsers/plumbing/plumbing_receipt_precedence_parser.dart` — same target path has different content
- `lib/shared/device_capabilities/device_capabilities.dart` — same target path has different content
- `lib/shared/device_capabilities/device_capability_service.dart` — same target path has different content
- `lib/shared/odometer/odometer_correction_review.dart` — same target path has different content
- `lib/shared/odometer/odometer_entry_sheet.dart` — same target path has different content
- `lib/shared/odometer/odometer_review_dialogs.dart` — same target path has different content
- `lib/shared/state/app_state.dart` — same target path has different content
- `lib/shared/state/global_odometer.dart` — same target path has different content
- `lib/shared/trip_tracking/trip_active_day_timer_policy.dart` — same target path has different content
- `lib/shared/trip_tracking/trip_battery_gps_continuation_policy.dart` — same target path has different content
- `lib/shared/trip_tracking/trip_initial_fix_classifier.dart` — same target path has different content
- `lib/shared/trip_tracking/trip_lifecycle_supervisor_policy.dart` — same target path has different content
- `lib/shared/trip_tracking/trip_live_checkpoint_durability_policy.dart` — same target path has different content
- `lib/shared/trip_tracking/trip_native_event_lifecycle_policy.dart` — same target path has different content
- `lib/shared/trip_tracking/trip_recovery_resume_policy.dart` — same target path has different content
- `lib/shared/trip_tracking/trip_route_history_models.dart` — unique content requires ownership or overlap review
- `lib/shared/trip_tracking/trip_route_history_store.dart` — unique content requires ownership or overlap review
- `lib/shared/trip_tracking/trip_start_detection_assistant.dart` — unique content requires ownership or overlap review
- `lib/shared/trip_tracking/trip_tracking_backup_port.dart` — unique content requires ownership or overlap review
- `lib/shared/trip_tracking/trip_tracking_bluetooth.dart` — same target path has different content
- `lib/shared/trip_tracking/trip_tracking_cancelled_session.dart` — unique content requires ownership or overlap review
- `lib/shared/trip_tracking/trip_tracking_command_policy.dart` — same target path has different content
- `lib/shared/trip_tracking/trip_tracking_controller.dart` — same target path has different content
- `lib/shared/trip_tracking/trip_tracking_daily_bundle_bridge.dart` — unique content requires ownership or overlap review
- `lib/shared/trip_tracking/trip_tracking_device_operational_policy.dart` — same target path has different content
- `lib/shared/trip_tracking/trip_tracking_durable_record_bridge.dart` — same target path has different content
- `lib/shared/trip_tracking/trip_tracking_engine.dart` — same target path has different content
- `lib/shared/trip_tracking/trip_tracking_firebase_bridge.dart` — same target path has different content
- `lib/shared/trip_tracking/trip_tracking_heartbeat_watchdog_policy.dart` — same target path has different content
- `lib/shared/trip_tracking/trip_tracking_lifecycle_event.dart` — unique content requires ownership or overlap review
- `lib/shared/trip_tracking/trip_tracking_models.dart` — same target path has different content
- `lib/shared/trip_tracking/trip_tracking_odometer_calibration.dart` — same target path has different content
- `lib/shared/trip_tracking/trip_tracking_odometer_reconciliation.dart` — same target path has different content
- `lib/shared/trip_tracking/trip_tracking_odometer_usage_anomaly.dart` — same target path has different content
- `lib/shared/trip_tracking/trip_tracking_platform.dart` — same target path has different content
- `lib/shared/trip_tracking/trip_tracking_policy.dart` — same target path has different content
- `lib/shared/trip_tracking/trip_tracking_profile_strategy.dart` — same target path has different content
- `lib/shared/trip_tracking/trip_tracking_quarantined_session.dart` — unique content requires ownership or overlap review
- `lib/shared/trip_tracking/trip_tracking_recovery_diagnostic.dart` — unique content requires ownership or overlap review
- `lib/shared/trip_tracking/trip_tracking_recovery_policy.dart` — same target path has different content
- `lib/shared/trip_tracking/trip_tracking_session_recovery_validation.dart` — same target path has different content
- `lib/shared/trip_tracking/trip_tracking_session_snapshot.dart` — unique content requires ownership or overlap review
- `lib/shared/trip_tracking/trip_tracking_session_store.dart` — same target path has different content
- `lib/shared/trip_tracking/trip_tracking_settings_store.dart` — same target path has different content
- `lib/shared/trip_tracking/trip_tracking_state_machine.dart` — same target path has different content
- `lib/shared/trip_tracking/trip_tracking_user_event.dart` — unique content requires ownership or overlap review
- `lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart` — same target path has different content
- `lib/shared/widgets/receipt_capture/receipt_attachment_review_read_actions.dart` — same target path has different content
- `lib/shared/widgets/receipt_capture/receipt_photo_review_build.dart` — same target path has different content
- `lib/shared/widgets/receipt_capture/receipt_photo_review_common_controls.dart` — same target path has different content
- `lib/shared/widgets/receipt_capture/receipt_photo_review_image_edit_actions.dart` — same target path has different content
- `lib/shared/widgets/receipt_capture/receipt_photo_review_order_actions.dart` — same target path has different content
- `lib/shared/widgets/receipt_capture/receipt_photo_review_photo_surface.dart` — same target path has different content
- `lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart` — same target path has different content
- `lib/shared/widgets/receipt_capture/receipt_photo_review_preview_primary_row.dart` — same target path has different content
- `lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart` — same target path has different content
- `lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart` — same target path has different content
- `lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart` — same target path has different content
- `lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar_buttons.dart` — same target path has different content
- `lib/shared/widgets/receipt_capture/receipt_photo_review_ui_config.dart` — same target path has different content
- `screen_notes/expenses_receipts.txt` — same target path has different content
- Remaining manual items: 75 (see JSONL)

## Initial compatibility validation

- Two target-absent Dart files were evaluated.
- `trip_tracking_gps_opt_in_flow.dart` was rejected because it requires an older vehicle tire-configuration API absent from 5.7.
- `trip_tracking_bluetooth_coordinator.dart` analyzed cleanly, but its coordinator behavior has already been superseded by the newer controller-owned implementation and stronger tests in 5.7; adding it would duplicate code and ownership.
- Both candidate copies were removed from 5.7. Their source versions remain untouched and preserved on GitHub.
- The source has 24 commits not reachable from 5.7, requiring batch history evaluation.

## History-batch validation

- A non-committing merge trial evaluated all 24 source-only commits together while retaining the 5.7 side of textual conflicts.
- The trial changed 87 files. One auto-merged test was syntactically invalid; after restoring that test to 5.7, changed-file analysis still reported 731 issues across incompatible lifecycle enums, session/review schemas, dashboard wiring, and tests.
- The trial was aborted completely; none of the incompatible batch entered 5.7.
- The unique source history remains preserved on GitHub and indexed for later feature-level reconciliation.

## Semantic reconciliation completed — 2026-07-22

The incompatible bulk merge described above was not used. All 24 commits unique
to `codex/gps-assisted-trip-commercial-20260720` were reviewed in chronological
capability batches against the newer 5.7 architecture. The source worktree and
branch remained read-only and clean.

The repository's separate `codex/gps-assisted-trip-commercial-20260721` head
(`a0cb57c1`) is already an ancestor of 5.7. Its later runtime checkpoint,
completion-review, TripLog revision, ingestion serialization, cancellation
retry, GPS hardening, and receipt-review changes were therefore retained as the
baseline rather than re-imported as duplicates.

### Added or semantically merged

- Odometer rollover and unit-change audit safeguards.
- Tire calibration context, vehicle-configuration isolation, and bound
  vehicle/profile recovery context.
- GPS opt-in tire-setup guidance and trip-start time-zone context.
- Stop-advisory ancestry, reviewed-trip local-day bundles, and driver-confirmed
  pickup/drop-off/manual events using the existing canonical event model.
- Rejected-distance and estimated-gap diagnostics without allowing GPS to
  become official mileage truth.
- Private route write serialization, explicit confirmed route deletion, and
  mid-trip map-consent revocation while GPS mileage continues.
- Idempotent corrupt-checkpoint diagnostics and lossless quarantine of unsafe
  or terminal recovery evidence.
- iOS monotonic location ordering plus mocked, malformed-motion, and
  pre-session initial-fix rejection.
- Native Bluetooth capability reporting and serialized, user-approved linked
  vehicle coordination, while retaining the newer 5.7 automatic-start detector
  and Bluetooth link model.
- Checksummed, generation-ordered active-session recovery across active,
  pending, and previous slots, including corruption fallback diagnostics.
- Exhaustive current-state lifecycle transition matrix coverage.
- A Firebase-neutral trip backup port while retaining the fuller consent-bound,
  reviewed-mileage Firebase mirror and the module-neutral durable record bridge.

### Intentionally not duplicated or overwritten

- The older parallel lifecycle enum, cancelled-session record,
  lifecycle-event class, route-history store, initial-fix classifier,
  assisted-start detector, and Bluetooth link model were not copied. Their
  unique behavior was merged into the newer canonical 5.7 models instead.
- Older schema-boundary and pause/cancellation implementations were superseded
  by 5.7's revisioned reviews, transition audits, operation serialization,
  completion crash recovery, and quarantine path.
- The final deletion-only dashboard Firebase wiring change was not applied.
  The privacy-safe dashboard snapshot, durable reviewed-trip bundle, and
  Firebase mirror are complementary boundaries; removing one would discard
  capability rather than remove duplicate code.

### Validation

- Dart formatting and changed-file analysis: clean.
- Swift native bridge parse: passed.
- Android `:app:compileDebugKotlin`: passed after restoring the missing receipt
  photo-quality executor exposed by the build.
- Trip controller suite: 195 passed.
- Store/recovery suite: 64 passed.
- Bluetooth/automatic-start suite: 20 passed.
- Native capability boundary suite: 12 passed.
- Snapshot corruption/interrupted-write suite: 2 passed.
- State-machine and contract suite: 13 passed.
- Firebase trip-backup tests and the controller suite passed when run in their
  isolated test groups.
