## Pass 204 - 07:33:48 EDT to 07:35:45 EDT

Scope:
- Archived active `Pass 184` into
  `docs/receipt_camera_cleanup_pass_log_archive_from_pass_184_to_pass_184.md`
  so the active cleanup log stays under the 500-line project limit.
- Split derived device capability labels and cloud-assist planning out of
  `receipt_assistance_policy_device_capability.dart` into
  `receipt_assistance_policy_device_capability_assist.dart`.
- Kept core capability construction and storage-pressure policy in the original
  file.
- Reduced `receipt_assistance_policy_device_capability.dart` from 376 lines to
  206 lines; the new assist extension part is 173 lines.

Verification:
- Focused verification passed on the first run: `dart format`, targeted
  `dart analyze`, and `flutter test test/receipt_assistance_policy_test.dart
  test/receipt_assistance_policy_diagnostics_test.dart
  test/receipt_assistance_footprint_policy_test.dart
  test/receipt_device_capability_tiers_test.dart -r compact`.
- Focused source audit, `bash tool/receipt_fast_guard_gate.sh`, and
  `git diff --check` passed.
