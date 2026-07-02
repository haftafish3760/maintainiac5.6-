# Receipt Camera Cleanup Pass Log Archive - Pass 276

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
under the 500-line source guard.

## Pass 276 - 09:29:00 EDT to 09:31:02 EDT

Scope:
- Split `ReceiptAttachmentRecord.toMap()` serialization out of
  `receipt_attachment_record.dart` into
  `receipt_attachment_record_serialization.dart`.
- Kept the attachment record constructor, `fromMap`, public convenience getters,
  `copyWith`, and photo-quality update behavior on the class so downstream
  modules can keep using member syntax.
- Reduced `receipt_attachment_record.dart` from 318 lines to 279 lines; the new
  serialization part is 42 lines.

Failures fixed during this pass:
- First focused Flutter test run failed because moving public getters such as
  `label` into an extension broke downstream member lookup in
  `expense_materials_receipt_bridge.dart`. Restored those getters and
  `withPhotoQuality` to the class, then reran verification.

Verification:
- Rerun passed `dart format`, targeted `dart analyze`, focused receipt camera
  result, native quality, PDF proof-storage torture, and native staging tests.
- Passed `bash tool/receipt_fast_guard_gate.sh` and `git diff --check`; the
  footprint audit still reports `total_receipt_camera_ocr_source` at 1.75 MB.
- The PDF torture storage fixture still prints known Helvetica font warnings,
  but exited green.
