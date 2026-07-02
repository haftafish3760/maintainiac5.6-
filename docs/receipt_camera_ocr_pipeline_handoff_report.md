# Maintainiac Receipt Camera/OCR Pipeline Handoff Report

Last updated: 2026-07-01

Workspace: `/Users/rbbie/Documents/Maintainiac_5.6`

## Hard Boundaries

- Work only in Maintainiac 5.6 unless the user explicitly says otherwise.
- Do not touch Maintainiac 5.5.
- Current focus is the local receipt camera, image processing, OCR handoff, and expense receipt parsing pipeline.
- Do not drift into Firebase/cloud OCR, PDF import, inventory, maintenance, or permissions until the local camera/OCR pipeline is stable enough for real-device testing.
- The production camera direction is a custom in-app native camera surface:
  - Android: CameraX.
  - iOS: AVFoundation.
- The stock phone camera app and image picker are fallback/import paths only.
- The old Flutter camera package/controller path is not allowed to be the production camera foundation.
- OCR must read the clearest/original capture source before any aggressive proof compression.
- Saved proof/cloud backup copies can be compressed after OCR source selection.
- User privacy is paramount. Diagnostics must not include raw receipt text, merchant-specific private text, personal data, full receipt images, or user financial content.

## Product Objective

Build a receipt capture and OCR system good enough that a driver, contractor, or small business user can:

1. Open expense receipt capture.
2. Take one or more readable receipt photos quickly.
3. Add another photo when the receipt is long.
4. See an understandable review screen.
5. Let Maintainiac read the receipt locally when possible.
6. Review the parsed result on the next screen, not get dumped back to the expense start screen.
7. Classify the receipt as business, personal, or mixed.
8. For mixed receipts, classify individual receipt lines.
9. Save the expense with receipt proof and parser/OCR diagnostics.

The experience should feel like a purpose-built receipt scanner, not a generic photo picker. It should borrow the best ideas from:

- Adobe Scan: image cleanup, crop, perspective correction, clean document look.
- Microsoft Lens: fast capture, simple framing, minimal cognitive load.
- Expensify: receipt-to-expense intelligence.
- Genius Scan: multi-page/long-receipt workflow.
- Scanner Pro/CamScanner: polished scan review, filters, and professional scanner feel.

Maintainiac must then add its own business logic:

- Business, personal, and mixed receipt classification.
- Simple price-only review mode.
- Detailed receipt line review mode.
- Split percentages per line when needed.
- Vehicle/profile awareness.
- Local-first storage.
- Privacy-safe diagnostics.
- Low-storage and older-phone safe behavior.

## Current Completion Estimate

This is an estimate, not a guarantee:

- Native camera foundation: about 55-60%.
- Receipt review/stitching flow: about 50-55%.
- Local OCR handoff: about 45-50%.
- Local parser intelligence: about 40-45%.
- QA harness/testing maturity: about 25-30%.
- Whole local receipt camera/OCR/parser system: about 45-50%.

For just the camera and OCR pipeline, excluding deep category parser intelligence, the system is roughly 55-60% done. The remaining 40-45% is mostly real-device hardening, camera quality tuning, image cleanup, OCR confidence calibration, QA automation, and flow polish.

## What Has Already Been Built Or Started

### Native Camera Bridge

Relevant files:

- `android/app/src/main/kotlin/com/maintainiac/MainActivity.kt`
- `android/app/src/main/kotlin/com/maintainiac/ReceiptCameraActivity.kt`
- `ios/Runner/AppDelegate.swift`
- `ios/Runner/ReceiptCameraViewController.swift`
- `lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart`
- `lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart`
- `lib/shared/widgets/receipt_capture/receipt_native_camera_shell.dart`
- `lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart`

Current state:

- Android code references CameraX through `ProcessCameraProvider`.
- iOS code references AVFoundation through `AVCaptureSession`, `AVCapturePhotoOutput`, `AVCaptureVideoPreviewLayer`, and video frame hooks.
- Dart has a `maintainiac/receipt_camera` method channel through `ReceiptNativeCameraService`.
- Native capture diagnostics include `captureSurface` and `nativeCaptureUiContract`.
- The Dart side verifies a Maintainiac native/custom receipt camera surface rather than blindly accepting any result.
- Camera capabilities model includes support flags for focus, exposure, torch, zoom, macro, YUV live frames, RAW, native edge signals, and still dimensions.

Important expectation:

- The user must never be surprised by seeing the stock Samsung/iPhone camera UI as the primary receipt flow. That is not the desired production camera.

### Camera Settings Contract

Relevant files:

- `lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart`
- `lib/shared/widgets/receipt_capture/receipt_capture_settings_store.dart`
- `lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart`
- `lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart`
- `test/receipt_native_android_bridge_test.dart`
- `test/receipt_native_ios_bridge_test.dart`
- `test/receipt_capture_settings_store_test.dart`
- `test/receipt_assistance_policy_test.dart`

Already modeled:

- Assisted receipt fill.
- Prices-only versus detailed-line review depth.
- Long receipt mode.
- Manual shutter always available.
- Auto capture disabled by default.
- Tap focus.
- Pinch zoom.
- Exposure slider.
- Exposure reset.
- Auto exposure assist.
- Focus mode.
- Exposure mode.
- White balance mode.
- Flash mode.
- Macro preference.
- JPEG/YUV/RAW-style format planning.
- Live analysis.
- Edge detection.
- Edge overlay.
- Perspective correction.
- Motion blur warning.
- Glare warning.
- Low light warning.
- Shadow warning.
- Too far/too close warning.
- Receipt fully visible warning.
- Text too small warning.
- Previous-section ghost guide.
- Manual crop after capture.
- Auto crop suggestion.
- Grayscale/black-and-white proof planning.
- Contrast boost.
- Sharpening.
- Data saver/proof-size tiering.
- Optional parser pack/device-space recommendations.

Still needed:

- Prove these settings are exposed in the correct places in the UI.
- Prove native Android/iOS actually honor the important controls.
- Make sure every setting has user-friendly language, not developer jargon.
- Add reset-to-default behavior where needed.
- Keep user-facing device capability details private/background-only unless the user asks for diagnostics.

### Receipt Capture Flow

Relevant files:

- `lib/shared/widgets/receipt_capture/receipt_capture.dart`
- `lib/shared/widgets/receipt_capture/receipt_capture_flow.dart`
- `lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart`
- `lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart`
- `lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart`
- `lib/shared/widgets/receipt_capture/receipt_capture_models.dart`
- `lib/screens/expenses/entry/expense_receipt_entry_screen.dart`
- `lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart`
- `lib/screens/expenses/entry/expense_receipt_parse_review.dart`

Current direction:

- Native camera should be attempted before fallback/import paths.
- Manual capture should not be blocked by quality guidance unless the camera is unavailable, busy, closing, or inactive.
- Back/cancel should behave as a clean user cancellation, not a false camera failure.
- After capture, the user should review the photo and then continue into assisted receipt review when assisted fill is enabled.
- The user must not be dropped back to the receipt start screen after accepting a photo if assisted receipt fill is on.

Still needed:

- Real-device proof that Back/cancel works on S24/S25/S9/iPhone.
- Real-device proof that photo acceptance flows to the parsed receipt review screen.
- Remove confusing labels like `Read receipt` if the user expects `Next`, `Continue`, or `Save and continue`.
- Make Add Another Photo obvious, not just a camera icon with a plus.
- Avoid hiding critical controls in a small scrollable bottom panel.
- Ensure the receipt image is not obscured while reviewing/cropping.

### Photo Review UI Modules

Relevant files:

- `lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart`
- `lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart`
- `lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart`
- `lib/shared/widgets/receipt_capture/receipt_photo_review_common_controls.dart`
- `lib/shared/widgets/receipt_capture/receipt_photo_review_context_controls.dart`
- `lib/shared/widgets/receipt_capture/receipt_photo_review_crop_and_proof_controls.dart`
- `lib/shared/widgets/receipt_capture/receipt_photo_review_mode_controls.dart`
- `lib/shared/widgets/receipt_capture/receipt_photo_review_order_controls.dart`
- `lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart`
- `lib/shared/widgets/receipt_capture/receipt_photo_review_stitch_controls.dart`
- `lib/shared/widgets/receipt_capture/receipt_photo_review_data_saver_panel.dart`
- `lib/shared/widgets/receipt_capture/receipt_photo_review_image_edit_actions.dart`
- `lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart`
- `lib/shared/widgets/receipt_capture/receipt_photo_review_section_labels.dart`

Current direction:

- Photo review was split into multiple smaller modules.
- There are controls for order, stitch, crop/proof, preview, mode, context, common actions, and data saver.
- The system models saved proof versus OCR source separately.

Still needed:

- Real-device UI review.
- Reduce any remaining control-panel clutter.
- Make the main photo preview about 75-80% of the height when appropriate.
- Keep controls visible enough to understand but not so large that they cover the receipt.
- Ensure pinch-to-zoom works in camera capture and review.
- Ensure crop/manual adjustment can reach all receipt edges.
- Ensure accepted photos are not thrown away if the user hits Back accidentally.

### Image Processing And Proof Storage

Relevant files:

- `lib/shared/widgets/receipt_capture/receipt_image_processor.dart`
- `lib/shared/widgets/receipt_capture/receipt_proof_storage.dart`
- `lib/shared/widgets/receipt_capture/receipt_proof_storage_copy.dart`
- `lib/shared/widgets/receipt_capture/receipt_proof_storage_file_names.dart`
- `lib/shared/widgets/receipt_capture/receipt_storage_guard.dart`
- `test/receipt_image_data_saver_test.dart`
- `test/receipt_proof_storage_hardening_test.dart`
- `test/receipt_proof_storage_lifecycle_test.dart`

Current direction:

- OCR source image and saved proof image are distinct concepts.
- OCR should use the cleanest/original source first.
- Saved proof can be compressed for storage/cloud cost.
- Data saver tiers exist conceptually.
- Proof storage has lifecycle and hardening tests.

Still needed:

- Better black-and-white/grayscale proof preview.
- User-facing data saver previews that show estimated file size and visual result.
- Stronger image cleanup:
  - deskew,
  - perspective correction,
  - shadow cleanup,
  - glare mitigation,
  - contrast normalization,
  - sharpening,
  - noise reduction,
  - orientation correction.
- Always keep a fallback to original OCR source if enhancement makes OCR worse.

### Long Receipt Stitching

Relevant files:

- `lib/shared/widgets/receipt_capture/receipt_image_processor.dart`
- `lib/shared/widgets/receipt_capture/receipt_capture_models.dart`
- `test/receipt_stitching_test.dart`
- `test/receipt_ocr_overlap_test.dart`
- `test/synthetic_receipt_long_retail_torture_test.dart`
- `test/synthetic_receipt_long_contractor_pack_test.dart`

Verified recently:

- `flutter test test/receipt_stitching_test.dart -r compact` passed.

Already covered:

- Stitch result labels explain stitched and fallback OCR handoff.
- Stitch fallback reasons have user-safe labels.
- A stitch preview can be rebound to final OCR artifact paths.
- A verified stitch preview can be copied into durable OCR artifact storage.
- Manual overlap can stitch when automatic matching is uncertain.
- Manual overlap fraction can drive stitching from review UI.
- Unsafe manual overlap falls back.
- Overlapping receipt sections can be stitched for OCR.
- Next photo closer/farther scale changes are handled.
- Slight handheld rotation is handled.
- Output-too-large falls back safely.
- Low overlap confidence falls back to ordered OCR sections.

Still needed:

- Real-device long-receipt flow proof.
- Ghost image overlay from the previous section during next-photo capture.
- Bottom-edge and subtotal/total detection to suggest adding another section.
- Duplicate line suppression after stitching/ordered OCR.
- Better user copy for when stitching falls back but OCR can still read sections top-to-bottom.

### OCR Service And OCR Handoff

Relevant files:

- `lib/shared/widgets/receipt_capture/receipt_ocr_service.dart`
- `lib/shared/receipts/receipt_line_models.dart`
- `lib/shared/receipts/receipt_processing_contract.dart`
- `lib/shared/receipts/receipt_layout_intelligence.dart`
- `test/receipt_ocr_service_test.dart`
- `test/receipt_ocr_combined_text_stress_test.dart`
- `test/synthetic_receipt_ocr_noise_pack_test.dart`
- `test/synthetic_receipt_damaged_input_pack_test.dart`

Already started:

- OCR result can identify parser-ready ordered line signals.
- OCR distinguishes item lines, totals, subtotals, tax, tender/auth/reference rows.
- OCR can preserve fuel/grocery/hardware/material family hints.
- OCR handoff can carry mixed-family evidence forward.
- OCR handles common receipt labels such as `MERCH TOTAL`.
- OCR avoids treating address/phone/tender/auth/reference rows as item prices in covered cases.

Still needed:

- A much larger OCR fixture set.
- Better confidence scoring calibrated against readable real receipts.
- Better handling of:
  - faded thermal paper,
  - dirty receipts,
  - folded receipts,
  - screen photos,
  - receipts with blurry bottom sections,
  - tilted receipts,
  - clipped top/bottom,
  - very long receipts,
  - tiny text,
  - split fuel rows,
  - multiple tax lines,
  - gift card/store credit/payment balance rows.
- Live or near-live readability checks must remain advisory and fast.
- If live OCR is too slow on older devices, capture guidance must use lightweight heuristics and defer OCR until after capture.

### Expense Receipt Parser

Relevant files:

- `lib/screens/expenses/data/expense_receipt_parser.dart`
- `lib/screens/expenses/data/expense_receipt_parser_logic.dart`
- `lib/screens/expenses/data/expense_receipt_parse_models.dart`
- `lib/screens/expenses/data/expense_receipt_parse_quality.dart`
- `lib/screens/expenses/data/expense_receipt_parser_support_models.dart`
- `lib/screens/expenses/data/expense_receipt_category_keywords.dart`
- `lib/screens/expenses/data/expense_receipt_category_rules.dart`
- `lib/screens/expenses/data/expense_receipt_fuel_parser.dart`
- `lib/screens/expenses/data/expense_receipt_material_parser.dart`
- `lib/screens/expenses/data/expense_receipt_maintenance_parser.dart`
- `lib/screens/expenses/data/expense_receipt_merchant_profiles.dart`
- `lib/screens/expenses/data/expense_receipt_merchant_fuel_profiles.dart`
- `lib/screens/expenses/data/expense_receipt_merchant_grocery_profiles.dart`
- `lib/screens/expenses/data/expense_receipt_merchant_material_profiles.dart`
- `lib/screens/expenses/data/expense_receipt_merchant_meal_profiles.dart`
- `lib/screens/expenses/data/expense_receipt_merchant_auto_profiles.dart`
- `lib/screens/expenses/data/expense_receipt_merchant_telecom_profiles.dart`

Already started:

- Merchant/date/time/subtotal/tax/total parsing.
- Fuel quantity/unit price/total extraction.
- Grocery, food, materials, vehicle supplies, tools, maintenance-style item categories in covered cases.
- Tender/reference/auth rows are excluded in covered cases.
- Parser diagnostics include trust labels, category counts, review buckets, required-field status, downstream readiness, family counts, and mixed-family evidence.
- OCR-derived family hints can upgrade generic parser lines when safe.

Important distinction:

- This expense parser is not the same as the inventory/materials parser.
- Inventory parsing can use material/trade catalogs.
- Expense parsing must handle broad receipts: fuel, food, groceries, repairs, maintenance, tools, supplies, fees, telecom, travel, parking, tolls, etc.

Still needed:

- Fuel-specific parsing must become much stronger:
  - store name,
  - station/merchant,
  - pump,
  - gallons,
  - price per gallon,
  - fuel grade/type,
  - subtotal,
  - discounts/rewards,
  - tax,
  - total,
  - odometer if present,
  - other purchased items.
- Maintenance parsing is a separate large project:
  - oil type,
  - oil weight,
  - filter,
  - service mileage,
  - next due mileage/date,
  - tire rotation,
  - transmission/coolant/brake service,
  - maintenance interval setup.
- Maintenance receipt parsing should be handled after camera/OCR is stable.
- Parser learning/QA tools are needed so corrections can become future parsing capability.

### Assisted Receipt Review

Relevant files:

- `lib/screens/expenses/entry/expense_receipt_parse_review.dart`
- `lib/screens/expenses/entry/expense_receipt_line_models.dart`
- `lib/screens/expenses/entry/expense_receipt_line_actions.dart`
- `lib/screens/expenses/entry/expense_receipt_line_editor.dart`
- `lib/screens/expenses/entry/expense_receipt_totals.dart`
- `test/expense_receipt_assisted_review_flow_test.dart`

Current direction:

- Assisted review should show parsed receipt contents after accepting photo(s).
- User should choose:
  - all business,
  - all personal,
  - mixed.
- In mixed mode, each line should be classifiable as business/personal/split.
- Mixed-family receipts should surface clear guidance without noisy UI.

Recently started:

- OCR/parser mixed-family evidence is being carried into diagnostics.
- Assisted review can use mixed-family guidance labels.

Still needed:

- Finish any in-progress pass around mixed-family review readiness copy.
- Ensure the accepted photo flow actually lands on this review screen.
- Make the UI clearly show what OCR/parser found.
- Add simple mode versus detailed mode:
  - simple mode: item price lines only.
  - detailed mode: item descriptions/details plus prices.
- Add tax allocation for mixed receipts.
- Add split percentages for mixed lines.
- Ensure receipt totals reconcile after business/personal/mixed splits.

### Diagnostics And Telemetry

Relevant files:

- `lib/screens/expenses/data/expense_screen_telemetry.dart`
- `lib/screens/expenses/data/expense_screen_telemetry_recorder.dart`
- `lib/screens/expenses/data/expense_screen_telemetry_firestore_bridge.dart`
- `lib/screens/expenses/data/expense_screen_telemetry_summary_scheduler.dart`
- `lib/screens/expenses/data/expense_receipt_privacy_event.dart`
- `lib/screens/expenses/data/expense_receipt_privacy_event_store.dart`
- `lib/screens/expenses/data/expense_ocr_failure_diagnostics.dart`
- `lib/screens/expenses/data/expense_parser_failure_diagnostics.dart`
- `docs/expense_command_center_ocr_contract.md`
- `test/expense_screen_telemetry_test.dart`
- `test/expense_screen_telemetry_firestore_bridge_test.dart`
- `test/receipt_privacy_event_test.dart`
- `test/receipt_privacy_event_store_test.dart`
- `test/expense_telemetry_redaction_contract_guard_test.dart`

Current direction:

- Command One/admin health needs OCR/parser diagnostics without private user content.
- Diagnostics should report categories, counts, failure causes, readiness, and privacy-safe codes.

Still needed:

- Keep telemetry local until cloud/Firebase work resumes.
- Ensure no raw receipt text leaks into telemetry.
- Add camera/OCR health dashboard metrics:
  - capture success rate,
  - cancel rate,
  - back-button/cancel failures,
  - OCR readable rate,
  - OCR failed rate,
  - parser success rate,
  - parser review rate,
  - stitch success/fallback rate,
  - low-light/blur/glare issue buckets,
  - device-tier issue buckets.

### QA Harness And Tests

QA harness details, remaining work, evidence commands, and next-model warnings were archived to keep the active handoff report under the 500-line file limit.

- Archive: `docs/receipt_camera_ocr_pipeline_handoff_report_archive_qa_and_remaining_work.md`.
