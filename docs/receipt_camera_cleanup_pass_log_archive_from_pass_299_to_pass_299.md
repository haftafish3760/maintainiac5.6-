# Receipt Camera Cleanup Pass Log Archive

Archived from the active cleanup pass log to keep the active file under the
500-line working limit.

## Pass 299 - 10:09:35 EDT to 10:09:35 EDT

Scope:
- Split Android native captured-photo diagnostics payload fields out of
  `ReceiptCameraDiagnosticsPayload.kt` into
  `ReceiptCameraCapturedQuality.kt` via `nativeCapturedPhotoDiagnostics(...)`.
- Kept the main native capture diagnostics payload focused on session, control,
  close, storage, workload, and long-receipt policy evidence while still
  merging saved-photo quality, bottom-edge, preview-parity, and latency fields.
- Verified the split coexists with the parallel previous-section diagnostics
  split now logged as Pass 298.
- `ReceiptCameraDiagnosticsPayload.kt` remains 288 lines and the captured
  quality helper is now 239 lines.

Verification:
- Passed focused Android native bridge settings/quality, privacy diagnostics,
  and native shell recovery contract tests against the combined current state.
- Passed `bash tool/android_receipt_camera_compile_gate.sh`, `bash
  tool/receipt_fast_guard_gate.sh`, `git diff --check`, and standalone
  footprint audit; footprint remains `total_receipt_camera_ocr_source` at
  1.76 MB.
