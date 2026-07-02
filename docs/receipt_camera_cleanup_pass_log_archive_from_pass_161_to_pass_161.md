# Receipt Camera Cleanup Pass Log Archive - Pass 161

This archive keeps the active receipt camera cleanup log under the 500-line
project limit while preserving the full pass history.

## Pass 161 - 06:17:48 EDT to 06:20:12 EDT

Scope:
- Extended `tool/receipt_camera_footprint_audit.dart` to report existing iOS
  IPA artifact sizes when local probe exports are present.
- Kept Android artifact reporting and source footprint reporting unchanged.
- Preserved the explicit warning path for future runs where no iOS artifact is
  available.

Verification:
- Focused iOS artifact-footprint verification passed:
  `dart format`, `dart analyze tool/receipt_camera_footprint_audit.dart`,
  `dart run tool/receipt_camera_footprint_audit.dart`,
  `bash tool/receipt_fast_guard_gate.sh`, focused source audit, and
  `git diff --check`.
- Current iOS artifacts reported by the audit:
  `Runner-size-probe.ipa` 29.9 MB and `maintainiac-size-probe.ipa` 30.2 MB.
- Touched files remain under 500 lines:
  `receipt_camera_footprint_audit.dart` 180 lines and
  `receipt_fast_guard_gate.sh` 21 lines.

Known follow-up:
- Add signed App Store export or TestFlight artifact measurement if that output
  differs from the current local probe IPA files.
