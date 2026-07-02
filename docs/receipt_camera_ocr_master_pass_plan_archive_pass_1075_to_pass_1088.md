# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 1075: Multi-Photo Bottom-Section Status Copy

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 1075: Multi-Photo Bottom-Section Status Copy

Status: complete.

What changed:
- Updated the receipt photo review controls so multi-photo review status copy no
  longer always promises that `Next` opens receipt details.
- If the selected/final section coverage decision still says another receipt
  section is needed, the tray now explains the missing-section action first.
- The missing bottom-edge plus missing subtotal/total path now tells the user to
  add the bottom section and repeat 3-5 readable lines in the top ghost slice,
  or tap `Next` only if the current set already shows the full receipt.
- Added source guards so the multi-photo status path continues to branch on
  `coverageDecision.shouldPromptForMorePhotos` before using the generic
  receipt-details copy.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --plain-name "photo review tray uses explicit long-receipt language" -r compact`
- `flutter test test/receipt_camera_result_test.dart --plain-name "ordered sections still request bottom section when final totals are missing" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is checking the `Next`
  button/action labels themselves so a partial final section does not look like
  the same action as a complete receipt details handoff.

### Receipt Camera Reopen Pass 1076: Partial Receipt Continue Gate

Status: complete.

What changed:
- Aligned the receipt review `Next` action with the same bottom-edge plus
  subtotal/total evidence rule used by the warning copy.
- Replaced the single-photo-only completion check with a receipt-section
  completion check, so a multi-photo receipt can still pause on the final
  section when the bottom edge and subtotal/total evidence are missing.
- Kept the user override: if the photo really is the full receipt, they can
  continue into receipt details, but the app first recommends adding the bottom
  section with the top ghost-slice guide.
- Updated source guards so the protected path is now “possible partial receipt”
  rather than “single possible partial receipt.”

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --plain-name "possible partial receipt prompts without blocking OCR" -r compact`
- `flutter test test/receipt_camera_capture_layout_test.dart --plain-name "receipt photo back protects captured images from silent discard" -r compact`
- `flutter test test/receipt_camera_capture_layout_test.dart --plain-name "post-capture quality copy leads with action and evidence" -r compact`
- `flutter test test/receipt_camera_result_test.dart --plain-name "ordered sections still request bottom section when final totals are missing" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is auditing the actual
  native capture diagnostics that feed bottom-edge and subtotal/total evidence,
  so camera results cannot under-report an obviously unfinished receipt.

### Receipt Camera Reopen Pass 1077: Native Bottom-Edge Evidence Normalization

Status: complete.

What changed:
- Normalized bottom-edge evidence when native capture photos are staged for
  receipt review.
- Native staging now emits `receiptBottomEdgeDetected`,
  `receiptBottomEdgeStatus`, `receiptBottomEdgeEvidenceSource`, and
  `receiptBottomEdgeEvidenceReason` for every staged receipt photo.
- Explicit native bottom-edge diagnostics are preserved when present.
- Weak bottom-edge score, cutoff framing, and low edge coverage now become a
  first-class missing-bottom signal before OCR reads the photo.
- Added a behavioral staging test proving a weak bottom-edge capture combines
  with missing subtotal/total OCR evidence into `missing_bottom_edge_and_totals`
  and the `subtotal_total_and_final_lines` ghost-guide target.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_native_capture_staging_test.dart`
- `flutter test test/receipt_native_capture_staging_test.dart --plain-name "native staging normalizes weak bottom edge evidence" -r compact`
- `flutter test test/receipt_camera_result_test.dart --plain-name "missing bottom edge and totals recommends next receipt section" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_native_capture_staging_test.dart`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is making sure the OCR
  totals evidence is merged back onto accepted photo diagnostics before the
  final coverage decision and receipt-details handoff run.

### Receipt Camera Reopen Pass 1078: OCR Totals Evidence Merge

Status: complete.

What changed:
- Kept OCR diagnostics on `_ReceiptAttachmentReadResult` instead of dropping
  them after app-assisted reading finishes.
- Merged `receiptTotalsCoverageEvidenceDiagnostics` back onto the accepted
  final receipt photo section after OCR reads the source image.
- The accepted photo diagnostics now preserve the combined evidence the receipt
  flow needs: camera-side bottom-edge status plus OCR-side subtotal/total text
  status.
- Marked the merged evidence with `receiptOcrTotalsEvidenceMerged`,
  `receiptOcrTotalsEvidenceSource`, and final-section/photo-count metadata so
  later review, telemetry, and debugging can tell where the signal came from.
- Added source guards covering the diagnostic carry-forward and merge contract.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_capture_layout_test.dart`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --plain-name "post-capture quality copy leads with action and evidence" -r compact`
- `flutter test test/receipt_camera_result_test.dart --plain-name "missing bottom edge and totals recommends next receipt section" -r compact`
- `flutter test test/receipt_native_capture_staging_test.dart --plain-name "native staging normalizes weak bottom edge evidence" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is tightening the post-OCR
  receipt-details route so a successful read opens the parsed receipt review
  screen with the line items, business/personal/mixed controls, and bottom
  section warnings instead of dropping the user back into the generic receipt
  attachment area.

### Receipt Camera Reopen Pass 1079: Parse-Aware Receipt Details Handoff

Status: complete.

What changed:
- Added explicit parsed-receipt outcome state on the expense receipt entry
  screen: parse completed, parse had usable fields, and parse had safe line
  items.
- Reset that state whenever a new app-assisted receipt read starts so stale
  parsed data from an older receipt cannot make the next photo look ready.
- Marked parsed OCR text as usable only after the parser creates receipt fields,
  totals, or line items; unusable OCR text now stays in the manual/no-safe-lines
  route even if OCR technically read text.
- Updated the successful receipt-read-finished handoff so it distinguishes:
  still parsing, bottom-section needed, subtotal/total missing, manual fallback,
  totals-only review, and full line-item review.
- Added source guards proving the successful photo-read route is parse-aware
  and no longer treats every OCR success as a finished parsed receipt review.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/expense_receipt_assisted_review_flow_test.dart`
- `dart analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart -r compact`
- `flutter test test/receipt_camera_capture_layout_test.dart --plain-name "post-capture quality copy leads with action and evidence" -r compact`
- `flutter test test/receipt_camera_result_test.dart --plain-name "missing bottom edge and totals recommends next receipt section" -r compact`
- `git diff --check -- lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/expense_receipt_assisted_review_flow_test.dart`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is strengthening the
  parsed receipt review's first visible line-item decision surface so
  Business/Personal/Mixed and totals-only/manual fallback are impossible to miss
  after the camera flow hands off into receipt details.

### Receipt Camera Reopen Pass 1080: First Visible Classification Next Step

Status: complete.

What changed:
- Added a compact next-step callout to the first app-assisted parsed receipt
  review card.
- The callout now tells the user the immediate next action after camera/OCR
  handoff: add the bottom section first, use the receipt total, add manual
  lines, classify highlighted lines, or classify ready lines before saving.
- The callout is driven by the existing local OCR/parser signals: line count,
  review count, subtotal/total evidence, bottom-section evidence, and parser
  summary signals.
- This keeps the camera-to-details route from feeling like a generic attachment
  area; the first receipt-details surface now points directly at
  Business/Personal/Mixed or the safe fallback path.
- Added source guards for all next-step branches.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `dart analyze lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart -r compact`
- `git diff --check -- lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is auditing the native
  camera review/capture route so the user never sees the phone stock camera UI
  for the primary Maintainiac receipt flow, while still allowing phone-camera
  backup only as an explicit fallback when the native Maintainiac camera is not
  available.

### Receipt Camera Reopen Pass 1081: Native-First Backup Capture Contract

Status: complete.

What changed:
- Moved backup capture handling behind
  `_openReceiptBackupCaptureAfterNativeUnavailable`, making the source contract
  explicit: Maintainiac native receipt camera is attempted first, then backup
  capture only after native camera is unavailable.
- Added fallback-only diagnostics to the document-scanner backup path, matching
  the phone-camera backup metadata.
- Backup captures now carry `backupCaptureAuthorizedBy:
  maintainiac_native_unavailable`, `stockCameraUiAllowedAsPrimary: false`, and
  fallback role metadata before they enter receipt photo review.
- Phone-camera backup diagnostics now also carry the same authorization and
  stock-camera-primary block markers.
- Added source guards proving native Maintainiac capture stays before document
  scanner and phone-camera fallback, and proving backup photos are labeled as
  fallback-only.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_capture_layout_test.dart`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --plain-name "receipt import uses Maintainiac native camera before any fallback" -r compact`
- `flutter test test/receipt_capture_flow_shareability_test.dart --plain-name "shared camera OCR flow stays module neutral" -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_capture_layout_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is strengthening review
  diagnostics for backup-captured receipt photos so OCR/parser confidence,
  bottom-section guidance, and user-facing warnings can distinguish native
  Maintainiac capture from document-scanner/phone-camera backup without storing
  receipt content.

### Receipt Camera Reopen Pass 1082: Backup Capture OCR Review Signals

Status: complete.

What changed:
- Made document-scanner backup capture a first-class native capture source
  policy outcome without making it the primary receipt camera path.
- Added saved-photo notice warnings for document-scanner and phone-camera backup
  captures so review, OCR, and parser diagnostics can distinguish backup photos
  from Maintainiac native capture.
- Added OCR source risk flags for document-scanner backup captures in both the
  shared capture flow and the receipt import panel.
- Kept backup notices privacy-safe: they identify capture source and review
  risk, not receipt text, merchant, line items, or user content.
- Added regression coverage for backup warning copy, parser risk/action codes,
  fallback-only document scanner source policy, and source-level OCR risk flags.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_result_test.dart --plain-name "photo review result flags bridged dim and glare capture wording" -r compact`
- `flutter test test/receipt_camera_result_test.dart --plain-name "document scanner backup is tracked as fallback-only capture source" -r compact`
- `flutter test test/receipt_camera_capture_layout_test.dart --plain-name "photo review surfaces native saved-photo quality warnings" -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is the long-receipt
  completion rule: combine bottom-edge evidence with subtotal/total word and
  amount evidence so missing-bottom receipts route into add-another-photo with
  the previous bottom section as the ghost alignment guide.

### Receipt Camera Reopen Pass 1083: Bottom Edge Plus Totals Amount Gate

Status: complete.

What changed:
- Tightened the missing-bottom receipt rule so it is not just an edge check and
  not just a text check. The photo is treated as likely needing another section
  when bottom-edge evidence is missing and subtotal/total words plus total
  amount evidence are not confirmed.
- Stopped treating a tax line or vague summary line as enough proof that the
  receipt's bottom totals section is present.
- Updated the user-facing completion guidance to explain the combined evidence:
  bottom edge missing, subtotal/total words missing, and total amount missing.
- Added stronger privacy-safe coverage codes for the stricter
  words-plus-amount rule while keeping the older totals-text signal names as
  compatibility aliases for current OCR/parser handoffs.
- Taught OCR and expense parser diagnostics to recognize both the new strict
  signal names and the older compatibility signal names.
- Added regression coverage proving tax-only evidence still routes to add the
  bottom receipt section with the top ghost-slice guide.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/data/expense_receipt_parse_models.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/data/expense_receipt_parse_models.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_result_test.dart --plain-name "missing bottom edge and totals recommends next receipt section" -r compact`
- `flutter test test/receipt_camera_result_test.dart --plain-name "tax line alone does not satisfy bottom totals completion evidence" -r compact`
- `flutter test test/receipt_camera_capture_layout_test.dart --plain-name "post-capture quality copy leads with action and evidence" -r compact`
- `flutter test test/receipt_camera_capture_layout_test.dart --plain-name "photo review surfaces native saved-photo quality warnings" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr diagnostics combines missing totals with bottom coverage risk" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "parses expense fields from OCR parser-ready receipt signals" -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/data/expense_receipt_parse_models.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is making the review route
  act on the stricter completion decision every time: add-bottom should reopen
  the camera with the previous bottom section as the top ghost alignment guide,
  while Next should open receipt details only after the user confirms the photo
  is complete or the evidence says it is complete enough.

### Receipt Camera Reopen Pass 1084: Completion Prompt Suppression Fix

Status: complete.

What changed:
- Fixed the single-photo/last-section completion prompt so the app no longer
  marks a photo as already prompted before the user chooses an action.
- `Keep Reviewing` now keeps the bottom-section prompt eligible for the next
  Next tap instead of silently letting receipt details open later.
- Add-bottom attempts that are canceled or fail no longer bless the current
  photo as complete.
- Only an explicit `Continue And Review` decision suppresses the repeat prompt
  for that photo.
- Added a source guard proving the prompt marker is written in the
  continue-confirmed branch, not before the dialog decision.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --plain-name "possible partial receipt prompts without blocking OCR" -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is the actual add-bottom
  continuation experience: when the rule says bottom edge plus subtotal/total
  words and amount are missing, Add Bottom Section must reopen capture with the
  previous bottom section as the top ghost guide and preserve that evidence
  through OCR/parser handoff.

### Receipt Camera Reopen Pass 1085: Native Bottom Ghost-Slice Contract

Status: complete.

What changed:
- Added explicit ghost-guide slice metrics to the receipt capture continuation
  contract: source start fraction, source height fraction, overlay top fraction,
  overlay height fraction, opacity, and slice percent.
- Missing-bottom receipts now carry a concrete 20% bottom-slice instruction
  from Dart flow options through the native CameraX/AVFoundation session
  config.
- Android native receipt camera now crops the previous photo to the requested
  bottom slice before displaying it as the top ghost guide.
- iOS native receipt camera now crops the previous `UIImage` to the requested
  bottom slice before displaying it as the top ghost guide.
- Native diagnostics now include the ghost slice metrics, so Command/admin
  health can verify whether long-receipt alignment was actually offered without
  storing receipt content.
- Added contract, bridge, and layout guards for the numeric ghost-guide fields
  and the native crop helpers.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart test/receipt_camera_capture_layout_test.dart test/receipt_native_camera_contract_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart test/receipt_camera_capture_layout_test.dart test/receipt_native_camera_contract_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_native_camera_contract_test.dart --plain-name "session carries previous section guide only for long receipt flow" -r compact`
- `flutter test test/receipt_native_camera_contract_test.dart --plain-name "native service sends previous section guide through channel" -r compact`
- `flutter test test/receipt_native_android_bridge_test.dart --plain-name "Android receipt camera bridge uses CameraX method channel" -r compact`
- `flutter test test/receipt_native_ios_bridge_test.dart --plain-name "iOS receipt camera bridge uses AVFoundation method channel" -r compact`
- `flutter test test/receipt_camera_capture_layout_test.dart --plain-name "native ghost guide contract keeps repeat-line guidance explicit" -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart android/app/src/main/kotlin/com/maintainiac/ReceiptCameraActivity.kt ios/Runner/ReceiptCameraViewController.swift test/receipt_camera_capture_layout_test.dart test/receipt_native_camera_contract_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is making the visible review
  UI clearly separate the first photo review, Add Bottom Section, and Next to
  receipt details so the user never has to guess whether they are reviewing an
  image or reviewing parsed receipt lines.

### Receipt Camera Reopen Pass 1086: Photo Review Handoff Label Hardening

Status: complete.

What changed:
- Replaced the ambiguous photo-review primary labels with explicit action
  labels:
  - missing bottom edge plus subtotal/total evidence missing now shows
    `Add Bottom Section`;
  - uncertain continuation now shows `Next: Details If Complete`;
  - critical-quality override now shows `Next: Review Anyway`.
- Kept the gate behavior intact: Next still runs the completion prompt before
  OCR/receipt-detail handoff, while Add Bottom Section remains the preferred
  action when bottom edge and totals evidence are missing together.
- Updated stacked button copy, top-bar tooltip semantics, and exit-dialog labels
  so the UI no longer sounds like it is going back to the receipt home screen or
  silently reading a photo.
- Tightened source guards against the old confusing labels: `Add Bottom First`,
  `Next If Complete`, and `Next Anyway`.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_common_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_common_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --plain-name "receipt photo back protects captured images from silent discard" -r compact`
- `flutter test test/receipt_camera_capture_layout_test.dart --plain-name "possible partial receipt prompts without blocking OCR" -r compact`
- `flutter test test/receipt_camera_capture_layout_test.dart --plain-name "native ghost guide contract keeps repeat-line guidance explicit" -r compact`
- `flutter test test/receipt_camera_capture_layout_test.dart --plain-name "receipt review continuation copy explains the next screen" -r compact`
- `flutter test test/receipt_camera_capture_layout_test.dart --plain-name "photo review tray uses explicit long-receipt language" -r compact`
- `flutter test test/receipt_camera_capture_layout_test.dart --plain-name "reviewed receipt photos announce app fill handoff safely" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is the actual parsed-detail
  landing screen contract: after the accepted image review, the next visible
  screen must be the receipt detail review with OCR/parser evidence, line
  classification, and clear business/personal/mixed decisions, not the receipt
  home/attachment screen.

### Receipt Camera Reopen Pass 1087: Accepted Photo Handoff Scroll Contract

Status: complete.

What changed:
- Accepted receipt photos now scroll to the receipt handoff panel while OCR and
  parsing are still running instead of trying to scroll to the parsed-detail
  section before that section exists.
- The parsed receipt application path still scrolls to the receipt detail
  review section once OCR/parser has filled fields and mounted the review UI.
- The handoff panel remains the only interim state after photo review: the
  attachment/photo home area stays hidden once the receipt review flow has
  started.
- Updated the source guard so accepted-photo handoff must route to the
  handoff key first, while parsed results continue to route to the review key.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/expense_receipt_assisted_review_flow_test.dart`
- `dart analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is parsing-line evidence:
  keep the photo/ghost completion decision attached to OCR blocks and parsed
  receipt lines so the detail screen can explain whether a line came from the
  accepted image, the stitched/continued image, or a fallback source without
  showing private receipt content in diagnostics.

### Receipt Camera Reopen Pass 1088: OCR Section Anchors On Parsed Lines

Status: complete.

What changed:
- Added section-aware OCR source anchors to expense receipt lines:
  - `ocrSourceSectionNumber`
  - `ocrSourceSectionLineNumber`
- Updated ledger persistence, entry-screen working lines, parser application,
  confirm/correct flows, and save conversion so those anchors survive the
  complete local receipt detail review path.
- Bridged `parseExpenseReceiptOcrResult` to OCR's existing
  `ReceiptOcrParserHandoff.lineDrafts`, replacing generic parser row references
  with OCR stable line IDs and section/line location evidence when available.
- Strengthened privacy-safe proof references so diagnostics can identify
  section/line anchors and redaction targets without storing receipt text.
- Updated line labels and redaction anchor codes so long-receipt sections can
  be referenced as `Section N line M` instead of only flat OCR line numbers.

Validation:
- `dart format lib/screens/expenses/data/expense_line_record.dart lib/screens/expenses/entry/expense_receipt_line_models.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_line_record_test.dart test/expense_receipt_parser_test.dart`
- `dart analyze lib/screens/expenses/data/expense_line_record.dart lib/screens/expenses/entry/expense_receipt_line_models.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_line_record_test.dart test/expense_receipt_parser_test.dart`
- `flutter test test/expense_receipt_line_record_test.dart -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "preserves OCR item review buckets through parser diagnostics" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is receipt detail review
  visibility: show the section-aware source/proof anchors in a compact way on
  parsed lines and use the anchors to drive add-bottom/section-order guidance
  without cluttering the receipt image review.
