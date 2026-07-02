# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 531: Long Receipt Warning Task Buckets Batch

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 531: Long Receipt Warning Task Buckets Batch

Status: complete.

What changed:
- Folded long-receipt OCR warnings into parser task counts using separate
  content-free buckets:
  - `long_receipt_duplicate_text`
  - `long_receipt_probable_overlap`
  - `long_receipt_section_gap`
- Carried those buckets through OCR diagnostics, expense parser diagnostics, and
  privacy-safe OCR events.
- Added regression coverage proving duplicate, overlap, and missing-section
  warnings stay separated instead of collapsing into one generic review signal.
- Kept the buckets private: no OCR text, merchant names, item descriptions,
  addresses, phone numbers, notes, line IDs, or prices are recorded.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/data/expense_receipt_privacy_event.dart test/receipt_ocr_service_test.dart test/receipt_privacy_event_test.dart test/expense_parser_failure_diagnostics_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/data/expense_receipt_privacy_event.dart test/receipt_ocr_service_test.dart test/receipt_privacy_event_test.dart test/expense_parser_failure_diagnostics_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --name "long receipt overlap warning task buckets"`
- `flutter test test/receipt_privacy_event_test.dart --name "OCR privacy event"`
- `flutter test test/expense_parser_failure_diagnostics_test.dart --name "long receipt OCR warning task buckets"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is surfacing these long-receipt buckets
  in Command One top-health summaries and review actions so duplicate,
  probable-overlap, and missing-section problems point at different fixes.

### Receipt Camera Reopen Pass 532: Long Receipt Review Action Routing Batch

Status: complete.

What changed:
- Added app-assisted review actions for each long-receipt OCR task bucket:
  duplicate text, probable overlap, and missing section gap.
- Made duplicate overlap point at confirming no duplicate charges, probable
  overlap point at checking repeated or missing charges, and section gap point
  at adding the missing middle section/checking photo order.
- Kept the actions content-free and bucket-driven; no receipt text or line
  content is displayed or stored.
- Added guard coverage so the receipt review flow keeps these separate action
  labels.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --name "assisted expense receipt review exposes whole receipt choices"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is tightening native camera capture
  interruption/resume verification and ensuring accepted images always preserve
  OCR source images separately from storage-saving backup copies.

### Receipt Camera Reopen Pass 363 / Total Pass 443: Command One OCR Contract Documentation Batch

Status: complete.

What changed:
- Audited the Command One OCR handoff documentation after adding native settings
  contract and local/cloud OCR assist telemetry fields.
- Added the missing Command One-visible camera/OCR telemetry keys to the
  contract doc, including saved-photo warnings, exposure decisions, bottom
  brightness/edge quality, native camera engine/settings-contract versions,
  local OCR mode, optional cloud OCR, optional cloud inventory matching, device
  policy, native recovery, capability policy, and stitching buckets.
- Documented the local/cloud boundary plainly: local OCR remains available on
  device, Google/cloud OCR is optional, cloud inventory matching is optional,
  and none of those assists may make basic capture, local OCR, local review, or
  manual entry cloud-only.
- Documented that native CameraX/AVFoundation bridge and settings-contract
  versions are operational count tokens, not device-identifying data.
- Tightened the doc guard so the privacy/cost contract keeps those promises
  visible.

Validation:
- `dart format test/expense_command_center_ocr_contract_doc_test.dart`
- `flutter test test/expense_command_center_ocr_contract_doc_test.dart`
- `flutter analyze test/expense_command_center_ocr_contract_doc_test.dart`

Note:
- `dart format docs/expense_command_center_ocr_contract.md` was attempted and
  correctly rejected because `dart format` treats Markdown as Dart source. The
  Markdown file was left as normal Markdown text.

Next camera/OCR focus:
- Continue camera/OCR only. Next target is bridge parity and focused tests for
  native tap-focus, pinch-zoom, exposure/reset, settings, and back/close
  diagnostics.

### Receipt Camera Reopen Pass 878: Primary Native Capture Contract Batch

Status: complete.

What changed:
- Added primary-capture contract fields to the shared receipt capture flow:
  Maintainiac native receipt camera is primary, stock phone camera UI is not
  allowed as primary, and phone camera backup is fallback-only.
- Added the same primary-vs-backup fields to review-opening diagnostics so
  accepted native photos carry the correct capture-source contract into review.
- Whitelisted those fields in native capture staging diagnostics as
  privacy-safe operational flags.
- Added Android bridge guard coverage proving the native CameraX bridge remains
  the primary capture path and the phone camera remains fallback-only.
- Confirmed the existing document scanner service already blocks Android
  document-scanner routing that could wait on Google Play Services updates.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_native_android_bridge_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_native_android_bridge_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart --name "Android receipt camera bridge" -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_native_android_bridge_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is accepted-photo handoff verification:
  after the user accepts the photo, the app-assisted expense flow must proceed
  into receipt details/OCR review instead of feeling like it returned to the
  attachment starting panel.

### Receipt Camera Reopen Pass 879: Accepted Photo Handoff Clarity Batch

Status: complete.

What changed:
- Added a receipt-review-started state so accepting a photo opens the assisted
  receipt details path instead of looking like the user returned to the
  attachment starting panel.
- Added explicit handoff stage/action/route-result labels for accepted photo
  review so the flow can distinguish parsed receipt fields, parsed totals with
  no safe item lines, manual receipt review, and unreadable saved proof.
- Updated accepted-photo handling to save the draft, record diagnostics, and
  scroll to receipt details review after OCR/parsing starts.
- Preserved OCR-source warnings when the saved proof copy must be used or a
  possible partial receipt needs review.
- Updated the assisted receipt review guard test so it locks the expected
  forward path: accepted photo -> OCR/read status -> receipt details review.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `flutter analyze test/expense_receipt_assisted_review_flow_test.dart`
- `git diff --check -- lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/expense_receipt_assisted_review_flow_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is device/storage-aware capture policy:
  keep the base receipt camera lean, keep heavy parser/OCR/category packs out
  of the required download, and make low-storage users safe without blocking
  local receipt capture.

### Receipt Camera Reopen Pass 880: Storage Footprint Install Policy Batch

Status: complete.

What changed:
- Added `ReceiptFeatureInstallRecommendation` so the receipt stack can decide
  base-only, small optional pack, full optional offline pack, or conservative
  base-first install behavior from storage class and footprint plan.
- Added hardware and capability helpers so critical-storage phones stay on the
  base receipt camera/local OCR path while roomy phones can be offered full
  offline receipt packs only by explicit choice.
- Wired install recommendation diagnostics through the native CameraX/
  AVFoundation session contract and native method-channel payload.
- Whitelisted only privacy-safe install policy fields in native staging,
  expense telemetry, and privacy event storage.
- Added tests proving a very low-storage phone blocks optional local pack
  downloads, low-storage phones may allow only small add-ons, and native camera
  sessions carry the install policy into capture diagnostics.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart lib/screens/expenses/data/expense_screen_telemetry.dart lib/screens/expenses/data/expense_receipt_privacy_event_store.dart test/receipt_assistance_policy_test.dart test/receipt_native_camera_contract_test.dart`
- `flutter test test/receipt_assistance_policy_test.dart --name "receipt install recommendation" -r compact`
- `flutter test test/receipt_native_camera_contract_test.dart --name "session honors device storage pressure" -r compact`
- `flutter test test/receipt_assistance_policy_test.dart test/receipt_native_camera_contract_test.dart -r compact`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart lib/screens/expenses/data/expense_screen_telemetry.dart lib/screens/expenses/data/expense_receipt_privacy_event_store.dart test/receipt_assistance_policy_test.dart test/receipt_native_camera_contract_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart lib/screens/expenses/data/expense_screen_telemetry.dart lib/screens/expenses/data/expense_receipt_privacy_event_store.dart test/receipt_assistance_policy_test.dart test/receipt_native_camera_contract_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is capture/review speed and state
  clarity: make accepted-photo review faster to open, keep Next wording
  consistent, and continue removing anything that makes the user think a saved
  receipt photo disappeared.

### Receipt Camera Reopen Pass 881: Long Receipt Source Section Continuity Batch

Status: complete.

What changed:
- Added OCR handoff diagnostics for long-receipt source section order so the
  app can tell whether section 1, 2, 3 stayed continuous, arrived out of order,
  had a missing gap, or only had partial section locations.
- Added privacy-safe source section counts and continuity status to parser
  handoff contracts, OCR diagnostics, parse diagnostics, privacy events, and
  command/admin aggregate snapshots without storing receipt text.
- Added parser failure diagnostics for out-of-order, missing, or partial
  long-receipt source sections so broken long receipts point to the correct
  camera/stitch handoff step.
- Added focused OCR tests proving out-of-order sections are flagged for review
  while the privacy-safe contract avoids leaking receipt line content.
- Preserved the low-storage/offline strategy: base capture remains lean while
  heavy local OCR/parser packs remain optional and diagnosable.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/data/expense_receipt_privacy_event.dart lib/screens/expenses/data/expense_receipt_privacy_event_store.dart lib/screens/expenses/data/expense_parser_failure_diagnostics.dart test/receipt_ocr_service_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/data/expense_receipt_privacy_event.dart lib/screens/expenses/data/expense_receipt_privacy_event_store.dart lib/screens/expenses/data/expense_parser_failure_diagnostics.dart test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --name "ocr parser handoff flags out-of-order long receipt sections" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --name "source section" -r compact`
- `flutter test test/receipt_privacy_event_test.dart test/receipt_privacy_event_store_test.dart -r compact`
- `flutter test test/receipt_ocr_service_test.dart -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/data/expense_receipt_privacy_event.dart lib/screens/expenses/data/expense_receipt_privacy_event_store.dart lib/screens/expenses/data/expense_parser_failure_diagnostics.dart test/receipt_ocr_service_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is low-storage/local pack selection
  copy and receipt-flow gating: make the app recommend base/local/cloud-style
  OCR choices without forcing a huge install, while keeping original images for
  OCR before proof-size data saving.

### Receipt Camera Reopen Pass 882: Lean Receipt Brain Deployment Policy Batch

Status: complete.

What changed:
- Added `ReceiptBrainDeploymentRecommendation` to separate the base receipt
  camera, local OCR reader, optional offline parser packs, and optional assist
  fallback into one explicit policy object.
- Added hardware and capability helpers so the app can recommend a lean receipt
  brain for phones with critical storage while keeping local receipt capture and
  local receipt reading available.
- Added user-facing summary and storage-warning copy that explains optional
  offline add-ons without calling the saved-proof step "compression" and
  without implying OCR uses the smaller backup image.
- Added privacy-safe diagnostics for the receipt brain mode, local OCR mode,
  optional pack allowance, optional pack size, storage class, device tier, and
  whether the base install remains lean.
- Added tests for a roughly 200 MB free-space phone, a low-storage phone, and a
  roomy flagship-style phone so optional downloads never become mandatory.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart test/receipt_assistance_policy_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart test/receipt_assistance_policy_test.dart`
- `flutter test test/receipt_assistance_policy_test.dart --name "receipt brain recommendation" -r compact`
- `flutter test test/receipt_assistance_policy_test.dart -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart test/receipt_assistance_policy_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is surfacing the receipt brain
  recommendation through native camera session diagnostics and settings/help
  copy so users see "base capture works now, optional offline packs are a
  choice" instead of a scary giant camera download.

### Receipt Camera Reopen Pass 883: Native Receipt Brain Diagnostics Batch

Status: complete.

What changed:
- Wired `ReceiptBrainDeploymentRecommendation` into the native CameraX/
  AVFoundation receipt session config so the camera session knows the effective
  base/local/optional-pack policy for that storage mode.
- Added receipt-brain diagnostics to native method-channel session arguments
  and native capture result diagnostics: brain mode, local OCR mode, base
  capture availability, optional local pack allowance/bytes, assist fallback,
  storage class, device tier, and lean-base status.
- Corrected the recommendation to use the effective session cloud/local plan
  instead of the device's default plan, so maximum data saver and low-storage
  sessions report lean local OCR correctly.
- Surfaced concise settings copy explaining that receipt capture works in the
  base app, optional offline packs are a choice, and OCR reads the clearest
  source before saved-proof space saving.
- Strengthened native contract tests so the storage-constrained channel payload
  cannot lose these policy fields silently.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart test/receipt_native_camera_contract_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart test/receipt_native_camera_contract_test.dart test/receipt_assistance_policy_test.dart`
- `flutter test test/receipt_native_camera_contract_test.dart --name "storage" -r compact`
- `flutter test test/receipt_native_camera_contract_test.dart test/receipt_assistance_policy_test.dart -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart test/receipt_native_camera_contract_test.dart test/receipt_assistance_policy_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is local receipt category pack routing:
  define fuel/material/general receipt pack tiers so the parser can stay small
  by default while still leaving room for stronger offline packs by category
  and region later.

### Receipt Camera Reopen Pass 884: Category Pack Routing Policy Batch

Status: complete.

What changed:
- Added `ReceiptParserCategoryPackRoute` and
  `ReceiptParserPackRoutingPlan` so receipt intelligence can be routed by
  category without forcing every category/region pack into the base app.
- Defined local-first routing for fuel receipts so common gas/diesel/DEF
  receipts remain usable on-device while future regional fuel pattern packs can
  strengthen merchant and pump-line parsing.
- Defined general expense routing through the base reader plus optional
  line-item packs when the device/storage mode allows them.
- Defined materials/inventory routing as optional trade/region pack work so
  contractor intelligence can grow without bloating the required install.
- Added privacy-safe routing diagnostics: route count, local-first categories,
  optional-local categories, assist-fallback categories, and future regional
  category codes.
- Added tests proving lean plans keep fuel local-first, keep materials optional
  or assist-backed, and roomy plans can offer materials as an offline optional
  pack.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart test/receipt_assistance_policy_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart test/receipt_assistance_policy_test.dart`
- `flutter test test/receipt_assistance_policy_test.dart --name "parser pack routing" -r compact`
- `flutter test test/receipt_assistance_policy_test.dart -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart test/receipt_assistance_policy_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is surfacing parser pack routing in
  native/session diagnostics and receipt settings copy so command/admin can see
  which categories are local-first, optional local, or assist-backed without
  seeing receipt content.

### Receipt Camera Reopen Pass 885: Native Category Pack Routing Diagnostics Batch

Status: complete.

What changed:
- Wired `ReceiptParserPackRoutingPlan` into the native receipt camera session
  config so CameraX/AVFoundation sessions carry the effective category routing
  policy alongside cloud/install/brain policy.
- Added parser-pack route diagnostics to native method-channel arguments and
  capture result diagnostics: route count, local-first categories,
  optional-local categories, assist-fallback categories, and future regional
  category codes.
- Added settings copy that explains fuel stays local-first while
  materials/inventory intelligence can grow through optional trade or regional
  packs instead of bloating the base app.
- Strengthened native contract tests so low-storage sessions prove materials
  are not forced local-first while storage-constrained maximum sessions still
  report the full privacy-safe category routing map.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart test/receipt_native_camera_contract_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart test/receipt_native_camera_contract_test.dart test/receipt_assistance_policy_test.dart`
- `flutter test test/receipt_native_camera_contract_test.dart --name "storage" -r compact`
- `flutter test test/receipt_native_camera_contract_test.dart test/receipt_assistance_policy_test.dart -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart test/receipt_native_camera_contract_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is local OCR/parser confidence routing
  by receipt category: expose whether fuel/material/general lines are strong,
  weak, or pack-limited so the review screen and command/admin know what failed
  without storing the receipt text.

### Receipt Camera Reopen Pass 886: Category-Level Parser Confidence Routing Batch

Status: complete.

What changed:
- Extended parser category health diagnostics with confidence buckets per
  category and category family (`strong`, `ready`, `weak`, `poor`) so expense
  review and command/admin can see which receipt categories are reliable
  without storing receipt text.
- Added pack-limit diagnostics for categories that need optional local packs or
  future assist routing instead of forcing every parser brain into the base
  install. Materials now reports pack-limited when inventory matching is not
  available; fuel remains local-first.
- Added parser diagnostic helpers for pack-limit and weak-confidence checks so
  UI, telemetry, and admin health screens can ask simple questions without
  hard-coding every bucket name.
- Strengthened parser tests around fuel, materials line-item mode, and heavy
  inventory-matching mode so the lean base app keeps fuel local while materials
  can grow through optional trade/regional packs.
- Updated the OCR parser readiness expectation to include source-section
  continuity, matching the newer long-receipt diagnostics.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/data/expense_receipt_parse_models.dart test/expense_receipt_parser_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/data/expense_receipt_parse_models.dart test/expense_receipt_parser_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --name "parser depth" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --name "parses expense fields from OCR parser-ready receipt signals" -r compact`
- `flutter test test/expense_receipt_parser_test.dart -r compact`
- `git diff --check -- lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/data/expense_receipt_parse_models.dart test/expense_receipt_parser_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is receipt brain install-size surfacing:
  expose estimated base/optional brain size and category-pack choices in
  privacy-safe diagnostics so older phones can stay lean while newer phones can
  opt into stronger local parsing.

### Receipt Camera Reopen Pass 887: Receipt Brain Footprint Summary Batch

Status: complete.

What changed:
- Added `ReceiptBrainFootprintSummary` so the receipt system can distinguish
  base receipt camera/local reader budget from optional offline parser packs.
- Exposed base receipt budget, included local pack bytes, optional local pack
  bytes, full-offline receipt budget, parser depth, local OCR mode, storage
  class, optional pack codes, and cloud fallback pack codes without including
  receipt content or private user data.
- Added hardware/capability helpers so S9-class and S24/S25-class devices ask
  the same policy layer for footprint guidance.
- Kept optional parser packs detached from the base install: critical storage
  devices keep capture and lean local reading available, while roomy devices
  can choose stronger offline packs after explicit download.
- Added tests proving the base receipt camera/reader remains lean on critical
  storage and that the 100 MB materials/inventory pack remains optional on
  roomy devices.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart test/receipt_assistance_policy_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart test/receipt_assistance_policy_test.dart`
- `flutter test test/receipt_assistance_policy_test.dart --name "receipt brain footprint" -r compact`
- `flutter test test/receipt_assistance_policy_test.dart -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart test/receipt_assistance_policy_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is wiring the receipt brain footprint
  summary into native session diagnostics and settings copy so the app can tell
  low-storage users what stays in the base app and what is an optional download.
