# Receipt Real-Device Result Template

Use this template for each real-device receipt-camera session.

Purpose:
- capture camera-lane evidence in one repeatable format
- keep personal receipt information out of the notes
- make Phase 9 real-device proof review faster and less guess-heavy

Rules:
- Do not paste full receipt text.
- Do not paste receipt images into this note.
- Use merchant class only when needed, for example `fuel`, `hardware`, or
  `grocery`.
- If a field was unreadable, say that directly instead of guessing.
- If a flow was not run, mark it `NOT RUN`.

Suggested file path:
- `docs/receipt_real_device_runs/YYYY-MM-DD-device-batch.md`

## Session Metadata

- Date:
- Branch:
- Commit:
- Build type:
- Tester:
- Devices:
- Receipt set:

## Environment And Device Matrix

List the device classes covered in this session:

- Metadata snapshot summary:
- Flutter devices snapshot log:
- ADB devices snapshot log:
- Xcode devices snapshot log:

## Required Target Evidence Matrix

Target identity must come from the reported hardware model, not an inferred
capability tier. A newer flagship does not satisfy the S24 row, and a simulator
or another iPhone does not satisfy the iPhone SE row.

- Galaxy S24 Ultra flagship: NOT RUN
- Galaxy S25 Ultra additional flagship: NOT RUN; does not satisfy S24 evidence
- Galaxy S9 Plus older flagship: NOT RUN
- Constrained Android emulator: NOT RUN
- iPhone SE third generation: NOT RUN
- Future budget Android: NOT RUN

For every row changed from `NOT RUN`, record the exact model/virtual profile,
OS/API version, capability tier reported by Maintainiac, evidence file path,
and whether the result passed, failed, or was incomplete.

Do not copy results between rows.

- Older Android:
- Current Android:
- Additional Android:
- iPhone:

List the lighting or interruption conditions covered:

- Bright indoor light:
- Dim room:
- Direct glare:
- Shadow across the receipt:
- Vehicle interior:
- App switch:
- Lock screen:
- Back/close during capture:
- Low-storage or smallest saved-proof setting:

## Flow Results

### Flow 1: Single Photo Receipt

- Status:
- Device coverage:
- Notes:

### Flow 2: Multi-Photo Capture And Long-Receipt Reconstruction

- Status:
- Device coverage:
- Source section count and verified order:
- Automatic result (accepted composite or safe fallback):
- Every join visually valid:
- No repeated, missing, squeezed, or crossed receipt content:
- Retake/manual alignment available after decline:
- OCR source after result:
- Notes:

### Flow 3: Save-Space Preview

- Status:
- Device coverage:
- Notes:

### Flow 4: Receipt-Review Handoff

- Status:
- Device coverage:
- Notes:

### Flow 5: Manual Or No-Assist Photo Handoff

- Status:
- Device coverage:
- Notes:

### Flow 6: Interruption And Recovery

- Status:
- Device coverage:
- Notes:

## Android Stitch Runtime Evidence

Repeat this block for each flagship and constrained Android target. Do not copy
flagship results into the constrained-device row.

- Device model and Android API:
- Capability tier:
- Effective output pixel and height limits:
- Effective target, comparison, and retry widths:
- Effective evidence and processing timeouts:
- Source section count:
- Continue-to-result elapsed time:
- App memory before, peak observed, and after review:
- Output dimensions:
- Result status and privacy-safe reason code:
- Ordered sources preserved after timeout/cancellation:
- Crash buffer clear:
- ANR evidence clear:

## Failure Reports

Repeat this block for each real failure:

- Device:
- Flow number:
- Step number:
- What you expected:
- What happened:
- Was the receipt proof still visible:
- Did the app show an error:
- Did the app crash:

## Privacy And Diagnostics Check

- Help Improve Receipt Camera defaulted off:
- Owner-visible diagnostics stayed metadata-only:
- No receipt images were owner-visible:
- No receipt text was owner-visible:

## Exit Summary

- Single-photo flow ready:
- Multi-photo capture handoff ready:
- Long-receipt reconstruction ready:
- Constrained-Android performance ready:
- Save-space review ready:
- Manual/no-assist ready:
- Recovery ready:
- Remaining risks:
- Recommended next camera pass:
