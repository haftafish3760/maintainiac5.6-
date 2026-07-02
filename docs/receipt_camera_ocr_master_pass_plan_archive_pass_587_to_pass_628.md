# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 587: Android Receipt Still-Capture Quality Batch

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 587: Android Receipt Still-Capture Quality Batch

Status: complete.

What changed:
- Removed Android CameraX minimize-latency still capture from the receipt
  camera path.
- Android now uses `CAPTURE_MODE_MAXIMIZE_QUALITY` for receipt still photos on
  every device tier.
- Low-tier devices still get lighter live analysis and workload settings, but
  the actual saved receipt photo no longer trades readability for shutter
  latency.
- Raised the light-device receipt JPEG quality target from 92 to 94.
- Added a native bridge guard so minimize-latency capture mode cannot return to
  the receipt still-photo path unnoticed.

Validation:
- `dart format test/receipt_native_android_bridge_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_camera_capture_layout_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is saved-photo brightness and sharpness
  parity: compare live brightness, pre-capture exposure decision, saved-photo
  luma bands, and captured sharpness so review warnings explain exactly why a
  photo needs retake/crop/add-light.

### Receipt Camera Reopen Pass 588: Brightness Assist Outcome Warning Batch

Status: complete.

What changed:
- Android CameraX saved-photo diagnostics now distinguish captures that remain
  too dark or dim after pre-capture brightness assist.
- iOS AVFoundation saved-photo diagnostics now use the same assisted-brightness
  mismatch vocabulary.
- Added `pre_capture_brightened_still_too_dark` and
  `pre_capture_brightened_still_dim` mismatch outcomes.
- Receipt review now shows specific warnings when brightness assist tried but
  the saved photo still needs more light.
- Added action codes for turning on light/retaking or checking text/adding
  light before OCR review.
- Kept telemetry privacy-safe: only mismatch/status buckets are recorded, not
  receipt text or image content.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_quality_guidance_test.dart test/receipt_camera_result_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_quality_guidance_test.dart test/receipt_camera_result_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_camera_quality_guidance_test.dart test/receipt_camera_result_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is saved-photo vertical quality:
  connect bottom-dark/bottom-soft diagnostics more directly to Add Next Section
  and long-receipt recovery so the user can fix only the bad section instead
  of retaking everything.

### Receipt Camera Reopen Pass 589: Bottom Section Recovery Emphasis Batch

Status: complete.

What changed:
- Added `prefersAddSection` to native saved-photo review warnings.
- Bottom-dark and bottom-soft saved-photo warnings now mark Add Section as the
  preferred recovery action.
- Receipt photo review now emphasizes Add Section when native bottom-section
  diagnostics say the lower receipt area may fail OCR.
- Preserved Retake and Crop as available actions, but made the long-receipt
  recovery path more direct when only the bottom portion is suspect.
- Added guards so bottom-section warnings keep steering users toward Add
  Section instead of only relying on generic coverage detection.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_quality_guidance_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_quality_guidance_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_quality_guidance_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is post-capture review affordance
  clarity: make sure the quality warning row, Retake, Crop, Add Section, and
  Next all remain visible, compact, and unambiguous for single and multi-photo
  receipt flows.

### Receipt Camera Reopen Pass 575: Explicit Backup Capture + Fast Review Paint Batch

Status: complete.

What changed:
- Restored an explicit phone-camera backup for cases where the Maintainiac
  native receipt camera or native bridge is unavailable, while keeping the
  Maintainiac native receipt camera as the primary path.
- Labeled backup capture as a backup in user-facing copy instead of silently
  swapping camera systems.
- Added privacy-safe diagnostics for phone-camera backup use:
  `phone_camera_backup`, `phone_camera_backup_receipt_photo`,
  `phoneCameraBackupUsed`, and backup photo count.
- Kept document scanning as an optional native fallback when the platform
  supports it, then phone camera as the last capture backup before existing
  photo import.
- Restored the review-screen picker import needed by the save-actions part file
  so Add Next Section can use the backup camera path.
- Updated receipt-camera guard tests so they enforce the professional behavior:
  native Maintainiac camera first, document-scanner fallback where supported,
  explicit phone-camera backup only when native capture is unavailable, and no
  legacy Flutter camera controller/preview path.
- Kept recent review-speed work in place: post-capture quality/storage preview
  work is scheduled after first paint instead of blocking the photo review
  screen from opening.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart test/receipt_native_camera_shell_test.dart`
- `flutter build apk --debug`
- `git diff --check`

Full-project note:
- `flutter analyze` for the full repo currently reports one unrelated generated
  work-supplies warning in
  `lib/screens/work_supplies/data/catalog/fencing/generated_fencing_detail_catalog.dart`.
  Camera-focused analyzer is clean, and this pass intentionally did not edit
  inventory/work-supplies while another workflow owns that area.

Remaining top-tier camera deliverable buckets:
- Native bridge parity: CameraX/AVFoundation focus, pinch zoom, exposure
  compensation, exposure reset, flash, back/close, lifecycle, and settings
  diagnostics.
- Capture quality: no darkened preview, no unnecessary blocking, clear
  tap-focus feedback, device-tiered live guidance, and old-device safe limits.
- Long receipt capture: ghost overlap slice, photo order, missing-bottom
  detection, duplicate/overlap evidence, manual adjustment, and graceful
  fallback to multiple OCR sources when stitching confidence is low.
- Image cleanup: grayscale/BW document modes, contrast, sharpening, deskew,
  perspective correction, glare/shadow warnings, OCR-original preservation, and
  separate storage-saving copies.
- OCR handoff: OCR from original/best capture, confidence/failure reasons,
  parsed-line review, business/personal/mixed routing, and recovery if the user
  is interrupted.
- Command One diagnostics: camera health, fallback rate, capture failure
  reasons, OCR failure/correction rates, device-tier problems, storage problems,
  and privacy-safe failure buckets.

Current planning estimate:
- Treat the remaining camera/OCR capture work by deliverable bucket instead of
  repeating a generic pass range. Current rough buckets:
  - Native camera quality and control parity: 35-60 bundled passes.
  - Fast review, crop/rotate, retake/add-photo, and exit safety: 30-50 bundled
    passes.
  - Long-receipt ghost-overlap, stitching, fallback, and ordering: 55-90 bundled
    passes.
  - OCR original-source handoff, confidence, parser-review entry, and
    diagnostics: 45-80 bundled passes.
  - Real-device Android/iOS hardening and regression evidence: 35-70 bundled
    passes.
- Current realistic remainder: roughly 200-350 bundled passes, but the stop
  rule is evidence-based. Stop early only when the camera, long-receipt,
  review, OCR handoff, diagnostics, and real-device gates are all passing.

## Latest Active Receipt Camera Status

Current latest completed pass: **Receipt Camera Reopen Pass 636**.

The detailed entries for Passes 569-636 are present earlier in this file:
- Pass 569: review exit and long-receipt copy.
- Pass 570: recovered capture single-OCR handoff.
- Pass 571: filled-review language consistency.
- Pass 572: no-line review recovery copy.
- Pass 573: native vertical quality diagnostic contract.
- Pass 575: explicit backup capture and fast review paint.
- Pass 576: native control contract parity.
- Pass 577: recovery control diagnostics preservation.
- Pass 578: attachment-gated recovery clear.
- Pass 579: single-photo completion gate.
- Pass 580: native settings surface naming.
- Pass 581: native visible control contract.
- Pass 582: native control diagnostics staging.
- Pass 583: camera UI health handoff labels.
- Pass 584: camera UI health attachment diagnostics.
- Pass 585: review lifecycle exit guard.
- Pass 586: native pre-capture exposure confirmation.
- Pass 587: Android receipt still-capture quality.
- Pass 588: brightness assist outcome warning.
- Pass 589: bottom section recovery emphasis.
- Pass 590: post-capture next-step affordance clarity.
- Pass 591: review action language and accessibility clarity.
- Pass 592: stale read-label cleanup.
- Pass 593: Android native settings choice controls.
- Pass 594: native save-space choice staging handoff.
- Pass 595: iOS native settings parity.
- Pass 596: native review-depth handoff.
- Pass 597: receipt-photo add action wording consistency.
- Pass 598: compact recovery add-photo action clarity.
- Pass 599: proof data-saver level handoff metadata.
- Pass 600: OCR-source proof data-saver signal.
- Pass 601: small proof-copy OCR review risk flags.
- Pass 602: small proof-copy OCR warning guidance.
- Pass 603: duplicate import-action OCR handoff parity.
- Pass 604: duplicate native recovery and UI-health parity.
- Pass 605: OCR handoff helper parity guard.
- Pass 606: duplicate scanner-decision OCR risk parity.
- Pass 607: executable scanner-decision OCR risk coverage.
- Pass 608: native camera diagnostic naming cleanup.
- Pass 609: scanner-prep OCR review guidance.
- Pass 610: scanner-prep decode/skipped warning coverage.
- Pass 611: scanner-prep handoff status.
- Pass 612: scanner-prep Command One handoff telemetry coverage and
  multi-receipt customer-redaction rule capture.
- Pass 613: privacy-safe customer proof/redaction OCR line-reference contract.
- Pass 614: client-proof redaction telemetry and local/cloud accuracy-pack rule
  capture.
- Pass 615: client-proof redaction diagnostics handoff.
- Pass 616: local/cloud parser-pack disclosure policy.
- Pass 617: parser-pack Command One telemetry promotion.
- Pass 618: receipt-line proof selection contract.
- Pass 619: selected receipt-line bundle contract.
- Pass 620: parsed materials receipt selection bundles.
- Pass 621: selected-line Command One telemetry promotion.
- Pass 622: selected-line privacy event history.
- Pass 623: parsed materials selection privacy-event builders.
- Pass 624: client-proof redaction plan contract.
- Pass 625: client-proof redaction-plan Command One telemetry.
- Pass 626: client-proof redaction-plan privacy event history.
- Pass 627: client-proof review summary contract.
- Pass 628: client-proof source-section image review plan.
- Pass 629: client-proof image review privacy diagnostics.
- Pass 630: Hive-backed native capture recovery safety.
- Pass 631: native capture recovery freshness buckets.
- Pass 632: interrupted native capture freshness UI and diagnostics.
- Pass 633: native recovery freshness/status OCR-source handoff signals.
- Pass 634: receipt-reader recovery freshness/status count aggregation.
- Pass 635: expense telemetry promotion for recovery freshness/status buckets.
- Pass 636: Command One recovery freshness/status health aggregation.

Current next camera/OCR focus:
- Continue camera/OCR only.
- Continue tightening OCR-source handoff and review routing so recovered,
  stitched, and capability-gated receipt photos carry enough privacy-safe health
  context into OCR, assisted receipt review, and Command One health summaries
  without exposing receipt content.

### Receipt Camera Reopen Pass 636: Recovery Freshness Command One Aggregation Batch

Status: complete.

What changed:
- Added recovery freshness counts to the expense telemetry health snapshot.
- Added recovery storage-status counts to the expense telemetry health snapshot.
- Added top recovery freshness and top recovery storage-status fields for
  Command One summary cards.
- Extended schema and snapshot tests so the new buckets survive `toMap()`.

Validation:
- `dart format lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart test/helpers/expense_telemetry_schema_expectations.dart`
- `flutter test test/expense_screen_telemetry_test.dart --name "builds command center summary without private receipt details"`
- `flutter test test/expense_screen_telemetry_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart test/helpers/expense_telemetry_schema_expectations.dart`
- `flutter build apk --debug`
- `git diff --check`

### Receipt Camera Reopen Pass 635: Recovery Freshness Expense Telemetry Batch

Status: complete.

What changed:
- Promoted native recovery freshness buckets into expense receipt photo
  preparation telemetry.
- Promoted native recovery storage-status buckets into expense receipt photo
  preparation telemetry.
- Added the same buckets to non-failure recovery telemetry for accepted/closed
  interrupted capture review paths.
- Extended privacy-policy and source-guard coverage so these buckets remain
  content-free diagnostic metadata.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/expense_screen_telemetry_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart --name "allows only content-free receipt camera health metadata"`
- `flutter test test/receipt_camera_capture_layout_test.dart test/expense_screen_telemetry_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/expense_screen_telemetry_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter build apk --debug`
- `git diff --check`

### Receipt Camera Reopen Pass 634: Recovery Freshness Count Aggregation Batch

Status: complete.

What changed:
- Added privacy-safe native recovery freshness counts to receipt-reader handoff
  counts and metadata.
- Added privacy-safe native recovery storage-status counts to receipt-reader
  handoff counts and metadata.
- Extended OCR-source attachment coverage so stale/partial recovered receipt
  photos are visible as document signals and OCR-source risk flags.
- Kept the aggregation content-free: it counts freshness/status buckets only,
  never receipt text, prices, vendors, addresses, or line descriptions.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter build apk --debug`
- `git diff --check`

### Receipt Camera Reopen Pass 633: Recovery Freshness OCR-Source Handoff Batch

Status: complete.

What changed:
- Added native recovery freshness tokens to OCR-source document signals.
- Added native recovery storage-status tokens to OCR-source document signals.
- Added OCR-source risk flags for stale/very-stale recovery and partial/missing
  local photo recovery.
- Extended guard coverage so recovery freshness/status stays attached after
  recovered photos move from review into OCR-source attachments.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_flow.dart test/receipt_camera_capture_layout_test.dart docs/receipt_camera_ocr_master_pass_plan.md`
- `flutter test test/receipt_capture_flow_shareability_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_flow.dart test/receipt_camera_capture_layout_test.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter build apk --debug`
- `git diff --check`

### Receipt Camera Reopen Pass 632: Interrupted Native Capture Freshness UI Batch

Status: complete.

What changed:
- Added user-facing freshness wording for interrupted native capture recovery
  records: recently saved, saved earlier, older saved receipt, and very old saved
  receipt.
- Surfaced recovery freshness in the resume banner so a user can tell whether
  staged receipt photos are recent or old before resuming or discarding.
- Added privacy-safe recovery dismissal metadata for freshness, storage status,
  existing local photo count, and missing local photo count.
- Added guard coverage proving the banner uses freshness and does not expose
  receipt text.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart test/receipt_native_capture_staging_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter test test/receipt_native_capture_staging_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_native_capture_staging_test.dart test/receipt_capture_flow_shareability_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart test/receipt_native_capture_staging_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter build apk --debug`
- `git diff --check`

### Receipt Camera Reopen Pass 631: Native Capture Recovery Freshness Buckets Batch

Status: complete.

What changed:
- Added deterministic age and freshness helpers to interrupted native capture
  recovery records.
- Classified recovery age as `fresh`, `aging`, `stale`, or `very_stale` so the
  app can later prioritize old interrupted receipt captures without inspecting
  receipt content.
- Added the freshness bucket to privacy-safe recovery evidence labels.
- Added regression coverage for freshness boundary behavior and content-free
  evidence labels.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_native_capture_staging_test.dart`
- `flutter test test/receipt_native_capture_staging_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_native_capture_staging_test.dart`

### Receipt Camera Reopen Pass 630: Hive-Backed Native Capture Recovery Safety Batch

Status: complete.

What changed:
- Added recovery-safety metadata to the native capture Hive recovery index.
- Carried recovery-safety metadata into recovered native capture records, so a
  manifest-missing interrupted capture still reports whether local staged photos
  exist and whether the recovery evidence is privacy-scoped.
- Extended privacy-safe recovery evidence labels with Hive-index and recovery
  scope status.
- Added regression coverage proving Hive-only recovery keeps local photo safety
  evidence without storing receipt text or customer content.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_capture_recovery_store.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_native_capture_staging_test.dart`
- `flutter test test/receipt_native_capture_staging_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_capture_recovery_store.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_native_capture_staging_test.dart`

### Receipt Camera Reopen Pass 629: Client-Proof Image Review Privacy Diagnostics Batch

Status: complete.

What changed:
- Added a privacy-safe receipt event builder for client-proof image review
  plans.
- Added content-free image-review status and source-section count fields to
  local receipt privacy events.
- Aggregated image-review status/counts in receipt privacy health snapshots and
  Command One maps.
- Added regression coverage proving the image-review diagnostics expose only
  status/counts, not receipt text, merchant names, item descriptions, prices, or
  customer content.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_privacy_event.dart lib/screens/expenses/data/expense_receipt_privacy_event_store.dart test/receipt_privacy_event_test.dart test/receipt_privacy_event_store_test.dart`
- `flutter test test/receipt_privacy_event_test.dart test/receipt_privacy_event_store_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_receipt_privacy_event.dart lib/screens/expenses/data/expense_receipt_privacy_event_store.dart test/receipt_privacy_event_test.dart test/receipt_privacy_event_store_test.dart`

### Receipt Camera Reopen Pass 628: Client-Proof Source-Section Image Review Plan Batch

Status: complete.

What changed:
- Added source-section image review summaries for client-safe receipt proof
  workflows.
- Grouped visible, hidden, and review-required line counts by receipt photo or
  source section so later crop/redaction UI can identify which source image
  needs attention.
- Fixed selected `redact_by_default` lines so they stay hidden even when a
  downstream flow explicitly includes them in a redaction plan.
- Exposed the image review plan from parsed work-supply receipt drafts.
- Added regression coverage proving section-level proof planning stays
  content-free.

Validation:
- `dart format lib/shared/receipts/receipt_processing_contract.dart lib/screens/work_supplies/data/work_supply_parsed_receipt_bridge.dart test/receipt_processing_contract_test.dart test/work_supply_parsed_receipt_bridge_test.dart`
- `flutter test test/receipt_processing_contract_test.dart test/work_supply_parsed_receipt_bridge_test.dart`
- `flutter analyze lib/shared/receipts/receipt_processing_contract.dart lib/screens/work_supplies/data/work_supply_parsed_receipt_bridge.dart test/receipt_processing_contract_test.dart test/work_supply_parsed_receipt_bridge_test.dart`
