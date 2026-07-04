# Receipt Camera Cleanup Pass Log Archive - Pass 816

Archived from the active receipt camera cleanup log to keep the current log
under the project line cap.

## Pass 816 - 11:32:00 EDT to active cleanup

Scope:
- Promoted native backup scanner and phone-camera fallback warnings from
  generic review actions into explicit crop/focus review handoff families.
- Kept fallback-only backup capture from becoming the primary accepted warning
  profile while still exposing parser risk and receipt-reader handoff counts.
- Added focused regressions for document-scanner backup crop review and
  phone-camera backup focus review.
- Recorded `BUG-RECEIPT-0301` under `camera_review_state`.
- Archived Pass 809 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted saved-photo warning format/analyzer and focused native
  backup warning handoff regressions.
- Corrected one invalid focused-test command that combined two `--plain-name`
  filters and reran the two focused tests individually.
- Passed doc-size, bug-ledger, source-audit, test-audit, cleanup-log, and diff
  whitespace gates.
