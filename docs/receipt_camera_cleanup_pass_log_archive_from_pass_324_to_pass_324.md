# Receipt Camera Cleanup Pass Log Archive - Pass 324

## Pass 324 - 10:46:00 EDT to 10:49:43 EDT

Scope:
- Split shared receipt line copy/confirmation/map serialization helpers out of
  `receipt_line_models.dart` into `receipt_line_models_serialization.dart`.
- Kept core receipt line classification, proof-reference, review-state, and
  display labels in the original model file.
- Added a focused regression proving `copyWith`, `toMap`, and
  `privacySafeProofReference` preserve client-proof metadata after the split.
- `receipt_line_models.dart` is now 273 lines; the new serialization part is
  127 lines.

Verification:
- Passed `dart format`, targeted `dart analyze`, focused receipt line model,
  parsed-receipt bridge, and expense receipt line record tests.
- Passed source audit, `bash tool/receipt_fast_guard_gate.sh`, and `git diff
  --check`.
- Footprint is now `total_receipt_camera_ocr_source` at 1.74 MB.
