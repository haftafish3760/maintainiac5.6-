# Receipt Camera Cleanup Pass Log Archive - Pass 765

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
under the project line cap while preserving pass history.

## Pass 765 - 05:07:23 EDT to active cleanup

Scope:
- Hardened capture-flow continuation guide options so unsafe previous-photo
  paths cannot be preserved before native session construction.
- Reused the native camera local image path sanitizer for continuation guide
  creation, manual guide application, and flow diagnostics.
- Prevented diagnostics from claiming a previous-section guide photo is
  available when the path is relative, URL-like, non-image, or NUL-tainted.
- Added capture-flow regressions for unsafe previous-photo guide families.
- Recorded `BUG-RECEIPT-0253` under `multi_photo_ordering`.
- Archived Pass 737 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for capture-flow continuation changes.
- Fixed the initial analyzer/test failure caused by a private helper crossing
  Dart library boundaries by making the sanitizer a public contract helper.
- Passed focused Flutter capture-flow shareability regression.
- Passed doc-size, bug-ledger, source-audit, and test-audit gates.
