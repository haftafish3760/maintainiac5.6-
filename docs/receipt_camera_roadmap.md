# Maintainiac Receipt Camera Roadmap

Scope:
Work only on the receipt camera/capture/review/stitch/OCR-source handoff lane.
Do not touch PDF, inventory, admin, maintenance, maps, invoices, cloud sync, or
unrelated modules unless a documented receipt-camera dependency requires it.

Current phase:
- Active roadmap focus: Phase 6 through Phase 9 non-UI hardening and
  validation for stitch, OCR-source, storage-proof, and milestone gates.
- Phase 2 receipt entry flow and Phase 3 camera viewer contracts remain part of
  the roadmap, but they are not the active pass lane right now.
- Current branch: `codex/expense-camera`

Operating rules:
- Stick to this roadmap in order.
- Work one roadmap topic at a time.
- Bundle meaningful edits inside each topic instead of tiny pass churn.
- Small surgical passes are allowed only for blocking failures, regression
  ledger entries, or narrowly scoped bug fixes.
- Do targeted QA as each behavior lands.
- Do not run full quality gates after tiny edits.
- Do not monitor long-running tests line by line.
- If analyzer/tests/targeted checks fail, stop feature work and fix the failure
  first.
- Every confirmed bug gets a regression test or bug-ledger entry.
- Push only milestone commits, labeled with pass number, date/time, and clear
  purpose.

## Phase 1: Roadmap and scope lock

Goal:
Create and maintain the receipt camera punch list so the active lane stays
clear and does not drift into unrelated modules.

Deliverables:
- Active roadmap document or checklist.
- Current phase marked clearly.
- Out-of-scope modules named clearly.
- No duplicate handoff or roadmap confusion.

QA:
- Lightweight doc and scope check only.

Status:
- In progress. This document is the repo-backed roadmap anchor.

## Phase 2: Receipt entry flow

Goal:
Make Add Receipt start cleanly without a setup wall.

Flow:
- Add Receipt opens a simple source chooser.
- Choices: Capture Photo, Upload Photos, Upload PDF/File, Paste/Text.
- If Capture Photo is chosen, ask one quick Receipt Assist question if needed.
- Receipt Assist wording uses app-assisted fill language, not "OCR."
- Manual entry remains available.
- Camera opens immediately after the choice.

Do not:
- Ask compression or storage questions before capture.
- Show a giant setup screen.
- Block the user with too many choices before the first photo.

QA:
- Test chooser options.
- Test Receipt Assist opt-in and manual path.
- Test camera launch route does not require compression setup.

Status:
- Source contracts are in place. Resume only when the late non-UI validation
  lane stops finding handoff or gate gaps.

## Phase 3: Camera viewer

Goal:
Make the live camera view usable and familiar.

Requirements:
- Full-screen preview.
- Round shutter button centered near bottom.
- Gear icon for settings.
- Torch or light button.
- Back button.
- Respect Android and iOS safe areas.
- Done/Next appears only after at least one photo.
- No fake or random guidance cycling.
- No oversized black bars or blocking panels over the preview.
- No screen-tap focus behavior.
- Manual focus controls only if supported and only through explicit controls,
  never blind screen tapping.

QA:
- Layout and source tests for shutter, gear, torch, back, and safe area
  behavior.
- Regression for no fake cycling guidance.
- Regression for no tap-to-focus screen behavior.

Status:
- Not the active pass lane right now; current work is finishing late non-UI
  hardening and milestone validation before more viewer polish.

## Phase 4: Post-photo review

Goal:
After capture, the user sees what they captured and decides what to do.

Flow:
- Show captured photo immediately.
- Show photo number.
- Actions: Retake, Add Photo, Use Receipt.
- Add Photo returns to camera continuation mode.
- Retake replaces the current photo.
- Use Receipt proceeds to processing and handoff.
- No "preparing receipt details" screen unless real processing is running.
- If processing is running, show a clear spinner or progress state.

QA:
- Test Retake, Add Photo, and Use Receipt actions exist and route correctly.
- Test back/cancel does not freeze the flow.
- Test no details or preparing screen appears without real captured input.

Status:
- Not complete.

## Phase 5: Long receipt capture

Goal:
Make multi-photo receipts understandable and stable.

Requirements:
- Each segment is numbered automatically.
- Add Photo creates Photo 2, Photo 3, and so on.
- Continuation mode shows previous-segment context or a ghost strip where
  available.
- Retaking Photo X preserves index and order.
- Retaking a middle photo uses previous and next context where practical.
- Segment metadata stays attached to the correct photo.

QA:
- Test segment numbering.
- Test Add Photo ordering.
- Test retake middle segment preserves order.
- Test ghost and overlap context source is correct.

Status:
- In progress, not complete.

## Phase 6: Stitching handoff

Goal:
Create a derived stitched proof from ordered receipt segments.

Requirements:
- Stitch only after the user chooses Use Receipt.
- Preserve original capture inputs until OCR/source processing is complete.
- Produce a derived stitched or proof image.
- Remove duplicate overlap where practical.
- If stitching confidence is low, fail gracefully and let the user continue
  with segments or manual review.
- Never silently mutate confirmed source records.

QA:
- Synthetic long-receipt stitching tests.
- Overlap removal tests.
- Low-confidence graceful failure tests.
- Original/source preservation tests.

Status:
- In progress, not complete.

## Phase 7: OCR source handoff

Goal:
Give ML Kit the best available source and keep OCR as suggestions.

Requirements:
- ML Kit receives the best available OCR source.
- For single photo, use the best capture source.
- For long receipt, use stitched proof when valid; otherwise use ordered
  segments.
- OCR/parser output is suggestion data only.
- User-confirmed data is truth.
- OCR/parser must not silently overwrite confirmed user values.
- Preserve useful diagnostics without personal user information.

QA:
- OCR handoff source tests.
- Suggestion-vs-confirmed-truth tests.
- No silent overwrite regression.
- Diagnostics privacy tests.

Status:
- In progress, not complete.

## Phase 8: Storage proof decision

Goal:
Handle storage after capture/review/OCR-source work, not before.

Requirements:
- Default to compressed readable proof.
- User may later choose ask every receipt, high quality, maximum savings, or
  keep original.
- Do not force original photo storage.
- Do not ask storage or compression questions before the user captures the
  receipt.

QA:
- Test compression/storage choice happens after capture/review.
- Test default proof path does not destroy OCR source before handoff.

Status:
- In progress, not complete.

## Phase 9: Milestone validation

Goal:
Prove the completed camera lane is stable enough for real-device testing.

Checks:
- Targeted tests for touched behavior.
- Receipt camera QA script/gate.
- Regression ledger gate.
- Scope gate.
- Line-count audit.
- Full quality gate only at milestone, not after tiny edits.

Exit criteria:
- Receipt entry flow works.
- Camera viewer is usable.
- Post-photo review works.
- Long receipt segment order works.
- Stitching handoff exists and fails safely.
- OCR source handoff is suggestion-only.
- No PDF/inventory/admin drift.

Status:
- Not complete.
