# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 367 / Total Pass 447: Command One Native Control Telemetry Batch

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 367 / Total Pass 447: Command One Native Control Telemetry Batch

Status: complete.

What changed:
- Carried native CameraX/AVFoundation control diagnostics from receipt capture
  results into privacy-safe expense OCR-start telemetry.
- Added content-free telemetry for native control contract versions and expected
  controls: tap focus, pinch zoom, exposure slider, exposure reset, settings,
  back, and torch.
- Added `settingsOpenTotal` so Command One can later show whether users are
  opening receipt-camera settings without recording what receipt they scanned.
- Added Command One health snapshot fields for native control contract version
  counts, top native control contract version, expected-control counts, and
  settings-open count.
- Updated Firestore summary sanitization so those fields survive into the
  existing one-document expense telemetry summary without uploading raw events
  or private receipt content.
- Updated the OCR contract documentation to state that local OCR remains
  available, Google/cloud OCR is optional, cloud inventory matching is optional,
  and native control diagnostics are safe version/count tokens only.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/expense_screen_telemetry_test.dart test/helpers/expense_telemetry_schema_expectations.dart test/maintainiac_firestore_documents_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart`
- `flutter test test/maintainiac_firestore_documents_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is the native camera/service boundary
  for low-storage device tiers and optional cloud assist routing so local OCR,
  Google/cloud OCR, and cloud inventory matching remain explicit, measurable,
  and replaceable without changing the receipt-flow UI.

### Receipt Camera Reopen Pass 368 / Total Pass 448: Storage-Aware Local/Cloud Assist Contract Batch

Status: complete.

What changed:
- Audited the receipt assistance policy, device capability profile, native
  camera session config, native camera bridge, OCR service limits, and focused
  tests for local OCR versus optional cloud assist behavior.
- Added `ReceiptDeviceCapability.cloudAssistPlanFor(dataSaverLevel:)` so the
  effective session storage mode controls local/cloud receipt work, not just the
  static hardware profile.
- Kept local OCR available for every tier while switching storage-constrained
  sessions into lean local OCR.
- Trimmed local catalog and local inventory cache limits when the effective
  data saver level is `strong` or `maximum`, so low-storage users are not forced
  to carry the full local matching workload.
- Kept Google/cloud OCR and cloud inventory matching as explicit optional assist
  paths, never as requirements for basic capture, local OCR, local review, or
  manual entry.
- Passed the privacy-safe cloud assist diagnostics through the native camera
  session arguments and returned capture diagnostics:
  `cloudAssistPlan`, `localOcrAvailable`, `localOcrMode`,
  `cloudOcrOptional`, `cloudInventoryOptional`,
  `cloudAssistRequiresExplicitChoice`, `parserDepth`,
  `localCatalogMatchLimit`, `localInventoryCacheLimit`, and `dataSaverLevel`.
- Added tests proving light/low-storage profiles send lean local OCR with
  optional cloud OCR/inventory, normal profiles remain local-only, and a
  high-capacity phone using maximum data saver trims local catalog/cache work
  while preserving local OCR.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart test/receipt_assistance_policy_test.dart test/receipt_native_camera_contract_test.dart`
- `flutter test test/receipt_assistance_policy_test.dart test/receipt_native_camera_contract_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is making the post-capture interruption
  recovery path prove that accepted native captures are staged locally/Hive-safe
  before OCR/review navigation, so a phone call, app switch, crash, or back
  action does not silently lose receipt photos.

### Receipt Camera Reopen Pass 369 / Total Pass 449: Interruption-Safe Native Staging Diagnostics Batch

Status: complete.

What changed:
- Audited `ReceiptNativeCaptureStaging`, the JSON recovery manifest path, the
  Hive-backed native capture recovery index, and existing staging tests.
- Preserved the new local/cloud OCR assist diagnostics through native capture
  staging so interrupted receipt captures keep their operational context:
  `cloudAssistPlan`, `localOcrAvailable`, `localOcrMode`,
  `cloudOcrOptional`, `cloudInventoryOptional`,
  `cloudAssistRequiresExplicitChoice`, `parserDepth`,
  `localCatalogMatchLimit`, and `localInventoryCacheLimit`.
- Preserved native control contract diagnostics through staging/recovery:
  `nativeControlContractVersion`, `controlDiagnosticsPrivacyScope`,
  tap-focus expected, pinch-zoom expected, exposure-slider/reset expected,
  settings expected, back expected, and torch expected.
- Kept the staging allowlist content-free; private receipt text remains dropped
  from staged diagnostics, recovery manifests, and the Hive recovery index.
- Extended recovery tests so staged result, manifest recovery, and Hive-only
  recovery all prove the same safe diagnostics survive interruption.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_native_capture_staging_test.dart`
- `flutter test test/receipt_native_capture_staging_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is confirming the expense receipt entry
  flow consumes interrupted native capture recovery records cleanly and routes
  resumed captures into photo review/OCR handoff without falling back to the
  expense home screen.

### Receipt Camera Reopen Pass 364 / Total Pass 444: Native Preview Control Callback Batch

Status: complete.

What changed:
- Added real Maintainiac-owned preview control hooks to the native receipt
  camera shell instead of only showing control labels.
- Tap-to-focus now reports normalized preview coordinates when supported by the
  native CameraX/AVFoundation capability contract and enabled in receipt camera
  settings.
- Pinch zoom now reports clamped zoom values when native zoom is available and
  the user performs a two-finger scale gesture.
- Added a compact brightness/exposure rail with reset control when native
  exposure compensation is available.
- Kept the preview full-screen and the top bar/bottom shutter controls outside
  the middle of the receipt view.
- Added widget coverage proving settings, torch, shutter, back, tap focus,
  pinch zoom, and brightness reset callbacks all fire from the shell.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_camera_shell.dart test/receipt_native_camera_shell_test.dart`
- `flutter test test/receipt_native_camera_shell_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_camera_shell.dart test/receipt_native_camera_shell_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is passing native preview control
  events through the service/channel contract so Android CameraX and iOS
  AVFoundation can receive focus, zoom, exposure, reset, back, and settings
  diagnostics without exposing receipt content.

### Receipt Camera Reopen Pass 365 / Total Pass 445: Native Control Channel Contract Batch

Status: complete.

What changed:
- Added a flat native control contract to the receipt camera service launch
  arguments so Android can receive it through scalar Intent extras and iOS can
  receive the same MethodChannel payload.
- The contract now declares `receipt_native_controls_v1`,
  `summary_only_no_receipt_content`, and expected control support for tap focus,
  pinch zoom, brightness slider, brightness reset, settings, back, and torch.
- Added the same content-free control contract into returned capture
  diagnostics so later telemetry can prove which control surface was expected
  for a capture without receipt text, image content, store names, or line-item
  data.
- Added channel tests proving the previous-section long-receipt native capture
  path sends and preserves the new control contract.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart test/receipt_native_camera_contract_test.dart`
- `flutter test test/receipt_native_camera_contract_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart test/receipt_native_camera_contract_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is native Android/iOS implementation
  parity for focus, zoom, exposure, reset, settings, back, and torch control
  behavior inside the actual CameraX and AVFoundation screens.

### Receipt Camera Reopen Pass 366 / Total Pass 446: Native Control Diagnostics Parity Batch

Status: complete.

What changed:
- Audited the actual native CameraX and AVFoundation receipt camera screens.
- Confirmed both native screens already implement tap focus, pinch zoom,
  brightness/exposure controls, brightness reset, settings, back/cancel, and
  torch behavior.
- Added native `settingsOpenCount` tracking on Android and iOS.
- Added native capture diagnostics for `receipt_native_controls_v1`,
  `summary_only_no_receipt_content`, tap-focus expected, pinch-zoom expected,
  exposure-slider expected, exposure-reset expected, settings expected, back
  expected, and torch expected.
- Fixed an iOS simulator compile failure in `CapturedPhotoQualitySample` where
  one fallback constructor missed the newer top/middle/bottom/bottom-edge
  quality fields.
- Added a source guard proving Android and iOS native camera screens keep the
  content-free control diagnostics and do not add raw receipt/OCR text fields.

Validation:
- `dart format test/receipt_native_camera_contract_test.dart`
- `flutter test test/receipt_native_camera_contract_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart test/receipt_native_camera_contract_test.dart`
- `xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Debug -sdk iphonesimulator -quiet build`

Blocked validation:
- `./gradlew :app:compileDebugKotlin` from `android/` could not run because
  this Mac session cannot locate a Java runtime.

Next camera/OCR focus:
- Continue camera/OCR only. Next target is carrying native control diagnostics
  into privacy-safe expense OCR telemetry and Command One health buckets so
  focus/zoom/exposure/settings/back problems are visible without receipt
  content.

### Receipt Camera Reopen Pass 522: Duplicate Overlap Review Cause Batch

Status: complete.

What changed:
- Promoted duplicate long-receipt overlap warnings into a specific
  privacy-safe parser review cause: `receipt_possible_duplicate_overlap`.
- Kept the cause content-free so Command One can show exactly why the parser
  needs review without exposing merchant names, item descriptions, prices, or
  receipt text.
- Added a regression test proving repeated line warnings produce the new cause
  while redacting vendor, item, and amount strings from the emitted event map.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_privacy_event.dart test/receipt_privacy_event_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_receipt_privacy_event.dart test/receipt_privacy_event_test.dart`
- `flutter test test/receipt_privacy_event_test.dart --name "duplicate overlap|total mismatch|tax math"`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is stronger parser line-role telemetry
  for vendor/date/total/line-item preparation so inventory and materials can
  reuse OCR output without receipt content leaking into diagnostics.

### Receipt Camera Reopen Pass 523: Parser Role Telemetry Batch

Status: complete.

What changed:
- Added parser-level, content-free line-role counts for vendor, date, time,
  subtotal, tax, total, item, item price, review item, and parsed expense
  categories.
- Added parser-level, content-free task counts for detected or missing vendor,
  date, time, subtotal, tax, total, ready item prices, and item prices needing
  review.
- Exposed those counts through `PrivacySafeReceiptEvent` and the local Hive
  privacy event health snapshot so Command One can show what the parser
  understood without receipt text, item descriptions, merchant names, or prices.
- Added regression coverage for direct privacy events and Command One snapshot
  aggregation.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/data/expense_receipt_privacy_event.dart lib/screens/expenses/data/expense_receipt_privacy_event_store.dart test/receipt_privacy_event_test.dart test/receipt_privacy_event_store_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/data/expense_receipt_privacy_event.dart lib/screens/expenses/data/expense_receipt_privacy_event_store.dart test/receipt_privacy_event_test.dart test/receipt_privacy_event_store_test.dart`
- `flutter test test/receipt_privacy_event_test.dart --name "parser privacy event reports counts|duplicate overlap|total mismatch|tax math"`
- `flutter test test/receipt_privacy_event_store_test.dart --name "health snapshot|tax math"`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is parser readiness hardening for mixed
  business/personal receipt classification and split-tax math preparation.

### Receipt Camera Reopen Pass 524: Pre-Save Split Allocation Preview Batch

Status: complete.

What changed:
- Added pre-save receipt math helpers to `ExpenseReceiptParseResult` so the
  app-assisted receipt review screen can show subtotal, tax, total, tax rate,
  receipt adjustment, business total, personal total, and per-line allocated
  totals before writing an expense record.
- Reused the same proportional allocation approach already used by saved
  receipts, so mixed business/personal classification behaves consistently
  before and after save.
- Added regression coverage for fuel receipt tax allocation and mixed
  business/personal/split line allocation before save.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parse_models.dart test/expense_receipt_parser_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_receipt_parse_models.dart test/expense_receipt_parser_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --name "fuel receipt|previews mixed receipt|mixed receipt text"`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is strengthening OCR/parser handoff for
  known vendor, item price, quantity, and material/inventory preparation signals
  without adding heavy device payloads.

### Receipt Camera Reopen Pass 525: Return-Safe Split Allocation Batch

Status: complete.

What changed:
- Aligned pre-save parsed receipt allocation math with the live receipt review
  UI by using positive business/personal adjustment bases for tax, fees,
  discounts, and receipt-level adjustments.
- Prevented return/negative lines from receiving extra allocated tax or
  adjustment during app-assisted receipt review.
- Added regression coverage proving a return line keeps its negative value
  while positive business and personal lines receive the receipt adjustment
  proportionally.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parse_models.dart test/expense_receipt_parser_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_receipt_parse_models.dart test/expense_receipt_parser_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --name "pre-save allocation|fuel receipt|mixed receipt text"`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is strengthening OCR/parser handoff for
  known vendor, item price, quantity, material/inventory preparation, and
  review-screen confidence evidence without adding heavy device payloads.

### Receipt Camera Reopen Pass 526: Parser Missing-Field Diagnostics Batch

Status: complete.

What changed:
- Added content-free OCR/parser missing-field counts for vendor, date, item
  prices, summary, subtotal, tax, and total signals.
- Added parser review task counts for line sequence review, summary math review,
  reviewed item prices, and missing parser-ready item prices.
- Merged these missing/review task counts into parser task counts, field
  readiness counts, and handoff counts so receipt review and Command One can
  show exactly what failed to parse without storing receipt text, merchant names,
  item descriptions, addresses, or prices.
- Added regression coverage for clean receipts, generic item review, bad line
  order, and weak OCR text that lacks structured receipt fields.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --name "parser line signals|parser handoff signals"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is using these parser missing/review
  buckets in the app-assisted receipt review flow so the user sees a clear next
  action when OCR found text but missed vendor, total, item prices, or receipt
  structure.

### Receipt Camera Reopen Pass 527: Assisted Review Missing-Field Chips Batch

Status: complete.

What changed:
- Updated the app-assisted receipt review guidance so parser fields can show
  separate missing states instead of only ready or needs-review states.
- Added user-facing chips for missing store, date, subtotal, tax, total, item
  prices, and totals section signals.
- Kept the chips content-free: they describe parser field status only and do not
  expose merchant names, item descriptions, addresses, phone numbers, notes, or
  prices.
- Added guard coverage to keep the missing-field chip labels and diagnostic
  count helper in the assisted review flow.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --name "app-assisted receipt review"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is routing parser missing/review buckets
  into privacy-safe telemetry event details so Command One can aggregate exactly
  which receipt fields fail most often without seeing receipt content.

### Receipt Camera Reopen Pass 528: OCR Parser Failure Telemetry Buckets Batch

Status: complete.

What changed:
- Added OCR parser task counts and OCR field readiness counts to parser telemetry
  metadata for completed, needs-review, and failed parser outcomes.
- Aggregated those count-only buckets into the expense telemetry health snapshot
  so Command One can show parser health by exact field/task failure type.
- Covered missing vendor, missing total, missing item prices, missing tax, item
  prices needing review, and parser-ready field buckets in telemetry tests.
- Kept the telemetry privacy-safe: only allowlisted bucket names and counts are
  recorded, never receipt text, merchant names, item descriptions, addresses,
  phone numbers, notes, or prices.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart --name "summarizes parser category health"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is tightening parser failure diagnostics
  so missing OCR handoff fields map to confirmed causes like
  `receipt_parser_missing_total` or `receipt_parser_missing_item_prices`.

### Receipt Camera Reopen Pass 529: Exact OCR Handoff Failure Causes Batch

Status: complete.

What changed:
- Added OCR parser task-count priority checks to parser failure diagnostics so
  missing/review handoff buckets become confirmed causes before generic parser
  readiness causes.
- Added exact causes and failure stages for missing date, missing summary,
  missing tax, line-sequence review, and summary-math review handoff failures.
- Added the OCR parser task bucket keys to diagnostic evidence so failures can
  be traced by exact parser bucket without storing receipt content.
- Added Command One operator guidance for the new failure causes.
- Added regression coverage proving each new OCR handoff task bucket maps to the
  intended confirmed cause and workflow stage.

Validation:
- `dart format lib/screens/expenses/data/expense_parser_failure_diagnostics.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_parser_failure_diagnostics_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_parser_failure_diagnostics.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_parser_failure_diagnostics_test.dart`
- `flutter test test/expense_parser_failure_diagnostics_test.dart --name "OCR parser"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is expanding parser evidence labels for
  vendor/item/total missing paths into the review UI and health breakdowns where
  they are still too general.

### Receipt Camera Reopen Pass 530: Top OCR Handoff Health Actions Batch

Status: complete.

What changed:
- Added `topOcrParserTask` and `topOcrFieldReadiness` to the expense telemetry
  health snapshot and Command One map so the biggest OCR/parser handoff bucket
  is visible without manually scanning count maps.
- Added OCR parser task driven review actions for missing vendor, date, total,
  summary, tax, item prices, line sequence, item-price review, and summary math
  review.
- Kept the review actions and Command One fields content-free: they expose only
  allowlisted parser task names, readiness names, and counts.
- Added regression coverage for the top OCR handoff health keys and the
  app-assisted review action routing.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_parse_review.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_parse_review.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart --name "summarizes parser category health"`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --name "assisted expense receipt review exposes whole receipt choices"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is strengthening OCR parser task labels
  and health buckets for long-receipt stitching/overlap failure causes so
  duplicate, missing-middle, and out-of-order receipt sections are clearly
  separated.
