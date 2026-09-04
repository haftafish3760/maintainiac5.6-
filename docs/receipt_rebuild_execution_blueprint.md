# Receipt-System Rebuild Execution Blueprint

**Status:** Active control document. No receipt rebuild pass may begin or close
without updating this document's pass ledger.

## 1. Purpose

Replace the unreliable long-receipt stitching and receipt-review subsystem
without losing the parts that protect a person's evidence: original capture,
OCR intake, local proof storage, draft/recovery, authenticated account backup,
and expense-save ownership. The rebuilt work remains on the integrated active
branch so any device build includes all Maintainiac work, not a receipt-only
variant.

## 2. Non-negotiable product rules

1. Originals are immutable session evidence. Derived crop, stitch, preview,
   thumbnail, OCR-ready, and compressed proof artifacts never replace them.
2. The user-approved section order is authoritative. Automation can suggest an
   order but cannot silently change it.
3. Geometry owns image placement. OCR can corroborate, veto, and help choose a
   seam inside a proven overlap; OCR cannot create a transform or extend a
   deletion beyond visual geometry.
4. Every long receipt ends in one of three honest states: an approved combined
   image, a clearly labelled review-required combined image, or ordered
   originals that remain usable for OCR and expense completion.
5. A failed automatic stitch never traps a person or discards their work. They
   can retake a targeted section, adjust the images themselves, or continue
   using ordered originals.
6. Saving uses the exact user-reviewed result. It does not rerun stitching,
   silently substitute a source, or change the user-approved order.
7. App-assisted OCR proposals are editable. They are never financial truth.
8. Device proof and cloud backup are separate. Local save must remain safe when
   backup is unavailable; opt-in backup must retain the user/account boundary.

## 3. What is preserved versus replaced

### Preserved contracts

- Native capture/import staging and original source ownership.
- OCR service and its input/output contract.
- Receipt-session, draft/recovery, expense-save, thumbnail, local-proof, and
  authenticated backup contracts, after each is re-verified.
- Data saver choices: Original plus four readable proof levels. OCR reads the
  original/full-quality working source, never the smaller retained proof.

### Replaced subsystem

- Current automatic stitch orchestration and all competing placement/seam
  ownership.
- Current long-receipt result/recovery UI and manual alignment workspace.
- Receipt-flow navigation state that couples crop, order, stitch, save-space,
  and exit decisions in one mutable screen state.
- Receipt-only QA/regression gates that prove source strings, manifests, or
  synthetic metadata rather than user-visible image behavior.

Legacy code is kept in Git history and is removed only after the replacement
has equivalent preservation/recovery coverage and stronger behavioral proof.

## 4. Rebuilt receipt flow

1. **Classify receipt**: business, personal, or split; category decision is
   explicit and persisted.
2. **Capture or import**: camera, device images, or supported document source;
   every input enters one receipt session.
3. **Review sections**: large pinch-zoomable image, thumbnails, add, replace,
   remove, arrange, crop/straighten, and targeted retake. Back is one known
   step and retains session state.
4. **Assemble**: automatic geometry attempt occurs only after the user starts
   it. The user sees an honest progress state.
5. **Inspect result**: full, zoomable stitched image with originals available.
   A person can accept the exact preview, reject it, retake, or enter manual
   assembly.
6. **Manual assembly**: a real canvas for each adjacent pair. Both sections can
   be selected and manipulated; the relative placement supports full vertical
   travel, horizontal travel, scale, rotation, crop/adjust entry, gap/no-
   overlap, reset, undo/redo, and rendered-preview apply/reject. Multi-section
   receipts retain completed pair decisions.
7. **Proof choice**: Original plus four readable compressed levels. The app
   must reject an unreadable compression target instead of chasing a byte size.
8. **Read and review**: OCR consumes original/full-quality sources; user edits
   receipt details, classifications, and splits before expense save.
9. **Save and backup**: save locally first, display a thumbnail from retained
   proof, and queue opted-in account backup without exposing content to another
   account.

## 5. Stitching architecture

For each adjacent user-ordered pair:

1. Decode and normalize orientation/document bounds into private working
   frames; retain source-to-frame transforms.
2. Generate bounded visual registration candidates from deterministic image
   search and native feature registration. Neither candidate source has
   automatic authority.
3. Score candidates once using visual continuity, two-dimensional support,
   transform limits, and source-quality guards.
4. Use positioned OCR only as independent corroboration/veto. Repeated receipt
   lines, including self-checkout repeats, are not overlap proof by themselves.
5. Select a seam inside the proven overlap, avoiding visible ink and never
   expanding physical removal using text bounds.
6. Render the result from the selected geometry. Persist source order,
   transform/seam decision, diagnostics, and preview identity together.
7. Produce a safe fallback when the evidence cannot prove a join.

Learning is a separate, privacy-safe ranking layer: user approval/rejection,
retakes, manual corrections, device/capture characteristics, and redacted
outcome codes may improve future candidates only with consent. It never alters
existing proof or silently accepts a risky join.

## 6. Pass protocol (anti-drift control)

A pass is the user's file-group work cycle: open a named, limited group;
complete its stated change; run the stated evidence; record the result; then
close that group before opening another. Pass numbers are sequential and never
reused. A failed check records a failed pass and creates the next corrective
pass; it is not relabelled as green.

Before each pass, record:

- pass number and file allowlist;
- requirement(s) being satisfied;
- explicit non-goals and preserved contracts;
- acceptance evidence.

At close, record:

- changed files;
- validation commands and outcome;
- device/real-image evidence status;
- remaining risk and the next pass number.

No pass may silently broaden to GPS, Jobs, trade modules, unrelated UI, or
cloud-account work. User-added work is appended as a new named pass unless it
replaces the active pass explicitly.

## 7. Evidence gates

Green means all applicable layers passed:

1. deterministic unit/model tests for result and session contracts;
2. pixel-level fixture tests with known source geometry, expected join/gap, and
   output/golden checks;
3. widget tests that operate actual controls and Navigator/Back behavior;
4. Android and iOS compile/static checks;
5. physical device interaction using real, consented or synthetic
   provenance-backed receipt images;
6. source-integrity and backup/account-boundary verification.

Tests that only search source text, validate a blank manifest, or fabricate
non-image bytes cannot be release evidence. They are retired or relabelled as
static policy checks.

## 8. Initial pass ledger

| Pass | File group | Objective | Close evidence | Status |
| --- | --- | --- | --- | --- |
| 0 | Git/worktree | Publish exact integrated snapshot; exclude rebuildable artifacts | commit `72918764`, remote push, Windows preflight | Complete |
| 1 | This blueprint and existing flow maps | Freeze rebuild contract and pass protocol | user-visible blueprint review | In progress |
| 2 | Receipt session/source/storage boundaries | Write a verified preservation map before replacement | focused contract and source ownership proof | Pending |
| 3 | Fixture harness | Establish actual image fixtures and golden measurement format | fixture images decoded and evaluated by production code | Pending |
| 4 | New stitch domain model | Separate candidate, decision, result, and fallback ownership | deterministic model tests | Pending |
| 5 | New visual registration service | One candidate pipeline and one geometry chooser | pixel fixtures including repeated rows | Pending |

The ledger grows one pass at a time. There is deliberately no guessed final
pass count: completion is evidence-based, not estimated into existence.

## 9. Release claim boundary

No statement that the receipt system is ready for on-device testing is allowed
until the relevant rebuilt flow has a production-code image fixture result,
widget interaction result, successful integrated build/install, and observed
device interaction. No release-ready claim is allowed without the broader
cross-platform, source-integrity, recovery, and backup evidence above.
