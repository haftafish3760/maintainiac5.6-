# Receipt Camera Cleanup Pass Log Archive - Pass 700

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
under the project line-count cap.

## Pass 700 - 01:40:00 EDT to active cleanup

Scope:
- Promoted module-specific receipt review depth into a direct
  `ReceiptCaptureFlowOptions.effectiveReviewDepth` contract.
- Updated the shared capture settings builder to use that model contract instead
  of a private helper, making the inventory/maintenance detailed-line default
  directly testable.
- Strengthened the shareability regression so it asserts behavior for expenses,
  shared, materials inventory, maintenance/repair, and forced overrides.
- Recorded `BUG-RECEIPT-0187` under `qa_harness`.
- Archived Pass 640 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for shared receipt capture flow models.
- Passed focused Flutter receipt capture flow shareability regression.
