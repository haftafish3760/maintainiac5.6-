# Maintainiac 5.7 Git-history reconciliation — 2026-07-22

## Method

The first inventory collapsed the then-fetched `origin/*` refs to nine maximal,
distinct history tips. A final `git fetch --prune origin` exposed preservation
refs that were missing from that clone. The refreshed 60 remote branch refs
collapse to 19 independent tips. Non-ancestor status does not by itself mean
code is missing because consolidation is semantic and does not merge source
commits wholesale.

## Maximal source tips

| Tip | Source-only commits | Reconciliation |
| --- | ---: | --- |
| `28b6893b` Receipt OCR | 33 | Semantically reconciled; user-reviewed routing and newer 5.7 owners retained. |
| `3cfc4883` camera backup | 1 | Metadata, exposure-window, and manual-overlap behavior already present. |
| `4299691c` camera lane | 32 | Existing camera behavior retained; unique privacy-safe barcode/QR QA dimension restored. |
| `6af96ab6` Long Receipt | 62 | Semantically reconciled; unique native orientation and source-integrity safeguards integrated. |
| `8c025c1e` PDF system | 101 | Compatible export/import, verifier, health, and Document Engine contracts integrated; superseded parallel archive/renderer rejected. |
| `b29c0d2e` Trip Tracking | 24 | Semantically reconciled into current durable and advisory trip owners. |
| `e315c50b` camera backup | 1 | Phone-window and weak-overlap behavior already present. |
| `e90fab78` camera backup | 1 | Weak-overlap fast-gate behavior already present. |
| `f4715f1f` Trip Tracking | 1 | Confirmed-stop review survives GPS gaps in current split engine; focused regression passed. |

## Refs exposed by the final fetch

| Tip | Reconciliation |
| --- | --- |
| `13df8b2d` active dirty-state backup | Odometer, maintenance, receipt, and review-control changes are present or superseded; ignored build output and formatting were not imported. |
| `46611e84` initial main/dashboard | Zero tip-only paths; current maintained descendants retained. |
| `469d9ae1` pre-control dashboard | Superseded legacy monolithic screens/assets; no parallel owner imported. |
| `7a79acfc` Inventory parser backup | Superseded by the July 12 indexed PEH parser overhaul; historical ambiguity suite remains preserved on GitHub without duplicating executable parser authority. |
| `86cf5321` restored dashboard | Superseded legacy dashboard owners; no parallel owner imported. |
| `8e9771d9` reusable parsing QA | Five exact patches present; remaining handoff/status behavior is contained and extended by current owners. |
| `94e91e1d` PDF stash | UTF-16/binary PDF decoding moved to the shared decoder and remains covered in the fixture inventory. |
| `b7049e96` Expense Camera timeout | Device-aware OCR timeout and focused regression are present. |
| `eb4e51ee` Expense home stash | Duplicate daily navigator removal is present. |

Detailed evidence and the Work Supplies runtime boundary are recorded in
`REMOTE_REF_GAP_RECONCILIATION_2026_07_22.md`.

## Result

- Every remote source-only independent tip exposed by the refreshed 60-ref
  inventory has a recorded semantic outcome.
- No source branch was merged wholesale and no source repository was modified.
- Source branches remain on GitHub as preservation evidence; they should not be
  deleted merely because 5.7 contains the selected behavior.
- Target-absent code was integrated only when it remained compatible with the
  newer 5.7 architecture. Superseded and uncertain alternatives remain in Git
  history and consolidation reports rather than being silently discarded.
