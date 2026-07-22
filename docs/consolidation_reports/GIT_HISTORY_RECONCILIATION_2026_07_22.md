# Maintainiac 5.7 Git-history reconciliation — 2026-07-22

## Method

All `origin/*` refs not already ancestors of the 5.7 head were collapsed by
commit identity and ancestry. This leaves nine maximal, distinct history tips;
older branch aliases are reachable from one of these tips. Non-ancestor status
does not by itself mean code is missing because consolidation is semantic and
does not merge source commits wholesale.

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

## Result

- Every remote source-only maximal tip has a recorded semantic outcome.
- No source branch was merged wholesale and no source repository was modified.
- Source branches remain on GitHub as preservation evidence; they should not be
  deleted merely because 5.7 contains the selected behavior.
- Target-absent code was integrated only when it remained compatible with the
  newer 5.7 architecture. Superseded and uncertain alternatives remain in Git
  history and consolidation reports rather than being silently discarded.
