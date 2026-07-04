# Receipt Camera Release-One Blueprint

This is the active architecture map for Maintainiac's shared receipt camera
system. It narrows the current work to the camera and receipt-image flow needed
for release one. OCR, parsing, PDFs, inventory, maps, invoices, and cloud sync
must consume this system later instead of pulling the camera work off course.

## Release-One Target

The goal is an 80-90% solid release-one receipt camera system that can keep
improving through real receipt regressions. It does not need perfect scanner-app
polish before the expense system can move forward, but it must be dependable
enough that bad captures, ordering mistakes, lost OCR sources, and obvious
review bugs are not normal user experiences.

Release one must prove:

- A user can capture a clear single receipt photo.
- A user can capture a long receipt through ordered multiple segments.
- A user can retake any segment without losing its intended order.
- The app keeps temporary full-quality capture sources available through OCR
  prep, then saves the compressed proof by default.
- Full original-quality proof retention is explicit user choice, not the
  default storage behavior.
- Derived crop, stitch, OCR-ready, thumbnail, and compressed images never
  silently replace the OCR source before handoff.
- The app can warn about blur, glare, low light, crop/edge risk, missing bottom,
  and weak overlap without blocking manual capture.
- OCR receives the clearest available image or ordered segment set, but OCR
  results remain suggestions until the user confirms them.

## Scope Boundaries

### In Scope Now

- Shared receipt camera entry that can be launched from expenses, maintenance,
  inventory/materials, and future receipt-using flows.
- Native Android camera path through CameraX.
- Native iOS camera path through AVFoundation.
- Flutter orchestration, review, settings, and handoff UI.
- Single-photo receipt capture.
- Multi-photo long receipt capture.
- Segment thumbnails, ordering, retake, and review.
- Ghost/overlap guidance for continuation capture.
- Clear-photo quality scoring contracts.
- Edge, blur, glare, low-light, cropped-edge, and bottom-coverage diagnostics.
- Stitching/overlap handling good enough for receipt readability and OCR handoff.
- Source preservation and derived-artifact tracking.
- Camera-specific QA, fixture, and regression infrastructure.

### Out Of Scope Until Camera Is Stable

- Trying to outperform Google ML Kit or Google Cloud Vision OCR.
- Full expense parser perfection.
- Inventory parser expansion.
- Invoice generation.
- PDF export polish.
- Hosted sync implementation.
- Admin app dashboards beyond privacy-safe failure contract notes.

## Architecture Lanes

### Native Camera Engine

Android owns camera frames through CameraX. iOS owns camera frames through
AVFoundation. Native code should expose the same high-level contract to Flutter:
start session, update settings, provide live quality signals, capture segment,
recover session, and close session.

Native code should not own expense parsing, business/personal classification, or
record saving. It should only capture image evidence and return camera metadata.

### Flutter Capture Orchestrator

Flutter owns the user-visible receipt flow:

1. Start a `ReceiptCaptureSession`.
2. Show the capture surface and controls.
3. Receive live camera signals.
4. Capture a segment.
5. Show review actions: Retake, Add Photo, Done/Use Receipt.
6. Keep ordered segment metadata.
7. Build the final receipt handoff only after the user chooses Done/Use Receipt.

### Review And Segment State

Every segment needs stable metadata:

- session id
- segment id
- zero-based segment index
- source image path
- timestamp
- retake generation
- previous/next alignment context when available
- blur score
- glare score
- low-light score
- edge/crop status
- rotation/deskew status
- overlap estimate
- user acceptance status

Retaking a middle segment replaces the segment content but preserves the segment
index. The review UI must make it obvious which segment is being retaken.

### Long Receipt Guidance

Continuation mode should show the bottom 15-20% of the previous segment as a
semi-transparent guide near the top of the camera view. When replacing a middle
segment, the UI should prefer previous and next context where practical:

- previous segment bottom overlay for where the retake should begin
- next segment top cue for where the retake should end
- clear text only when needed, not developer-style warnings

Manual capture always remains available.

### Image Processing

The image-processing lane prepares derived artifacts:

- edge detection
- crop candidate
- perspective correction
- rotation correction
- OCR-ready image
- stitched long receipt image when safe
- fallback ordered segment handoff when stitching is not safe
- compressed display/proof copies after review

The temporary OCR source image is kept through OCR/prep, then the retained proof
follows user storage settings.

### Quality Scoring

Quality scoring should guide the user without pretending to be perfect:

- blur and focus confidence
- brightness and low-light risk
- glare or hot-spot risk
- crop/edge confidence
- bottom-of-receipt confidence
- overlap confidence for long receipts
- device capability tier
- memory and storage safety

Optional auto-capture can be added only as an opt-in setting. It should require a
stable good-quality signal for a short window, then capture without blocking
manual shutter.

### OCR Handoff Contract

The camera system hands off evidence to OCR:

- temporary full-quality source segment references
- derived OCR-ready image or ordered fallback segments
- stitch confidence and overlap evidence
- quality warnings
- source preservation status
- user review status

The camera system does not treat OCR text as truth. OCR and parser output may
suggest merchant, totals, tax, line items, and receipt type, but user-confirmed
data wins.

## Pass Map

Use these lanes to keep each pass focused. A pass may touch more than one lane
only when the dependency is direct and documented.

### Lane A - Blueprint And Audit

- Make the architecture map current.
- Identify stale docs and old Flutter-camera assumptions.
- Record pass numbers and verification.
- Keep all active docs under 500 lines.

### Lane B - Capture Shell

- Stabilize shared camera entry points.
- Verify native Android/iOS service contracts.
- Confirm permission, unavailable-camera, and fallback states.
- Keep manual capture reliable.

### Lane C - Single Receipt Quality

- Improve live clarity guidance.
- Add blur, glare, low-light, edge, and crop contracts.
- Keep warnings helpful and non-blocking.
- Add regression tests for rejected/bad images.

### Lane D - Multi-Segment Flow

- Strengthen Add Photo continuation.
- Preserve segment ordering.
- Retake segment by index.
- Show review thumbnails and segment labels clearly.
- Recover session state after interruption.

### Lane E - Ghost And Overlap Guidance

- Show previous-segment bottom overlay.
- Support middle-segment replacement context.
- Track overlap estimates and missing-overlap warnings.
- Add tests for wrong overlay, missing overlay, and bad order.

### Lane F - Stitching And Derived Artifacts

- Stitch only when overlap evidence is good enough.
- Remove duplicate overlap conservatively.
- Fall back to ordered segments when stitching is risky.
- Preserve originals and record derived-artifact lineage.

### Lane G - Device And Storage Safety

- Use device capability tiers instead of model-specific assumptions.
- Scale live analysis on older or low-memory devices.
- Detect low storage before creating heavy derived artifacts.
- Keep local-first manual fallback available.

### Lane H - Real Receipt QA

- Add synthetic fixtures for camera failure families.
- Add real-receipt fixture format with redaction support.
- Turn every confirmed real receipt failure into a regression case.
- Track family-level protections, not only one-off examples.

## Milestones

### Milestone 1 - Trust The Foundation

Evidence needed:

- analyzer passes for touched camera files
- receipt doc size gate passes
- source audit passes
- shared camera source preservation tests pass
- native Android/iOS service contract tests pass

### Milestone 2 - Trust Single Capture

Evidence needed:

- manual capture path works
- review screen has Retake, Add Photo, Done/Use Receipt
- quality warnings are present and non-blocking
- source image survives every derived-image operation

### Milestone 3 - Trust Long Receipts

Evidence needed:

- Add Photo keeps ordered segments
- retake preserves index
- ghost overlay uses the correct prior segment
- middle retake has previous/next context where practical
- stitch succeeds when overlap is strong
- fallback ordered handoff is used when overlap is weak

### Milestone 4 - Trust Device Reality

Evidence needed:

- low-memory and low-storage paths have safe fallbacks
- Android and iOS native contracts expose matching data
- older-device capability tiers reduce heavy live work
- manual capture remains available when assistance is unavailable

### Milestone 5 - Ready For Expense Flow

Evidence needed:

- camera handoff includes original references, derived artifacts, quality
  warnings, stitch confidence, and review status
- OCR/parser contracts can validate camera output without owning camera truth
- regression suite covers known camera failure families
- full receipt camera quality gate passes at milestone handoff

## Pass Budget

The practical release-one target is about 1,500-2,500 additional focused camera
passes from the reset point, with roughly 2,000 as the planning anchor. This is
not a guarantee and not a hard cap. Stop earlier if the evidence proves release
readiness; continue longer if real receipt/device testing exposes important
failure families.

Budget by lane:

- Lane A blueprint/audit: 25-75 passes.
- Lane B capture shell: 200-350 passes.
- Lane C single receipt quality: 250-400 passes.
- Lane D multi-segment flow: 250-450 passes.
- Lane E ghost/overlap guidance: 200-350 passes.
- Lane F stitching/artifacts: 250-450 passes.
- Lane G device/storage safety: 150-300 passes.
- Lane H real receipt QA: 300-500 passes before release, then ongoing.

## Pass Discipline

- Name every active camera pass with its pass number and start/end time.
- Work one lane at a time unless a direct dependency requires a paired edit.
- Do not add features on a failing analyzer, QA runner, source audit, or quality
  gate.
- Run targeted checks during the pass and full gates only at milestones.
- Do not watch long-running tests; wait for final results and summarize only
  actionable output.
- Every confirmed bug gets a regression test before it is considered fixed.
- Every bug-family root cause should get a generalized regression where
  practical.

## Release-One Definition Of Done

The camera system is release-one ready only when:

- single capture is reliable
- long receipt capture is understandable
- retake and ordering are stable
- ghost/overlap guidance is correct enough to help
- stitching is conservative and source-preserving
- fallback ordered handoff works when stitching is unsafe
- clear-photo guidance catches common bad images
- manual capture still works
- temporary OCR sources survive until receipt reading/prep completes
- camera handoff is stable enough for expense OCR/parser review
- Android and iOS native paths share the same contract
- targeted camera QA, regression tests, source audit, doc gate, and milestone
  quality gate pass
