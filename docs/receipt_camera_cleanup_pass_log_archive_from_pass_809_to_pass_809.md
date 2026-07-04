# Receipt Camera Cleanup Pass Log Archive - Pass 809

Archived from the active cleanup log so the active pass log stays under the
project documentation line cap.

## Pass 809 - 12:01:00 EDT to active cleanup

Scope:
- Added direct low-light receipt quality guidance coverage at the model boundary.
- Pinned that too-dark receipts recommend retake, block auto capture, still
  allow manual review/Next, and surface add-light/torch guidance.
- Recorded `BUG-RECEIPT-0294` under `camera_capture_quality`.
- Archived Pass 777 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted quality guidance format/analyzer and focused low-light
  regression test.
- Passed doc-size, bug-ledger, source-audit, test-audit, cleanup-log, and diff
  whitespace gates.
