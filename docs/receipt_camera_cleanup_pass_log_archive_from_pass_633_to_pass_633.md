# Receipt Camera Cleanup Pass Log Archive - Pass 633

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
under the project documentation size cap.

## Pass 633 - 22:15:43 EDT to active cleanup

Scope:
- Hardened malformed native review-depth diagnostics so privacy-safe receipt
  metadata uses a generic invalid bucket instead of tokenizing raw diagnostic
  text that could contain receipt content.
- Added focused review-depth regression coverage proving malformed values stay
  visible without leaking the raw text or receipt paths.
- Archived Pass 622 from the active cleanup log to keep the doc under cap.
- Recorded `BUG-RECEIPT-0154` under `privacy_redaction`.

Verification:
- Passed targeted Dart format/analyzer for native review-depth metadata.
- Passed focused Flutter frozen camera/result metadata regression.
- Passed whitespace check.
