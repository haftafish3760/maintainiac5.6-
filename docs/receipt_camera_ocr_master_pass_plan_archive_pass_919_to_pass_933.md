# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 919: Lean Local OCR Readiness Handoff

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 919: Lean Local OCR Readiness Handoff

Status: complete.

What changed:
- Added lean-local OCR readiness status, counts, and user-facing labels to the
  OCR parser handoff so the app can distinguish no text, proof-field review,
  totals-ready, line-review-needed, and full line-item-ready receipts.
- Carried that readiness contract into expense receipt parse diagnostics, with
  convenience helpers for totals-ready and line-review states.
- Added parser-depth-aware policy so older/lean devices can still keep store,
  date, tax, and total proof locally while deferring detailed line parsing,
  even when OCR evidence can see a possible item line.
- Kept the OCR handoff evidence and the expense parser policy separate: the
  OCR layer may report line evidence, while the parser layer decides whether
  the current device/session should use that evidence for detailed local
  review.
- Strengthened tests for high-capacity and older-phone receipt parsing so the
  app does not overclaim detailed local parsing on constrained devices.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/data/expense_receipt_parse_models.dart test/expense_receipt_parser_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/data/expense_receipt_parse_models.dart test/expense_receipt_parser_test.dart`
- `flutter test test/expense_receipt_parser_test.dart -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/data/expense_receipt_parse_models.dart test/expense_receipt_parser_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is app-size control for local OCR/parser
  intelligence: document and enforce the core-camera/basic-OCR baseline versus
  optional offline parser packs and explicit cloud assist so low-storage phones
  are not forced to carry heavyweight receipt intelligence.

### Receipt Camera Reopen Pass 920: Required Base Size Guardrails

Status: complete.

What changed:
- Tightened the receipt-brain footprint model so diagnostics explicitly list
  the required base receipt payload: native receipt camera, proof storage, basic
  local receipt reader, manual receipt entry, and data-saver proof copies.
- Added optional payload reporting for heavier offline parser packs and cloud
  fallback routes, keeping those separate from the required base install.
- Added guardrail booleans proving the base app can ship without the full
  offline receipt brain and that parser packs require an explicit user choice.
- Updated install-choice copy so every storage tier says the same product rule:
  base capture/basic reading is required; stronger receipt intelligence is
  optional and must not be silently bundled.
- Strengthened cramped-device and roomy-device tests so a low-storage phone
  keeps the lean base flow while a flagship can be offered full offline packs
  without making those packs mandatory.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart test/receipt_assistance_policy_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart test/receipt_assistance_policy_test.dart`
- `flutter test test/receipt_assistance_policy_test.dart -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart test/receipt_assistance_policy_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is making the capture/review result
  surface these base-vs-optional payload guardrails in the same privacy-safe
  summary that Command One can consume, so app-size and pack-routing health can
  be monitored without seeing receipt content.

### Receipt Camera Reopen Pass 921: Capture Result Payload Guardrail Summary

Status: complete.

What changed:
- Carried required-base payload counts into `ReceiptPhotoReviewResult`
  diagnostics so accepted receipt photos can report whether the base flow stayed
  limited to camera, proof storage, basic local reader, manual entry, and
  data-saver proof copies.
- Carried optional payload counts into the same result summary so heavier
  offline parser packs and cloud fallback routes stay visible as optional
  receipt brain work rather than required base-app weight.
- Added result-level counts for whether the base app can ship without the full
  offline receipt brain and whether optional parser packs require user choice.
- Added a `receiptBrainBasePayloadGuardrailOutcome` for Command One-ready
  health reporting without receipt text, merchant names, prices, or line items.
- Strengthened result tests so receipt reader handoff counts and privacy-safe
  metadata now prove required payloads, optional payloads, and pack-choice
  guardrails survive from accepted photo diagnostics into the receipt handoff.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart`
- `flutter test test/receipt_camera_result_test.dart -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is making the camera/import/review
  diagnostic producers attach the new payload guardrail fields by default, so
  every route reports app-size health consistently without each caller having
  to remember the keys manually.

### Receipt Camera Reopen Pass 922: Default Producer Footprint Guardrails

Status: complete.

What changed:
- Confirmed the receipt review save route and receipt attachment import route
  already attach `ReceiptBrainFootprintSummary.toPrivacySafeDiagnostics()` by
  default through their local receipt-brain diagnostic helpers.
- Strengthened source guards so both default producers must keep using
  `receiptBrainFootprintSummaryFor(...)` and spread the footprint diagnostics.
- This locks the Pass 920/921 payload fields into the normal receipt capture
  routes without adding receipt text, merchant names, prices, addresses, or
  line items to diagnostics.
- The result is that accepted photos, kept-for-later photos, backup phone
  camera photos, and existing-photo imports all inherit the same base-vs-
  optional app-size guardrail policy from one footprint source.

Validation:
- `dart format test/receipt_camera_capture_layout_test.dart`
- `flutter analyze test/receipt_camera_capture_layout_test.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart -r compact`
- `git diff --check -- test/receipt_camera_capture_layout_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is tightening user-facing receipt setup
  wording around low-storage versus full-offline choices so the app explains
  size tradeoffs plainly without scary device-detail language.

### Receipt Camera Reopen Pass 923: Plain Storage Choice Wording

Status: complete.

What changed:
- Reworded the default receipt capability summary so users see plain language:
  receipt capture, proof saving, and basic receipt reading work without any
  extra download.
- Clarified that stronger offline receipt help is optional, named by size, and
  downloads only after the user chooses it.
- Reframed critical/low storage copy around keeping the receipt camera,
  fuel/simple receipts, and basic OCR working first instead of exposing raw
  device details.
- Clarified that assisted reading is offered only when the user chooses it and
  internet is available.
- Clarified that saved proof copies can be smaller for phone/backup space while
  receipt reading still uses the clearest source first.
- Strengthened settings tests so the user-facing summary avoids raw
  device/manufacturer wording and keeps the low-storage/full-offline choice
  understandable.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_settings_store.dart test/receipt_capture_settings_store_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_settings_store.dart test/receipt_capture_settings_store_test.dart`
- `flutter test test/receipt_capture_settings_store_test.dart -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_capture_settings_store.dart test/receipt_capture_settings_store_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is local receipt parser routing for
  fuel/simple receipts versus optional detailed line-item/material parsing, so
  the app can prioritize common fuel and simple business receipts on low-storage
  phones before heavier catalog intelligence.

### Receipt Camera Reopen Pass 924: Local Parser Routing For Fuel And Simple Receipts

Status: complete.

What changed:
- Added local parser routing diagnostics to expense receipt parse diagnostics
  so the app can distinguish proof-totals-first, fuel/simple local, simple
  expense local, optional detail pack, standard local line review, and manual
  entry routes.
- Marked fuel/simple receipts as local-first so low-storage phones can keep
  common fuel and simple business receipts usable without forcing heavier parser
  packs.
- Marked proof-totals-only parsing as local proof-first rather than failed
  parsing.
- Marked material/detail parsing without catalog matching as optional-pack
  territory instead of pretending the base parser has full detail intelligence.
- Strengthened parser tests for fuel, proof-only, and material line-item modes.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parse_models.dart test/expense_receipt_parser_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_receipt_parse_models.dart test/expense_receipt_parser_test.dart`
- `flutter test test/expense_receipt_parser_test.dart -r compact`
- `git diff --check -- lib/screens/expenses/data/expense_receipt_parse_models.dart test/expense_receipt_parser_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is carrying these local parser routing
  codes into OCR/parser handoff metadata and privacy-safe telemetry so Command
  One can show how many receipts stayed local-first versus needed optional
  detail packs.

### Receipt Camera Reopen Pass 925: Local Parser Routing Telemetry

Status: complete.

What changed:
- Added privacy-safe parser-routing fields to receipt parser privacy events:
  local route code, route counts, local-first count, and optional-pack-offer
  count.
- Aggregated those fields in expense telemetry health snapshots so Command One
  can report how many receipts stayed fuel/simple local-first versus how many
  would benefit from optional detailed parser packs.
- Kept the telemetry payload content-free: no receipt text, vendor names,
  prices, addresses, customer data, or line descriptions.
- Strengthened tests for parser privacy events and Command One telemetry
  snapshots so local-first, optional-pack, and manual/fallback routes are all
  visible as counts.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_privacy_event.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/receipt_privacy_event_test.dart test/expense_screen_telemetry_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_receipt_privacy_event.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/receipt_privacy_event_test.dart test/expense_screen_telemetry_test.dart`
- `flutter test test/receipt_privacy_event_test.dart test/expense_screen_telemetry_test.dart -r compact`
- `git diff --check -- lib/screens/expenses/data/expense_receipt_privacy_event.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/receipt_privacy_event_test.dart test/expense_screen_telemetry_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is ensuring accepted capture/result
  handoff metadata preserves local parser routing and app-size guardrail signals
  from receipt capture into expense entry without forcing heavy local parser
  packs into the base install.

### Receipt Camera Reopen Pass 926: Base Install Size Decision Guardrails

Status: complete.

What changed:
- Added an explicit 50 MB review point for the required receipt camera/base
  reader payload and kept the existing 100 MB hard block for required installs.
- Added privacy-safe size-decision diagnostics:
  `receiptBrainBaseNeedsSizeReview`,
  `receiptBrainBaseBlocksLowStorageUsers`, and
  `receiptBrainBaseSizeDecisionCode`.
- Added a user-facing base-size decision label that explains whether the base
  receipt camera/reader is lean, needs review, or must move heavy OCR/parser
  work into optional packs.
- Strengthened footprint tests so lean low-storage setups stay shippable while
  oversized required camera/OCR bases are blocked before release.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart test/receipt_assistance_policy_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart test/receipt_assistance_policy_test.dart`
- `flutter test test/receipt_assistance_policy_test.dart -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart test/receipt_assistance_policy_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is carrying these base-size decision
  diagnostics into accepted capture/result handoff metadata so expense entry and
  Command One can see when the receipt stack is lean, reviewable, or blocked
  without exposing receipt content.

### Receipt Camera Reopen Pass 927: Accepted Capture Size Guardrail Handoff

Status: complete.

What changed:
- Carried the base install size decision code from receipt capture diagnostics
  into accepted receipt handoff counts.
- Added handoff counts for whether the receipt base needs size review and
  whether the base install would block low-storage users.
- Added privacy-safe handoff metadata for base-size decision counts, decision
  outcome, size-review counts, and low-storage-blocking counts.
- Strengthened the receipt result regression so accepted photos prove the lean
  base/optional-pack guardrail survives after the photo review result freezes.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart`
- `flutter test test/receipt_camera_result_test.dart -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is routing these accepted capture size
  guardrail fields into expense entry OCR metadata so the expense form and
  local telemetry can preserve the same base-vs-optional receipt brain decision.

### Receipt Camera Reopen Pass 928: Expense Entry Size Guardrail Continuity

Status: complete.

What changed:
- Confirmed expense entry already spreads accepted receipt handoff metadata from
  `ReceiptPhotoReviewResult` into OCR-start telemetry.
- Strengthened source guards so expense entry must keep spreading
  `result.privacySafeReceiptReaderHandoffMetadata`.
- Strengthened receipt model guards so the accepted-photo metadata contract must
  keep the base-size decision counts, decision outcome, size-review counts, and
  low-storage-blocking counts.
- This keeps the lean-base versus optional-heavy-parser decision visible from
  camera review into expense entry without adding receipt content or cloud work.

Validation:
- `dart format test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_help_flow_test.dart -r compact`
- `git diff --check -- test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_help_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is preserving the same size-decision and
  local/optional parser route signals through OCR result diagnostics and parser
  failure diagnostics, so local parser failures can say whether they were caused
  by photo quality, parser scope, or optional-pack limits.

### Receipt Camera Reopen Pass 929: Parser Failure Route Cause Separation

Status: complete.

What changed:
- Added a distinct parser review cause for receipts that are readable locally
  but need optional detailed parser packs for stronger category/material detail.
- Added local parser route evidence to parser failure diagnostics so failures
  can distinguish simple local routing, proof/totals-first routing, and optional
  detail-pack routing.
- Kept fuel/simple local receipts clean: staying local-first does not become a
  failure by itself.
- Strengthened parser failure tests for OCR handoff review, optional-pack
  review, and clean fuel/simple local parsing.

Validation:
- `dart format lib/screens/expenses/data/expense_parser_failure_diagnostics.dart test/expense_parser_failure_diagnostics_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_parser_failure_diagnostics.dart test/expense_parser_failure_diagnostics_test.dart`
- `flutter test test/expense_parser_failure_diagnostics_test.dart -r compact`
- `git diff --check -- lib/screens/expenses/data/expense_parser_failure_diagnostics.dart test/expense_parser_failure_diagnostics_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is carrying local parser route cause
  counts into the local privacy-event store health snapshot, so Command One can
  separate photo/OCR failures from parser-scope and optional-pack review causes
  without receipt content.

### Receipt Camera Reopen Pass 930: Local Parser Route Health Snapshot

Status: complete.

What changed:
- Aggregated local receipt parser routing counts in the privacy-safe receipt
  health snapshot.
- Added local-first and optional-pack-offer totals so Command One can separate
  receipts handled by the lean local parser from receipts that need optional
  detail packs.
- Allowed only privacy-safe route/count keys through the receipt event sanitizer;
  receipt text, vendor names, item names, addresses, and prices remain excluded.
- Strengthened privacy-event store tests for simple local routing, optional
  detail-pack routing, and command-center map handoff.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_privacy_event_store.dart test/receipt_privacy_event_store_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_receipt_privacy_event_store.dart test/receipt_privacy_event_store_test.dart`
- `flutter test test/receipt_privacy_event_store_test.dart -r compact`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is adding route-aware summary labels and
  action labels to local parser diagnostics so UI/help can explain "stays
  local," "proof totals first," or "optional pack improves details" without
  confusing users or implying the base app must download every parser pack.

### Receipt Camera Reopen Pass 931: Parser Route Labels For Review Handoff

Status: complete.

What changed:
- Added concise local parser route summary labels for proof/totals-first, fuel
  local, simple local, standard local line review, optional detail-pack, and
  manual routes.
- Added route-specific user action labels so accepted receipt handoff panels can
  say what the user should do next without exposing parser-code language.
- Wired parsed receipt handoff actions to the parser route action label instead
  of the old generic filled-review copy.
- Appended the route summary to the receipt details route result so the handoff
  can distinguish "fuel stayed local" from "optional detail pack can improve
  categories."
- Strengthened parser and assisted-flow tests so local/optional parser routing
  remains a reusable model contract, not scattered UI copy.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart -r compact`
- `flutter test test/expense_receipt_parser_test.dart -r compact`
- `flutter analyze lib/screens/expenses/data/expense_receipt_parser.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `git diff --check -- lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is enforcing the lean base versus
  optional pack architecture in the capture/settings copy and diagnostics: base
  capture and simple local OCR must remain usable on low-storage phones, while
  detailed parser packs stay optional and measurable.

### Receipt Camera Reopen Pass 932: Base Versus Full Offline Receipt Size Copy

Status: complete.

What changed:
- Added a policy-level base-versus-full-offline receipt summary that explains
  the first install only needs camera, proof storage, data saver copies, manual
  entry, and basic local reading.
- Added the same summary to privacy-safe receipt brain diagnostics so Command
  One can show the required-base versus optional-pack split without receipt
  content or raw device details.
- Surfaced the summary in receipt settings next to data saver and parser-pack
  routing notes.
- Strengthened settings and policy tests so low-storage phones keep receipt
  capture unblocked and high-capacity phones can still choose full offline
  intelligence later.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart test/receipt_capture_settings_store_test.dart test/receipt_assistance_policy_test.dart`
- `flutter test test/receipt_capture_settings_store_test.dart test/receipt_assistance_policy_test.dart -r compact`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart test/receipt_capture_settings_store_test.dart test/receipt_assistance_policy_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart test/receipt_capture_settings_store_test.dart test/receipt_assistance_policy_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is carrying the base-versus-full-offline
  summary into accepted receipt capture diagnostics and health counters so the
  app can measure whether low-storage users are staying on the lean path.

### Receipt Camera Reopen Pass 933: Base-Vs-Full-Offline Capture Handoff

Status: complete.

What changed:
- Allowed the base-versus-full-offline receipt summary through native capture
  diagnostics so the camera path can prove whether a receipt stayed on the lean
  base install path.
- Added a compact present/missing count for that summary in accepted receipt
  handoff counts.
- Carried the same count into privacy-safe receipt reader/details metadata so
  health can show whether low-storage users are being kept on the base camera,
  proof, data saver, and basic local reader path instead of being forced into
  optional heavy offline packs.
- Strengthened native camera, receipt result, and assisted-flow source guards so
  the base-versus-full-offline signal survives native capture, photo review, and
  receipt-details handoff.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_native_camera_contract_test.dart test/receipt_camera_result_test.dart test/receipt_camera_help_flow_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_native_camera_contract_test.dart test/receipt_camera_result_test.dart test/receipt_camera_help_flow_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/receipt_native_camera_contract_test.dart -r compact`
- `flutter test test/receipt_camera_result_test.dart -r compact`
- `flutter test test/receipt_camera_help_flow_test.dart test/expense_receipt_assisted_review_flow_test.dart -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_native_camera_contract_test.dart test/receipt_camera_result_test.dart test/receipt_camera_help_flow_test.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is estimating and enforcing the actual
  base-camera footprint versus optional OCR/parser-pack footprint so the app can
  warn before receipt intelligence becomes too large for low-storage users.
