# Long Receipt Stitching Cross-Platform Handoff

## Current ownership

- Canonical worktree: `/Users/rbbie/Documents/Maintainiac_5.6_Long_Receipt`
- Branch: `codex/long-receipt-hardening-20260714`
- Remote: `origin/codex/long-receipt-hardening-20260714`
- Latest verified implementation milestone: Pass 2814, 2026-07-15 04:12 PM EDT,
  commit `5e2f86ee4`.

This lane owns the long-receipt workflow end to end: its capture/review UI,
ordered receipt sections from either live capture or uploaded images, safe
stitching, and OCR handoff. It never mutates an original receipt.

## Where work belongs

Keep the implementation checkout on the Mac Mini. It is the only machine that
can verify both Android and iOS/native receipt behavior from one checkout.

Windows may safely use its own clone and branch for pure-Dart work only:

- deterministic image fixtures and stitch-model tests;
- shell QA scripts that do not require iOS tooling;
- source-preservation, duplicate, ordering, weak-overlap, and fallback tests.

Windows must not change iOS/native ghost-slice code, run iOS validation, or
claim cross-platform proof. Before a Windows change is merged, pull it onto the
Mac branch and run the named regression plus the relevant Mac health group.

## Editable scope

Primary implementation:

- `lib/shared/widgets/receipt_capture/receipt_image_processor_stitch_api.dart`
- `lib/shared/widgets/receipt_capture/receipt_image_processor_stitch_helpers.dart`
- `lib/shared/widgets/receipt_capture/receipt_image_processor_stitch_scoring_helpers.dart`
- `lib/shared/widgets/receipt_capture/receipt_image_processor_stitch_transform_helpers.dart`
- `lib/shared/widgets/receipt_capture/receipt_image_processor_models.dart`

Tests and QA:

- `test/receipt_stitching_*_test.dart`
- `test/helpers/receipt_stitching_image_helpers.dart`
- `tool/receipt_stitch_contract_health.sh`
- `tool/receipt_stitch_real_probe.sh`
- `tool/receipt_stitch_real_window_probe.sh`
- `tool/receipt_stitch_real_window_matrix.sh`
- `docs/receipt_bug_regression_ledger.md`

Do not work in camera UI/UX, OCR providers, fuel parsing, PDF, inventory,
maintenance, trip/GPS, or unrelated settings while assigned this lane.

The exception is the long-receipt UI itself. It is in scope when it exposes or
correctly routes section capture, numbered sections, previous-section ghost
context, Add Another Photo, selected-section retake, quality/fallback review,
and final OCR handoff. Keep that work modular and limited to the long-receipt
flow; do not redesign the general camera viewer or unrelated receipt screens.

## Current contract

1. Preserve every source image byte-for-byte.
2. Accept ordered sections from live and uploaded sources, including a mixed
   source stack.
3. Stitch only confident, non-duplicate adjacent sections.
4. Keep a safe fallback when overlap is weak, ambiguous, duplicated, unreadable,
   malformed, or too large.
5. A successful stitch provides exactly one derived OCR source. A fallback keeps
   the original ordered sources and requires review before assisted reading.
6. High-overlap final captures are valid when their visual evidence is
   distinctive. Pass 2814 expanded automatic overlap search through 82%;
   duplicate and confidence safeguards remain mandatory.
7. Ghost/retake context follows the prior/next section contract and must respect
   image orientation on Android and iOS.

## Verified automated coverage

- Long stacks, phone-window captures, transformed/worn/torn/smudged sections,
  weak overlap, duplicate safety, ordering, mixed uploaded/live sections, OCR
  handoff, source preservation, and real-probe shell contracts are covered.
- Pass 2814 regression: `test/receipt_stitching_high_overlap_test.dart`.
- Pass 2814 targeted verification passed:
  `test/receipt_stitching_high_overlap_test.dart`,
  `test/receipt_stitching_long_stack_test.dart`,
  `test/receipt_stitching_duplicate_safety_test.dart`, and targeted analyzer.
- The quiet suite is `tool/receipt_stitch_contract_health.sh`; do not stream its
  output. Run it non-interactively, then inspect the final result only.

## Remaining proof

Automated hardening is substantially covered. Do not call this complete until
physical multi-section receipt captures prove the flow on a real Android device
and a real iOS device:

- ordinary long receipt with 20-40% overlap;
- a last section with intentionally heavy overlap;
- wrinkled, smudged, and low-contrast paper;
- uploaded multi-image receipt; and
- safe fallback when one section is retaken or does not overlap.

Record any confirmed device failure in `docs/receipt_bug_regression_ledger.md`,
add a deterministic regression, fix it, and rerun the smallest applicable
health group before continuing.

## Working rules

- Keep files under 500 lines.
- Bundle a coherent stitch feature with its regression; do not make unrelated
  one-line changes.
- Do not treat inspection, commits, pushes, or test runs as implementation
  passes.
- Stop feature work on a failing gate. Fix the failure first.
- Commit only verified milestones with pass number, Eastern time, and a concise
  label. Push about hourly or at a meaningful milestone, whichever comes first.
