# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 1059: Assisted Review Top Ghost-Slice Trail

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 1059: Assisted Review Top Ghost-Slice Trail

Status: complete.

What changed:
- Updated expense receipt parse diagnostics so the missing-bottom/totals route
  tells the user to add the bottom receipt section with the top ghost-slice
  guide and repeat 3-5 readable lines.
- Updated continuation review labels from generic ghost-guide wording to
  `Bottom continuation uses top ghost slice`.
- Updated continuation instructions and action labels to use the top ghost
  slice wording instead of vague overlap guidance.
- Updated the assisted receipt parse/review screen bottom-section alert and
  structure summary so parsed receipt details carry the same bottom-section
  proof trail.
- Hardened assisted-review and parser guards for the new copy.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart test/expense_receipt_parser_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "parses expense fields from OCR parser-ready receipt signals" -r compact`
- `dart analyze lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart test/expense_receipt_parser_test.dart`
- `git diff --check -- lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart test/expense_receipt_parser_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is a broader stale-copy
  sweep for remaining generic bottom/overlap labels in receipt capture,
  especially places that should reference top ghost-slice guidance only when
  the missing-bottom/totals route is active.

### Receipt Camera Reopen Pass 1060: Stale Overlap Copy Sweep

Status: complete.

What changed:
- Updated the receipt entry screen continuation handoff so missing bottom edge
  plus missing subtotal/total tells the user to add the bottom receipt section,
  repeat 3-5 readable lines in the top ghost slice, and match subtotal, total,
  and final lines.
- Updated general long-receipt help and first-use tips from vague overlap copy
  to the explicit top ghost-slice repeat-line rule.
- Updated assisted-review chips from `Use overlap guide` to `Use top ghost
  slice` for the bottom/totals route.
- Updated native camera shell semantics from generic overlap-guide language to
  top ghost-slice guide language.
- Confirmed the old user-facing phrases `Use overlap guide`, `overlap a few
  lines`, `ghost overlap guide`, and stale ghost-guide labels are gone from the
  searched local app/test/platform paths.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/shared/widgets/receipt_capture/receipt_camera_help_sheet.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart lib/shared/widgets/receipt_capture/receipt_native_camera_shell_guidance.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `flutter test test/receipt_camera_help_flow_test.dart --plain-name "receipt capture exposes camera help and long receipt guidance" -r compact`
- `flutter test test/receipt_native_camera_shell_test.dart --plain-name "native camera shell can show long receipt ghost guide" -r compact`
- `flutter test test/receipt_camera_capture_layout_test.dart --plain-name "native ghost guide contract keeps repeat-line guidance explicit" -r compact`
- `dart analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/shared/widgets/receipt_capture/receipt_camera_help_sheet.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart lib/shared/widgets/receipt_capture/receipt_native_camera_shell_guidance.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_help_flow_test.dart test/receipt_native_camera_shell_test.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check -- lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/shared/widgets/receipt_capture/receipt_camera_help_sheet.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart lib/shared/widgets/receipt_capture/receipt_native_camera_shell_guidance.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is tightening the remaining
  long-receipt section labels and match-panel copy so generic overlap wording
  remains only for non-bottom/totals matching contexts.

### Receipt Camera Reopen Pass 1061: Long-Receipt Match Copy Tightening

Status: complete.

What changed:
- Updated long-receipt section strip guidance so normal continuation photos
  use `3-5 repeated readable lines` instead of vague `a few repeated lines`.
- Updated middle-section review guidance with the same 3-5 readable-line
  standard.
- Updated the manual stitch/match overlay from `overlap guide` wording to
  `match guide` while preserving the match-percentage evidence.
- Updated stitch OCR handoff expectation labels from vague repeated-line copy
  to `Repeat 3-5 readable lines between sections`.
- Hardened camera layout guards around the updated section-label and match-panel
  copy.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_section_labels.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --plain-name "long receipt stitch review shows plain decision evidence" -r compact`
- `flutter test test/receipt_camera_capture_layout_test.dart --plain-name "photo review bottom controls stay capped by mode" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_photo_review_section_labels.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_photo_review_section_labels.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_capture_layout_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is hardening local OCR
  diagnostics so bottom-section continuation signals include enough
  non-private evidence for parser decisions without requiring cloud assistance.

### Receipt Camera Reopen Pass 1062: Local OCR Bottom Evidence Summary

Status: complete.

What changed:
- Added a privacy-safe missing-bottom/totals evidence code to local OCR source
  handoff diagnostics.
- Added a privacy-safe evidence label explaining whether the bottom/totals
  route came from multiple local evidence families, coverage signals,
  continuation signals, handoff signals, or quality signals.
- Added a local evidence-family count so parser/review decisions can tell when
  more than one signal family agreed without storing receipt text.
- Passed the evidence code, label, and family count through receipt totals
  coverage diagnostics for assisted review and parser use.
- Hardened OCR tests around the new local-only bottom-continuation evidence
  and top ghost-slice guidance.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr diagnostics combines missing totals with bottom coverage risk" -r compact`
- `flutter test test/receipt_camera_result_test.dart --plain-name "single partial receipt photo recommends next section before details" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart test/receipt_camera_result_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is using the new
  missing-bottom/totals evidence summary in parser-facing diagnostics and
  review copy where it improves the user-facing explanation without adding
  clutter.

### Receipt Camera Reopen Pass 1063: Parser-Facing Local Evidence Summary

Status: complete.

What changed:
- Carried the local missing-bottom/totals evidence code, label, and evidence
  family count from OCR diagnostics into expense parser diagnostics.
- Added a parser diagnostics review label that explains when the bottom edge
  and subtotal/total evidence are missing together without exposing receipt
  text.
- Updated app-assisted receipt review copy so the next-section route can cite
  the local bottom/totals evidence before asking for the bottom receipt section.
- Hardened parser and assisted-flow tests so the evidence can no longer drop
  between OCR, parser diagnostics, and review copy.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "parses expense fields from OCR parser-ready receipt signals" -r compact`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `dart analyze lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `git diff --check -- lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is using this parser-facing
  bottom/totals evidence to harden the actual route decision so missing bottom
  edge plus missing subtotal/total cannot fall back to a normal receipt-complete
  review path.

### Receipt Camera Reopen Pass 1064: Bottom Evidence Route Decision Hardening

Status: complete.

What changed:
- Added parsed-receipt handoff helpers so bottom-edge plus missing
  subtotal/total evidence routes to `Add bottom receipt section` instead of the
  generic `Open receipt details` decision.
- Applied the same route decision to both usable parsed receipts and manual
  parsed fallback receipts so partially read receipts do not lose the bottom
  continuation warning.
- Updated the parsed receipt stage/action/result labels to preserve the
  privacy-safe local bottom/totals evidence in the route result.
- Hardened assisted-flow string guards around the new route helpers and
  add-bottom decision label.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `dart analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/expense_receipt_assisted_review_flow_test.dart`
- `git diff --check -- lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is strengthening the camera
  and review handoff so accepted photo decisions can request another bottom
  section before OCR when bottom-edge and subtotal/total evidence are both weak.

### Receipt Camera Reopen Pass 1065: Accepted Photo Bottom-Section Route Pause

Status: complete.

What changed:
- Changed accepted-photo handoff route metadata so a photo flagged for missing
  bottom edge plus missing subtotal/total does not claim receipt details should
  open immediately.
- Added a bottom-section next-screen code for accepted photos that need the
  lower receipt section before receipt details.
- Paused `acceptedPhotoHandoffMustOpenFilledReview` and
  `acceptedPhotoHandoffMustOpenReceiptDetails` when another bottom section is
  required.
- Hardened camera result tests around the bottom-section route, next screen,
  processing label, and must-open flags.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart`
- `flutter test test/receipt_camera_result_test.dart --plain-name "single partial receipt photo recommends next section before details" -r compact`
- `flutter test test/receipt_camera_capture_layout_test.dart --plain-name "reviewed receipt photos announce app fill handoff safely" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is making the UI layer
  consume this paused bottom-section route instead of showing generic receipt
  details language while the bottom section is still needed.

### Receipt Camera Reopen Pass 1066: Import Flow Bottom-Section OCR Pause

Status: complete.

What changed:
- Updated both reviewed-photo accept paths so a photo that still needs the
  bottom receipt section does not immediately run OCR or open receipt details.
- Added a shared pause helper that saves the accepted photo, shows a plain
  warning status, and tells the user to add the bottom section with the
  ghost-slice overlap before receipt details open.
- Added privacy-safe diagnostics for the pause route, next screen, reason,
  user action, and handoff metadata without logging receipt text.
- Hardened the layout guard so this pause cannot be removed without a failing
  test.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --plain-name "reviewed receipt photos announce app fill handoff safely" -r compact`
- `flutter test test/receipt_camera_result_test.dart --plain-name "single partial receipt photo recommends next section before details" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is making the continuation
  capture re-entry more direct so the user can add the bottom photo from the
  paused state without hunting through generic receipt import choices.

### Receipt Camera Reopen Pass 1067: Direct Add-Bottom Re-Entry

Status: complete.

What changed:
- Added a small paused-bottom-section state to the shared receipt attachment
  panel.
- When the bottom section is needed, the add button now reads
  `Add Bottom Section`, uses a bottom-align icon, and opens the receipt camera
  directly instead of the generic import picker.
- Cleared the paused state when OCR begins, attachments are cleared, or the
  final photo is removed so the button does not stay stuck in bottom-section
  mode.
- Cleared stale photo capture diagnostics when attachments are cleared or a
  photo is removed so old continuation evidence does not leak into the next
  receipt attempt.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --plain-name "reviewed receipt photos announce app fill handoff safely" -r compact`
- `flutter test test/receipt_camera_result_test.dart --plain-name "single partial receipt photo recommends next section before details" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is strengthening the
  continuation capture options so the next camera launch receives explicit
  bottom-section guidance even when the widget did not get an external
  continuation reason.

### Receipt Camera Reopen Pass 1068: Explicit Bottom Continuation Reason

Status: complete.

What changed:
- Added shared continuation helpers so the next camera launch uses the paused
  bottom-section state as the reason source.
- When the app paused because the bottom edge plus subtotal/total evidence were
  missing, the next camera launch now receives
  `missing_bottom_edge_and_totals`.
- Added bottom-section guidance telling the capture flow to repeat 3-5 readable
  lines in the top ghost slice so subtotal, total, and final lines can be
  matched.
- Preserved the existing external continuation reason for callers that already
  provide one.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --plain-name "reviewed receipt photos announce app fill handoff safely" -r compact`
- `flutter test test/receipt_camera_result_test.dart --plain-name "single partial receipt photo recommends next section before details" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is verifying the native
  capture diagnostics and review screen actually surface the explicit
  continuation reason as a bottom ghost-slice capture, then tighten any missing
  bridge metadata.

### Receipt Camera Reopen Pass 1069: Bottom Ghost Guide Re-Entry Safety

Status: complete.

What changed:
- Hardened bottom-section camera re-entry so the paused
  `missing_bottom_edge_and_totals` route forces long-receipt mode on.
- This keeps the previous-photo ghost guide available even if general
  long-receipt tips are disabled in settings.
- Forced auto-capture off for the bottom-section re-entry so the camera does
  not snap before the user lines up the top ghost-slice overlap.
- Added layout guards for the continuation helpers and the true/false overrides
  that protect this behavior.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --plain-name "reviewed receipt photos announce app fill handoff safely" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_capture_layout_test.dart`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is strengthening the
  review-screen continuation state after the bottom photo is accepted so the
  combined/ordered receipt can proceed to OCR only when coverage is complete or
  explicitly confirmed.

### Receipt Camera Reopen Pass 1070: Final Section Totals Gate

Status: complete.

What changed:
- Added final-section coverage logic so ordered multi-photo receipts do not
  automatically proceed to OCR/details when the newest section is still missing
  bottom-edge plus subtotal/total evidence.
- Kept the existing good path where an earlier top section may be partial, but
  a later bottom section is complete enough to continue as ordered receipt
  sections.
- Prioritized `missing_bottom_edge_and_totals` as the route reason when the
  final section still needs the bottom/totals continuation.
- Added regression coverage for two ordered sections where the final section is
  still missing bottom/totals.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart`
- `flutter test test/receipt_camera_result_test.dart --plain-name "ordered sections still request bottom section when final totals are missing" -r compact`
- `flutter test test/receipt_camera_result_test.dart --plain-name "photo review result summarizes possible partial receipt photos" -r compact`
- `flutter test test/receipt_camera_result_test.dart --plain-name "single partial receipt photo recommends next section before details" -r compact`
- `flutter test test/receipt_camera_capture_layout_test.dart --plain-name "reviewed receipt photos announce app fill handoff safely" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is improving OCR/readiness
  diagnostics for final-section totals so the app can explain whether it is
  missing bottom edge, subtotal/total words, total amount, or all of them.

### Receipt Camera Reopen Pass 1071: Final Section Evidence Summary

Status: complete.

What changed:
- Added a privacy-safe final-section continuation evidence map to
  `ReceiptPhotoReviewResult`.
- The evidence records whether bottom/totals continuation is needed, whether
  bottom edge/subtotal/total/total amount signals were confirmed, the totals
  evidence status token, and the missing evidence family count.
- Added a user-safe label explaining that bottom edge, subtotal/total words,
  and total amount were not confirmed without exposing receipt text.
- Surfaced the evidence map and label in receipt-reader handoff metadata only
  when another section is required.
- Expanded the ordered-sections regression test to prove the evidence is
  present and privacy-safe.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart`
- `flutter test test/receipt_camera_result_test.dart --plain-name "ordered sections still request bottom section when final totals are missing" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is using this evidence
  label in the pause status copy so users understand why the app is asking for
  the bottom section without showing diagnostic jargon.

### Receipt Camera Reopen Pass 1072: User-Safe Bottom Pause Copy

Status: complete.

What changed:
- Updated the bottom-section pause status to use the user-safe final-section
  evidence label instead of the compact handoff evidence string.
- The banner now explains that bottom edge, subtotal/total words, and total
  amount were not confirmed before asking for the bottom receipt section.
- Kept the exact ghost-slice next-step guidance after the plain-language reason.
- Added a layout guard so the pause copy keeps using the final-section evidence
  label.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --plain-name "reviewed receipt photos announce app fill handoff safely" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_capture_layout_test.dart`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is running the focused
  camera result/layout/native guide suite together and then auditing the OCR
  parser handoff for any remaining path that can open details before coverage
  is complete.

### Receipt Camera Reopen Pass 1073: Defensive OCR Coverage Gate

Status: complete.

What changed:
- Added a defensive incomplete-coverage gate inside
  `_readReviewedPhotosForReceiptForm`.
- Even if a future accept path calls the OCR read helper directly, the helper
  now reuses the bottom-section pause before OCR starts and returns a skipped
  read result.
- Added a layout guard so the defensive read helper gate stays present.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --plain-name "reviewed receipt photos announce app fill handoff safely" -r compact`
- `flutter test test/receipt_camera_result_test.dart --plain-name "ordered sections still request bottom section when final totals are missing" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is auditing the expense
  parser handoff so OCR diagnostics that say bottom/totals are missing cannot
  be treated as a normal ready-to-save receipt.

### Receipt Camera Reopen Pass 1074: Expense Handoff Bottom-Section Gate

Status: complete.

What changed:
- Tightened `_markReceiptReadFinished` so a receipt OCR result that already
  flagged missing bottom edge plus missing subtotal/total evidence cannot be
  overwritten as a normal ready-to-review receipt.
- When both evidence families are missing, the receipt handoff now stays on
  `Add bottom receipt section`, uses the bottom-section stage, and keeps the
  bottom-section warning/result copy.
- When subtotal/total evidence is missing or the receipt may need a bottom
  section, the handoff stays in bottom-check/bottom-section review instead of
  pretending the details are simply ready.
- Updated assisted-flow source guards so the bottom-section override, ghost
  continuation reason, and pause-before-OCR path remain protected.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `dart analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/expense_receipt_assisted_review_flow_test.dart`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is auditing the review UI
  copy and action labels so every partial-receipt state says exactly why another
  section is needed: missing bottom edge, missing subtotal/total text, missing
  total amount, or user-confirmed complete.
