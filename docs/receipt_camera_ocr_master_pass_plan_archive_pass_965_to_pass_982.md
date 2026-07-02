# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 965: Install Footprint Handoff Guard

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 965: Install Footprint Handoff Guard

Status: complete.

What changed:
- Carried receipt install-footprint decisions from accepted camera results into the receipt reader handoff metadata.
- Added count and outcome getters for required base segment, full-offline segment, low-storage impact, recommended distribution, parser-free camera shell, tiny-phone usefulness, and optional-pack consent.
- Threaded the same install-footprint maps into expense receipt parse diagnostics so parser review and Command1 telemetry can see when the base flow stayed lean versus when heavy local packs must remain optional.
- Added a parser-facing install-footprint outcome and summary label so future UI can explain whether the base receipt flow is ready, large packs are hidden, or heavy receipt work must be split before release.
- Strengthened receipt result, assisted review, and telemetry tests so these local-only install-size guardrails cannot disappear quietly.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/receipt_camera_result_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/receipt_camera_result_test.dart test/expense_receipt_assisted_review_flow_test.dart test/expense_screen_telemetry_test.dart -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/receipt_camera_result_test.dart test/expense_receipt_assisted_review_flow_test.dart`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is the first actual low-storage receipt proof policy enforcement: accepted originals should be used for OCR first, then only the selected saved proof/data-saver copy should remain in the normal receipt record unless the user explicitly keeps a local original.

### Receipt Camera Reopen Pass 966: Receipt Proof Storage Policy Signals

Status: complete.

What changed:
- Added receipt proof storage policy counts and outcomes to the photo review result.
- Distinguished saved receipt proof, temporary OCR source, saved-proof OCR fallback, data-saver proof as the normal record, and temporary original quality-guard cases.
- Added the same policy buckets to receipt reader/details handoff counts and privacy-safe metadata.
- Tagged OCR attachment document signals and risk flags in both the shared capture flow and the expense attachment import flow so other modules can reuse the camera/OCR path without accidentally treating OCR sources as normal saved proof.
- Strengthened tests so the model and assisted receipt flow require the storage policy to stay visible.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_result_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/receipt_camera_result_test.dart test/expense_receipt_assisted_review_flow_test.dart -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_result_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_result_test.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is a concrete receipt proof/data-saver sizing policy that estimates target proof bytes for tiny, low, normal, and high-quality modes without exposing receipt content or forcing full-size originals into backup.

### Receipt Camera Reopen Pass 967: Proof Target Size Policy

Status: complete.

What changed:
- Added a concrete saved-proof target size policy for each receipt data-saver level: original local-only, high quality, normal, low storage, and tiny proof.
- Carried target min/target/max byte ranges, cloud-backup default allowance, original-local-only status, and readability-review requirements into privacy-safe receipt handoff metadata.
- Surfaced the selected proof target summary in the receipt camera settings sheet so data-saver choices explain the actual saved proof size and review burden.
- Strengthened receipt result and settings tests so balanced proof targets, low-storage readability review, and proof-target handoff counts remain visible.
- Kept OCR source handling separate from saved proof size: OCR still reads the clearest available source first, then the normal record uses the chosen saved proof policy.
- Repaired the Android native camera focus/exposure lock diagnostic helpers so lock control expectations derive from `focusMode` and `exposureMode` instead of missing flags.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_settings_store.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart test/receipt_camera_result_test.dart test/receipt_capture_settings_store_test.dart`
- `flutter test test/receipt_camera_result_test.dart test/receipt_capture_settings_store_test.dart -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_store.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart test/receipt_camera_result_test.dart test/receipt_capture_settings_store_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_store.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart test/receipt_camera_result_test.dart test/receipt_capture_settings_store_test.dart android/app/src/main/kotlin/com/maintainiac/ReceiptCameraActivity.kt docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is visible camera behavior: make the native capture review/close path harder to trap, keep manual shutter and back/close reliable, and start moving from policy metadata back into real camera UX and receipt review behavior.

### Receipt Camera Reopen Pass 968: Generic Receipt Skeleton and Safe Close Contract

Status: complete.

What changed:
- Added a shared receipt layout analyzer that numbers every non-empty OCR line, assigns broad receipt zones, and tags merchant, address, date/time, transaction, item, subtotal, tax, total, payment, barcode, footer, and private-share-risk signals without relying on a known merchant profile.
- Added a client-proof redaction plan model so future job, estimate, invoice, material, and inventory flows can expose only selected receipt line numbers while hiding unrelated lines, payment text, transaction ids, and other private content.
- Wired the generic receipt skeleton into expense parser diagnostics so unknown gas stations and stores still produce a receipt-structure status, parser line numbers, client-proof default visible lines, zone counts, signal counts, and a review/action label.
- Tightened the native Android receipt camera close contract: no-photo back cancels cleanly, captured-photo back returns the captured sections to photo review, and in-flight capture close waits for save/review rather than silently discarding the photo.
- Renamed native Android add-section copy to “Add Photo” / “Add another receipt photo...” so long receipt capture is understandable without guessing what a plus-camera icon means.

Validation:
- `flutter test test/expense_receipt_parser_test.dart --plain-name "generic receipt layout keeps unknown gas station receipts parseable" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "receipt layout analyzer numbers lines and creates client proof redaction plan" -r compact`
- `flutter test test/receipt_native_android_bridge_test.dart --plain-name "Android receipt camera bridge uses CameraX method channel" -r compact`
- `flutter test test/receipt_native_camera_contract_test.dart --plain-name "native camera screens report control diagnostics without content" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is strengthening the real parsed-line handoff so generic receipt skeleton lines can drive the receipt review screen, mixed business/personal classification, and future line-specific client proof redaction without depending on a store-specific parser pack.

### Receipt Camera Reopen Pass 969: Parsed Line Proof Anchors

Status: complete.

What changed:
- Added privacy-safe proof metadata to parsed expense receipt lines without adding a new migration: proof line labels, stable redaction anchor codes, default client-proof visibility, share-review labels, and proof references.
- Personal receipt lines now default to hidden from client proof, while uncategorized or parser-review lines default to review-before-share.
- Derived redaction anchors from OCR line numbers where available, falling back to stable OCR source ids or line ids so future crop/redaction work can identify exact lines without raw receipt text.
- Included the same proof metadata in line maps while keeping the privacy-safe reference free of merchant names, item descriptions, and raw receipt amounts.
- Added tests for material, personal, and review-line proof visibility.

Validation:
- `dart format lib/screens/expenses/data/expense_line_record.dart test/expense_receipt_line_record_test.dart`
- `flutter test test/expense_receipt_line_record_test.dart -r compact`
- `dart analyze lib/screens/expenses/data/expense_line_record.dart test/expense_receipt_line_record_test.dart`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is using proof anchors in the receipt review/handoff layer so business/personal/mixed classification and future client-proof cropping can rely on line numbers and redaction metadata instead of raw receipt text.

### Receipt Camera Reopen Pass 970: Assisted Review Proof Anchor Visibility

Status: complete.

What changed:
- Carried OCR line ids, OCR line numbers, parser family, and parser hints through the in-progress receipt entry line model so assisted receipt review does not lose line identity before saving.
- Mirrored privacy-safe proof anchors in the receipt review model: proof line labels, redaction anchor codes, client-proof visibility status, and client-proof review labels.
- Added a compact proof/status chip to the existing receipt line evidence row. It shows the receipt line reference and client-proof status without adding another large panel or covering the receipt.
- Ensured proof status still appears even when a line has weak or missing category classification, because line proof/redaction identity must not depend on the parser being confident about the expense category.
- Guarded the source contract so future review UI work keeps OCR line labels, proof line labels, and client-proof review status visible in the assisted review flow.

Validation:
- `dart format lib/screens/expenses/data/expense_line_record.dart lib/screens/expenses/entry/expense_receipt_line_models.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_line_record_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_line_record_test.dart -r compact`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `dart analyze lib/screens/expenses/data/expense_line_record.dart lib/screens/expenses/entry/expense_receipt_line_models.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_line_record_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `git diff --check -- lib/screens/expenses/data/expense_line_record.dart lib/screens/expenses/entry/expense_receipt_line_models.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_line_record_test.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is using the generic receipt skeleton and proof anchors to improve parser diagnostics/telemetry for unknown merchants, line proof readiness, and future customer-safe crop/redaction review without sending raw receipt text anywhere.

### Receipt Camera Reopen Pass 971: Long Receipt Section First Review Contract

Status: complete.

What changed:
- Re-centered the receipt flow around the actual user sequence: take a photo, review it, add the next receipt section when the photo likely does not cover the whole receipt, then continue to receipt details only when the user accepts the coverage.
- Added a receipt review result signal for `needsAnotherReceiptSectionBeforeDetails`, including privacy-safe handoff metadata and reason codes so diagnostics know when a user continued past an incomplete-coverage warning without exposing receipt content.
- Changed single-photo partial receipt review copy to make `Add Next Section` the recommended action and `Next If Complete` the explicit override when the receipt is already fully visible/readable.
- Kept the long-receipt ghost guide path intact: adding the next section still passes the previous section, coverage reason, and guidance into the native capture session so the user can line up overlap.
- Strengthened tests so partial single photos recommend another section, multi-section receipts still proceed as ordered sections, and review UI source guards require the new labels.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_result_test.dart --plain-name "single partial receipt photo recommends next section before details" -r compact`
- `flutter test test/receipt_camera_capture_layout_test.dart --plain-name "single possible partial receipt prompts without blocking OCR" -r compact`
- `flutter test test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is making the accepted-photo-to-receipt-details path prove the user lands in parsed receipt review with store/date/tax/total/item lines instead of returning to the receipt start screen, including long-receipt ordered sections and stitched/fallback sources.

### Receipt Camera Reopen Pass 972: Parsed Review Stays The Destination

Status: complete.

What changed:
- Tightened the accepted-photo-to-details layout so the full receipt attachment panel no longer reappears as the main destination after app-assisted review starts.
- Kept long-receipt recovery available without making the user feel sent backward: add/retake receipt photos now lives behind a collapsed recovery panel that only appears when OCR, coverage, or partial-section warnings need it.
- Added a separate recovery scroll anchor and an explicit `Add / Retake` action on the handoff panel so missing sections can still be added from the review state.
- Preserved the parsed receipt review as the primary next screen, including store/date/tax/total/item-line review and Business/Personal/Mixed classification.
- Updated the assisted receipt source contract so tests reject the old `if (!showAttachmentBeforeReview)` full-panel return path.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `flutter test test/receipt_camera_capture_layout_test.dart -r compact`
- `dart analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check -- lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is proving the native capture review result cannot silently discard accepted photos or leave the user trapped on the camera/review screen when using Android back, app back, or the close controls after one or more sections are captured.

### Receipt Camera Reopen Pass 973: Native Close Never Drops Prior Sections

Status: complete.

What changed:
- Hardened Android CameraX close/error behavior so a failed in-flight section capture during back/close returns any already captured receipt sections to Maintainiac review instead of canceling the whole receipt flow.
- Hardened iOS AVFoundation with the same rule: pending close after capture failure only cancels when there are zero captured receipt photos.
- Added a shared native close reason, `back_capture_failed_returned_existing_sections`, so diagnostics can distinguish “last photo failed but previous sections were returned” from true no-photo cancellation.
- Kept existing successful in-flight close behavior intact: when the in-flight photo saves, back/close still returns captured sections to receipt photo review.
- Added source guards to Android and iOS native bridge tests so the old cancel-on-failed-close branch cannot come back without failing tests.

Validation:
- `dart format test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart -r compact`
- `dart analyze test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `git diff --check -- android/app/src/main/kotlin/com/maintainiac/ReceiptCameraActivity.kt ios/Runner/ReceiptCameraViewController.swift test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is tightening the actual camera review controls and native result handoff so the preview screen cannot trap the user, hide the primary Next action, or use ambiguous labels after a single receipt photo is captured.

### Receipt Camera Reopen Pass 974: Single Photo Review Action Clarity

Status: complete.

What changed:
- Tightened the single-photo review primary row so the secondary capture action is visibly labeled `Add Photo` instead of the vague `Add Another`.
- Kept the receipt-specific tooltip: add another receipt photo only when the receipt continues.
- Preserved `Add Next Section` when the coverage system thinks the single photo may not include the whole receipt.
- Added a source guard so the old vague `Add Another` branch does not come back in the primary single-photo row.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --plain-name "post-capture quality copy leads with action and evidence" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart test/receipt_camera_capture_layout_test.dart`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is checking the post-capture review screen for any remaining ambiguous single-photo language such as “choose the best photo” when there is only one photo, and making sure the primary action always reads as the next workflow step.

### Receipt Camera Reopen Pass 975: One Photo Means Review Receipt Photo

Status: complete.

What changed:
- Updated the single-photo review title from generic `Review Photo` to `Review Receipt Photo`.
- Kept multi-photo/best-shot wording separate so burst or multi-section cases can still show photo position when that is actually relevant.
- Added a source guard so one-photo review remains receipt-specific instead of drifting back into generic gallery language.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --plain-name "receipt photo back protects captured images from silent discard" -r compact`
- `flutter test test/receipt_camera_capture_layout_test.dart --plain-name "receipt review continuation copy explains the next screen" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart test/receipt_camera_capture_layout_test.dart`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is reviewing the remaining post-capture review actions for accidental photo loss, ambiguous “save” wording, and whether the primary Next action is always reachable without scrolling.

### Receipt Camera Reopen Pass 976: Bottom Edge Plus Totals Coverage Rule

Status: complete.

What changed:
- Added an explicit `missing_bottom_edge_and_totals` coverage reason for long
  receipts.
- The coverage decision now combines bottom-edge evidence with subtotal, total,
  tax, or total-amount text evidence instead of treating framing and OCR totals
  as unrelated hints.
- If the bottom edge is missing and receipt totals evidence is explicitly absent,
  the flow recommends adding the next receipt section before opening receipt
  details.
- If the bottom edge is present and subtotal/total evidence is found, the photo
  is allowed to continue to receipt details instead of being pushed into the
  long-receipt path.
- Added source guards so the receipt camera model keeps the bottom-edge and
  totals diagnostic keys available for native camera/live OCR/parser handoff.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_result_test.dart --plain-name "missing bottom edge and totals recommends next receipt section" -r compact`
- `flutter test test/receipt_camera_result_test.dart --plain-name "detected totals avoid long receipt prompt when bottom is present" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is feeding native bottom-edge
  detection and live/OCR totals evidence into the new coverage keys from the
  Android CameraX and iOS AVFoundation capture layers, then tightening the UI
  copy that explains why Add Next Section is recommended.

### Receipt Camera Reopen Pass 977: Native Bottom Edge Diagnostic Parity

Status: complete.

What changed:
- Android CameraX capture diagnostics now publish `receiptBottomEdgeDetected`,
  `receiptBottomEdgeStatus`, and `receiptTotalsTextEvidenceStatus`.
- iOS AVFoundation capture diagnostics now publish the same keys so both native
  camera paths feed the Dart receipt coverage brain consistently.
- Added native bottom-edge status helpers that classify the captured bottom as
  visible, soft/missing, possibly cut off, uncertain, or not evaluated.
- Native capture intentionally marks totals text as
  `not_evaluated_native_capture` because native capture does not OCR words yet;
  the subtotal/total/amount evidence must come from OCR/parser diagnostics
  after receipt text is actually read.
- Added Android and iOS bridge guards for the new bottom-edge fields and status
  labels.

Validation:
- `dart format test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart -r compact`
- `dart analyze test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is carrying OCR/parser
  subtotal, total, tax, and amount evidence into the same coverage decision so a
  captured photo with missing bottom edge plus missing receipt-summary text can
  route the user back to Add Next Section instead of pretending receipt details
  are complete.

### Receipt Camera Reopen Pass 978: OCR Totals Coverage Evidence

Status: complete.

What changed:
- `ReceiptOcrDiagnostics` now exposes privacy-safe totals coverage evidence:
  subtotal detected, total detected, total amount detected, summary line count,
  and `receiptTotalsTextEvidenceStatus`.
- The OCR evidence map uses the same diagnostic keys as the receipt coverage
  brain, so OCR/parser output can be merged with native bottom-edge evidence
  without carrying private receipt text.
- The parsed receipt review now gives stronger guidance when OCR found receipt
  text but no subtotal/total/tax evidence: check whether the bottom of the
  receipt is missing, add the next receipt section, or enter the total manually.
- Added regression tests proving both sides of the combined rule: totals evidence
  is detected on a complete receipt, and missing totals plus missing bottom edge
  triggers `missing_bottom_edge_and_totals`.
- Added a source guard so the assisted receipt review keeps the missing-bottom
  action copy visible in the OCR structure guidance path.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/receipt_ocr_service_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr diagnostics exposes receipt totals coverage evidence" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr totals evidence can trigger missing bottom coverage decision" -r compact`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/receipt_ocr_service_test.dart test/expense_receipt_assisted_review_flow_test.dart`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is connecting this combined
  coverage evidence into the receipt-photo recovery panel after OCR finishes, so
  a missing-bottom/missing-total read can offer Add Next Section from the filled
  receipt review without sending the user back to the expense start screen.

### Receipt Camera Reopen Pass 979: Missing Totals Recovery Handoff

Status: complete.

What changed:
- OCR completion now preserves the missing-summary evidence state when OCR finds
  receipt text but no subtotal/total/tax evidence.
- The final read-finished handler no longer overwrites that recovery state; it
  keeps a bottom-check stage, an Add Next Section style action, and a route result
  explaining that receipt details opened but summary evidence is missing.
- The existing receipt-photo recovery panel is reused. The handoff panel's
  `Add / Retake` button scrolls to the recovery panel instead of sending the user
  back to the expense start screen.
- Added user-facing copy that explains the real issue: subtotal/total lines were
  not found, so add the next receipt section if the bottom of the receipt is
  missing, or enter the total manually if the receipt is complete.
- Added source guards so the assisted review flow keeps the missing-total
  handoff labels, coverage warning, and recovery key connected.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `dart analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/expense_receipt_assisted_review_flow_test.dart`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is tightening the long
  receipt add-next-section UX around the ghost overlap guide and section order
  evidence, especially making sure the next section preserves top-to-bottom order
  and does not make the user guess which image is section 1, 2, or 3.

### Receipt Camera Reopen Pass 980: Numbered Ghost Section Guidance

Status: complete.

What changed:
- Android CameraX now labels the post-capture next action as the next numbered
  receipt section instead of a generic additional photo.
- iOS AVFoundation now mirrors the numbered section action.
- Native guidance after saving a receipt section now says the next photo is
  section `N + 1`, tells the user to line up the ghost guide at the top, and
  reminds them to repeat 3-5 readable lines.
- Native diagnostics now include `receiptSectionCount`,
  `nextReceiptSectionNumber`, `receiptSectionOrderPolicy`,
  `previousSectionGhostGuidePolicy`, and `previousSectionGhostGuideVisible`.
- Added bridge guards so Android and iOS keep the same top-to-bottom numbered
  section contract.

Validation:
- `dart format test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart -r compact`
- `dart analyze test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is carrying the numbered
  section diagnostics from native capture into `ReceiptPhotoReviewResult` and OCR
  source handoff metadata so parser/Command One health can distinguish ordered
  section captures from generic multi-photo receipts without seeing receipt text.

### Receipt Camera Reopen Pass 981: Section Order Handoff Metadata

Status: complete.

What changed:
- `ReceiptPhotoReviewResult` now summarizes numbered receipt-section diagnostics
  from native capture without carrying merchant names, prices, or receipt text.
- The privacy-safe handoff metadata now includes section-order counts, a compact
  section-order outcome, and an evidence label that can distinguish numbered
  top-to-bottom sections with the ghost guide active from generic multi-photo
  receipts.
- The OCR handoff evidence label now includes a `sections=...` signal when native
  section evidence exists.
- Receipt reader handoff counts now include prefixed section-order signals so
  parser/admin health can see whether the long-receipt workflow used numbered
  sections and the overlap ghost guide.
- Added a regression test proving the ghost guide/section-order signals survive
  the handoff while private merchant/line text does not leak into metadata.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart`
- `flutter test test/receipt_camera_result_test.dart --plain-name "native section order metadata preserves ghost guide handoff" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is feeding the same
  bottom-edge plus totals evidence into the long-receipt capture decision so the
  user gets Add Next Section when the bottom is likely missing, but can still
  continue when the whole receipt is readable.

### Receipt Camera Reopen Pass 982: Bottom Missing Dialog Copy

Status: complete.

What changed:
- The combined `missing_bottom_edge_and_totals` decision now carries explicit
  dialog copy for the single-photo review gate.
- When the bottom edge and subtotal/total evidence are both missing, the dialog
  now asks about adding the bottom of the receipt instead of using generic photo
  wording.
- The add action now says `Add Bottom Section` for this specific case and the
  continue action says `Continue And Review`, preserving the user's ability to
  proceed when the receipt really is complete.
- The generic incomplete-receipt path now uses `Need another receipt section?`
  and `Add Next Section`, keeping the long-receipt workflow section-based.
- Updated regression/source guards so the flow remains wired to the decision
  model instead of stale hard-coded dialog copy.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_result_test.dart --plain-name "missing bottom edge and totals recommends next receipt section" -r compact`
- `flutter test test/receipt_camera_capture_layout_test.dart --plain-name "single possible partial receipt prompts without blocking OCR" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is preserving bottom-edge
  and totals evidence when OCR diagnostics arrive after photo review, so the
  filled receipt review can recommend adding the next section without losing the
  original capture proof.
