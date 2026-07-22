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

## Explicit allocation reconciliation

- Compared source commits `7b053a05b` and `27694e9d1` against the newer 5.7
  split-allocation model and receipt evidence boundaries.
- Removed the remaining silent 50/50 ownership default from the full line
  editor, mixed-receipt guidance, and no-line recovery label. A split line now
  requires an explicit 0-to-100 business allocation before the editor saves.
- Existing dollar-amount or quantity allocation methods are preserved when the
  displayed equivalent percentage is not changed; an edited percentage becomes
  an explicit percentage allocation instead of silently losing user intent.
- The source's direct replacement of a parsed description with raw evidence was
  not copied. Current 5.7 already uses `receiptDisplayText` while retaining raw,
  source, normalized, interpretation, and OCR provenance separately.
- The source's Basic/Quick/Detailed visibility changes were not applied in this
  checkpoint because they are a product-flow choice rather than a duplicate or
  ownership correction.
- Validation: `flutter analyze` passed. The corrected split-allocation, line
  record, parser allocation, and receipt save-guardrail batch passed 26 tests.

## Evidence and capture handoff reconciliation

- Compared source commits `7c6f3acdd`, `e5facada2`, `c946098cb`, `b7671a3b2`,
  `e3d319cf8`, `c79cae9fd`, `e2ddfa5ea`, and `5f1392d04` file-by-file against
  current 5.7.
- Current 5.7 already keeps source fragments, tab-delimited source evidence,
  natural user-visible spacing, normalized text, token references, bounds,
  confidence, and interpretations as separate fields. The older source change
  that displayed tabs to users was not copied.
- Current 5.7 already uses the structured `onReceiptOcrResultForReview`
  callback, with the legacy text callback only as fallback. This supersedes the
  source's older `onReceiptOcrReadyForReview` contract.
- Crop loading/recovery, full-screen iOS capture settings, runtime settings
  notes, single-photo handoff, Use Receipt flow, native evidence handoff, and
  OCR candidate fallback are present in their newer 5.7 forms. Three absent
  source contract-test filenames were not copied because current tests cover
  the renamed/newer owners and behavior.
- Validation: the OCR layout/candidates, editable handoff, capture order,
  review controls, and iOS settings batch passed 33 tests.

## OCR benchmark reconciliation

- Compared source commits `3137cc972`, `6e250dd81`, `ee09f08db`, `78d78ebb1`,
  and the benchmark portion of `8ea7fd15f`.
- Current 5.7 already has the separate OCR accuracy metrics, privacy-safe
  provenance checks, labeled fixture, scenario coverage, minimum real-case
  counts, synthetic-only release rejection, and photo quality selection. Its
  runner is a refactored newer equivalent and retains the source release gates.
- The sample benchmark scored all populated metrics at 1.0 but deliberately
  does not satisfy the real-evidence release gate. No accuracy or release claim
  is made from the sample.
- Validation: benchmark metrics, runner, provenance, release-gate, and photo
  selection tests passed 7 tests.

## Recovery, classification, and ownership reconciliation

- Compared source commits `92c14ffa0`, `866441ead`, `33624ceb4`, `7e62cc1e6`,
  `7d75e5f05`, and `ca3c29504` against current 5.7.
- Source labels, token evidence, stalled-read recovery, draft OCR metadata,
  warning classification, saved-photo diagnostics, PDF safety, and recovery
  copy already exist in newer 5.7 owners.
- The source-only `ReceiptOcrDocumentClassification` was not copied because 5.7
  has the richer `ExpenseReceiptClassification` model and visible review panel,
  covering fuel, materials, maintenance, repair, phone, job documents, other
  documents, ambiguous, unsupported, and not-receipt suggestions.
- The source's automatic `routePlan`/`dispatchPlan` behavior was deliberately
  not copied. It could run Fuel and Inventory consumers based on OCR evidence
  before user ownership. Current 5.7 correctly keeps OCR classification as a
  suggestion and routes a dedicated consumer only from the user's selected
  category or explicit inventory request.
- No source ownership-boundary test file was copied because current handoff
  tests directly prove that OCR infers no domain when the user selected none,
  and that dedicated consumers receive unchanged evidence only after selection.
- Validation: classification, explicit-route handoff, reusable QA, OCR warning/
  source recovery, native warning, and durable draft tests passed 51 tests.
