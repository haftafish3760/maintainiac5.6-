# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 1173: Noisy Register Header Merchant Recovery

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 1173: Noisy Register Header Merchant Recovery

Status: complete.

What changed:
- Widened the local merchant/profile header scan so receipts with copy banners,
  store/register/cashier/terminal/trace rows, and other register noise before
  the real merchant can still recover the merchant profile.
- Kept the scan header-limited and continued filtering admin rows, dates, times,
  money rows, address/contact rows, and generic receipt-copy banners so register
  metadata does not become the merchant.
- Added station/food wording to local merchant scoring so unknown fuel and
  convenience merchants have stronger fallback ranking without needing a known
  merchant profile.
- Added regression coverage for an unknown fuel station hidden under noisy
  register headers and for a known Sheetz profile appearing after register
  noise.
- Verified noisy transaction/payment lines are excluded through content-free
  parser diagnostics, while date/time/fuel line extraction remains ready.
- This pass is local OCR/parser only; no cloud, PDF, Firebase, inventory,
  maintenance, or 5.5 work was touched.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart`
- `dart analyze lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/data/expense_receipt_fuel_parser.dart test/expense_receipt_parser_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "merchant ranking survives noisy fuel register headers" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "known fuel profile can appear after register header noise" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "merchant ranking skips generic banners before gas station name" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "merchant ranking skips sale header before unknown hardware store" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "parses unknown fuel receipts with noisy abbreviated fuel labels" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "keeps convenience fuel and store items separate on hybrid receipts" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is bottom-of-receipt
  completion detection: combine footer/total/subtotal/barcode signals with
  missing-bottom warnings so long-receipt capture can ask for another photo
  only when the receipt actually looks incomplete.

### Receipt Camera Reopen Pass 1174: Bottom Completion Evidence Counters

Status: complete.

What changed:
- Added local parser task counters that prove when the visible receipt bottom
  looks complete instead of only proving when it looks incomplete.
- New content-free counters:
  - `receipt_summary_totals_ready`
  - `receipt_footer_or_barcode_seen`
  - `receipt_bottom_complete_ready`
- A receipt now reports bottom-complete evidence when it has priced lines, an
  explicit final total, and either footer/barcode evidence or complete
  subtotal/tax/total math.
- Existing long-receipt warning behavior is preserved: item-only receipts still
  suggest adding the lower section, while footer-seen receipts with missing
  totals still route to OCR/crop/manual-total review instead of blindly asking
  for another photo.
- Added focused regression tests for footer+summary completion, full summary
  math completion without footer text, item-only missing-lower-section review,
  footer-seen totals-missing review, and subtotal-only final-total review.
- This pass is local OCR/parser only; no cloud, PDF, Firebase, inventory,
  maintenance, or 5.5 work was touched.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart`
- `dart analyze lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/data/expense_receipt_parse_models.dart test/expense_receipt_parser_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "marks footer and summary totals as bottom-complete evidence" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "marks full summary math as bottom-complete without footer text" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "routes item-only receipt text to missing lower section review" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "routes footer-seen receipt without totals to OCR total review" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "routes subtotal-only receipt text to final total review" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is crop/readability
  readiness evidence for photo review: make sure review can distinguish
  "readable enough to continue", "needs crop/retake", and "needs another lower
  section" without exposing private receipt text.

### Receipt Camera Reopen Pass 1175: Photo Review Action Codes

Status: complete.

What changed:
- Added stable, content-free photo review action codes to
  `ReceiptPhotoQualityCheck` so the camera review UI can decide what to show
  without parsing user-facing copy.
- New quality action codes:
  - `continue_to_receipt_details`
  - `check_photo_then_next`
  - `crop_or_retake_then_next`
  - `check_readability_or_add_closer_photo`
  - `retake_recommended_continue_allowed`
- Added `reviewActionFamily` buckets for compact diagnostics and UI routing:
  `continue`, `review`, and `retake`.
- Updated the Next action label so crop/framing issues and small/weak text get
  clearer action copy while still preserving the rule that manual Next remains
  available when the user can read the receipt.
- Added regression coverage for stable review action codes, critical retake
  guidance, bright-but-readable receipts, readable weak-heuristic receipts, and
  readable framed-photo coverage decisions.
- This pass is local camera/photo quality only; no cloud, PDF, Firebase,
  inventory, maintenance, or 5.5 work was touched.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_quality_guidance_test.dart`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_quality_guidance_test.dart`
- `flutter test test/receipt_camera_quality_guidance_test.dart --plain-name "photo review exposes stable action codes for UI flow" -r compact`
- `flutter test test/receipt_camera_quality_guidance_test.dart --plain-name "bright readable receipt paper is not treated as glare failure" -r compact`
- `flutter test test/receipt_camera_quality_guidance_test.dart --plain-name "review guidance separates soft warnings from critical retakes" -r compact`
- `flutter test test/receipt_camera_quality_guidance_test.dart --plain-name "likely readable receipt photos are not scored like weak photos" -r compact`
- `flutter test test/receipt_camera_quality_guidance_test.dart --plain-name "receipt coverage decision accepts readable framed photos" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is wiring these quality
  action codes into photo review/attachment telemetry so command-center health
  can report continue/review/retake outcomes without raw receipt data.

### Receipt Camera Reopen Pass 1176: Quality Action Handoff Telemetry

Status: complete.

What changed:
- Added privacy-safe capture diagnostic keys for photo quality action routing:
  - `latestCapturedQualityAction`
  - `latestCapturedQualityActionFamily`
- Native capture diagnostics now carry the selected quality action code and
  action family alongside the existing readable/needs-review signal.
- Accepted photo review results now count `quality_action_*` and
  `quality_family_*` outcomes in `acceptedPhotoQualityOutcomeCounts`.
- Attached receipt photo document signals now include quality action/family
  tokens so command-center health can summarize continue/review/retake posture
  without raw receipt text.
- OCR-source risk flags now include quality action/family tokens so parser
  diagnostics can explain whether OCR read from a ready photo, a review photo,
  or a retake-risk photo.
- Added regression coverage for accepted review-result quality action counts
  and per-photo native capture diagnostics.
- This pass is local camera/photo quality telemetry only; no cloud, PDF,
  Firebase, inventory, maintenance, or 5.5 work was touched.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_result_test.dart`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_result_test.dart`
- `flutter test test/receipt_camera_result_test.dart --plain-name "photo review result counts quality action outcomes" -r compact`
- `flutter test test/receipt_camera_result_test.dart --plain-name "camera result converts native evidence into per-photo diagnostics" -r compact`
- `flutter test test/receipt_camera_result_test.dart --plain-name "photo review result summarizes scanner prep concerns" -r compact`
- `flutter test test/receipt_attachment_panel_actions_test.dart --plain-name "multiple receipt photos are shown in receipt order" -r compact`
- `flutter test test/receipt_camera_quality_guidance_test.dart --plain-name "photo review exposes stable action codes for UI flow" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is using quality action
  evidence in OCR/parser failure diagnostics so unreadable, reviewable,
  retake-risk, and partial-receipt paths produce different local health codes.

### Receipt Camera Reopen Pass 1177: Quality-Action-Aware OCR/Parser Failure Diagnostics

Status: complete.

What changed:
- OCR diagnostics now translate photo review action/family risk flags into
  parser task buckets:
  - `photo_retake_recommended_review`
  - `photo_crop_or_retake_review`
  - `photo_readability_or_closer_review`
  - `photo_quality_retake_family_review`
  - `photo_quality_review_family`
- Parser failure diagnostics now expose separate confirmed causes and failure
  stages for retake-risk, crop/retake, and readability/closer-photo handoffs.
- Receipt parse diagnostics now include those same review cause codes so the
  review layer and command-center health can agree on why OCR/parser review is
  needed without exposing receipt text.
- OCR parser task evidence now prioritizes camera/photo handoff tasks before
  generic parser noise, preventing the exact camera failure reason from being
  hidden when many local parser tasks are present.
- Added regression coverage for direct source quality-action handoff through
  OCR result, parser diagnostics, confirmed cause, failure stage, and evidence.
- This pass is local camera/OCR/parser diagnostics only; no cloud, PDF,
  Firebase, inventory, maintenance, or 5.5 work was touched.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/data/expense_parser_failure_diagnostics.dart lib/screens/expenses/data/expense_receipt_parse_models.dart test/expense_parser_failure_diagnostics_test.dart`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/data/expense_parser_failure_diagnostics.dart lib/screens/expenses/data/expense_receipt_parse_models.dart test/expense_parser_failure_diagnostics_test.dart`
- `flutter test test/expense_parser_failure_diagnostics_test.dart --plain-name "maps source quality action handoff to retake diagnostic cause" -r compact`
- `flutter test test/expense_parser_failure_diagnostics_test.dart --plain-name "marks OCR parser-readiness failures with exact handoff causes" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is making receipt-bottom
  completeness and quality-action diagnostics agree in the assisted review flow:
  if the bottom edge/totals are missing, the flow should favor "add another
  photo" over generic quality review; if the photo is complete but weak, it
  should favor crop/retake/readability review.

### Receipt Camera Reopen Pass 1178: Assisted Review Quality Versus Bottom Continuation Routing

Status: complete.

What changed:
- Added local parser diagnostics getters for stable photo quality action review:
  - `hasOcrPhotoRetakeActionReview`
  - `hasOcrPhotoCropOrRetakeActionReview`
  - `hasOcrPhotoReadabilityOrCloserActionReview`
  - `hasOcrPhotoQualityActionReview`
  - `ocrPhotoQualityActionReviewCode`
  - `ocrPhotoQualityActionReviewLabel`
  - `ocrPhotoQualityActionReviewInstruction`
  - `ocrPhotoQualityActionReviewActionLabel`
- Photo-action diagnostics now distinguish retake, crop/retake, readability or
  closer-photo, generic quality review, and bottom-section-first routing.
- Bottom-section evidence intentionally outranks crop/retake quality action:
  when the app has bottom-edge/totals evidence, assisted review tells the user
  to add the next receipt section with the ghost-slice flow before final
  classification.
- Assisted review guidance now uses the photo-action label, action label, and
  instruction when no bottom continuation is required, giving the review screen
  a clear next step instead of generic parser wording.
- Added regression coverage for retake-action routing and bottom-continuation
  priority over crop/retake routing.
- This pass is local camera/OCR/parser review routing only; no cloud, PDF,
  Firebase, inventory, maintenance, or 5.5 work was touched.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `dart analyze lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "routes quality action retake evidence into assisted review guidance" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "bottom continuation evidence outranks crop and retake review actions" -r compact`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "marks footer and summary totals as bottom-complete evidence" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "marks full summary math as bottom-complete without footer text" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is strengthening the
  native camera/photo handoff contract for preview-versus-saved brightness and
  focus evidence so dark saved photos and soft lower receipt sections produce
  actionable local diagnostics before OCR.

### Receipt Camera Reopen Pass 1179: Saved-Photo Brightness And Bottom-Soft OCR Handoff

Status: complete.

What changed:
- OCR diagnostics now map saved-photo native review warnings into parser task
  buckets:
  - `photo_saved_dark_or_exposure_review`
  - `photo_saved_soft_blur_review`
  - `photo_saved_bottom_quality_review`
- Parser review diagnostics now understand saved-photo exposure, soft blur, and
  bottom-quality tasks as first-class photo review outcomes.
- Assisted review can now tell the user to:
  - check the bottom receipt section or add a clearer bottom photo,
  - retake with better light when the saved proof is darker than preview,
  - retake while holding steady when the saved proof is soft.
- Failure diagnostics now produce exact privacy-safe causes and stages for
  saved dark/exposure, saved soft/focus, and bottom-quality handoff problems.
- Added regression coverage for saved bottom-photo quality routing into
  assisted review guidance and exact failure diagnostic mapping.
- This pass is local camera/OCR/parser diagnostics only; no cloud, PDF,
  Firebase, inventory, maintenance, or 5.5 work was touched.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_parser_failure_diagnostics.dart test/expense_receipt_parser_test.dart test/expense_parser_failure_diagnostics_test.dart`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_parser_failure_diagnostics.dart test/expense_receipt_parser_test.dart test/expense_parser_failure_diagnostics_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "routes saved bottom photo quality into assisted review guidance" -r compact`
- `flutter test test/expense_parser_failure_diagnostics_test.dart --plain-name "marks OCR parser-readiness failures with exact handoff causes" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is tightening OCR-source
  risk mapping so dark/exposure and soft/focus saved-photo warnings also affect
  source handoff status and recovery copy before the parser tries to trust line
  items.

### Receipt Camera Reopen Pass 1180: OCR Source Quality Review Status

Status: complete.

What changed:
- Added source handoff quality review buckets for saved-photo risks:
  - `saved_bottom_quality_review`
  - `saved_dark_exposure_review`
  - `saved_soft_blur_review`
  - `scanner_prep_review_needed`
- Added source handoff actions for those buckets:
  - `check_bottom_or_add_photo`
  - `retake_or_raise_brightness`
  - `retake_hold_steady`
  - `review_scanner_preparation`
- Privacy-safe OCR source handoff contracts now include
  `sourceQualityReviewStatus` and `sourceQualityReviewAction` when the source
  quality needs action before parser trust.
- OCR source status now escalates to `scanner_prep_review_needed` when saved
  photo bottom quality, dark/exposure, or soft/focus risk is the primary source
  signal.
- Existing stitched/partial route statuses remain intact, while the separate
  source quality status still carries the camera-quality review action.
- Added regression coverage for bottom saved-photo quality and dark saved-photo
  exposure handoff statuses/actions.
- This pass is local camera/OCR source handoff only; no cloud, PDF, Firebase,
  inventory, maintenance, or 5.5 work was touched.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr result carries accepted photo handoff signals without receipt content" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "source handoff reports bottom saved-photo quality review" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "source handoff reports dark saved-photo exposure review" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is adding recovery-message
  copy that uses `sourceQualityReviewAction` so the receipt read failure path
  tells the user whether to add a bottom photo, brighten/retake, or hold steady.

### Receipt Camera Reopen Pass 1181: Source-Quality-Aware Receipt Read Recovery Copy

Status: complete.

What changed:
- Receipt read recovery advice now recomputes after OCR returns diagnostics, so
  the failure path can use `sourceQualityReviewAction` instead of only generic
  photo/PDF/text advice.
- Added targeted recovery copy for:
  - bottom section still needing capture with the ghost-slice guide,
  - bottom receipt photo needing review or another clearer bottom photo,
  - saved photo too dark for reliable reading,
  - saved photo too soft for reliable reading.
- Crash/exception recovery still uses the pre-OCR generic advice because no OCR
  diagnostics exist yet.
- The user-facing recovery copy remains local and privacy-safe; it uses action
  codes and does not include receipt text.
- Added flow coverage to keep the source-quality action lookup and targeted
  recovery phrases present in the app-assisted receipt flow.
- This pass is local receipt read recovery only; no cloud, PDF, Firebase,
  inventory, maintenance, or 5.5 work was touched.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart test/expense_receipt_assisted_review_flow_test.dart`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "source handoff reports bottom saved-photo quality review" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "source handoff reports dark saved-photo exposure review" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is expanding OCR parser
  task summaries so saved-photo exposure/focus/bottom quality tasks produce
  clear compact labels in assisted review and admin health, not only detailed
  instructions.

### Receipt Camera Reopen Pass 1182: Compact Photo-Action Parser Summary Labels

Status: complete.

What changed:
- Parser task summaries now prefer the photo quality action label when a
  camera/photo handoff task is present.
- Compact labels now surface:
  - `Retake recommended`
  - `Add bottom receipt section first`
  - `Check bottom receipt section`
  - and the other photo-action labels added in prior passes.
- This keeps assisted review and admin health from hiding camera-quality
  problems behind generic `OCR prepared vendor/date/item prices` summaries.
- Added regression assertions to the retake, bottom-continuation, and saved
  bottom-quality parser tests.
- This pass is local parser summary labeling only; no cloud, PDF, Firebase,
  inventory, maintenance, or 5.5 work was touched.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parse_models.dart test/expense_receipt_parser_test.dart`
- `dart analyze lib/screens/expenses/data/expense_receipt_parse_models.dart test/expense_receipt_parser_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "routes quality action retake evidence into assisted review guidance" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "bottom continuation evidence outranks crop and retake review actions" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "routes saved bottom photo quality into assisted review guidance" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is verifying that the
  camera/OCR quality action evidence is represented in telemetry metadata
  without receipt text so Command 1 can report health later.

### Receipt Camera Reopen Pass 1183: Source Quality Review Telemetry Handoff

Status: complete.

What changed:
- OCR completion metadata now includes privacy-safe
  `ocrSourceQualityReviewStatus` and `ocrSourceQualityReviewAction` values
  when the source handoff identifies a camera/source-quality review action.
- Parser diagnostics now preserve the OCR source-quality review status/action
  after OCR text is handed into the local receipt parser.
- Parser event metadata now emits the same privacy-safe source-quality review
  status/action without receipt text, store names, prices, file paths, or image
  content.
- Expense telemetry aggregation now counts:
  - `ocrSourceQualityReviewStatusCounts`
  - `ocrSourceQualityReviewActionCounts`
  - `topOcrSourceQualityReviewStatus`
  - `topOcrSourceQualityReviewAction`
- Command One health can now distinguish dark saved photos, soft saved photos,
  bottom-quality review, and scanner-prep review without seeing user receipt
  data.
- Schema expectations and regression tests were updated so these fields stay
  allowlisted and visible in the local health snapshot.
- This pass is local camera/OCR/parser telemetry only; no cloud, PDF, Firebase,
  inventory, maintenance, or 5.5 work was touched.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_receipt_parser_test.dart test/expense_screen_telemetry_test.dart test/helpers/expense_telemetry_schema_expectations.dart`
- `dart analyze lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_receipt_parser_test.dart test/expense_screen_telemetry_test.dart test/helpers/expense_telemetry_schema_expectations.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "routes saved bottom photo quality into assisted review guidance" -r compact`
- `flutter test test/expense_screen_telemetry_test.dart --plain-name "summarizes OCR source handoff buckets for Command One without content" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is making the local parser
  review summary use these source-quality buckets to separate camera/source
  defects from merchant/date/total parsing defects, so admin health can show
  whether failures come from capture quality or parser intelligence.

### Receipt Camera Reopen Pass 1184: Parser Root-Cause Health Buckets

Status: complete.

What changed:
- Added local parser review root-cause classification to
  `ExpenseReceiptParseDiagnostics`.
- Parser review root causes now separate:
  - `capture_coverage_or_long_receipt`
  - `camera_source_quality`
  - `multi_photo_overlap`
  - `receipt_math_review`
  - `ocr_required_fields`
  - `parser_optional_pack_limit`
  - `parser_category_confidence`
  - `parser_ready`
  - `parser_review_not_classified`
- Parser event metadata now emits only the safe
  `parserReviewRootCauseCode`; the human-readable label stays local and is not
  placed into telemetry because telemetry tokens must remain sanitized.
- Expense telemetry aggregation now counts `parserReviewRootCauseCounts` and
  exposes `topParserReviewRootCause`.
- The saved-bottom-quality parser regression now proves that camera/source
  quality is not mislabeled as a parser intelligence failure.
- The Command One telemetry regression now proves camera quality and OCR-field
  root-cause buckets aggregate without receipt content.
- This pass is local camera/OCR/parser health classification only; no cloud,
  PDF, Firebase, inventory, maintenance, or 5.5 work was touched.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_receipt_parser_test.dart test/expense_screen_telemetry_test.dart test/helpers/expense_telemetry_schema_expectations.dart`
- `dart analyze lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_receipt_parser_test.dart test/expense_screen_telemetry_test.dart test/helpers/expense_telemetry_schema_expectations.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "routes saved bottom photo quality into assisted review guidance" -r compact`
- `flutter test test/expense_screen_telemetry_test.dart --plain-name "summarizes OCR source handoff buckets for Command One without content" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is using the root-cause
  buckets to improve assisted review copy and diagnostics around long receipts,
  overlap, and missing required fields without adding cloud dependencies.
