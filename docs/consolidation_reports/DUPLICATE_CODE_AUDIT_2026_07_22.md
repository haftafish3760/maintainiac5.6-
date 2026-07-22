# Maintainiac 5.7 duplicate-code audit — 2026-07-22

## Scope and method

- Scanner: `tool/duplicate_code_scan.dart`
- Production roots: `lib`, supported platform folders, `web`, `functions`, and
  `tool`
- Tests, generated code, Flutter plugin symlinks, Pods, ephemeral output,
  third-party/vendor trees, and build caches are excluded by default.
- Exact files and normalized blocks of 16 or more lines are SHA-256
  fingerprinted. Source code is read only; the scanner does not rewrite files.

## Current 5.7 result

- Maintainiac-owned code files scanned: **1,608**
- Exact duplicate file groups: **0**
- Repeated block groups: **220**
- Unique repeated-block fingerprints: **158**

## Baseline comparison

The same scanner and exclusions were run against the untouched
`Maintainiac_5.6_Active` baseline:

- Baseline code files scanned: **1,564**
- Baseline exact duplicate file groups: **0**
- Baseline repeated block groups: **220**
- Baseline unique repeated-block fingerprints: **158**
- Fingerprints shared by baseline and 5.7: **157**
- Net additional repeated-block groups introduced by consolidation: **0**

The first expanded scan found one additional repeated block inside
`tool/pdf_quality_gate.sh`. That imported gate repeated the same target list for
analysis and testing and referenced removed PDF owners. The gate now owns one
test-target array, references only current 5.7 owners, and the additional clone
is gone.

The expanded post-PDF scan also found two repeated validation/privacy blocks
inside the imported invoice export verifier. They now call one shared internal
method, and the focused 26-test verifier contract passed afterward. The one
current fingerprint that differs from the baseline is the updated paired
Android/iOS receipt-camera settings contract; it replaces one older paired
baseline fingerprint rather than adding another group.

## Interpretation

The consolidation did not introduce an exact duplicate file or increase the
number of repeated production-code groups. The 220 remaining groups match the
5.6 baseline count and include shared UI/calendar patterns, mirrored native
platform contracts, serialization contracts, and repeated audit-tool
structure. They are reported for later targeted refactoring; they are not safe
deletion instructions. Removing one side without semantic and call-site review
could discard behavior.

Machine-readable current evidence is stored in
`docs/consolidation_reports/duplicate_code_scan_2026_07_22.json`.
