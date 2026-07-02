# Receipt Camera Cleanup Pass Log Archive - Pass 159

This archive keeps the active receipt camera cleanup log under the 500-line
project limit while preserving the full pass history.

## Pass 159 - 06:15:40 EDT to 06:17:48 EDT

Scope:
- Extended `tool/receipt_camera_footprint_audit.dart` to report existing
  Android APK/AAB artifact sizes when build outputs are present.
- Kept source footprint and packaged artifact footprint separate so the audit
  does not pretend source bytes equal phone install size.
- Left the audit wired into `tool/receipt_fast_guard_gate.sh`.

Verification:
- Focused artifact-footprint verification passed:
  `dart format`, `dart analyze tool/receipt_camera_footprint_audit.dart`,
  `dart run tool/receipt_camera_footprint_audit.dart`,
  `bash tool/receipt_fast_guard_gate.sh`, focused source audit, and
  `git diff --check`.
- Current scoped source footprint remains 1.75 MB across 224 files.
- Existing Android artifacts reported by the audit:
  debug APK 224.1 MB, universal release APK 102.1 MB, arm64 release APK
  42.1 MB, armeabi-v7a release APK 37.1 MB, x86_64 release APK 44.2 MB, and
  release AAB 70.8 MB.
- Touched files remain under 500 lines:
  `receipt_camera_footprint_audit.dart` 156 lines and
  `receipt_fast_guard_gate.sh` 21 lines.

Known follow-up:
- iOS IPA/archive artifact size still needs a matching artifact audit once an
  iOS build product exists locally.
