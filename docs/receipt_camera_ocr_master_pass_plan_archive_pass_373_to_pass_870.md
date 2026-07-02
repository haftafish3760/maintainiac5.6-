# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 373 / Total Pass 453: Recovery Telemetry Receipt Details Naming Batch

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 373 / Total Pass 453: Recovery Telemetry Receipt Details Naming Batch

Status: complete.

What changed:
- Renamed native capture/recovery flow reasons that still said
  `accepted_for_reader` to `accepted_for_receipt_details`.
- Renamed recovery resume routes from `before_reader` to
  `before_receipt_details`.
- Renamed saved-for-later outcome/count tokens from reader language to receipt
  details language.
- Renamed the saved-proof compression policy from
  `saved_proof_created_after_receipt_read_source` to
  `saved_proof_created_after_receipt_details_source`.
- Updated result and native staging tests so saved photos, accepted recovery,
  and recovery stage updates all use receipt-details terminology.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart test/receipt_camera_result_test.dart test/receipt_native_capture_staging_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart test/receipt_camera_result_test.dart test/receipt_native_capture_staging_test.dart`
- `flutter test test/receipt_camera_result_test.dart --name "kept for later review does not open receipt details input" -r compact`
- `flutter test test/receipt_native_capture_staging_test.dart --name "recovery stage updates manifest and Hive index safely" -r compact`
- `flutter test test/receipt_native_capture_staging_test.dart --name "accepted native capture is copied into receipt staging" -r compact`
- `rg -n "for_reader|before_reader|receipt_review_reader_not_accepted|not_accepted_for_reader_yet|saved_proof_created_after_receipt_read_source|read_receipt_or_save_proof|receipt_photos_accepted_for_reader|recovered_receipt_photos_accepted_for_reader|recovery_review_accepted_for_reader" lib/shared/widgets/receipt_capture test/receipt_camera_result_test.dart test/receipt_native_capture_staging_test.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is cleaning remaining "receipt reading"
  copy in local OCR/PDF warning paths where it affects user-facing flow clarity,
  while keeping PDF implementation work out of scope.

### Receipt Camera Reopen Pass 374 / Total Pass 454: Receipt Assistance Copy Alignment Batch

Status: complete.

What changed:
- Replaced user-facing "receipt reading" copy with "receipt assistance" or
  "receipt details" across local OCR warnings, attachment OCR actions, data
  saver review copy, native bridge guidance, expense review/save summaries, and
  export/calendar summaries.
- Kept backward-compatible warning classifiers for old stored strings while
  adding recognition for the new assistance failure/off wording.
- Updated Android CameraX and iOS AVFoundation bridge copy so both native
  camera contracts say save-space proof copies are applied after receipt
  assistance uses the clearest source.
- Changed accepted-photo handoff stage text to "Opening receipt details from
  accepted photo" so the post-photo flow says what is actually happening next.
- Updated source-guard and unit tests that pin OCR warning labels, device
  policy text, bridge text, saved-proof data saver text, and assisted receipt
  routing language.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_pdf_viewer_status.dart lib/shared/widgets/receipt_capture/receipt_pdf_inspection.dart lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart lib/shared/widgets/receipt_capture/receipt_photo_review_mode_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_data_saver_panel.dart lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/screens/expenses/data/expense_receipt_ocr_review.dart lib/screens/expenses/data/expense_export_models.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart lib/screens/expenses/entry/expense_receipt_save_actions.dart lib/screens/expenses/calendar/expense_calendar_models.dart test/receipt_ocr_service_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_pdf_viewer_status.dart lib/shared/widgets/receipt_capture/receipt_pdf_inspection.dart lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart lib/shared/widgets/receipt_capture/receipt_photo_review_mode_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_data_saver_panel.dart lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/screens/expenses/data/expense_receipt_ocr_review.dart lib/screens/expenses/data/expense_export_models.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart lib/screens/expenses/entry/expense_receipt_save_actions.dart lib/screens/expenses/calendar/expense_calendar_models.dart test/receipt_ocr_service_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_assistance_policy_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_result_test.dart test/receipt_camera_help_flow_test.dart test/receipt_capture_flow_shareability_test.dart test/expense_ledger_store_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --name "ocr service can skip photo assistance for a limited device profile" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --name "ocr service can disable PDF assistance for a limited device profile" -r compact`
- `flutter test test/receipt_assistance_policy_test.dart --name "low storage phones keep local OCR while cloud OCR stays optional" -r compact`
- `flutter test test/receipt_camera_help_flow_test.dart --name "reviewed camera photos read OCR sources before saved copies" -r compact`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "receipt photo back protects captured images from silent discard" -r compact`
- `flutter test test/receipt_capture_flow_shareability_test.dart --name "shared capture keeps UI labels on next/review language" -r compact`
- `flutter test test/receipt_native_android_bridge_test.dart -r compact`
- `flutter test test/receipt_native_ios_bridge_test.dart --name "iOS receipt camera bridge uses AVFoundation method channel" -r compact`
- `flutter test test/expense_ledger_store_test.dart --name "saved receipts keep OCR review metadata" -r compact`
- `rg -n "Receipt reading|receipt reading|PDF receipt reading|Receipt photo reading|Turn on receipt reading|reading failed|read one PDF|read one photo|receipt_read_source|Wait for receipt reading" lib android ios test`
- `git diff --check`

Note:
- The scoped search still intentionally finds backward-compatible classifier
  patterns for older stored warnings and one negative UI test guard. No active
  user-facing copy in this pass keeps the old "receipt reading" wording.
- The first iOS bridge test run hit a transient native-assets `lipo` move error
  while other Flutter commands were active; rerunning the same focused test by
  itself passed.

Next camera/OCR focus:
- Continue camera/OCR only. Next target is post-photo review state accuracy:
  make no-line/low-confidence states explain whether OCR found text, whether
  parsing failed, and what the user should do next without blaming the user.

### Receipt Camera Reopen Pass 365 / Total Pass 445: Native Control Contract Tags Batch

Status: complete.

What changed:
- Added a shared native control contract tag list to the receipt camera session
  config so the Dart layer can describe the expected native camera controls as
  one ordered, privacy-safe bundle.
- Included core controls every session must expose: settings, back, manual
  shutter, review-next, receipt guidance, and safe close.
- Added conditional tags for tap focus, pinch zoom, brightness slider,
  brightness reset, auto brightness assist, focus/brightness/white-balance
  locks, receipt light, edge overlay, and previous-section ghost guidance.
- Sent the same ordered contract tag list through the native camera method
  channel and merged it back into capture diagnostics.
- Expanded native contract tests so capable phones, unsupported-control phones,
  channel arguments, and returned diagnostics all prove the same control
  contract.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart test/receipt_native_camera_contract_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart test/receipt_native_camera_contract_test.dart`
- `flutter test test/receipt_native_camera_contract_test.dart -r compact`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is native bridge parity tests for the
  Android and iOS receipt camera UI source files so both sides honor the same
  tap-focus, pinch-zoom, brightness/reset, settings, and back/close controls.

### Receipt Camera Reopen Pass 366 / Total Pass 446: Native Control Tags Bridge Parity Batch

Status: complete.

What changed:
- Fixed Android method-channel argument forwarding so string-list arguments are
  preserved when Flutter sends native receipt camera session settings.
- Added native control contract tag storage to the Android CameraX receipt
  camera activity and echoed the tags back through capture diagnostics.
- Added native control contract tag storage to the iOS AVFoundation receipt
  camera controller and echoed the tags back through capture diagnostics.
- Added Android source guards proving list arguments are forwarded, the receipt
  camera reads `nativeControlContractTags`, and diagnostics include the same
  tag list.
- Added iOS source guards proving the controller reads and reports
  `nativeControlContractTags`.

Validation:
- `dart format test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter analyze test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart -r compact`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is converting native control tag
  diagnostics into receipt-reader health buckets so command/review can detect
  missing tap-focus, pinch-zoom, brightness, settings, or back controls without
  seeing receipt content.

### Receipt Camera Reopen Pass 367 / Total Pass 447: Native Control Tag Health Buckets Batch

Status: complete.

What changed:
- Taught the receipt camera result diagnostics to read
  `nativeControlContractTags` from native capture diagnostics.
- Added privacy-safe health buckets for contract presence, tag count, and every
  expected native control tag.
- Connected user-facing brightness tags to internal native control names so
  `brightness_slider`, `brightness_reset`, and `brightness_lock` correctly map
  to exposure slider/reset/lock health.
- Made tag-expected controls count as missing when the native screen does not
  report an actual status, giving exact buckets for missing settings, back,
  manual shutter, tap focus, pinch zoom, brightness slider, and brightness
  reset.
- Removed a double-count of `native_control_readiness_missing` when no explicit
  readiness summary was provided.
- Added focused coverage for all-ready control tags and missing-control tag
  diagnostics flowing into receipt-reader handoff counts.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart`
- `flutter test test/receipt_camera_result_test.dart --name "native controls" -r compact`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is tightening receipt photo review
  routing/copy so the accepted-photo screen consistently says Next/Add Another
  Photo and routes to filled receipt details instead of returning to the
  previous expense screen.

### Receipt Camera Reopen Pass 368 / Total Pass 448: Photo Review Next Route Copy Batch

Status: complete.

What changed:
- Tightened the primary receipt photo review add action from ambiguous
  "Add Photo" wording to "Add Another" while preserving the explicit tooltip
  and menu wording for "Add Another Photo".
- Added an accepted-photo route result label to the review result contract so
  the handoff explicitly states that accepting photo review must open receipt
  details next, not return to the previous expense screen.
- Added the route result label to privacy-safe receipt-reader handoff metadata.
- Updated exact handoff tests and assisted review source guards so the result
  contract and visible review controls stay aligned with the required
  Next/Add Another Photo flow.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart test/receipt_camera_result_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart test/receipt_camera_result_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/receipt_camera_result_test.dart --name "photo review results freeze accepted camera diagnostics" -r compact`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --name "assisted expense receipt review exposes whole receipt choices" -r compact`

Note:
- `flutter test test/receipt_camera_result_test.dart --name "receipt reader handoff" -r compact`
  was attempted first but no test name matched that filter, so it was not
  counted as validation.

Next camera/OCR focus:
- Continue camera/OCR only. Next target is strengthening the actual
  photo-review accepted callback path so app-assisted reading clearly enters
  receipt details, records route-stage evidence, and never labels the action as
  generic "read receipt".

### Receipt Camera Reopen Pass 364 / Total Pass 444: Saved Photo Review Action Contract Batch

Status: complete.

What changed:
- Added a privacy-safe saved-photo review action contract to the receipt camera
  result model so dim, glare, blur, and weak-bottom-section warnings carry
  concrete next actions into the receipt-detail review.
- Added ordered, deduped saved-photo review action labels and a primary accepted
  warning action label for the current accepted photo set.
- Added saved-photo action buckets into receipt-reader handoff counts so
  diagnostics can separate "why OCR might struggle" from "what the user should
  check next" without storing receipt text.
- Added the primary accepted warning action label and full action label list to
  privacy-safe receipt-reader metadata only when a warning exists.
- Tightened dim-photo handoff wording so a dim-but-accepted photo tells the user
  to check readability/add light/retake instead of falling back to a generic
  receipt review message.
- Updated source guards and unit coverage for saved-photo warning actions,
  parser-risk counts, metadata, and handoff counts.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/receipt_camera_result_test.dart --name "saved-photo" -r compact`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --name "assisted expense receipt review exposes whole receipt choices" -r compact`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is bridge parity and focused tests for
  native tap-focus, pinch-zoom, exposure/reset, settings, and back/close
  diagnostics.

### Receipt Camera Reopen Pass 864: Privacy-Safe Capability Settings Wiring Batch

Status: complete.

What changed:
- Added controller-level accessors for the privacy-safe receipt camera
  capability label and diagnostics so UI and diagnostics can use capability
  buckets without exposing device identity.
- Surfaced the sanitized capability label inside the receipt scanner settings
  runtime summary as "Detected safely" copy.
- Kept manufacturer, model, and device name out of the settings screen and
  continued reporting only capability/storage/control buckets.
- Refreshed stale receipt review source guards so the focused receipt settings
  test protects the current 154/176 preview controls and current stitch/data
  saver control heights.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_settings_store.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart test/receipt_camera_help_flow_test.dart test/receipt_native_camera_contract_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_settings_store.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart test/receipt_camera_help_flow_test.dart test/receipt_native_camera_contract_test.dart`
- `flutter test test/receipt_camera_help_flow_test.dart --name "receipt capture exposes camera help and long receipt guidance" -r compact`
- `flutter test test/receipt_native_camera_contract_test.dart --name "hardware profile exposes privacy-safe capability buckets" -r compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is exact local OCR/parser failure
  labeling for receipt-total mismatch and missing subtotal/tax/total fields so
  Command One and the receipt review flow can explain what actually failed
  without exposing receipt content.

### Receipt Camera Reopen Pass 865: Parser Math Failure Evidence Buckets Batch

Status: complete.

What changed:
- Added privacy-safe parser math evidence buckets for receipt line-total
  mismatch and subtotal/tax/total mismatch.
- Bucketed math differences as zero, under 25 cents, under 1 dollar, under 5
  dollars, under 20 dollars, over 20 dollars, or unknown instead of exposing
  raw receipt totals in diagnostics.
- Added explicit-field evidence so diagnostics can tell whether subtotal, tax,
  and total were actually present on the receipt handoff.
- Added a focused subtotal/tax/total mismatch fixture so parser diagnostics
  distinguish line reconciliation failure from summary math failure.

Validation:
- `dart format lib/screens/expenses/data/expense_parser_failure_diagnostics.dart test/expense_parser_failure_diagnostics_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_parser_failure_diagnostics.dart test/expense_parser_failure_diagnostics_test.dart`
- `flutter test test/expense_parser_failure_diagnostics_test.dart -r compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is surfacing these safe parser-math
  buckets in the assisted receipt review actions so the user sees whether to
  check missing/duplicate lines or subtotal/tax/total math first.

### Receipt Camera Reopen Pass 866: Assisted Review Parser Math Guidance Batch

Status: complete.

What changed:
- Added a parser math review label on receipt parse diagnostics so review UI
  can distinguish line reconciliation problems from subtotal/tax/total summary
  problems.
- Routed that label into the assisted receipt review chip/detail text before
  generic OCR parser task wording.
- Added source guards so the review flow keeps the math guidance wired and the
  parse model keeps the exact line-total and subtotal/tax/total instructions.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `flutter test test/expense_parser_failure_diagnostics_test.dart --name "marks subtotal tax total mismatch with safe math buckets" -r compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is review-screen action chips for
  parser math failures: add missing section, check duplicate lines, check
  subtotal/tax/total, and use receipt total only when item detail is not safe.

### Receipt Camera Reopen Pass 867: Parser Math Review Action Chips Batch

Status: complete.

What changed:
- Threaded parse diagnostics into the receipt classification review panel and
  OCR review row so parser math failures can drive review actions.
- Added parser-math action chips for line reconciliation failures: check
  missing lines, check duplicate lines, or use receipt total only.
- Added parser-math action chips for subtotal/tax/total failures: check
  subtotal, check tax, and check receipt total.
- Kept the actions privacy-safe and bucket-driven; no receipt text, vendor,
  amount, or item content is displayed in diagnostics.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_recap.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_recap.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `flutter test test/expense_parser_failure_diagnostics_test.dart --name "marks total reconciliation problems as reviewable parser failures" -r compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is deduplicating and ordering OCR/parser
  review action labels so repeated chips do not clutter the receipt review
  screen when multiple warning buckets fire together.

### Receipt Camera Reopen Pass 868: Parser Review Action Ordering Batch

Status: complete.

What changed:
- Replaced implicit set-based action dedupe with an explicit ordered unique
  action-label helper.
- Prioritized parser-math actions before generic OCR task/readiness/structure
  actions so the first visible chips point at the highest-value fix.
- Added action priority ordering for missing lines, duplicate lines,
  subtotal/tax/total checks, receipt-total-only fallback, missing sections,
  photo order, and retake/add-photo actions.
- Added source guards so parser math actions stay first in the review action
  list.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is tightening capture/review diagnostics
  for exact back/close/cancel reasons and preserving accepted OCR source images
  separately from storage-saving proof copies.

### Receipt Camera Reopen Pass 869: Native Close Action Label Batch

Status: complete.

What changed:
- Added a privacy-safe native close action label to receipt photo review
  results.
- Surfaced that label in receipt-reader handoff metadata and capture-flow
  diagnostics beside the native close outcome token/counts.
- Covered back-returned-captured-sections, next-returned-captured-sections,
  capture-failed-after-close, closed-before-photo, duplicate close delivery,
  in-flight close wait, and open/not-closed outcomes.
- Kept the label content-free: no receipt text, photo path, amount, merchant,
  or device identity is included.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart test/receipt_camera_result_test.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart test/receipt_camera_result_test.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter test test/receipt_camera_result_test.dart --name "native close" -r compact`
- `flutter test test/receipt_capture_flow_shareability_test.dart -r compact`
- `flutter test test/receipt_camera_result_test.dart --name "photo review result summarizes native camera close health" -r compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is accepted-source preservation:
  make the result metadata prove OCR uses original/prepared source images before
  saved proof copies, and flag when it had to fall back to saved proof.

### Receipt Camera Reopen Pass 870: OCR Source-First Outcome Batch

Status: complete.

What changed:
- Added `ocrSourceFirstOutcome` and `ocrSourceFirstActionLabel` to accepted
  receipt photo review results.
- Distinguished prepared OCR source, original source, separate source copies,
  saved-source match, saved-proof fallback, and source-not-ready outcomes.
- Surfaced those fields in receipt-reader handoff metadata and capture-flow
  diagnostics beside the existing source-first policy.
- Strengthened tests so accepted receipt photos prove OCR uses prepared/original
  source images before saved proof copies and flags fallback when proof is the
  only usable source.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart test/receipt_camera_result_test.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart test/receipt_camera_result_test.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter test test/receipt_camera_result_test.dart --name "photo review results freeze accepted camera diagnostics" -r compact`
- `flutter test test/receipt_capture_flow_shareability_test.dart --name "app assisted OCR reads prepared OCR sources instead of saved backup proof" -r compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is camera preview/capture brightness
  diagnostics: make saved-photo dim/bright/glare warnings feed clearer review
  actions and exact health buckets without blocking manual capture.
