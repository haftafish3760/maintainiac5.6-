# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 904: Lean Base Vs Optional Parser Packs

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 904: Lean Base Vs Optional Parser Packs

Status: complete.

What changed:
- Tightened the footprint policy so `general_expense_lines_v1` is no longer
  treated as silently included in the required/full-local base install.
- Kept `core_receipt_text_v1` as the only included local receipt pack, with fuel
  and basic receipt reading protected in the base reader.
- Moved general line-item help and materials/inventory matching into explicit
  optional local downloads for full offline mode.
- Updated the expected full offline optional footprint from 100 MB to 124 MB
  while keeping the required base receipt budget at 40 MB.
- Preserved low-storage behavior: critical storage offers no optional local
  packs, low storage can expose only the small 24 MB line-item add-on, and roomy
  storage can be offered the full optional offline pack by choice.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart test/receipt_assistance_policy_test.dart`
- `flutter test test/receipt_assistance_policy_test.dart -r compact`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_store.dart test/receipt_assistance_policy_test.dart test/receipt_capture_settings_store_test.dart`
- `flutter test test/receipt_capture_settings_store_test.dart -r compact`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is adding stronger diagnostics around
  which local receipt parser packs were available, deferred, or intentionally
  not downloaded when a receipt parse needs review.

### Receipt Camera Reopen Pass 905: Parser Pack Review Cues

Status: complete.

What changed:
- Tightened the assisted receipt review storage cue so parser-pack help is no
  longer vague.
- When parser review says an optional parser pack may help, the review row now
  distinguishes:
  - optional packs deferred on this phone,
  - optional local add-ons available later with their size label,
  - cloud/assisted help available later only by explicit user choice.
- Kept the base promise visible: receipt capture, OCR review, and manual line
  review still work without downloading optional parser packs.
- Updated source guard tests so the review copy keeps exposing the size-aware
  parser-pack path.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart -r compact`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_store.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/receipt_assistance_policy_test.dart test/receipt_capture_settings_store_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/receipt_assistance_policy_test.dart test/receipt_capture_settings_store_test.dart test/expense_receipt_assisted_review_flow_test.dart -r compact`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is privacy-safe parser-pack telemetry
  counts so Command One can see how often receipt reviews needed optional local
  packs, deferred packs, or assist fallback without seeing receipt content.

### Receipt Camera Reopen Pass 906: Parser-Pack Pressure Telemetry

Status: complete.

What changed:
- Added privacy-safe parser-pack review action metadata at the expense parser
  telemetry boundary.
- Added parser-pack pressure buckets to the Command One health snapshot so admin
  diagnostics can show whether receipt review needed optional offline parser
  packs, storage-aware deferral, or later assisted help.
- Kept receipt content out of telemetry: only action/status tokens are stored,
  never merchant names, prices, raw OCR text, or line text.
- Updated telemetry schema expectations and Command One tests so this stays
  enforced.

Validation:
- `dart format lib/screens/expenses/data/expense_screen_telemetry.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/expense_screen_telemetry_test.dart test/helpers/expense_telemetry_schema_expectations.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/expense_screen_telemetry_test.dart test/helpers/expense_telemetry_schema_expectations.dart`
- `flutter test test/expense_screen_telemetry_test.dart -r compact`
- `git diff --check -- lib/screens/expenses/data/expense_screen_telemetry.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/expense_screen_telemetry_test.dart test/helpers/expense_telemetry_schema_expectations.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is tightening the low-storage package
  install UX/diagnostics so the app can clearly separate base receipt OCR,
  optional offline parser packs, and later cloud assist without bloating the
  first install.

### Receipt Camera Reopen Pass 907: Low-Storage Install Size UX

Status: complete.

What changed:
- Added a user-facing install choice summary for receipt camera/OCR footprint:
  base receipt capture/basic reading size, optional offline add-on size, and the
  full offline receipt setup size.
- Surfaced that summary in receipt photo settings so the app can explain the
  storage tradeoff before any optional receipt parser pack is downloaded.
- Tightened receipt-size formatting so whole MB values read as `40 MB` and
  `24 MB` instead of engineer-looking decimal labels.
- Added controller tests for critical, low, and comfortable storage paths so the
  base stays lean and optional packs stay explicit.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart test/receipt_capture_settings_store_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_store.dart test/receipt_capture_settings_store_test.dart`
- `flutter test test/receipt_capture_settings_store_test.dart -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart test/receipt_capture_settings_store_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is reinforcing the receipt capture path
  so native capture/source decisions, optional pack choices, and OCR handoff all
  stay modular and reusable by expenses, materials, and later maintenance
  without dragging inventory data into the base receipt camera.

### Receipt Camera Reopen Pass 908: Native Bridge Pack-Boundary Contract

Status: complete.

What changed:
- Carried the new receipt install-size summary through the native camera bridge
  and returned capture diagnostics.
- Expanded staged native capture diagnostics so receipt-brain footprint fields
  are preserved by the sanitizer instead of being dropped before review.
- Reinforced the custom native receipt camera boundary: Maintainiac owns the
  preview/controls, stock phone camera UI remains fallback-only, and optional
  parser packs stay explicit.
- Updated native camera contract tests for the current optional-pack policy:
  comfortable storage may offer optional receipt packs, but the base install
  remains separate and lean.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_native_camera_contract_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart test/receipt_native_camera_contract_test.dart`
- `flutter test test/receipt_native_camera_contract_test.dart -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_native_camera_contract_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is strengthening the capture-to-review
  recovery path so accepted receipt photos and OCR-source originals cannot be
  lost or hidden behind confusing controls when the user backs out, retakes, or
  adds another long-receipt section.

### Receipt Camera Reopen Pass 909: Long-Receipt Add-Photo Copy Tightening

Status: complete.

What changed:
- Tightened single-photo review guidance from “use Add Another Photo if the
  receipt continues” to “Use Add Another Photo only if the receipt continues.”
- Updated supporting receipt review model copy so readable single-shot receipts
  send the user to Next instead of implying extra photos are expected.
- Kept long-receipt support intact: Add Another Photo remains available for
  continued receipts, blurry/missing sections, and OCR review issues.
- Updated layout/source guard tests so the review copy stays explicit about the
  next screen and avoids unnecessary extra-photo pressure.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_capture_layout_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is tightening the post-capture close/back
  wording and recovery diagnostics so users can leave review without losing
  captured photos and without mistaking “Save for later” for “finish the
  app-assisted receipt.”

### Receipt Camera Reopen Pass 910: Save-Without-Filling Exit Clarity

Status: complete.

What changed:
- Renamed the receipt review exit prompt from “Use this receipt photo before
  leaving?” to “Review receipt details from this photo?” so the user sees the
  actual decision.
- Changed the non-filling exit action from “Save Photo(s) For Later” to “Save
  Photo(s) Without Filling,” making it clear that the expense form will not be
  filled until the user resumes review and taps Next.
- Kept local recovery behavior intact: captured photos remain recoverable, and
  generated review work is closed safely without silent discard.
- Updated layout guard tests so this copy cannot drift back to confusing
  save/finish wording.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is strengthening parser-facing photo
  handoff diagnostics so the receipt details screen can distinguish accepted,
  saved-without-filling, stitched, fallback, and source-first OCR paths without
  leaking receipt content.

### Receipt Camera Reopen Pass 911: Parser-Facing Photo Handoff Diagnostics

Status: complete.

What changed:
- Added a privacy-safe `receiptPhotoReviewHandoffPath` and label to accepted
  receipt photo results so downstream receipt details can tell exactly which
  path happened without reading receipt content.
- Covered the major receipt-photo handoff cases: saved without filling,
  accepted with missing OCR source, saved-proof OCR fallback, stitched combined
  long receipt, ordered-section stitch fallback, ordered sections, prepared
  single source, and normal single photo.
- Added the new handoff path fields to the privacy-safe receipt reader metadata
  for diagnostics, Command One health summaries, and future parser routing.
- Updated receipt result tests for accepted/prepared, saved-without-filling,
  saved-proof fallback, stitched, fallback, and native settings-control health
  signals.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart`
- `flutter test test/receipt_camera_result_test.dart -r compact`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is keeping the base install lean while
  documenting and enforcing optional local/cloud receipt capability packs, so
  older phones and low-storage users are not forced to carry the full offline
  receipt brain.

### Receipt Camera Reopen Pass 912: Required Base Size Guardrail

Status: complete.

What changed:
- Added a release-action code for receipt brain footprint decisions so the app
  can distinguish a shippable lean base from an oversized required camera/OCR
  install that must be moved into optional packs.
- Added install distribution mode codes for critical, low, comfortable, roomy,
  and unknown storage devices, with an explicit
  `required_base_blocked_until_optionalized` outcome when required receipt work
  crosses the 100 MB guardrail.
- Added a plain-language required-base guardrail summary: base receipt capture
  stays under the guardrail, extra offline receipt brain downloads are optional,
  and oversized required payloads cannot ship until heavy work is moved out of
  the first install.
- Updated assistance policy tests and added an oversized-base regression case
  proving a 132 MB required receipt base is blocked rather than treated as a
  normal low-storage optional add-on.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart test/receipt_assistance_policy_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart test/receipt_assistance_policy_test.dart`
- `flutter test test/receipt_assistance_policy_test.dart -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart test/receipt_assistance_policy_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is surfacing the base/optional-pack
  decision through receipt diagnostics and native capture metadata so Command
  One and the receipt flow can explain storage pressure without exposing receipt
  content.

### Receipt Camera Reopen Pass 913: Native Guardrail Diagnostic Handoff

Status: complete.

What changed:
- Allowed the new receipt-brain release-action and install-distribution fields
  through the native capture staging sanitizer.
- Preserved the required-base guardrail summary in native capture diagnostics so
  storage pressure and optional-pack decisions can be reported without receipt
  text, store names, prices, or private user content.
- Strengthened native camera contract tests so low-storage native sessions prove
  the guardrail fields are sent through the channel and returned in capture
  diagnostics.
- Kept this pass camera/OCR-scoped: no Firebase writes, no PDF work, and no
  inventory parsing changes.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_native_camera_contract_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_native_camera_contract_test.dart`
- `flutter test test/receipt_native_camera_contract_test.dart -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_native_camera_contract_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is feeding the same base/optional-pack
  diagnostics into receipt review/result summaries so accepted photo diagnostics
  can explain whether the device used lean local OCR, optional pack deferral, or
  stronger local receipt help.

### Receipt Camera Reopen Pass 914: Receipt Review Brain-Mode Summary

Status: complete.

What changed:
- Added accepted-photo review counters for receipt-brain release action,
  install distribution mode, storage class, and local OCR mode.
- Added preferred outcome helpers so the receipt result can summarize whether
  the required base is blocked, lean/deferred, explicit optional download, or
  full offline optional without inspecting raw diagnostics.
- Added the same receipt-brain summaries to privacy-safe receipt reader handoff
  metadata for downstream receipt details, diagnostics, and Command One health.
- Updated receipt result tests so an accepted photo proves those storage/pack
  decisions flow into receipt-reader counts and metadata without receipt
  content.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart`
- `flutter test test/receipt_camera_result_test.dart -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is adding a small user-facing capability
  summary for the receipt review/settings flow so low-storage users understand
  that capture and basic local OCR still work while heavier receipt packs remain
  optional.

### Receipt Camera Reopen Pass 915: Plain-Language Capability Summary

Status: complete.

What changed:
- Added `defaultDataSaverReceiptCapabilitySummary` to the receipt settings
  controller so the settings UI can explain the storage tradeoff in normal user
  language.
- The summary now says receipt capture and basic local reading stay in the base
  app, stronger offline receipt help is optional, low-storage phones still keep
  basic OCR/fuel receipt support, cloud assist is explicit when available, and
  OCR reads the clearest source before smaller saved proof copies.
- Replaced two more technical settings notes with the single capability summary
  while keeping the install-choice, category-pack, and storage-warning notes.
- Added settings store coverage for critical, low, and balanced storage modes.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_settings_store.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart test/receipt_capture_settings_store_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_settings_store.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart test/receipt_capture_settings_store_test.dart`
- `flutter test test/receipt_capture_settings_store_test.dart -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_capture_settings_store.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart test/receipt_capture_settings_store_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is tightening capture/review source
  diagnostics so native captures, recovered captures, and imported photos all
  report the same base/optional receipt-brain mode without exposing content.

### Receipt Camera Reopen Pass 916: OCR Attachment Receipt-Brain Mode Signals

Status: complete.

What changed:
- Added receipt-brain mode document signals and risk flags to OCR source
  attachments created by both the shared capture flow and the import/review
  flow.
- The attachment handoff now reports release action, install distribution,
  storage class, and local OCR mode using privacy-safe tokens instead of receipt
  text, merchant names, prices, or line details.
- Low-storage and lean-local paths now surface diagnostic risk flags such as
  optional packs deferred, critical storage, and lean local OCR so Command One
  can explain whether the base app stayed small or a heavier receipt pack is
  needed later.
- Strengthened recovered multi-photo OCR attachment tests to prove native
  recovery, edited-photo review, stitching, and receipt-brain storage mode all
  survive the same handoff.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_result_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_result_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter test test/receipt_camera_result_test.dart -r compact`
- `flutter test test/receipt_camera_help_flow_test.dart -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_result_test.dart test/receipt_camera_help_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is keeping the base receipt app lean by
  auditing imported/manual photo defaults and making sure every capture route
  has a clear local-basic, optional-pack, or cloud-assist diagnostic mode before
  any heavier OCR/parser package is allowed into the base download.

### Receipt Camera Reopen Pass 917: Review Default Local Receipt-Brain Diagnostics

Status: complete.

What changed:
- Added a default receipt-brain diagnostic profile at the receipt photo review
  save layer for routes that do not already carry native camera diagnostics.
- Accepted review photos now merge the current device/data-saver receipt-brain
  recommendation and footprint summary before coverage diagnostics, while
  preserving any stronger native capture fields that already exist.
- Save-without-filling / kept-for-later photos now keep the same base-local,
  optional-pack, storage-class, and local OCR mode diagnostics instead of
  becoming unknown just because OCR was deferred.
- The default profile remains local-only and privacy-safe: it records route,
  storage class, local OCR mode, required-base action, install distribution, and
  budget guardrail status, not receipt text, store names, prices, or item lines.
- Strengthened tests so kept-for-later review photos prove lean-local OCR and
  optional-pack deferral counts survive the handoff, and the review screen keeps
  the default receipt-brain policy helper wired in.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_result_test.dart -r compact`
- `flutter test test/receipt_camera_capture_layout_test.dart -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is making the import panel's immediate
  diagnostic event for phone-camera backup and existing-photo imports report
  the same local/base receipt-brain mode so diagnostics are consistent before
  and after review acceptance.

### Receipt Camera Reopen Pass 918: Import Panel Local Receipt-Brain Diagnostics

Status: complete.

What changed:
- Added the same default local receipt-brain diagnostic profile to the receipt
  attachment import panel's immediate capture diagnostic events.
- Phone-camera backup photos now enter review with per-photo diagnostics that
  identify the fallback route, primary Maintainiac native camera intent, backup
  role, and local/base receipt-brain mode.
- Existing photo imports now enter review with per-photo diagnostics that mark
  the route as user-selected receipt photo import and carry the same local OCR,
  storage class, optional pack, and base-size guardrail metadata.
- The import-panel metadata remains local-only and privacy-safe. It reports
  route, mode, storage class, size guardrail, and local OCR mode without receipt
  text, merchant names, prices, addresses, or line items.
- Strengthened layout/source guards so the import flow keeps the default
  receipt-brain diagnostic helper, existing-photo import route, and phone-camera
  backup route wired in.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_capture_layout_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is the local parser/OCR handoff for
  low-storage routes: make sure lean local OCR can report when it has enough
  vendor/date/total evidence for a simple receipt and when line-item parsing
  should be deferred or reviewed instead of silently overclaiming.
