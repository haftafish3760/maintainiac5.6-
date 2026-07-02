# Receipt Camera Cleanup Pass Log Archive - Pass 374

Archived from the active cleanup log to keep the active file under the
500-line limit.

## Pass 374 - 12:05:52 EDT to 12:09:39 EDT

Scope:
- Archived oldest active `Pass 346` into
  `receipt_camera_cleanup_pass_log_archive_from_pass_346_to_pass_346.md` after
  the active cleanup log reached 504 lines and failed the 500-line guard.
- Split receipt privacy event payload-count aggregation out of
  `expense_receipt_privacy_event_health_builder.dart` into
  `expense_receipt_privacy_event_health_payload_counts.dart`.
- Reduced `expense_receipt_privacy_event_health_builder.dart` from 340 lines to
  165 lines; the new payload-count helper is 190 lines.

Failures fixed during this pass:
- `bash tool/receipt_cleanup_log_gate.sh` failed because the active pass log was
  504 lines. Archived Pass 346, reran the log gate, and restored the active log
  to 466 lines before continuing source cleanup.

Verification:
- Passed `dart format`, targeted `dart analyze`, focused receipt privacy-event
  Flutter tests, source audit, `bash tool/receipt_fast_guard_gate.sh`, and
  `git diff --check`.
- Footprint remains `total_receipt_camera_ocr_source` at 1.74 MB.
