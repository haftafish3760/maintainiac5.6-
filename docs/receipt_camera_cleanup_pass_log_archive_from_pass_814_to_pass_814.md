# Receipt Camera Cleanup Pass Log Archive - Pass 814

Archived from the active cleanup log so the active pass log stays under the
project documentation line cap.

## Pass 814 - 12:34:00 EDT to active cleanup

Scope:
- Surfaced dirty-lens/hazy saved-photo warnings in the receipt review warning
  profile and next-action handoff copy.
- Added result-level regression coverage proving hazy photos keep the
  `saved_photo_dirty_lens_or_haze` profile, wipe-lens action, and parser risk.
- Recorded `BUG-RECEIPT-0299` under `camera_review_state`.
- Archived Pass 782 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted saved-photo warning format/analyzer and focused dirty-lens
  result regression.
- Passed doc-size, bug-ledger, source-audit, test-audit, cleanup-log, and diff
  whitespace gates.
