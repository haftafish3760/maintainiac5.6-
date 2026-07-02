# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 1045: Bottom-First Review Routing

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 1045: Bottom-First Review Routing

Status: complete.

What changed:
- When the current receipt photo is in preview mode and the coverage decision
  says the bottom edge and subtotal/total text are both missing, the top-bar and
  bottom-tray continue action now reads as a bottom check instead of a normal
  "ready for receipt details" step.
- Added a stacked "Check / Bottom" label for the bottom-first path so the main
  green action does not imply the receipt is complete.
- Updated preview tooltips and semantics to say "Check the bottom before receipt
  details" for the two-signal bottom/totals case.
- Kept "continue anyway" available, but visually secondary in the completion
  dialog when both edge evidence and word evidence indicate the receipt may
  continue.
- Updated camera help/layout guards to protect the smaller bottom tray sizing
  and the new bottom-first copy.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_common_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_help_flow_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_help_flow_test.dart --plain-name "receipt capture exposes camera help and long receipt guidance" -r compact`
- `flutter test test/receipt_camera_capture_layout_test.dart --plain-name "photo review bottom controls stay capped by mode" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_common_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_help_flow_test.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_common_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_help_flow_test.dart test/receipt_camera_capture_layout_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is making the bottom-section
  add-photo path pass the previous section guide and reason into native capture
  consistently, so the next camera session can show the ghost overlap guide for
  missing-bottom/subtotal-total cases.

### Receipt Camera Reopen Pass 1046: Native Ghost-Guide Handoff Policy

Status: complete.

What changed:
- Added `previousSectionGhostGuidePolicy` to the native receipt camera session
  contract so the bridge carries an explicit policy for long-receipt overlap
  capture.
- The missing-bottom/subtotal-total case now maps to
  `bottom_overlap_ghost_at_top_repeat_3_to_5_lines`.
- If a previous-section guide is present but custom guidance is missing, the
  native camera contract now falls back to bottom-specific copy for the
  missing-bottom/subtotal-total case instead of generic long-receipt copy.
- The native camera service now sends the ghost-guide policy through method
  channel arguments and includes it in privacy-safe diagnostics.
- Android and iOS bridge guards now require the explicit ghost-guide policy
  field alongside the existing previous-photo and missing-bottom signals.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart test/receipt_native_camera_contract_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_native_camera_contract_test.dart --plain-name "session carries previous section guide only for long receipt flow" -r compact`
- `flutter test test/receipt_native_camera_contract_test.dart --plain-name "native service sends previous section guide through channel" -r compact`
- `flutter test test/receipt_native_android_bridge_test.dart -r compact`
- `flutter test test/receipt_native_ios_bridge_test.dart -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart test/receipt_native_camera_contract_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart test/receipt_native_camera_contract_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is making captured-photo
  diagnostics preserve the ghost-guide policy through receipt result models and
  section-order diagnostics so OCR/parser review can explain which photos were
  captured as continuation sections.

### Receipt Camera Reopen Pass 1047: Continuation Ghost Policy Diagnostics

Status: complete.

What changed:
- Added `ghostGuidePolicyCode` to `ReceiptPhotoCoverageDecision` so review,
  fallback camera capture, and result diagnostics can share the same ghost-guide
  policy token.
- The receipt continuation signal summary now counts
  `ghost_policy_bottom_overlap_ghost_at_top_repeat_3_to_5_lines` for
  missing-bottom/subtotal-total continuation photos.
- Phone camera fallback diagnostics now preserve the previous section's
  ghost-guide policy when Maintainiac native capture is unavailable.
- Result-model tests now verify that normal native review and fallback review
  both carry bottom-section continuation and ghost-policy evidence without
  leaking receipt paths or text.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_result_test.dart`
- `flutter test test/receipt_camera_result_test.dart --plain-name "review result preserves bottom-section continuation handoff context" -r compact`
- `flutter test test/receipt_camera_result_test.dart --plain-name "phone camera fallback preserves bottom-section continuation handoff" -r compact`
- `flutter test test/receipt_camera_result_test.dart --plain-name "native section order metadata preserves ghost guide handoff" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_result_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_result_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is surfacing the
  continuation ghost-policy signal inside OCR source handoff summaries so parser
  review and diagnostics can report whether a receipt was read from ordinary
  photos, stitched photos, or bottom-section continuation photos.

### Receipt Camera Reopen Pass 1048: OCR Continuation Ghost-Policy Handoff

Status: complete.

What changed:
- Added `receipt_continuation_ghost_policy_*` document signals to the shared
  receipt capture OCR-source handoff path.
- Added the same continuation ghost-policy signal to the attachment import path
  so imported/reviewed photos and fresh native camera captures stay aligned.
- Added `ocr_source_continuation_bottom_overlap_ghost_policy` risk/evidence
  flags for the bottom-overlap policy used when the receipt bottom and
  subtotal/total text are missing.
- Extended OCR diagnostics coverage so the bottom-overlap ghost policy is
  counted in `continuationSignalCounts`.
- Hardened the shared capture/import guard to require both paths to emit the
  new ghost-policy signals.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_ocr_service_test.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr diagnostics combines missing totals with bottom coverage risk" -r compact`
- `flutter test test/receipt_capture_flow_shareability_test.dart --plain-name "accepted shared flow clears interrupted native recovery after attach" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_ocr_service_test.dart test/receipt_capture_flow_shareability_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_ocr_service_test.dart test/receipt_capture_flow_shareability_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is teaching expense parse
  diagnostics to read the OCR continuation ghost-policy counts and expose a
  user-safe review label for bottom-section continuation receipts.

### Receipt Camera Reopen Pass 1049: Parser Bottom-Continuation Review Handoff

Status: complete.

What changed:
- Added `ocrSourceContinuationSignalCounts` to expense receipt parse
  diagnostics so parser review no longer loses continuation-photo evidence
  after OCR handoff.
- Added parser helpers for the specific bottom-overlap ghost-guide case where
  bottom edge evidence and subtotal/total text are missing together.
- Updated assisted receipt review copy and actions to prefer the continuation
  ghost-guide explanation when that stronger evidence is present.
- Hardened parser and review-flow guards so the coverage rule and continuation
  rule stay paired: missing bottom edge plus missing subtotal/total means add
  the next receipt section with the ghost guide.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "parses expense fields from OCR parser-ready receipt signals" -r compact`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `dart analyze lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `git diff --check -- lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is using the same
  bottom-edge-plus-subtotal-total continuation rule to route the post-photo
  capture result into add-next-section/review-next flow instead of generic
  receipt review wording.

### Receipt Camera Reopen Pass 1050: Post-Photo Continuation Route Handoff

Status: complete.

What changed:
- Tightened the receipt attachment-panel OCR completion callback so a detected
  bottom-edge-plus-subtotal-total miss uses the stronger "add bottom section
  with ghost overlap" handoff warning instead of the softer missing-total copy.
- Added OCR source continuation counts to the privacy-safe completion metadata
  and parser telemetry so bottom-continuation evidence can be traced without
  receipt content, file paths, or private user data.
- Hardened OCR diagnostics tests to require continuation signal counts inside
  the coverage evidence map for the missing-bottom/subtotal-total route.
- Hardened assisted receipt review guards so the attachment-panel callback and
  parser telemetry keep the continuation-count handoff wired.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/receipt_ocr_service_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr diagnostics combines missing totals with bottom coverage risk" -r compact`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `dart analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/receipt_ocr_service_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `git diff --check -- lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/receipt_ocr_service_test.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is auditing the capture
  review controls that appear after a photo is accepted so the visible "add
  another photo" and ghost-guide path match the continuation route instead of
  feeling like a hidden or generic control.

### Receipt Camera Reopen Pass 1051: Visible Add-Bottom Review Control

Status: complete.

What changed:
- Changed the bottom-continuation primary review button rendering from
  `Check / Bottom` to `Add / Bottom` so the next action is explicit when OCR
  and capture evidence indicate the receipt bottom/subtotal-total section is
  missing.
- Updated top-bar and preview-row tooltip/semantics copy to say "Add the
  bottom receipt section before receipt details" instead of generic bottom
  checking language.
- Kept the separate photo-match workflow on `Check / Photo Match`, so
  multi-photo matching remains distinct from the add-bottom continuation path.
- Hardened camera help and capture-layout guards around the visible
  bottom-continuation controls.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_common_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart test/receipt_camera_help_flow_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --plain-name "photo review bottom controls stay capped by mode" -r compact`
- `flutter test test/receipt_camera_help_flow_test.dart --plain-name "receipt capture exposes camera help and long receipt guidance" -r compact`
- `flutter test test/receipt_camera_capture_layout_test.dart --plain-name "photo review async preview work cleans up after lifecycle changes" -r compact`
- `flutter test test/receipt_camera_capture_layout_test.dart --plain-name "photo review tray uses explicit long-receipt language" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_photo_review_common_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart test/receipt_camera_help_flow_test.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_photo_review_common_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart test/receipt_camera_help_flow_test.dart test/receipt_camera_capture_layout_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is making the add-bottom
  action explain and preserve the ghost-slice alignment contract clearly when
  the user opens the camera for the next section.

### Receipt Camera Reopen Pass 1052: Ghost-Slice Alignment Contract

Status: complete.

What changed:
- Added explicit native-session ghost guide contract fields for the repeated
  line target, top ghost-slice placement, and match target.
- Propagated those fields through the CameraX/AVFoundation method-channel
  arguments and privacy-safe capture diagnostics.
- Added the same ghost-slice contract to the phone-camera fallback diagnostics
  so the backup path still reports that the next section should repeat 3-5
  readable lines at the top.
- Updated the ghost guide overlay, alignment sheet, and review-action copy to
  say the user should repeat 3-5 readable lines in the top ghost slice, with
  subtotal, total, and final-line matching for bottom-section continuation.
- Hardened native contract and capture-layout guards so missing bottom edge
  plus missing subtotal/total remains paired with add-bottom ghost guidance.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart lib/shared/widgets/receipt_capture/receipt_native_camera_shell_guidance.dart test/receipt_native_camera_contract_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_native_camera_contract_test.dart --plain-name "session carries previous section guide only for long receipt flow" -r compact`
- `flutter test test/receipt_native_camera_contract_test.dart --plain-name "native service sends previous section guide through channel" -r compact`
- `flutter test test/receipt_camera_capture_layout_test.dart --plain-name "native ghost guide contract keeps repeat-line guidance explicit" -r compact`
- `flutter test test/receipt_camera_capture_layout_test.dart --plain-name "add another photo carries partial receipt reason to ghost guide" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart lib/shared/widgets/receipt_capture/receipt_native_camera_shell_guidance.dart test/receipt_native_camera_contract_test.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart lib/shared/widgets/receipt_capture/receipt_native_camera_shell_guidance.dart test/receipt_native_camera_contract_test.dart test/receipt_camera_capture_layout_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is using the explicit
  ghost-slice contract fields in OCR source handoff and receipt-result
  diagnostics so parser review can distinguish native ghost-guided
  continuation from generic multi-photo capture.

### Receipt Camera Reopen Pass 1053: Ghost-Slice OCR Handoff Diagnostics

Status: complete.

What changed:
- Extended receipt photo review result continuation counts to include the
  previous-section ghost repeat target, ghost-slice placement, and match target
  from both Maintainiac native capture and phone-camera fallback diagnostics.
- Added OCR source handoff helpers that derive a privacy-safe
  `ghostSliceAlignmentStatus` when missing bottom-edge/subtotal-total evidence
  is paired with top ghost-slice alignment signals.
- Added ghost-slice placement, repeat target, match target, and review
  instruction to the OCR source handoff contract without receipt text, file
  paths, or private content.
- Exposed the same ghost-slice status and instruction through receipt totals
  coverage evidence so the parser/review route can distinguish ghost-guided
  bottom continuation from generic multi-photo capture.
- Hardened camera-result and OCR diagnostics guards for native and fallback
  bottom-section continuation.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_camera_result_test.dart test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_camera_result_test.dart --plain-name "review result preserves bottom-section continuation handoff context" -r compact`
- `flutter test test/receipt_camera_result_test.dart --plain-name "phone camera fallback preserves bottom-section continuation handoff" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr diagnostics combines missing totals with bottom coverage risk" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_camera_result_test.dart test/receipt_ocr_service_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_camera_result_test.dart test/receipt_ocr_service_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is making the assisted
  receipt parse/review screen surface the ghost-slice continuation status as
  the reason for "add bottom section" instead of treating it like a generic
  receipt-quality warning.

### Receipt Camera Reopen Pass 1054: Review-Screen Ghost Continuation Reason

Status: complete.

What changed:
- Updated the assisted receipt parse/review screen to use OCR ghost-slice
  continuation status directly, even when parser diagnostics are not the source
  of the bottom-section decision.
- Added fallback review title, message, and action copy for the ghost-guided
  bottom-continuation route: add the bottom receipt section and repeat 3-5
  readable lines in the top ghost slice.
- Updated OCR structure action chips to prefer the explicit top ghost-slice
  instruction when that continuation contract is present.
- Updated OCR structure summary copy so missing bottom edge plus missing
  subtotal/total explains the exact alignment behavior instead of a generic
  overlap-guide warning.
- Hardened assisted-review guards so the review screen keeps the ghost-slice
  status, instruction, and label visible in code.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `dart analyze lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `git diff --check -- lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is tightening the add-photo
  UI route so the bottom-continuation action uses the same ghost-slice reason
  when reopening capture, reviewing the stitched receipt, and moving into
  parsed receipt details.

### Receipt Camera Reopen Pass 1055: Bottom Ghost-Slice Route Labels

Status: complete.

What changed:
- Centralized the bottom-continuation handoff phrase used by receipt photo
  review result labels: add the bottom receipt section and repeat 3-5 readable
  lines in the top ghost slice so subtotal, total, and final lines can be
  matched.
- Updated accepted-photo action, route-result, next-review handoff, and
  next-review readiness labels to use the concrete top ghost-slice instruction
  instead of generic ghost-overlap wording.
- Updated OCR completion action and post-capture route labels so telemetry and
  entry-screen handoff copy carry the same bottom ghost-slice route.
- Updated assisted parse/review fallback copy to instruct the user to add the
  bottom receipt section and repeat 3-5 readable lines in the top ghost slice.
- Hardened focused model, OCR, and assisted-review guards around the new route
  wording.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/receipt_camera_result_test.dart test/receipt_ocr_service_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/receipt_camera_result_test.dart --plain-name "missing bottom edge and totals recommends next receipt section" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr diagnostics combines missing totals with bottom coverage risk" -r compact`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/receipt_camera_result_test.dart test/receipt_ocr_service_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/receipt_camera_result_test.dart test/receipt_ocr_service_test.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is checking the visible
  add-photo/reopen controls and stitch review controls for any remaining
  generic wording or hidden-route behavior around bottom-section continuation.

### Receipt Camera Reopen Pass 1056: Visible Bottom Ghost-Slice Controls

Status: complete.

What changed:
- Updated visible photo-review add-photo controls so the missing-bottom/totals
  path tells the user to add the bottom receipt section and repeat 3-5 readable
  lines in the top ghost slice.
- Updated the top-bar Next/Add Bottom tooltip and semantics copy with the same
  bottom-section ghost-slice instruction before receipt details.
- Updated stitch readiness/fallback copy so stitched receipt review talks about
  repeated receipt lines, not vague photo overlap, and keeps bottom-section
  ghost-slice guidance visible.
- Updated the manual stitch adjustment banner to remind the user to keep 3-5
  readable lines in the top ghost slice for bottom-section photos.
- Hardened focused camera layout guards so the visible bottom-continuation
  controls cannot drift back to generic overlap wording.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart lib/shared/widgets/receipt_capture/receipt_photo_review_stitch_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --plain-name "photo review bottom controls stay capped by mode" -r compact`
- `flutter test test/receipt_camera_capture_layout_test.dart --plain-name "long receipt stitch review shows plain decision evidence" -r compact`
- `flutter test test/receipt_camera_capture_layout_test.dart --plain-name "native ghost guide contract keeps repeat-line guidance explicit" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart lib/shared/widgets/receipt_capture/receipt_photo_review_stitch_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart lib/shared/widgets/receipt_capture/receipt_photo_review_stitch_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is auditing native capture
  shell guidance and reopen handoff labels so the same bottom edge plus
  missing subtotal/total decision drives the camera overlay before another
  section is captured.

### Receipt Camera Reopen Pass 1057: Native Bottom Ghost-Slice Handoff

Status: complete.

What changed:
- Updated the native camera session contract so missing bottom edge plus missing
  subtotal/total defaults to top ghost-slice guidance that repeats 3-5 readable
  lines and targets subtotal, total, and final lines.
- Updated the Flutter native camera overlay fallback copy with the same subtotal,
  total, and final-lines target.
- Updated the add-another-photo alignment guide to say the prior bottom section
  becomes the top ghost-slice guide for the next capture.
- Updated Android CameraX and iOS AVFoundation camera overlays so the actual
  native receipt camera surfaces no longer say generic ghost-area guidance.
- Hardened native shell, help-flow, Android bridge, iOS bridge, and session
  contract guards around the new top ghost-slice handoff copy.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_shell_guidance.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_native_camera_shell_test.dart test/receipt_camera_help_flow_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart --plain-name "Android receipt camera bridge uses CameraX method channel" -r compact`
- `flutter test test/receipt_native_ios_bridge_test.dart --plain-name "iOS receipt camera bridge uses AVFoundation method channel" -r compact`
- `flutter test test/receipt_native_camera_shell_test.dart --plain-name "native camera shell can show long receipt ghost guide" -r compact`
- `flutter test test/receipt_camera_help_flow_test.dart --plain-name "receipt capture exposes camera help and long receipt guidance" -r compact`
- `flutter test test/receipt_native_camera_contract_test.dart --plain-name "session carries previous section guide only for long receipt flow" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_shell_guidance.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_native_camera_shell_test.dart test/receipt_camera_help_flow_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_native_camera_contract_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_shell_guidance.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart android/app/src/main/kotlin/com/maintainiac/ReceiptCameraActivity.kt ios/Runner/ReceiptCameraViewController.swift test/receipt_native_camera_shell_test.dart test/receipt_camera_help_flow_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_native_camera_contract_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is wiring the bottom
  edge/subtotal-total completion decision into clearer receipt-completeness
  diagnostics so the app can explain why it is asking for another section
  without blocking manual capture.

### Receipt Camera Reopen Pass 1058: Bottom Completion Decision Metadata

Status: complete.

What changed:
- Updated the bottom-edge/subtotal-total decision guidance so it tells the user
  to use the top ghost-slice guide and repeat 3-5 readable lines for subtotal,
  total, and final-line matching.
- Added explicit privacy-safe coverage metadata for ghost guide placement,
  repeat-line target, and match target so downstream review/camera/telemetry
  paths can stay aligned without storing receipt content.
- Added a completion evidence summary label that explains the two-signal rule:
  bottom edge missing plus subtotal/total missing.
- Updated the continuation contract label to stop using generic ghost-overlap
  wording for the missing-bottom/totals path.
- Hardened focused receipt result guards for the new diagnostics.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart`
- `flutter test test/receipt_camera_result_test.dart --plain-name "missing bottom edge and totals recommends next receipt section" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr diagnostics combines missing totals with bottom coverage risk" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart test/receipt_ocr_service_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart test/receipt_ocr_service_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is auditing the assisted
  parse/review route for any remaining generic ghost-overlap copy so the parsed
  receipt details screen carries the same bottom-section proof trail.
