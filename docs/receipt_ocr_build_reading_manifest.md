# Receipt OCR Build Reading Manifest

This is the scoped reading boundary for the receipt camera/OCR/form workflow
on branch `codex/receipt-ocr-audit-20260713`. Read only the files needed for the
current pass. Add a file here only when a direct dependency requires it.

## Product and architecture contracts

- `docs/receipt_camera_ocr_product_standard.md`
- `docs/receipt_camera_release_one_blueprint.md`
- `docs/receipt_camera_completion_map.md`
- `docs/receipt_native_camera_service_spec.md`
- `docs/receipt_ocr_pipeline_blueprint.json`

## Native camera and permissions

- `android/app/src/main/AndroidManifest.xml`
- `android/app/build.gradle.kts`
- `android/app/src/main/kotlin/com/maintainiac/MainActivity.kt`
- `android/app/src/main/kotlin/com/maintainiac/ReceiptCameraActivity.kt`
- `android/app/src/main/kotlin/com/maintainiac/ReceiptCamera*.kt`
- `ios/Runner/Info.plist`
- `ios/Runner/AppDelegate.swift`
- `ios/Runner/ReceiptCameraViewController.swift`
- `ios/Runner/ReceiptCameraViewController*.swift`
- `lib/shared/widgets/receipt_capture/receipt_camera_permission.dart`
- `lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart`
- `lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart`
- `lib/shared/widgets/receipt_capture/receipt_native_camera_settings.dart`

## Capture, source preservation, and OCR

- `lib/shared/widgets/receipt_capture/receipt_capture_flow*.dart`
- `lib/shared/widgets/receipt_capture/receipt_photo_review*.dart`
- `lib/shared/widgets/receipt_capture/receipt_image_processor*.dart`
- `lib/shared/widgets/receipt_capture/receipt_ocr*.dart`
- `lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart`
- `lib/shared/widgets/receipt_capture/receipt_attachment_duplicate_detector.dart`
- `lib/shared/receipts/receipt_ocr_contract.dart`
- `lib/shared/receipts/receipt_ocr_handoff.dart`
- `lib/shared/receipts/receipt_processing_contract.dart`

## Expense form and classification boundary

- `lib/screens/expenses/entry/expense_receipt_entry_screen.dart`
- `lib/screens/expenses/entry/expense_receipt_entry*.dart`
- `lib/screens/expenses/entry/expense_receipt_parse_review*.dart`
- `lib/screens/expenses/entry/expense_receipt_line*.dart`
- `lib/screens/expenses/data/expense_receipt_ocr_review.dart`
- `lib/screens/expenses/data/expense_receipt_parser_ocr_handoff_logic.dart`
- `lib/shared/receipts/receipt_line_models.dart`
- `lib/shared/receipts/receipt_line_selection_contract.dart`
- `lib/shared/state/expense_settings_store.dart`

## Reusable QA infrastructure

- `tool/receipt_ocr_audit.sh`
- `tool/receipt_ocr_focus_gate.sh`
- `tool/receipt_ocr_pipeline_run.sh`
- `tool/receipt_qa_runner.dart`
- `tool/receipt_qa_report_models.dart`
- `tool/receipt_qa_scoring*.dart`
- `test/support/qa_harness/qa_harness.dart`
- `test/support/qa_harness/qa_threshold_gate.dart`
- `test/support/qa_harness/maintainiac_qa_backbone.dart`
- `test/support/qa_harness/maintainiac_scope_policy.dart`
- `test/support/qa_harness/maintainiac_source_boundary.dart`

## Focused regression families

- `test/receipt_camera_*test.dart`
- `test/receipt_native_*test.dart`
- `test/receipt_ocr_*test.dart`
- `test/receipt_capture_*test.dart`
- `test/expense_receipt_assisted_review_*test.dart`
- `test/expense_receipt_category_rules_test.dart`
- `test/expense_receipt_parser_business_personal_test.dart`
- `test/receipt_line_models_test.dart`

Fuel, inventory/materials, Work Supplies, GPS, payroll, invoice, maintenance,
and unrelated dashboard files are excluded unless a test proves a direct
receipt handoff contract dependency. Their parser implementations must not be
modified in this lane.

## Working rules

1. Use `tool/receipt_ocr_audit.sh` before broad searches.
2. Read only the smallest direct dependency slice for the current pass.
3. Run the narrowest relevant regression before expanding scope.
4. Bundle safe related changes into one commit and push after a green gate.
5. Do not call the flow world-class without real-device and real-receipt proof.
