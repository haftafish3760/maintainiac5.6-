# Consolidation report: Maintainiac_5.6_Receipt_OCR

- Applied: `True`
- Source remained unchanged: `true`

## Counts

- add: 10
- manual_merge: 403
- manual_review: 32
- manual_secret: 2
- skip_duplicate: 8991
- skip_generated: 1295

## Protected-feature signals

- expenses_payments: 1248
- firebase_storage: 2441
- jobs_maintenance_calendar: 530
- mapbox_dashboard_profiles: 421
- pdf_invoices_estimates: 618
- receipt_ocr_camera: 2739
- trip_tracking: 198
- work_supplies_materials: 1214

## Manual review

- `.DS_Store` — unique content requires ownership or overlap review
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
- `android/app/google-services.json` — credential-like path
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
- `android/app/src/main/kotlin/com/maintainiac/ReceiptCameraSettingsDialog.kt` — same target path has different content
- `docs/expense_release_one_blueprint.md` — same target path has different content
- `docs/firebase_sync_schema_spec.md` — same target path has different content
- `docs/firestore_data_model.md` — same target path has different content
- `docs/receipt_ocr_competitive_benchmark.md` — same target path has different content
- `docs/receipt_real_device_result_template.md` — same target path has different content
- `docs/receipt_real_device_test_script.md` — same target path has different content
- `firebase_emulator_tests/test/firestoreRules.test.mjs` — same target path has different content
- `integration_test/receipt_ocr_device_smoke_test.dart` — unique content requires ownership or overlap review
- `ios/Podfile.lock` — same target path has different content
- `ios/.symlinks/plugins/firebase_app_check` — same target path has different content
- `ios/.symlinks/plugins/firebase_auth` — same target path has different content
- `ios/.symlinks/plugins/firebase_core` — same target path has different content
- `ios/Flutter/Generated.xcconfig` — same target path has different content
- `ios/Flutter/flutter_export_environment.sh` — same target path has different content
- `ios/Runner/AppDelegate.swift` — same target path has different content
- `ios/Runner/GeneratedPluginRegistrant.m` — same target path has different content
- `ios/Runner/GoogleService-Info.plist` — credential-like path
- `ios/Runner/Info.plist` — same target path has different content
- `ios/Runner/ReceiptCameraFullScreenSettingsViewController.swift` — same target path has different content
- `ios/Runner/ReceiptCameraViewController.swift` — same target path has different content
- `ios/Runner/ReceiptCameraViewControllerCapture.swift` — same target path has different content
- `ios/Runner/ReceiptCameraViewControllerControls.swift` — same target path has different content
- `ios/Runner/ReceiptCameraViewControllerDiagnostics.swift` — same target path has different content
- `ios/Runner/ReceiptCameraViewControllerLabels.swift` — same target path has different content
- `ios/Runner/ReceiptCameraViewControllerLayout.swift` — same target path has different content
- `ios/Runner/ReceiptCameraViewControllerLiveReadability.swift` — same target path has different content
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
- `lib/screens/expenses/calendar/expense_calendar_models.dart` — same target path has different content
- `lib/screens/expenses/calendar/expense_day_summary_recap_panels.dart` — same target path has different content
- `lib/screens/expenses/calendar/expense_receipt_detail_info.dart` — same target path has different content
- `lib/screens/expenses/calendar/expense_receipt_detail_ocr_review.dart` — same target path has different content
- `lib/screens/expenses/calendar/expense_receipt_detail_screen.dart` — same target path has different content
- `lib/screens/expenses/data/expense_draft_store.dart` — same target path has different content
- `lib/screens/expenses/data/expense_export_handoff.dart` — same target path has different content
- `lib/screens/expenses/data/expense_export_models.dart` — same target path has different content
- `lib/screens/expenses/data/expense_export_store.dart` — same target path has different content
- `lib/screens/expenses/data/expense_firestore_documents.dart` — same target path has different content
- `lib/screens/expenses/data/expense_job_store.dart` — unique content requires ownership or overlap review
- `lib/screens/expenses/data/expense_ledger_models.dart` — same target path has different content
- `lib/screens/expenses/data/expense_ledger_scope_filter.dart` — unique content requires ownership or overlap review
- `lib/screens/expenses/data/expense_ledger_store.dart` — same target path has different content
- `lib/screens/expenses/data/expense_ledger_summary.dart` — same target path has different content
- `lib/screens/expenses/data/expense_line_record.dart` — same target path has different content
- `lib/screens/expenses/data/expense_line_record_serialization.dart` — same target path has different content
- `lib/screens/expenses/data/expense_receipt_classification_models.dart` — same target path has different content
- `lib/screens/expenses/data/expense_receipt_classifier.dart` — same target path has different content
- `lib/screens/expenses/data/expense_receipt_context_snapshot.dart` — unique content requires ownership or overlap review
- `lib/screens/expenses/data/expense_receipt_deletion_store.dart` — unique content requires ownership or overlap review
- `lib/screens/expenses/data/expense_receipt_draft_record.dart` — same target path has different content
- `lib/screens/expenses/data/expense_receipt_fuel_parser.dart` — same target path has different content
- `lib/screens/expenses/data/expense_receipt_fuel_quantity_logic.dart` — same target path has different content
- `lib/screens/expenses/data/expense_receipt_ocr_review.dart` — same target path has different content
- `lib/screens/expenses/data/expense_receipt_parse_result.dart` — same target path has different content
- Remaining manual items: 337 (see JSONL)

## Initial compatibility validation

- The engine identified eight target-absent artifacts for high-confidence copying.
- Changed-file analysis exposed 49 errors: the Dart additions depended on older companion models, storage APIs, and expense controllers that are not compatible with the current 5.7 baseline.
- All eight candidate copies were therefore rejected from 5.7; their originals and full decision evidence remain preserved in the read-only source and its pushed Git history.
- The source has 33 commits not reachable from 5.7, so those commits require batch history evaluation rather than isolated file copying.

## History-batch validation

- A non-committing merge trial evaluated all 33 source-only commits together while retaining the 5.7 side of textual conflicts.
- The trial changed 163 files and produced 262 analyzer issues across mutually dependent expense allocation, receipt models, storage, settings, camera guidance, and tests.
- The trial was aborted completely; none of that incompatible batch entered 5.7.
- These unique implementations remain preserved on GitHub and in the detailed manual-review evidence for later feature-level reconciliation.

## Semantic reconciliation resumed

- The whole-batch failure was not treated as proof that every source change was obsolete. The OCR history was reopened commit-by-commit against the current 5.7 contracts.
- Integrated evidence-backed merchant, date, subtotal, tax, and total candidates without adding automatic destination routing or record creation. Competing candidates, original line indexes, token indexes, bounds, confidence, and printed evidence remain available for mandatory user review.
- Integrated mixed positioned/unpositioned row ordering and token provenance while preserving 5.7's normal user-visible spacing.
- Integrated device-tier photo read timeouts, stalled-recognizer recovery, quality-prioritized photo selection, ordered long-receipt segment preservation, and coordinate-only readable-text recognition.
- Added focused candidate and photo-selection tests and extended timeout/warning tests.
- Validation: `flutter analyze` passed with no issues. The focused OCR evidence, layout, warning, source-quality, and review suite passed 39 tests.
- This is a verified semantic subset of the source history. Remaining source-only expense and OCR changes continue to require feature-level comparison; they are not considered rejected merely because the old batch trial failed.
