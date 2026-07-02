# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 570: Recovered Capture Single-OCR Handoff Batch

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 570: Recovered Capture Single-OCR Handoff Batch

Status: complete.

What changed:
- Fixed the recovered native capture path so it no longer starts app-assisted
  receipt reading twice after a recovered receipt photo is accepted.
- Kept recovered photos on the same shared acceptance path as normal captures:
  attach reviewed photos, publish the attachment change, notify the expense
  entry screen, start read status, read OCR source images, then clean temporary
  OCR photos.
- Added a guard test proving `_resumeRecoverableNativeCapture` delegates to
  `_acceptReviewedPhotoResult(...)` and does not directly call
  `_readReviewedPhotosForReceiptForm(...)` itself.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter test test/receipt_capture_flow_shareability_test.dart --name "accepted camera photo starts filled receipt review before OCR work finishes"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is tightening the user-facing handoff
  path after "Next" so every accepted photo makes the filled receipt review
  destination obvious and keeps the review state recoverable if OCR is slow,
  unreadable, or interrupted.

### Receipt Camera Reopen Pass 571: Filled-Review Language Consistency Batch

Status: complete.

What changed:
- Replaced remaining user-facing "add another photo" action copy in the camera
  and receipt review flow with "Add Next Section" where the action means
  continuing a long receipt.
- Renamed the native camera setting label from "Saved copy size" to
  "Space-saving proof size" so the storage/data-saving control reads like a
  receipt proof setting instead of a vague file label.
- Kept the accepted-photo destination explicit: the post-capture action still
  says "Next: Review Receipt Details" and guidance says Next opens the filled
  receipt review.
- Updated the expense unreadable-photo recovery copy so it points to retake,
  Add Next Section, or manual entry without implying a hidden/discarded photo.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_entry_screen.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart test/receipt_capture_flow_shareability_test.dart`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is runtime back/close and review-state
  resilience: make sure slow OCR, unreadable OCR, and interrupted review states
  keep the user in the filled receipt review area with clear next actions.

### Receipt Camera Reopen Pass 572: No-Line Review Recovery Copy Batch

Status: complete.

What changed:
- Tightened the no-line/unreadable receipt next-step copy so the user is told
  to retake, use Add Next Section for a continuing receipt, or enter the
  receipt manually.
- Rechecked the slow OCR handoff panel and filled-review panel so accepted
  photos continue to keep the user oriented in the receipt review area while
  OCR is running or when OCR cannot produce safe lines.
- Confirmed no remaining user-facing camera/receipt review copy uses stale
  "add another photo", "Saved copy size", "Back to receipt form", or
  "Leave For Later" wording. The only remaining "add another photo" match is a
  test name.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_entry_screen.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --name "assisted expense receipt review exposes whole receipt choices"`
- `rg -n "add another receipt photo|add another photo|Add another photo|Saved copy size|Back to receipt form|Leave For Later" lib/shared/widgets/receipt_capture lib/screens/expenses/entry test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart test/receipt_capture_flow_shareability_test.dart test/expense_receipt_assisted_review_flow_test.dart -g "*.dart"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is native preview/capture quality
  instrumentation and device-tier behavior so darker/blurry native captures can
  be diagnosed with concrete brightness, exposure, focus, and quality signals.

### Receipt Camera Reopen Pass 573: Native Vertical Quality Diagnostic Contract Batch

Status: complete.

What changed:
- Promoted native captured-photo vertical quality keys into
  `ReceiptCaptureDiagnosticKeys`: top luma, middle luma, bottom luma, bottom
  edge score, and vertical quality signal.
- Updated the native capture staging allowlist to use those stable keys, keeping
  bottom-dark and bottom-soft evidence available after staging/recovery without
  exposing receipt content.
- Kept Android CameraX and iOS AVFoundation payloads aligned: both return
  captured photo dimensions, average luma, edge score, top/middle/bottom luma,
  bottom edge score, vertical quality signal, brightness/sharpness buckets, and
  live-vs-captured exposure mismatch.
- Updated parser-impact guidance to use "Add Next Section" for clearer bottom
  sections instead of stale generic add-photo wording.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_camera_capture_layout_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is using these native quality signals to
  improve the post-capture review decision: bottom-dark, bottom-soft, and
  live-preview-vs-captured mismatch should lead to clear retake/review guidance
  and privacy-safe health metrics.

### Receipt Camera Reopen Pass 568: Native Capture Preview And Exposure Baseline Batch

Status: complete.

What changed:
- Kept receipt capture on Maintainiac-owned native camera surfaces:
  Android CameraX and iOS AVFoundation. No Flutter `camera:` package or stock
  phone camera controller was introduced.
- Changed Android CameraX preview from center-fill to full-frame fit mode so a
  receipt is less likely to appear centered while useful paper area is cropped
  out of the live preview.
- Changed iOS AVFoundation preview to full-frame aspect mode for the same
  reason.
- Reduced native capture-screen obstruction on both platforms:
  smaller top/bottom bars, smaller brightness strip, lighter overlay opacity,
  smaller long-receipt guide, and a smaller shutter footprint.
- Moved Android normal/high-tier still capture to quality-first
  `CAPTURE_MODE_MAXIMIZE_QUALITY`; low-tier devices keep the faster capture
  path.
- Made live and pre-capture exposure assist start brightening earlier on both
  platforms so dark receipt frames get help before the captured photo is already
  visibly too dim.
- Added privacy-safe diagnostics for the native preview/control contract:
  `nativePreviewScaleMode` and `nativeControlDensity`.
- Added the missing `Receipt Sections` label constant and wired it into the
  long-receipt action rail.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_section_labels.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_section_labels.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check`

Blocked verification:
- `cd android && ./gradlew :app:compileDebugKotlin` could not run because this
  Mac session reports no Java runtime. This is an environment blocker, not a
  Dart/source-test failure.

Next camera/OCR focus:
- Continue camera/OCR only. Next target is runtime back/close behavior and
  accepted-photo continuity: camera back must return cleanly, accepted photos
  must not be silently discarded, and the next step after accepting a photo must
  stay pointed at app-assisted receipt detail review.

### Receipt Camera Reopen Pass 567: Command One OCR Source Handoff Aggregation Batch

Status: complete.

What changed:
- Aggregated accepted-photo OCR source handoff buckets into the expense health
  snapshot and Command One map.
- Added dashboard-safe counts for OCR handoff status, handoff signals, stitching
  source signals, scanner source decisions, and photo-quality risk signals.
- Added top bucket fields so Command One can show the dominant camera/OCR source
  problem without exposing receipt text, merchant names, totals, file paths, or
  image content.
- Wired OCR completed/failed and parser completed/review/failed telemetry to
  include the privacy-safe source handoff buckets already produced by the
  receipt capture and OCR layers.
- Updated the telemetry schema guard and manual Firestore sanitizer snapshot so
  the new fields stay part of the verified contract.

Validation:
- `dart format lib/screens/expenses/data/expense_screen_telemetry.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart test/maintainiac_firestore_documents_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart test/maintainiac_firestore_documents_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart --name "summarizes OCR source handoff buckets for Command One without content"`
- `flutter test test/expense_screen_telemetry_test.dart --name "allows only content-free receipt camera health metadata"`
- `flutter test test/expense_screen_telemetry_test.dart --name "builds command center summary without private receipt details"`
- `flutter test test/expense_screen_telemetry_test.dart --name "summarizes parser category health for Command 1 without receipt content"`
- `flutter test test/expense_receipt_parser_test.dart --name "parses expense fields from OCR parser-ready receipt signals"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is native camera bridge and receipt-flow
  runtime behavior: tap-focus/pinch-zoom/exposure/back/close diagnostics,
  accepted-photo continuity, and keeping the next step pointed at app-assisted
  receipt review instead of returning to the expense home screen.

### Receipt Camera Reopen Pass 565: Accepted Photo To Parser Continuity Batch

Status: complete.

What changed:
- Added a privacy-safe receipt-reader handoff metadata contract on
  `ReceiptPhotoReviewResult` so accepted photos carry the same evidence into
  OCR start telemetry and parser handoff diagnostics.
- The contract records only operational counts and tokens: saved proof/OCR
  source integrity, stitch status, scanner preparation decisions, coverage
  status counts, saved-photo warning counts, parser-risk counts, and stitch pair
  diagnostic counts.
- Wired that handoff metadata into expense OCR-start telemetry before OCR reads
  the accepted photos.
- Added handoff tokens to OCR-source attachment signals so shared camera/OCR
  consumers can distinguish ready, partial, separate OCR source, stitched, and
  fallback handoffs without reading expense-screen state.
- Removed an unused receipt review label helper caught by analyzer while
  verifying this pass.
- Kept the handoff private: no receipt text, merchant/vendor names, item
  descriptions, addresses, phone numbers, notes, prices, local file paths, or
  user identifiers are recorded.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_photo_review_section_labels.dart test/receipt_camera_result_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture lib/screens/expenses test/receipt_camera_result_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_capture_layout_test.dart test/expense_screen_telemetry_test.dart`
- `flutter test test/receipt_camera_result_test.dart --name "photo review results freeze accepted camera diagnostics"`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --name "assisted expense receipt review exposes whole receipt choices"`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "reviewed receipt photos announce app fill handoff safely"`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "post-capture quality copy leads with action and evidence"`
- `flutter test test/expense_screen_telemetry_test.dart --name "allows only content-free receipt camera health metadata"`
- `flutter test test/expense_screen_telemetry_test.dart --name "builds command center summary without private receipt details"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is OCR-result continuity: carry the
  accepted-photo handoff contract through OCR completion diagnostics so Command
  One can compare what was accepted, what OCR read, and what the parser could
  safely use without exposing receipt content.

### Receipt Camera Reopen Pass 566: OCR Result Continuity Batch

Status: complete.

What changed:
- Added `ReceiptOcrSourceHandoffSummary`, derived from OCR-source attachment
  signals and risk flags, so OCR results retain the accepted-photo handoff
  context after text recognition finishes.
- Exposed privacy-safe OCR source handoff diagnostics on
  `ReceiptOcrDiagnostics`: status, handoff signal counts, stitch signal counts,
  scanner decision counts, photo-quality risk counts, and a versioned contract.
- Threaded the same OCR source handoff fields through
  `ExpenseReceiptParseDiagnostics` so parse review and downstream privacy
  events can compare accepted capture evidence with OCR/parser output.
- Added the OCR source handoff buckets to `PrivacySafeReceiptEvent` for both
  OCR-result and parse-result events.
- Kept the bridge content-free: only operational tokens/counts are kept; no
  receipt text, merchant/vendor names, item descriptions, addresses, phone
  numbers, notes, prices, local paths, or user identifiers are recorded.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/data/expense_receipt_privacy_event.dart lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart test/receipt_ocr_service_test.dart test/receipt_privacy_event_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/data/expense_receipt_privacy_event.dart lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart test/receipt_ocr_service_test.dart test/receipt_privacy_event_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --name "ocr result carries accepted photo handoff signals without receipt content"`
- `flutter test test/receipt_privacy_event_test.dart --name "OCR privacy event carries source handoff buckets without receipt content"`
- `flutter test test/receipt_privacy_event_test.dart --name "OCR privacy event keeps warning categories but no receipt text"`
- `flutter test test/expense_receipt_parser_test.dart --name "parses expense fields from OCR parser-ready receipt signals"`
- `flutter test test/expense_parser_failure_diagnostics_test.dart --name "prioritizes OCR parser task buckets as exact handoff causes"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is Command One aggregation for OCR
  source handoff status and risk buckets so accepted-photo issues, stitching
  fallback, scanner decisions, and parser results can be compared at health
  dashboard level without exposing receipt content.

### Receipt Camera Reopen Pass 559: Camera Result Diagnostics Bridge Batch

Status: complete.

What changed:
- Preserved native capture evidence from `ReceiptCameraResult`
  fallback/document-scanner paths as per-photo diagnostic maps.
- The review flow now carries brightness, sharpness, exposure mismatch, zoom,
  focus/exposure support, and scanner decision tokens forward instead of
  dropping diagnostics.
- Kept diagnostics privacy-safe: tokens/status/counts only, no receipt text,
  merchant names, item descriptions, amounts, addresses, phone numbers, notes,
  or OCR line IDs.
- Added direct model coverage and source guard coverage for the fallback bridge.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`
- `flutter test test/receipt_camera_result_test.dart --name "camera result converts native evidence into per-photo diagnostics"`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "post-capture quality copy leads with action and evidence"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is native capture back/close diagnostics
  and accepted-photo persistence verification.

### Receipt Camera Reopen Pass 560: Accepted Capture Persistence Diagnostics Batch

Status: complete.

What changed:
- Added per-photo persistence diagnostics after native receipt photos are staged
  locally for review.
- Each staged photo now records privacy-safe recovery state: staged locally,
  staged photo index/number/count, recovery manifest presence, attachment kind,
  attachment storage state, data-saver level, byte-size bucket, and hash
  presence.
- Kept the diagnostics content-free: no receipt text, merchant names, item
  descriptions, prices, customer content, addresses, phone numbers, notes, or
  OCR line IDs.
- Added regression coverage to prove accepted native captures carry this local
  persistence evidence.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_native_capture_staging_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_native_capture_staging_test.dart`
- `flutter test test/receipt_native_capture_staging_test.dart --name "accepted native capture is copied into receipt staging"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is parser-readiness contracts for line
  grouping, vendor/total/tax extraction handoff, and device-tier local/cloud OCR
  decision tokens without implementing inventory-specific parsing yet.

### Receipt Camera Reopen Pass 561: OCR Parser Handoff Contract Batch

Status: complete.

What changed:
- Added a privacy-safe `receipt_ocr_parser_handoff_v1` contract to the OCR
  parser handoff.
- The contract exposes ordered stable line IDs, primary field line IDs,
  line IDs by role, role/bucket/family/hint maps, parser task counts, field
  readiness counts, required field status, parser readiness, downstream
  readiness, receipt structure, line sequence, summary math status, and
  candidate line ID lists.
- The contract supports later vendor/date/total/tax/item-line parsing and
  inventory/material/fuel readiness without exposing receipt text or prices.
- Threaded the same contract into OCR diagnostics for future expense health and
  Command One summaries.
- Added regression coverage proving the local review map can retain line text
  on-device while the privacy-safe contract does not leak vendor text, item
  descriptions, or amounts.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --name "ocr parser handoff exposes local line drafts without leaking text to summaries"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is device-tier OCR decision evidence:
  record when local OCR, lean local OCR, optional cloud OCR, or optional cloud
  inventory matching should be offered without making camera capture depend on
  cloud services.

### Receipt Camera Reopen Pass 562: Device-Tier OCR Decision Evidence Batch

Status: complete.

What changed:
- Added privacy-safe OCR decision policy tokens to the device capability/cloud
  assist plan: local default only vs local default with optional cloud assist.
- Explicitly records that local OCR remains available/default and that camera
  capture and receipt review do not require cloud services.
- Preserved the tokens through native camera session arguments, native capture
  diagnostics, staged native capture recovery diagnostics, expense telemetry
  metadata, and local receipt privacy events.
- Added regression coverage for low-storage/older-device behavior and
  high-capacity behavior.
- Kept all fields content-free: no receipt text, vendor names, item
  descriptions, prices, addresses, phone numbers, customer content, notes, or
  OCR line text.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart lib/screens/expenses/data/expense_screen_telemetry.dart lib/screens/expenses/data/expense_receipt_privacy_event_store.dart test/receipt_assistance_policy_test.dart test/receipt_native_camera_contract_test.dart test/receipt_native_capture_staging_test.dart test/expense_screen_telemetry_test.dart test/receipt_privacy_event_store_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart lib/screens/expenses/data/expense_screen_telemetry.dart lib/screens/expenses/data/expense_receipt_privacy_event_store.dart test/receipt_assistance_policy_test.dart test/receipt_native_camera_contract_test.dart test/receipt_native_capture_staging_test.dart test/expense_screen_telemetry_test.dart test/receipt_privacy_event_store_test.dart`
- `flutter test test/receipt_assistance_policy_test.dart --name "low storage tightens automatic receipt photo space saving"`
- `flutter test test/receipt_assistance_policy_test.dart --name "high capacity phones keep cloud inventory matching optional"`
- `flutter test test/receipt_native_camera_contract_test.dart --name "native service sends previous section guide through channel"`
- `flutter test test/receipt_native_camera_contract_test.dart --name "native service sends storage safety limits through channel"`
- `flutter test test/receipt_native_capture_staging_test.dart --name "accepted native capture is copied into receipt staging"`
- `flutter test test/expense_screen_telemetry_test.dart --name "allows only content-free receipt camera health metadata"`
- `flutter test test/receipt_privacy_event_store_test.dart --name "keeps local-first OCR decision tokens without receipt content"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is line-item parser preparation: expose
  parser handoff health summaries for vendor/date/tax/total/item-price line
  readiness and exact review causes without exposing private receipt content.

### Receipt Camera Reopen Pass 563: Parser Field Readiness Cause Batch

Status: complete.

What changed:
- Added derived OCR required-field status by field for vendor, date, subtotal,
  tax, total, and item-price lines.
- Added a compact readiness summary label showing exactly which required OCR
  handoff fields are ready, missing, or need review.
- Added exact OCR parser review cause codes that align with failure
  diagnostics, including missing vendor/date/summary/tax/total, no priced
  lines, no parser-ready items, line-sequence review, summary math review, and
  item-price review.
- Kept this content-free: the diagnostics expose statuses, counts, buckets, and
  stable cause codes only, not receipt text, vendor names, item descriptions,
  amounts, addresses, phone numbers, notes, or OCR line text.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parse_models.dart test/expense_receipt_parser_test.dart test/expense_parser_failure_diagnostics_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_receipt_parse_models.dart test/expense_receipt_parser_test.dart test/expense_parser_failure_diagnostics_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --name "parses expense fields from OCR parser-ready receipt signals"`
- `flutter test test/expense_parser_failure_diagnostics_test.dart --name "prioritizes OCR parser task buckets as exact handoff causes"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is receipt line grouping evidence:
  preserve source section/line grouping and parser handoff sequence summaries so
  long-receipt stitching and parser review can identify where a line came from
  without exposing private text.

### Receipt Camera Reopen Pass 564: OCR Source Section Handoff Batch

Status: complete.

What changed:
- Added source-section grouping maps to the OCR parser handoff:
  line counts by source section, item-line counts by source section, all line
  IDs by source section, parser-ready line IDs by source section, and
  parser-review line IDs by source section.
- Added those maps to the privacy-safe OCR parser handoff contract so
  long-receipt review can identify where parser-ready/review lines came from
  after duplicate overlap suppression.
- Proved the two-section overlap flow keeps the second-section item source
  location after duplicate text is ignored.
- Kept the maps content-free: section numbers, counts, stable line IDs, and
  role/readiness grouping only. No receipt text, vendor names, item
  descriptions, amounts, addresses, phone numbers, notes, or OCR line text.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --name "ocr service keeps source section labels after suppressing overlap lines"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is accepted-photo-to-parser continuity:
  ensure review acceptance carries OCR source/stitch/capture diagnostics into
  receipt OCR start metadata and parser privacy events without private content.
