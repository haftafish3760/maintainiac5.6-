# Receipt Camera OCR Master Pass Plan Archive - Pass 21 of 40: Separate OCR Fallback

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Pass 21 of 40: Separate OCR Fallback

Status: pending.

Goal:
- Make fallback to separate photos reliable.

Scope:
- Ordered OCR per photo.
- Duplicate overlap text suppression.
- Missing middle section detection where possible.
- User-safe warnings.

Done:
- Bad stitching does not ruin the receipt read.

### Pass 22 of 40: S24 UI Review Batch 2

Status: pending.

Goal:
- Install UI/image/long-receipt batch to S24 Ultra.

Scope:
- Live capture.
- Photo review.
- Long receipt section capture.
- Stitch/fallback review.

Done:
- User can test real long receipt behavior on S24.

## OCR And Parser Intelligence Track

### Pass 23 of 40: OCR Reliability Audit

Status: pending.

Goal:
- Audit shared OCR service for photo, PDF, imported text, and stitched sources.

Scope:
- Timeouts.
- Page limits.
- Duplicate/overlap handling.
- Warnings.
- Older-phone workload limits.

Done:
- OCR service has clear behavior for every receipt source.

### Pass 24 of 40: OCR Diagnostics Hardening

Status: pending.

Goal:
- Make OCR failures explainable without exposing receipt content.

Scope:
- No text found.
- Blurry/unreadable.
- Too long/too large.
- Plugin unavailable.
- Timeout.
- Duplicate/overlap suppressed.

Done:
- Each OCR failure has confirmed cause or clear missing evidence.

### Pass 25 of 40: Expensify-Style Parser Fields

Status: pending.

Goal:
- Improve extraction for merchant, date, subtotal, tax, total, payment, receipt number.

Scope:
- Lowe's/Home Depot.
- Walmart/Target/general retail.
- Fuel receipts.
- Returns/negative lines.
- Regional convenience stores.

Done:
- Core receipt fields are extracted and confidence-scored.

### Pass 26 of 40: Parser Line Items

Status: pending.

Goal:
- Improve line item extraction.

Scope:
- Item description.
- Amount.
- Quantity.
- Unit/pack where available.
- Returns/discounts/negative lines.
- Taxable vs non-taxable signals where possible.

Done:
- Parsed lines match the receipt better and mark uncertainty clearly.

### Pass 27 of 40: Vendor Profiles

Status: pending.

Goal:
- Add maintainable vendor parsing profiles.

Scope:
- Vendor aliases.
- Receipt layout hints.
- Total/tax/date patterns.
- Fuel-specific profiles.
- Regional store hooks.

Done:
- Vendor matching is explainable and updateable.

### Pass 28 of 40: Correction Learning

Status: pending.

Goal:
- Use local corrections to improve future receipt parsing.

Scope:
- Original OCR text.
- Corrected field.
- Corrected category/item.
- Merchant context.
- Local-first storage.
- Future Firebase contribution remains opt-in.

Done:
- User corrections make future parsing better locally.

## Expense Review And Maintainiac Intelligence Track

### Pass 29 of 40: Receipt Review Screen Polish

Status: pending.

Goal:
- Make the parsed receipt review screen professional and fast.

Scope:
- Merchant/date/total summary.
- Line list.
- Confidence and review reasons.
- Edit/confirm/remove actions.
- No developer jargon.

Done:
- User knows what the app found and what needs review.

### Pass 30 of 40: Business Personal Mixed Whole Receipt

Status: pending.

Goal:
- Make whole-receipt classification fast.

Scope:
- All business.
- All personal.
- Mixed receipt.
- Keep selected state unmistakable.
- Update totals immediately.

Done:
- User can classify a simple receipt in seconds.

### Pass 31 of 40: Mixed Receipt Line Classification

Status: pending.

Goal:
- Make mixed receipt line-by-line classification fast.

Scope:
- Business/personal/split per line.
- Bulk actions.
- Keyboard/accessibility friendly.
- Clear line totals.

Done:
- Mixed receipts are manageable without frustration.

### Pass 32 of 40: Split Percent And Tax Allocation

Status: pending.

Goal:
- Make split math correct.

Scope:
- Business percentage.
- Personal percentage.
- Tax allocation.
- Receipt total reconciliation.
- Rounding rules.

Done:
- Business/personal totals are defensible and understandable.

### Pass 33 of 40: Simple Mode Detailed Mode

Status: pending.

Goal:
- Make simple and detailed receipt modes clear.

Scope:
- Simple mode: amounts and classification.
- Detailed mode: descriptions, quantity, unit, category, inventory fields.
- First-use explanation.
- Per-area settings.

Done:
- User understands the difference and can switch without confusion.

### Pass 34 of 40: Vehicle And Mixed-Use Expense Intelligence

Status: pending.

Goal:
- Use vehicle/profile context in receipt expenses.

Scope:
- Vehicle selected.
- Business/personal mileage share.
- Fuel/maintenance/repair/insurance/registration allocation.
- Odometer edge-case coordination.

Done:
- Shared-use vehicle expenses allocate correctly.

### Pass 35 of 40: Materials Inventory Bridge

Status: pending.

Goal:
- Keep expense receipts and inventory updates correctly separated.

Scope:
- Expense-origin materials stay expense-first.
- Ask whether to prepare inventory.
- Stage inventory changes.
- Confirm before inventory update.

Done:
- Inventory never changes behind the user's back.

## Storage, Sync, Privacy, Diagnostics, And QA Track

### Pass 36 of 40: Storage And Backup Policy

Status: pending.

Goal:
- Make receipt proof storage lean and understandable.

Scope:
- Local original temporary handling.
- Saved proof size.
- Cloud backup size.
- Low-storage behavior.
- Export implications.

Done:
- User storage and Firebase costs stay controlled.

### Pass 37 of 40: Firestore Sync Shape For Receipts

Status: pending.

Goal:
- Ensure receipt backup does not explode reads/writes/cost.

Scope:
- Local-first Hive source of truth.
- Firestore mirror documents.
- Bundled/summarized sync where feasible.
- Receipt image storage references.
- No private raw OCR text in telemetry.

Done:
- Receipt data can sync without runaway Firebase cost.

### Pass 38 of 40: Command One Diagnostics Feed

Status: pending.

Goal:
- Feed Command One with privacy-safe receipt health.

Scope:
- Capture success/failure.
- OCR success/failure.
- Parser success/failure.
- Review correction rate.
- Abandonment rate.
- Device tier and app version context.

Done:
- Command One can show what failed, where it failed, and why without private receipt content.

### Pass 39 of 40: Synthetic Torture Test Suite

Status: pending.

Goal:
- Build repeatable receipt tests before relying only on real receipts.

Scope:
- Lowe's/Home Depot.
- Walmart/Target.
- Fuel.
- Returns.
- Long receipts.
- Faded/wrinkled/noisy.
- Multi-photo overlap.

Done:
- Parser and OCR changes are regression-tested.

### Pass 40 of 40: Real Device And Real Receipt QA

Status: pending.

Goal:
- Prove the receipt flow on actual devices and actual ugly receipts.

Scope:
- S9 Plus class.
- S24/S25 class.
- iPhone class.
- Photo capture.
- Multi-photo stitching.
- OCR/parser review.
- Save and later calendar/detail review.

Done:
- The receipt system can be called ready for broader app testing.

## Camera-Only Continuation After PDF Freeze

The user paused PDF work until the receipt camera/capture/review flow is
professional and complete. The active lane resumes camera, OCR handoff,
stitching, and expense receipt review only.

### Camera/Receipt Pass 68 of up to 150: Review Tray And OCR Handoff Cleanup

Status: completed.

Goal:
- Make the receipt photo review path feel like a professional camera workflow,
  especially for one-photo receipts and long receipts.

Completed:
- Reserved more vertical room for the receipt image in preview, order, stitch,
  and saved-proof preview modes so the bottom controls do not cover the
  receipt being reviewed or cropped.
- Reworked the single-photo review tray so the primary action is clearly
  "Read Receipt" and the tool actions are secondary.
- Changed multi-photo wording from vague "sections" to plain "receipt photos,"
  with clear top-to-bottom ordering guidance.
- Renamed the review tool action to "Saved Proof Size" where the user previews
  the smaller backup image, while preserving that OCR reads the clear source
  first.
- Stopped the expense receipt screen from immediately kicking off a duplicate
  OCR scan after the shared receipt panel already reads the reviewed photo.
- Added visible parsing state and confirmed failure telemetry for the imported
  OCR text handoff into the expense parser.

Verification:
- `flutter test test/receipt_camera_help_flow_test.dart test/receipt_photo_section_labels_test.dart test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/receipt_camera_help_flow_test.dart test/expense_receipt_assisted_review_flow_test.dart`

Next camera-only focus:
- Continue receipt photo review polish around crop ergonomics, stitch preview
  confidence, and the direct OCR-to-business/personal/mixed review landing.

### Camera/Receipt Pass 69 of up to 150: Crop Preview Crash And Crop Ergonomics

Status: completed.

Goal:
- Fix the receipt preview failure reported during camera/photo review and make
  receipt cropping behave more like a professional document/photo editor.

Completed:
- Moved cropper display-rect and initial-crop callbacks out of layout/build and
  into safe post-frame callbacks.
- Added mounted/context guards so crop callbacks do not update the review screen
  after the cropper has been disposed or after the user leaves crop mode.
- Added corner crop handles in addition to edge handles, so users can adjust a
  receipt crop from the corners instead of fighting one edge at a time.
- Wired the saved-proof preview card into the active Saved Proof Size mode so
  the user sees a plain-language storage preview instead of a dead/unused
  widget.
- Removed the unused photo-strip part and stale review-control widgets that
  were guarded by `unused_element` ignores.

Verification:
- `flutter test test/receipt_camera_help_flow_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_photo_section_labels_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_edge_cropper.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_help_flow_test.dart test/receipt_photo_section_labels_test.dart`
- `rg -n "unused_element|_ReceiptPhotoOrderCheckPanel|_ReceiptPreviewActions|_BestPhotoReviewNotice|_CompactPhotoActionButton|receipt_photo_review_strip|build preview|disposed" lib/shared/widgets/receipt_capture test/receipt_camera_help_flow_test.dart test/receipt_photo_section_labels_test.dart -S`

Next camera-only focus:
- Continue camera flow polish around the direct post-photo review landing,
  multi-photo stitch confidence, and making crop/stitch/data-saver modes feel
  like one coherent receipt-scanner workflow.

### Camera/Receipt Pass 70 of up to 150: Post-Photo Review Landing

Status: completed.

Goal:
- Make the app land on visible receipt review after the user accepts and reads a
  receipt photo, even when OCR/parser finds only header/totals and not line
  items.

Completed:
- Moved the receipt-review scroll target so it wraps the full parsed review
  block instead of only the line-item review panel.
- Kept whole-receipt business/personal/mixed controls and line review inside
  that same landing area when line items are available.
- Preserved the classification, OCR diagnostics, field confidence, and
  maintenance hint display as the first review surface after app-assisted photo
  reading.
- Verified the deleted legacy photo strip and stale review widgets are no
  longer referenced.

Verification:
- `flutter test test/receipt_camera_help_flow_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_photo_section_labels_test.dart test/receipt_camera_result_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_edge_cropper.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/receipt_camera_help_flow_test.dart test/receipt_photo_section_labels_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_edge_cropper.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_data_saver_panel.dart lib/shared/widgets/receipt_capture/receipt_photo_review_strip.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/receipt_camera_help_flow_test.dart test/receipt_photo_section_labels_test.dart docs/receipt_camera_ocr_master_pass_plan.md`
- `rg -n "unused_element|_ReceiptPhotoOrderCheckPanel|_ReceiptPreviewActions|_BestPhotoReviewNotice|_CompactPhotoActionButton|receipt_photo_review_strip|build preview|disposed" lib/shared/widgets/receipt_capture test/receipt_camera_help_flow_test.dart test/receipt_photo_section_labels_test.dart -S`

Next camera-only focus:
- Continue with camera/stitch polish only: stitch confidence language, review
  action flow, and safer multi-photo long-receipt handling.
