# Receipt Camera Cleanup Pass Log Archive - Pass 598

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active
cleanup pass log under the project line-count cap.

## Pass 598 - 20:52:16 EDT to 20:54:10 EDT

Scope:
- Hardened iOS pre-capture exposure adjustment so losing camera UI during the
  AVFoundation exposure callback clears in-flight capture state instead of
  silently returning.
- Added iOS pre-capture exposure abort diagnostics matching the Android
  behavior: abort count plus abort reason.
- Updated iOS source-contract regressions so the unsafe `guard let self,
  self.isCameraUiUsable else { return }` does not come back in capture prep.
- Recorded `BUG-RECEIPT-0119` under `native_bridge`.

Verification:
- Fixed the first focused regression by scoping the negative early-return check
  to `ReceiptCameraViewControllerCapture.swift` instead of the full iOS bridge
  bundle, where live-frame callbacks still have their own valid guard.
- Passed targeted Dart format/analyzer for the iOS bridge source-contract
  regressions.
- Passed focused Flutter iOS bridge analysis/exposure and UI-session
  regressions.
- Passed cleanup log gate, doc-size gate, source audit, and whitespace check.
