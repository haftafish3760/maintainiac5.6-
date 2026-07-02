# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 888: Native Footprint Diagnostics And Settings Copy Batch

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 888: Native Footprint Diagnostics And Settings Copy Batch

Status: complete.

What changed:
- Wired `ReceiptBrainFootprintSummary` into
  `ReceiptNativeCameraSessionConfig` so the effective native camera session
  carries the same base-vs-optional footprint plan as the receipt policy layer.
- Added footprint diagnostics to native camera launch arguments and accepted
  capture diagnostics: base budget bytes, included local pack bytes, optional
  local pack bytes, full offline budget bytes, storage class, parser depth,
  optional pack codes, cloud fallback pack codes, and lean-base flags.
- Updated the receipt photo settings copy to explain that receipt capture and
  the base local reader stay in the base app budget while stronger offline
  add-ons are optional downloads.
- Fixed settings copy to use the effective selected data-saver cloud plan when
  building receipt-brain text, avoiding mismatches between selected data saver
  and displayed pack size.
- Strengthened native contract tests so storage-constrained sessions prove the
  base stays lean, optional packs are deferred, and the full-offline budget is
  reported separately from what the phone is allowed to download.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart test/receipt_native_camera_contract_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart test/receipt_native_camera_contract_test.dart`
- `flutter test test/receipt_native_camera_contract_test.dart --name "storage" -r compact`
- `flutter test test/receipt_native_camera_contract_test.dart -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart test/receipt_assistance_policy_test.dart test/receipt_native_camera_contract_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is category-pack UI readiness: expose
  clear settings/review copy for fuel local-first, general optional line-item
  packs, and materials/inventory optional trade or regional packs without
  forcing those packs into the base app.

### Receipt Camera Reopen Pass 889: Category Pack Settings Summary Batch

Status: complete.

What changed:
- Added `ReceiptParserPackRoutingPlan.userFacingCategoryPackSummary` to give
  concise user-facing copy for category-pack behavior without exposing raw
  device details or receipt content.
- Updated receipt photo settings to use the concise summary instead of dumping
  longer route labels for individual categories.
- Locked the copy to the storage strategy: fuel receipts stay local-first,
  general line-item help can be optional, materials/inventory stays optional by
  trade or region, and receipt capture works without downloading add-ons.
- Strengthened policy tests so the category-pack summary stays honest for both
  lean/cloud-assist setups and roomy/full-offline setups.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart test/receipt_assistance_policy_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart test/receipt_assistance_policy_test.dart`
- `flutter test test/receipt_assistance_policy_test.dart --name "parser pack routing" -r compact`
- `flutter test test/receipt_assistance_policy_test.dart -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart test/receipt_assistance_policy_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is local parser pack recommendation
  handoff from diagnostics: use weak/pack-limited category counts to decide
  whether the review screen should suggest retake, local optional pack, or
  manual review without blocking save.

### Receipt Camera Reopen Pass 890: Parser Category Review Action Batch

Status: complete.

What changed:
- Added parser category review action helpers to
  `ExpenseReceiptParseDiagnostics` so downstream receipt review can choose a
  sane next message without inspecting every bucket manually.
- Added action codes for no category signals, no priced lines,
  low-confidence lines, optional parser pack availability, flagged-line review,
  and ready-to-save states.
- Added user-facing labels for those actions that guide review without blocking
  save.
- Strengthened parser tests for fuel ready receipts, materials receipts where
  inventory matching was skipped, heavy inventory-matching receipts, and weak
  receipts where most lines need review.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parse_models.dart test/expense_receipt_parser_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_receipt_parse_models.dart test/expense_receipt_parser_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --name "parses fuel receipt|medium parser depth|heavy parser depth|flags receipts" -r compact`
- `flutter test test/expense_receipt_parser_test.dart -r compact`
- `git diff --check -- lib/screens/expenses/data/expense_receipt_parse_models.dart test/expense_receipt_parser_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is exposing the parser category review
  action through privacy-safe event diagnostics so command/admin can show
  whether receipt failures are photo quality, missing source sections, weak
  parser confidence, or optional-pack limits.

### Receipt Camera Reopen Pass 891: Privacy-Safe Parser Action Diagnostics Batch

Status: complete.

What changed:
- Added `parserCategoryReviewActionCode` to privacy-safe parser events so
  command/admin can aggregate whether the next action is ready, manual review,
  low-confidence review, no priced lines, or optional parser pack availability.
- Added `parserCategoryReviewActionCounts` to the command-center health
  snapshot so admin can see the failure/action mix without receipt content.
- Kept the user-facing action label out of the persisted/uploaded privacy
  event payload. The app can still render local labels from parser diagnostics,
  but telemetry stores only safe token-style codes.
- Updated privacy tests to prove parser action codes survive sanitization and
  aggregation while receipt text, vendor text, item text, prices, and line IDs
  remain absent.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_privacy_event.dart lib/screens/expenses/data/expense_receipt_privacy_event_store.dart test/receipt_privacy_event_test.dart test/receipt_privacy_event_store_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_receipt_privacy_event.dart lib/screens/expenses/data/expense_receipt_privacy_event_store.dart test/receipt_privacy_event_test.dart test/receipt_privacy_event_store_test.dart`
- `flutter test test/receipt_privacy_event_test.dart test/receipt_privacy_event_store_test.dart -r compact`
- `git diff --check -- lib/screens/expenses/data/expense_receipt_privacy_event.dart lib/screens/expenses/data/expense_receipt_privacy_event_store.dart test/receipt_privacy_event_test.dart test/receipt_privacy_event_store_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is review-screen handoff readiness:
  expose the local parser action label in the assisted receipt review model so
  users see clear guidance after OCR instead of cryptic quality scores.

### Receipt Camera Reopen Pass 892: Assisted Review Parser Action Handoff Batch

Status: complete.

What changed:
- Wired parser category review actions into the assisted receipt review action
  strip so users can see practical next steps after OCR/parser handoff.
- Added category-action labels for low-confidence lines, optional parser pack
  help, flagged lines, and no priced lines.
- Ranked category review actions alongside existing math, OCR readiness, photo
  order, overlap, and retake actions so the guidance stays compact and useful.
- Kept privacy boundaries intact: friendly labels are local UI guidance only;
  privacy event storage from Pass 891 keeps token-style action codes.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart -r compact`
- `git diff --check -- lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is one consolidated focused validation
  batch across parser policy, native camera diagnostics, privacy events, and
  assisted review guidance after the size/pack-routing changes.

### Receipt Camera Reopen Pass 893: Consolidated Size And Pack Routing Validation

Status: complete.

What changed:
- No product code changes in this pass. This was a consolidation checkpoint
  after the receipt-brain footprint, parser pack routing, parser action,
  privacy event, native diagnostics, and assisted review guidance changes.

Validation:
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/data/expense_receipt_privacy_event.dart lib/screens/expenses/data/expense_receipt_privacy_event_store.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/receipt_assistance_policy_test.dart test/receipt_native_camera_contract_test.dart test/receipt_privacy_event_test.dart test/receipt_privacy_event_store_test.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/receipt_assistance_policy_test.dart test/receipt_native_camera_contract_test.dart test/receipt_privacy_event_test.dart test/receipt_privacy_event_store_test.dart test/expense_receipt_assisted_review_flow_test.dart -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/data/expense_receipt_privacy_event.dart lib/screens/expenses/data/expense_receipt_privacy_event_store.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/receipt_assistance_policy_test.dart test/receipt_native_camera_contract_test.dart test/receipt_privacy_event_test.dart test/receipt_privacy_event_store_test.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is applying the same base-vs-optional
  policy to the actual receipt settings/review state so low-storage users are
  never prompted into a giant local parser pack by accident.

### Receipt Camera Reopen Pass 894: Settings Footprint Source Of Truth Batch

Status: complete.

What changed:
- Added controller-level data-saver policy getters for the current receipt
  storage class, cloud-assist plan, receipt-brain recommendation, footprint
  summary, parser-pack routing plan, parser-pack install choice, and optional
  local parser-pack prompt decision.
- Moved the receipt settings sheet away from recomputing storage-class and
  footprint policy inside the widget. The UI now uses the settings controller as
  the single source of truth, reducing the chance that low-storage phones get a
  misleading heavy-pack prompt.
- Kept the core promise explicit in tests: receipt capture and the base local
  reader stay within the lean base budget, stronger parser packs remain
  detached from the base install, maximum space saving defers optional local
  packs, and strong space saving can offer only the small general line-item
  add-on.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_settings_store.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart test/receipt_capture_settings_store_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_settings_store.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart test/receipt_capture_settings_store_test.dart`
- `flutter test test/receipt_capture_settings_store_test.dart -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_capture_settings_store.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart test/receipt_capture_settings_store_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is carrying the same lightweight
  footprint and parser-pack choice into receipt review handoff copy so the user
  sees "Next" and practical add-photo/review actions without hidden heavy local
  downloads.

### Receipt Camera Reopen Pass 895: Review Footprint Handoff Batch

Status: complete.

What changed:
- Added local review guidance that reads the receipt settings controller's
  footprint summary during OCR/parser review.
- When parser diagnostics say an optional parser pack may help, the review now
  distinguishes between tight-storage phones where optional packs are deferred
  and roomier setups where a small optional offline add-on can be offered later.
- Added compact local-only action labels such as "Continue without add-on",
  "Review by hand", and "Optional add-on later" without triggering any download
  or telemetry write.
- Reinforced the copy that OCR review uses the clear source first and saved
  proof size does not weaken the OCR source.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart -r compact`
- `git diff --check -- lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is a compact end-to-end validation pass
  over settings, native-camera diagnostics, OCR/parser review, and privacy-safe
  events after the footprint and optional-pack handoff changes.

### Receipt Camera Reopen Pass 896: Required Base Size Guardrail Batch

Status: complete.

What changed:
- Added explicit receipt-brain base-install budget guardrails:
  - lean required receipt base target: 40 MB
  - maximum required receipt base guardrail: 100 MB
- Added privacy-safe diagnostics that expose whether the required receipt base
  is still under the guardrail and which install tier it falls into.
- Tightened `baseInstallKeepsReceiptBrainLean` so it only remains true when
  the receipt brain has no included heavy parser packs and the required base
  stays under the 100 MB guardrail.
- Sent the new guardrail diagnostics through the native camera launch/capture
  contract so camera health can show base-size safety without any receipt
  content.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart test/receipt_assistance_policy_test.dart test/receipt_native_camera_contract_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart test/receipt_assistance_policy_test.dart test/receipt_native_camera_contract_test.dart`
- `flutter test test/receipt_assistance_policy_test.dart test/receipt_native_camera_contract_test.dart -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart test/receipt_assistance_policy_test.dart test/receipt_native_camera_contract_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is consolidating the size guardrail,
  settings source of truth, review handoff, and privacy-safe diagnostics in one
  focused validation pass before moving to the next camera/OCR hardening item.

### Receipt Camera Reopen Pass 897: Consolidated Footprint Validation

Status: complete.

What changed:
- No product code changes in this pass. This was a consolidation checkpoint
  after the settings source-of-truth, review footprint handoff, and required
  base-size guardrail changes.
- Verified that receipt policy, native camera diagnostics, settings store,
  settings sheet, assisted review, parse diagnostics, and privacy-safe event
  storage still agree on the base-vs-optional receipt brain model.

Validation:
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_store.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_privacy_event.dart lib/screens/expenses/data/expense_receipt_privacy_event_store.dart test/receipt_assistance_policy_test.dart test/receipt_native_camera_contract_test.dart test/receipt_capture_settings_store_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_privacy_event_test.dart test/receipt_privacy_event_store_test.dart`
- `flutter test test/receipt_assistance_policy_test.dart test/receipt_native_camera_contract_test.dart test/receipt_capture_settings_store_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_privacy_event_test.dart test/receipt_privacy_event_store_test.dart -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_store.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_privacy_event.dart lib/screens/expenses/data/expense_receipt_privacy_event_store.dart test/receipt_assistance_policy_test.dart test/receipt_native_camera_contract_test.dart test/receipt_capture_settings_store_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_privacy_event_test.dart test/receipt_privacy_event_store_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is receipt parser pack scoping for fuel
  and low-storage first-run behavior so common fuel receipts remain useful even
  when optional materials/inventory packs are not installed.

### Receipt Camera Reopen Pass 898: Fuel-First Parser Pack Routing

Status: complete.

What changed:
- Adjusted parser-pack routing so fuel receipt essentials stay local-first in
  the base reader and are not marked as requiring the optional general
  line-item pack.
- Kept optional future regional fuel patterns as a later add-on path, but the
  current fuel flow remains useful on low-storage phones without downloading
  heavy packs.
- Left general expense line detail as the small optional local add-on and kept
  materials/inventory matching behind optional trade/region packs or optional
  assisted fallback.
- Updated native camera diagnostics tests so admin/camera health sees fuel as
  local-first while optional-local categories only include the categories that
  actually need add-ons.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart test/receipt_assistance_policy_test.dart test/receipt_native_camera_contract_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart test/receipt_assistance_policy_test.dart test/receipt_native_camera_contract_test.dart`
- `flutter test test/receipt_assistance_policy_test.dart test/receipt_native_camera_contract_test.dart -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart test/receipt_assistance_policy_test.dart test/receipt_native_camera_contract_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is making the first-run/settings copy
  explicit that common fuel receipts work with the base local reader while
  bigger category intelligence can be downloaded later.

### Receipt Camera Reopen Pass 899: Fuel-First Settings Copy

Status: complete.

What changed:
- Updated parser-pack summary copy to say fuel receipt essentials stay
  local-first in the base reader.
- Locked that language through both policy and settings-store tests so the
  low-storage setup does not imply users need optional downloads just to scan
  common fuel receipts.
- Kept the heavier category language scoped to optional general line-item help
  and optional materials/inventory packs.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart test/receipt_assistance_policy_test.dart test/receipt_capture_settings_store_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart test/receipt_assistance_policy_test.dart test/receipt_capture_settings_store_test.dart`
- `flutter test test/receipt_assistance_policy_test.dart test/receipt_capture_settings_store_test.dart -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart test/receipt_assistance_policy_test.dart test/receipt_capture_settings_store_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is making low-storage storage warnings
  more actionable in the receipt settings flow while keeping raw device details
  hidden.

### Receipt Camera Reopen Pass 900: Actionable Low-Storage Copy

Status: complete.

What changed:
- Rewrote low-storage receipt-brain warnings so they tell the user what still
  works instead of only warning about storage.
- Critical storage now emphasizes that receipt capture, fuel receipts, and
  basic local reading stay available first while bigger offline parser packs
  stay hidden until the user has room and chooses them.
- Low storage now explicitly says fuel receipts still use the base reader,
  whether or not a small optional line-item add-on is available.
- Kept raw device details out of the user-facing settings copy.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart test/receipt_assistance_policy_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart test/receipt_assistance_policy_test.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart`
- `flutter test test/receipt_assistance_policy_test.dart -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart test/receipt_assistance_policy_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is one more focused validation over the
  fuel-first, low-storage, settings, and native camera diagnostic paths.

### Receipt Camera Reopen Pass 901: Fuel And Low-Storage Validation

Status: complete.

What changed:
- No product code changes in this pass. This was a focused validation checkpoint
  for the fuel-first, low-storage, settings, native camera diagnostic, and
  assisted review paths.
- Verified that fuel receipt essentials stay base-local, optional parser packs
  remain explicit, low-storage warning copy is actionable, and native camera
  diagnostics still carry the footprint/pack-routing state without content.

Validation:
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_store.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/receipt_assistance_policy_test.dart test/receipt_capture_settings_store_test.dart test/receipt_native_camera_contract_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/receipt_assistance_policy_test.dart test/receipt_capture_settings_store_test.dart test/receipt_native_camera_contract_test.dart test/expense_receipt_assisted_review_flow_test.dart -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_store.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/receipt_assistance_policy_test.dart test/receipt_capture_settings_store_test.dart test/receipt_native_camera_contract_test.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is receipt source-quality scoring and
  low-storage review behavior: make sure OCR/readability decisions prefer the
  clear original source, while saved proof compression remains separate.

### Receipt Camera Reopen Pass 902: OCR Source-First Summary

Status: complete.

What changed:
- Added explicit OCR source-first decision helpers to `ReceiptPhotoReviewResult`
  so downstream code no longer has to infer the policy from saved-proof and OCR
  source path lists.
- Added privacy-safe source-first metadata:
  - `ocrSourceFirstDecisionCode`
  - `ocrReadsClearSourceBeforeSavedProof`
  - `ocrUsesSavedProofOnlyAsFallback`
  - clear review cue/action wording
- Updated the receipt handoff metadata to use
  `ocr_reads_clear_source_before_saved_proof`, making the saved proof boundary
  clearer than the older generic backup wording.
- Kept fallback behavior explicit: OCR may use the saved proof only when a
  clearer prepared/original source is not available, and that path requires
  careful review.
- Updated capture/help-flow guard tests to track the controller-based optional
  parser-pack setting path and the new source-first metadata.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart -r compact`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_help_flow_test.dart -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_help_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is wiring the source-first summary into
  OCR diagnostics/failure diagnostics so failures can say whether OCR failed on
  a prepared source, original source, separate source, or saved-proof fallback.

### Receipt Camera Reopen Pass 903: OCR Source-First Failure Diagnostics

Status: complete.

What changed:
- Carried OCR source-first decision tokens from the accepted photo review result
  into the OCR attachment boundary for both shared receipt capture and expense
  receipt imports.
- Extended `ReceiptOcrSourceHandoffSummary` with privacy-safe source-first
  decision/outcome counts plus status fields in the OCR source handoff contract.
- Updated expense OCR failure diagnostics so failure evidence includes whether
  OCR was reading a prepared source, original/separate source, accepted source,
  or saved-proof fallback.
- Added tests for prepared-source and saved-proof fallback failures, without
  exposing merchant names, prices, or receipt text in diagnostics.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/data/expense_ocr_failure_diagnostics.dart test/expense_ocr_failure_diagnostics_test.dart test/receipt_ocr_service_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_ocr_failure_diagnostics.dart lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/screens/expenses/data/expense_ocr_failure_diagnostics.dart test/receipt_ocr_service_test.dart test/expense_ocr_failure_diagnostics_test.dart`
- `flutter test test/expense_ocr_failure_diagnostics_test.dart -r compact`
- `flutter test test/receipt_ocr_service_test.dart test/expense_ocr_failure_diagnostics_test.dart -r compact`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is tightening the low-storage/local-pack
  size boundary: base receipt camera/OCR stays lean, while heavy regional parser
  packs remain optional or cloud-assisted instead of bloating every install.
