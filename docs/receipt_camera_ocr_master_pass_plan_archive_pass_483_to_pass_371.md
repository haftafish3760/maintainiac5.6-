# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 483: Parser-Ready OCR Structure Health Batch

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 483: Parser-Ready OCR Structure Health Batch

Status: complete.

What changed:
- Added shared OCR handoff counts for priced lines, parser-ready lines, and
  parser review signals.
- Added a receipt structure status token for the OCR handoff:
  `no_text`, `missing_vendor`, `no_items`, `missing_total`,
  `line_sequence_review`, `summary_math_review`, `line_item_review`, or
  `ready_for_parser`.
- Propagated those parser-readiness signals into expense parse diagnostics.
- Added privacy-safe receipt telemetry fields and Command One health snapshot
  aggregation for parser-ready line counts, review-signal counts, priced-line
  counts, receipt-structure status counts, and receipt-structure review count.
- Kept the telemetry content-free: no receipt image, vendor text, item
  descriptions, address, phone number, or prices are added to event payloads.

Validation:
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/data/expense_receipt_privacy_event.dart lib/screens/expenses/data/expense_receipt_privacy_event_store.dart test/receipt_ocr_service_test.dart test/expense_receipt_parser_test.dart test/receipt_privacy_event_test.dart test/receipt_privacy_event_store_test.dart`
- `flutter test test/receipt_ocr_service_test.dart test/expense_receipt_parser_test.dart test/receipt_privacy_event_test.dart test/receipt_privacy_event_store_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is using the structure-health status in
  the receipt review flow so the user sees concrete next steps after capture
  and Command One can later show exact non-private failure buckets.

### Receipt Camera Reopen Pass 484: Assisted Review Structure Guidance Batch

Status: complete.

What changed:
- Surfaced the OCR receipt-structure status in the assisted receipt review UI.
- Added concrete user guidance for `ready_for_parser`, `missing_vendor`,
  `no_items`, `missing_total`, `line_sequence_review`, `summary_math_review`,
  `line_item_review`, and `no_text`.
- Kept the guidance content-safe. It explains what part of the receipt flow
  needs review without displaying private receipt text, vendor names, item
  descriptions, phone numbers, addresses, or prices.
- Added a source guard so later UI cleanup keeps the structure-health guidance
  wired into the receipt review panel.

Validation:
- `flutter analyze lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_privacy_event.dart lib/screens/expenses/data/expense_receipt_privacy_event_store.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/receipt_ocr_service_test.dart test/expense_receipt_parser_test.dart test/receipt_privacy_event_test.dart test/receipt_privacy_event_store_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is converting structure-health guidance
  into button-level review actions after OCR, especially retake/add-section,
  confirm store/total, continue manually, and proceed to business/personal/mixed
  classification.

### Receipt Camera Reopen Pass 485: OCR Structure Action Chip Batch

Status: complete.

What changed:
- Extended the receipt parse review box with compact action chips.
- Added structure-specific OCR action labels for the assisted review path:
  review filled fields, classify business/personal/mixed, check store name,
  add line manually, use receipt total, retake/add photo, check receipt total,
  check photo order, add missing section, check subtotal/tax/total, review line
  prices, and enter manually.
- Kept the action chips non-private and status driven. They do not display raw
  OCR text, vendor names, item descriptions, prices, phone numbers, addresses,
  or receipt image content.
- Added a source guard so future UI work keeps the action-chip path attached to
  OCR structure health.

Validation:
- `flutter analyze lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is wiring those action chips to real
  review operations where the surrounding screen has callbacks available:
  retake/add photo, jump to store/total, continue manually, and jump to line
  classification.

### Receipt Camera Reopen Pass 486: OCR Review Action Callback Wiring Batch

Status: complete.

What changed:
- Threaded OCR review action callbacks from the expense receipt entry screen
  into the receipt classification/review widgets.
- Wired available real actions instead of leaving every chip as static text:
  - review filled fields and business/personal/mixed classification scroll to
    the receipt review area,
  - add line manually and enter manually open the existing manual line flow,
  - use receipt total creates an existing business receipt-total line,
  - retake/add photo, add missing section, check photo order, retake section,
    retake photo, and add clearer photo scroll back to the receipt capture
    section.
- Kept non-private action labels only. No raw OCR text, vendor names, item
  descriptions, prices, addresses, phone numbers, or receipt image data are
  exposed.
- Added a guard proving the action chip path is wired to callbacks and renders
  actual tappable outlined buttons when callbacks exist.

Validation:
- `flutter analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_recap.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is adding explicit UI state for
  long-receipt add-section/retake guidance near the capture and review screens
  so the scroll target makes the next user action obvious.

### Receipt Camera Reopen Pass 487: Capture Target Long-Receipt Guidance Batch

Status: complete.

What changed:
- Added a compact long-receipt guidance strip directly inside the shared receipt
  attachment/capture panel.
- The guidance respects the existing `cameraLongReceiptTips` setting.
- Before proof is attached, the strip tells the user to scan long receipts from
  top to bottom with a little overlap and keep the order top, middle, bottom.
- After proof exists, the strip tells the user to use Add More Proof if the
  receipt continues, a section is blurry, or OCR says order/total needs review.
- This makes the scroll target from OCR action chips more useful without adding
  fake retake/add-section callbacks.

Validation:
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is strengthening the native review/add
  photo handoff so the add-section reason from OCR/quality guidance can be
  carried into the ghost-overlap capture flow more explicitly.

### Receipt Camera Reopen Pass 380 / Total Pass 460: Command One Local/Cloud OCR Bucket Summary Batch

Status: complete.

What changed:
- Promoted the newer accepted-photo OCR metadata buckets into the Command One
  expense telemetry snapshot. The snapshot now counts both legacy single-value
  metadata and newer bucket/count metadata for cloud assist plan, local OCR
  mode, parser depth, optional cloud OCR, and optional cloud inventory matching.
- Added `receiptParserDepthCounts` and `topReceiptParserDepth` as privacy-safe
  Command One fields so admin health can distinguish price-only versus detailed
  receipt reading without seeing receipt text.
- Updated Firestore summary sanitization, schema expectations, and the OCR
  contract documentation so these fields can be mirrored safely without private
  receipt content.

Validation:
- `flutter test test/expense_screen_telemetry_test.dart test/maintainiac_firestore_documents_test.dart test/expense_command_center_ocr_contract_doc_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/expense_screen_telemetry_test.dart test/maintainiac_firestore_documents_test.dart test/helpers/expense_telemetry_schema_expectations.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is the native camera bridge and receipt
  review flow, keeping the parser/PDF work out of scope until the camera path is
  stable.

### Receipt Camera Reopen Pass 382 / Total Pass 462: Parser-Ready OCR Line Signal Batch

Status: complete.

What changed:
- Added parser-ready computed views to `ReceiptOcrResult`:
  `orderedRawLines`, `orderedParserLines`, `vendorCandidateLines`,
  `priceCandidateLines`, `totalCandidateLines`, `taxCandidateLines`, and
  `parserSignalCounts`.
- Kept the signals local to the OCR result. They are for downstream expense,
  materials, inventory, and maintenance parsers to use; they are not raw
  telemetry uploads.
- Improved OCR review messaging so blocked no-text results can still surface a
  source-limit warning, such as skipped PDFs or proof-only sources, instead of
  hiding that behind the primary blocking warning.
- Added a Lowe's-style receipt test proving ordered line preservation, vendor
  candidate detection, price candidate detection, total detection, tax
  detection, and privacy-safe count summaries.

Validation:
- `flutter test test/receipt_ocr_service_test.dart test/receipt_ocr_overlap_test.dart test/synthetic_receipt_long_retail_torture_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is strengthening the native camera
  capture/review bridge while preserving this parser-ready OCR contract for the
  future inventory/materials and maintenance parsers.

### Receipt Camera Reopen Pass 383 / Total Pass 463: OCR Parser Signal Review Batch

Status: complete.

What changed:
- Extended `ReceiptOcrDiagnostics` with parser-ready line signal counts:
  vendor/header candidates, price candidates, total candidates, and tax
  candidates.
- Added `parserSignalSummaryLabel` so the expense receipt review can explain
  count-level OCR evidence like ordered lines, price candidates, total found,
  and tax found without exposing receipt text in telemetry.
- Wired the receipt parse review diagnostics row to include the parser signal
  summary when OCR text exists.
- Added focused guards proving the OCR service owns the `Parser signals` copy
  and the expense review uses `diagnostics.parserSignalSummaryLabel`.

Validation:
- `flutter test test/receipt_ocr_service_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/receipt_ocr_service_test.dart test/expense_receipt_assisted_review_flow_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is native capture/review bridge
  hardening and device-tier behavior, while keeping parser/PDF expansion out of
  scope until the camera path is stable.

### Receipt Camera Reopen Pass 370 / Total Pass 450: Local OCR Plus Optional Cloud Assist Handoff Batch

Status: complete.

What changed:
- Kept the receipt flow local-first: accepted receipt photos still use local
  OCR/app-assisted filling when local reading is available.
- Clarified the active storage-mode boundary in code: low-storage and maximum
  data-saving modes can offer Google/cloud OCR and cloud inventory matching
  later, but only as explicit user choices.
- Updated the shared receipt OCR status message so optional cloud help is
  described as a later choice, not as a required dependency.
- Updated the expense OCR telemetry handoff to calculate cloud assist from the
  effective data-saver setting, not just from the device model.
- Added guard coverage so both the shared receipt read path and the expense
  receipt state path continue using `cloudAssistPlanFor(...)`.

Validation:
- Pending targeted test/analyzer run.

Next camera/OCR focus:
- Continue camera/OCR only. Next target is the interrupted native capture resume
  path so recovered photos move into photo review/local OCR handoff instead of
  behaving like a plain attachment return.

### Receipt Camera Reopen Pass 372 / Total Pass 452: Interrupted Capture Resume Handoff Batch

Status: complete.

What changed:
- Tightened the interrupted native capture banner copy so Resume clearly means
  review saved receipt photos, then continue into receipt reading.
- Added a privacy-safe `recovery_review_started` diagnostic before the recovered
  photos open in review.
- Changed the accepted recovery action from generic attachment cleanup to
  `cleared_recovery_after_receipt_photos_sent_to_reader`.
- Added source guards proving the resume-start diagnostic, reader handoff
  action, and user-facing copy stay in place.

Validation:
- Pending targeted test/analyzer run.

Next camera/OCR focus:
- Continue camera/OCR only. Next target is stronger route/back handling around
  the native camera and photo review return path.

### Receipt Camera Reopen Pass 373 / Total Pass 453: Native Camera System Back Guard Batch

Status: complete.

What changed:
- Wrapped `ReceiptNativeCameraShell` in `PopScope(canPop: false)` so Android
  system back/gesture back routes through the same `onBack` handler as the
  visible receipt-camera Back button.
- Added widget coverage proving route pop invokes the camera back handler.
- Kept the camera preview, settings, torch, capture, tap-focus, pinch-zoom, and
  exposure controls unchanged.

Validation:
- Pending targeted test/analyzer run.

Next camera/OCR focus:
- Continue camera/OCR only. Next target is native capture route/result
  diagnostics for canceled/back paths so Command One can distinguish user cancel,
  back with staged sections, and native failure.

### Receipt Camera Reopen Pass 374 / Total Pass 454: Native Cancel Reason Bridge Batch

Status: complete.

What changed:
- Android CameraX receipt camera now returns a privacy-safe `closeAction` when
  canceling without captured photos.
- Android `MainActivity` passes that `closeAction` through PlatformException
  details.
- iOS AVFoundation receipt camera now passes the cancel reason through its
  cancel callback.
- iOS `AppDelegate` passes that `closeAction` through FlutterError details.
- Dart `ReceiptNativeCameraCanceledException` now carries `closeAction` so
  caller diagnostics can distinguish `back_no_photo_cancel`,
  `done_no_photo_cancel`, and other safe cancel outcomes.
- Added tests/source guards for the cancel reason bridge and no receipt-content
  leakage.

Validation:
- Pending targeted test/analyzer run.

Next camera/OCR focus:
- Continue camera/OCR only. Next target is using the native cancel close action
  in receipt capture flow diagnostics and recovery messages.

### Receipt Camera Reopen Pass 375 / Total Pass 455: Capture Flow Close Action Diagnostics Batch

Status: complete.

What changed:
- Shared `ReceiptCaptureFlow` now catches
  `ReceiptNativeCameraCanceledException` as `error`.
- Cancel diagnostics now include the native `closeAction` token from Android
  CameraX or iOS AVFoundation.
- This feeds the existing expense/Command One close-action buckets without
  storing receipt content.
- Added source guards proving `closeAction` remains attached to the cancel path.

Validation:
- Pending targeted test/analyzer run.

Next camera/OCR focus:
- Continue camera/OCR only. Next target is source-guarding native close-action
  bridge parity across Android and iOS.

### Receipt Camera Reopen Pass 376 / Total Pass 456: Native Close Action Source Guard Batch

Status: complete.

What changed:
- Added source guards proving Android activity, Android bridge, iOS camera
  controller, and iOS app delegate all preserve the privacy-safe `closeAction`
  reason for canceled native receipt captures.
- This protects the Command One/expense close-action buckets from silently
  degrading back to generic cancel telemetry.

Validation:
- Pending targeted native contract test/analyzer run.

Next camera/OCR focus:
- Continue camera/OCR only. Next target is local OCR/inventory parser input
  contract notes so inventory can consume OCR output later without owning the
  shared camera engine.

### Receipt Camera Reopen Pass 377 / Total Pass 457: Inventory OCR Boundary Note

Status: complete.

Inventory coordination rule:
- Inventory/materials work may build trade packs, item catalogs, material
  matching, SKU aliases, category trees, and inventory-specific parsing.
- Inventory/materials work should not fork or replace the shared receipt camera,
  native CameraX/AVFoundation bridge, OCR service, image processor, stitching,
  photo review, or attachment widgets.
- The inventory parser should consume shared OCR output through a stable input
  contract:
  - `rawOcrText`
  - ordered OCR lines
  - optional prices/totals/tax
  - optional SKU/model candidates
  - optional merchant/vendor name
  - optional confidence/review flags
  - optional source kind such as receipt photo, PDF, or pasted text
- Trade packs should stay downloadable/selectable. Large packs such as plumbing
  should not be forced into the base app payload.
- Low-storage devices should keep local OCR available, while cloud inventory
  matching remains optional and explicit when a huge catalog would overload the
  phone.

Validation:
- Documentation-only pass.

Next camera/OCR focus:
- Continue camera/OCR only. Next target is tightening app-assisted review
  handoff copy and telemetry around local OCR versus optional Google/cloud OCR.

### Receipt Camera Reopen Pass 378 / Total Pass 458: Local OCR Visibility In Settings Batch

Status: complete.

What changed:
- Receipt backup-size settings now show a low-storage/cloud-assist note when the
  active data-saver plan has optional cloud help.
- The note says on-device receipt reading remains available and optional cloud
  OCR/cloud inventory matching require user choice and internet.
- Added guard coverage so the settings sheet keeps that wording and keeps the
  `hasOptionalCloudAssist` condition.

Validation:
- Pending targeted test/analyzer run.

Next camera/OCR focus:
- Continue camera/OCR only. Next target is local/cloud OCR telemetry labels in
  the app-assisted handoff and Command One summary.

### Receipt Camera Reopen Pass 379 / Total Pass 459: Photo Accept Local/Cloud OCR Telemetry Batch

Status: complete.

What changed:
- Receipt photo review acceptance telemetry now includes summary buckets for
  cloud assist plan, local OCR mode, and parser depth.
- It also counts optional cloud OCR and optional cloud inventory matching across
  the accepted photo diagnostics.
- Added source guards so the app-assisted expense review flow keeps these
  local/cloud OCR handoff fields.
- This remains privacy-safe: it only records mode/count tokens, not images,
  receipt text, merchant names, item descriptions, or paths.

Validation:
- Pending targeted test/analyzer run.

Next camera/OCR focus:
- Continue camera/OCR only. Next target is deciding whether these event-level
  local/cloud OCR buckets should be promoted into Command One summary fields.

### Receipt Camera Reopen Pass 371 / Total Pass 451: Cloud Assist Policy Boundary Batch

Status: complete.

What changed:
- Wired the shared receipt OCR path into `ReceiptAssistancePolicy` with
  `cloudAssistedAvailable` based on the active cloud OCR assist plan.
- Wired the expense receipt scan path into the same policy boundary.
- Kept the behavior local-first: the app reads locally only when the policy says
  local read is safe, and cloud OCR remains optional/explicit.
- Added source guards proving both paths keep `cloudAssistPlanFor(...)` and pass
  `cloudAssistedAvailable: cloudAssistPlan.cloudOcrOptional`.

Validation:
- Pending targeted test/analyzer run.

Next camera/OCR focus:
- Continue camera/OCR only. Next target is the interrupted native capture resume
  path so recovered photos move into photo review/local OCR handoff instead of
  behaving like a plain attachment return.
