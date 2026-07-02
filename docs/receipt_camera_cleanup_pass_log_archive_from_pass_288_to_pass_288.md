## Pass 288 - 09:50:44 EDT to 09:52:55 EDT

Scope:
- Split receipt photo order thumbnail rendering out of
  `receipt_photo_review_order_controls.dart` into
  `receipt_photo_review_order_thumbnail.dart`.
- Kept the order tool control layout, move earlier/later actions, add-photo
  action, and retake action in the original order-controls part.
- Updated long-receipt and photo-review source-contract readers so thumbnail
  cache sizing and section labels remain covered after the split.
- Reduced `receipt_photo_review_order_controls.dart` from 291 lines to 164
  lines; the new thumbnail part is 126 lines.

Failures fixed during this pass:
- First focused Flutter run failed because
  `receipt_photo_review_controls_layout_test.dart` still read only the original
  order-controls file while asserting thumbnail cache sizing. Added the new
  thumbnail part to that source bundle and reran.

Verification:
- Rerun passed `dart format`, targeted `dart analyze`, focused photo-section,
  long-receipt guidance, photo-review controls layout, and exit-completion
  tests.
- Passed source audit, `bash tool/receipt_fast_guard_gate.sh`, and
  `git diff --check`; footprint remains `total_receipt_camera_ocr_source` at
  1.75 MB.
