# Receipt Camera Cleanup Pass Log Archive - Pass 245

Archived from the active receipt camera cleanup pass log so the active file
stays under the 500-line rule.

## Pass 245 - 08:38:35 EDT to 08:41:57 EDT

Scope:
- Archived active Pass 224 into
  `receipt_camera_cleanup_pass_log_archive_from_pass_224_to_pass_224.md` so the
  active cleanup log stays under the 500-line rule.
- Split device, storage, camera-control labels and hardware-profile capability
  recommendation adapters out of
  `receipt_assistance_policy_hardware_profile.dart` into
  `receipt_assistance_policy_hardware_labels.dart`.
- Kept raw hardware fields, privacy-safe capability diagnostics, automatic tier
  scoring, and storage classification in the original hardware profile file.
- Reduced `receipt_assistance_policy_hardware_profile.dart` from 349 lines to
  266 lines; the new hardware-label part is 86 lines.
- Fixed `receipt_native_camera_privacy_diagnostics_test.dart` to read
  `receipt_native_camera_service_contract_helpers.dart` with the service source,
  because the native control contract had already been split into that part.

Failures fixed during this pass:
- First focused run failed because the native privacy diagnostics source bundle
  did not include the service contract helper part. Added the part to the test
  reader and reran the same focused verification successfully.

Verification:
- Rerun passed: `dart format`, targeted `dart analyze`, and focused
  `flutter test test/receipt_native_camera_privacy_diagnostics_test.dart
  test/receipt_assistance_policy_diagnostics_test.dart
  test/receipt_assistance_footprint_policy_test.dart
  test/receipt_assistance_policy_install_strategy_test.dart -r compact`.
- Source audit, `bash tool/receipt_fast_guard_gate.sh`, and `git diff --check`
  passed after the split.
