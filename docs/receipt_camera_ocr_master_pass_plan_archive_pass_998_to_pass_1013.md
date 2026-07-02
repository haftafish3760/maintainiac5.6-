# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 998: Generic Totals Missing Guard

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 998: Generic Totals Missing Guard

Status: complete.

What changed:
- Strengthened OCR diagnostics tests so generic missing subtotal/total text does
  not automatically claim bottom-edge/totals evidence.
- The generic missing-totals test now verifies
  `ocrSourceBottomCoverageRiskDetected == false`,
  `receiptMissingBottomEdgeAndTotals == false`, and no continuation signal
  counts are exposed.
- Added a source-handoff guard proving a normal OCR source does not create
  bottom coverage evidence while `receipt_handoff_possible_partial_receipt`
  does.

Validation:
- `dart format test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is moving from diagnostics
  proof into parser handoff behavior, so parsed receipt details can use the
  combined bottom/totals decision without confusing it with ordinary total-field
  review.

### Receipt Camera Reopen Pass 999: Parser Task Coverage Buckets

Status: complete.

What changed:
- OCR diagnostics parser task counts now add privacy-safe receipt coverage
  buckets after warning buckets are merged.
- Generic missing subtotal/total/tax text now adds
  `receipt_totals_text_missing_review` and
  `receipt_missing_totals_manual_review`.
- Combined bottom-edge/totals evidence now adds
  `receipt_missing_bottom_edge_and_totals` and
  `receipt_bottom_section_continuation_needed`.
- Added tests proving the generic path does not get the continuation buckets and
  the combined path does not get the manual-only bucket.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr diagnostics" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is making the expense
  review panel consume these parser-task buckets for cleaner user guidance.

### Receipt Camera Reopen Pass 1000: Review Actions From Coverage Tasks

Status: complete.

What changed:
- The OCR review row now consumes the new parser task buckets for receipt
  coverage decisions.
- Combined bottom-edge/totals task buckets surface `Add next receipt section`,
  `Use overlap guide`, and `Review totals after OCR`.
- Generic totals-missing task buckets surface `Check totals section` and
  `Enter total manually`.
- Action priority now keeps `Add next receipt section` and `Use overlap guide`
  near the top when the combined long-receipt path is active.
- Added review-flow source guards for the new task keys and labels.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `dart analyze lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `git diff --check -- lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is tightening parser
  summaries so the text body mirrors the action labels for bottom/totals
  recovery.

### Receipt Camera Reopen Pass 1001: Parser Summary Bottom Recovery Copy

Status: complete.

What changed:
- Parser signal summaries now include `bottom section continuation needed` when
  the combined bottom-edge/totals parser task is active.
- Parser signal summaries now include `totals need manual review` when totals
  text is missing without bottom coverage evidence.
- The OCR review body now has specific parser readiness copy for the combined
  bottom/totals path and a separate generic totals-review copy for ordinary
  missing totals.
- Added tests/guards for both summary phrases.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/receipt_ocr_service_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr diagnostics" -r compact`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/receipt_ocr_service_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/receipt_ocr_service_test.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is checking whether the
  long-receipt continuation path preserves this parser context when the next
  section is added and OCR is rerun.

### Receipt Camera Reopen Pass 1002: Continuation Handoff Preservation

Status: complete.

What changed:
- `ReceiptPhotoReviewResult` now exposes a privacy-safe continuation handoff
  summary with status and reason counts, so the app can remember when OCR asked
  for the next bottom receipt section.
- The handoff status distinguishes ordinary review continuation from
  `ocr_requested_bottom_section_continuation`.
- Both shared capture flow and receipt import actions now add matching
  continuation document signals and OCR risk flags before source-specific OCR
  work begins.
- Added regression coverage proving bottom-section continuation context is
  preserved without leaking local receipt paths.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart test/receipt_camera_result_test.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter test test/receipt_camera_result_test.dart --plain-name "continuation" -r compact`
- `flutter test test/receipt_capture_flow_shareability_test.dart -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart test/receipt_camera_result_test.dart test/receipt_capture_flow_shareability_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart test/receipt_camera_result_test.dart test/receipt_capture_flow_shareability_test.dart`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is making the next-section
  capture/review route show the ghost-overlap continuation state clearly while
  keeping the OCR source-first handoff intact.

### Receipt Camera Reopen Pass 1003: Native Ghost Overlap Guidance Label

Status: complete.

What changed:
- The reusable native receipt camera shell now accepts previous-section reason
  and guidance text alongside the previous-section preview.
- The long-receipt ghost strip now includes a compact user-facing label,
  `Match the bottom section`, when the prior decision was the combined
  bottom-edge/subtotal-total continuation path.
- Added a small alignment rule, `Line up repeated receipt text here`, so the
  ghost area explains what the user should do without blocking the camera
  preview.
- Added widget coverage proving the long-receipt ghost guide renders the label,
  custom guidance, and alignment rule.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_camera_shell.dart lib/shared/widgets/receipt_capture/receipt_native_camera_shell_guidance.dart test/receipt_native_camera_shell_test.dart`
- `flutter test test/receipt_native_camera_shell_test.dart --plain-name "native camera shell can show long receipt ghost guide" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_native_camera_shell.dart lib/shared/widgets/receipt_capture/receipt_native_camera_shell_guidance.dart test/receipt_native_camera_shell_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_native_camera_shell.dart lib/shared/widgets/receipt_capture/receipt_native_camera_shell_guidance.dart test/receipt_native_camera_shell_test.dart`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is threading the same
  ghost-overlap reason/guidance into any Flutter-side shell previews and
  platform diagnostics so Android and iOS remain aligned.

### Receipt Camera Reopen Pass 1004: Native Ghost Guide Platform Parity

Status: complete.

What changed:
- Android CameraX receipt capture now uses the same bottom-section guide copy
  as the shared shell when the reason is `missing_bottom_edge_and_totals`.
- iOS AVFoundation receipt capture now uses the same guide title/instruction
  and accessibility label.
- Native diagnostics now include privacy-safe ghost guide title/instruction
  fields so health tooling can see which guide was presented without storing
  receipt content.
- Android and iOS bridge tests now guard the new bottom-section wording and
  diagnostic keys.

Validation:
- `dart format test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart --plain-name "Android receipt camera bridge uses CameraX method channel" -r compact`
- `flutter test test/receipt_native_ios_bridge_test.dart --plain-name "iOS receipt camera bridge uses AVFoundation method channel" -r compact`
- `flutter test test/receipt_native_camera_shell_test.dart --plain-name "native camera shell can show long receipt ghost guide" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_native_camera_shell.dart lib/shared/widgets/receipt_capture/receipt_native_camera_shell_guidance.dart test/receipt_native_camera_shell_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `git diff --check -- android/app/src/main/kotlin/com/maintainiac/ReceiptCameraActivity.kt ios/Runner/ReceiptCameraViewController.swift lib/shared/widgets/receipt_capture/receipt_native_camera_shell.dart lib/shared/widgets/receipt_capture/receipt_native_camera_shell_guidance.dart test/receipt_native_camera_shell_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is tightening the
  next-section action from receipt review so the Add Bottom Section path opens
  the native camera with the correct previous-section guide every time.

### Receipt Camera Reopen Pass 1005: Add Bottom Section Pre-Camera Copy

Status: complete.

What changed:
- The Add Another/Add Bottom Section alignment sheet now passes
  `missingBottomAndTotals` into its helper note.
- When the prior section is missing bottom-edge and subtotal/total evidence,
  the pre-camera sheet tells the user the next camera session will open with a
  bottom-section ghost guide.
- The helper copy now explicitly tells the user to keep the last readable lines
  in the ghost area so subtotal and total lines can be matched.
- Added source guard coverage for the bottom-section note and matching language.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --plain-name "add another photo carries partial receipt reason to ghost guide" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is making OCR completion
  and receipt review remember that a next-section capture was prompted from the
  bottom-edge/totals rule, so the app can separate successful completion from a
  user choosing to continue anyway.

### Receipt Camera Reopen Pass 1006: Continue-Anyway Completion Evidence

Status: complete.

What changed:
- Receipt photo review now records the single-photo completion dialog choice per
  photo before OCR source prep.
- `Continue And Review` becomes a privacy-safe handoff signal instead of
  silently looking like an unresolved missing-bottom warning.
- `ReceiptPhotoReviewResult` now distinguishes:
  `needs_next_section_before_details`,
  `user_confirmed_complete_after_prompt`,
  `completed_with_ordered_sections`, and stitched completion.
- Receipt details may open after an explicit user confirmation while still
  preserving the warning evidence for OCR/parser review.
- Added regression coverage for the exact difference between an unconfirmed
  partial receipt and a user-confirmed partial receipt.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_result_test.dart --plain-name "single partial receipt photo" -r compact`
- `flutter test test/receipt_camera_capture_layout_test.dart --plain-name "add another photo carries partial receipt reason to ghost guide" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is feeding the
  continue-anyway completion evidence into OCR diagnostics/parser task buckets
  so the review screen can say "user confirmed full receipt" separately from
  "missing bottom section".

### Receipt Camera Reopen Pass 1007: Confirmed Complete OCR Parser Buckets

Status: complete.

What changed:
- OCR source handoff now carries receipt completion signal counts alongside
  continuation signal counts.
- OCR diagnostics now distinguish `user_confirmed_complete_after_prompt` from
  unresolved missing-bottom continuation.
- If OCR found receipt text but no subtotal/total/tax evidence, and the user
  explicitly confirmed the photo was complete, parser tasks now use
  user-confirmed review buckets instead of forcing the Add Next Section bucket.
- The receipt parse review screen now shows confirmation-review actions and
  summaries for user-confirmed receipts whose totals still need checking.
- Added regression coverage for the exact edge case: bottom edge/totals looked
  missing, the user continued anyway, and the parser must review totals without
  routing back into another camera section.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/receipt_ocr_service_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "user confirmed complete receipt separates review from continuation" -r compact`
- `flutter test test/receipt_capture_flow_shareability_test.dart -r compact`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "review" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/receipt_ocr_service_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_capture_flow_shareability_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/receipt_ocr_service_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_capture_flow_shareability_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is tightening the live
  receipt capture/review UI behavior around the same bottom-edge + subtotal/
  total decision so the camera flow asks for another section only when the
  evidence and the user's choice both support that route.

### Receipt Camera Reopen Pass 1008: Backup Camera Bottom-Section Handoff

Status: complete.

What changed:
- Phone-camera fallback now preserves the previous-section coverage decision
  when Maintainiac native capture is unavailable.
- Fallback capture diagnostics now carry the previous-section reason, guidance,
  and `missing_bottom_edge_and_totals` state.
- `ReceiptPhotoReviewResult` now counts phone-camera fallback continuation
  evidence the same way it counts native previous-section evidence.
- Added regression coverage proving backup camera captures still publish the
  bottom-edge/subtotal-total continuation handoff without leaking file paths.
- Added layout source guards so the fallback metadata remains attached while
  the camera/review UI continues to be cleaned up.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_result_test.dart --plain-name "phone camera fallback preserves bottom-section continuation handoff" -r compact`
- `flutter test test/receipt_camera_capture_layout_test.dart --plain-name "add another photo carries partial receipt reason to ghost guide" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is the visible review
  screen affordance for long receipts: make Add Bottom Section / Next / Review
  state obvious without relying on hidden controls or confusing labels.

### Receipt Camera Reopen Pass 1009: Clear Bottom-Section Review Actions

Status: complete.

What changed:
- The photo review preview tray now uses a specific `Add Bottom` button when
  bottom-edge plus subtotal/total evidence indicates the lower receipt section
  may be missing.
- The button tooltip and semantics say the full action: add the bottom receipt
  section with overlap from the current photo.
- `Next If Complete` now renders as a stacked `Next / If Complete` button so
  the forward path is visible without a cramped single-line label.
- Added layout contract coverage for the clearer bottom-section action and the
  stacked Next label.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_common_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --plain-name "post-capture quality copy leads with action and evidence" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_common_controls.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_common_controls.dart test/receipt_camera_capture_layout_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is tightening the actual
  photo review tray footprint and overflow behavior so controls stay visible
  without covering too much of the receipt preview.

### Receipt Camera Reopen Pass 1010: Compact Preview Tray Footprint

Status: complete.

What changed:
- Preview-mode receipt review controls now cap at 20% of safe screen height
  instead of 22%.
- Preview-mode absolute height caps were reduced for both single-photo and
  multi-photo review.
- Primary preview-row buttons were trimmed from 38px to 36px minimum height.
- Horizontal action rails were trimmed from 34px to 32px.
- The footprint guard test now checks the tighter preview caps and compact
  button/rail dimensions.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_common_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --plain-name "photo review bottom controls stay capped by mode" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_common_controls.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_common_controls.dart test/receipt_camera_capture_layout_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is making the long-receipt
  prompt and action labels line up exactly with the OCR bottom/subtotal/total
  reason in all visible review surfaces.

### Receipt Camera Reopen Pass 1011: Bottom-Section Label Parity

Status: complete.

What changed:
- The preview action row and the recovery strip now both use bottom-specific
  wording when the coverage reason is `missing_bottom_edge_and_totals`.
- The recovery strip no longer falls back to generic `Add Next Section` for the
  same bottom-edge/subtotal-total condition.
- Added layout guard coverage so the missing-bottom decision controls the
  recovery-strip add button as well as the primary action row.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --plain-name "post-capture quality copy leads with action and evidence" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart test/receipt_camera_capture_layout_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is making native CameraX
  and AVFoundation visible action labels match the same bottom-section reason
  instead of only using generic Add Next wording.

### Receipt Camera Reopen Pass 1012: Native Bottom-Section Action Labels

Status: complete.

What changed:
- Android CameraX receipt capture now shows `Add Bottom` for the add-section
  button when the previous section reason is `missing_bottom_edge_and_totals`.
- iOS AVFoundation receipt capture now uses the same bottom-specific
  add-section label.
- Native accessibility labels now say `Add bottom receipt section with overlap
  from this photo` for that bottom-section case.
- Added bridge/layout guards for the native helper methods and label wiring.

Validation:
- `dart format test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart -r compact`
- `flutter test test/receipt_native_ios_bridge_test.dart -r compact`
- `flutter test test/receipt_camera_capture_layout_test.dart --plain-name "photo review tray uses explicit long-receipt language" -r compact`
- `dart analyze test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check -- android/app/src/main/kotlin/com/maintainiac/ReceiptCameraActivity.kt ios/Runner/ReceiptCameraViewController.swift test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_camera_capture_layout_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is strengthening the
  decision source that sets `missing_bottom_edge_and_totals`: bottom-edge
  coverage evidence plus OCR subtotal/total evidence must decide whether the
  receipt likely needs another bottom photo.

### Receipt Camera Reopen Pass 1013: Bottom-Section Handoff Specificity

Status: complete.

What changed:
- Receipt photo review results now use bottom-specific handoff wording when
  the first possible-partial reason is `missing_bottom_edge_and_totals`.
- The next review handoff label now says to add the bottom receipt section with
  overlap instead of the generic next section for that same reason.
- The OCR/readiness label now keeps the same bottom-specific instruction, so
  the UI, model, and diagnostics agree on the next action.
- Added focused result coverage for the bottom-section handoff label, next
  review label, and match-readiness label.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart`
- `flutter test test/receipt_camera_result_test.dart --plain-name "missing bottom edge and totals recommends next receipt section" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is tightening the native
  captured-photo diagnostics that feed bottom-edge status, totals text
  evidence, and the long-receipt ghost-guide request.
