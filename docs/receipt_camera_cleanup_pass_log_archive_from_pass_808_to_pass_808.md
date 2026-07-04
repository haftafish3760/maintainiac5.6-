# Receipt Camera Cleanup Pass Log Archive - Pass 808

## Pass 808 - 11:51:00 EDT to active cleanup

Scope:
- Added a low-light damaged OCR fixture so the synthetic pack covers true
  too-dark receipt capture alongside blur, glare, crop, and low contrast.
- Pinned the damaged OCR pack count/name regression so focused QA fails if the
  low-light receipt class disappears again.
- Updated stale critical-quality fixture expectations so decodable blurry,
  glare, and low-light photos still allow manual review/Next while recommending
  retake.
- Recorded `BUG-RECEIPT-0292` under `fixture_generation` and
  `BUG-RECEIPT-0293` under `qa_harness`.
- Archived Pass 776 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted fixture format/analyzer and focused damaged OCR QA runner.
- Passed doc-size, bug-ledger, source-audit, test-audit, cleanup-log, and diff
  whitespace gates.
