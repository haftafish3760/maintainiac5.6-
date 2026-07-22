# Consolidation report: Maintainiac_5.6_Long_Receipt

- Applied: `True`
- Source remained unchanged: `true`

## Counts

- add: 1
- manual_merge: 452
- manual_review: 4
- manual_text_difference: 2
- skip_duplicate: 6189
- skip_generated: 749

## Protected-feature signals

- expenses_payments: 1201
- firebase_storage: 1857
- jobs_maintenance_calendar: 511
- mapbox_dashboard_profiles: 376
- pdf_invoices_estimates: 613
- receipt_ocr_camera: 2641
- trip_tracking: 198
- work_supplies_materials: 1196

## Manual review

- `.flutter-plugins-dependencies` — same target path has different content
- `.gitignore` — same target path has different content
- `firebase.json` — same target path has different content
- `firestore.indexes.json` — same target path has different content
- `firestore.rules` — same target path has different content
- `pubspec.lock` — same target path has different content
- `pubspec.yaml` — same target path has different content
- `storage.rules` — same target path has different content
- `android/build.gradle.kts` — same target path has different content
- `android/app/build.gradle.kts` — same target path has different content
- `android/app/src/main/AndroidManifest.xml` — same target path has different content
- `android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java` — same target path has different content
- `android/app/src/main/kotlin/com/maintainiac/MainActivity.kt` — same target path has different content
- `android/app/src/main/kotlin/com/maintainiac/ReceiptCameraActivity.kt` — same target path has different content
- `android/app/src/main/kotlin/com/maintainiac/ReceiptCameraAnalysis.kt` — same target path has different content
- `android/app/src/main/kotlin/com/maintainiac/ReceiptCameraCaptureClose.kt` — same target path has different content
- `android/app/src/main/kotlin/com/maintainiac/ReceiptCameraControls.kt` — same target path has different content
- `android/app/src/main/kotlin/com/maintainiac/ReceiptCameraDiagnosticsLabels.kt` — same target path has different content
- `android/app/src/main/kotlin/com/maintainiac/ReceiptCameraDiagnosticsPayload.kt` — same target path has different content
- `android/app/src/main/kotlin/com/maintainiac/ReceiptCameraLiveReadabilitySignals.kt` — same target path has different content
- `android/app/src/main/kotlin/com/maintainiac/ReceiptCameraPhotoQuality.kt` — same target path has different content
- `android/app/src/main/kotlin/com/maintainiac/ReceiptCameraPreCaptureExposure.kt` — same target path has different content
- `android/app/src/main/kotlin/com/maintainiac/ReceiptCameraPreviousSectionGuide.kt` — same target path has different content
- `android/app/src/main/kotlin/com/maintainiac/ReceiptCameraSettingsDialog.kt` — same target path has different content
- `docs/expense_release_one_blueprint.md` — same target path has different content
- `docs/firebase_sync_schema_spec.md` — same target path has different content
- `docs/firestore_data_model.md` — same target path has different content
- `docs/receipt_bug_regression_ledger.md` — same target path has different content
- `docs/receipt_camera_completion_map.md` — same target path has different content
- `docs/receipt_camera_ocr_master_pass_plan.md` — same target path has different content
- `docs/receipt_camera_release_one_blueprint.md` — same target path has different content
- `docs/receipt_camera_roadmap.md` — same target path has different content
- `docs/receipt_real_device_result_template.md` — same target path has different content
- `docs/receipt_real_device_test_script.md` — same target path has different content
- `firebase_emulator_tests/test/firestoreRules.test.mjs` — same target path has different content
- `ios/Podfile.lock` — same target path has different content
- `ios/Flutter/Generated.xcconfig` — same target path has different content
- `ios/Flutter/flutter_export_environment.sh` — same target path has different content
- `ios/Runner/AppDelegate.swift` — same target path has different content
- `ios/Runner/GeneratedPluginRegistrant.m` — same target path has different content
- `ios/Runner/Info.plist` — same target path has different content
- `ios/Runner/ReceiptCameraFullScreenSettingsViewController.swift` — same target path has different content
- `ios/Runner/ReceiptCameraViewController.swift` — same target path has different content
- `ios/Runner/ReceiptCameraViewControllerCapture.swift` — same target path has different content
- `ios/Runner/ReceiptCameraViewControllerDiagnostics.swift` — same target path has different content
- `ios/Runner/ReceiptCameraViewControllerLabels.swift` — same target path has different content
- `ios/Runner/ReceiptCameraViewControllerLayout.swift` — same target path has different content
- `ios/Runner/ReceiptCameraViewControllerLiveReadability.swift` — same target path has different content
- `ios/Runner/ReceiptCameraViewControllerPreviousSectionGuide.swift` — same target path has different content
- `ios/Runner/ReceiptCameraViewControllerSessionSettings.swift` — same target path has different content
- `ios/Runner/ReceiptCameraViewControllerSettingsCopy.swift` — same target path has different content
- `ios/Runner.xcodeproj/project.pbxproj` — same target path has different content
- `lib/main.dart` — same target path has different content
- `lib/app/incoming_receipt_destination_screen.dart` — same target path has different content
- `lib/app/incoming_receipt_destination_widgets.dart` — same target path has different content
- `lib/app/maintaniac_app.dart` — same target path has different content
- `lib/screens/dashboard/active_workday_actions.dart` — same target path has different content
- `lib/screens/dashboard/active_workday_context_bar.dart` — same target path has different content
- `lib/screens/dashboard/active_workday_quick_action_editor.dart` — same target path has different content
- `lib/screens/dashboard/active_workday_screen.dart` — same target path has different content
- `lib/screens/dashboard/dashboard.dart` — same target path has different content
- `lib/screens/dashboard/dashboard_panels.dart` — same target path has different content
- `lib/screens/dashboard/vehicle_profile_detail.dart` — same target path has different content
- `lib/screens/dashboard/vehicle_profile_flow.dart` — same target path has different content
- `lib/screens/dashboard/vehicle_profile_widgets.dart` — same target path has different content
- `lib/screens/dashboard/contractor/contractor_dashboard_models.dart` — same target path has different content
- `lib/screens/dashboard/contractor/contractor_dashboard_screen.dart` — same target path has different content
- `lib/screens/dashboard/contractor/contractor_dashboard_sections.dart` — same target path has different content
- `lib/screens/dashboard/contractor/contractor_dashboard_tiles.dart` — same target path has different content
- `lib/screens/dashboard/data/active_workday_store.dart` — same target path has different content
- `lib/screens/expenses/calendar/expense_calendar.dart` — same target path has different content
- `lib/screens/expenses/calendar/expense_calendar_actions.dart` — same target path has different content
- `lib/screens/expenses/calendar/expense_receipt_detail_screen.dart` — same target path has different content
- `lib/screens/expenses/data/expense_draft_store.dart` — same target path has different content
- `lib/screens/expenses/data/expense_export_handoff.dart` — same target path has different content
- `lib/screens/expenses/data/expense_export_store.dart` — same target path has different content
- `lib/screens/expenses/data/expense_firestore_documents.dart` — same target path has different content
- `lib/screens/expenses/data/expense_ledger_models.dart` — same target path has different content
- `lib/screens/expenses/data/expense_ledger_store.dart` — same target path has different content
- `lib/screens/expenses/data/expense_ledger_summary.dart` — same target path has different content
- `lib/screens/expenses/data/expense_line_record.dart` — same target path has different content
- `lib/screens/expenses/data/expense_line_record_serialization.dart` — same target path has different content
- `lib/screens/expenses/data/expense_receipt_classification_models.dart` — same target path has different content
- `lib/screens/expenses/data/expense_receipt_classifier.dart` — same target path has different content
- `lib/screens/expenses/data/expense_receipt_draft_record.dart` — same target path has different content
- `lib/screens/expenses/data/expense_receipt_fuel_parser.dart` — same target path has different content
- `lib/screens/expenses/data/expense_receipt_fuel_quantity_logic.dart` — same target path has different content
- `lib/screens/expenses/data/expense_receipt_parser.dart` — same target path has different content
- `lib/screens/expenses/data/expense_receipt_parser_category_match_logic.dart` — same target path has different content
- `lib/screens/expenses/data/expense_receipt_parser_description_cleanup_logic.dart` — same target path has different content
- `lib/screens/expenses/data/expense_receipt_parser_line_item_logic.dart` — same target path has different content
- `lib/screens/expenses/data/expense_receipt_parser_support_models.dart` — same target path has different content
- `lib/screens/expenses/data/expense_receipt_parser_text_entry_logic.dart` — same target path has different content
- `lib/screens/expenses/data/expense_receipt_privacy_event_store_hive.dart` — same target path has different content
- `lib/screens/expenses/data/expense_receipt_record.dart` — same target path has different content
- `lib/screens/expenses/data/expense_receipt_record_computed_fields.dart` — same target path has different content
- `lib/screens/expenses/data/expense_receipt_record_serialization.dart` — same target path has different content
- `lib/screens/expenses/data/expense_screen_telemetry_recorder.dart` — same target path has different content
- `lib/screens/expenses/data/fuel_economy_helpers.dart` — same target path has different content
- `lib/screens/expenses/data/fuel_economy_metrics.dart` — same target path has different content
- Remaining manual items: 358 (see JSONL)

## Migration and validation outcome

- Added: `docs/long_receipt_stitching_cross_platform_handoff_2026_07_15.md`.
- Broad Git merge preflight identified 36 overlapping paths.
- A preservation-biased merge was rejected after targeted analysis reported 323 issues; the merge was aborted cleanly.
- Four target-absent tests analyzed without diagnostics but failed their 5.7 runtime contracts because required older companion implementations were intentionally not imported.
- Those four candidate copies were rejected; their originals remain in the read-only source and its GitHub branch.
- No source repository content was modified.
