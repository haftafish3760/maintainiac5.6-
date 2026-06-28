# Receipt Camera Parallel Work Boundary

Last updated: 2026-06-28

This file tells any other Codex thread/model what this thread is actively
working on and what it must not touch. Read this before editing Maintainiac
receipt, expense, OCR, parser, camera, or Command 1 telemetry code.

## Active Owner

This thread owns the Maintainiac receipt camera and receipt OCR flow in:

- `/Users/rbbie/Documents/Maintainiac_5.6`
- `/Users/rbbie/Documents/Comand 1` for Command 1 admin telemetry surfaces only

Do not edit `/Users/rbbie/Documents/Maintainiac_5.5`. The user has explicitly
made 5.5 off-limits.

## Current Goal

Build a state-of-the-art receipt capture system for Maintainiac:

- native Maintainiac-owned camera flow
- Android CameraX backend
- iOS AVFoundation backend
- no generic Samsung camera UI as the product experience
- receipt-focused camera controls
- tap-to-focus
- pinch-to-zoom
- exposure/brightness control
- manual shutter always works
- optional automatic capture only when safe
- long receipt multi-photo workflow
- overlap/ghost guide for the next receipt section
- image review before accepting
- accepted photo recovery/local staging
- OCR uses the original/clearest source image first
- compressed backup copies are made after OCR/image review
- filled receipt review follows accepted photos
- business / personal / mixed receipt review
- price-only mode and detailed-line mode
- privacy-safe telemetry for Command 1

## Design Standards Being Targeted

Maintainiac should combine:

- Adobe Scan style image cleanup: crop, straighten, grayscale, contrast,
  shadow cleanup, document-style receipt clarity.
- Microsoft Lens style camera experience: fast, low-clutter, receipt framing
  guidance, tap-and-go, no user confusion.
- Expensify style receipt intelligence: merchant/date/tax/total/line parsing
  and correction tracking.
- Genius Scan style long receipt handling: multiple photos, readable overlap,
  add-next-section without annoying the user.
- Maintainiac-specific logic: business, personal, mixed, split percentages,
  vehicle/profile awareness, local-first storage, and privacy-safe diagnostics.

## Files This Thread Is Actively Touching

Other threads should not edit these unless the user explicitly transfers
ownership.

### Receipt Capture / Camera

- `lib/shared/widgets/receipt_capture/receipt_capture.dart`
- `lib/shared/widgets/receipt_capture/receipt_capture_models.dart`
- `lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart`
- `lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart`
- `lib/shared/widgets/receipt_capture/receipt_native_camera_shell.dart`
- `lib/shared/widgets/receipt_capture/receipt_native_capture_recovery_store.dart`
- `lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart`
- `lib/shared/widgets/receipt_capture/receipt_image_picker.dart`
- `lib/shared/widgets/receipt_capture/receipt_image_processor.dart`
- `lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart`
- `lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart`
- `lib/shared/widgets/receipt_capture/receipt_photo_review_data_saver_panel.dart`
- `lib/shared/widgets/receipt_capture/receipt_photo_review_image_edit_actions.dart`
- `lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart`
- `lib/shared/widgets/receipt_capture/receipt_edge_cropper.dart`
- `lib/shared/widgets/receipt_capture/receipt_ocr_service.dart`
- `lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart`
- `lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart`
- `lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart`

### Native Android / iOS Camera Bridge

- `android/app/src/main/kotlin/com/maintainiac/MainActivity.kt`
- `android/app/src/main/kotlin/com/maintainiac/ReceiptCameraActivity.kt`
- `android/app/src/main/AndroidManifest.xml`
- `android/app/build.gradle.kts`
- `ios/Runner/AppDelegate.swift`
- `ios/Runner/ReceiptCameraViewController.swift`
- `ios/Runner.xcodeproj/project.pbxproj`
- `ios/Podfile.lock`

### Expense Receipt Flow

- `lib/screens/expenses/entry/expense_receipt_entry_screen.dart`
- `lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart`
- `lib/screens/expenses/entry/expense_receipt_parse_review.dart`
- `lib/screens/expenses/entry/expense_receipt_line_actions.dart`
- `lib/screens/expenses/entry/expense_receipt_line_editor.dart`
- `lib/screens/expenses/entry/expense_receipt_line_editor_actions.dart`
- `lib/screens/expenses/entry/expense_receipt_line_fields.dart`
- `lib/screens/expenses/entry/expense_receipt_line_models.dart`
- `lib/screens/expenses/entry/expense_receipt_recap.dart`
- `lib/screens/expenses/entry/expense_receipt_totals.dart`
- `lib/screens/expenses/entry/expense_receipt_save_actions.dart`

### Expense OCR / Parser / Diagnostics

- `lib/screens/expenses/data/expense_receipt_parser.dart`
- `lib/screens/expenses/data/expense_receipt_classifier.dart`
- `lib/screens/expenses/data/expense_receipt_category_rules.dart`
- `lib/screens/expenses/data/expense_receipt_ocr_review.dart`
- `lib/screens/expenses/data/expense_ocr_failure_diagnostics.dart`
- `lib/screens/expenses/data/expense_parser_failure_diagnostics.dart`
- `lib/screens/expenses/data/expense_screen_telemetry.dart`
- `lib/screens/expenses/data/expense_screen_telemetry_recorder.dart`
- `lib/screens/expenses/data/expense_screen_telemetry_firestore_bridge.dart`
- `lib/screens/expenses/data/expense_screen_telemetry_summary_scheduler.dart`

### Receipt / Camera Tests

- `test/receipt_native_android_bridge_test.dart`
- `test/receipt_native_ios_bridge_test.dart`
- `test/receipt_native_camera_contract_test.dart`
- `test/receipt_native_camera_shell_test.dart`
- `test/receipt_native_capture_staging_test.dart`
- `test/receipt_camera_capture_layout_test.dart`
- `test/receipt_camera_help_flow_test.dart`
- `test/receipt_camera_quality_guidance_test.dart`
- `test/receipt_camera_result_test.dart`
- `test/receipt_end_to_end_regression_matrix_test.dart`
- `test/receipt_image_data_saver_test.dart`
- `test/receipt_stitching_test.dart`
- `test/expense_receipt_assisted_review_flow_test.dart`
- `test/expense_screen_telemetry_test.dart`
- `test/helpers/expense_telemetry_schema_expectations.dart`

### Command 1 Admin Telemetry

This thread also owns the Command 1 expense health/admin telemetry surface:

- `/Users/rbbie/Documents/Comand 1/lib/features/expense_health/`
- `/Users/rbbie/Documents/Comand 1/lib/features/admin_screens/admin_detail_screen.dart`
- `/Users/rbbie/Documents/Comand 1/test/expense_health_panel_test.dart`

Other Command 1 work is allowed only if it does not modify the expense health
surface above.

## What Other Threads Can Safely Work On

Other threads may work on these areas if they avoid the files listed above:

- inventory catalog/trade-pack data
- materials catalog pack expansion
- maintenance UI and maintenance interval setup
- employee permission screens
- dashboard polish
- invoice planning
- non-receipt PDF planning
- general docs that do not redefine the receipt camera spec

If another thread needs receipt capture from maintenance or materials, it should
call into the existing shared receipt capture flow instead of forking it.

## Do Not Do These Things

Other threads must not:

- replace the receipt camera flow
- remove the native CameraX / AVFoundation bridge
- restore the deleted Flutter-camera screen files
- use the Samsung/native external camera app as the Maintainiac camera UI
- change receipt capture settings semantics
- change OCR to read compressed backup images before the original/clearest image
- rename `Use Photo`, `Use Photos`, `Next`, or receipt review handoff actions
  without coordinating here
- add private receipt text, store addresses, phone numbers, customer names,
  employee names, notes, or line-item descriptions to telemetry
- write service account keys, billing secrets, or admin credentials into either
  app
- connect Command 1 privileged actions directly from the app without a future
  server-authorized Cloud Function path
- edit `/Users/rbbie/Documents/Maintainiac_5.5`

## Current Receipt Flow Contract

The intended flow is:

1. User taps receipt/photo capture from the expense flow.
2. Maintainiac opens its own receipt camera UI.
3. Camera gives receipt-specific guidance.
4. User can pinch zoom, tap receipt text to focus, and adjust brightness.
5. User can always manually take a photo.
6. If long receipt mode is enabled, the app lets the user add another section.
7. The next section may show a previous-section ghost/overlap guide.
8. User accepts the photo(s).
9. The accepted photo(s) are locally staged/recoverable.
10. OCR reads from the original/clearest source first.
11. Backup/storage-optimized copies are created after the read/review path.
12. The app opens the filled receipt details review, not a confusing dead-end.
13. User reviews store/date/total/tax/item prices.
14. User classifies the whole receipt as business, personal, or mixed.
15. If mixed, each line supports business/personal/split allocation.
16. Save creates the expense and queues safe telemetry.

## Current Command 1 Telemetry Contract

Command 1 must show expense health without private content:

- OCR readable rate
- parser success rate
- save success rate
- time on Expense screen
- abandonment rate
- parser category counts
- parser needs-review category counts
- parser failed category counts
- top parser category
- top parser needs-review category
- top parser failed category
- failure cause
- workflow step
- where it failed
- confirmed evidence
- next action

Command 1 must not show:

- receipt image
- receipt text
- store address
- customer name
- employee name
- phone number
- email
- private notes
- full item descriptions

## Latest Completed Work In This Thread

- Added privacy-safe expense parser category telemetry in Maintainiac.
- Added Command 1 expense health model and expense telemetry panel.
- Added accepted-photo handoff panel copy for receipt reading.
- Added Android native camera settings/status strip.
- Changed Android native long-receipt action wording from generic `Done` to
  `Use Photo` / `Use Photos`.
- Added settings copy that OCR reads the original photo first and compressed
  backup copies are created after receipt reading.

## Validation Status

Last known passing checks:

- Maintainiac:
  - `flutter test test/expense_receipt_assisted_review_flow_test.dart test/expense_screen_telemetry_test.dart`
  - `flutter analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart`
- Command 1:
  - `flutter test test/expense_health_panel_test.dart test/widget_test.dart`
  - `flutter analyze lib/features/admin_screens/admin_detail_screen.dart lib/features/expense_health/expense_health_models.dart lib/features/expense_health/expense_health_panel.dart test/expense_health_panel_test.dart`

Interrupted check that still needs rerun:

- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_camera_shell_test.dart`

The interrupted check was stopped by user request during this coordination turn.

## Next Work For This Thread

This thread should continue with:

1. Rerun the interrupted Android native bridge and shell tests.
2. Fix any stale test guards from the Android native settings/status strip pass.
3. Continue native camera UI settings and review continuity.
4. Continue post-capture image review, crop/readability, and accepted-photo
   preservation.
5. Continue long receipt stitching and overlap confidence.
6. Continue OCR-source quality and parser handoff after camera capture is stable.

## Rule For Parallel Work

If another model needs to touch any file listed under "Files This Thread Is
Actively Touching," pause and ask the user before editing. Do not assume a small
change is safe. This receipt system is the active critical path.
