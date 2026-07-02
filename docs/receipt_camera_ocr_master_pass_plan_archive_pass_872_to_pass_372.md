# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 872: Low-Storage Long-Receipt OCR Cause Buckets Batch

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 872: Low-Storage Long-Receipt OCR Cause Buckets Batch

Status: complete.

What changed:
- Added local OCR parser task buckets for receipt photo readability problems:
  `ocr_no_readable_text`, `photo_tiny_text_review`,
  `photo_small_proof_review`, `photo_quality_review`, and
  `photo_read_failed`.
- Preserved the existing long-receipt buckets while promoting them into exact
  parser failure causes:
  `long_receipt_duplicate_text`, `long_receipt_probable_overlap`, and
  `long_receipt_section_gap`.
- Mapped those buckets to confirmed parser failure causes and exact failure
  stages, so Command One can tell whether the receipt failed because the text
  was unreadable, the long receipt was squeezed too small, the proof copy was
  too small to trust, the photo read failed, a section was missing, overlap was
  questionable, or duplicate overlap text was removed.
- Updated parser review cause-code summaries so app-assisted review and
  telemetry keep these causes separated instead of collapsing them into generic
  OCR/parser review.
- Kept the implementation local-first and low-storage friendly: these are
  compact diagnostic tokens, not heavy parser packs, image payloads, OCR text,
  merchant names, prices, addresses, notes, phone numbers, or cloud-dependent
  features.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/data/expense_parser_failure_diagnostics.dart lib/screens/expenses/data/expense_receipt_parse_models.dart test/receipt_ocr_service_test.dart test/expense_parser_failure_diagnostics_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/data/expense_parser_failure_diagnostics.dart lib/screens/expenses/data/expense_receipt_parse_models.dart test/receipt_ocr_service_test.dart test/expense_parser_failure_diagnostics_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --name "ocr diagnostics separates photo readability warning task buckets" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --name "ocr diagnostics separates long receipt overlap warning task buckets" -r compact`
- `flutter test test/expense_parser_failure_diagnostics_test.dart --name "prioritizes OCR parser task buckets as exact handoff causes" -r compact`
- `flutter test test/expense_parser_failure_diagnostics_test.dart -r compact`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/data/expense_parser_failure_diagnostics.dart lib/screens/expenses/data/expense_receipt_parse_models.dart test/receipt_ocr_service_test.dart test/expense_parser_failure_diagnostics_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is the low-storage capture/parser
  policy: fuel/simple receipts must stay fast and local on phones with very low
  free space, while heavier parser packs remain optional and separately
  diagnosable.

### Receipt Camera Pass 380 / Total Pass 460: OCR Capture Source Diagnostics Batch

Status: complete.

What changed:
- Added privacy-safe OCR source capture buckets so diagnostics can distinguish
  Maintainiac native camera capture, phone-camera backup capture, imported
  photo handoff, and recovery-photo handoff without storing receipt content.
- Threaded capture-source counts through OCR handoff summaries, OCR
  diagnostics, parser diagnostics, privacy-safe receipt events, expense entry
  metadata, and expense health telemetry.
- Added Command One health summary fields for capture-source counts and top
  capture-source signal so failure-rate drilldowns can say which capture path
  caused trouble.
- Updated schema guards and regression tests so the new field remains
  allowlisted and content-free.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/data/expense_receipt_privacy_event.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/helpers/expense_telemetry_schema_expectations.dart test/receipt_ocr_service_test.dart test/receipt_privacy_event_test.dart test/expense_screen_telemetry_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/data/expense_receipt_privacy_event.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/helpers/expense_telemetry_schema_expectations.dart test/receipt_ocr_service_test.dart test/receipt_privacy_event_test.dart test/expense_screen_telemetry_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --name "ocr result carries accepted photo handoff signals without receipt content" -r compact`
- `flutter test test/receipt_privacy_event_test.dart --name "privacy" -r compact`
- `flutter test test/expense_screen_telemetry_test.dart --name "summarizes OCR source handoff buckets for Command One without content" -r compact`
- `flutter test test/expense_screen_telemetry_test.dart -r compact`
- `flutter test test/receipt_ocr_service_test.dart test/receipt_privacy_event_test.dart -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/data/expense_receipt_privacy_event.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/helpers/expense_telemetry_schema_expectations.dart test/receipt_ocr_service_test.dart test/receipt_privacy_event_test.dart test/expense_screen_telemetry_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is tightening the UI handoff wording and
  diagnostics around the first screen after receipt capture so the next action
  clearly means review extracted receipt details, not return to the expense
  entry screen.

### Receipt Camera Pass 381 / Total Pass 461: Native Surface Verification Batch

Status: complete.

What changed:
- Strengthened the native receipt camera service so the primary capture result
  must come from Maintainiac's in-app native camera surface, not a stock camera
  or external camera app result.
- Added explicit verified-surface diagnostics:
  `nativeReceiptCameraSurfaceVerified`,
  `nativeReceiptCameraSurfaceVerification`, and
  `nativeReceiptCameraSurfaceActual`.
- Kept the phone camera as a labeled backup path only; it is not accepted as
  the primary Maintainiac native receipt camera surface.
- Added regression coverage for both stock-camera rejection and mismatched
  native surface rejection.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart test/receipt_native_camera_contract_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart test/receipt_native_camera_contract_test.dart`
- `flutter test test/receipt_native_camera_contract_test.dart --name "native service rejects" -r compact`
- `flutter test test/receipt_native_camera_contract_test.dart --name "native service sends previous section guide through channel" -r compact`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "receipt import uses Maintainiac native camera before any fallback" -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart test/receipt_native_camera_contract_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is surfacing verified native camera
  surface diagnostics into expense camera telemetry so Command One can prove
  whether a capture used Maintainiac's camera or a labeled backup path.

### Receipt Camera Pass 382 / Total Pass 462: Command One Native Surface Telemetry Batch

Status: complete.

What changed:
- Added Command One-safe telemetry buckets for the actual native receipt camera
  surface, surface verification result, and native camera identity.
- Aggregated these beside the existing native engine/control-contract buckets
  so camera health can now say whether a receipt used Maintainiac's in-app
  native camera surface or another labeled route.
- Exposed top native surface, top surface verification, and top native identity
  in the expense health map without storing device-identifying details or
  receipt content.
- Updated schema guards and the full expense telemetry test suite.

Validation:
- `dart format lib/screens/expenses/data/expense_screen_telemetry.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart -r compact`
- `git diff --check -- lib/screens/expenses/data/expense_screen_telemetry.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is tying native surface verification
  into receipt capture source handoff metadata so OCR results and camera
  telemetry agree on the same source route.

### Receipt Camera Pass 383 / Total Pass 463: OCR Native Surface Handoff Batch

Status: complete.

What changed:
- Added native receipt camera surface, surface verification, and camera
  identity counts to `ReceiptPhotoReviewResult`.
- Included those counts in privacy-safe receipt-reader handoff metadata.
- Added OCR attachment document signals for verified Maintainiac native camera
  surfaces, including actual surface, verification result, and identity.
- Updated the OCR source handoff counter so it now counts native source,
  native surface, and native identity tokens together.
- Kept all signals content-free: no receipt text, image bytes, merchant names,
  item names, amounts, or device identifiers are stored.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_camera_result_test.dart test/receipt_ocr_service_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_camera_result_test.dart test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_camera_result_test.dart --name "OCR handoff attachments expose privacy-safe native recovery signals" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --name "ocr result carries accepted photo handoff signals without receipt content" -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_camera_result_test.dart test/receipt_ocr_service_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is native camera live-preview exposure
  parity diagnostics so dark saved/preview mismatch reports an exact,
  content-free cause instead of a vague photo-quality warning.

### Receipt Camera Reopen Pass 375 / Total Pass 455: No-Line OCR vs Parser Cause Clarity Batch

Status: complete.

What changed:
- Split the empty-line receipt review state into clearer outcomes instead of
  one vague "No Line Items Found" message.
- Added separate labels for OCR result, parser result, what happened, and next
  step so the user can tell whether OCR found no usable text or whether OCR
  found text but the parser could not safely build line items.
- Kept the accepted-photo waiting state clear: it now says receipt details are
  opening/checking instead of implying the user must understand OCR internals.
- Preserved the existing recovery actions for using the total as business,
  personal, split, or manually adding receipt lines.
- Added source guards so the no-line panel keeps the new title/subtitle/status
  helpers and does not drift back into generic wording.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `git diff --check -- lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/expense_receipt_assisted_review_flow_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is tightening low-confidence receipt
  detail routing so accepted photos always land on the receipt-details review
  path with a clear Next action and no silent return to the prior expense
  screen.

### Receipt Camera Reopen Pass 376 / Total Pass 456: Accepted Photo Handoff Health Batch

Status: complete.

What changed:
- Tightened accepted-photo handoff diagnostics so an accepted review result
  proves the route to receipt details instead of reporting a false native
  capture transition failure.
- Added result-level ready/protected health counts for accepted receipt photos:
  transition ready, target receipt details, and discard protected.
- Kept real native control problems visible: fixtures without native control
  signals still report the separate `native_ui_signal_missing` outcome instead
  of pretending every control is ready.
- Updated regression coverage so the route contract says Next opens receipt
  details and no longer expects `native_capture_review_transition_missing` or
  `native_capture_review_discard_policy_missing` for a valid accepted photo
  review handoff.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart`
- `flutter test test/receipt_camera_result_test.dart --name "photo review results freeze accepted camera diagnostics" -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is removing remaining
  receipt-reader-named compatibility keys from new diagnostics while keeping
  backwards compatibility for old saved drafts and old telemetry.

### Receipt Camera Reopen Pass 377 / Total Pass 457: Receipt Details Diagnostic Alias Batch

Status: complete.

What changed:
- Added receipt-details-named aliases beside the older receipt-reader handoff
  diagnostics so new health data can speak in the same language as the UI.
- Kept the old `receiptReaderHandoff...` keys and getters for saved drafts,
  old telemetry, and compatibility.
- Added `receiptDetailsHandoff...` aliases for schema, integrity, counts,
  outcome, route, next screen, next-step label, route result, required receipt
  details opening, user action, OCR-source policy, compression policy, and
  evidence.
- Added telemetry allowlist entries for the new privacy-safe receipt-details
  handoff keys.
- Updated source guards and result tests so both the old compatibility keys and
  the new receipt-details keys stay present.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/receipt_camera_result_test.dart --name "photo review results freeze accepted camera diagnostics" -r compact`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "receipt photo back protects captured images from silent discard" -r compact`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is a focused audit of the photo review
  action labels and menus so the primary action stays `Next: Review Receipt
  Details`, add-photo actions are clearly long-receipt actions, and old
  generic camera/import labels do not reappear.

### Receipt Camera Reopen Pass 378 / Total Pass 458: Photo Review Next Label Consistency Batch

Status: complete.

What changed:
- Audited the visible receipt photo review labels for stale or vague action
  wording.
- Replaced the shortened dialog action `Next: Review Details` with the full
  `Next: Review Receipt Details` label.
- Added a guard so the shortened label does not reappear in the receipt photo
  review save/continue dialog.
- Left the existing `Add Another Photo`, `Check Photo Match`, and fallback
  phone-camera wording in place where they are intentional and already guarded.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "receipt photo back protects captured images from silent discard" -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is reviewing the capture/review flow
  fallback messages so native-camera fallback copy stays clear without making
  the stock phone camera look like the normal Maintainiac camera experience.

### Receipt Camera Reopen Pass 379 / Total Pass 459: Backup Camera Fallback Copy Batch

Status: complete.

What changed:
- Tightened the first receipt photo fallback copy so the stock phone camera is
  described as backup capture, not the normal Maintainiac camera.
- Tightened the add-another-photo fallback copy the same way for long receipt
  sections.
- Made the backup-captured photo review prefix say the photo is still reviewed
  in Maintainiac.
- Updated diagnostics user-facing labels from `Phone camera fallback` to
  `Phone camera backup; returns to Maintainiac review`.
- Strengthened tests so fallback copy proves the backup path still returns to
  Maintainiac receipt review.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "review add-photo flow also uses native capture before fallback" -r compact`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "receipt import uses Maintainiac native camera before any fallback" -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is strengthening local OCR failure
  diagnostics around backup-captured photos so Command One can distinguish
  native camera photos, phone-camera backup photos, imported photos, and
  recovery photos without storing receipt content.

### Receipt Camera Reopen Pass 369 / Total Pass 449: Accepted Photo Route Stage Evidence Batch

Status: complete.

What changed:
- Carried the accepted-photo route result from `ReceiptPhotoReviewResult` into
  the expense receipt entry screen state so accepting a reviewed photo has an
  explicit next-screen contract.
- Added the route result to the receipt read handoff panel with a route chip,
  making the flow state plain: accepted photo review opens receipt details next,
  not the previous expense screen.
- Persisted the route result through receipt draft save and restore so an
  interrupted assisted receipt flow comes back with the same handoff state.
- Added the route result to the privacy-safe receipt telemetry snapshot as a
  tokenized operational status, not receipt content.
- Updated assisted-flow source guards and draft round-trip coverage for the new
  route-stage evidence.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart lib/screens/expenses/data/expense_receipt_draft_record.dart test/expense_receipt_assisted_review_flow_test.dart test/expense_draft_store_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart lib/screens/expenses/data/expense_receipt_draft_record.dart test/expense_receipt_assisted_review_flow_test.dart test/expense_draft_store_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `flutter test test/expense_draft_store_test.dart --name "drafts keep accepted photo review handoff state" -r compact`
- `git diff --check`

Note:
- `flutter test test/expense_draft_store_test.dart --name "receipt handoff" -r compact`
  was attempted first and correctly not counted because no test matched that
  filter.

Next camera/OCR focus:
- Continue camera/OCR only. Next target is removing remaining generic receipt
  handoff wording from the capture/import path and replacing it with clear
  "Next/open receipt details/fill receipt details" routing language.

### Receipt Camera Reopen Pass 370 / Total Pass 450: Receipt Details Wording Cleanup Batch

Status: complete.

What changed:
- Replaced remaining user-facing `receipt reader` / `read into the form` copy
  in the scoped receipt capture, saved-photo, PDF import, and expense handoff
  paths with clearer `receipt details` language.
- Updated saved-photo exit copy so leaving review no longer sounds like the
  app silently threw the image away or hid a backend read operation; it now says
  whether receipt details have been opened from the photo.
- Changed recovery guidance to say saved photos resume into review and then
  open receipt details from the saved proof.
- Tightened long-receipt guidance so top/middle/bottom order is described as
  helping receipt details fill correctly.
- Updated tests that pin the back/exit protection copy and kept the old wording
  out of the scoped receipt files.

Validation:
- `rg -n "read into this expense|read into the form|receipt reader|Waiting for receipt reader|Review receipt fields|Receipt text sent to the receipt form|PDF receipt proof was read|OCR read receipt text" test lib/screens/expenses lib/shared/widgets/receipt_capture`
- `dart format lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart lib/shared/widgets/receipt_capture/receipt_pdf_import_actions.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart lib/shared/widgets/receipt_capture/receipt_pdf_import_actions.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`
- `flutter test test/receipt_camera_result_test.dart --name "kept for later review does not open receipt details input" -r compact`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "receipt photo back protects captured images from silent discard" -r compact`
- `flutter analyze test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`
- `git diff --check`

Note:
- `flutter test test/receipt_camera_capture_layout_test.dart --name "Use this receipt photo before leaving" -r compact`
  was attempted first and correctly not counted because no test matched that
  filter.

Next camera/OCR focus:
- Continue camera/OCR only. Next target is strengthening saved-photo/recovery
  diagnostics so interrupted native camera reviews clearly report whether the
  user should resume, discard, retake, or open receipt details next.

### Receipt Camera Reopen Pass 371 / Total Pass 451: Native Recovery Receipt Details Token Batch

Status: complete.

What changed:
- Replaced native recovery action tokens that still said
  `before_receipt_read` with `before_receipt_details` so interrupted capture
  diagnostics line up with the user-facing flow.
- Updated the recovery interruption guarantee token to say photos stay
  available before receipt details, not before a vague read step.
- Added a source guard in the receipt capture layout tests so the old
  `before_receipt_read` wording cannot come back in native staging.
- Updated native staging recovery tests to expect the new receipt-details
  action names and recovery copy.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_camera_capture_layout_test.dart test/receipt_native_capture_staging_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_native_capture_staging_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "ocr source handoff helpers stay aligned across receipt paths" -r compact`
- `flutter test test/receipt_native_capture_staging_test.dart --name "accepted native capture is copied into receipt staging" -r compact`
- `flutter test test/receipt_native_capture_staging_test.dart --name "recovery record explains resume context without receipt content" -r compact`
- `rg -n "attach and read the receipt into the form|read into the form|before_receipt_read|resume_review_before_receipt_read|resume_review_keeps_photos_available_before_receipt_read" lib/shared/widgets/receipt_capture test`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is native recovery UI clarity: make the
  banner/action text distinguish resume, retake, discard, and open receipt
  details with no receipt content in diagnostics.

### Receipt Camera Reopen Pass 372 / Total Pass 452: Interrupted Recovery Banner Action Clarity Batch

Status: complete.

What changed:
- Added a plain next-step line to the interrupted native capture banner:
  recoverable photos now say Resume reviews saved photos first and Next opens
  receipt details.
- Added the missing-files branch copy so incomplete recovery tells the user to
  retake receipt photos or discard the interrupted recovery copy.
- Changed the discard diagnostic from `discarded_no_reader_handoff` to
  `discarded_no_receipt_details_handoff`.
- Updated the banner source guard to require resume, retake, discard, and open
  receipt-details language while still rejecting receipt text and the old
  reader-handoff token.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "interrupted native capture banner surfaces freshness and safe diagnostics" -r compact`
- `rg -n "discarded_no_reader_handoff|reader_handoff|read into the form|before_receipt_read" lib/shared/widgets/receipt_capture test/receipt_camera_capture_layout_test.dart`
- `git diff --check`

Note:
- The remaining `receiptReaderHandoffSchema` key is a compatibility diagnostic
  schema name in `receipt_capture_models.dart`, not user-facing copy. It was
  left unchanged to avoid breaking existing stored diagnostics without a
  migration.

Next camera/OCR focus:
- Continue camera/OCR only. Next target is camera-flow recovery telemetry:
  rename accepted/interrupted recovery reasons that still say "for_reader" to
  receipt-details wording while preserving safe compatibility where needed.
