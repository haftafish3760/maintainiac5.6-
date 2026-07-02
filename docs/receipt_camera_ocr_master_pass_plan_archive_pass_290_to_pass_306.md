# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 290 / Total Pass 370: Accepted Photo Handoff Health Batch

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 290 / Total Pass 370: Accepted Photo Handoff Health Batch

Status: complete.

What changed:
- Added accepted-photo quality handoff outcomes to the receipt review result:
  ready for receipt review, needs review before OCR, critical quality retake
  recommended, possible partial receipt, stitch fallback sections, and missing
  quality signal.
- Added user-facing handoff action/evidence labels so the review flow has one
  deterministic decision for what should happen after accepted receipt photos.
- Recorded privacy-safe accepted-photo handoff outcome counts in OCR-start
  telemetry and surfaced top accepted-photo outcome in the expense telemetry
  health snapshot and Command Center payload.
- Kept the Firestore sanitizer and redaction contract aligned so Command One
  can receive the new health fields without receipt content.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart test/maintainiac_firestore_documents_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart test/maintainiac_firestore_documents_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart test/maintainiac_firestore_documents_test.dart test/receipt_camera_capture_layout_test.dart`

Next camera-only focus:
- Continue camera capture/review hardening around saved-photo quality,
  section-order confidence, and long-receipt handoff behavior before PDF work.

### Receipt Camera Reopen Pass 291 / Total Pass 371: Accepted Photo Handoff UI Batch

Status: complete.

What changed:
- Wired accepted-photo handoff action copy into the receipt-read status message
  shown while app-assisted receipt reading starts.
- Added a separate action chip to the expense receipt handoff panel so users
  see both the review route and the specific next check before the filled
  receipt details review opens.
- Preserved the existing saved-proof and OCR-source handoff flow; this pass
  only made the next action explicit and consistent with the telemetry outcome.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart`

Next camera-only focus:
- Continue hardening long-receipt ordering/stitch fallback diagnostics and keep
  all next-step copy aligned with the receipt review route.

### Receipt Camera Reopen Pass 292 / Total Pass 372: Long Receipt Stitch Health Snapshot Batch

Status: complete.

What changed:
- Aggregated long-receipt stitch status, fallback reason, and confidence bucket
  from OCR-start metadata into the expense telemetry health snapshot.
- Added top stitch status, top fallback reason, and top stitch confidence bucket
  to the Command Center payload so Command One can show whether long receipts
  are stitching, falling back to ordered sections, or matching poorly.
- Kept stitch diagnostics privacy-safe: only operational codes and counts are
  preserved, not receipt text or images.
- Updated schema expectations, Firestore summary sanitizer, redaction map
  fields, and focused telemetry tests.

Validation:
- `dart format lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart test/maintainiac_firestore_documents_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart test/maintainiac_firestore_documents_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart test/maintainiac_firestore_documents_test.dart`

Next camera-only focus:
- Continue improving long-receipt review confidence and any remaining native
  camera capture/review diagnostics before PDF work.

### Receipt Camera Reopen Pass 293 / Total Pass 373: Long Receipt Pair Diagnostic Health Batch

Status: complete.

What changed:
- Added `stitchPairDiagnosticCounts` to receipt review results so long-receipt
  matching evidence is summarized from each photo pair and safe stitch
  fallback.
- Added pair-level stitch diagnostics to OCR-start telemetry and the expense
  telemetry health snapshot.
- Surfaced top stitch pair diagnostic in the Command Center payload so Command
  One can distinguish zoom adjustment, straightening adjustment, no repeated
  text, manual overlap, and fallback reasons without receipt content.
- Updated Firestore sanitizer/redaction contracts and focused tests to preserve
  these privacy-safe operational codes.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart test/maintainiac_firestore_documents_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart test/maintainiac_firestore_documents_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart test/maintainiac_firestore_documents_test.dart test/receipt_camera_capture_layout_test.dart`

Next camera-only focus:
- Continue improving native camera capture/review diagnostics and long-receipt
  confidence before PDF work.

### Receipt Camera Reopen Pass 294 / Total Pass 374: Native Capability Policy Health Batch

Status: complete.

What changed:
- Added native camera capability policy codes to the receipt camera session
  config so each capture can explain why heavier features were enabled or
  limited for that device.
- Sent those policy codes through the native method-channel arguments and
  merged them into returned capture diagnostics.
- Preserved policy codes through native capture staging and recovery while
  keeping the allowlist privacy-safe.
- Counted capability policy codes in OCR-start telemetry and surfaced the top
  policy code in the Command Center / Firestore summary payload.

Validation:
- `dart format test/receipt_native_camera_contract_test.dart`
- `flutter test test/receipt_native_camera_contract_test.dart test/receipt_native_capture_staging_test.dart test/expense_screen_telemetry_test.dart test/maintainiac_firestore_documents_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/helpers/expense_telemetry_schema_expectations.dart test/receipt_native_camera_contract_test.dart test/receipt_native_capture_staging_test.dart test/expense_screen_telemetry_test.dart test/maintainiac_firestore_documents_test.dart test/receipt_camera_capture_layout_test.dart`

Next camera-only focus:
- Continue device-specific native camera diagnostics and capture/review
  hardening before PDF work.

### Receipt Camera Reopen Pass 295 / Total Pass 375: Native Camera Pipeline Health Batch

Status: complete.

What changed:
- Added OCR-start telemetry buckets for the native camera engine, device policy,
  workload tier, and resolution tier used by accepted receipt captures.
- Aggregated those buckets into the expense telemetry health snapshot so
  Command One can show which native camera path is actually being used across
  devices.
- Surfaced top native camera engine, device policy, workload tier, and
  resolution tier in the Command Center / Firestore summary payload.
- Updated Firestore sanitizing and schema expectations so the new fields stay
  privacy-safe and cannot drift silently.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart test/maintainiac_firestore_documents_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart test/maintainiac_firestore_documents_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart test/maintainiac_firestore_documents_test.dart test/receipt_camera_capture_layout_test.dart`

Next camera-only focus:
- Continue hardening saved-photo quality diagnostics and native camera review
  guidance before PDF work.

### Receipt Camera Reopen Pass 296 / Total Pass 376: Saved Photo Warning Action Health Batch

Status: complete.

What changed:
- Added action codes to native saved-photo review warnings so dim, dark, blur,
  and glare problems map to concrete operational actions.
- Added `savedPhotoWarningActionCounts` to app-assisted receipt OCR-start
  telemetry.
- Aggregated saved-photo warning action counts and top action code into the
  expense telemetry health snapshot.
- Surfaced warning action counts and top warning action code in the Command
  Center / Firestore summary payload.
- Updated privacy/schema expectations and source guards so the warning action
  path stays content-free and cannot silently drift.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart test/maintainiac_firestore_documents_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart test/maintainiac_firestore_documents_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart test/maintainiac_firestore_documents_test.dart test/receipt_camera_capture_layout_test.dart`

Next camera-only focus:
- Continue camera-only hardening around review guidance and native capture
  failure/recovery behavior before PDF work.

### Receipt Camera Reopen Pass 297 / Total Pass 377: Native Capture Failure Diagnostic Callback Batch

Status: complete.

What changed:
- Added a shared receipt-panel callback for content-free native capture
  diagnostics.
- Emitted code-only diagnostics for camera permission denial, unavailable
  native capabilities, no returned photos, staging failures, missing native
  plugin, platform errors, user cancellation, and unexpected open failures.
- Wired the expense receipt screen to record those diagnostics as
  `imageAttachFailure` telemetry with confirmed failure causes and recovery
  actions for Command One.
- Added allowlisted metadata keys for native capture failure stage, reason,
  recovery action, engine, permission state, availability, and rear-camera
  availability.
- Added tests proving the metadata is content-free and the shared panel stays
  wired to the expense screen telemetry callback.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_attachment_panel_actions_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_attachment_panel_actions_test.dart`

Next camera-only focus:
- Continue hardening native capture recovery/resume and review guidance before
  PDF work.

### Receipt Camera Reopen Pass 298 / Total Pass 378: Stale Recovery Diagnostic Batch

Status: complete.

What changed:
- Added native capture recovery diagnostics when an interrupted receipt capture
  record points to staged photos that are no longer on the device.
- The recovery path now reports `native_capture_recovery`,
  `recovery_photos_missing`, and `retake_receipt_photos` through the shared
  diagnostic callback before showing the user-facing retake message.
- Added source guards proving the stale recovery path remains wired to the
  content-free telemetry callback.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart test/receipt_attachment_panel_actions_test.dart`
- `flutter test test/receipt_attachment_panel_actions_test.dart test/expense_screen_telemetry_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/receipt_attachment_panel_actions_test.dart test/expense_screen_telemetry_test.dart test/expense_receipt_assisted_review_flow_test.dart`

Next camera-only focus:
- Continue hardening native capture recovery/resume, especially successful
  recovery completion and cleanup evidence, before PDF work.

### Receipt Camera Reopen Pass 299 / Total Pass 379: Successful Recovery Resume Health Batch

Status: complete.

What changed:
- Tagged successful interrupted native capture recovery when recovered photos
  enter receipt review.
- Added recovery resume status, recovered-photo total, and multiple-section
  count to OCR-start telemetry.
- Aggregated recovery resume status and counts into the Command Center health
  snapshot.
- Added the recovery resume metrics to the Firestore summary allowlist and
  schema expectations.
- Updated source guards so recovered photo paths keep code-only recovery
  diagnostics without private receipt content.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart test/maintainiac_firestore_documents_test.dart test/receipt_attachment_panel_actions_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart test/maintainiac_firestore_documents_test.dart test/receipt_attachment_panel_actions_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart test/maintainiac_firestore_documents_test.dart test/receipt_attachment_panel_actions_test.dart`

Next camera-only focus:
- Continue hardening native capture recovery cleanup and review guidance before
  PDF work.

### Receipt Camera Reopen Pass 300 / Total Pass 380: Recovery Discard Classification Batch

Status: complete.

What changed:
- Added content-free diagnostics when the user dismisses an interrupted native
  receipt capture instead of resuming it.
- Included discarded-photo count and multi-section state without storing receipt
  image content, receipt text, paths, names, or private notes in telemetry.
- Routed `user_discarded_recovery` through `addExpenseAbandoned` instead of
  `imageAttachFailure` so Command One does not inflate camera failure rate for a
  deliberate discard.
- Kept true native camera failures on `imageAttachFailure`.
- Updated source guards for the shared receipt panel, diagnostic callback, and
  expense receipt telemetry routing.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/receipt_attachment_panel_actions_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/receipt_attachment_panel_actions_test.dart test/expense_receipt_assisted_review_flow_test.dart test/expense_screen_telemetry_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/receipt_attachment_panel_actions_test.dart test/expense_receipt_assisted_review_flow_test.dart test/expense_screen_telemetry_test.dart`

Next camera-only focus:
- Continue hardening review flow behavior around retained photos, back/cancel
  handling, and capture-result handoff before PDF work.

### Receipt Camera Reopen Pass 301 / Total Pass 381: Review Exit Safety Copy Batch

Status: complete.

What changed:
- Tightened the receipt photo review exit dialog so the safe path is explicit:
  `Next: Review Receipt Details`.
- Renamed destructive exit actions from vague discard wording to
  `Delete Staged Photo` / `Delete Staged Photos`.
- Updated the exit warning to explain that deleting staged photos is only for
  retaking the receipt.
- Kept the review back path protected by the existing confirmation instead of
  silently dropping photos.
- Updated layout/source guards for the safer receipt-review exit contract.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_attachment_panel_actions_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart test/receipt_attachment_panel_actions_test.dart`

Next camera-only focus:
- Continue hardening capture-result handoff, photo quality guidance, and review
  readiness before PDF work.

### Receipt Camera Reopen Pass 302 / Total Pass 382: Quality Score Meaning Batch

Status: complete.

What changed:
- Added `reviewScoreMeaningLabel` to receipt photo quality checks so the app
  explains what the quality score means.
- Made readable and soft-warning photos explicitly say the score is guidance,
  not a hard blocker.
- Kept truly unsafe photos saying retake is safer before app-assisted review.
- Surfaced the score meaning in the receipt photo review tray and quality
  recovery strip.
- Updated quality guidance and layout guards so a 70-80 score can still move
  forward when the receipt text is readable.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_quality_guidance_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_quality_guidance_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_quality_guidance_test.dart test/receipt_camera_capture_layout_test.dart`

Next camera-only focus:
- Continue hardening capture brightness/exposure diagnostics and review
  confidence before PDF work.

### Receipt Camera Reopen Pass 303 / Total Pass 383: Saved Capture Diagnostic Health Batch

Status: complete.

What changed:
- Promoted saved-capture brightness, sharpness, exposure mismatch, and quality
  signal buckets from OCR-start metadata into the Command Center health
  snapshot.
- Added top saved-capture brightness, sharpness, exposure mismatch, and quality
  signal fields so Command One can quickly show what is wrong with receipt
  photos.
- Added the new bucket fields to Firestore summary allowlists and redaction
  map rules.
- Updated schema expectations and tests so these health fields cannot silently
  drift or drop from Command One.
- Kept all fields code-only and content-free: no receipt image, receipt text,
  store names, item descriptions, or private user content.

Validation:
- `dart format lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart test/maintainiac_firestore_documents_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart test/maintainiac_firestore_documents_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart test/maintainiac_firestore_documents_test.dart`

Next camera-only focus:
- Continue hardening native camera exposure behavior and saved-photo review
  feedback before PDF work.

### Receipt Camera Reopen Pass 304 / Total Pass 384: Live Exposure Assist Health Batch

Status: complete.

What changed:
- Promoted live native exposure-assist diagnostics from OCR-start metadata into
  the Command Center health snapshot.
- Added health buckets for auto exposure decisions, preview brightness,
  exposure candidate state, and exposure assist status.
- Added counters for exposure candidate frames and manual brightness changes so
  Command One can show when users or the camera are fighting dim preview.
- Added top exposure-assist fields for fast Command One summaries.
- Updated Firestore summary allowlists, redaction map rules, schema
  expectations, and telemetry tests so these fields stay privacy-safe and do
  not drift.
- Kept all fields code-only and content-free: no receipt image, receipt text,
  merchant names, line items, notes, addresses, or private user content.

Validation:
- `dart format lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart test/maintainiac_firestore_documents_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart test/maintainiac_firestore_documents_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart test/maintainiac_firestore_documents_test.dart`

Next camera-only focus:
- Continue hardening native camera exposure behavior, review brightness
  feedback, and capture-to-review handoff before PDF work.

### Receipt Camera Reopen Pass 305 / Total Pass 385: Preview Brightness And Next Handoff Copy Batch

Status: complete.

What changed:
- Reduced the native camera shell vignette so the live preview is not visually
  darkened as heavily by Maintainiac's own UI chrome.
- Expanded the clear center preview area so the receipt stays visually primary
  while top and bottom controls remain readable.
- Tightened the single-photo review tray copy so the primary path is explicit:
  tap Next to review item prices.
- Tightened the multi-photo review tray copy so users understand they can tap
  Next or first check order/add another receipt section.
- Added source guards so future passes do not reintroduce the heavy camera
  darkening or vague after-photo copy.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_camera_shell.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_help_flow_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart test/receipt_native_camera_shell_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_camera_shell.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart test/receipt_native_camera_shell_test.dart`

Next camera-only focus:
- Continue hardening native camera preview controls, manual capture reliability,
  and capture-to-review navigation before PDF work.

### Receipt Camera Reopen Pass 306 / Total Pass 386: Native Preview Chrome Weight Batch

Status: complete.

What changed:
- Reduced Android CameraX receipt guide opacity so the guide is assistive
  instead of dominating the receipt preview.
- Reduced Android guidance, settings strip, exposure slider, previous-section
  guide, and bottom control chrome opacity so the live camera view stays
  brighter.
- Reduced iOS AVFoundation receipt guide, guidance label, settings strip,
  exposure controls, previous-section guide, and bottom bar opacity to match
  the lighter Android camera surface.
- Left dynamic edge-detection highlight colors intact so actual receipt edge
  feedback can still become prominent when the camera detects useful edges.
- Added Android, iOS, and Flutter shell source guards to prevent the heavy
  always-on preview darkening from coming back.

Validation:
- `dart format test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_native_camera_shell_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_camera_shell.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_native_camera_shell_test.dart`

Next camera-only focus:
- Continue hardening native capture controls, manual shutter behavior, and
  capture result review flow before PDF work.
