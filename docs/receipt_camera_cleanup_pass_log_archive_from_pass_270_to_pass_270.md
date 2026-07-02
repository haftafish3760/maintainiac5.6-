# Receipt Camera Cleanup Pass Log Archive

Archived from the active cleanup log to keep
`docs/receipt_camera_cleanup_pass_log.md` under the 500-line rule.

## Pass 270 - 09:19:00 EDT to 09:20:51 EDT

Scope:
- Split long-receipt source loading out of
  `receipt_camera_long_receipt_guidance_test.dart` into
  `test/helpers/receipt_long_guidance_sources.dart`.
- Kept the long-receipt test's assertions covering photo ordering, retake,
  ghost overlap, stitch review, bottom-section guidance, device stitch caps,
  edge crop controls, backup camera, and product/real-device copy.
- Reduced repeated source setup in the test while preserving all source-contract
  expectations; the new helper also owns the policy part-reader.

Failures fixed during this pass:
- Mechanical variable replacement initially produced `sources.sources.*`, left a
  stale inline policy read, and kept a direct image-edit file read in the test.
  Repaired those leftovers before verification.

Verification:
- Rerun passed `dart format`, targeted `dart analyze`, focused
  `flutter test test/receipt_camera_long_receipt_guidance_test.dart -r compact`,
  and `git diff --check` for the touched test/helper files.
- Did not rerun the fast source guard for this pass because only test files
  changed after the previous successful source gate.
