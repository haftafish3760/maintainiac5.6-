# Receipt Camera OCR Master Pass Plan

This is the active index for Maintainiac receipt capture, OCR, parsing, review, and expense intelligence work.

The detailed historical pass log was split into archive files so the active plan stays under the 500-line project file limit. Keep new active planning here concise; move completed pass history into focused archive files instead of appending thousands of lines to this file.

## Active Planning Sections

This is the working execution plan for making Maintainiac's receipt capture, OCR, parsing, review, and expense intelligence state-of-the-art.

The plan is intentionally numbered. Every receipt-hardening pass should be reported as `Pass NN` after the state-of-art spec reset, so progress is easy to track and the work does not drift.

## Current Receipt Camera Roadmap Lock

Active roadmap source:
`/Users/rbbie/.codex/attachments/9f1b3106-a148-4132-981e-4f2e16404c97/goal-objective.md`.

Work must stay on the receipt camera/capture/review/stitch/OCR-source handoff
lane unless a documented camera dependency requires otherwise. PDF, inventory,
admin, maintenance, maps, invoices, and cloud sync are out of scope for this
camera pass stream.

Current phase order:

1. Roadmap and scope lock.
2. Receipt entry flow.
3. Camera viewer.
4. Post-photo review.
5. Long receipt capture.
6. Stitching handoff.
7. OCR source handoff.
8. Storage proof decision.
9. Milestone validation.

Current active phase: Phase 4, Post-photo review.

Phase 2 acceptance rules:

- Add Receipt opens a compact source chooser.
- Source choices stay Capture Photo, Upload Photos, Upload PDF/File, and
  Paste/Text.
- Capture Photo may ask exactly one first-use Receipt Assist question before
  opening the camera.
- Receipt Assist copy must describe app-assisted receipt filling, not raw OCR.
- Manual entry must remain available.
- Camera launch must not require compression, storage, parser pack, or data
  saver setup first.
- Storage proof decisions belong after capture/review/OCR-source work, not
  before the first photo.

QA cadence:

- Add targeted tests or source contracts as behavior lands.
- Fix failing targeted checks before adding dependent feature work.
- Run full gates only at roadmap milestones, not after tiny edits.
- Bundle related edits inside the current phase; use surgical passes only for
  blockers or narrow regressions.

## Native Camera Architecture Reset

The old phone-camera production path is no longer the target. Maintainiac must
own the receipt camera UI and talk to native camera frameworks underneath:

- Android: CameraX.
- iOS: AVFoundation.
- Flutter: bridge/UI/review layer only, not the production camera engine.
- Samsung/Apple camera apps: fallback/import path only.

The active native rebuild spec is `docs/receipt_native_camera_service_spec.md`.
The release-one camera architecture map is
`docs/receipt_camera_release_one_blueprint.md`.

## Download Size And Device Storage Rule

The receipt camera/OCR system must not assume every user has flagship storage
or compute headroom.

- Target a lean default install. Native camera controls and custom image
  cleanup should stay lightweight; avoid heavy scanner/OCR dependencies unless
  they prove a major quality gain.
- Device capability detection must classify low-storage and low-memory phones
  before enabling expensive camera/OCR behavior.
- Low-storage devices, including older phones such as Galaxy S9-class devices,
  must still have a usable receipt flow: native photo capture, local proof
  saving, basic OCR when available, manual entry fallback, and safe backup-size
  controls.
- Heavy OCR/document intelligence should be optional, deferred, cloud-assisted,
  or capability-gated where possible. Do not force a 100 MB scanner/OCR payload
  onto devices that cannot afford it.
- If cloud OCR or cloud parsing is offered for low-storage users, the app must
  explain that it needs internet access, may use cloud processing, and still
  must not expose private receipt content in Command One telemetry.
- OCR should always read the clearest available source first. Save-space proofs
  are for storage and backup, not the first OCR source.
- The finished camera/OCR stack should stay comfortably under the app's 400 MB
  ceiling; treat anything that pushes the camera/OCR feature over roughly 50 MB
  added size as a decision point requiring explicit review.

## Local Pack, Cloud OCR, And Accuracy Disclosure Rule

- Maintainiac should have a lean baseline receipt system that works immediately:
  capture proof, save locally, basic local OCR where available, manual review,
  and cloud/manual fallback.
- Heavy local OCR/parser/catalog intelligence may be offered as optional
  downloadable packs instead of forcing every user to carry the full payload.
- First-run expense setup must explain the tradeoff plainly: smaller app with
  cloud-assisted OCR/parser requires internet, while full local OCR/parser packs
  use more storage but work offline.
- Pack choices may be organized by category, vendor family, region/state, trade,
  or inventory/material catalog scope. Examples include fuel/store parsing packs,
  regional vendor packs, and materials/inventory trade packs.
- Each OCR/parser pack must expose an honest accuracy/confidence label by
  category or vendor group. If a pack is only expected to perform around 80%, say
  so. Do not imply 99% quality until regression data proves it.
- The target quality standard is aggressive: OCR text extraction should aim for
  95-99% on clean receipts and improve toward higher accuracy on damaged,
  smudged, thermal-darkened, folded, long, and mixed-layout receipts through
  capture guidance, image cleanup, local parser rules, optional cloud OCR, and
  pack updates.
- Cloud OCR/parser assist must be optional, internet-aware, and privacy-scoped.
  Raw receipt content can be processed only for the user's requested receipt
  work; Command One still receives only privacy-safe counts, statuses, and
  failure buckets.
- Download size is allowed to grow for premium/local power users when the user
  explicitly chooses the heavier local capability. The default install still
  needs to remain usable for older or low-storage devices.

## Multi-Receipt Job And Customer-Redaction Rule

- Jobs, estimates, invoices, inventory/materials, and expenses may reference
  multiple receipt proof images from multiple stores.
- Users must be able to create a customer-safe receipt view that redacts
  unrelated items, payment/card/auth details, loyalty/customer identifiers,
  addresses, phone numbers, private notes, and unrelated receipt lines while
  preserving the store/vendor name, allowed date, relevant line items, and totals
  needed for proof.
- Redaction must not destroy the original local proof. Keep the original proof
  separate from the customer-safe redacted copy.
- OCR/parser output must assign stable receipt line numbers per image/section and
  preserve receipt id, section number, and line number so detailed review,
  redaction, materials/inventory, job costing, estimates, and invoices can point
  to exact receipt lines.
- Price-only receipt mode may hide item descriptions and show only line numbers,
  prices, and business/personal/split decisions.
- Detailed receipt mode may show item text locally, but Command One telemetry
  must only receive status/count buckets and must never receive private receipt
  text.
- Multiple receipt sections and multiple receipts must stay ordered, with
  duplicate/overlap handling, missing-section risk, and customer-redaction status
  tracked as privacy-safe diagnostics.
- Regional/vendor parsing packs and optional cloud OCR/parser assists are
  allowed, but they must be optional, capability-aware, privacy-safe, and able to
  fall back to local/manual review.
- Estimates, active jobs, invoices, and inventory/material intake must be able to
  consume the same stable receipt-line references so a user can add selected
  items from one or many receipts without exposing unrelated receipt lines.
- Customer/client proof views must support automatic crop/redaction suggestions
  and manual adjustment before sharing. The original receipt proof remains local
  record evidence; the redacted proof is a separate share/export artifact.

## Progress Rule

- Always name the current pass as `Pass NN` after this update. Existing original pass headings may still say `of 40`, `of 55`, or `of 150` until they are touched, but new progress reporting should use the 300-pass cap.
- Keep each pass shippable: format, analyze, and run focused tests before calling it done.
- Bundle related changes inside each pass, but do not mix unrelated domains.
- UI passes come first so the product flow can be judged on the S24 Ultra before deeper parser work.
- Do not push a phone build after every tiny tweak.
- For UI work, push to the S24 Ultra after a meaningful batch of roughly 3-4 UI passes, or sooner only when the user asks for device review.
- Backend/parser-only passes do not require a phone install unless the change affects visible workflow.
- Continue through receipt passes automatically until the receipt camera/OCR/parser flow is complete or a real product/blocking decision is required.
- Do not take phone screenshots, inspect the device UI, or push device builds unless the user explicitly asks for that action.

## Benchmark Responsibilities

- **Adobe Scan lane:** image enhancement, cleanup, crop, perspective, shadow reduction.
- **Microsoft Lens lane:** camera experience, fast capture, edge controls, no clutter.
- **Expensify lane:** OCR/parser intelligence for merchant, date, tax, total, lines, expense creation.
- **Scanner Pro lane:** polish, animation, consistency, premium feel.
- **Genius Scan lane:** long receipts, multi-photo capture, batch order, stitching/fallback.
- **Google Drive Scanner lane:** simplicity, no fifty-button clutter, obvious path.
- **CamScanner lane:** document scanning engine ideas, filters, batch scanning, automatic document help.
- **Maintainiac lane:** business/personal/mixed, simple/detailed modes, split tax, local-first storage, profiles, vehicles, inventory, diagnostics, privacy.

## Future Maintenance Receipt Parser Note

- Do not start maintenance-category implementation until the receipt camera,
  OCR source selection, image cleanup, stitching/fallback, and expense receipt
  parsing flow are stable.
- When the camera/OCR receipt foundation is ready, add a maintenance receipt
  parser lane that uses the same receipt capture flow to extract privacy-safe
  maintenance setup hints from oil-change and repair receipts.
- Maintenance receipt parsing should look for service type, vehicle mileage,
  service date, next due mileage/date, engine oil type, oil weight, filter
  details, transmission fluid, coolant, tire rotation, brake work, and other
  maintenance interval evidence when present on the receipt.
- If a user uploads a maintenance-related receipt from expenses, ask whether
  Maintainiac should use it to help set up or update that vehicle's maintenance
  schedule. Include a "do not show again" choice for that prompt.
- The maintenance parser must be rule/parser based first, without requiring AI,
  and must never depend on storing private receipt images or raw receipt text in
  admin-visible telemetry.

## Future Expense Vehicle/Fleet Attribution Note

- Every saved expense must be attributable to the selected active vehicle when
  the expense belongs to a vehicle cost. The active vehicle row is the user's
  current working context, and the expense flow must preserve that context when
  adding, editing, reviewing, and saving receipts.
- The expense flow must still let the user choose a different vehicle for the
  expense before saving when the active vehicle row is not the right one. The
  saved expense should record the final selected vehicle context, not merely
  whatever happened to be active when the receipt camera opened.
- Single-person mode and multi-employee/fleet mode both need vehicle-aware
  expense records so fuel, repairs, supplies, materials, insurance, and other
  costs can roll up correctly by vehicle.
- Fleet mode will also need employee/profile attribution so account owners can
  review which employee recorded an expense, which vehicle it was tied to, and
  whether permissions allowed that action, without exposing private receipt
  content in admin telemetry.
- Inventory/materials work can proceed in parallel with another model as long
  as shared receipt capture, camera, OCR source selection, and app-assisted
  receipt parsing contracts are treated as shared infrastructure and not forked
  or rewritten independently.
- The inventory/materials parser may define material-specific parsing needs,
  aliases, SKU matching, and catalog handoff fields, but it should consume the
  shared receipt result object instead of creating a separate photo capture,
  stitching, OCR, or saved-proof pipeline.

## Current Status

Detailed historical status was archived to keep this active plan readable and under the 500-line limit.

- Current readiness ruler: `docs/receipt_camera_world_class_readiness.md`.
- Historical status archive: `docs/receipt_camera_ocr_master_pass_plan_archive_current_status.md`.

## Historical Pass Archives

- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_225_to_pass_239.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_240_to_pass_221.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_220_to_pass_206.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_205_to_pass_190.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_189_to_pass_173.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_172_to_pass_157.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_156_to_pass_142.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_141_to_pass_125.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_124_to_pass_108.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_107_to_pass_004.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_005_to_pass_025.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_026_to_pass_046.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_047_to_pass_067.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_021_to_pass_070.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_071_to_pass_085.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_086_to_pass_102.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_103_to_pass_122.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_123_to_pass_255.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_256_to_pass_271.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_272_to_pass_289.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_290_to_pass_306.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_307_to_pass_321.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_322_to_pass_336.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_337_to_pass_352.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_353_to_pass_871.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_872_to_pass_372.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_373_to_pass_870.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_857_to_pass_853.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_846_to_pass_833.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_834_to_pass_815.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_816_to_pass_804.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_805_to_pass_789.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_788_to_pass_769.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_770_to_pass_759.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_760_to_pass_739.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_738_to_pass_720.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_721_to_pass_700.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_701_to_pass_692.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_693_to_pass_683.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_684_to_pass_653.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_654_to_pass_638.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_639_to_pass_586.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_587_to_pass_628.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_627_to_pass_608.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_607_to_pass_569.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_570_to_pass_564.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_554_to_pass_545.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_546_to_pass_507.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_508_to_pass_421.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_422_to_pass_414.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_483_to_pass_371.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_367_to_pass_530.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_531_to_pass_887.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_888_to_pass_903.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_904_to_pass_918.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_919_to_pass_933.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_934_to_pass_948.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_949_to_pass_964.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_965_to_pass_982.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_983_to_pass_997.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_998_to_pass_1013.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_1014_to_pass_1028.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_1029_to_pass_1044.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_1045_to_pass_1058.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_1059_to_pass_1074.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_1075_to_pass_1088.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_1089_to_pass_1102.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_1103_to_pass_1118.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_1119_to_pass_1132.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_1133_to_pass_1146.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_1147_to_pass_1159.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_1160_to_pass_1172.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_1173_to_pass_1184.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_1185_to_pass_1197.md`
- `docs/receipt_camera_ocr_master_pass_plan_archive_pass_1198_to_pass_1198.md`
