# Maintainiac Receipt Camera Roadmap

Scope:
Work only on the receipt camera/capture/review/stitch/OCR-source handoff lane.
Do not touch PDF, inventory, admin, maintenance, maps, invoices, cloud sync, or
unrelated modules unless a documented receipt-camera dependency requires it.

Current phase:
- Active roadmap focus: the system-managed capture through long-receipt review
  flow in Phases 2-6.
- Capture uses the phone's normal rear-camera experience; Maintainiac owns the
  receipt-specific chooser, review, overlap guidance, stitch decision, and
  OCR handoff.
- Do not skip ahead to milestone closeout claims while the live flow still
  needs real-device proof.
- Current branch: `codex/long-receipt-hardening-20260714`

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
- In active progress. The compact chooser and first-use assist question are the
  current working lane, and this phase stays open until the Add Receipt path is
  clean enough to hand off directly into Phase 3 viewer work.

## Phase 3: System-managed camera capture

Goal:
Use the camera experience the person already knows without trying to replace
the phone's photography software.

Requirements:
- Launch the system rear-camera route for Capture, Add Another, and Retake.
- Return every accepted image to the same numbered Maintainiac review screen.
- Do not show invented live blur, glare, shadow, or focus claims.
- Do not build custom shutter, focus, exposure, torch, or tap-to-focus UI.
- Respect Android and iOS system camera permissions and cancellation behavior.

QA:
- Test the initial capture, Add Another, and Retake routes use the same system
  camera boundary.
- Test cancellation returns safely without freezing the receipt flow.
- Regression for no custom live-quality ticker or screen-tap focus behavior.

Status:
- Implemented in code. It remains open until real-device capture, cancel, and
  return-to-review behavior is proven on Android and iOS.

Flow:
- Show captured photo immediately.
- Show photo number.
- Actions: Retake, Add Another Photo, Continue.
- Add Another Photo opens a short previous-section overlap guide, then returns
  to the system camera.
- Retake replaces the current photo.
- Continue opens stitch review for multi-photo receipts and receipt details for
  a single accepted photo.
- The primary action labels must not claim the app knows which section is next.
- No "preparing receipt details" screen unless real processing is running.
- If processing is running, show a clear spinner or progress state.

QA:
- Test Retake, Add Photo, and Use Receipt actions exist and route correctly.
- Test back/cancel does not freeze the flow.
- Test no details or preparing screen appears without real captured input.

Status:
- Targeted gate is green. Remaining work is real-device proof that review,
  back/cancel, and captured-photo decisions behave correctly in the live app.

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
- Targeted gate is green. Remaining work is real-device proof for numbering,
  continuation context, and retake order under actual long-receipt capture.

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
- Targeted gate is green. Remaining work is fixture expansion plus real-device
  proof that the stitch/fallback handoff behaves safely in live flows.

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
- Targeted gate is green. Remaining work is app-flow proof and real-device
  confirmation that suggestion-only OCR handoff stays intact.

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
- Targeted gate is green. Remaining work is live app-flow proof that storage
  questions stay after capture/review and never break OCR-source handling.

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
- Active pass lane. Phase 2 receipt entry flow is the current bundle, followed
  immediately by Phase 3 camera viewer cleanup. Later targeted gates stay in
  place as guardrails, but they are not permission to skip the current roadmap
  order.

Status:
- Not complete.
