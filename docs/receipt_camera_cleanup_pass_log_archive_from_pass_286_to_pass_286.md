## Pass 286 - 09:50:43 EDT to 09:50:43 EDT

Scope:
- Split the `SharedReceiptAttachmentPanel` build body out of
  `receipt_attachment_panel.dart` into `receipt_attachment_panel_build.dart`.
- Kept the public widget, state fields, lifecycle, initial attachment hydration,
  and `updateAttachmentState` guard in the original panel file.
- Updated source-contract readers/tests so Add Receipt Photo, read-status, and
  interrupted native capture UI checks continue to cover the moved build body.
- Reduced `receipt_attachment_panel.dart` from 294 lines to 159 lines; the new
  build helper part is 143 lines.

Verification:
- Passed `dart format`, targeted `dart analyze`, focused attachment-panel
  widget tests, attachment recovery contract, capture handoff-order contract,
  and import-source sheet tests.
- Passed `bash tool/receipt_fast_guard_gate.sh`, `git diff --check`, and the
  standalone `dart run tool/receipt_camera_footprint_audit.dart`; footprint
  remains `total_receipt_camera_ocr_source` at 1.75 MB.
