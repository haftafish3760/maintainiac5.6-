# Receipt Camera World-Class Readiness

This file is the working readiness map for the Maintainiac receipt camera, OCR,
and review pipeline. It is intentionally stricter than an MVP checklist. The
goal is a shared camera system that can be reused from expenses, maintenance,
materials/inventory, and future receipt-backed flows.

## Readiness Position

The current codebase is not "nearly done" against the full world-class receipt
camera goal. The cleanup and guardrail foundation is materially stronger than
before, but the finished product-quality camera/OCR system still depends on
late synthetic QA, real-device receipt proof, and release-build measurement.

Any source-footprint number in this lane must come from a fresh current audit,
not an older pass log. Source-size snapshots are useful for maintenance
pressure, but they are not installed app-size guarantees. Native libraries,
Flutter build output, images, ML Kit packaging, and platform build settings
still need release-build measurement before claiming phone install size.

## Non-Negotiable Product Standard

The shared receipt camera must help a tired or non-technical user capture a
usable receipt without needing to understand OCR, stitching, compression, or
parser failure modes.

The release standard is not "the happy path works." The release standard is:

- capture guidance detects obvious unreadable photos before OCR
- OCR uses the cleanest available source image before saved proof compression
- long receipt capture keeps ordered sections and overlap evidence
- missing bottom edge, missing total, or weak final section triggers a clear
  continuation prompt
- retaking a middle section preserves order and shows the correct section
  context
- stitching and non-stitch ordered-section handoff both have regression tests
- receipt line review supports business, personal, and mixed-use assignment
- admin diagnostics explain failures without exposing user private data
- device-tier policy avoids choking older phones while allowing stronger phones
  to use stronger camera/OCR settings
- all major bug fixes add regression coverage for the whole bug family, not just
  one example

## Current Evidence Already Present

The repository already contains contract or unit-level evidence for these
areas:

- native Android CameraX and iOS AVFoundation bridge expectations
- receipt camera help and long-receipt guidance
- stitch result models, manual overlap, fallback reasons, and output limits
- OCR source handoff metadata, including stitched source selection
- bottom/total coverage decisions and continuation prompts
- saved-photo quality warnings and parser-risk buckets
- glare/readability warning wording
- native camera capability/device diagnostics without private content
- privacy-safe admin diagnostic artifacts
- Firestore summary upload shape for OCR/expense health
- local-first privacy rules for telemetry and Command Center OCR contracts

That evidence is valuable. It does not yet prove the full camera behaves as a
single polished app-wide capture system on real devices.

## Major Remaining Readiness Areas

### Capture Guidance

- live clarity scoring before capture
- blur, glare, dirty-lens, exposure, and skew feedback
- user-facing guidance that stays calm and actionable
- configurable assist settings without burying critical defaults

### Long Receipt Flow

- section numbering from first capture through review/save
- retake section N without corrupting section order
- previous/next ghost overlap for middle-section retakes
- top and bottom receipt completeness checks
- continuation prompt when bottom edge or total is missing
- regression fixtures for top, middle, bottom, missing-middle, duplicated, and
  out-of-order sections

### OCR Source Policy

- original or prepared OCR source is always preferred over compressed proof
- saved proof compression never degrades OCR silently
- stitched image, ordered sections, and fallback image all preserve safe
  evidence labels
- local-only OCR path stays usable without cloud assist

### Parser And Review Handoff

- expense/fuel/maintenance/material parser handoff gets enough evidence to make
  correct review prompts
- receipt line items support business, personal, and mixed allocation
- maintenance receipts can later seed vehicle maintenance intervals from parsed
  service signals
- parser failure states produce clear review tasks instead of silent wrong saves

### Admin Diagnostics

- admin receives failure class, workflow step, confirmed cause when proven,
  missing evidence when not proven, device tier, OS bucket, app version bucket,
  storage bucket, and quality buckets
- admin never receives raw receipt text, private merchant details, customer
  data, notes, local file paths, or unredacted receipt images
- any image preview sent for diagnosis must be privacy-cropped/redacted first
  and must exist only behind an explicit privacy contract

### Device And Storage Policy

- device-tier detection controls capture resolution, section limits, stitch
  output limits, and expensive processing
- low-storage phones get safe local behavior and optional cloud/storage relief
- Firebase or cloud assist must stay optional for the required base flow
- release builds must measure real packaged size, not just source size

## Pass Order

Work should stay one topic at a time:

1. Finish cleanup guardrails so no receipt camera/OCR source file drifts past
   size, lint, privacy, or focused QA gates.
2. Harden the long-receipt section model and retake behavior.
3. Harden capture quality scoring and continuation decisions.
4. Harden OCR source selection and compression boundaries.
5. Harden parser/review handoff for expense, maintenance, and material flows.
6. Harden admin diagnostics and privacy-safe diagnostic preview policy.
7. Add real-device Android/iOS QA passes for native camera behavior.
8. Measure release-build install size and runtime performance on device tiers.

## Percentage Rule

Do not describe the full camera/OCR system as nearly done until all readiness
areas above have executable coverage and real-device evidence. Isolated unit
tests and source audits can prove parts of the foundation; they cannot by
themselves prove a world-class app-wide camera system.
